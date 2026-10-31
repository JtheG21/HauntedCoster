--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProblemRules = require(ReplicatedStorage.Shared.ProblemRules)

-- The operator survives in Problem.text ("12 + 3", "12 - 3", "4 x 5", "20 / 4"); use it to tell which
-- branch generate() took without reaching into internals.
local function opOf(text: string): string
	if text:find(" %+ ") then
		return "add"
	elseif text:find(" %- ") then
		return "sub"
	elseif text:find(" x ") then
		return "mul"
	else
		return "div"
	end
end

return function(t: TestRunner.T)
	t.test("generate is deterministic for a fixed seed and difficulty", function()
		for difficulty = 1, 3 do
			for seed = 1, 20 do
				local a = ProblemRules.generate(seed, difficulty)
				local b = ProblemRules.generate(seed, difficulty)
				t.eq(a.text, b.text, "text")
				t.eq(a.answer, b.answer, "answer")
				t.eq(a.timeLimit, b.timeLimit, "timeLimit")
			end
		end
	end)

	t.test("every difficulty tier produces integer answers only", function()
		for difficulty = 1, 3 do
			for seed = 1, 200 do
				local problem = ProblemRules.generate(seed, difficulty)
				t.eq(math.floor(problem.answer), problem.answer, `tier {difficulty} seed {seed}: non-integer answer`)
			end
		end
	end)

	t.test("every difficulty tier covers add, sub, mul and div", function()
		for difficulty = 1, 3 do
			local seen = { add = false, sub = false, mul = false, div = false }
			for seed = 1, 200 do
				local problem = ProblemRules.generate(seed, difficulty)
				seen[opOf(problem.text)] = true
			end
			for op, found in seen do
				t.truthy(found, `tier {difficulty} never produced a {op} problem in 200 seeds`)
			end
		end
	end)

	t.test("subtraction never produces a negative answer", function()
		for difficulty = 1, 3 do
			for seed = 1, 200 do
				local problem = ProblemRules.generate(seed, difficulty)
				if opOf(problem.text) == "sub" then
					t.truthy(problem.answer >= 0, `tier {difficulty} seed {seed}: negative sub answer`)
				end
			end
		end
	end)

	t.test("division is always exact and matches the answer", function()
		for difficulty = 1, 3 do
			for seed = 1, 200 do
				local problem = ProblemRules.generate(seed, difficulty)
				if opOf(problem.text) == "div" then
					local dividendText, divisorText = problem.text:match("^(%d+) / (%d+)$")
					local dividend, divisor = tonumber(dividendText), tonumber(divisorText)
					t.truthy(dividend ~= nil and divisor ~= nil, "div text parses")
					t.eq((dividend :: number) % (divisor :: number), 0, "exact division")
					t.eq((dividend :: number) / (divisor :: number), problem.answer, "quotient matches answer")
				end
			end
		end
	end)

	t.test("timeLimit matches the tier and an unknown difficulty errors", function()
		t.eq(ProblemRules.generate(1, 1).timeLimit, 15, "tier 1 timeLimit")
		t.eq(ProblemRules.generate(1, 2).timeLimit, 12, "tier 2 timeLimit")
		t.eq(ProblemRules.generate(1, 3).timeLimit, 9, "tier 3 timeLimit")
		local ok = pcall(function()
			ProblemRules.generate(1, 4)
		end)
		t.truthy(not ok, "difficulty 4 should error")
	end)
end
