--!strict
-- Pure player-profile rules (TASK-0099): defaults, sanitising stored and client data, merging a save into what is
-- already stored, and the payload the menu receives. No Instances, no services. Nothing here throws on bad input.
-- Stored data is lenient (bad fields fall back); client settings are strict (anything off is rejected whole).
-- Glyph saves are at most once (TASK-0141, schema v3): every save is an immutable operation (session id, seq, delta,
-- createdAt) and the profile keeps a receipt log `applied` of the last seq each session wrote. planSave() decides one
-- UpdateAsync callback; the Ledger functions below are the per-session operation state the save worker drives. Over-credit
-- is impossible by construction: an operation is retried only inside RETRY_WINDOW_S, its receipt outlives that window
-- (TTL prune and cap eviction never reach a receipt younger than window + skew), and an operation that may have committed
-- is never credited again: a covering receipt acknowledges it, otherwise it is abandoned (under-credit, logged).

local MenuConfig = require(script.Parent.MenuConfig)
local ProfileConfig = require(script.Parent.ProfileConfig)

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
-- One save operation, frozen when taken. Every attempt of it reuses seq and delta, so the receipt log can tell.
export type SaveOp = {
	sessionId: string, -- one per server session of a player (HttpService GUID)
	seq: number, -- 1, 2, 3 ... per session; never reused for a different delta
	glyphsDelta: number, -- taken from pending, never from the displayed total
	createdAt: number, -- os.clock() when taken: monotonic, meaningful on this server only
}
-- What one UpdateAsync callback knows besides the stored value.
export type SaveContext = {
	nowWall: number, -- this server's os.time(): stamps a new receipt and measures stored receipts' age
	elapsed: number, -- os.clock() - op.createdAt, read inside the callback
	ambiguous: boolean, -- an earlier attempt errored after a callback had returned a write candidate
	patch: Patch?, -- idempotent fields (settings, bests, test clock), rebuilt per attempt; its glyphsDelta is ignored
	window: number?, -- Studio hook only: a shorter retry window (never longer than RETRY_WINDOW_S)
}
export type SaveTag = "applied" | "acknowledged" | "abandoned" | "capacity" | "newer_schema"
-- The callback's decision: `write` is the value to return (nil cancels the write).
export type SavePlan = { tag: SaveTag, write: Profile?, reason: string? }
-- Per-session save state, replaced (never mutated) by takeOp / credit / settle.
export type Ledger = {
	sessionId: string,
	nextSeq: number,
	pending: number, -- glyph value earned since the last op was taken; goes into the NEXT op only
	op: SaveOp?, -- the unresolved operation
	ambiguous: boolean, -- op may have committed (an attempt errored after returning a write candidate)
}
-- How an attempt ended. plan: the call returned, `tag` is the last callback's decision. error: the call errored,
-- `candidate` says whether any callback had returned a write. expired: not dispatched (elapsed >= window).
-- unconfirmed: the shutdown deadline passed with the op unresolved (`candidate`: a call was still in flight).
export type AttemptKind = "plan" | "error" | "expired" | "unconfirmed"
export type Attempt = { kind: AttemptKind, tag: SaveTag?, reason: string?, candidate: boolean? }
-- A terminal operation, logged once: reason, seq, delta and whether it may have committed.
export type Terminal = { reason: string, seq: number, glyphsDelta: number, ambiguous: boolean }
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
local RETRY_WINDOW = ProfileConfig.RETRY_WINDOW_S
local EVICT_AGE = ProfileConfig.RETRY_WINDOW_S + ProfileConfig.CLOCK_SKEW_ALLOWANCE_S -- strictly older may be evicted
local RECEIPT_TTL = ProfileConfig.RECEIPT_TTL_S
local RECEIPT_CAP = ProfileConfig.RECEIPT_CAP
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

local function cleanEntry(entry: any): AppliedEntry?
	if typeof(entry) == "table" and isInt(entry.seq, 1, MAX_GLYPHS) and isFinite(entry.at) then
		return { seq = entry.seq, at = entry.at }
	end
	return nil
end

-- A clean copy of a stored receipt log: entries with a non-empty session id of at most 64 characters, a positive integer
-- seq and a finite `at` survive; anything else is dropped. With `now`, entries older than RECEIPT_TTL_S are pruned
-- (exactly RECEIPT_TTL_S old is kept; a future `at` from a skewed clock is kept). Never capped here: only planSave makes
-- room, and only by evicting receipts older than window + skew.
function ProfileRules.sanitizeApplied(raw: any, now: number?): AppliedLog
	local out: AppliedLog = {}
	if typeof(raw) ~= "table" then
		return out
	end
	local oldest = if now ~= nil and isFinite(now) then now - RECEIPT_TTL else nil
	for id, entry in raw do
		local clean = cleanEntry(entry)
		if isSessionId(id) and clean ~= nil and (oldest == nil or clean.at >= oldest) then
			out[id] = clean
		end
	end
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

local function validOp(op: any): boolean
	return typeof(op) == "table"
		and isSessionId(op.sessionId)
		and isInt(op.seq, 1, MAX_GLYPHS)
		and isInt(op.glyphsDelta, 0, MAX_GLYPHS)
		and isFinite(op.createdAt)
end

-- The retry window in force: RETRY_WINDOW_S, or a shorter positive override (the Studio hook). Never longer.
function ProfileRules.retryWindow(override: number?): number
	if override ~= nil and isFinite(override) and override > 0 then
		return math.min(override, RETRY_WINDOW)
	end
	return RETRY_WINDOW
end

-- Is the op at or past its retry window at monotonic time `clock`? NaN / garbage counts as expired.
function ProfileRules.expired(op: SaveOp, clock: number, window: number?): boolean
	return not (clock - op.createdAt < ProfileRules.retryWindow(window))
end

local function patchWith(patch: Patch?, delta: number): Patch
	local out: Patch = if typeof(patch) == "table" then table.clone(patch) else {}
	out.glyphsDelta = delta
	return out
end

-- Fits `log` (which already holds `keep`) into RECEIPT_CAP by evicting only receipts strictly older than window + skew,
-- oldest first (ties by session id). Mutates `log`; returns false when it still does not fit.
local function makeRoom(log: AppliedLog, keep: string, now: number): boolean
	local count = 0
	local evictable = {}
	for id, entry in log do
		count += 1
		if id ~= keep and now - entry.at > EVICT_AGE then
			table.insert(evictable, id)
		end
	end
	if count <= RECEIPT_CAP then
		return true
	end
	table.sort(evictable, function(a: string, b: string): boolean
		local atA, atB = log[a].at, log[b].at
		if atA ~= atB then
			return atA < atB
		end
		return a < b
	end)
	for _, id in evictable do
		if count <= RECEIPT_CAP then
			break
		end
		log[id] = nil
		count -= 1
	end
	return count <= RECEIPT_CAP
end

-- Decides one UpdateAsync callback for `op`. Pure; never mutates `stored`. In order:
--  1. stored data from a newer build -> newer_schema, no write (also when it became newer after this session loaded).
--  2. an op or context without a valid identity -> abandoned ("invalid"), no write.
--  3. the stored receipt for this session covers op.seq (checked BEFORE any pruning) -> acknowledged: no delta. Inside the
--     window the idempotent fields are written over a pruned log; at or past it nothing is written.
--  4. op ambiguous (may have committed) and no covering receipt -> abandoned, no write. A missing receipt never
--     authorises a second credit.
--  5. elapsed >= window -> abandoned ("expired"), no write: a replayed callback past the deadline returns no candidate.
--  6. prune receipts older than TTL, record {seq, at = nowWall}, make room at the cap (evicting only receipts older than
--     window + skew); no room -> capacity, no write (retryable, nothing changed). Otherwise applied: delta added.
function ProfileRules.planSave(stored: any, op: SaveOp, ctx: SaveContext): SavePlan
	if ProfileRules.isNewerVersion(stored) then
		return { tag = "newer_schema" }
	end
	if not validOp(op) or typeof(ctx) ~= "table" or not isFinite(ctx.nowWall) then
		return { tag = "abandoned", reason = "invalid" }
	end
	local rawLog = if typeof(stored) == "table" then stored.applied else nil
	local receipt = if typeof(rawLog) == "table" then cleanEntry(rawLog[op.sessionId]) else nil
	local expired = not (ctx.elapsed < ProfileRules.retryWindow(ctx.window))
	if receipt ~= nil and receipt.seq >= op.seq then
		if expired then
			return { tag = "acknowledged", reason = "receipt" }
		end
		local log = ProfileRules.sanitizeApplied(rawLog, ctx.nowWall)
		log[op.sessionId] = receipt -- the covering receipt is never pruned by its own acknowledgement
		local out = ProfileRules.merge(stored, patchWith(ctx.patch, 0))
		out.applied = log
		return { tag = "acknowledged", write = out, reason = "receipt" }
	end
	if ctx.ambiguous == true then
		return {
			tag = "abandoned",
			reason = if receipt == nil then "ambiguous_no_receipt" else "ambiguous_receipt_behind",
		}
	end
	if expired then
		return { tag = "abandoned", reason = "expired" }
	end
	local log = ProfileRules.sanitizeApplied(rawLog, ctx.nowWall)
	log[op.sessionId] = { seq = op.seq, at = ctx.nowWall }
	if not makeRoom(log, op.sessionId, ctx.nowWall) then
		return { tag = "capacity" }
	end
	local out = ProfileRules.merge(stored, patchWith(ctx.patch, op.glyphsDelta))
	out.applied = log
	return { tag = "applied", write = out }
end

-- A fresh ledger for one server session of a player.
function ProfileRules.newLedger(sessionId: string): Ledger
	return { sessionId = sessionId, nextSeq = 1, pending = 0, op = nil, ambiguous = false }
end

-- `amount` added to pending (for the next op). Anything but a positive integer leaves the ledger as it is.
function ProfileRules.credit(ledger: Ledger, amount: any): Ledger
	if not isInt(amount, 1, MAX_GLYPHS) then
		return ledger
	end
	local out = table.clone(ledger)
	out.pending = math.min(ledger.pending + amount, MAX_GLYPHS)
	return out
end

-- The op to attempt: the unresolved one unchanged, or (when there is pending glyph value or `want`, i.e. dirty
-- idempotent fields) a new frozen op that takes ALL of pending, with the next seq. Returns the new ledger, the op (nil
-- when there is nothing to save) and whether the op is new.
function ProfileRules.takeOp(ledger: Ledger, want: boolean, clock: number): (Ledger, SaveOp?, boolean)
	if ledger.op ~= nil then
		return ledger, ledger.op, false
	end
	if ledger.pending <= 0 and not want then
		return ledger, nil, false
	end
	local op: SaveOp = table.freeze({
		sessionId = ledger.sessionId,
		seq = ledger.nextSeq,
		glyphsDelta = ledger.pending,
		createdAt = clock,
	})
	local out = table.clone(ledger)
	out.nextSeq = ledger.nextSeq + 1
	out.pending = 0
	out.op = op
	out.ambiguous = false
	return out, op, true
end

local function finish(ledger: Ledger, reason: string?, ambiguous: boolean): (Ledger, Terminal?)
	local op = ledger.op :: SaveOp
	local out = table.clone(ledger)
	out.op = nil
	out.ambiguous = false
	if reason == nil then
		return out, nil
	end
	return out, { reason = reason, seq = op.seq, glyphsDelta = op.glyphsDelta, ambiguous = ambiguous }
end

-- Folds an attempt's outcome into the ledger. Pending is never touched: an abandoned or possibly committed delta never
-- returns to it, and increments that arrived meanwhile stay for the next op. Returns the terminal record when the op
-- ended without a confirmed write (log it once).
function ProfileRules.settle(ledger: Ledger, attempt: Attempt): (Ledger, Terminal?)
	if ledger.op == nil then
		return ledger, nil
	end
	local kind = attempt.kind
	if kind == "plan" then
		local tag = attempt.tag
		if tag == "applied" or tag == "acknowledged" then
			return finish(ledger, nil, false)
		elseif tag == "capacity" then
			return ledger, nil -- unchanged op, retried until room opens or it expires
		elseif tag == "newer_schema" then
			return finish(ledger, "newer_schema", ledger.ambiguous)
		end
		return finish(ledger, attempt.reason or "abandoned", ledger.ambiguous)
	elseif kind == "error" then
		if attempt.candidate == true and not ledger.ambiguous then
			local out = table.clone(ledger)
			out.ambiguous = true
			return out, nil
		end
		return ledger, nil
	elseif kind == "expired" then
		return finish(ledger, "expired", ledger.ambiguous)
	end
	-- unconfirmed (shutdown deadline): the op stays as it is; an in-flight call keeps it potentially committed.
	local ambiguous = ledger.ambiguous or attempt.candidate == true
	return ledger,
		{
			reason = "unconfirmed_at_shutdown",
			seq = (ledger.op :: SaveOp).seq,
			glyphsDelta = (ledger.op :: SaveOp).glyphsDelta,
			ambiguous = ambiguous,
		}
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
