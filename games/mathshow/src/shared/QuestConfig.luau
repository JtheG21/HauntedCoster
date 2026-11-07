--!strict
-- Immutable daily quest catalog v1: id -> category, difficulty, kind, target. XP comes from XpConfig by difficulty.
-- A changed definition needs a new CatalogVersion; never edit v1 entries in place.

local XpConfig = require(script.Parent.XpConfig)

export type Category = "play" | "answers" | "glyphs"
export type Difficulty = "easy" | "medium" | "hard"
export type Kind = "round_finish" | "blitz_finish" | "skill_finish" | "correct" | "glyph" | "rare"
export type Quest = { id: string, category: Category, difficulty: Difficulty, kind: Kind, target: number, xp: number }

local function q(id: string, category: Category, difficulty: Difficulty, kind: Kind, target: number): Quest
	return table.freeze({
		id = id,
		category = category,
		difficulty = difficulty,
		kind = kind,
		target = target,
		xp = XpConfig.QuestXp[difficulty],
	})
end

local Catalog: { [string]: Quest } = table.freeze({
	P_E_ROUND2 = q("P_E_ROUND2", "play", "easy", "round_finish", 2),
	P_E_BLITZ1 = q("P_E_BLITZ1", "play", "easy", "blitz_finish", 1),
	P_M_ROUND4 = q("P_M_ROUND4", "play", "medium", "round_finish", 4),
	P_M_BLITZ3 = q("P_M_BLITZ3", "play", "medium", "blitz_finish", 3),
	P_M_SKILL1 = q("P_M_SKILL1", "play", "medium", "skill_finish", 1),
	P_H_ROUND6 = q("P_H_ROUND6", "play", "hard", "round_finish", 6),
	P_H_BLITZ5 = q("P_H_BLITZ5", "play", "hard", "blitz_finish", 5),
	A_E_15 = q("A_E_15", "answers", "easy", "correct", 15),
	A_M_40 = q("A_M_40", "answers", "medium", "correct", 40),
	A_H_80 = q("A_H_80", "answers", "hard", "correct", 80),
	G_E_10 = q("G_E_10", "glyphs", "easy", "glyph", 10),
	G_M_25 = q("G_M_25", "glyphs", "medium", "glyph", 25),
	G_M_RARE1 = q("G_M_RARE1", "glyphs", "medium", "rare", 1),
	G_H_50 = q("G_H_50", "glyphs", "hard", "glyph", 50),
	G_H_RARE2 = q("G_H_RARE2", "glyphs", "hard", "rare", 2),
})

local Categories: { Category } = { "play", "answers", "glyphs" }
local Difficulties: { Difficulty } = { "easy", "medium", "hard" }
table.freeze(Categories)
table.freeze(Difficulties)

-- Selection cells in a fixed order: Cells[category][difficulty] = ordered quest ids.
local function ids(...: string): { string }
	return table.freeze({ ... })
end

local Cells = table.freeze({
	play = table.freeze({
		easy = ids("P_E_ROUND2", "P_E_BLITZ1"),
		medium = ids("P_M_ROUND4", "P_M_BLITZ3", "P_M_SKILL1"),
		hard = ids("P_H_ROUND6", "P_H_BLITZ5"),
	}),
	answers = table.freeze({
		easy = ids("A_E_15"),
		medium = ids("A_M_40"),
		hard = ids("A_H_80"),
	}),
	glyphs = table.freeze({
		easy = ids("G_E_10"),
		medium = ids("G_M_25", "G_M_RARE1"),
		hard = ids("G_H_50", "G_H_RARE2"),
	}),
})

return table.freeze({
	CatalogVersion = 1,
	Categories = Categories, -- slot order
	Difficulties = Difficulties,
	Catalog = Catalog,
	Cells = Cells,
	SlotCount = 3,
})
