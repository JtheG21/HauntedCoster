--!strict
-- Tunables for TierRules (blueprint section 9: nine tiers, no subdivisions). Frozen: never mutate at runtime.

local TierConfig = table.freeze({
	Ids = table.freeze({ "plastic", "bronze", "copper", "silver", "gold", "emerald", "platinum", "diamond", "demon" }),
	Names = table.freeze({
		plastic = "PLASTIC",
		bronze = "BRONZE",
		copper = "COPPER",
		silver = "SILVER",
		gold = "GOLD",
		emerald = "EMERALD",
		platinum = "PLATINUM",
		diamond = "DIAMOND",
		demon = "DEMON",
	}),
	ProgressPerTier = 100, -- progress points to fill one tier's bar
})

return TierConfig
