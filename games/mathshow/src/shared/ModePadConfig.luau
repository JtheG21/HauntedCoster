--!strict
-- Hub mode pads (TASK-0122). Valid modes come only from Modes: pad Mode attribute -> menu screen the client opens.
-- A "locked:" screen is not opened; the client shows the coming-soon toast instead.
return table.freeze({
	PollSeconds = 0.25,
	CooldownSeconds = 2,
	VerticalTolerance = 6, -- studs above the pad's top surface still counted as standing on it
	Modes = table.freeze({
		Blitz = "confirm_blitz",
		VS = "confirm_vs",
		Group = "confirm_group",
		Practice = "practice",
		Skill = "skillintro",
		Daily = "quests", -- TASK-0151: the Observatory Daily pad opens QUESTS
	}),
})
