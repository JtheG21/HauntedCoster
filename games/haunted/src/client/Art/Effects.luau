--!strict
-- Cosmetic effects (TASK-0047/0050): aura emitters around a creature and short capture bursts. Client-only and
-- purely visual; built-in particle textures only (no uploads). Effect intensity is capped so auras stay readable
-- beside the natural variant cues and cheap with a full pen.

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local Effects = {}

local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local function emitter(parent: Instance, props: { [string]: any }): ParticleEmitter
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 0.6
	e.LightInfluence = 0.2
	e.Rate = 4
	for k, v in props do
		(e :: any)[k] = v
	end
	e.Parent = parent
	return e
end

-- An aura on `root` (an Attachment the caller owns): "motes", "mist" or "moths".
function Effects.aura(root: BasePart, look: { [string]: any }, scale: number?): Attachment
	local s = scale or 1
	local a = Instance.new("Attachment")
	a.Name = "CosmeticAura"
	a.Parent = root
	local color: Color3 = look.color or Color3.new(1, 1, 1)
	local rate = math.min(look.rate or 4, 8)
	if look.effect == "mist" then
		emitter(a, {
			Texture = SMOKE,
			Color = ColorSequence.new(color),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.7),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Size = NumberSequence.new(2.2 * s, 3.4 * s),
			Lifetime = NumberRange.new(2.5, 3.5),
			Speed = NumberRange.new(0.2, 0.6),
			SpreadAngle = Vector2.new(180, 20),
			Acceleration = Vector3.new(0, -0.4, 0),
			Rate = rate,
			LightEmission = 0.2,
		})
	elseif look.effect == "moths" then
		emitter(a, {
			Texture = SPARK,
			Color = ColorSequence.new(color),
			Size = NumberSequence.new(0.25 * s),
			Lifetime = NumberRange.new(2, 3),
			Speed = NumberRange.new(1.2, 2),
			SpreadAngle = Vector2.new(180, 180),
			RotSpeed = NumberRange.new(-180, 180),
			Drag = 1.5,
			Rate = rate,
			LightEmission = 0.3,
		})
	else -- motes
		emitter(a, {
			Texture = SPARK,
			Color = ColorSequence.new(color),
			Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.3, 0.35 * s),
				NumberSequenceKeypoint.new(1, 0),
			}),
			Lifetime = NumberRange.new(1.5, 2.5),
			Speed = NumberRange.new(0.4, 1),
			SpreadAngle = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, 0.6, 0),
			Rate = rate,
		})
	end
	return a
end

-- A short capture burst at `position`: "sparks", "bats" or "chains". Cleans itself up.
function Effects.burst(position: Vector3, look: { [string]: any })
	local holder = Instance.new("Part")
	holder.Name = "CaptureEffect"
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.new(0.2, 0.2, 0.2)
	holder.CFrame = CFrame.new(position + Vector3.new(0, 2, 0))
	holder.Parent = Workspace
	local color: Color3 = look.color or Color3.new(1, 1, 1)
	local e
	if look.effect == "bats" then
		e = emitter(holder, {
			Texture = FIRE,
			Color = ColorSequence.new(color),
			LightEmission = 0,
			Size = NumberSequence.new(0.7, 0.3),
			Lifetime = NumberRange.new(0.8, 1.4),
			Speed = NumberRange.new(10, 16),
			SpreadAngle = Vector2.new(60, 60),
			Acceleration = Vector3.new(0, 6, 0),
			RotSpeed = NumberRange.new(-300, 300),
			Rate = 0,
		})
		e:Emit(24)
	elseif look.effect == "chains" then
		e = emitter(holder, {
			Texture = SPARK,
			Color = ColorSequence.new(color),
			Size = NumberSequence.new(0.5, 0),
			Lifetime = NumberRange.new(1, 1.6),
			Speed = NumberRange.new(3, 5),
			SpreadAngle = Vector2.new(5, 180),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular,
			Rate = 0,
		})
		e:Emit(40)
	else -- sparks
		e = emitter(holder, {
			Texture = SPARK,
			Color = ColorSequence.new(color),
			Size = NumberSequence.new(0.6, 0),
			Lifetime = NumberRange.new(0.6, 1.1),
			Speed = NumberRange.new(8, 14),
			SpreadAngle = Vector2.new(180, 180),
			Drag = 3,
			Rate = 0,
		})
		e:Emit(36)
	end
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 2
	light.Parent = holder
	Debris:AddItem(holder, 2.5)
end

return Effects
