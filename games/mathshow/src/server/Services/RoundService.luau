--!strict
-- RoundService: the server-authoritative match loop (games/mathshow/DESIGN.md "Core loop" and "Remotes").
-- One thread walks RoundRules.nextPhase, generates each problem from ProblemRules, broadcasts RoundState and
-- validates SubmitAnswer with SubmissionRules before scoring it with ScoringRules. The answer leaves the
-- server only in the Reveal payload. Submit times come from os.clock() on receipt, never from the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local JoinRules = require(ReplicatedStorage.Shared.JoinRules)
local MenuConfig = require(ReplicatedStorage.Shared.MenuConfig)
local Net = require(ReplicatedStorage.Shared.Net)
local ProblemRules = require(ReplicatedStorage.Shared.ProblemRules)
local RateRules = require(ReplicatedStorage.Shared.RateRules)
local RoundConfig = require(ReplicatedStorage.Shared.RoundConfig)
local RoundRules = require(ReplicatedStorage.Shared.RoundRules)
local ScoringRules = require(ReplicatedStorage.Shared.ScoringRules)
local SubmissionConfig = require(ReplicatedStorage.Shared.SubmissionConfig)
local SubmissionRules = require(ReplicatedStorage.Shared.SubmissionRules)
local Remotes = require(script.Parent.Parent.Remotes)
local LeaderstatsService = require(script.Parent.LeaderstatsService)

local ERROR_BACKOFF_SECONDS = 1
local PLAYER_POLL_SECONDS = 1

type PlayerState = {
	joined: boolean, -- pressed JOIN SHOW (JoinShow remote); stays true across matches until the player leaves
	joinStamps: { number }, -- os.clock() of recent JoinShow calls, for the rate limit
	participant: boolean, -- in the current match: joined when question 1 opened (JoinRules.participantAt)
	points: number,
	lastSubmitAt: number?, -- os.clock()
	lastRejectAt: number?, -- os.clock() of the last rejection that was replied to or logged
	answeredIndex: number, -- last question this player has an accepted submission for; 0 = none
	solvedIndex: number, -- last question this player got right; 0 = none
	solvedPoints: number, -- points that question earned
}

local RoundService = {}

local started = false

local phase: RoundRules.Phase = "Intermission"
local questionIndex = 0
local endsAt = 0 -- workspace:GetServerTimeNow() based; 0 while waiting for players
local matchSeed = 0
local problem: ProblemRules.Problem? = nil
local questionStartClock = 0
local questionEndsClock = 0

local states: { [Player]: PlayerState } = {}

local function newState(): PlayerState
	return {
		joined = false,
		joinStamps = {},
		participant = false,
		points = 0,
		lastSubmitAt = nil,
		lastRejectAt = nil,
		answeredIndex = 0,
		solvedIndex = 0,
		solvedPoints = 0,
	}
end

local function scores(): { Net.ScoreEntry }
	local list: { Net.ScoreEntry } = {}
	for player, state in states do
		if state.participant then
			table.insert(list, { userId = player.UserId, name = player.Name, points = state.points })
		end
	end
	table.sort(list, function(a, b)
		if a.points ~= b.points then
			return a.points > b.points
		end
		return a.userId < b.userId
	end)
	return list
end

-- Players who got the current question right, best first. Only ever sent in Reveal.
local function solvers(): { Net.ScoreEntry }
	local list: { Net.ScoreEntry } = {}
	for player, state in states do
		if state.participant and state.solvedIndex == questionIndex and questionIndex > 0 then
			table.insert(list, { userId = player.UserId, name = player.Name, points = state.solvedPoints })
		end
	end
	table.sort(list, function(a, b)
		if a.points ~= b.points then
			return a.points > b.points
		end
		return a.userId < b.userId
	end)
	return list
end

-- Secrecy: problemText from Question on, answer and solvers only in Reveal, scores only in Reveal and Results.
local function payload(): Net.RoundStatePayload
	local out: Net.RoundStatePayload = { phase = phase, endsAt = endsAt, questionIndex = questionIndex }
	local current = problem
	if phase == "Question" and current then
		out.problemText = current.text
	elseif phase == "Reveal" and current then
		out.problemText = current.text
		out.answer = current.answer
		out.scores = scores()
		out.solvers = solvers()
	elseif phase == "Results" then
		out.scores = scores()
	end
	return out
end

local function sendState(player: Player)
	local ok, err = pcall(function()
		Remotes.RoundState:FireClient(player, payload())
	end)
	if not ok then
		warn(`[MathShow] RoundState to {player.Name} failed: {err}`)
	end
end

local function broadcast()
	Remotes.RoundState:FireAllClients(payload())
end

-- Tells one player whether they are in this match or only watching (ShowState); the HUD hides the answer row and shows the
-- WATCHING banner from it. Nothing secret: it only says what that player already knows about themself.
local function sendShow(player: Player)
	local state = states[player]
	if not state then
		return
	end
	local ok, err = pcall(function()
		Remotes.ShowState:FireClient(player, { joined = state.joined, participant = state.participant })
	end)
	if not ok then
		warn(`[MathShow] ShowState to {player.Name} failed: {err}`)
	end
end

local function broadcastShow()
	for player in states do
		sendShow(player)
	end
end

local function waitUntil(deadline: number)
	while true do
		local remaining = deadline - os.clock()
		if remaining <= 0 then
			return
		end
		task.wait(remaining)
	end
end

local function resetMatch()
	phase = "Intermission"
	questionIndex = 0
	endsAt = 0
	problem = nil
	for _, state in states do
		state.participant = false -- `joined` is kept: a joined player is admitted when the next match opens question 1
		state.points = 0
		state.answeredIndex = 0
		state.solvedIndex = 0
		state.solvedPoints = 0
	end
	local ok, err = pcall(function()
		LeaderstatsService.reset()
	end)
	if not ok then
		warn(`[MathShow] leaderstats reset failed: {err}`)
	end
	broadcastShow()
end

-- Sets the phase state before anything yields, broadcasts, then waits out the phase. `base` is the previous
-- phase's end (or now), so each deadline is computed once and waits never accumulate drift. A Question stays open
-- LateGraceSeconds past its shown deadline (endsAt), so the next phase starts that much later.
local function runPhase(nextPhase: RoundRules.Phase, index: number, duration: number, base: number): number
	local deadline = base + duration
	phase = nextPhase
	questionIndex = index
	endsAt = Workspace:GetServerTimeNow() + (deadline - os.clock())
	if nextPhase == "Question" then
		for _, state in states do
			state.participant = JoinRules.participantAt(state.joined, index, state.participant)
		end
		problem = ProblemRules.generate(matchSeed + index, RoundRules.difficultyFor(index))
		questionStartClock = base
		questionEndsClock = deadline
	end
	if nextPhase == "Question" and index == 1 then
		broadcastShow() -- who is in this match is now decided
	end
	print(`[MathShow] phase={nextPhase} q={index} seed={matchSeed} endsAt={string.format("%.2f", endsAt)}`)
	if nextPhase == "Reveal" then
		-- Leaderstats change here, with the scores the Reveal payload carries, and not at submit (secrecy).
		local list = scores()
		local ok, err = pcall(function()
			LeaderstatsService.publish(list)
		end)
		if ok then
			print(`[MathShow] leaderstats published n={#list}`)
		else
			warn(`[MathShow] leaderstats publish failed: {err}`)
		end
	end
	broadcast()
	local closeAt = if nextPhase == "Question" then deadline + SubmissionConfig.LateGraceSeconds else deadline
	waitUntil(closeAt)
	return closeAt
end

-- One match: Intermission (after waiting for a player), six Question/Reveal pairs, Results. Returns early to
-- Intermission when every player has left, after the current phase finishes.
local function runMatch()
	resetMatch()
	if #Players:GetPlayers() == 0 then
		print("[MathShow] phase=Intermission waiting for players")
		broadcast()
		while #Players:GetPlayers() == 0 do
			task.wait(PLAYER_POLL_SECONDS)
		end
	end
	matchSeed = Random.new():NextInteger(1, 2 ^ 30)
	print(`[MathShow] match seed={matchSeed}`)
	local deadline = runPhase("Intermission", 0, RoundConfig.IntermissionSeconds, os.clock())
	local current: RoundRules.Phase, index = "Intermission", 0
	while true do
		local nextPhase: RoundRules.Phase, duration: number = RoundRules.nextPhase(current, index)
		if nextPhase == "Intermission" then
			return
		end
		if #Players:GetPlayers() == 0 then
			print(`[MathShow] all players left at phase={current} q={index}; back to Intermission`)
			return
		end
		if nextPhase == "Question" then
			index += 1
		end
		deadline = runPhase(nextPhase, index, duration, deadline)
		current = nextPhase
	end
end

local function loop()
	while true do
		local ok, err = pcall(function()
			runMatch()
		end)
		if not ok then
			warn(`[MathShow] match loop error: {err}; back to Intermission in {ERROR_BACKOFF_SECONDS}s`)
			resetMatch()
			task.wait(ERROR_BACKOFF_SECONDS)
		end
	end
end

-- No yields from evaluate to the score update, so two quick submissions can never both be accepted.
local function onSubmit(player: Player, raw: any)
	local state = states[player]
	if not state then
		return
	end
	local now = os.clock()
	local verdict: SubmissionRules.Verdict, parsed: number? = SubmissionRules.evaluate(raw, {
		phase = phase,
		now = now,
		questionEndsAt = questionEndsClock,
		questionIndex = questionIndex,
		isParticipant = state.participant,
		lastSubmitAt = state.lastSubmitAt,
		answeredIndex = state.answeredIndex,
	})
	if SubmissionRules.advancesRateLimit(verdict) then
		state.lastSubmitAt = now
	end
	-- Rejections are replied to and logged at most once per RejectReplyIntervalSeconds, so spam cannot flood either.
	if SubmissionRules.rejectThrottled(verdict, now, state.lastRejectAt) then
		return
	end
	if verdict ~= "ok" then
		state.lastRejectAt = now
	end

	local reply: Net.AnswerResultPayload = { accepted = false }
	local current = problem
	if verdict == "ok" and current then
		-- The first valid submission locks the question, right or wrong.
		local correct = parsed == current.answer
		local points = ScoringRules.score(correct, now - questionStartClock, current.timeLimit)
		state.answeredIndex = questionIndex
		state.points += points
		if correct then
			state.solvedIndex = questionIndex
			state.solvedPoints = points
		end
		reply = { accepted = true, correct = correct, points = points }
		print(`[MathShow] submit user={player.UserId} q={questionIndex} verdict=ok correct={correct} points={points}`)
	elseif verdict == "ok" then
		warn(`[MathShow] submit user={player.UserId} q={questionIndex} verdict=ok but no problem; rejected`)
	else
		print(`[MathShow] submit user={player.UserId} q={questionIndex} verdict={verdict}`)
	end
	if SubmissionRules.sendsReply(verdict) then
		Remotes.AnswerResult:FireClient(player, reply)
	end
end

local function onPlayerAdded(player: Player)
	if states[player] then
		return
	end
	states[player] = newState()
	sendState(player)
	sendShow(player)
end

-- JOIN SHOW: no data, rate limited. Joining mid-match makes the player a watcher until the next match (JoinRules).
local function onJoin(player: Player, raw: any)
	local state = states[player]
	if not state or not JoinRules.validJoin(raw) then
		return
	end
	local allowed
	state.joinStamps, allowed = RateRules.allow(state.joinStamps, os.clock(), MenuConfig.JoinsPer10s, 10)
	if not allowed then
		return
	end
	state.joined = true
	sendShow(player)
	sendState(player)
end

function RoundService.start(): ()
	if started then
		return
	end
	started = true

	Remotes.SubmitAnswer.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onSubmit(player, raw)
		end)
		if not ok then
			warn(`[MathShow] SubmitAnswer from {player.Name} failed: {err}`)
		end
	end)
	Remotes.JoinShow.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onJoin(player, raw)
		end)
		if not ok then
			warn(`[MathShow] JoinShow from {player.Name} failed: {err}`)
		end
	end)
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(loop)
end

return RoundService
