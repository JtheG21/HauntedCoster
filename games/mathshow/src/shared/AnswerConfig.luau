--!strict
-- Tunables for AnswerRules. Frozen: never mutate at runtime.

local AnswerConfig = table.freeze({
	MaxInputLength = 14, -- bytes of raw text parse will look at (blueprint section 10)
	MaxDigits = 7, -- most significant digits in an integer part, numerator or denominator (leading zeros not counted)
	MaxDecimals = 3, -- most digits after the decimal point
})

return AnswerConfig
