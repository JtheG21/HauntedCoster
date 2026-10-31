--!strict
-- Pure Hud rules (client/Hud, TASK-0093). No Instances, no services, no clock: callers pass the time in.
-- Nothing here throws on bad input; the Hud warns about and ignores what these helpers reject.

local HudConfig = require(script.Parent.HudConfig)
local HudCopy = require(script.Parent.HudCopy)
local Net = require(script.Parent.Net)
local ProblemConfig = require(script.Parent.ProblemConfig)
local RoundConfig = require(script.Parent.RoundConfig)
local ScoringConfig = require(script.Parent.ScoringConfig)
local ScoringRules = require(script.Parent.ScoringRules)
local StandingsRules = require(script.Parent.StandingsRules)

export type Phase = "Intermission" | "Question" | "Reveal" | "Results"
export type ToastKind = "sent" | "correct" | "wrong" | "timesup" | "rejected" | "sendfail"
export type Toast = { kind: string, text: string, points: string } -- points is "+N" for a correct answer, else ""
export type Visibility = { question: boolean, timer: boolean, input: boolean, results: boolean }
export type PipState = "done" | "current" | "todo"
export type TopModel = { label: string, pips: { PipState }? } -- pips nil: no pips in this phase
export type ProblemModel = { tag: string, lead: string, tail: string, size: number, gap: number }
export type Chip = { name: string, points: string, isYou: boolean }
export type SolversModel = { chips: { Chip }, more: string, nobody: boolean }

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

-- Difficulty tier (1..3) of a question, nil outside 1..QuestionCount.
function HudRules.difficultyOf(questionIndex: any): number?
	if not isFinite(questionIndex) then
		return nil
	end
	return RoundConfig.DifficultyByQuestion[questionIndex]
end

-- "Q3 · MEDIUM · 12S"; "" when the question index is unknown.
function HudRules.questionTag(questionIndex: any): string
	local difficulty = HudRules.difficultyOf(questionIndex)
	local seconds = HudRules.phaseSeconds("Question", questionIndex)
	local tier = if difficulty ~= nil then HudCopy.Tier[difficulty] else nil
	if tier == nil or seconds == nil then
		return ""
	end
	return HudCopy.QuestionTag:format(questionIndex, tier, seconds)
end

-- Text size from the character count of "a op b = ?": 9 or fewer 88, 10-11 76, 12 or more 64.
function HudRules.problemSize(chars: any): number
	if not isFinite(chars) or chars <= HudConfig.ProblemShortChars then
		return HudConfig.ProblemSizeSmall
	elseif chars <= HudConfig.ProblemMediumChars then
		return HudConfig.ProblemSizeMedium
	end
	return HudConfig.ProblemSizeLarge
end

-- Characters of the whole line "lead tail", the way a player reads it.
function HudRules.problemChars(lead: string, tail: string): number
	return (utf8.len(lead) or #lead) + 1 + (utf8.len(tail) or #tail)
end

-- The problem shard text for Question and Reveal; nil when there is nothing to show. The answer only ever
-- appears in Reveal, even if the payload carries one earlier. payload must have passed isValidState.
function HudRules.problemModel(phase: Phase, payload: Net.RoundStatePayload): ProblemModel?
	if phase ~= "Question" and phase ~= "Reveal" then
		return nil
	end
	local lead = payload.problemText
	if lead == nil then
		return nil
	end
	local revealed = phase == "Reveal" and payload.answer ~= nil
	local tail = HudCopy.Equals:format(if revealed then tostring(payload.answer) else HudCopy.Unknown)
	local size = HudRules.problemSize(HudRules.problemChars(lead, tail))
	return {
		tag = if phase == "Reveal" then HudCopy.AnswerTag else HudRules.questionTag(payload.questionIndex),
		lead = lead,
		tail = tail,
		size = size,
		gap = math.floor(size * HudConfig.ProblemGapRatio + 0.5),
	}
end

-- Lobby while the show waits for players, the countdown card once it has an end time.
function HudRules.intermissionMode(endsAt: any): string
	return if endsAt == 0 or not isFinite(endsAt) then "waiting" else "ready"
end

function HudRules.pipStates(phase: any, questionIndex: any): { PipState }
	local states: { PipState } = {}
	local current = if isFinite(questionIndex) then questionIndex else 0
	for index = 1, RoundConfig.QuestionCount do
		local state: PipState = "todo"
		if index < current or (index == current and phase == "Reveal") then
			state = "done"
		elseif index == current then
			state = "current"
		end
		table.insert(states, state)
	end
	return states
end

function HudRules.topModel(phase: any, questionIndex: any): TopModel
	if phase == "Question" or phase == "Reveal" then
		local index = if isFinite(questionIndex) then questionIndex else 0
		return {
			label = HudCopy.TopQuestion:format(index, RoundConfig.QuestionCount),
			pips = HudRules.pipStates(phase, questionIndex),
		}
	elseif phase == "Results" then
		return { label = HudCopy.TopResults, pips = nil }
	end
	return { label = HudCopy.TopLobby, pips = nil }
end

-- Tag under the big seconds number: SEC while counting, what comes next during Reveal.
function HudRules.secondsTag(phase: any, questionIndex: any): string
	if phase == "Reveal" then
		return if isFinite(questionIndex) and questionIndex < RoundConfig.QuestionCount
			then HudCopy.NextLabel
			else HudCopy.ResultsLabel
	end
	return HudCopy.SecondsLabel
end

function HudRules.scoreTag(phase: any): string
	return if phase == "Results" then HudCopy.NextMatch else HudCopy.Score
end

-- Scale for the 844x390 root so it fits the safe area; 1 for a bad size.
function HudRules.rootScale(width: any, height: any): number
	if not (isFinite(width) and isFinite(height)) or width <= 0 or height <= 0 then
		return 1
	end
	return math.min(width / HudConfig.ReferenceWidth, height / HudConfig.ReferenceHeight)
end

function HudRules.toastFor(kind: string, points: any): Toast
	local text = HudCopy.Sent
	if kind == "correct" then
		text = HudCopy.Correct
	elseif kind == "wrong" then
		text = HudCopy.Wrong
	elseif kind == "timesup" then
		text = HudCopy.TimesUp
	elseif kind == "rejected" then
		text = HudCopy.Rejected
	elseif kind == "sendfail" then
		text = HudCopy.SendFailed
	end
	local pointsText = ""
	if kind == "correct" and isFinite(points) then
		pointsText = HudCopy.CorrectPoints:format(StandingsRules.cleanPoints(points))
	end
	return { kind = kind, text = text, points = pointsText }
end

-- Maps the server's AnswerResult to a toast kind and the points it earned (nil when none were sent).
function HudRules.feedbackFor(result: any): (string, number?)
	if not HudRules.isValidResult(result) or result.accepted ~= true then
		return "rejected", nil
	end
	if result.correct == true then
		return "correct", if isFinite(result.points) then StandingsRules.cleanPoints(result.points) else nil
	end
	return "wrong", nil
end

-- The Reveal solver chips from the server's solvers list; nil when the list is malformed.
function HudRules.solversModel(solvers: any, localUserId: any): SolversModel?
	if not StandingsRules.isValidScores(solvers) then
		return nil
	end
	local list = solvers :: { Net.ScoreEntry }
	local chips: { Chip } = {}
	for index = 1, math.min(#list, HudConfig.MaxSolverNames) do
		local entry = list[index]
		table.insert(chips, {
			name = StandingsRules.displayName(entry.name),
			points = HudCopy.SolverPoints:format(StandingsRules.cleanPoints(entry.points)),
			isYou = entry.userId == localUserId,
		})
	end
	return {
		chips = chips,
		more = if #list > #chips then HudCopy.More:format(#list - #chips) else "",
		nobody = #list == 0,
	}
end

function HudRules.visibility(phase: any): Visibility
	if phase == "Question" then
		return { question = true, timer = true, input = true, results = false }
	elseif phase == "Intermission" or phase == "Reveal" then
		return { question = true, timer = true, input = false, results = false }
	elseif phase == "Results" then
		return { question = false, timer = false, input = false, results = true }
	end
	return { question = false, timer = false, input = false, results = false }
end

return table.freeze(HudRules)
