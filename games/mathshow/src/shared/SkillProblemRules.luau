--!strict
-- Pure Skill Test problem generation (TASK-0102): one generator per rank 0..9, deterministic from (rank, seed). Every
-- answer is an integer within +-1e6; typed ranks (0-4) never have a negative answer (the input takes digits only). Text is
-- ASCII plus the superscripts and the degree sign (all render in Merriweather, the glyph sheet of TASK-0098), at most
-- MAX_TEXT characters. Choice ranks (5-9) carry four distinct choices, the correct one at `correctIndex`.

local SkillRules = require(script.Parent.SkillRules)

export type Problem = {
	rank: number,
	kind: string, -- "integer" | "choice" (SkillRules.Kind)
	text: string,
	answer: number,
	choices: { string }?,
	correctIndex: number?,
}

local MAX_TEXT = 30
local SUPER = { [2] = "\u{00B2}", [3] = "\u{00B3}" }

local SkillProblemRules = {}

SkillProblemRules.MaxText = MAX_TEXT

local function pow(base: number, exponent: number): number
	local out = 1
	for _ = 1, exponent do
		out *= base
	end
	return out
end

local TRIPLES: { { number } } =
	{ { 3, 4, 5 }, { 5, 12, 13 }, { 6, 8, 10 }, { 8, 15, 17 }, { 9, 12, 15 }, { 12, 16, 20 } }
local TRIG_NAMES: { string } =
	{ "sin(30\u{00B0})", "cos(60\u{00B0})", "tan(45\u{00B0})", "sin(90\u{00B0})", "cos(0\u{00B0})" }
-- sin 30 and cos 60 are 1/2; the other three are 1
local TRIG_HALF: { boolean } = { true, true, false, false, false }

-- rank -> (text, answer). `n` is the rng.
local GENERATORS: { [number]: (rng: Random) -> (string, number) } = {
	[0] = function(rng)
		local a, b = rng:NextInteger(10, 60), rng:NextInteger(10, 60)
		return `{a} + {b} = ?`, a + b
	end,
	[1] = function(rng)
		local a, b, c = rng:NextInteger(2, 9), rng:NextInteger(2, 9), rng:NextInteger(2, 9)
		return `{a} + {b} \u{00D7} {c} = ?`, a + b * c
	end,
	[2] = function(rng)
		local x, a, b = rng:NextInteger(2, 12), rng:NextInteger(2, 9), rng:NextInteger(1, 20)
		return `{a}x + {b} = {a * x + b}, x = ?`, x
	end,
	[3] = function(rng)
		local t = TRIPLES[rng:NextInteger(1, #TRIPLES)]
		if rng:NextInteger(1, 2) == 1 then
			return `Hypotenuse: legs {t[1]}, {t[2]} = ?`, t[3]
		end
		local w, h = rng:NextInteger(3, 15), rng:NextInteger(3, 15)
		return `Rect {w} by {h}: area = ?`, w * h
	end,
	[4] = function(rng)
		local pick = rng:NextInteger(1, #TRIG_NAMES)
		local k = rng:NextInteger(1, 10) * 2
		return `{k} \u{00D7} {TRIG_NAMES[pick]} = ?`, if TRIG_HALF[pick] then k // 2 else k
	end,
	[5] = function(rng)
		if rng:NextInteger(1, 2) == 1 then
			local n = rng:NextInteger(3, 9)
			return `log2({pow(2, n)}) = ?`, n
		end
		local n = rng:NextInteger(5, 20)
		return `Sum of 1 to {n} = ?`, n * (n + 1) // 2
	end,
	[6] = function(rng)
		local n, a = rng:NextInteger(2, 3), rng:NextInteger(2, 6)
		return `d/dx (x{SUPER[n]}) at x = {a} = ?`, n * pow(a, n - 1)
	end,
	[7] = function(rng)
		local c, a = rng:NextInteger(2, 9), rng:NextInteger(2, 6)
		return `d/dx (x\u{00B3} + {c}x) at x = {a} = ?`, 3 * a * a + c
	end,
	[8] = function(rng)
		local b, k = rng:NextInteger(2, 6), rng:NextInteger(1, 4) * 2
		return `Integral 0..{b} of {k}x dx = ?`, k * b * b // 2
	end,
	[9] = function(rng)
		local a, b = rng:NextInteger(2, 6), rng:NextInteger(2, 6)
		-- both wordings have the same answer (2ab); the coin flip only varies the text
		if rng:NextInteger(1, 2) == 1 then
			return `d/dx (x\u{00B2}y) at ({a}, {b}) = ?`, 2 * a * b
		end
		return `d/dy (xy\u{00B2}) at ({a}, {b}) = ?`, 2 * a * b
	end,
}

-- Four distinct choices around the answer, shuffled by the rng; returns them as strings and the correct position.
local function choicesFor(answer: number, rng: Random): ({ string }, number)
	local pool: { number } = {}
	local seen: { [number]: boolean } = { [answer] = true }
	local function add(value: number)
		if not seen[value] and value >= 0 and #pool < 3 then
			seen[value] = true
			table.insert(pool, value)
		end
	end
	-- A window of nearby values (-6..+6) shuffled, so the answer is not always the middle of a tight cluster; then the answer
	-- doubled and +10 as fallbacks when the window is cut off at zero.
	local near: { number } = {}
	for delta = -6, 6 do
		if delta ~= 0 then
			table.insert(near, delta)
		end
	end
	for index = #near, 2, -1 do
		local swap = rng:NextInteger(1, index)
		near[index], near[swap] = near[swap], near[index]
	end
	for _, delta in near do
		add(answer + delta)
	end
	add(answer * 2)
	add(answer + 10)
	local step = 7
	while #pool < 3 do
		add(answer + step)
		step += 1
	end
	local all = { answer, pool[1], pool[2], pool[3] }
	for index = #all, 2, -1 do
		local swap = rng:NextInteger(1, index)
		all[index], all[swap] = all[swap], all[index]
	end
	local out: { string } = {}
	local correct = 1
	for position, value in all do
		out[position] = tostring(value)
		if value == answer then
			correct = position
		end
	end
	return out, correct
end

-- nil for an invalid rank. Deterministic: the same (rank, seed) always gives the same problem.
function SkillProblemRules.generate(rank: number, seed: number): Problem?
	local generator = if typeof(rank) == "number" then GENERATORS[rank] else nil
	if not generator then
		return nil
	end
	local rng = Random.new(seed)
	local text, answer = generator(rng)
	local kind = SkillRules.kindFor(rank)
	local problem: Problem = { rank = rank, kind = kind, text = text, answer = answer }
	if kind == "choice" then
		problem.choices, problem.correctIndex = choicesFor(answer, rng)
	end
	return problem
end

return SkillProblemRules
