--!strict
-- Mansion themes (TASK-0064). Pure. A theme declares the house tiers it covers; the plot shows it only while
-- the house is at a covered tier. A tier upgrade that leaves the equipped theme uncovered returns the plot to
-- the default look with a notice, and the theme stays owned. Looks only: nothing here touches income,
-- capacity, rarity or capture.

local CosmeticRules = require(script.Parent.CosmeticRules)

local ThemeRules = {}

ThemeRules.TierNames = { [0] = "Shabby Shack", [1] = "Restored Manor", [2] = "Grand Mansion" }

export type Item = { name: string?, category: string, tiers: { number }? }

-- Untrusted remote argument: a theme ID to equip, or nil to go back to the default look.
function ThemeRules.parse(id: any): (boolean, string?)
	if id ~= nil and not CosmeticRules.isId(id) then
		return false, "Something went wrong. Try again."
	end
	return true, nil
end

local MESSAGES: { [string]: string } = {
	notOwned = "You don't own that theme yet.",
	unknown = "That theme isn't available.",
	wrongCategory = "That isn't a mansion theme.",
	tier = "That theme doesn't cover your current house.",
}

function ThemeRules.message(reason: string?): string
	return MESSAGES[reason or ""] or "Something went wrong. Try again."
end

function ThemeRules.supports(item: Item?, tier: number): boolean
	return item ~= nil and item.category == "Theme" and item.tiers ~= nil and table.find(item.tiers, tier) ~= nil
end

-- "Covers: Restored Manor, Grand Mansion" (honest even for a theme that covers nothing yet).
function ThemeRules.coverage(item: Item?): string
	if not (item and item.tiers and #item.tiers > 0) then
		return "Covers no house tier yet."
	end
	local names: { string } = {}
	local tiers = table.clone(item.tiers)
	table.sort(tiers)
	for _, t in tiers do
		table.insert(names, ThemeRules.TierNames[t] or `Tier {t}`)
	end
	return "Covers: " .. table.concat(names, ", ")
end

-- The theme to show at `tier`: the saved choice, only if owned, listed and covering that tier.
function ThemeRules.resolve(cosmetics: CosmeticRules.State?, catalog: CosmeticRules.Catalog, tier: number): string?
	local id = cosmetics and cosmetics.mansionTheme
	if not (cosmetics and id) then
		return nil
	end
	if cosmetics.entitlements[id] and ThemeRules.supports(catalog.Items[id] :: any, tier) then
		return id
	end
	return nil
end

-- After an upgrade to `newTier`: a notice if the equipped theme no longer applies (nil if nothing changed).
function ThemeRules.fallbackNotice(
	cosmetics: CosmeticRules.State?,
	catalog: CosmeticRules.Catalog,
	newTier: number
): string?
	local id = cosmetics and cosmetics.mansionTheme
	if not (cosmetics and id) or ThemeRules.resolve(cosmetics, catalog, newTier) then
		return nil
	end
	local item = catalog.Items[id]
	local name = (item and item.name) or id
	local tierName = ThemeRules.TierNames[newTier] or "new house"
	return `Your {name} theme doesn't cover the {tierName}, so the default look is back. The theme is still yours.`
end

return ThemeRules
