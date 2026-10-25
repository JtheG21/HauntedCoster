--!strict
-- Tunables for ProblemRules. Frozen: never mutate at runtime.

export type Tier = {
	addSubMin: number,
	addSubMax: number,
	factorMin: number,
	factorMax: number,
	timeLimit: number, -- seconds
}

local ProblemConfig = table.freeze({
	-- Difficulty 1-3, ramping by question index (games/mathshow/DESIGN.md "Core loop").
	Tiers = {
		[1] = table.freeze({ addSubMin = 1, addSubMax = 10, factorMin = 2, factorMax = 9, timeLimit = 15 }) :: Tier,
		[2] = table.freeze({ addSubMin = 5, addSubMax = 30, factorMin = 2, factorMax = 12, timeLimit = 12 }) :: Tier,
		[3] = table.freeze({ addSubMin = 10, addSubMax = 50, factorMin = 3, factorMax = 20, timeLimit = 9 }) :: Tier,
	},
})

return ProblemConfig
