--!strict
-- Player-facing strings for the Hud (shards pass, TASK-0097). HudRules and StandingsRules read these; every
-- string is shown as written (all caps comes from the copy, not TextTransform).

local Copy = {
	Connecting = "CONNECTING",

	TopLobby = "MATHSHOW · LOBBY",
	TopQuestion = "QUESTION %d / %d", -- index, question count
	TopResults = "MATHSHOW · FINAL STANDINGS",

	WaitingTag = "LOBBY",
	WaitingTitle = "STANDING BY",
	WaitingSub = "The show starts when someone joins.",
	ReadyTag = "SHOW STARTS IN",
	ReadyTitle = "GET READY",
	ReadySub = "Six problems. Faster answers score up to 200 each.",

	QuestionTag = "Q%d · %s · %dS", -- index, tier name, seconds
	Tier = { "EASY", "MEDIUM", "HARD" }, -- by difficulty (RoundConfig.DifficultyByQuestion)
	AnswerTag = "THE ANSWER",
	SecondsLabel = "SEC",
	NextLabel = "NEXT UP",
	ResultsLabel = "RESULTS",
	Equals = "= %s",
	Unknown = "?",
	InputPlaceholder = "TYPE ANSWER",
	Submit = "LOCK IN",

	Sent = "LOCKED IN",
	Correct = "CORRECT",
	CorrectPoints = "+%d",
	Wrong = "NOT QUITE",
	TimesUp = "TIME'S UP",
	Rejected = "NOT COUNTED",
	SendFailed = "DIDN'T SEND · TRY AGAIN",

	SolvedBy = "SOLVED BY",
	Nobody = "NOBODY CRACKED IT",
	More = "+%d MORE",
	SolverPoints = "+%d",

	Score = "SCORE",
	NextMatch = "NEXT MATCH",
	Points = "%s PTS",
	TopScore = "TOP SCORE",
	TiedFirst = "TIED FOR FIRST",
	FinalStandings = "FINAL STANDINGS",
	NoScores = "NO SCORES THIS MATCH",
	Unavailable = "SCORES UNAVAILABLE",
	Gap = "···",
}

table.freeze(Copy.Tier)
return table.freeze(Copy)
