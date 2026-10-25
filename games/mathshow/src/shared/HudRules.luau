--!strict
-- Pure Hud rules (client/Hud, TASK-0093). No Instances, no services, no clock: callers pass the time in.
-- Nothing here throws on bad input; the Hud warns about and ignores what these helpers reject.

local HudConfig = require(script.Parent.HudConfig)
local Net = require(script.Parent.Net)
local ProblemConfig = require(script.Parent.ProblemConfig)
local RoundConfig = require(script.Parent.RoundConfig)
local ScoringConfig = require(script.Parent.ScoringConfig)
local ScoringRules = require(script.Parent.ScoringRules)

export type Phase = "Intermission" | "Question" | "Reveal" | "Results"
export type FeedbackKind = "correct" | "incorrect" | "notCounted"
export type Visibility = { question: boolean, timer: boolean, input: boolean }

local PHASES: { [string]: boolean } = { Intermission = true, Question = true, Reveal = true, Results = true }

local HudRules = {}

local function isFinite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- ASCII digits only, at most ScoringConfig.DigitCap of them. Anything else is dropped.
function HudRules.sanitizeInput(text: any): string
	if typeof(text) ~= "string" then
		return ""
	end
	local digits = text:gsub("[^0-9]", "")
	return digits:sub(1, ScoringConfig.DigitCap)
end

-- Seconds the phase lasts, or nil when it has no fixed length here (Results, unknown, bad index).
function HudRules.phaseSeconds(phase: any, questionIndex: any): number?
	if phase == "Intermission" then
		return RoundConfig.IntermissionSeconds
	elseif phase == "Reveal" then
		return RoundConfig.RevealSeconds
	elseif phase == "Question" then
		if not isFinite(questionIndex) then
			return nil
		end
		local difficulty = RoundConfig.DifficultyByQuestion[questionIndex]
		local tier = if difficulty ~= nil then ProblemConfig.Tiers[difficulty] else nil
		return if tier ~= nil then tier.timeLimit else nil
	end
	return nil
end

function HudRules.secondsLeft(endsAt: any, now: any): number
	if not (isFinite(endsAt) and isFinite(now)) then
		return 0
	end
	return math.max(0, endsAt - now)
end

function HudRules.timerFraction(endsAt: any, now: any, total: any): number
	if not (isFinite(total) and total > 0) then
		return 0
	end
	return math.clamp(HudRules.secondsLeft(endsAt, now) / total, 0, 1)
end

-- Deliberately ignores the clock: the server accepts answers LateGraceSeconds past endsAt.
function HudRules.canSubmit(phase: any, questionIndex: any, submittedIndex: any, text: any): boolean
	return phase == "Question" and submittedIndex ~= questionIndex and ScoringRules.parseAnswer(text) ~= nil
end

function HudRules.isValidState(payload: any): boolean
	if typeof(payload) ~= "table" then
		return false
	end
	local phase = payload.phase
	if typeof(phase) ~= "string" or not PHASES[phase] then
		return false
	end
	if not (isFinite(payload.endsAt) and isFinite(payload.questionIndex)) then
		return false
	end
	if payload.problemText ~= nil and typeof(payload.problemText) ~= "string" then
		return false
	end
	if payload.answer ~= nil and not isFinite(payload.answer) then
		return false
	end
	return true
end

function HudRules.isValidResult(payload: any): boolean
	if typeof(payload) ~= "table" or typeof(payload.accepted) ~= "boolean" then
		return false
	end
	if payload.correct ~= nil and typeof(payload.correct) ~= "boolean" then
		return false
	end
	if payload.points ~= nil and not isFinite(payload.points) then
		return false
	end
	return true
end

-- payload must have passed isValidState.
function HudRules.questionLabel(phase: Phase, payload: Net.RoundStatePayload): string
	local strings = HudConfig.Strings
	if phase == "Intermission" then
		return if payload.endsAt == 0 then strings.WaitingForPlayers else strings.GetReady
	elseif phase == "Question" or phase == "Reveal" then
		local text = payload.problemText
		if text == nil then
			return ""
		end
		if phase == "Reveal" and payload.answer ~= nil then
			return `{text} = {payload.answer}`
		end
		return `{text} = ?`
	end
	return ""
end

function HudRules.feedbackFor(result: any): (FeedbackKind, string)
	local strings = HudConfig.Strings
	if not HudRules.isValidResult(result) or result.accepted ~= true then
		return "notCounted", strings.NotCounted
	end
	if result.correct == true then
		local points = result.points
		return "correct", if isFinite(points) then strings.Correct:format(points) else strings.CorrectPlain
	end
	return "incorrect", strings.Incorrect
end

function HudRules.visibility(phase: any): Visibility
	if phase == "Question" then
		return { question = true, timer = true, input = true }
	elseif phase == "Intermission" or phase == "Reveal" then
		return { question = true, timer = true, input = false }
	end
	return { question = false, timer = false, input = false }
end

return table.freeze(HudRules)
