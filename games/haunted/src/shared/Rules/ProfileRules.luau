--!strict
-- Player profile schema, defaults and sanitising. Pure: no Roblox services, so it is unit-tested.
-- sanitize() never trusts stored data: every field is type-checked and clamped, unknown species are
-- dropped, and unknown top-level fields are preserved so a future schema's data is not destroyed.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)
local Monsters = require(Shared.Config.Monsters)
local Variants = require(Shared.Config.Variants)
local Track = require(Shared.Config.Track)
local Catalog = require(Shared.Config.Catalog)
local CosmeticRules = require(script.Parent.CosmeticRules)

local ProfileRules = {}

-- 1: original. 2 (TASK-0060): `cosmetics` (entitlements, ghost looks, capture effect, theme, decoration
-- placements, reward claims). A schema-1 profile migrates by gaining empty cosmetics; nothing else changes.
ProfileRules.Schema = 2
ProfileRules.MaxOwned = 40

export type OwnedMonster = { uid: string, species: string, variant: string, acquiredAt: number }
export type RoutePoint = { x: number, z: number }
export type RoutePiece = { i: number, kind: string }
export type Route = { points: { RoutePoint }, pieces: { RoutePiece } }
export type Exhibit = { slot: number, uid: string }

export type Profile = {
	schema: number,
	coins: number,
	speedLevel: number,
	houseTier: number,
	owned: { OwnedMonster },
	nextUid: number,
	journal: {
		seen: { [string]: boolean },
		caught: { [string]: boolean },
		variants: { [string]: boolean }, -- "Species:Variant"
		clues: { [string]: boolean }, -- retired (ADR-0007): kept so old profiles round-trip unchanged
	},
	flags: { [string]: boolean },
	stats: { rides: number, captures: number, escapes: number },
	route: Route?,
	exhibits: { Exhibit },
	tutorialStep: number,
	lastSeen: number,
	cosmetics: CosmeticRules.State,
	[string]: any,
}

local KNOWN_FLAGS = {
	-- Retired with clue hunting (ADR-0007): nothing sets or reads these any more, but they stay known so
	-- sanitize() keeps them in older profiles instead of dropping them.
	shortcut = true,
	bellHint = true,
	bellClue = true,
	onboarded = true,
	routeCustom = true,
	captureTried = true,
	journalOpened = true,
	mansionOpened = true,
}

function ProfileRules.default(): Profile
	return {
		schema = ProfileRules.Schema,
		coins = Economy.StartingCoins,
		speedLevel = 0,
		houseTier = 0,
		owned = {},
		nextUid = 1,
		journal = { seen = {}, caught = {}, variants = {}, clues = {} },
		flags = {},
		stats = { rides = 0, captures = 0, escapes = 0 },
		route = nil,
		exhibits = {},
		tutorialStep = 1,
		lastSeen = 0,
		cosmetics = CosmeticRules.default(),
	}
end

local function num(v: any, lo: number, hi: number, fallback: number, integer: boolean?): number
	if type(v) ~= "number" or v ~= v then
		return fallback
	end
	local n = math.clamp(v, lo, hi)
	return if integer then math.floor(n) else n
end

local function boolSet(v: any, allowed: ((string) -> boolean)?): { [string]: boolean }
	local out = {}
	if type(v) == "table" then
		for k, flag in v do
			if type(k) == "string" and flag == true and (allowed == nil or allowed(k)) then
				out[k] = true
			end
		end
	end
	return out
end

local function isSpecies(id: string): boolean
	return Monsters.Species[id] ~= nil
end

local function isVariantKey(key: string): boolean
	local species, variant = string.match(key, "^(%w+):(%w+)$")
	return species ~= nil and isSpecies(species) and variant ~= nil and Variants.ById[variant] ~= nil
end

function ProfileRules.sanitizeRoute(v: any): Route?
	if type(v) ~= "table" or type(v.points) ~= "table" then
		return nil
	end
	local points: { RoutePoint } = {}
	for _, p in v.points do
		if type(p) ~= "table" or type(p.x) ~= "number" or type(p.z) ~= "number" or p.x ~= p.x or p.z ~= p.z then
			return nil
		end
		table.insert(points, { x = math.clamp(p.x, -1000, 1000), z = math.clamp(p.z, -1000, 1000) })
		if #points > Track.MaxPoints then
			return nil
		end
	end
	local pieces: { RoutePiece } = {}
	if type(v.pieces) == "table" then
		for _, piece in v.pieces do
			if
				type(piece) == "table"
				and type(piece.i) == "number"
				and type(piece.kind) == "string"
				and Track.Pieces[piece.kind] ~= nil
				and piece.i >= 1
				and piece.i <= #points
				and #pieces < Track.MaxPieces
			then
				table.insert(pieces, { i = math.floor(piece.i), kind = piece.kind })
			end
		end
	end
	return { points = points, pieces = pieces }
end

-- True when stored data was written by a newer schema than this server understands.
function ProfileRules.isNewerSchema(raw: any): boolean
	return type(raw) == "table" and type(raw.schema) == "number" and raw.schema > ProfileRules.Schema
end

-- How a loaded profile may be persisted. A profile saved by a newer schema is read-only: this (older)
-- server plays with a sanitised copy but must never write it back and strip fields it doesn't know.
function ProfileRules.persistenceFor(mode: string, raw: any): string
	if mode == "saved" and ProfileRules.isNewerSchema(raw) then
		return "readonly"
	end
	return mode
end

-- Returns a fully valid profile built from untrusted data, plus a list of repaired field names.
-- `catalog` defaults to Config.Catalog; specs pass a test catalog.
function ProfileRules.sanitize(raw: any, now: number, catalog: CosmeticRules.Catalog?): (Profile, { string })
	local repaired: { string } = {}
	local p = ProfileRules.default()
	if type(raw) ~= "table" then
		if raw ~= nil then
			table.insert(repaired, "root")
		end
		return p, repaired
	end

	-- Preserve unknown top-level fields (forward compatibility; never drop data on migration).
	for k, v in raw do
		if type(k) == "string" and p[k] == nil and k ~= "route" then
			p[k] = v
		end
	end

	local function fix(name: string, ok: boolean)
		if not ok then
			table.insert(repaired, name)
		end
	end

	p.coins = num(raw.coins, 0, Economy.MaxCoins, Economy.StartingCoins, true)
	fix("coins", p.coins == raw.coins)
	p.speedLevel = num(raw.speedLevel, 0, #Economy.SpeedLevelCosts, 0, true)
	fix("speedLevel", p.speedLevel == raw.speedLevel)
	p.houseTier = num(raw.houseTier, 0, #Economy.HouseTiers - 1, 0, true)
	fix("houseTier", p.houseTier == raw.houseTier)
	p.tutorialStep = num(raw.tutorialStep, 1, 99, 1, true)
	fix("tutorialStep", p.tutorialStep == raw.tutorialStep)
	p.lastSeen = num(raw.lastSeen, 0, now + 60, 0)

	local maxUid = 0
	local seenUid: { [string]: boolean } = {}
	if type(raw.owned) == "table" then
		for _, m in raw.owned do
			if
				type(m) == "table"
				and type(m.uid) == "string"
				and not seenUid[m.uid]
				and type(m.species) == "string"
				and isSpecies(m.species)
				and #p.owned < ProfileRules.MaxOwned
			then
				local variant = if type(m.variant) == "string" and Variants.ById[m.variant]
					then m.variant
					else Variants.Normal
				seenUid[m.uid] = true
				table.insert(p.owned, {
					uid = m.uid,
					species = m.species,
					variant = variant,
					acquiredAt = num(m.acquiredAt, 0, now, now),
				})
				local n = tonumber(string.match(m.uid, "^m(%d+)$"))
				if n and n > maxUid then
					maxUid = n
				end
			else
				fix("owned", false)
			end
		end
	end
	p.nextUid = math.max(num(raw.nextUid, 1, 1e9, 1, true), maxUid + 1)

	local j = if type(raw.journal) == "table" then raw.journal else {}
	p.journal.seen = boolSet(j.seen, isSpecies)
	p.journal.caught = boolSet(j.caught, isSpecies)
	p.journal.variants = boolSet(j.variants, isVariantKey)
	p.journal.clues = boolSet(j.clues)
	-- Anything owned is, by definition, caught and seen.
	for _, m in p.owned do
		p.journal.caught[m.species] = true
		p.journal.seen[m.species] = true
		if m.variant ~= Variants.Normal then
			p.journal.variants[m.species .. ":" .. m.variant] = true
		end
	end

	p.flags = boolSet(raw.flags, function(k)
		return KNOWN_FLAGS[k] == true
	end)

	local s = if type(raw.stats) == "table" then raw.stats else {}
	p.stats = {
		rides = num(s.rides, 0, 1e9, 0, true),
		captures = num(s.captures, 0, 1e9, 0, true),
		escapes = num(s.escapes, 0, 1e9, 0, true),
	}

	if raw.route ~= nil then
		p.route = ProfileRules.sanitizeRoute(raw.route)
		fix("route", p.route ~= nil)
	end

	local slots = Economy.HouseTiers[p.houseTier + 1].exhibitSlots
	local usedSlot: { [number]: boolean } = {}
	local usedUid: { [string]: boolean } = {}
	if type(raw.exhibits) == "table" then
		for _, e in raw.exhibits do
			if
				type(e) == "table"
				and type(e.slot) == "number"
				and e.slot % 1 == 0
				and e.slot >= 1
				and e.slot <= slots
				and not usedSlot[e.slot]
				and type(e.uid) == "string"
				and seenUid[e.uid]
				and not usedUid[e.uid]
			then
				usedSlot[e.slot] = true
				usedUid[e.uid] = true
				table.insert(p.exhibits, { slot = math.floor(e.slot), uid = e.uid })
			else
				fix("exhibits", false)
			end
		end
	end

	local speciesByUid: { [string]: string } = {}
	for _, m in p.owned do
		speciesByUid[m.uid] = m.species
	end
	local rawCosmetics = raw.cosmetics
	if rawCosmetics ~= nil and type(rawCosmetics) ~= "table" then
		fix("cosmetics", false)
		rawCosmetics = nil
	end
	local cosmeticFixes
	p.cosmetics, cosmeticFixes = CosmeticRules.sanitize(rawCosmetics or {}, speciesByUid, catalog or Catalog)
	for _, name in cosmeticFixes do
		table.insert(repaired, "cosmetics." .. name)
	end

	p.schema = ProfileRules.Schema
	return p, repaired
end

function ProfileRules.findOwned(p: Profile, uid: string): OwnedMonster?
	for _, m in p.owned do
		if m.uid == uid then
			return m
		end
	end
	return nil
end

function ProfileRules.exhibitSlotOf(p: Profile, uid: string): number?
	for _, e in p.exhibits do
		if e.uid == uid then
			return e.slot
		end
	end
	return nil
end

function ProfileRules.capacity(p: Profile): number
	return Economy.HouseTiers[p.houseTier + 1].containment
end

return ProfileRules
