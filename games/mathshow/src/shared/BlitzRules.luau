--!strict
-- Pure Blitz rules (TASK-0103, RULES_SPEC): the score text, personal best, review rows, which difficulty a question uses,
-- and strict validation of what the client sends. No Instances, no clock. Nothing here throws on bad input.

local MenuConfig = require(script.Parent.MenuConfig)
local MenuCopy = require(script.Parent.MenuCopy)

export type Row = { q: string, you: string, ans: string, ok: boolean }

local ANSWER_LIMIT = 1e6

local BlitzRules = {}

local function total(): number
	return MenuConfig.BlitzTotal
end

-- "7/10": `correct` is floored and clamped to 0..total.
function BlitzRules.scoreText(correct: number, runTotal: number?): string
	local limit = runTotal or total()
	local value = if typeof(correct) == "number" and correct == correct then math.floor(correct) else 0
	value = math.clamp(value, 0, limit)
	return `{value}/{limit}`
end

-- A tie is not a new best (jg default); the first score always is.
function BlitzRules.isNewBest(score: number, previousBest: number?): boolean
	if previousBest == nil then
		return true
	end
	return score > previousBest
end

function BlitzRules.bestText(previousBest: number?): string
	if previousBest == nil then
		return MenuCopy.Blitz.FirstScore
	end
	return (string.gsub(MenuCopy.Blitz.PreviousBest, "{best}", BlitzRules.scoreText(previousBest)))
end

-- Review rows for questions 1..#solutions. `answers[i]` is the player's answer, nil or false for none.
function BlitzRules.reviewRows(answers: { any }, solutions: { number }): { Row }
	local rows: { Row } = {}
	for index = 1, #solutions do
		local answer = answers[index]
		local given = if typeof(answer) == "number" then answer else nil
		table.insert(rows, {
			q = "Q" .. index,
			you = if given ~= nil then tostring(given) else MenuCopy.Blitz.NoAnswer,
			ans = tostring(solutions[index]),
			ok = given ~= nil and given == solutions[index],
		})
	end
	return rows
end

-- The ten questions use three difficulties, ramping up (ProblemConfig tiers 1..3).
function BlitzRules.difficultyFor(questionIndex: number): number
	if questionIndex <= 3 then
		return 1
	elseif questionIndex <= 7 then
		return 2
	end
	return 3
end

-- BlitzAnswer payload: exactly { questionIndex: 1..total, answer: finite integer within +-1e6 }.
function BlitzRules.parseAnswerPayload(raw: any): (number?, number?)
	if typeof(raw) ~= "table" then
		return nil, nil
	end
	local count = 0
	for key in raw do
		if key ~= "questionIndex" and key ~= "answer" then
			return nil, nil
		end
		count += 1
	end
	if count ~= 2 then
		return nil, nil
	end
	local index, answer = raw.questionIndex, raw.answer
	if typeof(index) ~= "number" or index ~= index or index ~= math.floor(index) or index < 1 or index > total() then
		return nil, nil
	end
	if
		typeof(answer) ~= "number"
		or answer ~= answer
		or answer ~= math.floor(answer)
		or answer < -ANSWER_LIMIT
		or answer > ANSWER_LIMIT
	then
		return nil, nil
	end
	return index, answer
end

function BlitzRules.validStart(raw: any): boolean
	return raw == nil or (typeof(raw) == "table" and next(raw) == nil)
end

return BlitzRules
