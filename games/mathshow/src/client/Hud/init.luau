--!strict
-- MathShow Hud (TASK-0093): question, server-time countdown, digit input, feedback.
-- Driven only by RoundState and AnswerResult. Sends at most one SubmitAnswer per question and never waits
-- on a reply (the server sends none for throttled or malformed submissions).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudConfig = require(Shared:WaitForChild("HudConfig"))
local HudRules = require(Shared:WaitForChild("HudRules"))
local Net = require(Shared:WaitForChild("Net"))
local StandingsRules = require(Shared:WaitForChild("StandingsRules"))

local Fx = require(script.Fx)
local View = require(script.View)

local Strings = HudConfig.Strings

local Hud = {}

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
	-- last values written to the timer instances
	shownFraction: number,
	shownLabel: string,
	shownWarn: boolean,
	submit: RemoteEvent?,
	startedAt: number,
	gotState: boolean,
}

local session: Session? = nil

local function stopCountdown(s: Session)
	if s.countdown then
		s.countdown:Disconnect()
		s.countdown = nil
	end
end

local function renderTimer(s: Session, visible: boolean)
	local now = workspace:GetServerTimeNow()
	local fraction = math.floor(HudRules.timerFraction(s.endsAt, now, s.totalSeconds) * 1000 + 0.5) / 1000
	local left = HudRules.secondsLeft(s.endsAt, now)
	local label = tostring(math.ceil(left))
	local warn_ = left <= HudConfig.TimerWarnSeconds
	if fraction ~= s.shownFraction or label ~= s.shownLabel or warn_ ~= s.shownWarn then
		s.shownFraction, s.shownLabel, s.shownWarn = fraction, label, warn_
		s.view.setTimer(fraction, label, visible, warn_)
	end
end

local function startCountdown(s: Session)
	if s.countdown then
		return
	end
	s.shownFraction, s.shownLabel, s.shownWarn = -1, "", false
	s.countdown = RunService.Heartbeat:Connect(function()
		renderTimer(s, true)
	end)
end

-- Cosmetic: a fault here warns and leaves the rest of the Hud working.
local function applyResults(s: Session, show: HudRules.Visibility, payload: any)
	local ok, err = pcall(function()
		if not show.results then
			s.view.setResults(nil, nil)
		elseif StandingsRules.isValidScores(payload.scores) then
			s.view.setResults(StandingsRules.build(payload.scores, Players.LocalPlayer.UserId), nil)
		else
			warn("[MathShow] Hud ignored malformed scores")
			s.view.setResults(nil, Strings.ScoresUnavailable)
		end
	end)
	if not ok then
		warn(`[MathShow] Hud results failed: {err}`)
	end
end

local function applyState(s: Session, payload: any)
	if not HudRules.isValidState(payload) then
		warn("[MathShow] Hud ignored a malformed RoundState")
		return
	end
	local phase: HudRules.Phase = payload.phase
	local newQuestion = phase == "Question" and payload.questionIndex ~= s.questionIndex
	if not s.gotState then
		s.gotState = true
		print(`[MathShow] Hud first RoundState after {string.format("%.2f", os.clock() - s.startedAt)}s`)
	end

	s.phase = phase
	s.questionIndex = payload.questionIndex
	s.endsAt = payload.endsAt
	local total = HudRules.phaseSeconds(phase, payload.questionIndex)
	s.totalSeconds = total or HudRules.secondsLeft(payload.endsAt, workspace:GetServerTimeNow())

	if phase == "Intermission" or phase == "Results" then
		s.submittedIndex, s.pendingIndex = 0, 0
	end
	if newQuestion then
		s.pendingIndex = 0
		s.view.clearFeedback()
		Fx.reset(s.view.feedbackLabel)
		s.view.setInputText("")
	end

	local show = HudRules.visibility(phase)
	s.view.setQuestion(HudRules.questionLabel(phase, payload), show.question)
	s.view.setInputVisible(show.input)
	if show.input then
		s.view.setInputEnabled(s.submittedIndex ~= s.questionIndex)
	end

	if phase == "Results" or phase == "Intermission" then
		s.view.clearFeedback()
	elseif phase == "Reveal" and s.submittedIndex ~= s.questionIndex then
		s.view.setFeedback(Strings.TimesUp, "info")
	end

	applyResults(s, show, payload)
	-- Cosmetic: a fault here warns and leaves the rest of the Hud working.
	local solversOk, solversErr = pcall(function()
		local solvers = ""
		if phase == "Reveal" and payload.solvers ~= nil then
			solvers = HudRules.solversLabel(payload.solvers)
			if solvers == "" then
				warn("[MathShow] Hud ignored malformed solvers")
			end
		end
		s.view.setSolvers(solvers)
	end)
	if not solversOk then
		warn(`[MathShow] Hud solvers failed: {solversErr}`)
	end

	local counting = show.timer and payload.endsAt > 0
	if counting then
		startCountdown(s)
		renderTimer(s, true)
	else
		stopCountdown(s)
		s.view.setTimer(0, "", false, false)
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
	s.view.setInputEnabled(false)
	s.view.setFeedback(Strings.Sent, "info")
	local ok, err = pcall(function()
		remote:FireServer(text)
	end)
	if not ok then
		warn(`[MathShow] Hud SubmitAnswer failed: {err}`)
		-- Nothing reached the server: unlock this question so the player can try again.
		s.submittedIndex, s.pendingIndex = 0, 0
		s.view.setInputEnabled(true)
		s.view.setFeedback(Strings.SendFailed, "bad")
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
	local kind, text = HudRules.feedbackFor(payload)
	s.view.setFeedback(text, if kind == "correct" then "good" elseif kind == "incorrect" then "bad" else "info")
	Fx.fadeIn(s.view.feedbackLabel, HudConfig.FeedbackFadeSeconds)
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
	view.input.PlaceholderText = Strings.Placeholder
	view.submitButton.Text = Strings.Submit
	view.setQuestion(Strings.Connecting, true)
	view.setInputEnabled(true)

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
		shownFraction = -1,
		shownLabel = "",
		shownWarn = false,
		submit = nil,
		startedAt = os.clock(),
		gotState = false,
	}
	session = s

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
		end)
	)

	task.spawn(connectRemotes, s)
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
	Fx.destroy()
	s.view.destroy()
end

return Hud
