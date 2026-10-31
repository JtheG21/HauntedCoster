--!strict
-- Practice summary: Practice never changes competitive rank, so none of these types has a rating, rank or tier field.
-- The prototype's PracticeRules (Skill Test cooldown) is untouched. Pure.

local PracticeConfigV2 = require(script.Parent.PracticeConfigV2)

export type Answer = { skill: string, correct: boolean, seconds: number }
export type Summary = {
	total: number,
	correct: number,
	seconds: { number }, -- per question, in answer order
	missesBySkill: { [string]: number },
}
export type Weakness = { skill: string, misses: number }

local PracticeRulesV2 = {}

local function cleanSeconds(n: any): number
	if type(n) ~= "number" or n ~= n or n < 0 or n == math.huge then
		return 0
	end
	return n
end

function PracticeRulesV2.summarize(answers: { Answer }): Summary
	local s: Summary = { total = 0, correct = 0, seconds = {}, missesBySkill = {} }
	for i, a in answers do
		if i > PracticeConfigV2.Questions then
			break
		end
		s.total += 1
		s.seconds[i] = cleanSeconds(a.seconds)
		if a.correct == true then
			s.correct += 1
		else
			local skill = if type(a.skill) == "string" and a.skill ~= "" then a.skill else "unknown"
			s.missesBySkill[skill] = (s.missesBySkill[skill] or 0) + 1
		end
	end
	return s
end

-- Most misses first; equal counts ordered by skill tag so the result is stable.
function PracticeRulesV2.weaknesses(summary: Summary): { Weakness }
	local out: { Weakness } = {}
	for skill, misses in summary.missesBySkill do
		table.insert(out, { skill = skill, misses = misses })
	end
	table.sort(out, function(a, b)
		if a.misses ~= b.misses then
			return a.misses > b.misses
		end
		return a.skill < b.skill
	end)
	return out
end

-- Skill tags only (no UI strings): the weakest skills first, at most MaxSuggestions.
function PracticeRulesV2.suggestNext(summary: Summary): { string }
	local out: { string } = {}
	for _, w in PracticeRulesV2.weaknesses(summary) do
		if #out >= PracticeConfigV2.MaxSuggestions then
			break
		end
		table.insert(out, w.skill)
	end
	return out
end

return PracticeRulesV2
