--!strict
export type Input = {
	distance: number,
	frameErrorDegrees: number,
	state: string,
	wasAware: boolean,
	tuning: {
		CloseRange: number,
		GoodRange: number,
		LongRange: number,
		TightFrameDegrees: number,
		ClearFrameDegrees: number,
	},
}
export type Result = {
	points: number,
	maxPoints: number,
	tier: string,
	behavior: string,
	breakdown: { string },
}

local EvidenceRules = {}
local BEHAVIORS = {
	Roaming = "Quiet roam",
	Investigating = "Investigating",
	Pursuing = "Pursuit",
	Returning = "Returning",
}

local function finite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

function EvidenceRules.evaluate(input: Input): Result?
	if not finite(input.distance) or input.distance < 0 then
		return nil
	end
	if not finite(input.frameErrorDegrees) or input.frameErrorDegrees < 0 then
		return nil
	end
	if
		input.tuning.CloseRange <= 0
		or input.tuning.GoodRange <= input.tuning.CloseRange
		or input.tuning.LongRange <= input.tuning.GoodRange
		or input.tuning.TightFrameDegrees <= 0
		or input.tuning.ClearFrameDegrees <= input.tuning.TightFrameDegrees
	then
		return nil
	end

	local points = 0
	local breakdown = {}
	local function award(value: number, reason: string)
		points += value
		table.insert(breakdown, reason)
	end

	if input.frameErrorDegrees <= input.tuning.TightFrameDegrees then
		award(2, "Centered framing")
	elseif input.frameErrorDegrees <= input.tuning.ClearFrameDegrees then
		award(1, "Readable framing")
	else
		table.insert(breakdown, "Loose framing")
	end

	if input.distance <= input.tuning.CloseRange then
		award(2, "Close approach")
	elseif input.distance <= input.tuning.GoodRange then
		award(1, "Useful distance")
	elseif input.distance > input.tuning.LongRange then
		table.insert(breakdown, "Distant subject")
	else
		table.insert(breakdown, "Safe distance")
	end

	local behavior = BEHAVIORS[input.state] or "Unknown behavior"
	if input.state == "Pursuing" then
		award(2, "Pursuit captured")
	elseif input.state == "Investigating" then
		award(1, "Reaction captured")
	else
		table.insert(breakdown, behavior)
	end

	if input.state == "Pursuing" and input.distance <= input.tuning.GoodRange then
		award(2, "Danger held in frame")
	elseif not input.wasAware and input.distance <= input.tuning.GoodRange then
		award(1, "Quiet approach")
	else
		table.insert(breakdown, "Low pressure")
	end

	local tier = if points >= 7
		then "Remarkable"
		elseif points >= 5 then "Strong"
		elseif points >= 3 then "Clear"
		else "Sighting"
	return {
		points = points,
		maxPoints = 8,
		tier = tier,
		behavior = behavior,
		breakdown = breakdown,
	}
end

return table.freeze(EvidenceRules)
