--!strict
-- Pure player-profile rules (TASK-0099): defaults, sanitising stored and client data, merging a save into what is
-- already stored, and the payload the menu receives. No Instances, no services. Nothing here throws on bad input.
-- Stored data is lenient (bad fields fall back); client settings are strict (anything off is rejected whole).
-- Saves are exactly-once for the glyph total (TASK-0139 rev 2, schema v3): every save is an operation (session id, seq)
-- and the profile keeps a small save log `applied` of the last seq each session wrote, so a retried operation that had
-- already committed is never credited twice.

local MenuConfig = require(script.Parent.MenuConfig)

export type Settings = {
	music: number,
	sfx: number,
	reducedMotion: boolean,
	colorBlind: boolean,
	haptics: boolean,
}
export type Profile = {
	version: number,
	settings: Settings,
	bestRank: number?, -- 0..9, never decreases
	lastTestRank: number?, -- rank cleared by the last Skill Test, with lastTakenAt
	lastTakenAt: number?, -- os.time() of the last Skill Test start; the cooldown runs from it
	blitzBest: number?, -- 0..MenuConfig.BlitzTotal, never decreases
	glyphsLifetime: number?, -- hub glyph value collected over all visits (TASK-0138), never decreases
	applied: AppliedLog?, -- v3 save log: the last operation each server session committed (TASK-0139)
}
export type AppliedEntry = { seq: number, at: number }
export type AppliedLog = { [string]: AppliedEntry }
export type Patch = {
	settings: Settings?,
	bestRank: number?,
	lastTestRank: number?,
	lastTakenAt: number?,
	blitzBest: number?,
	glyphsDelta: number?, -- glyph value earned since the last confirmed save; ADDED to the stored total (AUD-02 F2)
}
-- One save. A retry of an operation that may have committed reuses its seq and delta, so the save log can tell.
export type SaveOp = {
	sessionId: string, -- one per server session of a player (HttpService GUID)
	seq: number, -- 1, 2, 3 ... per session; never reused for a different delta
	glyphsDelta: number,
	patch: Patch, -- the idempotent fields (settings, bests, test clock); its glyphsDelta is ignored
}
export type ClientProfile = {
	rank: number?,
	lastTestRank: number?,
	retryAt: number?,
	blitzBest: number?,
	settings: Settings,
	modes: { blitz: boolean, vs: boolean, group: boolean },
	persistence: string, -- "saved" | "memory": memory means progress is not kept (Studio / unpublished place)
}

local VERSION = 3 -- 2: glyphsLifetime (TASK-0138); 3: applied save log (TASK-0139, jg approval S1 2026-11-06)
local MAX_GLYPHS = 2 ^ 53 -- the largest exact integer; a total can never overflow into noise
local MAX_TIME = 2 ^ 40 -- far beyond any os.time(), keeps garbage out
local UNAVAILABLE = { "publish", "studioaccesstoapisnotallowed", "403", "not allowed", "api services" }
local SAVE_LOG_SECONDS = 604800 -- 7 days: a save log entry older than this is dropped (no session lives that long)
local SAVE_LOG_CAP = 200 -- at most this many sessions in the log, the oldest `at` dropped first
local MAX_SESSION_ID = 64
local SETTING_KEYS = { "music", "sfx", "reducedMotion", "colorBlind", "haptics" }
local KNOWN_KEYS =
	{ "version", "settings", "bestRank", "lastTestRank", "lastTakenAt", "blitzBest", "glyphsLifetime", "applied" }
-- Known table-valued fields that are records: a save overlays their known keys onto a clone of the stored table, so a
-- sub-key this build does not know survives (AUD-02 F2 of TASK-0139). `applied` is a map this build owns entirely (its
-- entries are pruned), so it is written whole.
local RECORD_KEYS: { [string]: { string } } = { settings = SETTING_KEYS }

local ProfileRules = {}

local function isInt(value: any, low: number, high: number): boolean
	return typeof(value) == "number"
		and value == value
		and value == math.floor(value)
		and value >= low
		and value <= high
end

local function isTime(value: any): boolean
	return typeof(value) == "number" and value == value and value >= 0 and value <= MAX_TIME
end

local function isFinite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isSessionId(value: any): boolean
	return typeof(value) == "string" and #value > 0 and #value <= MAX_SESSION_ID
end

function ProfileRules.defaultSettings(): Settings
	local d = MenuConfig.SettingsDefaults
	return {
		music = d.music,
		sfx = d.sfx,
		reducedMotion = d.reducedMotion,
		colorBlind = d.colorBlind,
		haptics = d.haptics,
	}
end

function ProfileRules.defaults(): Profile
	return { version = VERSION, settings = ProfileRules.defaultSettings(), glyphsLifetime = 0, applied = {} }
end

-- Keeps the SAVE_LOG_CAP newest entries (by `at`, ties by session id), always keeping `keep`. Mutates `log`.
local function capLog(log: AppliedLog, keep: string?)
	local ids = {}
	for id in log do
		table.insert(ids, id)
	end
	if #ids <= SAVE_LOG_CAP then
		return
	end
	table.sort(ids, function(a: string, b: string): boolean
		if a == keep then
			return b ~= keep
		elseif b == keep then
			return false
		end
		local atA, atB = log[a].at, log[b].at
		if atA ~= atB then
			return atA > atB
		end
		return a < b
	end)
	for i = SAVE_LOG_CAP + 1, #ids do
		log[ids[i]] = nil
	end
end

-- A clean copy of a stored save log: entries with a non-empty session id of at most 64 characters, a positive integer
-- seq and a finite `at` survive; anything else is dropped. With `now`, entries older than 7 days are dropped (exactly
-- 7 days is kept). Capped at SAVE_LOG_CAP entries, oldest `at` first.
function ProfileRules.sanitizeApplied(raw: any, now: number?): AppliedLog
	local out: AppliedLog = {}
	if typeof(raw) ~= "table" then
		return out
	end
	local oldest = if now ~= nil and isFinite(now) then now - SAVE_LOG_SECONDS else nil
	for id, entry in raw do
		if
			isSessionId(id)
			and typeof(entry) == "table"
			and isInt(entry.seq, 1, MAX_GLYPHS)
			and isFinite(entry.at)
			and (oldest == nil or entry.at >= oldest)
		then
			out[id] = { seq = entry.seq, at = entry.at }
		end
	end
	capLog(out, nil)
	return out
end

-- Any stored number as a valid lifetime total: non-finite, negative or non-number -> 0, fractions floored, capped.
local function cleanGlyphs(value: any): number
	if typeof(value) ~= "number" or value ~= value or value <= 0 or value == math.huge then
		return 0
	end
	return math.min(math.floor(value), MAX_GLYPHS)
end

-- Brings stored data up to VERSION without touching anything else: a shallow copy that keeps unknown fields, adds
-- glyphsLifetime = 0 when missing and cleans a bad one, and (below v3) adds an empty save log. Idempotent. A newer version is returned as a copy, untouched
-- (never downgraded); a missing or garbage version counts as the oldest. Non-tables are returned as they are.
function ProfileRules.migrate(data: any): any
	if typeof(data) ~= "table" then
		return data
	end
	local out = table.clone(data)
	local version = out.version
	if typeof(version) ~= "number" or version ~= version then
		version = 0
	end
	if version > VERSION then
		return out
	end
	out.glyphsLifetime = cleanGlyphs(out.glyphsLifetime)
	if version < 3 then
		out.applied = {}
	end
	out.version = math.max(math.floor(version), VERSION)
	return out
end

-- Was this stored data written by a newer server than this build? Such a profile must not be saved back: sanitize()
-- drops fields this build does not know, and the newer version number would then hide that loss.
function ProfileRules.isNewerVersion(data: any): boolean
	return typeof(data) == "table"
		and typeof(data.version) == "number"
		and data.version == data.version
		and data.version > VERSION
end

-- A copy with `amount` added to the lifetime total. Anything but a finite positive integer leaves the total as it is.
function ProfileRules.addGlyphs(data: Profile, amount: any): Profile
	local out = table.clone(data)
	local valid = typeof(amount) == "number" and amount > 0 and amount < math.huge and amount == math.floor(amount)
	if valid then
		out.glyphsLifetime = math.min(cleanGlyphs(out.glyphsLifetime) + amount, MAX_GLYPHS)
	end
	return out
end

-- Strict: exactly the five keys, integers 0..SettingMax and booleans. Returns a fresh table, or nil for anything else
-- (non-table, missing or extra keys, wrong types, out of range, NaN, fractions).
function ProfileRules.sanitizeSettings(raw: any): Settings?
	if typeof(raw) ~= "table" then
		return nil
	end
	local count = 0
	for key in raw do
		if table.find(SETTING_KEYS, key) == nil then
			return nil
		end
		count += 1
	end
	if count ~= #SETTING_KEYS then
		return nil
	end
	local max = MenuConfig.SettingMax
	if not (isInt(raw.music, 0, max) and isInt(raw.sfx, 0, max)) then
		return nil
	end
	if
		typeof(raw.reducedMotion) ~= "boolean"
		or typeof(raw.colorBlind) ~= "boolean"
		or typeof(raw.haptics) ~= "boolean"
	then
		return nil
	end
	return {
		music = raw.music,
		sfx = raw.sfx,
		reducedMotion = raw.reducedMotion,
		colorBlind = raw.colorBlind,
		haptics = raw.haptics,
	}
end

-- Lenient: keeps every valid stored field and replaces the rest with defaults / nil.
function ProfileRules.sanitize(raw: any): Profile
	local profile = ProfileRules.defaults()
	if typeof(raw) ~= "table" then
		return profile
	end
	if typeof(raw.settings) == "table" then
		local s = raw.settings
		local max = MenuConfig.SettingMax
		if isInt(s.music, 0, max) then
			profile.settings.music = s.music
		end
		if isInt(s.sfx, 0, max) then
			profile.settings.sfx = s.sfx
		end
		if typeof(s.reducedMotion) == "boolean" then
			profile.settings.reducedMotion = s.reducedMotion
		end
		if typeof(s.colorBlind) == "boolean" then
			profile.settings.colorBlind = s.colorBlind
		end
		if typeof(s.haptics) == "boolean" then
			profile.settings.haptics = s.haptics
		end
	end
	if isInt(raw.bestRank, 0, 9) then
		profile.bestRank = raw.bestRank
	end
	if isInt(raw.lastTestRank, 0, 9) then
		profile.lastTestRank = raw.lastTestRank
	end
	if isTime(raw.lastTakenAt) then
		profile.lastTakenAt = raw.lastTakenAt
	end
	if isInt(raw.blitzBest, 0, MenuConfig.BlitzTotal) then
		profile.blitzBest = raw.blitzBest
	end
	profile.glyphsLifetime = cleanGlyphs(raw.glyphsLifetime)
	profile.applied = ProfileRules.sanitizeApplied(raw.applied, nil)
	if typeof(raw.version) == "number" and raw.version == raw.version and raw.version > VERSION then
		profile.version = math.floor(raw.version) -- written by a newer server: keep its number
	end
	return profile
end

local function maxOf(a: number?, b: number?): number?
	if a == nil then
		return b
	elseif b == nil then
		return a
	end
	return math.max(a, b)
end

-- The stored table with every field this build knows replaced by its clean value (nil when invalid or absent) and every
-- other field left exactly as stored. sanitize() alone would drop those fields, and an UpdateAsync that returns the
-- sanitized table erases them from the store (AUD-02 F1). Record fields (settings) get the same treatment one level
-- down: known keys overlaid onto a clone of the stored record, unknown sub-keys kept (TASK-0139 AUD-02 F2).
local function overlay(stored: any, clean: Profile): Profile
	local out: { [any]: any } = if typeof(stored) == "table" then table.clone(stored) else {}
	local cleaned: { [any]: any } = clean :: any
	for _, key in KNOWN_KEYS do
		local subKeys = RECORD_KEYS[key]
		local value = cleaned[key]
		if subKeys ~= nil and typeof(value) == "table" then
			local record: { [any]: any } = if typeof(out[key]) == "table" then table.clone(out[key]) else {}
			for _, subKey in subKeys do
				record[subKey] = value[subKey]
			end
			out[key] = record
		else
			out[key] = value
		end
	end
	return out :: any
end

local function copySettings(settings: Settings): Settings
	return {
		music = settings.music,
		sfx = settings.sfx,
		reducedMotion = settings.reducedMotion,
		colorBlind = settings.colorBlind,
		haptics = settings.haptics,
	}
end

-- Folds `patch` into whatever is stored (UpdateAsync transform). Bests and the test time only ever go up, so a server
-- with older data cannot lower them; settings are last writer wins; the last test rank follows the newest test. The glyph
-- total is ADDED to (stored + patch.glyphsDelta): a counter built from independent increments cannot be max-merged without
-- losing some of them (AUD-02 F2). Fields this build does not know are kept as stored.
function ProfileRules.merge(stored: any, patch: Patch): Profile
	local base = ProfileRules.sanitize(stored)
	local clean = ProfileRules.sanitize({
		settings = patch.settings,
		bestRank = patch.bestRank,
		lastTestRank = patch.lastTestRank,
		lastTakenAt = patch.lastTakenAt,
		blitzBest = patch.blitzBest,
	})
	if patch.settings ~= nil and ProfileRules.sanitizeSettings(patch.settings) ~= nil then
		base.settings = clean.settings
	end
	base.bestRank = maxOf(base.bestRank, clean.bestRank)
	base.blitzBest = maxOf(base.blitzBest, clean.blitzBest)
	base.glyphsLifetime = math.min(cleanGlyphs(base.glyphsLifetime) + cleanGlyphs(patch.glyphsDelta), MAX_GLYPHS)
	if clean.lastTakenAt ~= nil then
		local newer = base.lastTakenAt == nil or clean.lastTakenAt > base.lastTakenAt
		if newer or (clean.lastTakenAt == base.lastTakenAt and clean.lastTestRank ~= nil) then
			base.lastTakenAt = clean.lastTakenAt
			base.lastTestRank = clean.lastTestRank
		end
	end
	return overlay(stored, base)
end

-- The session profile after a confirmed save: what UpdateAsync returned (another server may have raised a best or added
-- glyphs), our settings and bests folded in, and the glyph increments that arrived while the save was in flight
-- (`pending`, not yet in the stored total) added on top. Sanitized: the in-memory copy never carries stored fields or
-- settings sub-keys this build does not know (they stay in the store; the next save overlays onto them again).
function ProfileRules.adopt(result: any, current: Profile, pending: number): Profile
	local adopted = ProfileRules.sanitize(ProfileRules.merge(result, ProfileRules.toPatch(current)))
	adopted.glyphsLifetime = ProfileRules.addGlyphs(ProfileRules.merge(result, {}), pending).glyphsLifetime
	return adopted
end

-- The UpdateAsync transform for one save operation, exactly-once for the glyph total. Returns the value to write and
-- whether the operation had already been applied, or nil (cancel the write) when:
--  * the stored data was written by a newer build than this one, even if it only became newer after this session loaded
--    (returning it with its fields dropped and only the version number kept would hide the loss, AUD-02 F1), or
--  * the operation has no valid identity (session id, positive integer seq) or `now` is not finite.
-- When the save log already holds this session's seq or a later one, the delta is NOT added again (the operation
-- committed before, e.g. UpdateAsync wrote and then errored); the idempotent fields are still overlaid. Otherwise the
-- delta is added and the log records { seq, at = now }. The log is pruned (7 days) and capped on every write.
function ProfileRules.planSave(stored: any, op: SaveOp, now: number): (Profile?, boolean)
	if ProfileRules.isNewerVersion(stored) then
		return nil, false
	end
	if
		typeof(op) ~= "table"
		or not isSessionId(op.sessionId)
		or not isInt(op.seq, 1, MAX_GLYPHS)
		or not isFinite(now)
	then
		return nil, false
	end
	local log = ProfileRules.sanitizeApplied(if typeof(stored) == "table" then stored.applied else nil, now)
	local prior = log[op.sessionId]
	local alreadyApplied = prior ~= nil and op.seq <= prior.seq
	local patch: Patch = if typeof(op.patch) == "table" then table.clone(op.patch) else {}
	patch.glyphsDelta = if alreadyApplied then 0 else op.glyphsDelta
	local out = ProfileRules.merge(stored, patch)
	if not alreadyApplied then
		log[op.sessionId] = { seq = op.seq, at = now }
		capLog(log, op.sessionId)
	end
	out.applied = log
	return out, alreadyApplied
end

-- Everything in a profile as a patch (autosave and release): merge() makes it safe against older in-memory data. The glyph
-- total is not part of it: the caller supplies glyphsDelta. Settings are copied key by key, so a stray sub-key can never
-- make the strict settings check reject the patch.
function ProfileRules.toPatch(profile: Profile): Patch
	return {
		settings = copySettings(profile.settings),
		bestRank = profile.bestRank,
		lastTestRank = profile.lastTestRank,
		lastTakenAt = profile.lastTakenAt,
		blitzBest = profile.blitzBest,
	}
end

function ProfileRules.retryAt(lastTakenAt: number?, cooldown: number?): number?
	if lastTakenAt == nil or not isTime(lastTakenAt) then
		return nil
	end
	return lastTakenAt + (cooldown or MenuConfig.RetakeCooldownSeconds)
end

function ProfileRules.toClient(profile: Profile, persistence: string): ClientProfile
	local modes = MenuConfig.ModeEnabled
	return {
		rank = profile.bestRank,
		lastTestRank = profile.lastTestRank,
		retryAt = ProfileRules.retryAt(profile.lastTakenAt, nil),
		blitzBest = profile.blitzBest,
		settings = copySettings(profile.settings),
		modes = { blitz = modes.blitz == true, vs = modes.vs == true, group = modes.group == true },
		persistence = persistence,
	}
end

-- Is a DataStore error "the API is unavailable here" (Studio without API access, unpublished place)? Only a development
-- place may then run in memory mode; a live server retries and ends read-only.
function ProfileRules.loadFailure(message: string, developmentPlace: boolean): "memory" | "retry"
	local lowered = string.lower(tostring(message))
	for _, needle in UNAVAILABLE do
		if string.find(lowered, needle, 1, true) then
			return if developmentPlace then "memory" else "retry"
		end
	end
	return "retry"
end

return ProfileRules
