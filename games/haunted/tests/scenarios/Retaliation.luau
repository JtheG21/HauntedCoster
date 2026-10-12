--!strict
-- Failed-capture retaliation (TASK-0031 AC1-AC3, ADR-0007 "final miss only"; TASK-0032), on the pinned Cemetery:
--  * the last miss turns the target (and up to 2 neighbours within 30 studs) on the failing player only,
--  * a pursuer that reaches the player knocks them down briefly with no health loss, then gives up; the
--    player can move again afterwards,
--  * the pursuit ends (timeout) and every pursuer roams again; a capture start on a pursuer is refused,
--  * the survivor's counters for that player are cleared, so a retry on it starts fresh,
--  * just outside the hub edge (within the give-up distance) the pursuers stay inside the habitat
--    footprint; running further ends the pursuit,
--  * an error in the pursuit tick ends every pursuit and the loop keeps running,
--  * a habitat swap ends a pursuit at once, and so does the player's death.
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
	-- A free monster inside the hub (at least `minR` studs from its centre), with the player put 6 studs
	-- from it and a capture session opened, then failed on its last miss. `seed` first leaves saved counters
	-- on it, as an earlier walk-away would.
	local function failACapture(minR: number?, seed: boolean?): any
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
					and World.hubDistance(p.X, p.Z) >= (minR or 0)
				then
					tp(Vector3.new(p.X + 6, 0, p.Z))
					if seed then
						e.progress[player] = { hits = 0, misses = 1 }
					end
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
	-- Pursuers (of an earlier pursuit) still chasing someone or with Inspect off.
	local function stuckOf(list: { any }): number
		local stuck = 0
		for _, e in list do
			local inspect = e.root:FindFirstChild("Inspect")
			local off = inspect ~= nil and inspect:IsA("ProximityPrompt") and not inspect.Enabled
			if e.alive and (e.pursuing ~= nil or off) then
				stuck += 1
			end
		end
		return stuck
	end

	-- 1. The last miss starts a pursuit ------------------------------------------------------------------
	local health0 = humanoid.Health
	local target = failACapture(nil, true)
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
	check("the player's saved counters on the target were cleared", target.progress[player] == nil)
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

	-- 3. The pursuit ends, everyone roams again, and a retry on the survivor starts fresh -------------------
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
		task.wait(2.1)
		tp(target.root.Position + Vector3.new(6, 0, 0))
		local retry = CaptureService.startForTest(player, target.model)
		check(
			"a retry on the survivor starts at 0 hits and 0 misses",
			retry.ok and retry.hits == 0 and retry.misses == 0,
			`{retry.ok} {retry.reason} {retry.hits}/{retry.misses}`
		)
		if retry.ok then
			CaptureService.requestCancel(player)
		end
	end

	-- 4. Just outside the hub edge the pursuers stay inside the footprint; further away, they give up ------
	task.wait(2.1)
	local second = failACapture(70)
	check("a second pursuit started", second ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if second then
		-- Straight to the edge with no yield since the pursuit began, so nobody is caught on the way.
		local mine = RetaliationService.pursuersOf(player)
		local sp = second.root.Position
		tp(Vector3.new(sp.X, 0, sp.Z).Unit * (World.Hub.wallRadius + 7)) -- on the ring road, past the wall
		task.wait(3)
		local inside, farthest, closest = true, 0, math.huge
		for _, e in mine do
			if e.alive then
				local d = World.hubDistance(e.root.Position.X, e.root.Position.Z)
				farthest = math.max(farthest, d)
				inside = inside and d <= World.Hub.moduleRadius + 0.5
				closest = math.min(closest, (e.root.Position - root.Position).Magnitude)
			end
		end
		check(
			"still chased at the edge (within the give-up distance)",
			#RetaliationService.pursuersOf(player) > 0 and closest <= Monsters.Retaliation.giveUpDistance,
			math.floor(closest)
		)
		check("pursuers never leave the habitat footprint", inside, `farthest {math.floor(farthest)}`)
		tp(World.plotToWorld(PlotService.plotIndex(player) or 1, World.Plot.spawn))
		task.wait(1)
		check("outrunning them ends the pursuit", #RetaliationService.pursuersOf(player) == 0)
	end

	-- 5. An error in the pursuit tick ends every pursuit -----------------------------------------------------
	task.wait(2.1)
	local third = failACapture()
	check("a third pursuit started", third ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if third then
		-- No yield since the pursuit began, so the failing tick is its first one (nothing caught yet).
		local mine = RetaliationService.pursuersOf(player)
		local errors0 = RetaliationService.tickErrorCount()
		RetaliationService.failNextTickForTest()
		task.wait(0.6)
		check("the tick error was caught", RetaliationService.tickErrorCount() == errors0 + 1)
		check("a tick error ends the pursuit", #RetaliationService.pursuersOf(player) == 0)
		local stuck = stuckOf(mine)
		check("no pursuer is stuck after the error (roaming, inspectable)", stuck == 0, stuck)
	end

	-- 6. The loop survived the error: a new pursuit starts, and a habitat swap ends it at once ---------------
	task.wait(2.1)
	local fourth = failACapture()
	check("a pursuit starts after the tick error", fourth ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if fourth then
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

	-- 7. Death ends a pursuit (last: the character respawns) ------------------------------------------------
	task.wait(2.1)
	local fifth = failACapture()
	check("a pursuit started before death", fifth ~= nil and #RetaliationService.pursuersOf(player) > 0)
	if fifth then
		local mine = RetaliationService.pursuersOf(player)
		humanoid.Health = 0
		task.wait(0.6)
		check("death ends the pursuit", #RetaliationService.pursuersOf(player) == 0)
		local stuck = stuckOf(mine)
		check("no pursuer keeps chasing after death", stuck == 0, stuck)
	end
	return finish()
end
