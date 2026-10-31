--!strict
-- Global lighting and atmosphere, shared by the outer world and every habitat (TASK-0028, ADR-0007): a
-- violet twilight sky with stars, readable ground without the flashlight, and no global colour tint.
-- The engine's Atmosphere colours both the sky and the distance haze, so the sky carries the purple and
-- the green comes from low ground mist in each habitat (Kit.mist) - the look of map reference 3.
-- Built-in only (no uploaded sky textures). Values were tuned with Studio captures (TEST-20261012-04).

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

Atmosphere.Config = {
	clockTime = 19.2, -- just after sunset: no orange sunlight, sky still lit
	brightness = 1.4,
	ambient = Color3.fromRGB(90, 82, 115),
	outdoorAmbient = Color3.fromRGB(150, 160, 185), -- what keeps paths readable without the flashlight
	environmentDiffuse = 0.4,
	environmentSpecular = 0.2,
	haze = {
		density = 0.3,
		offset = 0.45,
		color = Color3.fromRGB(135, 85, 210), -- the purple sky and horizon
		decay = Color3.fromRGB(80, 40, 140),
		glare = 0,
		haze = 2.2,
	},
	starCount = 3000,
}

local function child<T>(className: string): T
	local existing = Lighting:FindFirstChildOfClass(className)
	if existing then
		return existing :: any
	end
	local inst = Instance.new(className :: any)
	inst.Parent = Lighting
	return inst :: any
end

function Atmosphere.apply()
	local c = Atmosphere.Config
	Lighting.ClockTime = c.clockTime
	Lighting.Brightness = c.brightness
	Lighting.Ambient = c.ambient
	Lighting.OutdoorAmbient = c.outdoorAmbient
	Lighting.EnvironmentDiffuseScale = c.environmentDiffuse
	Lighting.EnvironmentSpecularScale = c.environmentSpecular
	local atm: Atmosphere = child("Atmosphere")
	atm.Density = c.haze.density
	atm.Offset = c.haze.offset
	atm.Color = c.haze.color
	atm.Decay = c.haze.decay
	atm.Glare = c.haze.glare
	atm.Haze = c.haze.haze
	local sky: Sky = child("Sky")
	sky.CelestialBodiesShown = false
	sky.StarCount = c.starCount
	-- Neutral grade: a little contrast, no tint (the look must not come from a global colour wash).
	local cc: ColorCorrectionEffect = child("ColorCorrectionEffect")
	cc.TintColor = Color3.new(1, 1, 1)
	cc.Saturation = 0
	cc.Contrast = 0.1
end

return Atmosphere
