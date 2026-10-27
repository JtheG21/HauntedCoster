--!strict
-- Pure availability rules for the menu. No Instances. Missing or false flags mean locked; there is no rank gating.

local MenuConfig = require(script.Parent.MenuConfig)

export type Mode = "blitz" | "vs" | "group"
export type Secondary = "howto" | "practice" | "leaderboard" | "daily" | "drills"
export type State = "open" | "locked"

local ModeRules = {}

function ModeRules.cardState(mode: string, flags: { [string]: boolean }?): State
	local table_ = flags or MenuConfig.ModeEnabled
	if table_[mode] == true then
		return "open"
	end
	return "locked"
end

function ModeRules.secondaryState(id: string, flags: { [string]: boolean }?): State
	local table_ = flags or MenuConfig.SecondaryEnabled
	if table_[id] == true then
		return "open"
	end
	return "locked"
end

return ModeRules
