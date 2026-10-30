--!strict
-- Habitat rotation (TASK-0029, ADR-0007). Every server computes the schedule from UTC time
-- (RotationRules on Workspace:GetServerTimeNow()), so all servers agree without messaging. Phases:
--   open -> warning (T-60: HUD countdown) -> closing (T-15: no new captures) -> swap (T-0).
-- The swap follows jg's policy "evacuate to the gates":
--   1. the fog fades in (HabitatFog attribute; clients tween their atmosphere),
--   2. open meter sessions are cancelled (nothing was caught),
--   3. players inside the hub wall are moved just outside their nearest gate (carries are untouched),
--   4. the old module deactivates (wild monsters cleared) and the new one activates (it was validated at
--      start), then fleeing escapes follow their players out and the chase continues,
--   5. the fog lifts.
-- Phase state is mirrored to Workspace attributes (HabitatState). Studio test runs can pin the habitat or
-- pass a faster schedule; live servers always use Config/Rotation.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local Habitats = require(Shared.Config:WaitForChild("Habitats"))
local Rotation = require(Shared.Config:WaitForChild("Rotation"))
local RotationRules = require(Shared:WaitForChild("Rules"):WaitForChild("RotationRules"))
local HabitatState = require(Shared:WaitForChild("HabitatState"))
local HabitatService = require(script.Parent.HabitatService)
local CaptureService = require(script.Parent.CaptureService)
local StateService = require(script.Parent.StateService)

local RotationService = {}

local TICK = 0.25
local FOG_IN = 0.8 -- seconds of fog before the swap itself
local FOG_HOLD = 1.2 -- seconds of fog after it
local EXIT_RADIUS = World.Hub.wallRadius + 7 -- just outside the gate, on the ring road

local started = false
local config: Rotation.Config = Rotation
local swapping = false
local lastPhase: string? = nil
local swapCount = 0
local swapCallbacks: { (string, string) -> () } = {}
local failedSlot: number? = nil -- a slot whose swap failed is skipped, not retried every tick

-- The schedule now (the live config unless a Studio test run passed overrides).
function RotationService.state(now: number?): RotationRules.State
	return RotationRules.at(now or Workspace:GetServerTimeNow(), config)
end

function RotationService.config(): Rotation.Config
	return config
end

function RotationService.swapCount(): number
	return swapCount
end

function RotationService.onSwapped(fn: (string, string) -> ())
	table.insert(swapCallbacks, fn)
end

local function setPhase(phase: string, nextId: string?, swapAt: number?)
	local a = HabitatState.Attr
	Workspace:SetAttribute(a.phase, phase)
	Workspace:SetAttribute(a.next, nextId)
	Workspace:SetAttribute(a.swapAt, swapAt)
end

-- Players inside the hub wall go to just outside the nearest gate, facing away from the hub.
local function evacuate(): number
	local moved = 0
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if character and root and root:IsA("BasePart") and World.inHub(root.Position.X, root.Position.Z) then
			local best, bestDist = 1, math.huge
			for g = 1, #World.Hub.gateAngles do
				local d = (World.gatePosition(g) - root.Position).Magnitude
				if d < bestDist then
					best, bestDist = g, d
				end
			end
			local out = World.gatePoint(best, EXIT_RADIUS)
			local further = World.gatePoint(best, EXIT_RADIUS + 10)
			CaptureService.noteTeleport(player)
			character:PivotTo(CFrame.lookAt(out + Vector3.new(0, 3, 0), further + Vector3.new(0, 3, 0)))
			StateService.toast(player, "The fog rolled in and led you back out of the gates.", "info")
			moved += 1
		end
	end
	return moved
end

-- The swap itself. Runs on its own thread; the tick loop waits for it. Every step runs protected, and the
-- fog, the closing flag and the swapping flag are always reset, so a failing step can't leave the server
-- foggy or refusing captures (AUD-20261012-TASK-0029-01). Returns whether the new module is active.
function RotationService.swap(nextId: string): boolean
	if swapping or not Habitats.ById[nextId] then
		return false
	end
	swapping = true
	local fromId = HabitatService.activeId() or "?"
	Workspace:SetAttribute(HabitatState.Attr.fog, true)
	local ok, err = pcall(function()
		task.wait(FOG_IN)
		CaptureService.cancelAllSessions()
		evacuate()
		if not HabitatService.activate(nextId) then
			error(`could not activate {nextId}`)
		end
		CaptureService.followSwap()
	end)
	if ok then
		swapCount += 1
		for _, fn in swapCallbacks do
			task.spawn(fn, fromId, nextId)
		end
		task.wait(FOG_HOLD)
	else
		warn(`[RotationService] swap {fromId} -> {nextId} failed: {err}`)
	end
	Workspace:SetAttribute(HabitatState.Attr.fog, false)
	CaptureService.setClosing(false) -- the next tick recomputes it
	swapping = false
	return ok
end

local function tick()
	if swapping then
		return
	end
	local st = RotationService.state()
	if st.id ~= HabitatService.activeId() and st.slot ~= failedSlot then
		task.spawn(function()
			if not RotationService.swap(st.id) then
				failedSlot = st.slot
			end
		end)
		return
	end
	CaptureService.setClosing(st.phase == "closing")
	setPhase(st.phase, st.nextId, st.swapAt)
	if st.phase ~= lastPhase then
		lastPhase = st.phase
		if st.phase == "warning" then
			local name = Habitats.ById[st.nextId].name
			for _, player in Players:GetPlayers() do
				StateService.toast(
					player,
					`The fog is coming: the {name} replaces this hunting ground in a minute.`,
					"info"
				)
			end
		end
	end
end

-- Studio test runs only (overrides come from StudioTestHook.arg, which is nil on live servers): a faster
-- schedule, and `startNow = true` to start slot 0 (the Cemetery) at this moment.
function RotationService.configure(overrides: any?)
	local o = overrides
	if type(o) == "table" and o.startNow == true then
		o = table.clone(o)
		o.epoch = Workspace:GetServerTimeNow()
	end
	config = RotationRules.withOverrides(Rotation, o)
end

-- The habitat the schedule wants right now (for HabitatService.start).
function RotationService.scheduledId(): string
	return RotationService.state().id
end

-- `pinned`: no rotation at all (test runs that need a fixed habitat); the HUD shows no countdown.
function RotationService.start(pinned: boolean?)
	if started then
		return
	end
	started = true
	if pinned then
		CaptureService.setClosing(false)
		setPhase("pinned", nil, nil)
		return
	end
	task.spawn(function()
		while true do
			tick()
			task.wait(TICK)
		end
	end)
end

return RotationService
