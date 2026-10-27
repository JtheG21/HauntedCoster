--!strict
-- VsService (TASK-0104): 1v1 VS. An in-server queue pairs two searching players into a match that runs on its own thread,
-- independent of the Group Battle loop (RoundService). Six questions, scored like Group Battle (ScoringRules), points shown
-- only at Reveal, sudden death on a tie (first correct answer wins), forfeit when the rival leaves, rematch if both ask in
-- time. Server-authoritative: the problem, the answer and the clock live here; a client only sends QueueJoin / QueueCancel /
-- QueueKeepWaiting / VsAnswer / RematchRequest, each validated. The opponent's answer is never sent to anyone.
-- Studio-only: set workspace attribute MathShowVsBot = true and a lone searcher is matched with a practice bot after 2 s.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MatchRules = require(Shared:WaitForChild("MatchRules"))
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local ModeRules = require(Shared:WaitForChild("ModeRules"))
local Net = require(Shared:WaitForChild("Net"))
local ProblemRules = require(Shared:WaitForChild("ProblemRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))
local RoundRules = require(Shared:WaitForChild("RoundRules"))
local ScoringRules = require(Shared:WaitForChild("ScoringRules"))
local VsRules = require(Shared:WaitForChild("VsRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local ProfileService = require(script.Parent.ProfileService)

type Seat = {
	player: Player?, -- nil for the Studio practice bot
	userId: number,
	name: string,
	bot: boolean,
	score: number,
	answeredAt: number?, -- seconds into the question; nil = no answer yet
	correct: boolean,
	points: number, -- earned by the current question, added to `score` at Reveal
	rematch: boolean,
	stamps: { number },
}

type Match = {
	id: number,
	seats: { Seat },
	seed: number,
	index: number, -- question number; sudden-death questions continue past VsQuestions
	phase: string,
	problem: ProblemRules.Problem?,
	limit: number,
	startClock: number,
	endsClock: number,
	suddenDeath: boolean,
	over: boolean, -- the match ended (result sent, or forfeit): no more questions
	rematchOpen: boolean,
	forfeited: boolean,
}

type Queued = { startedAt: number, waits: number, token: number }

local VsService = {}

local started = false
local queue: { [Player]: Queued } = {}
local queueStamps: { [Player]: { number } } = {}
local playerMatch: { [Player]: Match } = {}
local nextMatchId = 0

local function botEnabled(): boolean
	return RunService:IsStudio() and Workspace:GetAttribute("MathShowVsBot") == true
end

local function otherSeat(match: Match, seat: Seat): Seat
	return if match.seats[1] == seat then match.seats[2] else match.seats[1]
end

local function seatOf(match: Match, player: Player): Seat?
	for _, seat in match.seats do
		if seat.player == player then
			return seat
		end
	end
	return nil
end

local function card(player: Player): Net.PlayerCard
	local profile = ProfileService.get(player)
	return { userId = player.UserId, displayName = player.DisplayName, rank = if profile then profile.bestRank else nil }
end

local function cardOf(seat: Seat): Net.PlayerCard
	if seat.player then
		return card(seat.player)
	end
	return { userId = seat.userId, displayName = seat.name, rank = 3 }
end

local function sendQueue(player: Player, payload: Net.QueueStatePayload)
	pcall(function()
		Remotes.QueueState:FireClient(player, payload)
	end)
end

local function sendVs(match: Match, seat: Seat, phase: string, endsAt: number, reveal: boolean)
	local player = seat.player
	if not player then
		return
	end
	local problem = match.problem
	local payload: Net.VsStatePayload = {
		phase = phase,
		questionIndex = match.index,
		total = MenuConfig.VsQuestions,
		endsAt = endsAt,
		problemText = if problem and (phase == "Question" or phase == "Reveal") then problem.text else nil,
		answer = if reveal and problem then problem.answer else nil,
		you = seat.score,
		them = otherSeat(match, seat).score,
		suddenDeath = match.suddenDeath,
	}
	pcall(function()
		Remotes.VsState:FireClient(player, payload)
	end)
end

local function broadcastVs(match: Match, phase: string, seconds: number, reveal: boolean)
	local endsAt = Workspace:GetServerTimeNow() + seconds
	for _, seat in match.seats do
		sendVs(match, seat, phase, endsAt, reveal)
	end
end

local function sendResult(match: Match, result: string, winner: Seat?)
	for _, seat in match.seats do
		local player = seat.player
		if player then
			local kind = result
			if result == "win" or result == "lose" then
				kind = if winner == seat then "win" else "lose"
			end
			pcall(function()
				Remotes.VsResult:FireClient(
					player,
					{ result = kind, you = seat.score, them = otherSeat(match, seat).score }
				)
			end)
		end
	end
end

local function release(match: Match)
	for _, seat in match.seats do
		if seat.player and playerMatch[seat.player] == match then
			playerMatch[seat.player] = nil
		end
	end
end

-- Waits `seconds`, or until the match is over; polls so a forfeit ends the wait at once.
local function waitFor(match: Match, seconds: number)
	local deadline = os.clock() + seconds
	while os.clock() < deadline and not match.over do
		task.wait(math.min(0.1, math.max(deadline - os.clock(), 0.01)))
	end
end

local function allAnswered(match: Match): boolean
	for _, seat in match.seats do
		if seat.answeredAt == nil then
			return false
		end
	end
	return true
end

local function scheduleBot(match: Match, seat: Seat, index: number)
	if not seat.bot then
		return
	end
	local delay = Random.new():NextNumber(2, math.max(3, match.limit - 2))
	task.delay(delay, function()
		if match.over or match.index ~= index or match.phase ~= "Question" or seat.answeredAt ~= nil then
			return
		end
		local problem = match.problem
		if not problem then
			return
		end
		local correct = Random.new():NextNumber() < 0.7
		local elapsed = os.clock() - match.startClock
		seat.answeredAt = elapsed
		seat.correct = correct
		seat.points = ScoringRules.score(correct, elapsed, match.limit)
	end)
end

local function askQuestion(match: Match, index: number, sudden: boolean)
	match.index = index
	match.suddenDeath = sudden
	local difficulty = if sudden then 3 else RoundRules.difficultyFor(index)
	local problem = ProblemRules.generate(match.seed + index + (if sudden then 1000 else 0), difficulty)
	match.problem = problem
	match.limit = if sudden then MenuConfig.VsSuddenDeathSeconds else problem.timeLimit
	for _, seat in match.seats do
		seat.answeredAt, seat.correct, seat.points = nil, false, 0
	end
	match.phase = "Question"
	match.startClock = os.clock()
	match.endsClock = match.startClock + match.limit
	broadcastVs(match, "Question", match.limit, false)
	for _, seat in match.seats do
		scheduleBot(match, seat, index)
	end
	-- Closes when both answered or the clock (plus the answer grace) runs out.
	while not match.over and not allAnswered(match) and os.clock() < match.endsClock + MenuConfig.SkillGraceSeconds do
		task.wait(0.1)
	end
end

local function reveal(match: Match)
	-- The totals only change here, at Reveal.
	for _, seat in match.seats do
		seat.score += seat.points
	end
	match.phase = "Reveal"
	broadcastVs(match, "Reveal", MenuConfig.VsRevealSeconds, true)
	waitFor(match, MenuConfig.VsRevealSeconds)
end

local runMatch: (Match) -> ()

local function startMatch(a: Seat, b: Seat)
	nextMatchId += 1
	local match: Match = {
		id = nextMatchId,
		seats = { a, b },
		seed = Random.new():NextInteger(1, 2 ^ 28),
		index = 0,
		phase = "Countdown",
		problem = nil,
		limit = 0,
		startClock = 0,
		endsClock = 0,
		suddenDeath = false,
		over = false,
		rematchOpen = false,
		forfeited = false,
	}
	for _, seat in match.seats do
		seat.score, seat.points, seat.answeredAt, seat.correct, seat.rematch = 0, 0, nil, false, false
		if seat.player then
			playerMatch[seat.player] = match
		end
	end
	local startsAt = Workspace:GetServerTimeNow() + MenuConfig.VsCountdownSeconds
	for _, seat in match.seats do
		if seat.player then
			sendQueue(seat.player, {
				state = "found",
				startedAt = Workspace:GetServerTimeNow(),
				opponent = cardOf(otherSeat(match, seat)),
				startsAt = startsAt,
			})
		end
	end
	task.spawn(function()
		local ok, err = pcall(function()
			runMatch(match)
		end)
		if not ok then
			warn(`[MathShow] VS match {match.id} failed: {err}`)
			match.over = true
			release(match)
		end
	end)
end

runMatch = function(match: Match)
	waitFor(match, MenuConfig.VsCountdownSeconds)
	for index = 1, MenuConfig.VsQuestions do
		if match.over then
			return
		end
		askQuestion(match, index, false)
		if match.over then
			return
		end
		reveal(match)
	end
	if match.over then
		return
	end
	local a, b = match.seats[1], match.seats[2]
	local result = MatchRules.vsResult(a.score, b.score, false)
	local winner: Seat? = nil
	if result == "draw" then
		sendResult(match, "draw", nil)
		match.phase = "SuddenCountdown"
		broadcastVs(match, "SuddenCountdown", MenuConfig.VsCountdownSeconds, false)
		waitFor(match, MenuConfig.VsCountdownSeconds)
		for round = 1, MenuConfig.VsSuddenDeathMax do
			if match.over then
				return
			end
			askQuestion(match, MenuConfig.VsQuestions + round, true)
			if match.over then
				return
			end
			local first =
				VsRules.suddenWinner(if a.correct then a.answeredAt else nil, if b.correct then b.answeredAt else nil)
			if first ~= nil then
				winner = if first == "a" then a else b
				break
			end
			match.phase = "Reveal"
			broadcastVs(match, "Reveal", 2, true)
			waitFor(match, 2)
		end
		if winner then
			match.phase = "Reveal"
			broadcastVs(match, "Reveal", MenuConfig.VsRevealSeconds, true)
			waitFor(match, MenuConfig.VsRevealSeconds)
			result = "win"
		end
	else
		winner = if result == "win" then a else b
	end
	if match.over then
		return
	end
	match.over = true
	sendResult(match, if winner then "win" else "draw", winner)
	print(`[MathShow] vs match={match.id} result={if winner then "decided" else "draw"} scores={a.score}-{b.score}`)
	-- Rematch window: both ask in time (a bot always agrees after 2 s) and a fresh match starts with the same pair.
	match.rematchOpen = true
	for _, seat in match.seats do
		if seat.bot then
			task.delay(2, function()
				seat.rematch = true
			end)
		end
	end
	local deadline = os.clock() + MenuConfig.VsRematchWindowSeconds
	while os.clock() < deadline and match.rematchOpen and not (a.rematch and b.rematch) do
		task.wait(0.2)
	end
	local again = match.rematchOpen and a.rematch and b.rematch
	match.rematchOpen = false
	release(match)
	if again then
		startMatch(a, b)
	end
end

local function tryPair()
	local waiting: { Player } = {}
	for player in queue do
		table.insert(waiting, player)
	end
	table.sort(waiting, function(x, y)
		return queue[x].startedAt < queue[y].startedAt
	end)
	while #waiting >= 2 do
		local x, y = table.remove(waiting, 1) :: Player, table.remove(waiting, 1) :: Player
		queue[x], queue[y] = nil, nil
		local function seat(player: Player): Seat
			return {
				player = player,
				userId = player.UserId,
				name = player.DisplayName,
				bot = false,
				score = 0,
				answeredAt = nil,
				correct = false,
				points = 0,
				rematch = false,
				stamps = {},
			}
		end
		startMatch(seat(x), seat(y))
	end
end

local function scheduleTimeout(player: Player, entry: Queued)
	entry.token += 1
	local token = entry.token
	task.delay(MenuConfig.VsSearchTimeoutSeconds, function()
		if queue[player] ~= entry or entry.token ~= token then
			return
		end
		entry.waits += 1
		local state = VsRules.afterTimeout(entry.waits)
		if state == "failed" then
			queue[player] = nil
		end
		sendQueue(player, { state = state, startedAt = Workspace:GetServerTimeNow() })
	end)
end

local function maybeBot(player: Player, entry: Queued)
	if not botEnabled() then
		return
	end
	task.delay(2, function()
		if queue[player] ~= entry or not botEnabled() then
			return
		end
		queue[player] = nil
		local human: Seat = {
			player = player,
			userId = player.UserId,
			name = player.DisplayName,
			bot = false,
			score = 0,
			answeredAt = nil,
			correct = false,
			points = 0,
			rematch = false,
			stamps = {},
		}
		local bot: Seat = {
			player = nil,
			userId = 1,
			name = "Practice Bot",
			bot = true,
			score = 0,
			answeredAt = nil,
			correct = false,
			points = 0,
			rematch = false,
			stamps = {},
		}
		startMatch(human, bot)
	end)
end

local function allowAction(player: Player): boolean
	local allowed
	queueStamps[player], allowed =
		RateRules.allow(queueStamps[player] or {}, os.clock(), MenuConfig.VsQueueActionsPer10s, 10)
	return allowed
end

local function onJoin(player: Player, raw: any)
	if not VsRules.validQueueJoin(raw) or not allowAction(player) then
		return
	end
	if queue[player] or playerMatch[player] then
		return
	end
	if ModeRules.cardState("vs") ~= "open" or ProfileService.get(player) == nil then
		sendQueue(player, { state = "failed", startedAt = Workspace:GetServerTimeNow() })
		return
	end
	local entry: Queued = { startedAt = os.clock(), waits = 0, token = 0 }
	queue[player] = entry
	sendQueue(player, { state = "searching", startedAt = Workspace:GetServerTimeNow() })
	scheduleTimeout(player, entry)
	tryPair()
	maybeBot(player, entry)
end

local function onCancel(player: Player, raw: any)
	if VsRules.validEmpty(raw) and allowAction(player) then
		queue[player] = nil -- idempotent; a player already in a match is not pulled out
	end
end

local function onKeepWaiting(player: Player, raw: any)
	local entry = queue[player]
	if not entry or not VsRules.validEmpty(raw) or not allowAction(player) then
		return
	end
	entry.startedAt = os.clock()
	scheduleTimeout(player, entry)
	sendQueue(player, { state = "searching", startedAt = Workspace:GetServerTimeNow() })
	maybeBot(player, entry)
end

local function onAnswer(player: Player, raw: any)
	local match = playerMatch[player]
	local seat = if match then seatOf(match, player) else nil
	if not match or not seat then
		return
	end
	local allowed
	seat.stamps, allowed = RateRules.allow(seat.stamps, os.clock(), MenuConfig.VsAnswersPer5s, 5)
	local index, answer = VsRules.parseAnswerPayload(raw)
	local problem = match.problem
	if
		not allowed
		or index == nil
		or answer == nil
		or not problem
		or match.phase ~= "Question"
		or match.over
		or index ~= match.index
		or seat.answeredAt ~= nil
	then
		return
	end
	local now = os.clock()
	if now > match.endsClock + MenuConfig.SkillGraceSeconds then
		return
	end
	-- No yield between the check above and these writes: two quick answers can never both count.
	local elapsed = now - match.startClock
	local correct = answer == problem.answer
	seat.answeredAt = elapsed
	seat.correct = correct
	seat.points = ScoringRules.score(correct, elapsed, match.limit)
	pcall(function()
		Remotes.AnswerResult:FireClient(player, { accepted = true, correct = correct, points = seat.points })
	end)
end

local function onRematch(player: Player, raw: any)
	local match = playerMatch[player]
	local seat = if match then seatOf(match, player) else nil
	if match and seat and VsRules.validEmpty(raw) and match.rematchOpen and not match.forfeited then
		seat.rematch = true
	end
end

local function onLeaving(player: Player)
	queue[player] = nil
	queueStamps[player] = nil
	local match = playerMatch[player]
	if not match then
		return
	end
	playerMatch[player] = nil
	if match.over then
		match.rematchOpen = false -- the rival left during the rematch window
		return
	end
	-- Mid-match: the rival wins by forfeit.
	match.over, match.forfeited = true, true
	for _, seat in match.seats do
		if seat.player and seat.player ~= player then
			pcall(function()
				Remotes.VsResult:FireClient(
					seat.player,
					{ result = "forfeit", you = seat.score, them = otherSeat(match, seat).score }
				)
			end)
		end
	end
	release(match)
end

function VsService.start(): ()
	if started then
		return
	end
	started = true
	local function connect(remote: RemoteEvent, name: string, handler: (Player, any) -> ())
		remote.OnServerEvent:Connect(function(player: Player, raw: any)
			local ok, err = pcall(function()
				handler(player, raw)
			end)
			if not ok then
				warn(`[MathShow] {name} from {player.Name} failed: {err}`)
			end
		end)
	end
	connect(Remotes.QueueJoin, "QueueJoin", onJoin)
	connect(Remotes.QueueCancel, "QueueCancel", onCancel)
	connect(Remotes.QueueKeepWaiting, "QueueKeepWaiting", onKeepWaiting)
	connect(Remotes.VsAnswer, "VsAnswer", onAnswer)
	connect(Remotes.RematchRequest, "RematchRequest", onRematch)
	Players.PlayerRemoving:Connect(onLeaving)
end

-- Studio-test surface (multi-client scenarios drive the same handlers the remotes call).
VsService._test = {
	join = onJoin,
	answer = onAnswer,
	cancel = onCancel,
	rematch = onRematch,
	matchOf = function(player: Player): Match?
		return playerMatch[player]
	end,
}

return VsService
