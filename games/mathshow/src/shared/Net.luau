--!strict
-- Remote names and payload types shared by the server (RoundService) and the client (Hud, TASK-0093).
-- The server creates the remotes in ReplicatedStorage.Remotes (server/Remotes.luau). Frozen.
--   RoundState   server -> all clients   RoundStatePayload
--   SubmitAnswer client -> server        (raw: string)
--   AnswerResult server -> one client    AnswerResultPayload

local RoundRules = require(script.Parent.RoundRules)

-- An array of these, not a map keyed by userId, so it survives a remote unchanged.
export type ScoreEntry = {
	userId: number,
	name: string,
	points: number,
}

-- endsAt is workspace:GetServerTimeNow() based (0 while Intermission waits for players). answer is only
-- present in Reveal; scores only in Reveal and Results.
export type RoundStatePayload = {
	phase: RoundRules.Phase,
	endsAt: number,
	questionIndex: number,
	problemText: string?,
	answer: number?,
	scores: { ScoreEntry }?,
	solvers: { ScoreEntry }?, -- Reveal only: who got this question right and the points it earned them, best first
}

export type AnswerResultPayload = {
	accepted: boolean,
	correct: boolean?,
	points: number?,
}

local Net = table.freeze({
	RoundState = "RoundState",
	SubmitAnswer = "SubmitAnswer",
	AnswerResult = "AnswerResult",
})

return Net
