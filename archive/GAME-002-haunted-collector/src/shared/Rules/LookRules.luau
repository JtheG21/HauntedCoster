--!strict
-- Ghost skin and aura equipment (TASK-0062). Pure: request parsing, the rare-variant rule and the look a ghost
-- actually shows. Ownership and species compatibility stay in CosmeticRules; this adds what is specific to
-- equipping from the Owned screen. Looks never touch income, capacity, rarity or capture.

local CosmeticRules = require(script.Parent.CosmeticRules)

local LookRules = {}

local NATURAL = "Normal" -- only the natural variant takes a skin; Spectral and Ashen keep their own identity

export type Request = { uid: string, slot: string, id: string? }
export type Appearance = { skin: string?, aura: string? }

-- Untrusted remote arguments in, one validated request out. id = nil means "remove".
function LookRules.parse(uid: any, slot: any, id: any): (Request?, string?)
	if type(uid) ~= "string" or #uid == 0 or #uid > 64 then
		return nil, "Pick a ghost first."
	end
	if slot ~= "skin" and slot ~= "aura" then
		return nil, "Something went wrong. Try again."
	end
	if id ~= nil and not CosmeticRules.isId(id) then
		return nil, "Something went wrong. Try again."
	end
	return { uid = uid, slot = slot :: string, id = id :: string? }, nil
end

-- Why `variant` can't take a skin (nil if it can). Auras go on any variant.
function LookRules.variantRefusal(slot: string, variant: string): string?
	if slot == "skin" and variant ~= NATURAL then
		return "Rare ghosts keep their natural look."
	end
	return nil
end

local MESSAGES: { [string]: string } = {
	noGhost = "You don't own that ghost.",
	notOwned = "You don't own that cosmetic yet.",
	unknown = "That cosmetic isn't available.",
	wrongCategory = "That doesn't fit this slot.",
	incompatible = "That doesn't fit this ghost.",
	badSlot = "Something went wrong. Try again.",
}

function LookRules.message(reason: string?): string
	return MESSAGES[reason or ""] or "Something went wrong. Try again."
end

-- The skin and aura a ghost shows right now. Only owned, still-listed, compatible items count, so a catalog
-- change or a stale selection falls back to the natural look instead of showing something unowned.
function LookRules.appearance(
	cosmetics: CosmeticRules.State?,
	catalog: CosmeticRules.Catalog,
	uid: string,
	species: string,
	variant: string
): Appearance
	local out: Appearance = {}
	local look = cosmetics and cosmetics.ghostLooks[uid]
	if not (cosmetics and look) then
		return out
	end
	local function usable(id: string?, category: string): string?
		local item = id and catalog.Items[id]
		if not (id and item and item.category == category and cosmetics.entitlements[id]) then
			return nil
		end
		if item.species and table.find(item.species, species) == nil then
			return nil
		end
		return id
	end
	if LookRules.variantRefusal("skin", variant) == nil then
		out.skin = usable(look.skin, "Skin")
	end
	out.aura = usable(look.aura, "Aura")
	return out
end

export type Target = { uid: string, species: string, variant: string, equipped: boolean, reason: string? }

-- For the Owned screen: every owned ghost with whether `itemId` can go on it. Sorted by species then UID.
function LookRules.targets(
	cosmetics: CosmeticRules.State?,
	catalog: CosmeticRules.Catalog,
	owned: { { uid: string, species: string, variant: string } },
	itemId: string
): { Target }
	local out: { Target } = {}
	local item = catalog.Items[itemId]
	if not (item and (item.category == "Skin" or item.category == "Aura")) then
		return out
	end
	local slot = if item.category == "Skin" then "skin" else "aura"
	for _, m in owned do
		local look = cosmetics and cosmetics.ghostLooks[m.uid]
		local reason: string? = nil
		if item.species and table.find(item.species, m.species) == nil then
			reason = "incompatible"
		elseif LookRules.variantRefusal(slot, m.variant) then
			reason = "variant"
		end
		table.insert(out, {
			uid = m.uid,
			species = m.species,
			variant = m.variant,
			equipped = look ~= nil and look[slot] == itemId,
			reason = reason,
		})
	end
	table.sort(out, function(a, b)
		if a.species ~= b.species then
			return a.species < b.species
		end
		return a.uid < b.uid
	end)
	return out
end

return LookRules
