--!strict
-- Client presentation data for ghost skins and auras (TASK-0062), keyed by catalog item ID. Looks only: nothing
-- here is read by income, capacity, rarity or capture. These are recolour and particle looks over the existing
-- creature art, not new models, so they carry no triangles or assets. DRAFT: the sample looks need jg's taste
-- check and real art before any release.

export type Skin = { tint: Color3, material: Enum.Material? }
export type Aura = { color: Color3, rate: number }
export type Theme = { Walls: Color3, Trim: Color3, Roof: Color3 } -- the house art's tintable parts
export type Decoration = { color: Color3, glow: Color3 }
export type CaptureEffect = { color: Color3, count: number, seconds: number }

local CosmeticLooks = {}

CosmeticLooks.Skins = {
	SkinMoss = { tint = Color3.fromRGB(96, 150, 92), material = Enum.Material.Fabric },
} :: { [string]: Skin }

CosmeticLooks.Auras = {
	AuraEmbers = { color = Color3.fromRGB(255, 150, 70), rate = 8 },
} :: { [string]: Aura }

CosmeticLooks.CaptureEffects = {
	FxSparks = { color = Color3.fromRGB(255, 225, 120), count = 36, seconds = 1.4 },
} :: { [string]: CaptureEffect }

CosmeticLooks.Themes = {
	ThemeMoonlit = {
		Walls = Color3.fromRGB(150, 160, 190),
		Trim = Color3.fromRGB(230, 235, 250),
		Roof = Color3.fromRGB(60, 70, 110),
	},
} :: { [string]: Theme }

CosmeticLooks.Decorations = {
	DecoLantern = { color = Color3.fromRGB(70, 66, 74), glow = Color3.fromRGB(255, 190, 110) },
} :: { [string]: Decoration }

return CosmeticLooks
