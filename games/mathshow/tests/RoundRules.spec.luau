--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProblemConfig = require(ReplicatedStorage.Shared.ProblemConfig)
local ProblemRules = require(ReplicatedStorage.Shared.ProblemRules)
local RoundConfig = require(ReplicatedStorage.Shared.RoundConfig)
local RoundRules = require(ReplicatedStorage.Shared.RoundRules)

type Phase = RoundRules.Phase

-- Walks one full match from Intermission back to Intermission, recording each step.
type Step = { phase: Phase, index: number, duration: number }

local function walk(): { Step }
	local steps: { Step } = {}
	local phase: Phase, index = "Intermission", 0
	repeat
		local nextPhase: Phase, duration: number = RoundRules.nextPhase(phase, index)
		if nextPhase == "Question" then
			index += 1
		end
		phase = nextPhase
		table.insert(steps, { phase = phase, index = index, duration = duration } :: Step)
	until phase == "Intermission"
	return steps
end

return function(t: TestRunner.T)
	t.test("config lists one real tier per question", function()
		t.eq(#RoundConfig.DifficultyByQuestion, RoundConfig.QuestionCount, "ramp length")
		for i, difficulty in RoundConfig.DifficultyByQuestion do
			t.truthy(ProblemConfig.Tiers[difficulty], `question {i} has no tier {difficulty}`)
		end
	end)

	t.test("full cycle runs Intermission, N x (Question, Reveal), Results, Intermission", function()
		local steps = walk()
		local count = RoundConfig.QuestionCount
		t.eq(#steps, 2 * count + 2, "step count")
		t.eq(steps[1].phase, "Question", "first step")
		for q = 1, count do
			t.eq(steps[2 * q - 1].phase, "Question", `question {q}`)
			t.eq(steps[2 * q - 1].index, q, `question {q} index`)
			t.eq(steps[2 * q].phase, "Reveal", `reveal {q}`)
			t.eq(steps[2 * q].duration, RoundConfig.RevealSeconds, `reveal {q} duration`)
		end
		t.eq(steps[2 * count + 1].phase, "Results", "results")
		t.eq(steps[2 * count + 1].duration, RoundConfig.ResultsSeconds, "results duration")
		t.eq(steps[2 * count + 2].phase, "Intermission", "back to intermission")
		t.eq(steps[2 * count + 2].duration, RoundConfig.IntermissionSeconds, "intermission duration")
	end)

	t.test("Question is left only after N questions: Results appears once, after question N", function()
		local resultsSeen = 0
		local lastQuestion = 0
		for _, step in walk() do
			if step.phase == "Question" then
				lastQuestion = step.index
			elseif step.phase == "Results" then
				resultsSeen += 1
				t.eq(lastQuestion, RoundConfig.QuestionCount, "results only after N questions")
			end
		end
		t.eq(resultsSeen, 1, "one Results per cycle")
	end)

	t.test("question durations equal the tier timeLimit that ProblemRules hands out", function()
		for _, step in walk() do
			if step.phase == "Question" then
				for seed = 1, 5 do
					local problem = ProblemRules.generate(seed, RoundRules.difficultyFor(step.index))
					t.eq(step.duration, problem.timeLimit, `question {step.index} seed {seed}`)
				end
			end
		end
	end)

	t.test("difficulty never falls as the match goes on", function()
		for i = 2, RoundConfig.QuestionCount do
			t.truthy(RoundRules.difficultyFor(i) >= RoundRules.difficultyFor(i - 1), `question {i} easier than {i - 1}`)
		end
	end)

	t.test("out-of-contract input errors", function()
		local count = RoundConfig.QuestionCount
		local bad: { { any } } = {
			{ "Bogus", 0 },
			{ "Intermission", 1 },
			{ "Question", 0 },
			{ "Reveal", 0 },
			{ "Question", count + 1 },
			{ "Results", count - 1 },
			{ "Question", 1.5 },
			{ "Question", -1 },
		}
		for _, case in bad do
			local ok = pcall(RoundRules.nextPhase :: any, case[1], case[2])
			t.eq(ok, false, `{case[1]} @ {case[2]} should error`)
		end
		t.eq(pcall(RoundRules.difficultyFor, 0), false, "difficultyFor 0")
		t.eq(pcall(RoundRules.difficultyFor, count + 1), false, "difficultyFor N+1")
	end)
end
