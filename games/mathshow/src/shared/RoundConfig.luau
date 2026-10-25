--!strict
-- Tunables for RoundRules. Frozen: never mutate at runtime. Question time limits live in ProblemConfig.Tiers.

local RoundConfig = table.freeze({
	IntermissionSeconds = 10,
	RevealSeconds = 4,
	ResultsSeconds = 8,
	QuestionCount = 6,
	-- Difficulty tier per question index (1-based); length must equal QuestionCount.
	DifficultyByQuestion = table.freeze({ 1, 1, 2, 2, 3, 3 }),
})

return RoundConfig
