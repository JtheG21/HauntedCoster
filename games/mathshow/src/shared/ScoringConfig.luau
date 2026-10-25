--!strict
-- Tunables for ScoringRules. Frozen: never mutate at runtime.

local ScoringConfig = table.freeze({
	BasePoints = 100, -- awarded for any correct answer, including one after the time limit
	SpeedBonusMax = 100, -- full bonus at elapsed 0, falling linearly to 0 at timeLimit
	RawLengthCap = 16, -- longest raw string parseAnswer will look at
	DigitCap = 6, -- most digits parseAnswer accepts; must cover the largest ProblemRules answer (400)
})

return ScoringConfig
