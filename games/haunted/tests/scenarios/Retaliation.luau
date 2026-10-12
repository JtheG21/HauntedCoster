--!strict
-- Failed-capture retaliation (TASK-0031 AC1-AC3, ADR-0007 "final miss only"), on the pinned Cemetery:
--  * the last miss turns the target (and up to 2 neighbours within 30 studs) on the failing player only,
--  * a pursuer that reaches the player knocks them down briefly with no health loss, then gives up; the
--    player can move again afterwards,
--  * the pursuit ends (timeout) and every pursuer roams again; a capture start on a pursuer is refused,
--  * a habitat swap ends a pursuit at once, and running out of the hub leaves the pursuers inside it.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "Retaliation" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Monsters = require(ReplicatedStorage.Shared.Config.Monsters)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local CaptureService = require(Services.CaptureService) :: any
local EncounterService = require(Services.EncounterService) :: any
local HabitatService = require(Services.HabitatService) :: any
local RetaliationService = require(Services.RetaliationService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local function finish()
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
	end

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	PlayerDataService.waitFor(player, 30)
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	task.wait(3)

	local function tp(pos: Vector3)
		CaptureService.noteTeleport(player)
		character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
		task.wait(0.3)
	end
	-- A free monster inside the hub, with the player put 6 studs from it and a capture session opened.
	local function failACapture(): any
		local folder = Workspace:FindFirstChild("Monsters")
		for _ = 1, 6 do
			for _, m in (folder and folder:GetChildren() or {}) do
				local e = EncounterService.get(m)
				local p = e and e.root.Position
				if
					e
					and p
					and e.alive
					and not e.claimedBy
					and not e.fleeing
					and not e.pursuing
					and not EncounterService.isStartled(e)
					and World.inHub(p.X, p.Z)
				then
					tp(Vector3.new(p.X + 6, 0, p.Z))
					local r = CaptureService.startForTest(player, m)
					if r.ok and CaptureService.failForTest(player) then
						return e
					end
					task.wait(2.1) -- the start remote allows 2 per 4 s
				end
			end
			task.wait(1)
		end
		return nil
	end

	-- 1. The last miss starts a pursuit ------------------------------------------------------------------
	local health0 = humanoid.Health
	local target = failACapture()
	check("a capture was failed on its last miss", target ~= nil)
	if not target then
		return finish()
	end
	local pursuers = RetaliationService.pursuersOf(player)
	check("the target turns on the player (it isn't removed)", target.alive and pursuers[1] == target, #pursuers)
	check(
		`at most {1 + Monsters.Retaliation.maxExtra} pursuers`,
		#pursuers >= 1 and #pursuers <= 1 + Monsters.Retaliation.maxExtra,
		#pursuers
	)
	local allMine, allNear = true, true
	for i, e in pursuers do
		allMine = allMine and e.pursuing == player
		if i > 1 then
			local d = Vector3.new(e.root.Position.X - root.Position.X, 0, e.root.Position.Z - root.Position.Z).Magnitude
			allNear = allNear and d <= Monsters.Retaliation.radius + 2
		end
	end
	check("every pursuer targets only the failing player", allMine)
	check("extra pursuers were within the join radius", allNear)
	local refused = CaptureService.startForTest(player, target.model)
	check("a charging monster can't be captured", not refused.ok, refused.reason)

	-- 2. Standing still: caught, knocked down without damage, back on their feet ----------------------------
	local knocks0 = RetaliationService.knockCount()
	local w0 = os.clock()
	while RetaliationService.knockCount() == knocks0 and os.clock() - w0 < Monsters.Retaliation.seconds do
		task.wait(0.1)
	end
	check("a pursuer reached the player and knocked them down", RetaliationService.knockCount() > knocks0)
	check("knocked down right now", RetaliationService.isKnockedDown(player))
	check("no health lost", humanoid.Health == health0, `{health0} -> {humanoid.Health}`)
	local gaveUp = 0
	for _, e in pursuers do
		if e.pursuing == nil then
			gaveUp += 1
		end
	end
	check("the pursuer that caught them gave up", gaveUp >= 1, gaveUp)
	task.wait(Monsters.Retaliation.knockdownSeconds + 0.6)
	check("the knockdown is over", not RetaliationService.isKnockedDown(player))
	-- Walk away with a server-side MoveTo, as the Reachability walk does.
	local before = root.Position
	humanoid:MoveTo(before + Vector3.new(0, 0, -12))
	task.wait(2.5)
	check(
		"the player can move again",
		(root.Position - before).Magnitude > 4,
		math.floor((root.Position - before).Magnitude)
	)

	-- 3. The pursuit ends and everyone roams again ----------------------------------------------------------
	w0 = os.clock()
	while #RetaliationService.pursuersOf(player) > 0 and os.clock() - w0 < Monsters.Retaliation.seconds + 2 do
		task.wait(0.2)
	end
	check("the pursuit ended", #RetaliationService.pursuersOf(player) == 0)
	local stillPursuing = 0
	for _, e in pursuers do
		if e.alive and e.pursuing ~= nil then
			stillPursuing += 1
		end
	end
	check("no pursuer is left chasing (no state leak)", stillPursuing == 0, stillPursuing)
	if target.alive then
		local p0 = target.root.Position
		task.wait(5)
		check("the target roams again", target.pursuing == nil and (target.root.Position - p0).Magnitude > 0.5)
	end

	-- 4. Running out of the hub: pursuers stay inside, and the pursuit ends -------------------------------
	task.wait(2.1)
	local second = failACapture()
	check("a second pursuit started", second ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if second then
		local mine = RetaliationService.pursuersOf(player)
		tp(World.plotToWorld(PlotService.plotIndex(player) or 1, World.Plot.spawn))
		task.wait(2)
		local inside = true
		for _, e in mine do
			if e.alive then
				inside = inside and World.inHub(e.root.Position.X, e.root.Position.Z)
			end
		end
		check("pursuers never leave the habitat", inside)
		check("outrunning them ends the pursuit", #RetaliationService.pursuersOf(player) == 0)
	end

	-- 5. A habitat swap ends a pursuit at once -----------------------------------------------------------
	task.wait(2.1)
	local third = failACapture()
	check("a third pursuit started", third ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if third then
		HabitatService.activate("Woodland")
		check("a swap ends the pursuit", #RetaliationService.pursuersOf(player) == 0)
		local leaked = 0
		for _, e in EncounterService.snapshot() do
			if e.claimed then
				leaked += 1
			end
		end
		check("no claim or pursuit left after the swap", leaked == 0, leaked)
		HabitatService.activate("Cemetery")
	end
	return finish()
end
