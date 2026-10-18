--!strict
-- Client presentation data for ghost skins and auras (TASK-0062), keyed by catalog item ID. Looks only: nothing
-- here is read by income, capacity, rarity or capture. These are recolour and particle looks over the existing
-- creature art, not new models, so they carry no triangles or assets. DRAFT: the sample looks need jg's taste
-- check and real art before any release.

export type Skin = { tint: Color3, material: Enum.Material? }
export type Aura = { color: Color3, rate: number }

local CosmeticLooks = {}

CosmeticLooks.Skins = {
	SkinMoss = { tint = Color3.fromRGB(96, 150, 92), material = Enum.Material.Fabric },
} :: { [string]: Skin }

CosmeticLooks.Auras = {
	AuraEmbers = { color = Color3.fromRGB(255, 150, 70), rate = 8 },
} :: { [string]: Aura }

return CosmeticLooks
