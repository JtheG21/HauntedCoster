--!strict
-- Pure clock and cooldown formatting for the menu. No Instances. Nothing here throws on bad input.

local MenuConfig = require(script.Parent.MenuConfig)
local MenuCopy = require(script.Parent.MenuCopy)

local MAX_SECONDS = 99 * 60 + 59

local CooldownRules = {}

local function clean(seconds: number): number
	if typeof(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 then
		return 0
	end
	return math.min(math.floor(seconds), MAX_SECONDS)
end

-- "mm:ss", zero padded, capped at 99:59.
function CooldownRules.formatClock(seconds: number): string
	local s = clean(seconds)
	return string.format("%02d:%02d", s // 60, s % 60)
end

-- "m:ss" for elapsed and Blitz clocks, capped at 99:59.
function CooldownRules.formatShort(seconds: number): string
	local s = clean(seconds)
	return string.format("%d:%02d", s // 60, s % 60)
end

function CooldownRules.retakeRemaining(now: number, lastTakenAt: number?, cooldown: number?): number
	if lastTakenAt == nil then
		return 0
	end
	local window = cooldown or MenuConfig.RetakeCooldownSeconds
	return math.max(0, lastTakenAt + window - now)
end

function CooldownRules.retakeLabel(remaining: number): string
	if typeof(remaining) ~= "number" or remaining ~= remaining or remaining <= 0 then
		return MenuCopy.Skill.TakeTest
	end
	return "RETAKE IN " .. CooldownRules.formatClock(remaining)
end

return CooldownRules
