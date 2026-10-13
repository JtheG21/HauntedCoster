--!strict
-- Monster models (server side). Each model has an anchored, invisible "Root" the services move or tween, an
-- invisible welded "Hitbox" sized to the creature (queries, prompts, highlights) and its lights. The visible
-- creature is client art (client/Art/Creatures, TASK-0043): models are tagged "Creature" and carry Species,
-- Variant and, for displays, ArtScale. The art origin is the Root, so species hover heights are unchanged.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Variants = require(Config:WaitForChild("Variants"))

local MonsterModels = {}

-- Hitbox size and centre offset from the Root, matched to the art bounds (games/haunted/art/assets/creatures.py).
local HITBOX: { [string]: { size: Vector3, offset: Vector3 } } = {
	Wisp = { size = Vector3.new(3, 4.4, 3.4), offset = Vector3.new(0, -0.5, 0.6) },
	Hound = { size = Vector3.new(2.6, 4.4, 6.6), offset = Vector3.new(0, -0.1, 0.1) },
	Gentleman = { size = Vector3.new(3, 8.6, 2.2), offset = Vector3.new(0, -0.3, 0) },
	BellWraith = { size = Vector3.new(4.6, 8.4, 4.6), offset = Vector3.new(0, -1.3, 0) },
}

local GLOW: { [string]: { color: Color3, range: number, brightness: number } } = {
	Wisp = { color = Color3.fromRGB(255, 196, 120), range = 14, brightness = 1.3 }, -- its little lantern
	BellWraith = { color = Color3.fromRGB(255, 205, 110), range = 16, brightness = 1.4 }, -- the cracked bell's glow
}

function MonsterModels.build(speciesId: string, variantId: string): Model
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
	local hb = HITBOX[speciesId] or HITBOX.Wisp
	local hitbox = Instance.new("Part")
	hitbox.Name = "Hitbox"
	hitbox.Size = hb.size
	hitbox.CFrame = root.CFrame * CFrame.new(hb.offset)
	hitbox.Transparency = 1
	hitbox.Anchored = false
	hitbox.Massless = true
	hitbox.CanCollide = false
	hitbox.CanTouch = false
	hitbox.CanQuery = true
	hitbox.CastShadow = false
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = hitbox
	weld.Parent = hitbox
	hitbox.Parent = model
	local glow = GLOW[speciesId]
	if glow then
		local l = Instance.new("PointLight")
		l.Color = glow.color
		l.Range = glow.range
		l.Brightness = glow.brightness
		l.Parent = root
	end
	if variant and variant.glow then
		local l = Instance.new("PointLight")
		l.Name = "VariantGlow"
		l.Color = variant.glow
		l.Range = 16
		l.Brightness = 2
		l.Parent = root
	end
	model:SetAttribute("Species", speciesId)
	model:SetAttribute("Variant", variantId)
	CollectionService:AddTag(model, "Creature")
	return model
end

return MonsterModels
