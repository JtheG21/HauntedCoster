--!strict
-- Multi-client scenario (TASK-0005): two players of different factions open a Convergence Gate
-- together and each earns exactly one Echo charge per opening power.
-- Powers are applied through the same server-side signals the real abilities produce (a
-- PlateActivator on the plate; LastKiHit on the Ki target), because a server scenario can't press
-- client keys. The real abilities feeding those signals are covered by single-player Play tests.
-- Launch: StudioTestService:ExecuteMultiplayerTestAsync(2, { scenario = "GateCoop", players = 2, timeout = 50 })

local Players = game:GetService("Players")

local GateFixture = require(script.Parent.GateFixture)

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
	local wanted = if typeof(args.players) == "number" then args.players else 2
	local timeout = if typeof(args.timeout) == "number" then args.timeout else 40
	if not waitFor(function()
		return #Players:GetPlayers() >= wanted
	end, timeout) then
		return { ok = false, error = `only {#Players:GetPlayers()} joined` }
	end
	local players = Players:GetPlayers()
	for _, player in players do
		if
			not waitFor(function()
				return player.Character ~= nil and player.Character:FindFirstChild("HumanoidRootPart") ~= nil
			end, 20)
		then
			return { ok = false, error = `{player.Name} never spawned` }
		end
	end
	-- Readiness (LES-0004): wait until characters simulate.
	for i, player in players do
		local character = player.Character :: Model
		local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
		character:PivotTo(CFrame.new(i * 6, 12, -60))
		waitFor(function()
			return root.Position.Y < 9
		end, 20)
	end

	local factions = {}
	for _, player in players do
		table.insert(factions, player:GetAttribute("Faction"))
	end

	local g = GateFixture.build(Vector3.new(0, 0, -100))
	task.wait(0.5)
	local result: { [string]: any } = { factions = factions, required = g.gate:GetAttribute("Required") }

	-- 1. Only one power applied: must stay closed.
	local clone = GateFixture.fakeClone(g)
	task.wait(1)
	result.closedWithOnePower = g.gate:GetAttribute("State") == "closed"

	-- 2. Ki applied outside the window (11 s ago): still closed.
	g.kiTarget:SetAttribute("LastKiHit", os.clock() - 11)
	task.wait(0.5)
	result.closedOutsideWindow = g.gate:GetAttribute("State") == "closed"

	-- 3. Ki applied now while the clone holds the plate: opens.
	g.kiTarget:SetAttribute("LastKiHit", os.clock())
	result.opened = waitFor(function()
		return g.gate:GetAttribute("State") == "open"
	end, 2)
	result.barrierPassable = g.gate.CanCollide == false
	clone:Destroy()

	-- 4. Both players walk through the pass zone (twice): exactly 1 charge per power each.
	for i, player in players do
		(player.Character :: Model):PivotTo(CFrame.new(g.passZone.Position + Vector3.new(i * 3 - 4, 0, 0)))
	end
	task.wait(1)
	for i, player in players do
		(player.Character :: Model):PivotTo(CFrame.new(g.passZone.Position + Vector3.new(i * 3 - 4, 0, 1)))
	end
	task.wait(1)
	local charges = {}
	local exact = true
	for _, player in players do
		local s = player:GetAttribute("Echo_Shinobi") or 0
		local k = player:GetAttribute("Echo_Ki") or 0
		table.insert(charges, `{s}/{k}`)
		if s ~= 1 or k ~= 1 then
			exact = false
		end
	end
	result.charges = charges

	-- 5. Optional (adds about 9 s; the MCP call can time out): the gate closes again after
	-- OpenSeconds and the consumed inputs don't reopen it. Also covered by single-player Play tests.
	if args.checkClose == true then
		result.closedAgain = waitFor(function()
			return g.gate:GetAttribute("State") == "closed"
		end, 10)
		task.wait(1)
		result.staysClosed = g.gate:GetAttribute("State") == "closed"
	else
		result.closedAgain, result.staysClosed = true, true
		result.closeChecked = false
	end
	g.folder:Destroy()

	result.ok = result.required == "Shinobi,Ki"
		and result.closedWithOnePower
		and result.closedOutsideWindow
		and result.opened
		and result.barrierPassable
		and exact
		and result.closedAgain
		and result.staysClosed
	return result
end
