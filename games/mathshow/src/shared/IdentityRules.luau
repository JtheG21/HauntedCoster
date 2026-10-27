--!strict
-- Pure rules behind the identity components (TASK-0106): status priority, card variant, chip widths, progress fill
-- width and every formatted string. No Instances, no yields; the client builders in client/Identity call these. All
-- wording comes from IdentityCopy. Not wired into the HUD or menu yet.

local IdentityCopy = require(script.Parent.IdentityCopy)

export type StatusKey =
	"SUBMITTED"
	| "FIRST_CORRECT"
	| "BOT"
	| "YOU"
	| "PROVISIONAL"
	| "CHALLENGE_UNLOCKED"
	| "DISCONNECTED"
	| "WATCHING"
export type Variant = "Default" | "You" | "Bot" | "FirstCorrect" | "Disconnected" | "Spectating"
export type TrackSize = "compact" | "standard" | "long"

local IdentityRules = {}

IdentityRules.HeadshotTimeoutSeconds = 3 -- ENGINEERING_NEEDS 6: fall back after this, never block the card
IdentityRules.MinTagWidth = 48 -- README D
IdentityRules.TagPad = 20
IdentityRules.StatusPad = 42
IdentityRules.MinFill = 16 -- README F: the caps never overlap

-- When several statuses apply, one shows (ENGINEERING_NEEDS 3).
local PRIORITY: { StatusKey } = { "DISCONNECTED", "WATCHING", "FIRST_CORRECT", "SUBMITTED", "YOU", "BOT" }

function IdentityRules.pickStatus(flags: { [string]: boolean? }): StatusKey?
	for _, key in PRIORITY do
		if flags[key] == true then
			return key :: StatusKey
		end
	end
	return nil
end

-- Which card shard and treatment a player gets; same order as the status priority, then default.
function IdentityRules.variantOf(p: {
	connected: boolean?,
	spectating: boolean?,
	firstCorrect: boolean?,
	isYou: boolean?,
	isBot: boolean?,
}): Variant
	if p.connected == false then
		return "Disconnected"
	elseif p.spectating == true then
		return "Spectating"
	elseif p.firstCorrect == true then
		return "FirstCorrect"
	elseif p.isYou == true then
		return "You"
	elseif p.isBot == true then
		return "Bot"
	end
	return "Default"
end

-- Group tags are server-validated (2-5 chars); the client still refuses anything else rather than draw it.
function IdentityRules.tagText(tag: any): string?
	if type(tag) ~= "string" then
		return nil
	end
	local n = utf8.len(tag)
	if n == nil or n < 2 or n > 5 or tag:find("[%c%s]") ~= nil then
		return nil
	end
	return IdentityCopy.TagFormat:format(tag)
end

function IdentityRules.tagWidth(textWidth: number): number
	return math.max(IdentityRules.MinTagWidth, math.ceil(textWidth) + IdentityRules.TagPad)
end

function IdentityRules.statusWidth(textWidth: number): number
	return math.ceil(textWidth) + IdentityRules.StatusPad
end

-- Fill width in px: value% of the track, at least MinFill, never more than the track; hidden (0) at 0.
function IdentityRules.fillWidth(value: any, trackWidth: number): number
	if type(value) ~= "number" or value ~= value or value <= 0 then
		return 0
	end
	local pct = math.min(value, 100) / 100
	return math.min(trackWidth, math.max(IdentityRules.MinFill, math.floor(trackWidth * pct + 0.5)))
end

local function whole(n: any): number
	if type(n) ~= "number" or n ~= n or n == math.huge or n == -math.huge then
		return 0
	end
	return if n >= 0 then math.floor(n) else math.ceil(n)
end

-- "+12" / "−8" (U+2212) / "0".
function IdentityRules.deltaText(delta: any): string
	local n = whole(delta)
	if n > 0 then
		return `{IdentityCopy.Plus}{n}`
	elseif n < 0 then
		return `{IdentityCopy.Minus}{-n}`
	end
	return "0"
end

function IdentityRules.rankChangeKind(delta: any): "up" | "down" | "same"
	local n = whole(delta)
	return if n > 0 then "up" elseif n < 0 then "down" else "same"
end

-- Magnitude only; the arrow icon carries the direction.
function IdentityRules.rankChangeText(delta: any): string
	return tostring(math.abs(whole(delta)))
end

function IdentityRules.gainText(value: any, gain: any): string
	return IdentityCopy.Progress.GainFormat:format(math.clamp(whole(value), 0, 100), math.max(whole(gain), 0))
end

function IdentityRules.lossText(value: any, loss: any): string
	return IdentityCopy.Progress.LossFormat:format(math.clamp(whole(value), 0, 100), math.max(whole(loss), 0))
end

function IdentityRules.standingText(standing: any, strip: boolean?): string
	local n = math.max(whole(standing), 1)
	local format = if strip == true
		then IdentityCopy.Progress.StripStandingFormat
		else IdentityCopy.Progress.StandingFormat
	return format:format(n)
end

function IdentityRules.provisionalText(played: any, needed: any): string
	return IdentityCopy.Progress.ProvisionalHintFormat:format(math.max(whole(played), 0), math.max(whole(needed), 1))
end

-- TrackRules mode ids -> IdentityCopy mode keys.
function IdentityRules.modeKey(modeId: any): string?
	if modeId == "groupBattle" then
		return "group"
	elseif modeId == "team3v3" then
		return "team"
	elseif modeId == "blitz" then
		return "blitz"
	end
	return nil
end

-- nil for compact (icons only) or unknown input. Standard: "TIER · MODE"; long: "TIER · MODE · FORMAT".
function IdentityRules.trackText(tier: any, modeId: any, format: any, size: TrackSize): string?
	local tierName = if type(tier) == "string" then (IdentityCopy.Tier :: { [string]: string })[tier] else nil
	local modeName = (IdentityCopy.Mode :: { [string]: string })[IdentityRules.modeKey(modeId) or ""]
	if size == "compact" or tierName == nil or modeName == nil then
		return nil
	end
	local sep = IdentityCopy.TrackSep
	if size == "standard" then
		return tierName .. sep .. modeName
	end
	local formatName = if type(format) == "string" then (IdentityCopy.Format :: { [string]: string })[format] else nil
	if formatName == nil then
		return nil
	end
	return tierName .. sep .. modeName .. sep .. formatName
end

-- "7/10 correct" plus " · 3 first" when there were firsts.
function IdentityRules.statLine(correct: any, total: any, firsts: any): string
	local line = IdentityCopy.Stat.CorrectFormat:format(math.max(whole(correct), 0), math.max(whole(total), 0))
	local f = whole(firsts)
	if f > 0 then
		line ..= IdentityCopy.Stat.FirstsFormat:format(f)
	end
	return line
end

-- Headshot slot: "ready" once the thumbnail loaded, "fallback" on failure or after the timeout, else "pending".
function IdentityRules.headshotState(
	loaded: boolean,
	failed: boolean,
	elapsed: number
): "pending" | "ready" | "fallback"
	if loaded then
		return "ready"
	elseif failed or not (elapsed < IdentityRules.HeadshotTimeoutSeconds) then
		return "fallback"
	end
	return "pending"
end

return IdentityRules
