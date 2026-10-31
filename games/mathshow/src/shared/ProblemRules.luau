--!strict
-- Pure problem generation (games/mathshow/DESIGN.md "Rules that matter" and "Modules"). No Instances,
-- no services: generate(seed, difficulty) is deterministic so RoundService and tests agree on the
-- problem from a seed alone.

local ProblemConfig = require(script.Parent.ProblemConfig)

local ProblemRules = {}

export type Problem = {
	text: string,
	answer: number,
	timeLimit: number,
}

local OPS = { "add", "sub", "mul", "div" }

-- a - b with a >= b, so the answer is never negative (no elimination in the slice; see DESIGN.md).
local function subPair(rng: Random, lo: number, hi: number): (number, number)
	local a, b = rng:NextInteger(lo, hi), rng:NextInteger(lo, hi)
	if b > a then
		a, b = b, a
	end
	return a, b
end

function ProblemRules.generate(seed: number, difficulty: number): Problem
	local tier = ProblemConfig.Tiers[difficulty]
	if not tier then
		error(`ProblemRules.generate: unknown difficulty {difficulty}`, 2)
	end

	local rng = Random.new(seed)
	local op = OPS[rng:NextInteger(1, #OPS)]

	local text: string
	local answer: number
	if op == "add" then
		local a, b = rng:NextInteger(tier.addSubMin, tier.addSubMax), rng:NextInteger(tier.addSubMin, tier.addSubMax)
		text, answer = `{a} + {b}`, a + b
	elseif op == "sub" then
		local a, b = subPair(rng, tier.addSubMin, tier.addSubMax)
		text, answer = `{a} - {b}`, a - b
	elseif op == "mul" then
		local a, b = rng:NextInteger(tier.factorMin, tier.factorMax), rng:NextInteger(tier.factorMin, tier.factorMax)
		text, answer = `{a} x {b}`, a * b
	else -- "div": build from a*b so the division is always exact.
		local a, b = rng:NextInteger(tier.factorMin, tier.factorMax), rng:NextInteger(tier.factorMin, tier.factorMax)
		text, answer = `{a * b} / {b}`, a
	end

	return { text = text, answer = answer, timeLimit = tier.timeLimit }
end

return ProblemRules
