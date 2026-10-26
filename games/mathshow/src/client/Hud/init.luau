--!strict
-- MathShow Hud (TASK-0093, shards pass TASK-0097): question, server-time countdown, digit input, feedback.
-- Driven only by RoundState and AnswerResult. Sends at most one SubmitAnswer per question and never waits
-- on a reply (the server sends none for throttled or malformed submissions). Motion is cosmetic: every Fx call is
-- isolated, and nothing here waits on it.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudConfig = require(Shared:WaitForChild("HudConfig"))
local HudCopy = require(Shared:WaitForChild("HudCopy"))
local HudRules = require(Shared:WaitForChild("HudRules"))
local Net = require(Shared:WaitForChild("Net"))
local StandingsRules = require(Shared:WaitForChild("StandingsRules"))

local Fx = require(script.Fx)
local Theme = require(script.Theme)
local View = require(script.View)

local Hud = {}

type Feedback = { kind: string, points: number? }

type Session = {
	view: View.View,
	connections: { RBXScriptConnection },
	countdown: RBXScriptConnection?,
	-- round state
	phase: string,
	questionIndex: number,
	endsAt: number,
	totalSeconds: number,
	submittedIndex: number, -- question we already sent an answer for, 0 = none
	pendingIndex: number, -- question awaiting an AnswerResult, 0 = none
	key: string, -- phase, question and intermission mode of the last RoundState; a change plays the entrance
	feedback: Feedback?, -- the last toast of this question
	scoreText: string,
	-- last values written to the timer instances
	shownFraction: number,
	shownLabel: string,
	shownWarn: boolean,
	shownSecond: number, -- whole seconds left at the last Fx.secondTick, -1 = none yet
	glowStops: { () -> () },
	ambientStops: { () -> () },
	submit: RemoteEvent?,
	startedAt: number,
	gotState: boolean,
}

local session: Session? = nil

local function stopAll(stops: { () -> () })
	for _, stop in stops do
		stop()
	end
	table.clear(stops)
end

local function stopCountdown(s: Session)
	if s.countdown then
		s.countdown:Disconnect()
		s.countdown = nil
	end
end

-- Writes the countdown to whichever instances the phase uses. Cheap to call every frame.
local function renderTimer(s: Session)
	local now = workspace:GetServerTimeNow()
	local left = HudRules.secondsLeft(s.endsAt, now)
	local seconds = math.ceil(left)
	local label = tostring(seconds)
	if s.phase == "Results" then
		if label ~= s.shownLabel then
			s.shownLabel = label
			s.view.setScore(HudRules.scoreTag(s.phase), label)
		end
		return
	end
	local fraction = math.floor(HudRules.timerFraction(s.endsAt, now, s.totalSeconds) * 1000 + 0.5) / 1000
	local warn_ = s.phase == "Question" and left <= HudConfig.TimerWarnSeconds
	if fraction ~= s.shownFraction or label ~= s.shownLabel or warn_ ~= s.shownWarn then
		local warnChanged = warn_ ~= s.shownWarn
		s.shownFraction, s.shownLabel, s.shownWarn = fraction, label, warn_
		if s.phase == "Intermission" then
			s.view.setCountdown(label)
		else
			s.view.setTimer(
				fraction,
				label,
				true,
				warn_,
				HudRules.secondsTag(s.phase, s.questionIndex),
				s.phase == "Reveal"
			)
		end
		if warnChanged then
			s.view.setTop(HudRules.topModel(s.phase, s.questionIndex), warn_)
		end
	end
	if seconds ~= s.shownSecond then
		local first = s.shownSecond == -1
		s.shownSecond = seconds
		if not first then
			Fx.secondTick(s.view.tickParts, s.phase, left)
		end
	end
end

local function startCountdown(s: Session)
	if s.countdown then
		return
	end
	s.shownFraction, s.shownLabel, s.shownWarn, s.shownSecond = -1, "", false, -1
	s.countdown = RunService.Heartbeat:Connect(function()
		renderTimer(s)
	end)
end

local function refreshSubmit(s: Session)
	local enabled = s.submittedIndex ~= s.questionIndex and HudRules.sanitizeInput(s.view.input.Text) ~= ""
	s.view.setSubmitEnabled(enabled)
end

-- Shows (or clears) the toast and plays its entrance. Cosmetic: a fault warns and leaves the Hud working.
local function showToast(s: Session, feedback: Feedback?, delay: number?)
	s.feedback = feedback
	local ok, err = pcall(function()
		if feedback == nil then
			s.view.setToast(nil, false)
		else
			s.view.setToast(HudRules.toastFor(feedback.kind, feedback.points), s.phase == "Reveal")
			Fx.feedback(s.view.toastParts, feedback.kind, delay)
		end
	end)
	if not ok then
		warn(`[MathShow] Hud toast failed: {err}`)
	end
end

-- The local player's own toast during Reveal: what they got, or TIME'S UP when no answer came back.
local function revealFeedback(s: Session): Feedback
	local last = s.feedback
	if last ~= nil and last.kind ~= "sent" and last.kind ~= "sendfail" then
		return last
	end
	return { kind = "timesup", points = nil }
end

-- Cosmetic: a fault here warns and leaves the rest of the Hud working.
local function applyResults(s: Session, payload: any)
	local ok, err = pcall(function()
		if s.phase ~= "Results" then
			s.view.setResults(nil, nil)
		elseif StandingsRules.isValidScores(payload.scores) then
			s.view.setResults(StandingsRules.build(payload.scores, Players.LocalPlayer.UserId), nil)
		else
			warn("[MathShow] Hud ignored malformed scores")
			s.view.setResults(nil, HudCopy.Unavailable)
		end
	end)
	if not ok then
		warn(`[MathShow] Hud results failed: {err}`)
	end
end

local function applySolvers(s: Session, payload: any)
	local ok, err = pcall(function()
		local model: HudRules.SolversModel? = nil
		if s.phase == "Reveal" and payload.solvers ~= nil then
			model = HudRules.solversModel(payload.solvers, Players.LocalPlayer.UserId)
			if model == nil then
				warn("[MathShow] Hud ignored malformed solvers")
			end
		end
		s.view.setSolvers(model)
	end)
	if not ok then
		warn(`[MathShow] Hud solvers failed: {err}`)
	end
end

local function restartGlows(s: Session)
	stopAll(s.glowStops)
	for index, glow in s.view.visibleGlows() do
		table.insert(s.glowStops, Fx.breathe(glow, (index - 1) * 0.3))
	end
end

-- Plays the entrance for the phase that just began.
local function enterPhase(s: Session, mode: string)
	if s.phase == "Intermission" then
		Fx.enterIntermission(s.view.intermissionParts(mode))
	elseif s.phase == "Question" then
		Fx.enterQuestion(s.view.questionParts)
	elseif s.phase == "Reveal" then
		Fx.enterReveal(s.view.revealParts())
		showToast(s, revealFeedback(s), 0.52)
	elseif s.phase == "Results" then
		Fx.enterResults(s.view.resultsParts())
	end
end

local function applyState(s: Session, payload: any)
	if not HudRules.isValidState(payload) then
		warn("[MathShow] Hud ignored a malformed RoundState")
		return
	end
	local view = s.view
	local phase: HudRules.Phase = payload.phase
	local mode = HudRules.intermissionMode(payload.endsAt)
	local key = `{phase}-{payload.questionIndex}-{if phase == "Intermission" then mode else ""}`
	local entering = key ~= s.key
	local newQuestion = phase == "Question" and payload.questionIndex ~= s.questionIndex
	if not s.gotState then
		s.gotState = true
		print(`[MathShow] Hud first RoundState after {string.format("%.2f", os.clock() - s.startedAt)}s`)
	end

	s.key = key
	s.phase = phase
	s.questionIndex = payload.questionIndex
	s.endsAt = payload.endsAt
	local total = HudRules.phaseSeconds(phase, payload.questionIndex)
	s.totalSeconds = total or HudRules.secondsLeft(payload.endsAt, workspace:GetServerTimeNow())

	if phase == "Intermission" or phase == "Results" then
		s.submittedIndex, s.pendingIndex = 0, 0
	end
	if phase == "Intermission" then
		s.scoreText = "0" -- a new match starts from nothing
	end
	if newQuestion then
		s.pendingIndex = 0
		view.setInputText("")
	end

	-- Score: the value changes at Reveal only, from the server's scores list, and pops when it does.
	local popScore = false
	if phase == "Reveal" and payload.scores ~= nil then
		local text = StandingsRules.formatNumber(StandingsRules.scoreFor(payload.scores, Players.LocalPlayer.UserId))
		popScore = text ~= s.scoreText
		s.scoreText = text
	end

	local show = HudRules.visibility(phase)
	s.shownWarn = false
	view.setTop(HudRules.topModel(phase, payload.questionIndex), false)
	view.setScore(HudRules.scoreTag(phase), s.scoreText)
	view.setIntermission(if phase == "Intermission" then mode else "hidden")
	local difficulty = HudRules.difficultyOf(payload.questionIndex) or 1
	view.setProblem(HudRules.problemModel(phase, payload), Theme.TierGem[difficulty] or "green", phase == "Reveal")
	view.setInputVisible(show.input)
	view.setInputLocked(s.submittedIndex == s.questionIndex)
	refreshSubmit(s)
	view.setTimer(1, "", false, false, HudRules.secondsTag(phase, payload.questionIndex), phase == "Reveal")

	if newQuestion or phase == "Intermission" or phase == "Results" then
		showToast(s, nil)
	end
	applyResults(s, payload)
	applySolvers(s, payload)

	local counting = (show.timer or phase == "Results") and payload.endsAt > 0
	stopCountdown(s)
	if counting then
		startCountdown(s)
		renderTimer(s)
	end

	if entering then
		restartGlows(s)
		enterPhase(s, mode)
	end
	if popScore then
		Fx.pop(view.scoreGroup, 0, 0.42)
	end
end

local function trySubmit(s: Session)
	local text = HudRules.sanitizeInput(s.view.input.Text)
	if not HudRules.canSubmit(s.phase, s.questionIndex, s.submittedIndex, text) then
		return
	end
	local remote = s.submit
	if remote == nil then
		return
	end
	-- Lock first, synchronously, so nothing can send a second answer for this question.
	s.submittedIndex = s.questionIndex
	s.pendingIndex = s.questionIndex
	s.view.setInputLocked(true)
	refreshSubmit(s)
	showToast(s, { kind = "sent", points = nil }, nil)
	local ok, err = pcall(function()
		remote:FireServer(text)
	end)
	if not ok then
		warn(`[MathShow] Hud SubmitAnswer failed: {err}`)
		-- Nothing reached the server: unlock this question so the player can try again.
		s.submittedIndex, s.pendingIndex = 0, 0
		s.view.setInputLocked(false)
		refreshSubmit(s)
		showToast(s, { kind = "sendfail", points = nil }, nil)
	end
end

local function applyResult(s: Session, payload: any)
	if not HudRules.isValidResult(payload) then
		warn("[MathShow] Hud ignored a malformed AnswerResult")
		return
	end
	if s.pendingIndex == 0 or s.pendingIndex ~= s.questionIndex then
		return -- stale: no answer outstanding for the question on screen
	end
	s.pendingIndex = 0
	local kind, points = HudRules.feedbackFor(payload)
	showToast(s, { kind = kind, points = points }, nil)
end

local function connectRemotes(s: Session)
	local folder = ReplicatedStorage:WaitForChild("Remotes", HudConfig.ConnectTimeoutSeconds)
	local state = if folder then folder:WaitForChild(Net.RoundState, HudConfig.ConnectTimeoutSeconds) else nil
	local submit = if folder then folder:WaitForChild(Net.SubmitAnswer, HudConfig.ConnectTimeoutSeconds) else nil
	local result = if folder then folder:WaitForChild(Net.AnswerResult, HudConfig.ConnectTimeoutSeconds) else nil
	if session ~= s then
		return -- stopped while waiting
	end
	if not (state and submit and result and state:IsA("RemoteEvent") and result:IsA("RemoteEvent")) then
		warn("[MathShow] Hud: server remotes not found; Hud stays inert")
		return
	end
	s.submit = submit :: RemoteEvent
	table.insert(
		s.connections,
		(state :: RemoteEvent).OnClientEvent:Connect(function(payload: any)
			applyState(s, payload)
		end)
	)
	table.insert(
		s.connections,
		(result :: RemoteEvent).OnClientEvent:Connect(function(payload: any)
			applyResult(s, payload)
		end)
	)
end

function Hud.start()
	if session then
		return
	end
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local view = View.build(playerGui)
	view.setTop({ label = HudCopy.Connecting, pips = nil }, false)
	view.setScore(HudCopy.Score, "0")
	view.setInputLocked(false)
	view.setSubmitEnabled(false)

	local s: Session = {
		view = view,
		connections = {},
		countdown = nil,
		phase = "Connecting",
		questionIndex = 0,
		endsAt = 0,
		totalSeconds = 0,
		submittedIndex = 0,
		pendingIndex = 0,
		key = "",
		feedback = nil,
		scoreText = "0",
		shownFraction = -1,
		shownLabel = "",
		shownWarn = false,
		shownSecond = -1,
		glowStops = {},
		ambientStops = {},
		submit = nil,
		startedAt = os.clock(),
		gotState = false,
	}
	session = s

	-- Always-on ambience: sparkles twinkle and the edge text drifts. Each is isolated inside Fx.
	for index, spark in view.ambient.sparks do
		table.insert(s.ambientStops, Fx.twinkle(spark, (index - 1) * 0.6))
	end
	for _, edge in view.ambient.edges do
		table.insert(s.ambientStops, Fx.drift(edge))
	end

	table.insert(
		s.connections,
		view.input.FocusLost:Connect(function(enterPressed: boolean)
			if enterPressed then
				trySubmit(s)
			end
		end)
	)
	table.insert(
		s.connections,
		view.submitButton.Activated:Connect(function()
			trySubmit(s)
		end)
	)
	table.insert(
		s.connections,
		view.input:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = HudRules.sanitizeInput(view.input.Text)
			if clean ~= view.input.Text then
				view.setInputText(clean)
			end
			refreshSubmit(s)
		end)
	)

	task.spawn(connectRemotes, s)
end

-- Shows or hides the HUD ScreenGui; the menu hides it until JOIN SHOW. The match loop keeps running either way.
function Hud.setVisible(visible: boolean)
	local s = session
	if s then
		s.view.gui.Enabled = visible
	end
end

function Hud.stop()
	local s = session
	if not s then
		return
	end
	session = nil
	stopCountdown(s)
	for _, connection in s.connections do
		connection:Disconnect()
	end
	table.clear(s.connections)
	stopAll(s.glowStops)
	stopAll(s.ambientStops)
	Fx.destroy()
	s.view.destroy()
end

return Hud
