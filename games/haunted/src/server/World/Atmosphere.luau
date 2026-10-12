--!strict
-- Global lighting and atmosphere, shared by the outer world and every habitat. The values are the M1
-- graveyard's; TASK-0028 tunes them to the purple-sky, green-haze, warm-light signature (ADR-0007).

local Lighting = game:GetService("Lighting")

local Atmosphere = {}

function Atmosphere.apply()
	Lighting.ClockTime = 0
	Lighting.Brightness = 1
	Lighting.Ambient = Color3.fromRGB(42, 42, 58)
	Lighting.OutdoorAmbient = Color3.fromRGB(86, 86, 118)
	Lighting.EnvironmentDiffuseScale = 0.3
	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atm = Instance.new("Atmosphere")
		atm.Density = 0.36
		atm.Offset = 0.1
		atm.Color = Color3.fromRGB(70, 70, 105)
		atm.Decay = Color3.fromRGB(45, 35, 70)
		atm.Glare = 0
		atm.Haze = 1.4
		atm.Parent = Lighting
	end
	if not Lighting:FindFirstChildOfClass("ColorCorrectionEffect") then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = -0.15
		cc.Contrast = 0.08
		cc.TintColor = Color3.fromRGB(225, 225, 255)
		cc.Parent = Lighting
	end
end

return Atmosphere
