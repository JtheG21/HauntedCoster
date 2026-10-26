--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HudConfig = require(ReplicatedStorage.Shared.HudConfig)
local HudCopy = require(ReplicatedStorage.Shared.HudCopy)
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

	t.test("feedbackFor maps each reply to a toast kind", function()
		local kind, points = HudRules.feedbackFor({ accepted = true, correct = true, points = 150 })
		t.eq(kind, "correct")
		t.eq(points, 150)
		kind, points = HudRules.feedbackFor({ accepted = true, correct = false, points = 0 })
		t.eq(kind, "wrong")
		t.eq(points, nil)
		kind, points = HudRules.feedbackFor({ accepted = false })
		t.eq(kind, "rejected")
		t.eq(points, nil)
	end)

	t.test("feedbackFor survives malformed replies", function()
		t.eq((HudRules.feedbackFor({})), "rejected")
		t.eq((HudRules.feedbackFor(nil)), "rejected")
		t.eq((HudRules.feedbackFor("x")), "rejected")
		t.eq((HudRules.feedbackFor({ accepted = "yes" })), "rejected")
		local kind, points = HudRules.feedbackFor({ accepted = true, correct = true })
		t.eq(kind, "correct")
		t.eq(points, nil)
	end)

	t.test("toastFor has the copy for every kind", function()
		t.eq(HudRules.toastFor("sent", nil).text, "LOCKED IN")
		t.eq(HudRules.toastFor("wrong", nil).text, "NOT QUITE")
		t.eq(HudRules.toastFor("timesup", nil).text, "TIME'S UP")
		t.eq(HudRules.toastFor("rejected", nil).text, "NOT COUNTED")
		t.eq(HudRules.toastFor("sendfail", nil).text, "DIDN'T SEND · TRY AGAIN")
		local correct = HudRules.toastFor("correct", 181)
		t.eq(correct.text, "CORRECT")
		t.eq(correct.points, "+181")
		t.eq(correct.kind, "correct")
	end)

	t.test("toastFor shows points only for a correct answer", function()
		t.eq(HudRules.toastFor("correct", nil).points, "")
		t.eq(HudRules.toastFor("correct", NAN).points, "")
		t.eq(HudRules.toastFor("correct", -5).points, "+0")
		t.eq(HudRules.toastFor("wrong", 100).points, "")
		t.eq(HudRules.toastFor("sent", 100).points, "")
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

	t.test("solversModel lists chips with points", function()
		local model = HudRules.solversModel({
			{ userId = 1, name = "Ann", points = 186 },
			{ userId = 2, name = "Bo", points = 150 },
		}, 2) :: HudRules.SolversModel
		t.eq(#model.chips, 2)
		t.eq(model.chips[1].name, "Ann")
		t.eq(model.chips[1].points, "+186")
		t.eq(model.chips[1].isYou, false)
		t.eq(model.chips[2].isYou, true)
		t.eq(model.more, "")
		t.eq(model.nobody, false)
	end)

	t.test("solversModel is nobody for an empty list", function()
		local model = HudRules.solversModel({}, 1) :: HudRules.SolversModel
		t.eq(#model.chips, 0)
		t.truthy(model.nobody)
		t.eq(model.more, "")
	end)

	t.test("solversModel caps chips and counts the rest", function()
		local max = HudConfig.MaxSolverNames
		for extra = 0, 2 do
			local list = {}
			for i = 1, max + extra do
				table.insert(list, { userId = i, name = `P{i}`, points = 100 - i })
			end
			local model = HudRules.solversModel(list, 99) :: HudRules.SolversModel
			t.eq(#model.chips, max)
			t.eq(model.more, if extra == 0 then "" else `+{extra} MORE`)
		end
	end)

	t.test("solversModel truncates long names and is nil for malformed lists", function()
		local long = string.rep("x", 25)
		local model = HudRules.solversModel({ { userId = 1, name = long, points = 5 } }, 1) :: HudRules.SolversModel
		t.eq(utf8.len(model.chips[1].name), 20)
		t.eq(HudRules.solversModel(nil, 1), nil)
		t.eq(HudRules.solversModel("x", 1), nil)
		t.eq(HudRules.solversModel({ { userId = 1, name = "A", points = -5 } }, 1), nil)
		t.eq(
			HudRules.solversModel({ { userId = 1, name = "A", points = 5 }, { userId = 1, name = "B", points = 4 } }, 1),
			nil
		)
	end)

	t.test("problemSize steps at 9, 11 and 12 characters", function()
		t.eq(HudRules.problemSize(1), 88)
		t.eq(HudRules.problemSize(9), 88)
		t.eq(HudRules.problemSize(10), 76)
		t.eq(HudRules.problemSize(11), 76)
		t.eq(HudRules.problemSize(12), 64)
		t.eq(HudRules.problemSize(40), 64)
		t.eq(HudRules.problemSize(nil), 88)
		t.eq(HudRules.problemSize(NAN), 88)
	end)

	t.test("problemChars counts characters, not bytes", function()
		t.eq(HudRules.problemChars("7 + 5", "= ?"), 9)
		t.eq(HudRules.problemChars("18 \u{00d7} 7", "= ?"), 10) -- the multiplication sign is two bytes
		t.eq(HudRules.problemChars("204 \u{00f7} 12", "= ?"), 12)
	end)

	t.test("problemModel sizes by the whole line", function()
		local function model(text: string, answer: number?)
			local phase: HudRules.Phase = if answer ~= nil then "Reveal" else "Question"
			return HudRules.problemModel(
				phase,
				{ phase = phase, endsAt = 5, questionIndex = 3, problemText = text, answer = answer }
			) :: HudRules.ProblemModel
		end
		t.eq(model("7 + 5").size, 88)
		t.eq(model("18 \u{00d7} 7").size, 76)
		t.eq(model("204 \u{00f7} 12").size, 64)
		t.eq(model("7 + 5").gap, 22)
		t.eq(model("204 \u{00f7} 12").gap, 16)
		-- A long answer can push the revealed line into a smaller size than the question had.
		t.eq(model("7 + 5").size, 88)
		t.eq(model("7 + 5", 12).size, 76)
	end)

	t.test("problemModel text per phase", function()
		local q = HudRules.problemModel(
			"Question",
			{ phase = "Question", endsAt = 5, questionIndex = 3, problemText = "3 + 4" }
		) :: HudRules.ProblemModel
		t.eq(q.lead, "3 + 4")
		t.eq(q.tail, "= ?")
		t.eq(q.tag, "Q3 \u{00b7} MEDIUM \u{00b7} 12S")
		local r = HudRules.problemModel(
			"Reveal",
			{ phase = "Reveal", endsAt = 5, questionIndex = 3, problemText = "3 + 4", answer = 7 }
		) :: HudRules.ProblemModel
		t.eq(r.tail, "= 7")
		t.eq(r.tag, HudCopy.AnswerTag)
		t.eq(HudRules.problemModel("Question", { phase = "Question", endsAt = 5, questionIndex = 1 }), nil)
		t.eq(HudRules.problemModel("Results", { phase = "Results", endsAt = 5, questionIndex = 6 }), nil)
		t.eq(HudRules.problemModel("Intermission", { phase = "Intermission", endsAt = 5, questionIndex = 0 }), nil)
	end)

	t.test("problemModel never shows an answer before Reveal", function()
		local q = HudRules.problemModel(
			"Question",
			{ phase = "Question", endsAt = 5, questionIndex = 1, problemText = "3 + 4", answer = 7 }
		) :: HudRules.ProblemModel
		t.eq(q.tail, "= ?")
	end)

	t.test("questionTag follows tier and time limit", function()
		t.eq(HudRules.questionTag(1), "Q1 \u{00b7} EASY \u{00b7} 15S")
		t.eq(HudRules.questionTag(2), "Q2 \u{00b7} EASY \u{00b7} 15S")
		t.eq(HudRules.questionTag(3), "Q3 \u{00b7} MEDIUM \u{00b7} 12S")
		t.eq(HudRules.questionTag(4), "Q4 \u{00b7} MEDIUM \u{00b7} 12S")
		t.eq(HudRules.questionTag(5), "Q5 \u{00b7} HARD \u{00b7} 9S")
		t.eq(HudRules.questionTag(6), "Q6 \u{00b7} HARD \u{00b7} 9S")
		t.eq(HudRules.questionTag(0), "")
		t.eq(HudRules.questionTag(7), "")
		t.eq(HudRules.questionTag(1.5), "")
		t.eq(HudRules.questionTag(nil), "")
	end)

	t.test("difficultyOf matches the round config", function()
		for index, difficulty in RoundConfig.DifficultyByQuestion do
			t.eq(HudRules.difficultyOf(index), difficulty)
		end
		t.eq(HudRules.difficultyOf(0), nil)
		t.eq(HudRules.difficultyOf(NAN), nil)
	end)

	t.test("intermissionMode is waiting until the server sets an end time", function()
		t.eq(HudRules.intermissionMode(0), "waiting")
		t.eq(HudRules.intermissionMode(NAN), "waiting")
		t.eq(HudRules.intermissionMode(nil), "waiting")
		t.eq(HudRules.intermissionMode(123.5), "ready")
	end)

	t.test("pipStates marks done, current and upcoming", function()
		local function join(states: { any }): string
			return table.concat(states, ",")
		end
		t.eq(join(HudRules.pipStates("Question", 1)), "current,todo,todo,todo,todo,todo")
		t.eq(join(HudRules.pipStates("Question", 3)), "done,done,current,todo,todo,todo")
		t.eq(join(HudRules.pipStates("Reveal", 3)), "done,done,done,todo,todo,todo")
		t.eq(join(HudRules.pipStates("Reveal", 6)), "done,done,done,done,done,done")
		t.eq(#HudRules.pipStates("Question", 0), RoundConfig.QuestionCount)
		t.eq(HudRules.pipStates("Question", nil)[1], "todo")
	end)

	t.test("topModel text and pips per phase", function()
		local q = HudRules.topModel("Question", 3)
		t.eq(q.label, "QUESTION 3 / 6")
		t.truthy(q.pips ~= nil)
		t.eq(HudRules.topModel("Reveal", 6).label, "QUESTION 6 / 6")
		t.eq(HudRules.topModel("Intermission", 0).label, HudCopy.TopLobby)
		t.eq(HudRules.topModel("Intermission", 0).pips, nil)
		t.eq(HudRules.topModel("Results", 6).label, HudCopy.TopResults)
		t.eq(HudRules.topModel("Results", 6).pips, nil)
		t.eq(HudRules.topModel("Bogus", 1).pips, nil)
	end)

	t.test("secondsTag and scoreTag follow the phase", function()
		t.eq(HudRules.secondsTag("Question", 2), "SEC")
		t.eq(HudRules.secondsTag("Intermission", 0), "SEC")
		t.eq(HudRules.secondsTag("Reveal", 5), "NEXT UP")
		t.eq(HudRules.secondsTag("Reveal", 6), "RESULTS")
		t.eq(HudRules.scoreTag("Results"), "NEXT MATCH")
		t.eq(HudRules.scoreTag("Question"), "SCORE")
		t.eq(HudRules.scoreTag(nil), "SCORE")
	end)

	t.test("rootScale fits the reference canvas into any viewport", function()
		t.eq(HudRules.rootScale(844, 390), 1)
		t.eq(HudRules.rootScale(1688, 780), 2)
		t.eq(HudRules.rootScale(1920, 1080), 1920 / 844) -- width limits
		t.eq(HudRules.rootScale(844, 1000), 1) -- width limits again
		t.eq(HudRules.rootScale(2000, 195), 0.5) -- height limits
		t.eq(HudRules.rootScale(0, 390), 1)
		t.eq(HudRules.rootScale(-5, 390), 1)
		t.eq(HudRules.rootScale(NAN, 390), 1)
		t.eq(HudRules.rootScale(nil, 390), 1)
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
