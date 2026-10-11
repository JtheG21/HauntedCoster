--!strict
-- Match flow tuning (TASK-0006). Positions are greybox placeholders until M3 course modules exist.

local MatchConfig = table.freeze({
	MinPlayers = 1, -- 1 so a solo match can run end to end (M2 testing); raise for public play
	CountdownSeconds = 10,
	CourseMaxSeconds = 120,
	FinaleSeconds = 10, -- placeholder until the ring-out finale (TASK-0007)
	ResultsSeconds = 8,
	TrialMaxSeconds = 30,
	TickSeconds = 0.2,

	-- The faction power a new player must use to finish the onboarding trial, plus its prompt.
	TrialPower = table.freeze({
		Shinobi = table.freeze({ ability = "EchoClone", prompt = "Press F to leave an Echo Clone" }),
		Ki = table.freeze({ ability = "KiBurst", prompt = "Hold R, then release, to fire a Ki Burst" }),
	}),

	-- Zones: used if Workspace.MatchZones.<Name> exists, otherwise a placeholder pad is created here.
	Zones = table.freeze({
		Lobby = Vector3.new(0, 1, 120),
		Trial = Vector3.new(-80, 1, 120),
		CourseStart = Vector3.new(0, 1, -40),
		CourseFinish = Vector3.new(0, 1, -160),
		Finale = Vector3.new(120, 1, -100),
	}),
})

return MatchConfig
