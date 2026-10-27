--!strict
-- Pure VS match display rules (TASK-0104, RULES_SPEC). No Instances, no clock. Nothing here throws on bad input.

export type Result = "win" | "lose" | "draw" | "forfeit"

local MatchRules = {}

local function points(value: any): number
	if typeof(value) ~= "number" or value ~= value or value < 0 then
		return 0
	end
	return math.floor(value)
end

-- A forfeit beats everything (the rival left); otherwise compare the points. Equal points are a draw (sudden death).
function MatchRules.vsResult(you: number, them: number, forfeit: boolean): Result
	if forfeit then
		return "forfeit"
	end
	local a, b = points(you), points(them)
	if a > b then
		return "win"
	elseif a < b then
		return "lose"
	end
	return "draw"
end

-- Your share of the head-to-head bar, 0..100 as an integer; 50 when nobody has scored.
function MatchRules.headToHeadPct(you: number, them: number): number
	local a, b = points(you), points(them)
	if a + b == 0 then
		return 50
	end
	return math.floor(a / (a + b) * 100 + 0.5)
end

function MatchRules.searchPhase(elapsed: number, timeout: number): "searching" | "timeout"
	if typeof(elapsed) == "number" and elapsed == elapsed and elapsed >= timeout then
		return "timeout"
	end
	return "searching"
end

return MatchRules
