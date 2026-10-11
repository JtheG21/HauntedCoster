--!strict
-- Placeholder monster models built from parts. Each model has an anchored, invisible "Root" part; every
-- other part is welded to it, so moving (or tweening) the Root moves the whole creature.
-- Variants reuse the base model and only recolour "body" parts and add a glow.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Variants = require(Config:WaitForChild("Variants"))

local MonsterModels = {}

type Spec = {
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material?,
	shape: Enum.PartType?,
	body: boolean?,
	transparency: number?,
}

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local SPECS: { [string]: { Spec } } = {
	Wisp = {
		{
			name = "Core",
			size = Vector3.new(2.4, 2.4, 2.4),
			offset = CFrame.new(),
			color = rgb(170, 220, 255),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			body = true,
			transparency = 0.15,
		},
		{
			name = "Halo",
			size = Vector3.new(3.6, 3.6, 3.6),
			offset = CFrame.new(),
			color = rgb(120, 180, 255),
			material = Enum.Material.ForceField,
			shape = Enum.PartType.Ball,
			body = true,
			transparency = 0.2,
		},
		{
			name = "Tail1",
			size = Vector3.new(1.4, 1.4, 1.4),
			offset = CFrame.new(0, -0.6, 1.8),
			color = rgb(150, 200, 255),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			body = true,
			transparency = 0.4,
		},
		{
			name = "Tail2",
			size = Vector3.new(0.8, 0.8, 0.8),
			offset = CFrame.new(0, -1.1, 3),
			color = rgb(150, 200, 255),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
			body = true,
			transparency = 0.55,
		},
		{
			name = "EyeL",
			size = Vector3.new(0.35, 0.5, 0.2),
			offset = CFrame.new(-0.45, 0.25, -1.15),
			color = rgb(10, 10, 30),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "EyeR",
			size = Vector3.new(0.35, 0.5, 0.2),
			offset = CFrame.new(0.45, 0.25, -1.15),
			color = rgb(10, 10, 30),
			material = Enum.Material.SmoothPlastic,
		},
	},
	Hound = {
		{
			name = "Body",
			size = Vector3.new(2.4, 2, 4.6),
			offset = CFrame.new(),
			color = rgb(120, 95, 80),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Patch",
			size = Vector3.new(2.5, 1.4, 1.6),
			offset = CFrame.new(0, 0.1, 1.2),
			color = rgb(80, 80, 90),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Head",
			size = Vector3.new(1.8, 1.6, 2),
			offset = CFrame.new(0, 0.9, -2.9),
			color = rgb(150, 120, 100),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Head2",
			size = Vector3.new(1.2, 1.1, 1.4),
			offset = CFrame.new(1.4, 1.2, -2.3) * CFrame.Angles(0, 0, math.rad(-25)),
			color = rgb(90, 85, 80),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Snout",
			size = Vector3.new(1, 0.8, 1),
			offset = CFrame.new(0, 0.6, -4.2),
			color = rgb(60, 45, 40),
			material = Enum.Material.Fabric,
		},
		{
			name = "EyeL",
			size = Vector3.new(0.35, 0.35, 0.2),
			offset = CFrame.new(-0.45, 1.25, -3.92),
			color = rgb(255, 40, 40),
			material = Enum.Material.Neon,
		},
		{
			name = "EyeR",
			size = Vector3.new(0.35, 0.35, 0.2),
			offset = CFrame.new(0.45, 1.25, -3.92),
			color = rgb(255, 40, 40),
			material = Enum.Material.Neon,
		},
		{
			name = "Stitch",
			size = Vector3.new(0.15, 0.15, 4.4),
			offset = CFrame.new(0, 1.02, 0),
			color = rgb(20, 20, 20),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "LegFL",
			size = Vector3.new(0.6, 1.8, 0.6),
			offset = CFrame.new(-0.8, -1.6, -1.6),
			color = rgb(110, 85, 70),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "LegFR",
			size = Vector3.new(0.6, 1.8, 0.6),
			offset = CFrame.new(0.8, -1.6, -1.6),
			color = rgb(70, 70, 80),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "LegBL",
			size = Vector3.new(0.6, 1.8, 0.6),
			offset = CFrame.new(-0.8, -1.6, 1.6),
			color = rgb(110, 85, 70),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "LegBR",
			size = Vector3.new(0.6, 1.8, 0.6),
			offset = CFrame.new(0.8, -1.6, 1.6),
			color = rgb(110, 85, 70),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Tail",
			size = Vector3.new(0.4, 0.4, 2),
			offset = CFrame.new(0, 0.6, 3) * CFrame.Angles(math.rad(35), 0, 0),
			color = rgb(80, 80, 90),
			material = Enum.Material.Fabric,
			body = true,
		},
	},
	Gentleman = {
		{
			name = "Coat",
			size = Vector3.new(2.4, 5, 1.4),
			offset = CFrame.new(0, -1.5, 0),
			color = rgb(30, 28, 36),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Collar",
			size = Vector3.new(2, 0.6, 1.5),
			offset = CFrame.new(0, 1.1, 0),
			color = rgb(220, 220, 225),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "Face",
			size = Vector3.new(1.6, 1.9, 1.4),
			offset = CFrame.new(0, 2.3, 0),
			color = rgb(235, 232, 225),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "EyeHoleL",
			size = Vector3.new(0.35, 0.5, 0.1),
			offset = CFrame.new(-0.38, 2.5, -0.72),
			color = rgb(0, 0, 0),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "EyeHoleR",
			size = Vector3.new(0.35, 0.5, 0.1),
			offset = CFrame.new(0.38, 2.5, -0.72),
			color = rgb(0, 0, 0),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "Mouth",
			size = Vector3.new(0.7, 0.18, 0.1),
			offset = CFrame.new(0, 1.85, -0.72),
			color = rgb(0, 0, 0),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "HatBrim",
			size = Vector3.new(2.4, 0.2, 2.2),
			offset = CFrame.new(0, 3.35, 0),
			color = rgb(15, 15, 18),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Hat",
			size = Vector3.new(1.5, 1.8, 1.4),
			offset = CFrame.new(0, 4.3, 0),
			color = rgb(15, 15, 18),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "ArmL",
			size = Vector3.new(0.5, 4.2, 0.5),
			offset = CFrame.new(-1.5, -0.6, 0),
			color = rgb(30, 28, 36),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "ArmR",
			size = Vector3.new(0.5, 4.2, 0.5),
			offset = CFrame.new(1.5, -0.6, -0.4) * CFrame.Angles(math.rad(-20), 0, 0),
			color = rgb(30, 28, 36),
			material = Enum.Material.Fabric,
			body = true,
		},
		{
			name = "Cane",
			size = Vector3.new(0.2, 4, 0.2),
			offset = CFrame.new(1.6, -2.6, -1.2),
			color = rgb(90, 60, 40),
			material = Enum.Material.Wood,
		},
	},
	BellWraith = {
		{
			name = "Bell",
			size = Vector3.new(3.2, 3.2, 3.2),
			offset = CFrame.new(0, 0.6, 0),
			color = rgb(185, 140, 60),
			material = Enum.Material.Metal,
			shape = Enum.PartType.Ball,
			body = true,
		},
		{
			name = "Lip",
			size = Vector3.new(0.6, 4.2, 4.2),
			offset = CFrame.new(0, -0.7, 0) * CFrame.Angles(0, 0, math.rad(90)),
			color = rgb(160, 120, 50),
			material = Enum.Material.Metal,
			shape = Enum.PartType.Cylinder,
			body = true,
		},
		{
			name = "Crack",
			size = Vector3.new(0.12, 2.4, 0.1),
			offset = CFrame.new(0.4, 0.6, -1.62) * CFrame.Angles(0, 0, math.rad(15)),
			color = rgb(20, 15, 10),
			material = Enum.Material.SmoothPlastic,
		},
		{
			name = "Core",
			size = Vector3.new(1.4, 1.4, 1.4),
			offset = CFrame.new(0, -1.3, 0),
			color = rgb(255, 220, 110),
			material = Enum.Material.Neon,
			shape = Enum.PartType.Ball,
		},
		{
			name = "Shroud",
			size = Vector3.new(3.6, 4, 3.6),
			offset = CFrame.new(0, -3.3, 0),
			color = rgb(60, 55, 70),
			material = Enum.Material.Fabric,
			body = true,
			transparency = 0.35,
		},
		{
			name = "Rag1",
			size = Vector3.new(0.8, 2.5, 0.2),
			offset = CFrame.new(-1.3, -5.6, 0.5) * CFrame.Angles(0, 0, math.rad(12)),
			color = rgb(50, 45, 60),
			material = Enum.Material.Fabric,
			body = true,
			transparency = 0.4,
		},
		{
			name = "Rag2",
			size = Vector3.new(0.8, 2.2, 0.2),
			offset = CFrame.new(1.2, -5.4, -0.6) * CFrame.Angles(0, 0, math.rad(-10)),
			color = rgb(50, 45, 60),
			material = Enum.Material.Fabric,
			body = true,
			transparency = 0.4,
		},
	},
}

function MonsterModels.build(speciesId: string, variantId: string): Model
	local specs = SPECS[speciesId] or SPECS.Wisp
	local variant = Variants.ById[variantId]
	local model = Instance.new("Model")
	model.Name = speciesId
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = Vector3.new(2, 2, 2)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanQuery = true
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	for _, s in specs do
		local p = Instance.new("Part")
		p.Name = s.name
		p.Size = s.size
		p.CFrame = root.CFrame * s.offset
		p.Color = if s.body and variant and variant.tint then s.color:Lerp(variant.tint, 0.65) else s.color
		p.Material = s.material or Enum.Material.SmoothPlastic
		if s.shape then
			p.Shape = s.shape
		end
		p.Transparency = s.transparency or 0
		p.Anchored = false
		p.Massless = true
		p.CanCollide = false
		p.CanTouch = false
		p.CastShadow = false
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = p
		weld.Parent = p
		p.Parent = model
	end
	if speciesId == "Wisp" or speciesId == "BellWraith" then
		local glowColor = if speciesId == "Wisp" then Color3.fromRGB(140, 200, 255) else Color3.fromRGB(255, 210, 110)
		local l = Instance.new("PointLight")
		l.Color = glowColor
		l.Range = 14
		l.Brightness = 1.2
		l.Parent = root
	end
	if variant and variant.glow then
		local l = Instance.new("PointLight")
		l.Name = "VariantGlow"
		l.Color = variant.glow
		l.Range = 16
		l.Brightness = 2
		l.Parent = root
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = variant.glow
		sparkles.Parent = root
	end
	model:SetAttribute("Species", speciesId)
	model:SetAttribute("Variant", variantId)
	return model
end

return MonsterModels
