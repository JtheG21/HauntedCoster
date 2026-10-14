--!strict
-- Cosmetic ownership, equipment, Coin purchases, Robux receipts and collection rewards (TASK-0047). Pure: no Roblox
-- services, so every rule is unit-tested. Cosmetics never feed gameplay: nothing in income, capture, rarity,
-- speed, capacity or retaliation reads `profile.cosmetics`.

local Shared = script.Parent.Parent
local Cosmetics = require(Shared.Config.Cosmetics)
local Monsters = require(Shared.Config.Monsters)
local Habitats = require(Shared.Config.Habitats)
local Variants = require(Shared.Config.Variants)
local PlacementRules = require(script.Parent.PlacementRules)

local CosmeticRules = {}

CosmeticRules.MaxReceipts = 200 -- remembered purchase ids (duplicate-safe ProcessReceipt)

export type State = {
	owned: { [string]: boolean }, -- account-wide unlocks
	skins: { [string]: string }, -- monster uid -> skin id
	auras: { [string]: string }, -- monster uid -> aura id
	capture: string?, -- selected capture effect
	theme: string?, -- selected mansion theme
	placements: { PlacementRules.Placement },
	nextKey: number,
	claimed: { [string]: boolean }, -- milestone id -> reward granted
	receipts: { string }, -- processed PurchaseIds, oldest first
}

function CosmeticRules.default(): State
	return {
		owned = {},
		skins = {},
		auras = {},
		capture = nil,
		theme = nil,
		placements = {},
		nextKey = 1,
		claimed = {},
		receipts = {},
	}
end

local function itemOf(id: any, category: string?): Cosmetics.Item?
	if type(id) ~= "string" then
		return nil
	end
	local item = Cosmetics.ById[id]
	if item and (category == nil or item.category == category) then
		return item
	end
	return nil
end

function CosmeticRules.compatible(item: Cosmetics.Item, species: string): boolean
	if not item.species then
		return true
	end
	return table.find(item.species, species) ~= nil
end

-- Builds a valid cosmetics state from untrusted stored data. `owned` is the profile's sanitized monster list
-- (selections for released monsters are dropped) and `tier` its house tier (invalid placements are stored).
function CosmeticRules.sanitize(raw: any, owned: { any }, tier: number): State
	local s = CosmeticRules.default()
	if type(raw) ~= "table" then
		return s
	end
	if type(raw.owned) == "table" then
		for id, v in raw.owned do
			if v == true and itemOf(id) then
				s.owned[id] = true
			end
		end
	end
	local speciesOf: { [string]: string } = {}
	for _, m in owned do
		speciesOf[m.uid] = m.species
	end
	for _, slot in { "skins", "auras" } do
		local category = if slot == "skins" then "Skin" else "Aura"
		local src = raw[slot]
		if type(src) == "table" then
			for uid, id in src do
				local item = itemOf(id, category)
				local species: string? = if type(uid) == "string" then speciesOf[uid] else nil
				if item and species and s.owned[id] and CosmeticRules.compatible(item, species) then
					(s :: any)[slot][uid] = id
				end
			end
		end
	end
	if itemOf(raw.capture, "CaptureEffect") and s.owned[raw.capture] then
		s.capture = raw.capture
	end
	local theme = itemOf(raw.theme, "Theme")
	if theme and s.owned[raw.theme] and table.find(theme.tiers or {}, tier) then
		s.theme = raw.theme
	end
	s.nextKey = if type(raw.nextKey) == "number" and raw.nextKey == raw.nextKey
		then math.clamp(math.floor(raw.nextKey), 1, 1e9)
		else 1
	if type(raw.placements) == "table" then
		local counts: { [string]: number } = {}
		for _, p in raw.placements do
			if
				type(p) == "table"
				and type(p.key) == "string"
				and itemOf(p.id, "Decoration")
				and s.owned[p.id]
				and #s.placements < Cosmetics.Placement.maxPlaced
			then
				local item = Cosmetics.ById[p.id]
				local n = (counts[p.id] or 0) + 1
				local placement = { key = p.key, id = p.id, x = p.x, z = p.z, rot = p.rot }
				if
					n <= (item.limit or 1)
					and PlacementRules.check(p.id, p.x, p.z, p.rot, tier, s.placements) == "ok"
				then
					counts[p.id] = n
					table.insert(s.placements, placement)
				end
			end
		end
	end
	if type(raw.claimed) == "table" then
		for id, v in raw.claimed do
			if v == true and type(id) == "string" and Cosmetics.MilestoneById[id] then
				s.claimed[id] = true
			end
		end
	end
	if type(raw.receipts) == "table" then
		for _, r in raw.receipts do
			if type(r) == "string" and #r <= 64 and #s.receipts < CosmeticRules.MaxReceipts then
				table.insert(s.receipts, r)
			end
		end
	end
	return s
end

-- Equipment ------------------------------------------------------------------------------------------------

-- Equips (or with `id == nil` removes) a skin or aura on one owned monster. Returns ok, reason.
function CosmeticRules.equipGhost(profile: any, slot: string, uid: any, id: any): (boolean, string?)
	if slot ~= "skins" and slot ~= "auras" then
		return false, "Unknown slot"
	end
	if type(uid) ~= "string" then
		return false, "Pick a ghost"
	end
	local monster = nil
	for _, m in profile.owned do
		if m.uid == uid then
			monster = m
		end
	end
	if not monster then
		return false, "That ghost isn't yours"
	end
	local state: State = profile.cosmetics
	if id == nil then
		state[slot][uid] = nil
		return true, nil
	end
	local item = itemOf(id, if slot == "skins" then "Skin" else "Aura")
	if not item then
		return false, "Unknown item"
	end
	if not state.owned[id] then
		return false, "You don't own that yet"
	end
	if not CosmeticRules.compatible(item, monster.species) then
		local names = {}
		for _, sp in (item.species or {}) :: { string } do
			table.insert(names, Monsters.Species[sp] and Monsters.Species[sp].name or sp)
		end
		return false, `Only fits: {table.concat(names, ", ")}`
	end
	state[slot][uid] = id
	return true, nil
end

-- Selects (or removes) the player's capture effect or mansion theme.
function CosmeticRules.select(profile: any, kind: string, id: any): (boolean, string?)
	local state: State = profile.cosmetics
	if kind ~= "capture" and kind ~= "theme" then
		return false, "Unknown slot"
	end
	if id == nil then
		(state :: any)[kind] = nil
		return true, nil
	end
	local item = itemOf(id, if kind == "capture" then "CaptureEffect" else "Theme")
	if not item then
		return false, "Unknown item"
	end
	if not state.owned[id] then
		return false, "You don't own that yet"
	end
	if kind == "theme" and not table.find(item.tiers or {}, profile.houseTier) then
		return false, "This theme doesn't fit your current house"
	end
	(state :: any)[kind] = id
	return true, nil
end

-- Acquisition ----------------------------------------------------------------------------------------------

-- Spends earned Coins on an item. Validates and charges in one synchronous step.
function CosmeticRules.buyWithCoins(profile: any, id: any): (boolean, string?)
	local item = itemOf(id)
	if not item then
		return false, "Unknown item"
	end
	local price = item.acquire.coins
	if not price then
		return false, "Not sold for Coins"
	end
	local state: State = profile.cosmetics
	if state.owned[item.id] then
		return false, "Already owned"
	end
	if profile.coins < price then
		return false, `Needs {price} Coins`
	end
	profile.coins -= price
	state.owned[item.id] = true
	return true, nil
end

-- The item a configured Robux product grants (nil while the product has no real id).
function CosmeticRules.productItem(productId: any): (string?, string?)
	if type(productId) ~= "number" then
		return nil, nil
	end
	for key, product in Cosmetics.Products do
		if product.productId == productId and itemOf(product.item) then
			return product.item, key
		end
	end
	return nil, nil
end

-- Applies a Robux receipt once. Returns "granted" (state changed, must be saved before acknowledging),
-- "duplicate" (already processed: acknowledge again, change nothing) or "invalid" (unknown product).
function CosmeticRules.applyReceipt(profile: any, purchaseId: any, productId: any): string
	if type(purchaseId) ~= "string" or #purchaseId == 0 or #purchaseId > 64 then
		return "invalid"
	end
	local state: State = profile.cosmetics
	if table.find(state.receipts, purchaseId) then
		return "duplicate"
	end
	local id = CosmeticRules.productItem(productId)
	if not id then
		return "invalid"
	end
	state.owned[id] = true -- an already-owned unlock is still recorded as processed (never charged twice by us)
	table.insert(state.receipts, purchaseId)
	while #state.receipts > CosmeticRules.MaxReceipts do
		table.remove(state.receipts, 1)
	end
	return "granted"
end

-- Collection rewards ---------------------------------------------------------------------------------------

local function habitatSpecies(habitatId: string): { string }
	local def = Habitats.ById[habitatId]
	local set: { [string]: boolean } = {}
	local out = {}
	if def then
		for _, zone in def.zones do
			for species in zone.spawns do
				if not set[species] then
					set[species] = true
					table.insert(out, species)
				end
			end
		end
	end
	table.sort(out)
	return out
end

-- Every natural variant that can actually spawn ("Species:Variant"): a variant restricted to some zones only
-- counts for the species those zones spawn (Ashen only in the Sealed Crypt), so the Bestiary can be completed.
local obtainable: { [string]: boolean }? = nil
function CosmeticRules.obtainableVariants(): { [string]: boolean }
	if obtainable then
		return obtainable
	end
	local out: { [string]: boolean } = {}
	for _, def in Habitats.List do
		for _, zone in def.zones do
			for species in zone.spawns do
				for _, v in Variants.List do
					if v.zones == nil or table.find(v.zones, zone.id) ~= nil then
						out[`{species}:{v.id}`] = true
					end
				end
			end
		end
	end
	obtainable = out
	return out
end

-- Progress toward each milestone from the journal (caught species and discovered natural variants only; owning
-- a paid skin never counts). Returns { [id] = { have, need, done, claimed } }.
function CosmeticRules.progress(
	profile: any
): { [string]: { have: number, need: number, done: boolean, claimed: boolean } }
	local out = {}
	local caught = profile.journal.caught
	local variants = profile.journal.variants
	local reachable = CosmeticRules.obtainableVariants()
	local nVariants, totalVariants = 0, 0
	for key in reachable do
		totalVariants += 1
		if variants[key] then
			nVariants += 1
		end
	end
	local nCaught = 0
	for _, sp in Monsters.Order do
		if caught[sp] then
			nCaught += 1
		end
	end
	local state: State = profile.cosmetics
	for _, m in Cosmetics.Milestones do
		local have, need = 0, 1
		if m.kind == "habitat" then
			local list = habitatSpecies(m.habitat :: string)
			need = #list
			for _, sp in list do
				if caught[sp] then
					have += 1
				end
			end
		elseif m.kind == "variants" then
			have, need = nVariants, m.need or 1
		elseif m.kind == "bestiary" then
			need = math.ceil((#Monsters.Order + totalVariants) * (m.need or 1))
			have = math.min(need, nCaught + nVariants)
		end
		out[m.id] = { have = have, need = need, done = have >= need, claimed = state.claimed[m.id] == true }
	end
	return out
end

-- The reward items a milestone grants.
function CosmeticRules.rewardsFor(milestoneId: string): { string }
	local out = {}
	for _, item in Cosmetics.Items do
		if item.acquire.reward == milestoneId then
			table.insert(out, item.id)
		end
	end
	return out
end

-- Claims a completed milestone's rewards once. Returns ok, reason, granted item ids.
function CosmeticRules.claim(profile: any, milestoneId: any): (boolean, string?, { string })
	if type(milestoneId) ~= "string" or not Cosmetics.MilestoneById[milestoneId] then
		return false, "Unknown reward", {}
	end
	local state: State = profile.cosmetics
	if state.claimed[milestoneId] then
		return false, "Already claimed", {}
	end
	local p = CosmeticRules.progress(profile)[milestoneId]
	if not p.done then
		return false, `{p.have}/{p.need} so far`, {}
	end
	state.claimed[milestoneId] = true
	local granted = CosmeticRules.rewardsFor(milestoneId)
	for _, id in granted do
		state.owned[id] = true
	end
	return true, nil, granted
end

-- Decorations ----------------------------------------------------------------------------------------------

local function placedCount(state: State, id: string): number
	local n = 0
	for _, p in state.placements do
		if p.id == id then
			n += 1
		end
	end
	return n
end

-- Places a new copy of an owned decoration. Returns ok, reason, key.
function CosmeticRules.place(profile: any, id: any, x: any, z: any, rot: any, fine: any): (boolean, string?, string?)
	local item = itemOf(id, "Decoration")
	if not item then
		return false, "Unknown decoration", nil
	end
	local state: State = profile.cosmetics
	if not state.owned[item.id] then
		return false, "You don't own that yet", nil
	end
	if placedCount(state, item.id) >= (item.limit or 1) then
		return false, `You can place {item.limit or 1} of these`, nil
	end
	if #state.placements >= Cosmetics.Placement.maxPlaced then
		return false, "Your plot is full of decorations", nil
	end
	if type(x) ~= "number" or type(z) ~= "number" or type(rot) ~= "number" then
		return false, "Bad position", nil
	end
	local sx, sz, sr = PlacementRules.snap(x, z, rot, fine == true)
	local why = PlacementRules.check(item.id, sx, sz, sr, profile.houseTier, state.placements)
	if why ~= "ok" then
		return false, `Can't place there: {why}`, nil
	end
	local key = `d{state.nextKey}`
	state.nextKey += 1
	table.insert(state.placements, { key = key, id = item.id, x = sx, z = sz, rot = sr })
	return true, nil, key
end

-- Moves (or rotates) a placed decoration. Cancel = simply not calling this.
function CosmeticRules.move(profile: any, key: any, x: any, z: any, rot: any, fine: any): (boolean, string?)
	local state: State = profile.cosmetics
	for _, p in state.placements do
		if p.key == key then
			if type(x) ~= "number" or type(z) ~= "number" or type(rot) ~= "number" then
				return false, "Bad position"
			end
			local sx, sz, sr = PlacementRules.snap(x, z, rot, fine == true)
			local why = PlacementRules.check(p.id, sx, sz, sr, profile.houseTier, state.placements, p.key)
			if why ~= "ok" then
				return false, `Can't place there: {why}`
			end
			p.x, p.z, p.rot = sx, sz, sr
			return true, nil
		end
	end
	return false, "Not placed"
end

-- Returns a placed decoration to storage (the unlock stays owned).
function CosmeticRules.store(profile: any, key: any): (boolean, string?)
	local state: State = profile.cosmetics
	for i, p in state.placements do
		if p.key == key then
			table.remove(state.placements, i)
			return true, nil
		end
	end
	return false, "Not placed"
end

-- After a house tier change: keeps the placements that still fit and stores the rest (returns their ids), and
-- drops a theme the new tier doesn't support (the theme stays owned).
function CosmeticRules.onTierChanged(profile: any): { string }
	local state: State = profile.cosmetics
	local kept, stored = PlacementRules.reconcile(state.placements, profile.houseTier)
	state.placements = kept
	local ids = {}
	for _, p in stored do
		table.insert(ids, p.id)
	end
	local theme = itemOf(state.theme, "Theme")
	if theme and not table.find(theme.tiers or {}, profile.houseTier) then
		state.theme = nil
	end
	return ids
end

-- A client-facing snapshot (ownership, equipment, placements, reward progress, which Robux products are live).
function CosmeticRules.snapshot(profile: any, productsLive: boolean): { [string]: any }
	local state: State = profile.cosmetics
	local live: { [string]: boolean } = {}
	if productsLive then
		for key, product in Cosmetics.Products do
			if type(product.productId) == "number" then
				live[key] = true
			end
		end
	end
	return {
		owned = table.clone(state.owned),
		skins = table.clone(state.skins),
		auras = table.clone(state.auras),
		capture = state.capture,
		theme = state.theme,
		placements = table.clone(state.placements),
		progress = CosmeticRules.progress(profile),
		productsLive = live,
	}
end

return CosmeticRules
