--!strict
-- Pure answer parsing and scoring (games/mathshow/DESIGN.md "Rules that matter"). No Instances, no
-- services. parseAnswer never evaluates text: it accepts ASCII digits only, so a client string can
-- become nothing but a whole number.

local ScoringConfig = require(script.Parent.ScoringConfig)

local ScoringRules = {}

-- Whole number from 1 to DigitCap ASCII digits with optional surrounding spaces, else nil. The raw
-- length cap runs first so the pattern only ever sees bounded input.
function ScoringRules.parseAnswer(raw: any): number?
	if typeof(raw) ~= "string" or #raw > ScoringConfig.RawLengthCap then
		return nil
	end
	local digits = raw:match("^ *(%d+) *$")
	if not digits or #digits > ScoringConfig.DigitCap then
		return nil
	end
	return tonumber(digits)
end

-- Wrong or missing answers score 0. A correct answer scores BasePoints plus a linear speed bonus that
-- is full at elapsed 0 and reaches 0 at timeLimit, so a late correct answer keeps BasePoints. Whole
-- numbers only, never NaN or negative. A timeLimit that is not a positive finite number gets no bonus.
function ScoringRules.score(correct: boolean?, elapsed: number, timeLimit: number): number
	if correct ~= true then
		return 0
	end
	local base = ScoringConfig.BasePoints
	if not (timeLimit > 0) or timeLimit == math.huge then
		return base
	end
	local remaining = math.min((timeLimit - elapsed) / timeLimit, 1)
	if not (remaining > 0) then
		return base
	end
	return base + math.floor(remaining * ScoringConfig.SpeedBonusMax)
end

return ScoringRules
