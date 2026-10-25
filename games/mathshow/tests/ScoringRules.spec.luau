--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProblemConfig = require(ReplicatedStorage.Shared.ProblemConfig)
local ProblemRules = require(ReplicatedStorage.Shared.ProblemRules)
local ScoringConfig = require(ReplicatedStorage.Shared.ScoringConfig)
local ScoringRules = require(ReplicatedStorage.Shared.ScoringRules)

local NAN = 0 * math.huge

-- The largest answer ProblemRules can produce: add tops out at 2 * addSubMax, mul at factorMax squared.
-- Derived from the tiers so that raising a cap fails the digit-cap test instead of silently rejecting answers.
local function largestAnswer(): number
	local largest = 0
	for _, tier in ProblemConfig.Tiers do
		largest = math.max(largest, 2 * tier.addSubMax, tier.factorMax * tier.factorMax)
	end
	return largest
end

return function(t: TestRunner.T)
	t.test("parseAnswer accepts ASCII digits with optional surrounding spaces", function()
		local cases: { { raw: string, expected: number } } = {
			{ raw = "0", expected = 0 },
			{ raw = "7", expected = 7 },
			{ raw = "42", expected = 42 },
			{ raw = " 42", expected = 42 },
			{ raw = "42 ", expected = 42 },
			{ raw = "  42  ", expected = 42 },
			{ raw = "000123", expected = 123 },
			{ raw = "400", expected = 400 },
		}
		for _, case in cases do
			t.eq(ScoringRules.parseAnswer(case.raw), case.expected, `parseAnswer({case.raw})`)
		end
	end)

	t.test("parseAnswer rejects non-integer, signed and non-decimal text", function()
		local cases = {
			"3.5",
			"-3",
			"+3",
			"1e3",
			"0x1F",
			"inf",
			"nan",
			"1,000",
			"4 2",
			"4a",
			"a4",
			"2^3",
			"3*4",
			"1 + 1",
			"print(1)",
			"",
			"   ",
			"\t42",
			"42\n",
			"\u{FF14}\u{FF12}",
		}
		for _, raw in cases do
			t.eq(ScoringRules.parseAnswer(raw), nil, `parseAnswer({raw}) should be nil`)
		end
	end)

	t.test("parseAnswer rejects digit strings over DigitCap", function()
		t.eq(ScoringRules.parseAnswer("999999"), 999999, "6 digits at the cap")
		t.eq(ScoringRules.parseAnswer("1234567"), nil, "7 digits")
		t.eq(ScoringRules.parseAnswer("00000001"), nil, "8 digits, leading zeros included")
	end)

	t.test("parseAnswer rejects raw strings over RawLengthCap", function()
		t.eq(ScoringRules.parseAnswer(string.rep(" ", ScoringConfig.RawLengthCap - 1) .. "4"), 4, "at the raw cap")
		t.eq(ScoringRules.parseAnswer(string.rep(" ", ScoringConfig.RawLengthCap) .. "4"), nil, "one over the raw cap")
		t.eq(ScoringRules.parseAnswer(string.rep("1", 200)), nil, "very long digit string")
	end)

	t.test("parseAnswer returns nil for non-string input without erroring", function()
		t.eq(ScoringRules.parseAnswer(nil), nil, "nil")
		t.eq(ScoringRules.parseAnswer(42), nil, "number")
		t.eq(ScoringRules.parseAnswer(4.2), nil, "float")
		t.eq(ScoringRules.parseAnswer(true), nil, "boolean")
		t.eq(ScoringRules.parseAnswer({}), nil, "table")
	end)

	t.test("DigitCap covers the largest ProblemRules answer", function()
		local largest = largestAnswer()
		t.eq(largest, 400, "largest answer in ProblemConfig")
		t.truthy(#tostring(largest) <= ScoringConfig.DigitCap, "DigitCap is too small for the largest answer")
		t.eq(ScoringRules.parseAnswer(tostring(largest)), largest, "largest answer round-trips")
	end)

	t.test("every generated answer parses back to itself", function()
		for difficulty = 1, 3 do
			for seed = 1, 200 do
				local problem = ProblemRules.generate(seed, difficulty)
				t.eq(
					ScoringRules.parseAnswer(tostring(problem.answer)),
					problem.answer,
					`tier {difficulty} seed {seed}: answer {problem.answer} did not round-trip`
				)
			end
		end
	end)

	t.test("score is 0 for an incorrect or missing answer at any speed", function()
		-- Not a loop over { false, nil }: a nil in a table constructor is dropped, so nil would never run.
		local function checkWrong(correct: boolean?)
			t.eq(ScoringRules.score(correct, 0, 15), 0, `{tostring(correct)} instant`)
			t.eq(ScoringRules.score(correct, 14, 15), 0, `{tostring(correct)} near the limit`)
			t.eq(ScoringRules.score(correct, 99, 15), 0, `{tostring(correct)} after the limit`)
		end
		checkWrong(false)
		checkWrong(nil)
	end)

	t.test("a correct answer at elapsed 0 earns base plus the full speed bonus", function()
		t.eq(ScoringRules.score(true, 0, 15), ScoringConfig.BasePoints + ScoringConfig.SpeedBonusMax, "15s tier")
		t.eq(ScoringRules.score(true, 0, 9), ScoringConfig.BasePoints + ScoringConfig.SpeedBonusMax, "9s tier")
	end)

	t.test("speed bonus never increases as elapsed grows, and reaches base at timeLimit", function()
		for _, timeLimit in { 15, 12, 9 } do
			local previous = ScoringRules.score(true, 0, timeLimit)
			for step = 1, 100 do
				local current = ScoringRules.score(true, timeLimit * step / 100, timeLimit)
				t.truthy(
					current <= previous,
					`timeLimit {timeLimit} step {step}: score rose from {previous} to {current}`
				)
				previous = current
			end
			t.eq(previous, ScoringConfig.BasePoints, `timeLimit {timeLimit}: score at the limit`)
		end
	end)

	t.test("speed bonus strictly decreases across whole-second ticks", function()
		local timeLimit = 9
		for elapsed = 1, timeLimit - 1 do
			t.truthy(
				ScoringRules.score(true, elapsed, timeLimit) < ScoringRules.score(true, elapsed - 1, timeLimit),
				`elapsed {elapsed} did not score below elapsed {elapsed - 1}`
			)
		end
	end)

	t.test("a late or invalid-window correct answer keeps base points and never goes below it", function()
		local base = ScoringConfig.BasePoints
		t.eq(ScoringRules.score(true, 15, 15), base, "exactly at the limit")
		t.eq(ScoringRules.score(true, 20, 15), base, "after the limit")
		t.eq(ScoringRules.score(true, 1e9, 15), base, "far after the limit")
		t.eq(ScoringRules.score(true, 0, 0), base, "zero timeLimit")
		t.eq(ScoringRules.score(true, 0, -5), base, "negative timeLimit")
		t.eq(ScoringRules.score(true, 0, NAN), base, "NaN timeLimit")
		t.eq(ScoringRules.score(true, NAN, 15), base, "NaN elapsed")
		t.eq(ScoringRules.score(true, 0, math.huge), base, "infinite timeLimit")
	end)

	t.test("a negative elapsed clamps to the full speed bonus", function()
		t.eq(
			ScoringRules.score(true, -5, 15),
			ScoringConfig.BasePoints + ScoringConfig.SpeedBonusMax,
			"negative elapsed"
		)
	end)

	t.test("score is always a whole, non-negative, in-range number", function()
		local elapsedValues = { -10, -0.5, 0, 0.001, 3.3, 9, 15, 15.5, 1e9, math.huge, -math.huge, NAN }
		local timeLimits = { 15, 9, 0.5, 0, -1, NAN }
		local maximum = ScoringConfig.BasePoints + ScoringConfig.SpeedBonusMax
		local function checkWhole(correct: boolean?)
			for _, timeLimit in timeLimits do
				for _, elapsed in elapsedValues do
					local points = ScoringRules.score(correct, elapsed, timeLimit)
					local label = `correct {tostring(correct)} elapsed {elapsed} timeLimit {timeLimit}`
					t.eq(points == points, true, `{label}: NaN`)
					t.eq(points, math.floor(points), `{label}: not whole`)
					t.truthy(points >= 0, `{label}: negative {points}`)
					t.truthy(points <= maximum, `{label}: above maximum {points}`)
				end
			end
		end
		checkWhole(true)
		checkWhole(false)
		checkWhole(nil)
	end)
end
