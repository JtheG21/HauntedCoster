--!strict
-- Tunables for the client Hud (HudRules, client/Hud). Frozen: never mutate at runtime. Strings: HudCopy.

local HudConfig = table.freeze({
	TimerWarnSeconds = 3, -- at or below this the bar, number and current pip turn alert red
	MaxSolverNames = 3, -- chips listed in the Reveal "solved by" row before "+N MORE"
	ConnectTimeoutSeconds = 10, -- how long the Hud waits for the server's Remotes folder
	ReferenceWidth = 844, -- the design canvas; View scales it to the viewport with HudRules.rootScale
	ReferenceHeight = 390,
	-- Problem text size by the character count of "a op b = ?" (HudRules.problemSize).
	ProblemSizeSmall = 88, -- up to ProblemShortChars characters
	ProblemSizeMedium = 76, -- up to ProblemMediumChars
	ProblemSizeLarge = 64,
	ProblemShortChars = 9,
	ProblemMediumChars = 11,
	ProblemGapRatio = 0.25, -- gap between the problem and "= ?" as a fraction of the text size
})

return HudConfig
