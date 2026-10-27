--!strict
-- Pure player-profile rules (TASK-0099): defaults, sanitising stored and client data, merging a save into what is
-- already stored, and the payload the menu receives. No Instances, no services. Nothing here throws on bad input.
-- Stored data is lenient (bad fields fall back); client settings are strict (anything off is rejected whole).

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
}
export type Patch = {
	settings: Settings?,
	bestRank: number?,
	lastTestRank: number?,
	lastTakenAt: number?,
	blitzBest: number?,
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

local VERSION = 1
local MAX_TIME = 2 ^ 40 -- far beyond any os.time(), keeps garbage out
local UNAVAILABLE = { "publish", "studioaccesstoapisnotallowed", "403", "not allowed", "api services" }
local SETTING_KEYS = { "music", "sfx", "reducedMotion", "colorBlind", "haptics" }

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
	return { version = VERSION, settings = ProfileRules.defaultSettings() }
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

-- Folds `patch` into whatever is stored (UpdateAsync transform). Bests and the test time only ever go up, so a server
-- with older data cannot lower them; settings are last writer wins; the last test rank follows the newest test.
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
	if clean.lastTakenAt ~= nil then
		local newer = base.lastTakenAt == nil or clean.lastTakenAt > base.lastTakenAt
		if newer or (clean.lastTakenAt == base.lastTakenAt and clean.lastTestRank ~= nil) then
			base.lastTakenAt = clean.lastTakenAt
			base.lastTestRank = clean.lastTestRank
		end
	end
	return base
end

-- Everything in a profile as a patch (autosave and release): merge() makes it safe against older in-memory data.
function ProfileRules.toPatch(profile: Profile): Patch
	return {
		settings = profile.settings,
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
		settings = table.clone(profile.settings),
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
