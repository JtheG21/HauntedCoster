--!strict
-- Cosmetic ownership, equipment, decoration placements and reward claims (TASK-0060). Pure: no Roblox
-- services, so it is unit-tested. Every rule takes the catalog explicitly so specs can pass a test catalog.
--
-- Storage policy (SYS-Haunted-Monetization-UI): an entitlement is never dropped because the current catalog
-- doesn't list it (a config gap must not destroy something a player earned or bought). Selections and
-- placements must reference an owned entitlement and, when the catalog knows the item, fit its category and
-- compatibility. Cosmetics never touch income, capacity, rarity, variants or capture rules.

local Shared = script.Parent.Parent
local CatalogConfig = require(Shared.Config.Catalog)
local World = require(Shared.Config.World)

local CosmeticRules = {}

export type Catalog = {
	Items: { [string]: CatalogConfig.Item },
	Rewards: { [string]: CatalogConfig.Reward },
}
export type GhostLook = { skin: string?, aura: string? }
export type Placement = { id: string, x: number, z: number, r: number }
export type State = {
	entitlements: { [string]: boolean },
	ghostLooks: { [string]: GhostLook }, -- keyed by owned monster UID
	captureEffect: string?,
	mansionTheme: string?,
	placements: { Placement },
	rewardsClaimed: { [string]: boolean },
}

CosmeticRules.Rotations = { 0, 90, 180, 270 }
CosmeticRules.HalfX = World.PlotSize.X / 2
CosmeticRules.HalfZ = World.PlotSize.Y / 2

function CosmeticRules.isId(v: any): boolean
	return type(v) == "string" and #v > 0 and #v <= CatalogConfig.MaxIdLength and string.match(v, "^[%w_%-]+$") ~= nil
end

function CosmeticRules.default(): State
	return {
		entitlements = {},
		ghostLooks = {},
		captureEffect = nil,
		mansionTheme = nil,
		placements = {},
		rewardsClaimed = {},
	}
end

local function idSet(v: any, max: number): ({ [string]: boolean }, boolean)
	local out, n, ok = {}, 0, true
	if v ~= nil and type(v) ~= "table" then
		return out, false
	end
	if type(v) == "table" then
		for k, flag in v do
			if CosmeticRules.isId(k) and flag == true and n < max then
				out[k] = true
				n += 1
			else
				ok = false
			end
		end
	end
	return out, ok
end

-- True when the item may sit in a slot of `category`: owned, and the catalog (if it knows the item) agrees.
local function fits(s: State, catalog: Catalog, id: any, category: string, species: string?): boolean
	if not CosmeticRules.isId(id) or not s.entitlements[id] then
		return false
	end
	local item = catalog.Items[id]
	if item == nil then
		return true -- unknown to this catalog: keep, never destroy (see header)
	end
	if item.category ~= category then
		return false
	end
	if species and item.species then
		return table.find(item.species, species) ~= nil
	end
	return true
end

local function validRotation(r: any): boolean
	return type(r) == "number" and table.find(CosmeticRules.Rotations, r) ~= nil
end

local function inPlot(x: any, z: any): boolean
	return type(x) == "number"
		and type(z) == "number"
		and x == x
		and z == z
		and math.abs(x) <= CosmeticRules.HalfX
		and math.abs(z) <= CosmeticRules.HalfZ
end

local function limitOf(catalog: Catalog, id: string): number
	local item = catalog.Items[id]
	return if item and item.placementLimit then item.placementLimit else 1
end

local function placedCount(s: State, id: string): number
	local n = 0
	for _, pl in s.placements do
		if pl.id == id then
			n += 1
		end
	end
	return n
end

-- Builds valid cosmetic state from untrusted fields. `speciesByUid` maps every owned monster UID to its
-- species. Returns the state and the names of repaired fields.
function CosmeticRules.sanitize(
	raw: { [string]: any },
	speciesByUid: { [string]: string },
	catalog: Catalog
): (State, { string })
	local repaired: { string } = {}
	local function fix(name: string, ok: boolean)
		if not ok then
			table.insert(repaired, name)
		end
	end
	local s = CosmeticRules.default()

	local ok
	s.entitlements, ok = idSet(raw.entitlements, CatalogConfig.MaxEntitlements)
	fix("entitlements", ok)
	s.rewardsClaimed, ok = idSet(raw.rewardsClaimed, CatalogConfig.MaxRewards)
	fix("rewardsClaimed", ok)

	if type(raw.ghostLooks) == "table" then
		local good = true
		for uid, look in raw.ghostLooks do
			local species = if type(uid) == "string" then speciesByUid[uid] else nil
			if species == nil or type(look) ~= "table" then
				good = false
				continue
			end
			local skin = if fits(s, catalog, look.skin, "Skin", species) then look.skin else nil
			local aura = if fits(s, catalog, look.aura, "Aura", species) then look.aura else nil
			good = good and skin == look.skin and aura == look.aura
			if skin or aura then
				s.ghostLooks[uid] = { skin = skin, aura = aura }
			end
		end
		fix("ghostLooks", good)
	else
		fix("ghostLooks", raw.ghostLooks == nil)
	end

	if raw.captureEffect ~= nil then
		s.captureEffect = if fits(s, catalog, raw.captureEffect, "CaptureEffect") then raw.captureEffect else nil
		fix("captureEffect", s.captureEffect ~= nil)
	end
	-- Tier coverage is not checked here: an upgrade must not silently unequip a theme (the world falls back).
	if raw.mansionTheme ~= nil then
		s.mansionTheme = if fits(s, catalog, raw.mansionTheme, "Theme") then raw.mansionTheme else nil
		fix("mansionTheme", s.mansionTheme ~= nil)
	end

	if type(raw.placements) == "table" then
		for _, pl in raw.placements do
			if
				type(pl) == "table"
				and fits(s, catalog, pl.id, "Decoration")
				and inPlot(pl.x, pl.z)
				and validRotation(pl.r)
				and #s.placements < CatalogConfig.MaxPlacements
				and placedCount(s, pl.id) < limitOf(catalog, pl.id)
			then
				table.insert(s.placements, { id = pl.id, x = pl.x, z = pl.z, r = pl.r })
			else
				fix("placements", false)
			end
		end
	else
		fix("placements", raw.placements == nil)
	end

	return s, repaired
end

-- Mutating rules below return (ok, reason). Callers (server services) validate input types and rate limits
-- first; these rules decide ownership and compatibility.

function CosmeticRules.owns(s: State, id: string): boolean
	return s.entitlements[id] == true
end

-- Grants an account-wide unlock. Idempotent: granting an owned item succeeds without change.
function CosmeticRules.grant(s: State, catalog: Catalog, id: string): (boolean, string?)
	if catalog.Items[id] == nil then
		return false, "unknown"
	end
	if s.entitlements[id] then
		return true, "alreadyOwned"
	end
	local n = 0
	for _ in s.entitlements do
		n += 1
	end
	if n >= CatalogConfig.MaxEntitlements then
		return false, "full"
	end
	s.entitlements[id] = true
	return true, nil
end

local function equipCheck(s: State, catalog: Catalog, id: string, category: string, species: string?): string?
	local item = catalog.Items[id]
	if item == nil then
		return "unknown"
	elseif not s.entitlements[id] then
		return "notOwned"
	elseif item.category ~= category then
		return "wrongCategory"
	elseif species and item.species and table.find(item.species, species) == nil then
		return "incompatible"
	end
	return nil
end

-- slot is "skin" or "aura"; species is the owned ghost's species (nil if the UID isn't owned).
function CosmeticRules.equipLook(
	s: State,
	catalog: Catalog,
	uid: string,
	species: string?,
	slot: string,
	id: string
): (boolean, string?)
	if species == nil then
		return false, "noGhost"
	end
	local category = if slot == "skin" then "Skin" elseif slot == "aura" then "Aura" else nil
	if category == nil then
		return false, "badSlot"
	end
	local err = equipCheck(s, catalog, id, category, species)
	if err then
		return false, err
	end
	local look: GhostLook = s.ghostLooks[uid] or {}
	if slot == "skin" then
		look.skin = id
	else
		look.aura = id
	end
	s.ghostLooks[uid] = look
	return true, nil
end

-- Removing a skin restores the natural look; removing an aura clears that layer. Ownership is kept.
function CosmeticRules.removeLook(s: State, uid: string, slot: string): (boolean, string?)
	local look = s.ghostLooks[uid]
	if slot ~= "skin" and slot ~= "aura" then
		return false, "badSlot"
	end
	if look then
		if slot == "skin" then
			look.skin = nil
		else
			look.aura = nil
		end
		if look.skin == nil and look.aura == nil then
			s.ghostLooks[uid] = nil
		end
	end
	return true, nil
end

-- id = nil clears the selection.
function CosmeticRules.setCaptureEffect(s: State, catalog: Catalog, id: string?): (boolean, string?)
	if id ~= nil then
		local err = equipCheck(s, catalog, id, "CaptureEffect")
		if err then
			return false, err
		end
	end
	s.captureEffect = id
	return true, nil
end

-- Equipping requires the theme to cover the current house tier; id = nil returns to the default exterior.
function CosmeticRules.setTheme(s: State, catalog: Catalog, id: string?, houseTier: number): (boolean, string?)
	if id ~= nil then
		local err = equipCheck(s, catalog, id, "Theme")
		if err then
			return false, err
		end
		local tiers = catalog.Items[id].tiers
		if tiers == nil or table.find(tiers, houseTier) == nil then
			return false, "tier"
		end
	end
	s.mansionTheme = id
	return true, nil
end

-- Places an owned, reusable decoration at plot-local (x, z). Geometry against gameplay areas is the world
-- task's check; this rule bounds the plot, rotation, per-item limit and total.
function CosmeticRules.place(
	s: State,
	catalog: Catalog,
	id: string,
	x: number,
	z: number,
	r: number
): (boolean, string?)
	local err = equipCheck(s, catalog, id, "Decoration")
	if err then
		return false, err
	elseif not inPlot(x, z) then
		return false, "outOfPlot"
	elseif not validRotation(r) then
		return false, "rotation"
	elseif #s.placements >= CatalogConfig.MaxPlacements then
		return false, "full"
	elseif placedCount(s, id) >= limitOf(catalog, id) then
		return false, "limit"
	end
	table.insert(s.placements, { id = id, x = x, z = z, r = r })
	return true, nil
end

-- Stores a placed decoration again (index into placements). Ownership is kept.
function CosmeticRules.removePlacement(s: State, index: number): (boolean, string?)
	if type(index) ~= "number" or s.placements[index] == nil then
		return false, "noPlacement"
	end
	table.remove(s.placements, index)
	return true, nil
end

-- Marks a reward claimed and grants its items, once. Eligibility is the caller's check (milestones are a
-- later task). A second claim is refused, so a retry never awards twice.
function CosmeticRules.claimReward(s: State, catalog: Catalog, rewardId: string): (boolean, string?)
	local reward = catalog.Rewards[rewardId]
	if reward == nil then
		return false, "unknown"
	elseif s.rewardsClaimed[rewardId] then
		return false, "claimed"
	end
	for _, id in reward.grants do
		if catalog.Items[id] == nil then
			return false, "badReward"
		end
	end
	for _, id in reward.grants do
		local ok, why = CosmeticRules.grant(s, catalog, id)
		if not ok then
			return false, why
		end
	end
	s.rewardsClaimed[rewardId] = true
	return true, nil
end

return CosmeticRules
