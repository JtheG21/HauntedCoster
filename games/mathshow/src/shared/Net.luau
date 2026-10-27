--!strict
-- Remote names and payload types shared by the server (RoundService) and the client (Hud, TASK-0093).
-- The server creates the remotes in ReplicatedStorage.Remotes (server/Remotes.luau). Frozen.
--   RoundState   server -> all clients   RoundStatePayload
--   SubmitAnswer client -> server        (raw: string)
--   AnswerResult server -> one client    AnswerResultPayload
--   JoinShow     client -> server        (no payload; validated by JoinRules.validJoin)
--   ShowState    server -> one client    ShowStatePayload (is this player in the match, or watching)
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

local Net = table.freeze({
	RoundState = "RoundState",
	SubmitAnswer = "SubmitAnswer",
	AnswerResult = "AnswerResult",
	JoinShow = "JoinShow",
	ShowState = "ShowState",
	MenuRequest = "MenuRequest",
	SettingsSave = "SettingsSave",
})

return Net
