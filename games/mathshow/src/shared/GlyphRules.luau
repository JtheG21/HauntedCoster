--!strict
local GlyphConfig = require(script.Parent.GlyphConfig)

export type Position = { x: number, y: number, z: number }
export type Rarity = "common" | "rare"
export type Spawn = { id: string, position: Position, rarity: Rarity }
export type GlyphState = { rarity: Rarity, collected: boolean, respawnAt: number? }
export type PlayerState = {
	glyphs: { [string]: GlyphState },
	sessionCount: number,
	collectTimes: { number },
}
export type SpawnRecord = { id: string, rarity: string, x: number, y: number, z: number }

local GlyphRules = {}

local function finite(value: unknown): boolean
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Turns raw spawn records (read from the map) into trusted spawns, in input order. A record with an unknown rarity, an
-- id already seen or a non-finite coordinate is dropped with one warning each; the first record with an id wins.
function GlyphRules.parseSpawns(records: { SpawnRecord }): ({ Spawn }, { string })
	local spawns: { Spawn } = {}
	local warnings: { string } = {}
	local seen: { [string]: boolean } = {}
	for index, record in records do
		local id = record.id
		if type(id) ~= "string" or id == "" then
			table.insert(warnings, `record {index}: missing id`)
		elseif seen[id] then
			table.insert(warnings, `{id}: duplicate id`)
		elseif not table.find(GlyphConfig.Rarity, record.rarity) then
			table.insert(warnings, `{id}: unknown rarity {tostring(record.rarity)}`)
		elseif not (finite(record.x) and finite(record.y) and finite(record.z)) then
			table.insert(warnings, `{id}: non-finite position`)
		else
			seen[id] = true
			local rarity: Rarity = (record.rarity :: any) :: Rarity -- checked against GlyphConfig.Rarity above
			local spawn: Spawn = { id = id, position = { x = record.x, y = record.y, z = record.z }, rarity = rarity }
			table.insert(spawns, spawn)
		end
	end
	return spawns, warnings
end

-- Spawns are trusted configuration with unique ids. State belongs to one player.
function GlyphRules.newPlayerState(spawns: { Spawn }): PlayerState
	local glyphs: { [string]: GlyphState } = {}
	for _, spawn in spawns do
		glyphs[spawn.id] = { rarity = spawn.rarity, collected = false, respawnAt = nil }
	end
	return { glyphs = glyphs, sessionCount = 0, collectTimes = {} }
end

local function copyState(state: PlayerState): PlayerState
	local glyphs: { [string]: GlyphState } = {}
	for id, glyph in state.glyphs do
		glyphs[id] = table.clone(glyph)
	end
	return { glyphs = glyphs, sessionCount = state.sessionCount, collectTimes = table.clone(state.collectTimes) }
end

-- First failing reason wins; a non-finite `now` is "bad_time". Expiration is applied explicitly by tickRespawns.
-- Callers supply finite positions and monotonically increasing timestamps.
function GlyphRules.validateCollect(
	state: PlayerState,
	glyphId: unknown,
	playerPos: Position,
	now: number,
	spawns: { Spawn }
): (boolean, string)
	if not finite(now) then
		return false, "bad_time"
	end
	if type(glyphId) ~= "string" then
		return false, "invalid_type"
	end
	local found: Spawn? = nil
	for _, spawn in spawns do
		if spawn.id == glyphId then
			found = spawn
			break
		end
	end
	local glyph = state.glyphs[glyphId]
	if not found or not glyph then
		return false, "unknown_id"
	end
	local dx = playerPos.x - found.position.x
	local dy = playerPos.y - found.position.y
	local dz = playerPos.z - found.position.z
	if not (dx * dx + dy * dy + dz * dz <= GlyphConfig.CollectRadius ^ 2) then
		return false, "out_of_range"
	end
	if glyph.collected then
		return false, "already_collected"
	end
	local count = 0
	for _, collectedAt in state.collectTimes do
		if collectedAt > now - GlyphConfig.RateWindowSeconds then
			count += 1
		end
	end
	if count >= GlyphConfig.RateLimit then
		return false, "rate_limited"
	end
	return true, "ok"
end

-- Apply only after successful validation, without a yield between the two calls.
function GlyphRules.applyCollect(state: PlayerState, glyphId: string, now: number): PlayerState
	local nextState = copyState(state)
	local glyph = nextState.glyphs[glyphId]
	assert(glyph and not glyph.collected, "applyCollect requires an available known glyph")
	glyph.collected = true
	glyph.respawnAt = now + GlyphConfig.RespawnSeconds[glyph.rarity]
	nextState.sessionCount += GlyphConfig.Value[glyph.rarity]
	local recent: { number } = {}
	for _, collectedAt in state.collectTimes do
		if collectedAt > now - GlyphConfig.RateWindowSeconds then
			table.insert(recent, collectedAt)
		end
	end
	table.insert(recent, now)
	nextState.collectTimes = recent
	return nextState
end

-- Client cadence: ask for a glyph that is available and in reach, at most once per RetryAfterSeconds. Local timing only;
-- the server stays authoritative. A non-finite `now` never asks.
function GlyphRules.shouldRequest(lastRequestAt: number?, now: number, inRange: boolean, available: boolean): boolean
	if not finite(now) or not (available and inRange) then
		return false
	end
	return lastRequestAt == nil or now - lastRequestAt >= GlyphConfig.RetryAfterSeconds
end

function GlyphRules.tickRespawns(state: PlayerState, now: number): PlayerState
	local nextState = copyState(state)
	for _, glyph in nextState.glyphs do
		if glyph.collected and glyph.respawnAt and now >= glyph.respawnAt then
			glyph.collected = false
			glyph.respawnAt = nil
		end
	end
	return nextState
end

return GlyphRules
