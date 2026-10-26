--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Shared.HudConfig)
local HudRules = require(ReplicatedStorage.Shared.HudRules)
local ProblemConfig = require(ReplicatedStorage.Shared.ProblemConfig)
local RoundConfig = require(ReplicatedStorage.Shared.RoundConfig)

local NAN = 0 / 0
local INF = math.huge

return function(t: TestRunner.T)
	t.test("sanitizeInput keeps ASCII digits only", function()
		t.eq(HudRules.sanitizeInput("12ab 3 "), "123")
		t.eq(HudRules.sanitizeInput("abc"), "")
		t.eq(HudRules.sanitizeInput(""), "")
		t.eq(HudRules.sanitizeInput("-5.5"), "55")
	end)

	t.test("sanitizeInput drops unicode digits", function()
		t.eq(HudRules.sanitizeInput("１２３"), "") -- fullwidth
		t.eq(HudRules.sanitizeInput("٣4"), "4") -- arabic-indic then ASCII
	end)

	t.test("sanitizeInput caps at six digits", function()
		t.eq(HudRules.sanitizeInput("123456"), "123456")
		t.eq(HudRules.sanitizeInput("1234567"), "123456")
		t.eq(HudRules.sanitizeInput("a1b2c3d4e5f6g7h8"), "123456")
	end)

	t.test("sanitizeInput tolerates non-strings", function()
		t.eq(HudRules.sanitizeInput(nil), "")
		t.eq(HudRules.sanitizeInput(42), "")
		t.eq(HudRules.sanitizeInput({}), "")
	end)

	t.test("secondsLeft clamps at zero and rejects bad numbers", function()
		t.eq(HudRules.secondsLeft(110, 100), 10)
		t.eq(HudRules.secondsLeft(100, 100), 0)
		t.eq(HudRules.secondsLeft(100, 105), 0)
		t.eq(HudRules.secondsLeft(NAN, 100), 0)
		t.eq(HudRules.secondsLeft(INF, 100), 0)
		t.eq(HudRules.secondsLeft(100, NAN), 0)
		t.eq(HudRules.secondsLeft("x", 100), 0)
	end)

	t.test("timerFraction stays within 0..1", function()
		t.eq(HudRules.timerFraction(115, 100, 15), 1) -- exactly total
		t.eq(HudRules.timerFraction(120, 100, 15), 1) -- more than total left
		t.eq(HudRules.timerFraction(107.5, 100, 15), 0.5)
		t.eq(HudRules.timerFraction(100, 100, 15), 0)
		t.eq(HudRules.timerFraction(90, 100, 15), 0) -- past the end
	end)

	t.test("timerFraction is 0 for bad totals and times", function()
		t.eq(HudRules.timerFraction(110, 100, 0), 0)
		t.eq(HudRules.timerFraction(110, 100, -5), 0)
		t.eq(HudRules.timerFraction(110, 100, NAN), 0)
		t.eq(HudRules.timerFraction(110, 100, INF), 0)
		t.eq(HudRules.timerFraction(NAN, 100, 15), 0)
	end)

	t.test("phaseSeconds follows the round config", function()
		t.eq(HudRules.phaseSeconds("Intermission", 0), RoundConfig.IntermissionSeconds)
		t.eq(HudRules.phaseSeconds("Reveal", 3), RoundConfig.RevealSeconds)
		for index, difficulty in RoundConfig.DifficultyByQuestion do
			t.eq(
				HudRules.phaseSeconds("Question", index),
				ProblemConfig.Tiers[difficulty].timeLimit,
				`question {index}`
			)
		end
	end)

	t.test("phaseSeconds is nil outside its contract", function()
		t.eq(HudRules.phaseSeconds("Question", 0), nil)
		t.eq(HudRules.phaseSeconds("Question", RoundConfig.QuestionCount + 1), nil)
		t.eq(HudRules.phaseSeconds("Question", 1.5), nil)
		t.eq(HudRules.phaseSeconds("Question", NAN), nil)
		t.eq(HudRules.phaseSeconds("Question", nil), nil)
		t.eq(HudRules.phaseSeconds("Results", 6), nil)
		t.eq(HudRules.phaseSeconds("Nope", 1), nil)
	end)

	t.test("canSubmit needs Question, an unsent index and a parseable answer", function()
		t.truthy(HudRules.canSubmit("Question", 2, 1, "42"))
		t.truthy(HudRules.canSubmit("Question", 1, 0, " 7 "))
		t.eq(HudRules.canSubmit("Reveal", 2, 1, "42"), false)
		t.eq(HudRules.canSubmit("Intermission", 0, 0, "42"), false)
		t.eq(HudRules.canSubmit("Question", 2, 2, "42"), false) -- already sent this question
		t.eq(HudRules.canSubmit("Question", 2, 1, ""), false)
		t.eq(HudRules.canSubmit("Question", 2, 1, "abc"), false)
		t.eq(HudRules.canSubmit("Question", 2, 1, "1234567"), false)
		t.eq(HudRules.canSubmit("Question", 2, 1, nil), false)
	end)

	t.test("canSubmit has no clock input", function()
		-- The server accepts answers LateGraceSeconds past endsAt, so a Question state is enough.
		t.truthy(HudRules.canSubmit("Question", 3, 2, "9"))
	end)

	t.test("feedbackFor maps each reply", function()
		local kind, text = HudRules.feedbackFor({ accepted = true, correct = true, points = 150 })
		t.eq(kind, "correct")
		t.eq(text, "Correct! +150")
		kind, text = HudRules.feedbackFor({ accepted = true, correct = false, points = 0 })
		t.eq(kind, "incorrect")
		t.eq(text, HudConfig.Strings.Incorrect)
		kind, text = HudRules.feedbackFor({ accepted = false })
		t.eq(kind, "notCounted")
		t.eq(text, HudConfig.Strings.NotCounted)
	end)

	t.test("feedbackFor survives malformed replies", function()
		t.eq((HudRules.feedbackFor({})), "notCounted")
		t.eq((HudRules.feedbackFor(nil)), "notCounted")
		t.eq((HudRules.feedbackFor("x")), "notCounted")
		t.eq((HudRules.feedbackFor({ accepted = "yes" })), "notCounted")
		local kind, text = HudRules.feedbackFor({ accepted = true, correct = true })
		t.eq(kind, "correct")
		t.eq(text, HudConfig.Strings.CorrectPlain)
	end)

	t.test("visibility per phase", function()
		local q = HudRules.visibility("Question")
		t.truthy(q.question and q.timer and q.input)
		for _, phase in { "Intermission", "Reveal" } do
			local v = HudRules.visibility(phase)
			t.truthy(v.question and v.timer, phase)
			t.eq(v.input, false, phase)
		end
		for _, phase in { "Question", "Intermission", "Reveal", "Bogus", "" } do
			t.eq(HudRules.visibility(phase).results, false, phase)
		end
		local results = HudRules.visibility("Results")
		t.truthy(results.results)
		t.eq(results.question or results.timer or results.input, false)
		for _, phase in { "Bogus", "" } do
			local v = HudRules.visibility(phase)
			t.eq(v.question or v.timer or v.input or v.results, false)
		end
		local none = HudRules.visibility(nil)
		t.eq(none.question or none.timer or none.input or none.results, false)
	end)

	t.test("solversLabel lists who got it", function()
		local S = HudConfig.Strings
		t.eq(HudRules.solversLabel({}), S.NobodyGotIt)
		t.eq(HudRules.solversLabel({ { userId = 1, name = "Ann", points = 186 } }), "Got it: Ann +186")
		t.eq(
			HudRules.solversLabel({
				{ userId = 1, name = "Ann", points = 186 },
				{ userId = 2, name = "Bo", points = 150 },
			}),
			"Got it: Ann +186, Bo +150"
		)
	end)

	t.test("solversLabel caps names and counts the rest", function()
		local list = {}
		for i = 1, HudConfig.MaxSolverNames + 2 do
			table.insert(list, { userId = i, name = `P{i}`, points = 100 - i })
		end
		t.eq(HudRules.solversLabel(list), "Got it: P1 +99, P2 +98, P3 +97 +2 more")
	end)

	t.test("solversLabel is empty for malformed lists", function()
		t.eq(HudRules.solversLabel(nil), "")
		t.eq(HudRules.solversLabel("x"), "")
		t.eq(HudRules.solversLabel({ { userId = 1, name = "A", points = -5 } }), "")
		t.eq(
			HudRules.solversLabel({ { userId = 1, name = "A", points = 5 }, { userId = 1, name = "B", points = 4 } }),
			""
		)
	end)

	t.test("questionLabel per phase", function()
		local S = HudConfig.Strings
		t.eq(
			HudRules.questionLabel(
				"Question",
				{ phase = "Question", endsAt = 5, questionIndex = 1, problemText = "3 + 4" }
			),
			"3 + 4 = ?"
		)
		t.eq(
			HudRules.questionLabel(
				"Reveal",
				{ phase = "Reveal", endsAt = 5, questionIndex = 1, problemText = "3 + 4", answer = 7 }
			),
			"3 + 4 = 7"
		)
		t.eq(HudRules.questionLabel("Question", { phase = "Question", endsAt = 5, questionIndex = 1 }), "")
		t.eq(
			HudRules.questionLabel("Intermission", { phase = "Intermission", endsAt = 0, questionIndex = 0 }),
			S.WaitingForPlayers
		)
		t.eq(
			HudRules.questionLabel("Intermission", { phase = "Intermission", endsAt = 50, questionIndex = 0 }),
			S.GetReady
		)
		t.eq(HudRules.questionLabel("Results", { phase = "Results", endsAt = 5, questionIndex = 6 }), "")
	end)

	t.test("questionLabel never shows an answer before Reveal", function()
		local label = HudRules.questionLabel(
			"Question",
			{ phase = "Question", endsAt = 5, questionIndex = 1, problemText = "3 + 4", answer = 7 }
		)
		t.eq(label, "3 + 4 = ?")
	end)

	t.test("isValidState checks shape", function()
		t.truthy(HudRules.isValidState({ phase = "Question", endsAt = 10.5, questionIndex = 1, problemText = "1 + 1" }))
		t.truthy(HudRules.isValidState({ phase = "Results", endsAt = 0, questionIndex = 6, scores = {} }))
		t.eq(HudRules.isValidState(nil), false)
		t.eq(HudRules.isValidState("Question"), false)
		t.eq(HudRules.isValidState({ endsAt = 1, questionIndex = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Bogus", endsAt = 1, questionIndex = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Question", questionIndex = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Question", endsAt = "1", questionIndex = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Question", endsAt = NAN, questionIndex = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Question", endsAt = 1 }), false)
		t.eq(HudRules.isValidState({ phase = "Question", endsAt = 1, questionIndex = 1, problemText = 5 }), false)
		t.eq(HudRules.isValidState({ phase = "Reveal", endsAt = 1, questionIndex = 1, answer = "7" }), false)
	end)

	t.test("isValidResult checks shape", function()
		t.truthy(HudRules.isValidResult({ accepted = false }))
		t.truthy(HudRules.isValidResult({ accepted = true, correct = true, points = 120 }))
		t.eq(HudRules.isValidResult(nil), false)
		t.eq(HudRules.isValidResult({}), false)
		t.eq(HudRules.isValidResult({ accepted = 1 }), false)
		t.eq(HudRules.isValidResult({ accepted = true, correct = "yes" }), false)
		t.eq(HudRules.isValidResult({ accepted = true, correct = true, points = NAN }), false)
		t.eq(HudRules.isValidResult({ accepted = true, correct = true, points = "5" }), false)
	end)
end
