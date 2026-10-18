--!strict
-- Rare capture finisher player (TASK-0054): maps the finisher sequence's cues onto camera, lighting and
-- particle effects through SequencePlayer (ADR-0012). Cosmetic and client-side only; the runner always
-- undoes every cue, so the camera, input and lighting return to normal on finish, cancel or error.

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Finisher = require(ReplicatedStorage.Shared.Config.RareCaptureFinisher)
local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local SequencePlayer = require(script.Parent.SequencePlayer)

local RareCaptureFinisher = {}

export type Options = { reduced: boolean?, destination: Vector3?, onDone: (() -> ())? }

local LOCKED_ACTIONS = {
	Enum.PlayerActions.CharacterForward,
	Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump,
}

local function color(c: any): Color3
	return Color3.new(c[1], c[2], c[3])
end

local function emitter(
	parent: Instance,
	c: Color3,
	rate: number,
	speed: NumberRange,
	life: NumberRange,
	size: number
): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(c)
	p.LightEmission = 0.7
	p.Lifetime = life
	p.Speed = speed
	p.SpreadAngle = Vector2.new(180, 180)
	p.Size = NumberSequence.new(size, 0)
	p.Rate = rate
	p.Parent = parent
	return p
end

-- Camera rig: every active camera cue contributes; the latest one with a position decides where the
-- camera sits, the latest with a fov sets the field of view, shakes add up. Restores the camera when
-- the last camera cue stops.
local function makeCameraRig(target: BasePart, reduced: boolean)
	local active: { { id: string, startedAt: number, p: { [string]: any } } } = {}
	local conn: RBXScriptConnection? = nil
	local saved: { type: Enum.CameraType, fov: number }? = nil
	local fov = 70

	local function step(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam or #active == 0 then
			return
		end
		local now = os.clock()
		local posCue, fovCue
		local shake = 0
		for _, a in active do
			if a.p.pos then
				posCue = a
			end
			if a.p.fov then
				fovCue = a
			end
			shake += FinisherRules.scale("shake", a.p.shake or 0, reduced)
		end
		local focus = target.Position + Vector3.new(0, 3, 0)
		if posCue then
			local p = posCue.p
			local angle = (now - posCue.startedAt) * 0.5
			local pos
			if p.pos == "low" then
				pos = target.Position + Vector3.new(math.cos(angle) * p.radius, 1.5, math.sin(angle) * p.radius)
			else
				pos = target.Position
					+ Vector3.new(math.cos(angle) * p.radius, p.height or 5, math.sin(angle) * p.radius)
			end
			local offset = Vector3.new(math.noise(now * 20, 1), math.noise(now * 20, 2), math.noise(now * 20, 3))
				* shake
			cam.CFrame = CFrame.lookAt(pos + offset, focus)
		end
		if fovCue then
			local goal = FinisherRules.fov(70, fovCue.p.fov, reduced)
			fov += (goal - fov) * math.min(1, dt * 3)
			cam.FieldOfView = fov
		end
	end

	return function(cue: Sequence.Cue): (() -> ())?
		local cam = Workspace.CurrentCamera
		if not cam or not RunService:IsClient() then
			return nil
		end
		if not saved then
			saved = { type = cam.CameraType, fov = cam.FieldOfView }
			fov = cam.FieldOfView
			cam.CameraType = Enum.CameraType.Scriptable
			conn = RunService.RenderStepped:Connect(step)
		end
		local entry = { id = cue.id, startedAt = os.clock(), p = (cue.params or {}) :: { [string]: any } }
		table.insert(active, entry)
		return function()
			local i = table.find(active, entry)
			if i then
				table.remove(active, i)
			end
			if #active == 0 and saved then
				if conn then
					conn:Disconnect()
					conn = nil
				end
				cam.CameraType = saved.type
				cam.FieldOfView = saved.fov
				saved = nil
			end
		end
	end
end

local function makeEffects(fx: Folder, anchor: BasePart, destination: Vector3, reduced: boolean): SequencePlayer.Handler
	return function(cue)
		local p: { [string]: any } = cue.params or {}
		local kind = p.effect
		if kind == "lock" then
			if not RunService:IsClient() then
				return nil
			end
			ContextActionService:BindActionAtPriority("FinisherLock", function()
				return Enum.ContextActionResult.Sink
			end, false, 3000, table.unpack(LOCKED_ACTIONS))
			return function()
				ContextActionService:UnbindAction("FinisherLock")
			end
		elseif kind == "tint" then
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "FinisherTint_" .. cue.id
			cc.Parent = Lighting
			TweenService:Create(cc, TweenInfo.new(0.6), { TintColor = color(p.color), Brightness = p.brightness or 0 })
				:Play()
			return function()
				cc:Destroy()
			end
		elseif kind == "flash" then
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "FinisherFlash_" .. cue.id
			cc.Parent = Lighting
			local peak = FinisherRules.scale("flash", p.strength or 0.5, reduced)
			TweenService:Create(cc, TweenInfo.new(0.08), { Brightness = peak }):Play()
			task.delay(0.1, function()
				if cc.Parent then
					TweenService:Create(cc, TweenInfo.new(0.22), { Brightness = 0 }):Play()
				end
			end)
			return function()
				cc:Destroy()
			end
		elseif kind == "aura" then
			local e = emitter(
				fx,
				color(p.color),
				FinisherRules.scale("rate", p.rate or 20, reduced),
				NumberRange.new(2, 8),
				NumberRange.new(0.8, 1.6),
				0.8
			)
			e.Parent = anchor
			return function()
				e:Destroy()
			end
		elseif kind == "sparks" then
			local e = emitter(
				anchor,
				Color3.fromRGB(190, 230, 255),
				FinisherRules.scale("rate", p.rate or 30, reduced),
				NumberRange.new(20, 45),
				NumberRange.new(0.15, 0.35),
				0.4
			)
			return function()
				e:Destroy()
			end
		elseif kind == "burst" then
			local e = emitter(anchor, color(p.color), 0, NumberRange.new(10, 26), NumberRange.new(0.6, 1.2), 1)
			e:Emit(math.floor(FinisherRules.scale("rate", p.count or 40, reduced)))
			return function()
				e:Destroy()
			end
		elseif kind == "pillar" then
			local pillar = Instance.new("Part")
			pillar.Name = "FinisherPillar"
			pillar.Anchored = true
			pillar.CanCollide = false
			pillar.CanQuery = false
			pillar.Material = Enum.Material.Neon
			pillar.Color = Color3.new(1, 1, 1)
			pillar.Transparency = 1
			pillar.Size = Vector3.new(5, p.height or 60, 5)
			pillar.Position = anchor.Position + Vector3.new(0, (p.height or 60) / 2, 0)
			local light = Instance.new("PointLight")
			light.Range = 40
			light.Brightness = 4
			light.Parent = pillar
			pillar.Parent = fx
			TweenService:Create(pillar, TweenInfo.new(0.5), { Transparency = 0.35 }):Play()
			return function()
				pillar:Destroy()
			end
		elseif kind == "orb" then
			local orb = Instance.new("Part")
			orb.Name = "FinisherOrb"
			orb.Shape = Enum.PartType.Ball
			orb.Anchored = true
			orb.CanCollide = false
			orb.CanQuery = false
			orb.Material = Enum.Material.Neon
			orb.Color = color(p.color)
			orb.Size = Vector3.new(4, 4, 4)
			orb.Position = anchor.Position + Vector3.new(0, 6, 0)
			orb.Parent = fx
			TweenService:Create(
				orb,
				TweenInfo.new(3.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ Position = destination, Size = Vector3.new(0.6, 0.6, 0.6) }
			):Play()
			return function()
				orb:Destroy()
			end
		end
		return nil
	end
end

-- Builds the finisher around `target` (the captured monster's position) without starting it. Call
-- :play() to run it from Heartbeat, or :step(dt) to drive it by hand. :stop() cancels and cleans up.
function RareCaptureFinisher.new(target: BasePart, opts: Options?): SequencePlayer.Player
	local o: Options = opts or {}
	local reduced = o.reduced == true
	local fx = Instance.new("Folder")
	fx.Name = "FinisherFx"
	fx.Parent = Workspace
	local anchor = Instance.new("Part")
	anchor.Name = "FinisherAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = target.Position
	anchor.Parent = fx
	local destination = o.destination or (target.Position + Vector3.new(0, 1.5, 12))
	local handlers: SequencePlayer.Handlers = {
		camera = makeCameraRig(target, reduced),
		effect = makeEffects(fx, anchor, destination, reduced),
	}
	return SequencePlayer.new(Finisher, handlers, function()
		fx:Destroy()
		if o.onDone then
			o.onDone()
		end
	end)
end

function RareCaptureFinisher.play(target: BasePart, opts: Options?): SequencePlayer.Player
	local player = RareCaptureFinisher.new(target, opts)
	player:play()
	return player
end

return RareCaptureFinisher
