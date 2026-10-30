--!strict
-- Multi-client scenario (TASK-0009 / TEST-20261010-02): two players touch the same coin in the
-- same server frame. Exactly one reward per round is expected. Then each player touches a
-- different coin, and both should be rewarded (legitimate rewards still work).
-- Launch from Studio edit mode:
--   game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "CollectibleRace", rounds = 2 })

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function waitFor(predicate: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	while not predicate() do
		if os.clock() > deadline then
			return false
		end
		task.wait(0.1)
	end
	return true
end

return function(args: { [string]: any }): { [string]: any }
	local wanted = args.players or 2
	local rounds = args.rounds or 2
	-- "drop": place characters just above the coin so they fall through it (physical contact, like
	-- walking in). "teleport": place them exactly at the coin centre (instant overlap).
	local approach = args.approach or "drop"
	local offset = if approach == "drop" then Vector3.new(0, 4, 0) else Vector3.zero

	if not waitFor(function()
		return #Players:GetPlayers() >= wanted
	end, 30) then
		return { ok = false, error = `only {#Players:GetPlayers()} players joined` }
	end
	local players = Players:GetPlayers()
	for _, player in players do
		if
			not waitFor(function()
				local character = player.Character
				return character ~= nil
					and character:FindFirstChild("HumanoidRootPart") ~= nil
					and player:FindFirstChild("leaderstats") ~= nil
			end, 20)
		then
			return { ok = false, error = `{player.Name} never spawned` }
		end
	end
	-- Readiness: a freshly joined client may not simulate its character yet, and a character
	-- that isn't simulating can't touch anything. Lift each character and wait until it falls.
	for i, player in players do
		local character = player.Character :: Model
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		local lifted = Vector3.new(i * 8, 12, 60)
		character:PivotTo(CFrame.new(lifted))
		if not waitFor(function()
			return root.Position.Y < lifted.Y - 3
		end, 20) then
			return { ok = false, error = `{player.Name}'s character never started simulating` }
		end
	end
	task.wait(1)

	local folder = Workspace:FindFirstChild("Collectibles")
	if not folder or #folder:GetChildren() < 3 then
		return { ok = false, error = "need at least 3 coins in Workspace.Collectibles" }
	end
	local coins = folder:GetChildren()
	local shared = coins[1] :: BasePart

	local function coinsOf(player: Player): number
		return ((player :: any).leaderstats.Coins :: IntValue).Value
	end
	local function total(): number
		local sum = 0
		for _, player in players do
			sum += coinsOf(player)
		end
		return sum
	end
	local function parkAll()
		for i, player in players do
			(player.Character :: Model):PivotTo(CFrame.new(i * 8, 5, 60))
		end
	end

	-- Race rounds: everyone onto the same coin in the same frame (no yield between PivotTo calls).
	local perRound = {}
	local trace = {}
	for _ = 1, rounds do
		parkAll()
		-- Let the owning clients settle at the parking spot; two server teleports in one frame
		-- can leave the client's physics state out of step (round 1 always missed without this).
		task.wait(args.settle or 1)
		if not waitFor(function()
			return shared:GetAttribute("Active") == true
		end, 10) then
			return { ok = false, error = "shared coin never became active" }
		end
		local before = total()
		-- Trace touches on the shared coin this round (diagnostics only).
		local touches, minDistance = 0, math.huge
		local connection = shared.Touched:Connect(function(hit)
			local model = hit:FindFirstAncestorOfClass("Model")
			local root = model and model:FindFirstChild("HumanoidRootPart")
			if root and root:IsA("BasePart") and Players:GetPlayerFromCharacter(model) then
				touches += 1
				minDistance = math.min(minDistance, (root.Position - shared.Position).Magnitude)
			end
		end)
		for _, player in players do
			(player.Character :: Model):PivotTo(CFrame.new(shared.Position + offset))
		end
		task.wait(1.5)
		connection:Disconnect()
		-- Where did the characters actually end up? (detects teleports the owning client overrode)
		local farthest = 0
		for _, player in players do
			local root = (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart?
			if root then
				local flat = Vector3.new(root.Position.X - shared.Position.X, 0, root.Position.Z - shared.Position.Z)
				farthest = math.max(farthest, flat.Magnitude)
			end
		end
		table.insert(perRound, total() - before)
		table.insert(trace, {
			touches = touches,
			minDistance = if minDistance == math.huge then -1 else math.floor(minDistance * 10) / 10,
			activeAfter = shared:GetAttribute("Active"),
			farthestAfter = math.floor(farthest * 10) / 10,
		})
	end

	-- Legit round: each player onto a different active coin.
	parkAll()
	task.wait(0.5)
	local legit = {}
	for i, player in players do
		local coin = coins[i + 1] :: BasePart
		waitFor(function()
			return coin:GetAttribute("Active") == true
		end, 10)
		local before = coinsOf(player);
		(player.Character :: Model):PivotTo(CFrame.new(coin.Position + offset))
		task.wait(1.5)
		table.insert(legit, coinsOf(player) - before)
	end
	parkAll()

	-- Duplicates (>1) would be a real game bug. Zero means no touch registered (harness or game).
	local raceOk, duplicates, misses = true, 0, 0
	for _, gained in perRound do
		if gained > 1 then
			duplicates += 1
		elseif gained < 1 then
			misses += 1
		end
		if gained ~= 1 then
			raceOk = false
		end
	end
	local legitOk = true
	for _, gained in legit do
		if gained ~= 1 then
			legitOk = false
		end
	end
	return {
		ok = raceOk and legitOk,
		players = #players,
		approach = approach,
		racePerRound = perRound,
		duplicates = duplicates,
		misses = misses,
		trace = trace,
		legitPerPlayer = legit,
	}
end
