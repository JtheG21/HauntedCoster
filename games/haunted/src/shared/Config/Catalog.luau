--!strict
-- Cosmetic catalog (TASK-0060, SYS-Haunted-Monetization-UI). Item and reward IDs are stable strings: once an
-- ID has shipped it is never renamed or reused, because profiles store it. This task defines the shape only;
-- the launch assortment, prices and product mechanism are later tasks, so both tables ship empty.

export type Category = "Skin" | "Aura" | "CaptureEffect" | "Theme" | "Decoration"

export type Item = {
	category: Category,
	species: { string }?, -- Skin/Aura: compatible species; nil means every species
	tiers: { number }?, -- Theme: house tiers (0-based) the theme covers; nil means none yet
	placementLimit: number?, -- Decoration: reusable, at most this many placed at once (default 1)
}

export type Reward = {
	grants: { string }, -- catalog item IDs granted once when the reward is claimed
}

local Catalog = {}

Catalog.Items = {} :: { [string]: Item }
Catalog.Rewards = {} :: { [string]: Reward }

-- Bounds that hold whatever the catalog contains, so a stored profile can't grow without limit.
Catalog.MaxIdLength = 64
Catalog.MaxEntitlements = 500
Catalog.MaxPlacements = 60
Catalog.MaxRewards = 200

return Catalog
