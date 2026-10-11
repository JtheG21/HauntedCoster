--!strict
-- Multi-client scenario (TASK-0007): the ring-out finale with two real clients.
--   1. a guard absorbs one knockback
--   2. a real Ki Burst (server handler + finale hook) knocks the rival off; the rival is eliminated
--      once and the attacker wins Combat
--   3. an eliminated player can't knock anyone back
--   4. two players out in the same poll = a Combat draw
--   5. an Echo_Ki charge is spent for a borrowed burst; nobody without a charge can spend
--   6. Teamwork credit goes to the clone owner and the Ki hitter of a gate opening
-- Knockback runs on the server and moves a client-owned character, so this also proves the
-- LinearVelocity replicates. Runs inside the game's server and shares module state with it.
-- Launch (in the background): ExecuteMultiplayerTestAsync(2, { scenario = "FinaleRingOut", players = 2, timeout = 60 })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("Services")
local Abilities = Server:WaitForChild("Abilities")
local Components = Server:WaitForChild("Components")
local MatchService = require(Services:WaitForChild("MatchService")) :: any
local FinaleService = require(Services:WaitForChild("FinaleService")) :: any
local EchoService = require(Services:WaitForChild("EchoService")) :: any
local FinaleModifiers = require(Abilities:WaitForChild("FinaleModifiers")) :: any
local KiBurst = require(Abilities:WaitForChild("KiBurst")) :: any
local ConvergenceGate = require(Components:WaitForChild("ConvergenceGate")) :: any
local FinaleConfig = require(ReplicatedStorage.Shared.FinaleConfig) :: any
local MatchConfig = require(ReplicatedStorage.Shared.MatchConfig) :: any

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

local function root(player: Player): BasePart
	return (player.Character :: Model):FindFirstChild("HumanoidRootPart") :: BasePart
end

return function(args: { [string]: any }): { [string]: any }
	local wanted = if typeof(args.players) == "number" then args.players else 2
	local timeout = if typeof(args.timeout) == "number" then args.timeout else 40
	-- Keep the real match loop out of the way: nobody becomes eligible during this scenario.
	MatchService.setEligibility(function(_player: Player)
		return false
	end)
	local function enough(): boolean
		return #Players:GetPlayers() >= wanted
	end
	-- Client joins are flaky on this Mac (Multi-Client Testing): after 30 s, ask Studio for the
	-- missing players from inside the test, then wait for the rest of the timeout.
	local addedPlayers = false
	if not waitFor(enough, math.min(30, timeout)) then
		addedPlayers = true
		StudioTestService:AddPlayers(wanted - #Players:GetPlayers())
	end
	if not waitFor(enough, math.max(timeout - 30, 20)) then
		return { ok = false, error = `only {#Players:GetPlayers()} joined (AddPlayers used: {addedPlayers})` }
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
	-- Readiness (LES-0004): wait until both characters are simulated by their clients.
	for i, player in players do
		local character = player.Character :: Model
		character:PivotTo(CFrame.new(i * 6, 12, 60))
		local ready = waitFor(function()
			return root(player).Position.Y < 9
		end, 20)
		if not ready then
			return { ok = false, error = `{player.Name} never simulated` }
		end
	end
	local p1, p2 = players[1], players[2]
	local result: { [string]: any } = { addedPlayers = addedPlayers }

	local zone = MatchConfig.Zones.Finale
	local c = Vector3.new(zone.X, FinaleConfig.TopY, zone.Z)
	-- p1 stands 10 studs from the +X edge facing it; p2 is 5 studs in front of p1.
	local function line()
		(p1.Character :: Model):PivotTo(CFrame.lookAt(c + Vector3.new(13, 3, 0), c + Vector3.new(40, 3, 0)));
		(p2.Character :: Model):PivotTo(CFrame.lookAt(c + Vector3.new(18, 3, 0), c + Vector3.new(40, 3, 0)))
		task.wait(1.5) -- settle (LES-0004: characters must be simulating)
	end

	FinaleService.begin({ p1, p2 })
	result.started = FinaleService.isAlive(p1) and FinaleService.isAlive(p2)
	result.remainingAtStart = ReplicatedStorage:GetAttribute("FinaleRemaining")
	line()
	result.settledOnDeck = root(p2).Position.Y > FinaleConfig.TopY

	-- 1. Guard absorbs one hit.
	FinaleService.grantGuard(p2)
	local before = root(p2).Position
	local pushed, absorbed = FinaleModifiers.knockback(p1, root(p1), 1)
	result.guardStep = `{pushed}/{absorbed}`
	task.wait(0.6)
	result.guardAbsorbed = absorbed == 1 and pushed == 0
	result.guardKeptPlace = (root(p2).Position - before).Magnitude < 2
	result.guardConsumed = p2:GetAttribute("FinaleGuard") == nil

	-- 2. Real Ki Burst at full charge knocks p2 off the deck.
	before = root(p2).Position
	KiBurst.chargeHandler(p1, p1.Character, root(p1))
	task.wait(1.6)
	KiBurst.burstHandler(p1, p1.Character :: Model, root(p1))
	local maxMove = 0
	result.eliminated = waitFor(function()
		maxMove = math.max(maxMove, (root(p2).Position - before).Magnitude)
		return p2:GetAttribute("FinaleAlive") == false
	end, 5)
	result.p2Moved = math.floor(maxMove)
	result.isOver = FinaleService.isOver()
	result.remainingAfter = ReplicatedStorage:GetAttribute("FinaleRemaining")
	FinaleService.results({})
	result.combatWinner = ReplicatedStorage:GetAttribute("Result_Combat")
	result.winnerIsAttacker = result.combatWinner == p1.DisplayName

	-- 3. The eliminated player can't knock the survivor back.
	local pushedByOut = FinaleModifiers.knockback(p2, root(p2), 1)
	result.eliminatedCantPush = pushedByOut == 0

	-- 4. Both out in the same poll = draw.
	FinaleService.begin({ p1, p2 })
	task.wait(0.5)
	FinaleService.recordContribution(p1)
	local below = c - Vector3.new(0, FinaleConfig.RingOutDepth + 10, 0);
	(p1.Character :: Model):PivotTo(CFrame.new(below + Vector3.new(0, 0, 40)));
	(p2.Character :: Model):PivotTo(CFrame.new(below + Vector3.new(4, 0, 40)))
	waitFor(function()
		return p1:GetAttribute("FinaleAlive") == false and p2:GetAttribute("FinaleAlive") == false
	end, 2)
	local summary = FinaleService.results({ p2 })
	result.drawCombat = ReplicatedStorage:GetAttribute("Result_Combat")
	result.isDraw = string.sub(tostring(result.drawCombat), 1, 5) == "draw:"
	result.summary = summary
	FinaleService.resetContributions()

	-- 5. Echo spend: only a player holding a charge, and it is consumed.
	FinaleService.begin({ p1, p2 })
	line()
	EchoService.add(p1, "Ki")
	result.canSpendWithCharge = FinaleModifiers.canSpend("Ki")(p1)
	result.cantSpendWithout = not FinaleModifiers.canSpend("Ki")(p2) and not FinaleModifiers.canSpend("Shinobi")(p1)
	before = root(p2).Position
	FinaleModifiers.echoBurstHandler(p1, p1.Character :: Model, root(p1))
	result.echoHadVelocity = root(p2):FindFirstChild("KnockbackVelocity") ~= nil
	local echoMove = 0
	-- Observe the whole push (1.5 s), then record the furthest distance.
	local echoUntil = os.clock() + 1.5
	while os.clock() < echoUntil do
		echoMove = math.max(echoMove, (root(p2).Position - before).Magnitude)
		task.wait()
	end
	result.echoBurstMoved = math.floor(echoMove)
	result.echoSpent = p1:GetAttribute("Echo_Ki") == nil and EchoService.get(p1, "Ki") == 0
	result.echoSecondSpendFails = not FinaleModifiers.canSpend("Ki")(p1)
	FinaleService.reset()
	result.resetClears = p1:GetAttribute("FinaleAlive") == nil
		and ReplicatedStorage:GetAttribute("FinaleRemaining") == nil

	-- 6. Teamwork credit for a gate opening: the clone owner and the Ki hitter.
	local credited: { [Player]: number } = {}
	ConvergenceGate.onContribution(function(player: Player)
		credited[player] = (credited[player] or 0) + 1
	end)
	local g = GateFixture.build(Vector3.new(0, 0, -100))
	for i, player in players do
		(player.Character :: Model):PivotTo(CFrame.new(g.approach.Position + Vector3.new(i * 3 - 4, 3, -4)))
	end
	task.wait(0.5)
	local clone = GateFixture.fakeClone(g)
	clone:SetAttribute("OwnerUserId", p1.UserId)
	task.wait(0.4)
	g.kiTarget:SetAttribute("LastKiHitBy", p2.UserId)
	g.kiTarget:SetAttribute("LastKiHit", os.clock())
	result.gateOpened = waitFor(function()
		return g.gate:GetAttribute("State") == "open"
	end, 2)
	task.wait(0.3)
	result.teamworkCredit = `{credited[p1] or 0}/{credited[p2] or 0}`
	result.teamworkOk = credited[p1] == 1 and credited[p2] == 1

	result.ok = result.started
		and result.guardAbsorbed
		and result.guardKeptPlace
		and result.guardConsumed
		and result.eliminated
		and result.winnerIsAttacker
		and result.eliminatedCantPush
		and result.isDraw
		and result.canSpendWithCharge
		and result.cantSpendWithout
		and result.echoBurstMoved > 5
		and result.echoSpent
		and result.echoSecondSpendFails
		and result.resetClears
		and result.gateOpened
		and result.teamworkOk
	return result
end
