--!strict
-- Frozen XP tunables (TASK-0149, SYS-Quests-And-XP). Pure data: no Instances, no services.
return table.freeze({
	PlayCap = 400, -- daily play-XP cap; quest XP sits outside it
	PlayAward = table.freeze({
		RoundFinish = 20,
		RoundTop3Bonus = 10,
		BlitzFinish = 15,
		SkillFinish = 20,
		Glyph = 1,
		Practice = 0,
	}),
	QuestXp = table.freeze({ easy = 100, medium = 150, hard = 200 }),
	AllThreeBonus = 100,
	LevelCap = 50,
	LevelBaseCost = 100, -- cost(L -> L+1) = LevelBaseCost + LevelStepCost * (L - 1)
	LevelStepCost = 35,
	DailySkewSeconds = 300,
	SecondsPerDay = 86400,
})
