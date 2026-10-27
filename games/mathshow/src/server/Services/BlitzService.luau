--!strict
-- BlitzService (TASK-0103): solo Blitz, ten problems against one clock, scored at the end. The server generates all ten
-- problems at the start and keeps the answers; the client only ever receives the current problem text (BlitzState). An
-- answer is acknowledged with the same AnswerAck whether it is right or wrong; correctness, solutions and the score leave the
-- server only in BlitzResult, after the clock ends or question 10 is answered. The personal best is saved through
-- ProfileService (the stored best only ever goes up). A player who leaves mid-run costs nothing and saves nothing.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BlitzRules = require(Shared:WaitForChild("BlitzRules"))
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local ModeRules = require(Shared:WaitForChild("ModeRules"))
local ProblemRules = require(Shared:WaitForChild("ProblemRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local ProfileService = require(script.Parent.ProfileService)

type Session = {
	index: number, -- the question being asked, 1..BlitzTotal
	problems: { ProblemRules.Problem },
	answers: { number | boolean }, -- false = not answered
	answered: boolean, -- the current question has an answer
	endsClock: number, -- os.clock() when the run clock ends
	endsAt: number, -- the same moment, workspace:GetServerTimeNow() based
	previousBest: number?,
	ended: boolean,
	answerStamps: { number },
}

local BlitzService = {}

local started = false
local sessions: { [Player]: Session } = {}
local startStamps: { [Player]: { number } } = {}

local function alive(player: Player, session: Session): boolean
	return sessions[player] == session and player.Parent ~= nil and not session.ended
end

local function sendState(player: Player, session: Session)
	local problem = session.problems[session.index]
	local ok, err = pcall(function()
		Remotes.BlitzState:FireClient(player, {
			state = "question",
			questionIndex = session.index,
			problem = problem.text,
			endsAt = session.endsAt,
			total = MenuConfig.BlitzClockSeconds,
		})
	end)
	if not ok then
		warn(`[MathShow] BlitzState to {player.Name} failed: {err}`)
	end
end

local function refuse(player: Player, state: string)
	pcall(function()
		Remotes.BlitzState:FireClient(player, { state = state, questionIndex = 0, endsAt = 0, total = 0 })
	end)
end

local function finish(player: Player, session: Session)
	if session.ended then
		return
	end
	session.ended = true
	local correct = 0
	local answers: { number | boolean } = {}
	local solutions: { number } = {}
	for index, problem in session.problems do
		local answer = session.answers[index]
		answers[index] = if typeof(answer) == "number" then answer else false
		solutions[index] = problem.answer
		if typeof(answer) == "number" and answer == problem.answer then
			correct += 1
		end
	end
	local newBest = BlitzRules.isNewBest(correct, session.previousBest)
	ProfileService.apply(player, { blitzBest = correct })
	sessions[player] = nil
	local ok, err = pcall(function()
		Remotes.BlitzResult:FireClient(player, {
			correct = correct,
			answers = answers,
			solutions = solutions,
			previousBest = session.previousBest,
			newBest = newBest,
		})
	end)
	if not ok then
		warn(`[MathShow] BlitzResult to {player.Name} failed: {err}`)
	end
	print(`[MathShow] blitz user={player.UserId} correct={correct} newBest={newBest}`)
end

local function onStart(player: Player, raw: any)
	if not BlitzRules.validStart(raw) then
		return
	end
	local allowed
	startStamps[player], allowed =
		RateRules.allow(startStamps[player] or {}, os.clock(), MenuConfig.BlitzStartsPer10s, 10)
	if not allowed or sessions[player] then
		return
	end
	if ModeRules.cardState("blitz") ~= "open" then
		refuse(player, "unavailable")
		return
	end
	local profile = ProfileService.get(player)
	if not profile then
		refuse(player, "unavailable")
		return
	end
	local seed = Random.new():NextInteger(1, 2 ^ 30)
	local problems: { ProblemRules.Problem } = {}
	for index = 1, MenuConfig.BlitzTotal do
		problems[index] = ProblemRules.generate(seed + index, BlitzRules.difficultyFor(index))
	end
	local clock = MenuConfig.BlitzClockSeconds
	local session: Session = {
		index = 1,
		problems = problems,
		answers = {},
		answered = false,
		endsClock = os.clock() + clock,
		endsAt = Workspace:GetServerTimeNow() + clock,
		previousBest = profile.blitzBest,
		ended = false,
		answerStamps = {},
	}
	sessions[player] = session
	sendState(player, session)
	task.delay(clock + MenuConfig.BlitzGraceSeconds, function()
		if alive(player, session) then
			finish(player, session) -- the clock ran out: whatever was answered counts
		end
	end)
end

local function onAnswer(player: Player, raw: any)
	local session = sessions[player]
	if not session or session.ended then
		return
	end
	local allowed
	session.answerStamps, allowed = RateRules.allow(session.answerStamps, os.clock(), MenuConfig.BlitzAnswersPer10s, 10)
	if not allowed then
		return
	end
	local index, answer = BlitzRules.parseAnswerPayload(raw)
	if index == nil or answer == nil or index ~= session.index or session.answered then
		return
	end
	if os.clock() > session.endsClock + MenuConfig.BlitzGraceSeconds then
		return
	end
	session.answered = true -- before any yield: two quick answers cannot both count
	session.answers[index] = answer
	-- The same ack whatever the answer was: nothing about correctness leaves the server until BlitzResult.
	pcall(function()
		Remotes.AnswerAck:FireClient(player, { questionIndex = index })
	end)
	task.delay(MenuConfig.BlitzNextDelaySeconds, function()
		if not alive(player, session) then
			return
		end
		if session.index >= MenuConfig.BlitzTotal then
			finish(player, session)
		else
			session.index += 1
			session.answered = false
			sendState(player, session)
		end
	end)
end

function BlitzService.start(): ()
	if started then
		return
	end
	started = true
	Remotes.BlitzStart.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onStart(player, raw)
		end)
		if not ok then
			warn(`[MathShow] BlitzStart from {player.Name} failed: {err}`)
		end
	end)
	Remotes.BlitzAnswer.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onAnswer(player, raw)
		end)
		if not ok then
			warn(`[MathShow] BlitzAnswer from {player.Name} failed: {err}`)
		end
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		sessions[player] = nil
		startStamps[player] = nil
	end)
end

return BlitzService
