--!strict
-- Tunables for GroupBattleRules (blueprint section 7, split plan decision 2). Frozen: never mutate at runtime.

local GroupBattleConfig = table.freeze({
	Seats = 6,
	Questions = 6,
	CorrectPoints = 100, -- a correct, valid answer
	FirstCorrectBonus = 50, -- added for the first correct answer of a question
	ClosingSeconds = 3, -- everyone else gets this long after the first correct answer
})

return GroupBattleConfig
