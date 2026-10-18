--!strict
-- Small helpers shared by the finisher's effect modules.

local RunService = game:GetService("RunService")

local Util = {}

-- What every effect needs to know about the run it belongs to.
export type Ctx = {
	fx: Folder, -- everything an effect creates lives here; destroyed when the run ends
	anchor: BasePart, -- fixed point on the monster the effects attach to
	target: BasePart,
	destination: Vector3, -- where the orb finally lands
	reduced: boolean,
	runId: string, -- unique per run, so two runs never share a binding name
}

function Util.color(c: { number }): Color3
	return Color3.new(c[1], c[2], c[3])
end

-- A textured particle emitter. Additive (LightEmission 1) so a texture's dark or soft edge never shows
-- as a box, and the Color tints it evenly.
function Util.emitter(
	parent: Instance,
	color: Color3,
	texture: string?,
	rate: number,
	speed: NumberRange,
	life: NumberRange,
	size: number
): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(color)
	p.LightEmission = 1
	p.LightInfluence = 0
	p.Lifetime = life
	p.Speed = speed
	p.SpreadAngle = Vector2.new(180, 180)
	p.Size = NumberSequence.new(size, 0)
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Rate = rate
	if texture then
		p.Texture = texture
	end
	p.Parent = parent
	return p
end

-- Runs fn(secondsSinceStart, dt) every frame until the returned stop function is called.
function Util.every(fn: (t: number, dt: number) -> ()): () -> ()
	local started = os.clock()
	local conn = RunService.Heartbeat:Connect(function(dt)
		fn(os.clock() - started, dt)
	end)
	return function()
		conn:Disconnect()
	end
end

return Util
