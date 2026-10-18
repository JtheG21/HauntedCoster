--!strict
-- Cosmetic catalog (TASK-0060, SYS-Haunted-Monetization-UI). Item and reward IDs are stable strings: once an
-- ID has shipped it is never renamed or reused, because profiles store it. The launch assortment, prices and
-- product mechanism are later tasks; only sample looks (TASK-0062) are listed.

export type Category = "Skin" | "Aura" | "CaptureEffect" | "Theme" | "Decoration"

export type Item = {
	name: string?, -- display name; the UI falls back to the ID
	category: Category,
	species: { string }?, -- Skin/Aura: compatible species; nil means every species
	tiers: { number }?, -- Theme: house tiers (0-based) the theme covers; nil means none yet
	placementLimit: number?, -- Decoration: reusable, at most this many placed at once (default 1)
	coinPrice: number?, -- Coins to buy it (whole number); nil means not for sale. PLACEHOLDER prices need jg's tuning
	footprint: { x: number, z: number }?, -- Decoration: plot-local studs before rotation (default 2 x 2)
}

export type Reward = {
	grants: { string }, -- catalog item IDs granted once when the reward is claimed
}

local Catalog = {}

-- Sample looks (TASK-0062 to TASK-0067). Every coinPrice here is a PLACEHOLDER for jg to tune from measured income.
-- FxSparks and ThemeMoonlit stay reward-only: data-only recolour and particle looks over the existing creature art, listed so the
-- equip path can be exercised. No grant path exists yet, so nobody owns them; real items need jg's decisions.
Catalog.Items = {
	SkinMoss = { name = "Mossy Skin", category = "Skin", coinPrice = 300 },
	AuraEmbers = { name = "Ember Aura", category = "Aura", coinPrice = 250 },
	FxSparks = { name = "Golden Sparks", category = "CaptureEffect" },
	DecoLantern = {
		name = "Garden Lantern",
		category = "Decoration",
		placementLimit = 4,
		footprint = { x = 2, z = 2 },
		coinPrice = 150,
	},
	ThemeMoonlit = { name = "Moonlit Theme", category = "Theme", tiers = { 1, 2 } }, -- not the Shack: tests the fallback
} :: { [string]: Item }
-- Milestone rewards (TASK-0066, Config/Milestones): the reward ID equals the milestone ID. DRAFT: which sample
-- each milestone grants needs jg's review.
Catalog.Rewards = {
	bestiary_half = { grants = { "FxSparks" } },
	bestiary_all = { grants = { "ThemeMoonlit" } },
	hab_Cemetery = { grants = { "SkinMoss" } },
	hab_Woodland = { grants = { "AuraEmbers" } },
	var_Spectral = { grants = { "AuraEmbers" } },
	var_Ashen = { grants = { "SkinMoss" } },
} :: { [string]: Reward }

-- Bounds that hold whatever the catalog contains, so a stored profile can't grow without limit.
Catalog.MaxIdLength = 64
Catalog.MaxEntitlements = 500
Catalog.MaxPlacements = 60
Catalog.MaxRewards = 200

return Catalog
