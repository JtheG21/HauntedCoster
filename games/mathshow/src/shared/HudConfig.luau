--!strict
-- Tunables and strings for the client Hud (HudRules, client/Hud). Frozen: never mutate at runtime.

local HudConfig = table.freeze({
	TimerWarnSeconds = 3, -- at or below this the bar changes colour and the number goes bold
	FeedbackFadeSeconds = 0.5,
	ConnectTimeoutSeconds = 10, -- how long the Hud waits for the server's Remotes folder
	Strings = table.freeze({
		Connecting = "Connecting...",
		WaitingForPlayers = "Waiting for players...",
		GetReady = "Get ready!",
		TimesUp = "Time's up",
		Correct = "Correct! +%d",
		CorrectPlain = "Correct!", -- used when the server sent no points
		Incorrect = "Not quite",
		NotCounted = "Not counted - wait for the next question",
		Sent = "Answer sent",
		Submit = "Submit",
		Placeholder = "Your answer",
		ResultsTitle = "Final standings",
		NoScores = "No scores this match",
		ScoresUnavailable = "Scores unavailable",
		PointsFormat = "%d pts",
		MoreFormat = "+%d more",
	}),
})

return HudConfig
