--!strict
-- Habitat rotation and capture-safe swaps (TASK-0029 AC2-AC6, ADR-0007 "evacuate to the gates"), on a
-- fast schedule passed as a test argument (30 s slots, warning at 12 s, closing at 6 s, slot 0 now):
--   swap 1 (Cemetery -> Woodland): the player carries a capture inside the hub. The carry survives
--          unchanged, the player is moved outside a gate, and securing adds exactly one monster. Captures
--          are refused while closing and allowed again after the swap.
--   swap 2 (Woodland -> Spider Woodland): an open meter session is cancelled; nothing is created and no
--          claim is left behind.
--   swap 3 (Spider Woodland -> Settlement): an escaped capture is being chased in the hub. It follows the
--          player out, the chase continues, and grabbing it gives the carry back (no duplicate).
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "HabitatRotation",
--       rotation = { slotSeconds = 30, warningSeconds = 12, closingSeconds = 6, startNow = true } })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local HabitatState = require(ReplicatedStorage.Shared.HabitatState)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local CaptureService = require(Services.CaptureService) :: any
local EncounterService = require(Services.EncounterService) :: any
local HabitatService = require(Services.HabitatService) :: any
local RotationService = require(Services.RotationService) :: any

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
	local profile = PlayerDataService.waitFor(player, 30)
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	local plotIndex = PlotService.plotIndex(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	check(
		"rotation is running on the test schedule",
		RotationService.config().slotSeconds == 30,
		RotationService.config().slotSeconds
	)
	if not profile or not plotIndex then
		check("profile and plot", false)
		return finish()
	end

	local function tp(pos: Vector3)
		CaptureService.noteTeleport(player)
		character:PivotTo(CFrame.new(pos + Vector3.new(0, 3, 0)))
		task.wait(0.3)
	end
	local function inHub(): boolean
		return World.inHub(root.Position.X, root.Position.Z)
	end
	local function waitLeft(seconds: number)
		local w0 = os.clock()
		while RotationService.state().secondsLeft > seconds and os.clock() - w0 < 40 do
			task.wait(0.1)
		end
	end
	local function waitSwap(n: number)
		local w0 = os.clock()
		while
			(RotationService.swapCount() < n or Workspace:GetAttribute(HabitatState.Attr.fog) == true)
			and os.clock() - w0 < 40
		do
			task.wait(0.1)
		end
		task.wait(0.5)
	end
	local function aMonster(): Model?
		local folder = Workspace:FindFirstChild("Monsters")
		for _, m in (folder and folder:GetChildren() or {}) do
			local e = EncounterService.get(m)
			if e and e.alive and not e.fleeing and not e.claimedBy and not EncounterService.isStartled(e) then
				return m :: Model
			end
		end
		return nil
	end
	local function onlyActiveZones(): (boolean, string)
		local bad = {}
		for _, e in EncounterService.snapshot() do
			if not e.fleeing and not Habitats.zoneById(e.zone) then
				table.insert(bad, `{e.species}@{e.zone}`)
			end
		end
		return #bad == 0, table.concat(bad, ", ")
	end
	local inside = Vector3.new(0, 0, 40) -- on the south path, inside the hub wall in every module

	-- Swap 1: carry across the swap, evacuation, closing window ---------------------------------------
	check("starts on the Cemetery", HabitatService.activeId() == "Cemetery", HabitatService.activeId())
	waitLeft(10)
	check(
		"warning phase is published",
		Workspace:GetAttribute(HabitatState.Attr.phase) == "warning",
		Workspace:GetAttribute(HabitatState.Attr.phase)
	)
	check("next habitat is published", Workspace:GetAttribute(HabitatState.Attr.next) == "Woodland")
	waitLeft(4)
	check("closing: the server refuses new captures", CaptureService.isClosing())
	local m1 = aMonster()
	if m1 then
		tp((m1.PrimaryPart :: BasePart).Position + Vector3.new(4, 0, 0))
		local r = CaptureService.startForTest(player, m1)
		check(
			"closing: a capture start is refused with the fog reason",
			not r.ok and string.find(r.reason or "", "fog") ~= nil,
			r.reason
		)
	else
		check("closing: a monster to try", false)
	end
	tp(inside)
	CaptureService.carryForTest(player, "Wisp", "Normal")
	local before = CaptureService.carryForTestInfo(player)
	local owned0 = #profile.owned
	waitSwap(1)
	check("swap 1 lands on the Woodland", HabitatService.activeId() == "Woodland", HabitatService.activeId())
	check("swap 1: the player was moved out of the hub", not inHub(), root.Position)
	local after = CaptureService.carryForTestInfo(player)
	check(
		"swap 1: the carry is unchanged (species, variant, deadline)",
		before
			and after
			and before.species == after.species
			and before.variant == after.variant
			and before.deadlineServer == after.deadlineServer,
		after and `{after.species} {after.variant}`
	)
	local ok1, stray1 = onlyActiveZones()
	check("swap 1: only Woodland monsters remain", ok1, stray1)
	check("after the swap captures are open again", not CaptureService.isClosing())
	tp(World.plotToWorld(plotIndex, World.Plot.pen))
	CaptureService.secure(player, plotIndex)
	check(
		"securing after the swap adds exactly one monster",
		#profile.owned == owned0 + 1,
		`{owned0} -> {#profile.owned}`
	)
	check("and the carry is done", not CaptureService.isCarrying(player))
	local m2 = aMonster()
	check("a monster to try after the swap", m2 ~= nil)
	if m2 then
		tp((m2.PrimaryPart :: BasePart).Position + Vector3.new(4, 0, 0))
		task.wait(2.1) -- the start remote allows 2 per 4 s
		local r = CaptureService.startForTest(player, m2)
		check("normal play resumes: a capture can start after the swap", r.ok == true, r.reason or "ok")
		if r.ok then
			CaptureService.requestCancel(player)
		end
	end

	-- Swap 2: an open meter session -----------------------------------------------------------------
	waitLeft(11)
	local started = false
	for _ = 1, 4 do
		local m = aMonster()
		if m then
			tp((m.PrimaryPart :: BasePart).Position + Vector3.new(4, 0, 0))
			local r = CaptureService.startForTest(player, m)
			if r.ok then
				started = true
				break
			end
		end
		task.wait(2.1) -- the start remote allows 2 per 4 s
	end
	check("swap 2: a meter session is open before the swap", started and CaptureService.sessionForTest(player) ~= nil)
	local owned1 = #profile.owned
	waitSwap(2)
	check(
		"swap 2 lands on the Spider Woodland",
		HabitatService.activeId() == "SpiderWoodland",
		HabitatService.activeId()
	)
	check("swap 2: the meter session was cancelled", CaptureService.sessionForTest(player) == nil)
	check(
		"swap 2: no monster was created",
		#profile.owned == owned1 and not CaptureService.isCarrying(player),
		#profile.owned
	)
	local claimed = 0
	for _, e in EncounterService.snapshot() do
		if e.claimed and not e.fleeing then
			claimed += 1
		end
	end
	check("swap 2: no claim is left behind", claimed == 0, claimed)
	check("swap 2: the player was moved out of the hub", not inHub(), root.Position)

	-- Swap 3: a chase across the swap -----------------------------------------------------------------
	waitLeft(9)
	tp(inside)
	CaptureService.carryForTest(player, "Hound", "Normal")
	CaptureService.expireCarryForTest(player)
	local w0 = os.clock()
	while not CaptureService.isChasing(player) and os.clock() - w0 < 3 do
		task.wait(0.1)
	end
	check("swap 3: a chase is running in the hub before the swap", CaptureService.isChasing(player))
	waitSwap(3)
	check("swap 3 lands on the Settlement", HabitatService.activeId() == "Settlement", HabitatService.activeId())
	check("swap 3: the player was moved out of the hub", not inHub(), root.Position)
	local target = CaptureService.chaseTarget(player)
	local tpos = target and target.PrimaryPart and target.PrimaryPart.Position
	check("swap 3: the chase continues (not silently deleted)", CaptureService.isChasing(player) and tpos ~= nil)
	if tpos then
		check(
			"swap 3: the escaped monster followed the player out",
			not World.inHub(tpos.X, tpos.Z) and (tpos - root.Position).Magnitude < 40,
			`{math.floor((tpos - root.Position).Magnitude)} studs`
		)
		local owned2 = #profile.owned
		tp(Vector3.new(tpos.X, 0, tpos.Z))
		local grabbed = CaptureService.grab(player)
		if not grabbed then
			local p2 = CaptureService.chaseTarget(player) :: any
			if p2 and p2.PrimaryPart then
				tp(p2.PrimaryPart.Position * Vector3.new(1, 0, 1))
				grabbed = CaptureService.grab(player)
			end
		end
		check("swap 3: grabbing it gives the carry back", grabbed and CaptureService.isCarrying(player))
		check(
			"swap 3: not duplicated (one Hound carried, none added to the pen)",
			CaptureService.carriedCount("Hound") == 1 and #profile.owned == owned2,
			CaptureService.carriedCount("Hound")
		)
	end
	return finish()
end
