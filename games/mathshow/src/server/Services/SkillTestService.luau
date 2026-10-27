--!strict
-- SkillTestService (TASK-0102): the server-authoritative Skill Test. The client asks to start (SkillStart); the server checks
-- the cooldown from the stored profile, issues one question at a time (SkillState), validates every answer (SkillAnswer:
-- attempt, range, time, once per question), reveals the correct answer only after the question closes, ends the run after
-- two misses in a row (or rank 9), and persists the best rank and the cooldown through ProfileService.
-- Answers never leave the server before reveal. A player who leaves mid-run costs nothing (jg default): the cooldown starts
-- when a run ends. Nothing here trusts the client: it only supplies an attempt number and an answer.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local ModeRules = require(Shared:WaitForChild("ModeRules"))
local Net = require(Shared:WaitForChild("Net"))
local ProfileRules = require(Shared:WaitForChild("ProfileRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))
local SkillProblemRules = require(Shared:WaitForChild("SkillProblemRules"))
local SkillRules = require(Shared:WaitForChild("SkillRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local ProfileService = require(script.Parent.ProfileService)

type Session = {
	run: SkillRules.Run,
	problem: SkillProblemRules.Problem?,
	attempt: number, -- question number in this run
	answered: boolean, -- the current question is closed (answered or timed out)
	endsClock: number, -- os.clock() deadline of the current question
	seedBase: number,
	previousBest: number?,
	answerStamps: { number },
}

local SkillTestService = {}

local started = false
local sessions: { [Player]: Session } = {}
local startStamps: { [Player]: { number } } = {}

local function send(player: Player, payload: Net.SkillStatePayload)
	local ok, err = pcall(function()
		Remotes.SkillState:FireClient(player, payload)
	end)
	if not ok then
		warn(`[MathShow] SkillState to {player.Name} failed: {err}`)
	end
end

local function refuse(player: Player, state: string, retryAt: number?)
	send(player, {
		state = state,
		attempt = 0,
		rank = 0,
		kind = "integer",
		endsAt = 0,
		total = 0,
		misses = 0,
		retryAt = retryAt,
	})
end

local function alive(player: Player, session: Session): boolean
	return sessions[player] == session and player.Parent ~= nil
end

local askQuestion: (Player, Session) -> ()

local function finish(player: Player, session: Session)
	local outcome = SkillRules.outcome(session.previousBest, session.run.cleared)
	local now = os.time()
	local retryAt = ProfileRules.retryAt(now, nil) :: number
	ProfileService.apply(player, { bestRank = outcome.best, lastTestRank = outcome.lastTest, lastTakenAt = now })
	sessions[player] = nil
	send(player, {
		state = "ended",
		attempt = session.attempt,
		rank = session.run.rank,
		kind = SkillRules.kindFor(session.run.rank),
		endsAt = 0,
		total = 0,
		misses = session.run.misses,
		retryAt = retryAt,
	})
	local ok, err = pcall(function()
		Remotes.SkillResult:FireClient(player, {
			kind = outcome.kind,
			cleared = session.run.cleared,
			best = outcome.best,
			retryAt = retryAt,
		})
	end)
	if not ok then
		warn(`[MathShow] SkillResult to {player.Name} failed: {err}`)
	end
	print(
		`[MathShow] skill test user={player.UserId} cleared={session.run.cleared} result={outcome.kind} best={outcome.best}`
	)
end

-- Closes the current question (answered or timed out), advances the run and reveals; then, after the reveal, asks the next
-- question or finishes. No yield between reading and writing the session, so two quick answers cannot both count.
local function resolve(player: Player, session: Session, correct: boolean)
	local problem = session.problem
	if session.answered or not problem then
		return
	end
	session.answered = true
	local asked = session.run.rank
	session.run = SkillRules.advance(session.run, correct)
	local reveal = MenuConfig.SkillRevealSeconds
	send(player, {
		state = "reveal",
		attempt = session.attempt,
		rank = asked,
		kind = problem.kind,
		problem = problem.text,
		endsAt = Workspace:GetServerTimeNow() + reveal,
		total = reveal,
		misses = session.run.misses,
		correct = correct,
		correctValue = if problem.kind == "integer" then problem.answer else nil,
		correctIndex = problem.correctIndex,
	})
	task.delay(reveal, function()
		if not alive(player, session) then
			return
		end
		if session.run.finished then
			finish(player, session)
		else
			askQuestion(player, session)
		end
	end)
end

askQuestion = function(player: Player, session: Session)
	session.attempt += 1
	local attempt = session.attempt
	local rank = session.run.rank
	local problem = SkillProblemRules.generate(rank, session.seedBase + attempt)
	if not problem then
		warn(`[MathShow] no skill problem for rank {rank}; ending the run`)
		session.run = { rank = rank, misses = session.run.misses, cleared = session.run.cleared, finished = true }
		finish(player, session)
		return
	end
	local limit = SkillRules.timeLimit(problem.kind :: SkillRules.Kind)
	session.problem = problem
	session.answered = false
	session.endsClock = os.clock() + limit
	send(player, {
		state = "question",
		attempt = attempt,
		rank = rank,
		kind = problem.kind,
		problem = problem.text,
		choices = problem.choices,
		endsAt = Workspace:GetServerTimeNow() + limit,
		total = limit,
		misses = session.run.misses,
	})
	task.delay(limit + MenuConfig.SkillGraceSeconds, function()
		if alive(player, session) and session.attempt == attempt and not session.answered then
			resolve(player, session, false) -- time ran out: a miss
		end
	end)
end

local function onStart(player: Player, raw: any)
	if not SkillRules.validStart(raw) then
		return
	end
	local allowed
	startStamps[player], allowed =
		RateRules.allow(startStamps[player] or {}, os.clock(), MenuConfig.SkillStartsPer10s, 10)
	if not allowed or sessions[player] then
		return
	end
	if ModeRules.secondaryState("skilltest") ~= "open" then
		refuse(player, "unavailable", nil)
		return
	end
	local profile = ProfileService.get(player)
	if not profile then
		refuse(player, "unavailable", nil)
		return
	end
	local retryAt = ProfileRules.retryAt(profile.lastTakenAt, nil)
	if retryAt ~= nil and retryAt > os.time() then
		refuse(player, "cooldown", retryAt)
		return
	end
	local session: Session = {
		run = SkillRules.newRun(),
		problem = nil,
		attempt = 0,
		answered = true,
		endsClock = 0,
		seedBase = Random.new():NextInteger(1, 2 ^ 30),
		previousBest = profile.bestRank,
		answerStamps = {},
	}
	sessions[player] = session
	askQuestion(player, session)
end

local function onAnswer(player: Player, raw: any)
	local session = sessions[player]
	if not session then
		return
	end
	local allowed
	session.answerStamps, allowed = RateRules.allow(session.answerStamps, os.clock(), MenuConfig.SkillAnswersPer5s, 5)
	if not allowed then
		return
	end
	local attempt, value = SkillRules.parseAnswerPayload(raw)
	local problem = session.problem
	if attempt == nil or attempt ~= session.attempt or session.answered or not problem then
		return
	end
	if os.clock() > session.endsClock + MenuConfig.SkillGraceSeconds then
		return -- the timeout handler will count this question as a miss
	end
	local answer = SkillRules.validAnswer(problem.kind :: SkillRules.Kind, value)
	if answer == nil then
		return
	end
	local correct = if problem.kind == "choice" then answer == problem.correctIndex else answer == problem.answer
	resolve(player, session, correct)
end

function SkillTestService.start(): ()
	if started then
		return
	end
	started = true
	Remotes.SkillStart.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onStart(player, raw)
		end)
		if not ok then
			warn(`[MathShow] SkillStart from {player.Name} failed: {err}`)
		end
	end)
	Remotes.SkillAnswer.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onAnswer(player, raw)
		end)
		if not ok then
			warn(`[MathShow] SkillAnswer from {player.Name} failed: {err}`)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil -- leaving mid-run costs nothing; pending timers see the session gone
		startStamps[player] = nil
	end)
end

return SkillTestService
