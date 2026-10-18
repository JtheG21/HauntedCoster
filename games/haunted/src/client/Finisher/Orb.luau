--!strict
-- The release phase's orb: it fades in, orbits the monster (spinning up and tightening exponentially while
-- the plane tumbles on all three axes), then leaves the orbit along its own tangent, keeping its speed and
-- direction, and curves into the target with an impact burst. A pulsing core on the monster and a wind ring
-- tighten with the orbit. Everything it creates is removed by the returned undo.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage.Shared.Config.FinisherAssets)
local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local Meshes = require(script.Parent.Meshes)
local Util = require(script.Parent.Util)

local Orb = {}

type Ctx = Util.Ctx

local FADE_IN = 0.45 -- seconds the orb takes to appear
local ARRIVE_SPEED = 2.2 -- exit speed into the target, as a multiple of the straight-line distance per curve
local CORE_PULSE_HZ = 2.5
local TRAIL_HALF_WIDTH = 0.28 -- of the orb's size: a slim ribbon, not a slab
local SNAP_TRAIL_LIFETIME = 0.14 -- seconds; short, so the break-off streaks instead of smearing

function Orb.start(ctx: Ctx, cue: Sequence.Cue): () -> ()
	local p: { [string]: any } = cue.params or {}
	local tint = Util.color(p.color)
	local orbitTime: number = p.orbitTime or 3.3
	local snapTime: number = p.snapTime or 0.55
	local center = ctx.anchor.Position + Vector3.new(0, FinisherRules.CENTER_HEIGHT, 0)

	local orb = Instance.new("Part")
	orb.Name = "FinisherOrb"
	orb.Shape = Enum.PartType.Ball
	orb.Anchored = true
	orb.CanCollide = false
	orb.CanQuery = false
	orb.Material = Enum.Material.Neon
	orb.Color = tint
	orb.Transparency = 1
	orb.Size = Vector3.new(FinisherRules.ORBIT.size0, FinisherRules.ORBIT.size0, FinisherRules.ORBIT.size0)

	local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
	a0.Parent, a1.Parent = orb, orb
	local trail = Instance.new("Trail")
	trail.Attachment0, trail.Attachment1 = a0, a1
	trail.FaceCamera = true
	trail.Color = ColorSequence.new(tint)
	trail.LightEmission = 1
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
	trail.Enabled = false -- on after the fade-in, so it never draws a streak from the spawn point
	trail.Parent = orb

	local _, orbGlow = Util.billboard(orb, Assets.Textures.sparkle, tint)
	local orbGui = orbGlow.Parent :: BillboardGui
	orbGlow.ImageTransparency = 1
	-- sparkle has a real alpha channel; the glow texture has an opaque dark background that shows as a box
	-- on a billboard (billboards cannot be additive like particles), so it is only used on emitters
	local coreGui, core = Util.billboard(ctx.anchor, Assets.Textures.sparkle, tint)
	core.ImageTransparency = 1

	local wind = Meshes.get("windRing", tint, 1)
	if wind then
		wind.Parent = ctx.fx
	end

	TweenService:Create(orb, TweenInfo.new(FADE_IN), { Transparency = 0 }):Play()
	TweenService:Create(orbGlow, TweenInfo.new(FADE_IN), { ImageTransparency = 0.1 }):Play()
	TweenService:Create(core, TweenInfo.new(FADE_IN), { ImageTransparency = 0.35 }):Play()
	task.delay(FADE_IN, function()
		trail.Enabled = true
	end)

	local function orbitPos(t: number): Vector3
		local o = FinisherRules.orbit(t, orbitTime)
		return center + Vector3.new(o.x, o.y, o.z)
	end

	local function place(t: number)
		local o = FinisherRules.orbit(t, orbitTime)
		orb.Position = center + Vector3.new(o.x, o.y, o.z)
		local s = o.size
		orb.Size = Vector3.new(s, s, s)
		a0.Position = Vector3.new(0, s * TRAIL_HALF_WIDTH, 0)
		a1.Position = Vector3.new(0, -s * TRAIL_HALF_WIDTH, 0)
		trail.Lifetime = 0.2 + 0.4 * o.u
		orbGui.Size = UDim2.fromScale(s * 2.6, s * 2.6)
		orbGlow.Rotation = (t * 160) % 360
		-- the core swells and quickens as the orbit tightens
		local pulse = 1 + 0.12 * math.sin(t * math.pi * 2 * CORE_PULSE_HZ * (1 + 2 * o.u))
		local coreSize = (4 + 5 * FinisherRules.smoothstep(o.u)) * pulse
		coreGui.Size = UDim2.fromScale(coreSize, coreSize)
		if wind then
			local d = o.radius * 2.2
			wind.Size = Vector3.new(d, 0.4 + 2.4 * (o.radius / FinisherRules.ORBIT.r0), d)
			wind.CFrame = CFrame.new(center)
				* CFrame.Angles(0, 0, o.az)
				* CFrame.Angles(0, o.ay, 0)
				* CFrame.Angles(o.ax, 0, 0)
				* CFrame.Angles(math.pi / 2, 0, 0)
				* CFrame.Angles(0, t * 5, 0)
			wind.Transparency = 0.75 - 0.3 * o.u
		end
	end

	-- break-off state, set once when the orbit ends
	local started = os.clock()
	local launch: { p0: Vector3, m0: Vector3, m1: Vector3, startSize: number }? = nil
	local arrived = false

	local function emitAt(texture: string, count: number, size: number, speed: NumberRange, life: number)
		local e = Util.emitter(orb, tint, texture, 0, speed, NumberRange.new(life, life), size)
		e:Emit(count)
	end

	local function startBreakOff()
		local p0 = orb.Position
		trail.Lifetime = SNAP_TRAIL_LIFETIME
		-- velocity on the orbit at the last instant, so the exit keeps its speed and direction
		local v0 = (orbitPos(orbitTime) - orbitPos(orbitTime - 1 / 60)) * 60
		local toTarget = ctx.destination - p0
		launch = {
			p0 = p0,
			m0 = v0 * snapTime,
			m1 = toTarget * ARRIVE_SPEED,
			startSize = orb.Size.X,
		}
		emitAt(
			Assets.Textures.sparkle,
			math.floor(FinisherRules.scale("rate", 30, ctx.reduced)),
			1.2,
			NumberRange.new(15, 35),
			0.4
		)
		emitAt(Assets.Textures.radialBurst, 1, 18, NumberRange.new(0, 0), 0.35)
		if wind then
			TweenService:Create(wind, TweenInfo.new(0.2), { Transparency = 1 }):Play()
		end
		TweenService:Create(core, TweenInfo.new(snapTime), { ImageTransparency = 1 }):Play()
	end

	local function arrive()
		arrived = true
		orb.Position = ctx.destination
		orb.Transparency = 1
		orbGlow.ImageTransparency = 1
		trail.Enabled = false
		-- impact at the target
		emitAt(
			Assets.Textures.sparkle,
			math.floor(FinisherRules.scale("rate", 36, ctx.reduced)),
			1.6,
			NumberRange.new(8, 22),
			0.6
		)
		emitAt(Assets.Textures.radialBurst, 1, 24, NumberRange.new(0, 0), 0.4)
	end

	place(0)
	orb.Parent = ctx.fx
	local conn = RunService.Heartbeat:Connect(function()
		local t = os.clock() - started
		if t <= orbitTime then
			place(t)
			return
		end
		if arrived then
			return
		end
		if not launch then
			startBreakOff()
		end
		local l = launch :: any
		local k = (t - orbitTime) / snapTime
		if k >= 1 then
			arrive()
			return
		end
		local d = ctx.destination
		orb.Position = Vector3.new(
			FinisherRules.hermite(l.p0.X, l.m0.X, d.X, l.m1.X, k),
			FinisherRules.hermite(l.p0.Y, l.m0.Y, d.Y, l.m1.Y, k),
			FinisherRules.hermite(l.p0.Z, l.m0.Z, d.Z, l.m1.Z, k)
		)
		local s = l.startSize + (0.9 - l.startSize) * FinisherRules.smoothstep(k)
		orb.Size = Vector3.new(s, s, s)
		orbGui.Size = UDim2.fromScale(s * 2.6, s * 2.6)
	end)

	return function()
		conn:Disconnect()
		orb:Destroy()
		coreGui:Destroy()
		if wind then
			wind:Destroy()
		end
	end
end

return Orb
