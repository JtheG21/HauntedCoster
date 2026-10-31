--!strict
-- Pure round phase machine (games/mathshow/DESIGN.md "Core loop"). No Instances, no clock. questionIndex is the
-- question the current phase belongs to: 0 in Intermission, 1..QuestionCount in Question and Reveal,
-- QuestionCount in Results. The caller increments it when it enters Question.

local ProblemConfig = require(script.Parent.ProblemConfig)
local RoundConfig = require(script.Parent.RoundConfig)

export type Phase = "Intermission" | "Question" | "Reveal" | "Results"

local RoundRules = {}

local function questionSeconds(questionIndex: number): number
	return ProblemConfig.Tiers[RoundConfig.DifficultyByQuestion[questionIndex]].timeLimit
end

function RoundRules.difficultyFor(questionIndex: number): number
	local difficulty = RoundConfig.DifficultyByQuestion[questionIndex]
	if difficulty == nil then
		error(`RoundRules.difficultyFor: question index {questionIndex} out of range`, 2)
	end
	return difficulty
end

-- Returns the phase that follows `phase` and how long it lasts in seconds. Errors on input outside the
-- contract (unknown phase, non-integer index, or an index that does not fit the phase).
function RoundRules.nextPhase(phase: Phase, questionIndex: number): (Phase, number)
	local count = RoundConfig.QuestionCount
	if questionIndex ~= math.floor(questionIndex) or questionIndex < 0 or questionIndex > count then
		error(`RoundRules.nextPhase: bad question index {questionIndex}`, 2)
	end
	if phase == "Intermission" then
		if questionIndex ~= 0 then
			error(`RoundRules.nextPhase: Intermission needs index 0, got {questionIndex}`, 2)
		end
		return "Question", questionSeconds(1)
	elseif phase == "Question" then
		if questionIndex < 1 then
			error(`RoundRules.nextPhase: Question needs index 1..{count}, got {questionIndex}`, 2)
		end
		return "Reveal", RoundConfig.RevealSeconds
	elseif phase == "Reveal" then
		if questionIndex < 1 then
			error(`RoundRules.nextPhase: Reveal needs index 1..{count}, got {questionIndex}`, 2)
		end
		if questionIndex >= count then
			return "Results", RoundConfig.ResultsSeconds
		end
		return "Question", questionSeconds(questionIndex + 1)
	elseif phase == "Results" then
		if questionIndex ~= count then
			error(`RoundRules.nextPhase: Results needs index {count}, got {questionIndex}`, 2)
		end
		return "Intermission", RoundConfig.IntermissionSeconds
	end
	error(`RoundRules.nextPhase: unknown phase {phase}`, 2)
end

return table.freeze(RoundRules)
