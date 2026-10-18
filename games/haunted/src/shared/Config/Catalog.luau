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
}

export type Reward = {
	grants: { string }, -- catalog item IDs granted once when the reward is claimed
}

local Catalog = {}

-- Sample looks (TASK-0062, TASK-0063): data-only recolour and particle looks over the existing creature art, listed so the
-- equip path can be exercised. No grant path exists yet, so nobody owns them; real items need jg's decisions.
Catalog.Items = {
	SkinMoss = { name = "Mossy Skin", category = "Skin" },
	AuraEmbers = { name = "Ember Aura", category = "Aura" },
	FxSparks = { name = "Golden Sparks", category = "CaptureEffect" },
} :: { [string]: Item }
Catalog.Rewards = {} :: { [string]: Reward }

-- Bounds that hold whatever the catalog contains, so a stored profile can't grow without limit.
Catalog.MaxIdLength = 64
Catalog.MaxEntitlements = 500
Catalog.MaxPlacements = 60
Catalog.MaxRewards = 200

return Catalog
