--!strict
-- Remote names and payload types shared by the server (RoundService) and the client (Hud, TASK-0093).
-- The server creates the remotes in ReplicatedStorage.Remotes (server/Remotes.luau). Frozen.
--   RoundState   server -> all clients   RoundStatePayload
--   SubmitAnswer client -> server        (raw: string)
--   AnswerResult server -> one client    AnswerResultPayload
--   JoinShow     client -> server        (no payload; validated by JoinRules.validJoin)
--   ShowState    server -> one client    ShowStatePayload (is this player in the match, or watching)
--   SkillStart   client -> server        (no payload; SkillRules.validStart)
--   SkillAnswer  client -> server        { attempt, answer } (SkillRules.parseAnswerPayload)
--   SkillState   server -> one client    SkillStatePayload
--   SkillResult  server -> one client    SkillResultPayload
--   BlitzStart   client -> server        (no payload; BlitzRules.validStart)
--   BlitzAnswer  client -> server        { questionIndex, answer } (BlitzRules.parseAnswerPayload)
--   BlitzState   server -> one client    BlitzStatePayload (never any answer or score)
--   AnswerAck    server -> one client    { questionIndex } (identical for right and wrong)
--   BlitzResult  server -> one client    BlitzResultPayload (only after the run ends)
--   QueueJoin    client -> server        { mode: "vs" } (VsRules.validQueueJoin)
--   QueueCancel / QueueKeepWaiting / RematchRequest   client -> server (no payload)
--   QueueState   server -> one client    QueueStatePayload
--   VsAnswer     client -> server        { questionIndex, answer } (VsRules.parseAnswerPayload)
--   VsState      server -> one client    VsStatePayload (the opponent's answer is never sent)
--   VsResult     server -> one client    VsResultPayload
--   MenuRequest  client -> server (RemoteFunction)  { kind: "profile" } -> MenuProfileReply
--   SettingsSave client -> server        SettingsPayload (validated by ProfileRules.sanitizeSettings)

local ProfileRules = require(script.Parent.ProfileRules)
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

-- MenuRequest reply. ok = false means no usable profile: the menu shows RANK UNAVAILABLE and keeps local settings.
export type MenuProfileReply = {
	ok: boolean,
	reason: string?, -- "rate" | "unavailable" | "loading" | "bad request"
	profile: ProfileRules.ClientProfile?,
}

-- Per-player: joined = pressed JOIN SHOW; participant = counted in the current match (set when it starts, so a player
-- who joins mid-match is joined but not a participant until the next one).
export type ShowStatePayload = {
	joined: boolean,
	participant: boolean,
}

-- state: "question" (no answer in it), "reveal" (correct / correctValue / correctIndex, only here), "ended" (a SkillResult
-- follows), "cooldown" (retryAt), "unavailable" (profile not loaded, or the Skill Test is switched off).
export type SkillStatePayload = {
	state: string,
	attempt: number, -- the question number within this run, 1-based; echoed by SkillAnswer
	rank: number, -- the rank this question asks
	kind: string, -- "integer" | "choice"
	problem: string?,
	choices: { string }?,
	endsAt: number, -- workspace:GetServerTimeNow() based
	total: number, -- seconds this state lasts
	misses: number, -- consecutive misses so far
	retryAt: number?,
	correct: boolean?, -- reveal only
	correctValue: number?, -- reveal only, typed
	correctIndex: number?, -- reveal only, choice
}

export type SkillResultPayload = {
	kind: string, -- "first" | "up" | "held"
	cleared: number?,
	best: number,
	retryAt: number,
}

-- state "question" (the problem text only), "unavailable" (profile not loaded or Blitz switched off).
export type BlitzStatePayload = {
	state: string,
	questionIndex: number, -- 1..BlitzTotal
	problem: string?,
	endsAt: number, -- when the single run clock ends, workspace:GetServerTimeNow() based
	total: number, -- seconds the run clock lasts
}

-- answers / solutions hold 10 entries each; a question that was not answered has `false` in answers (nil cannot cross a remote).
export type BlitzResultPayload = {
	correct: number,
	answers: { number | boolean },
	solutions: { number },
	previousBest: number?,
	newBest: boolean,
}

export type PlayerCard = { userId: number, displayName: string, rank: number? }

-- state "searching" | "timeout" | "found" | "failed"; found carries the opponent and when the countdown ends.
export type QueueStatePayload = {
	state: string,
	startedAt: number, -- workspace:GetServerTimeNow() when this search (or wait) began
	opponent: PlayerCard?,
	startsAt: number?,
}

-- phase "Countdown" | "Question" | "Reveal" | "SuddenCountdown"; answer only in Reveal; you / them are the running totals.
export type VsStatePayload = {
	phase: string,
	questionIndex: number,
	total: number, -- questions in the match (sudden death counts past it)
	endsAt: number,
	problemText: string?,
	answer: number?,
	you: number,
	them: number,
	suddenDeath: boolean,
}

export type VsResultPayload = {
	result: string, -- "win" | "lose" | "draw" | "forfeit"
	you: number,
	them: number,
}

local Net = table.freeze({
	RoundState = "RoundState",
	SubmitAnswer = "SubmitAnswer",
	AnswerResult = "AnswerResult",
	QueueJoin = "QueueJoin",
	QueueCancel = "QueueCancel",
	QueueKeepWaiting = "QueueKeepWaiting",
	QueueState = "QueueState",
	VsAnswer = "VsAnswer",
	VsState = "VsState",
	VsResult = "VsResult",
	RematchRequest = "RematchRequest",
	BlitzStart = "BlitzStart",
	BlitzAnswer = "BlitzAnswer",
	BlitzState = "BlitzState",
	AnswerAck = "AnswerAck",
	BlitzResult = "BlitzResult",
	SkillStart = "SkillStart",
	SkillAnswer = "SkillAnswer",
	SkillState = "SkillState",
	SkillResult = "SkillResult",
	JoinShow = "JoinShow",
	ShowState = "ShowState",
	MenuRequest = "MenuRequest",
	SettingsSave = "SettingsSave",
})

return Net
