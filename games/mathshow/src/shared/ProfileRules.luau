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
-- Settings (TASK-0141 rev 2, AUD-20261106-TASK-0141-01 F1): an op carries only the settings keys this session changed
-- (settingsPatch), never a full snapshot; acknowledging writes nothing; and a patch is dropped when another session's
-- receipt is not older than the op (createdAtWall - skew), unless this session already saw that receipt when it loaded.

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
-- Settings keys a session changed since its last confirmed save, with their newest values (known keys only).
export type SettingsPatch = { [string]: any }
-- One save operation, frozen when taken. Every attempt of it reuses seq, delta and settings patch, so the receipt log can
-- tell. createdAtWall and settingsPatch live in memory only; nothing about them is persisted.
export type SaveOp = {
	sessionId: string, -- one per server session of a player (HttpService GUID)
	seq: number, -- 1, 2, 3 ... per session; never reused for a different delta
	glyphsDelta: number, -- taken from pending, never from the displayed total
	createdAt: number, -- os.clock() when taken: monotonic, meaningful on this server only
	createdAtWall: number, -- os.time() when taken (the earlier op's, when it carries settings an unconfirmed op returned)
	settingsPatch: SettingsPatch, -- frozen; empty when no setting changed
}
-- What one UpdateAsync callback knows besides the stored value.
export type SaveContext = {
	nowWall: number, -- this server's os.time(): stamps a new receipt and measures stored receipts' age
	elapsed: number, -- os.clock() - op.createdAt, read inside the callback
	ambiguous: boolean, -- an earlier attempt errored after a callback had returned a write candidate
	patch: Patch?, -- idempotent fields (bests, test clock), rebuilt per attempt; its settings and glyphsDelta are ignored
	window: number?, -- Studio hook only: a shorter retry window (never longer than RETRY_WINDOW_S)
	shutdownLeft: number?, -- during shutdown only: seconds left to the shared shutdown deadline, read inside the callback
	knownReceipts: { [string]: number }?, -- other sessions' receipt seqs this session saw when it loaded (R3 exemption)
}
export type SaveTag = "applied" | "acknowledged" | "abandoned" | "capacity" | "newer_schema" | "deadline"
-- The callback's decision: `write` is the value to return (nil cancels the write). superseded: the op's settings patch
-- was dropped because another session saved more recently (R3).
export type SavePlan = { tag: SaveTag, write: Profile?, reason: string?, superseded: boolean? }
-- Per-session save state, replaced (never mutated) by takeOp / credit / noteSettings / settle.
export type Ledger = {
	sessionId: string,
	nextSeq: number,
	pending: number, -- glyph value earned since the last op was taken; goes into the NEXT op only
	settingsPatch: SettingsPatch, -- settings changed since the last op was taken; goes into the NEXT op only
	settingsWall: number?, -- createdAtWall of an unconfirmed op whose settings were returned to settingsPatch
	op: SaveOp?, -- the unresolved operation
	ambiguous: boolean, -- op may have committed (an attempt errored after returning a write candidate)
	reportedSeq: number, -- the op already given its terminal report (unconfirmed at shutdown); never reported again
}
-- How one UpdateAsync attempt ended (R6, classifyAttempt).
export type Outcome =
	"applied"
	| "acknowledged"
	| "abandoned"
	| "capacity"
	| "newer_schema"
	| "ambiguous"
	| "retryable_no_candidate"
-- What settle() folds in: an Outcome; expired (not dispatched, elapsed >= window); unconfirmed (the shutdown deadline
-- passed with the op unresolved, `candidate`: a call was still in flight). The older shapes are still read: plan (`tag`
-- is the last callback's decision) and error (`candidate`: a callback had returned a write).
export type AttemptKind = Outcome | "plan" | "error" | "expired" | "unconfirmed"
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
local SKEW = ProfileConfig.CLOCK_SKEW_ALLOWANCE_S
local EVICT_AGE = ProfileConfig.RETRY_WINDOW_S + SKEW -- strictly older may be evicted
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

-- Is `value` valid for the known setting `key`?
local function validSetting(key: string, value: any): boolean
	if key == "music" or key == "sfx" then
		return isInt(value, 0, MenuConfig.SettingMax)
	end
	return table.find(SETTING_KEYS, key) ~= nil and typeof(value) == "boolean"
end

-- A copy of `profile` with the valid known keys of `patch` written into its settings record. The record is cloned, so
-- sub-keys this build does not know stay as they are; anything else in the patch is ignored.
local function withSettings(profile: Profile, patch: SettingsPatch?): Profile
	if typeof(patch) ~= "table" or next(patch) == nil then
		return profile
	end
	local out = table.clone(profile)
	local record: { [any]: any } = if typeof(out.settings) == "table" then table.clone(out.settings) :: any else {}
	for _, key in SETTING_KEYS do
		local value = patch[key]
		if value ~= nil and validSetting(key, value) then
			record[key] = value
		end
	end
	out.settings = record :: any
	return out
end

-- Everything in a profile but settings and the glyph total, as a patch: the idempotent fields every attempt re-sends.
local function idempotentPatch(profile: Profile): Patch
	return {
		bestRank = profile.bestRank,
		lastTestRank = profile.lastTestRank,
		lastTakenAt = profile.lastTakenAt,
		blitzBest = profile.blitzBest,
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

-- The session profile after a settled save: what UpdateAsync returned or the callback last saw (another server may have
-- raised a best, added glyphs or saved newer settings), our bests folded in, the settings keys still waiting to be saved
-- (`settingsPending`) on top of the stored settings, and the glyph increments that arrived while the save was in flight
-- (`pending`, not yet in the stored total) added. Sanitized: the in-memory copy never carries stored fields or settings
-- sub-keys this build does not know (they stay in the store; the next save overlays onto them again).
function ProfileRules.adopt(result: any, current: Profile, pending: number, settingsPending: SettingsPatch?): Profile
	local merged = withSettings(ProfileRules.merge(result, idempotentPatch(current)), settingsPending)
	local adopted = ProfileRules.sanitize(merged)
	adopted.glyphsLifetime = ProfileRules.addGlyphs(ProfileRules.merge(result, {}), pending).glyphsLifetime
	return adopted
end

-- The other sessions' receipt seqs in a stored value (the R3 exemption: receipts this session saw when it loaded).
function ProfileRules.receiptSeqs(stored: any): { [string]: number }
	local out = {}
	local raw = if typeof(stored) == "table" then stored.applied else nil
	for id, entry in ProfileRules.sanitizeApplied(raw, nil) do
		out[id] = entry.seq
	end
	return out
end

local function validOp(op: any): boolean
	return typeof(op) == "table"
		and isSessionId(op.sessionId)
		and isInt(op.seq, 1, MAX_GLYPHS)
		and isInt(op.glyphsDelta, 0, MAX_GLYPHS)
		and isFinite(op.createdAt)
		and isFinite(op.createdAtWall)
		and typeof(op.settingsPatch) == "table"
end

-- R3: has another session saved since `op` was created (its receipt at >= op.createdAtWall - skew)? A receipt this
-- session already saw at load, at the same or a higher seq, does not count: its settings were in what this session loaded,
-- so this session's changes are newer. Malformed entries are ignored.
local function superseded(rawLog: any, op: SaveOp, known: { [string]: number }?): boolean
	if typeof(rawLog) ~= "table" then
		return false
	end
	local since = op.createdAtWall - SKEW
	for id, entry in rawLog do
		if id ~= op.sessionId and isSessionId(id) then
			local clean = cleanEntry(entry)
			if clean ~= nil and clean.at >= since then
				local seen = if typeof(known) == "table" then known[id] else nil
				if not (typeof(seen) == "number" and seen >= clean.seq) then
					return true
				end
			end
		end
	end
	return false
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

-- The idempotent fields of `patch` with `delta` as the glyph delta. Settings never come from here (R2): only from the
-- op's own settings patch.
local function patchWith(patch: Patch?, delta: number): Patch
	local out: Patch = if typeof(patch) == "table" then table.clone(patch) else {}
	out.settings = nil
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
--  3. the stored receipt for this session covers op.seq (checked BEFORE any pruning) -> acknowledged, and nothing is
--     written (R1): the stored value, its settings, bests and receipt log stay exactly as they are.
--  4. op ambiguous (may have committed) and no covering receipt -> abandoned, no write. A missing receipt never
--     authorises a second credit.
--  5. elapsed >= window -> abandoned ("expired"), no write: a replayed callback past the deadline returns no candidate.
--  6. during shutdown, at or past the shared shutdown deadline -> deadline, no write (R5; the op stays unresolved).
--  7. prune receipts older than TTL, record {seq, at = nowWall}, make room at the cap (evicting only receipts older than
--     window + skew); no room -> capacity, no write (retryable, nothing changed). Otherwise applied: delta added, bests
--     max-merged, and the op's settings patch written unless another session saved since the op was created (R3:
--     superseded, the patch is dropped and the delta still applied).
function ProfileRules.planSave(stored: any, op: SaveOp, ctx: SaveContext): SavePlan
	if ProfileRules.isNewerVersion(stored) then
		return { tag = "newer_schema" }
	end
	if not validOp(op) or typeof(ctx) ~= "table" or not isFinite(ctx.nowWall) then
		return { tag = "abandoned", reason = "invalid" }
	end
	local rawLog = if typeof(stored) == "table" then stored.applied else nil
	local receipt = if typeof(rawLog) == "table" then cleanEntry(rawLog[op.sessionId]) else nil
	if receipt ~= nil and receipt.seq >= op.seq then
		return { tag = "acknowledged", reason = "receipt" }
	end
	if ctx.ambiguous == true then
		return {
			tag = "abandoned",
			reason = if receipt == nil then "ambiguous_no_receipt" else "ambiguous_receipt_behind",
		}
	end
	if not (ctx.elapsed < ProfileRules.retryWindow(ctx.window)) then
		return { tag = "abandoned", reason = "expired" }
	end
	if ctx.shutdownLeft ~= nil and not (ctx.shutdownLeft > 0) then
		return { tag = "deadline", reason = "shutdown_deadline" }
	end
	local log = ProfileRules.sanitizeApplied(rawLog, ctx.nowWall)
	log[op.sessionId] = { seq = op.seq, at = ctx.nowWall }
	if not makeRoom(log, op.sessionId, ctx.nowWall) then
		return { tag = "capacity" }
	end
	local out = ProfileRules.merge(stored, patchWith(ctx.patch, op.glyphsDelta))
	local hasSettings = next(op.settingsPatch) ~= nil
	local dropped = hasSettings and superseded(rawLog, op, ctx.knownReceipts)
	if hasSettings and not dropped then
		out = withSettings(out, op.settingsPatch)
	end
	out.applied = log
	return { tag = "applied", write = out, superseded = if dropped then true else nil }
end

-- R6: how one UpdateAsync attempt ended, from the decisions its callback(s) returned (in order), what UpdateAsync
-- returned (nil when it returned nothing or errored) and whether it errored. A write is confirmed only when the LAST
-- decision was a write and UpdateAsync returned a value. Any other end after some callback returned a write candidate is
-- ambiguous (it may have committed): never confirmed, never retried with a fresh credit. Without any candidate an error or
-- the shutdown deadline is retryable_no_candidate (the op is unchanged) and every other end is the last decision's tag.
function ProfileRules.classifyAttempt(decisions: { SavePlan }, returned: any, errored: boolean): (Outcome, string?)
	local candidate = false
	for _, decided in decisions do
		if decided.write ~= nil then
			candidate = true
		end
	end
	local last = decisions[#decisions]
	if errored then
		return if candidate then "ambiguous" else "retryable_no_candidate", "error"
	end
	if last ~= nil and last.write ~= nil and returned ~= nil then
		return "applied", last.reason
	end
	if candidate then
		return "ambiguous", "no_value_after_candidate"
	end
	if last == nil then
		return "retryable_no_candidate", "no_callback"
	end
	local tag = last.tag
	if tag == "deadline" or tag == "applied" then
		return "retryable_no_candidate", last.reason
	end
	return tag :: any, last.reason
end

-- A fresh ledger for one server session of a player.
function ProfileRules.newLedger(sessionId: string): Ledger
	return {
		sessionId = sessionId,
		nextSeq = 1,
		pending = 0,
		settingsPatch = {},
		settingsWall = nil,
		op = nil,
		ambiguous = false,
		reportedSeq = 0,
	}
end

-- The ledger with the settings keys that differ between `before` and `after` recorded (newest value wins) for the next
-- op. Only known keys with valid values; nothing changed -> the same ledger.
function ProfileRules.noteSettings(ledger: Ledger, before: Settings, after: Settings): Ledger
	local changed: SettingsPatch = table.clone(ledger.settingsPatch)
	local any = false
	local old: { [string]: any } = before :: any
	local new: { [string]: any } = after :: any
	for _, key in SETTING_KEYS do
		local value = new[key]
		if value ~= old[key] and validSetting(key, value) then
			changed[key] = value
			any = true
		end
	end
	if not any then
		return ledger
	end
	local out = table.clone(ledger)
	out.settingsPatch = changed
	return out
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

-- The op to attempt: the unresolved one unchanged, or (when there is pending glyph value, a pending settings change or
-- `want`, i.e. dirty idempotent fields) a new frozen op that takes ALL of pending and the settings patch, with the next
-- seq, createdAt = `clock` and createdAtWall = `wall` (os.time(); the earlier op's when the patch carries settings an
-- unconfirmed op returned, so R3 still dates them from when they were first sent). Returns the new ledger, the op (nil when
-- there is nothing to save) and whether the op is new.
function ProfileRules.takeOp(ledger: Ledger, want: boolean, clock: number, wall: number?): (Ledger, SaveOp?, boolean)
	if ledger.op ~= nil then
		return ledger, ledger.op, false
	end
	if ledger.pending <= 0 and not want and next(ledger.settingsPatch) == nil then
		return ledger, nil, false
	end
	local createdAtWall = if wall ~= nil and isFinite(wall) then wall else 0
	if ledger.settingsWall ~= nil then
		createdAtWall = math.min(createdAtWall, ledger.settingsWall)
	end
	local op: SaveOp = table.freeze({
		sessionId = ledger.sessionId,
		seq = ledger.nextSeq,
		glyphsDelta = ledger.pending,
		createdAt = clock,
		createdAtWall = createdAtWall,
		settingsPatch = table.freeze(table.clone(ledger.settingsPatch)),
	})
	local out = table.clone(ledger)
	out.nextSeq = ledger.nextSeq + 1
	out.pending = 0
	out.settingsPatch = {}
	out.settingsWall = nil
	out.op = op
	out.ambiguous = false
	return out, op, true
end

-- Ends the op. `reason` set: it ended without a confirmed write, and the terminal record is returned unless the op was
-- already reported (R4). `requeue`: its settings patch returns to the ledger (keys changed since stay newer) with its
-- createdAtWall, so it goes out with the next op and R3 still compares it against when it was first sent.
local function finish(ledger: Ledger, reason: string?, ambiguous: boolean, requeue: boolean): (Ledger, Terminal?)
	local op = ledger.op :: SaveOp
	local out = table.clone(ledger)
	out.op = nil
	out.ambiguous = false
	if requeue and next(op.settingsPatch) ~= nil then
		local merged = table.clone(op.settingsPatch)
		for key, value in ledger.settingsPatch do
			merged[key] = value
		end
		out.settingsPatch = merged
		out.settingsWall = math.min(ledger.settingsWall or math.huge, op.createdAtWall)
	end
	if reason == nil or ledger.reportedSeq == op.seq then
		return out, nil
	end
	return out, { reason = reason, seq = op.seq, glyphsDelta = op.glyphsDelta, ambiguous = ambiguous }
end

-- The R6 outcome an attempt stands for (the older plan / error shapes are mapped onto it).
local function outcomeOf(attempt: Attempt): string
	local kind = attempt.kind
	if kind == "plan" then
		local tag = attempt.tag or "abandoned"
		return if tag == "deadline" then "retryable_no_candidate" else tag
	elseif kind == "error" then
		return if attempt.candidate == true then "ambiguous" else "retryable_no_candidate"
	end
	return kind
end

-- Folds an attempt's outcome into the ledger. Pending glyphs are never touched: an abandoned or possibly committed delta
-- never returns to them, and increments that arrived meanwhile stay for the next op. Returns the terminal record when the
-- op ended without a confirmed write, at most once per op (R4): after "unconfirmed" at shutdown a later settlement of the
-- same op only updates the ledger.
function ProfileRules.settle(ledger: Ledger, attempt: Attempt): (Ledger, Terminal?)
	if ledger.op == nil then
		return ledger, nil
	end
	local op = ledger.op :: SaveOp
	local outcome = outcomeOf(attempt)
	if outcome == "applied" or outcome == "acknowledged" then
		return finish(ledger, nil, false, false)
	elseif outcome == "capacity" or outcome == "retryable_no_candidate" then
		return ledger, nil -- unchanged op, retried until it resolves or expires
	elseif outcome == "ambiguous" then
		if ledger.ambiguous then
			return ledger, nil
		end
		local out = table.clone(ledger)
		out.ambiguous = true
		return out, nil
	elseif outcome == "newer_schema" then
		return finish(ledger, "newer_schema", ledger.ambiguous, false)
	elseif outcome == "expired" then
		return finish(ledger, "expired", ledger.ambiguous, true)
	elseif outcome == "unconfirmed" then
		-- The shutdown deadline passed: the op stays as it is; an in-flight call keeps it potentially committed.
		if ledger.reportedSeq == op.seq then
			return ledger, nil
		end
		local out = table.clone(ledger)
		out.reportedSeq = op.seq
		return out,
			{
				reason = "unconfirmed_at_shutdown",
				seq = op.seq,
				glyphsDelta = op.glyphsDelta,
				ambiguous = ledger.ambiguous or attempt.candidate == true,
			}
	end
	return finish(ledger, attempt.reason or "abandoned", ledger.ambiguous, true)
end

-- Everything in a profile as a patch: merge() makes it safe against older in-memory data. The glyph total is not part of
-- it: the caller supplies glyphsDelta. Settings are copied key by key, so a stray sub-key can never make the strict
-- settings check reject the patch. Saves never send these settings: planSave writes only an op's settings patch (R2).
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
