--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local BlitzRules = require(ReplicatedStorage.Shared.BlitzRules)

local NAN = 0 / 0

return function(t: TestRunner.T)
	t.test("scoreText follows RULES_SPEC", function()
		t.eq(BlitzRules.scoreText(7), "7/10")
		t.eq(BlitzRules.scoreText(10), "10/10")
		t.eq(BlitzRules.scoreText(0), "0/10")
		t.eq(BlitzRules.scoreText(12), "10/10")
		t.eq(BlitzRules.scoreText(-1), "0/10")
		t.eq(BlitzRules.scoreText(6.9), "6/10")
		t.eq(BlitzRules.scoreText(NAN), "0/10")
		t.eq(BlitzRules.scoreText(3, 5), "3/5")
		t.eq(BlitzRules.scoreText(9, 5), "5/5")
	end)

	t.test("isNewBest: first score yes, a tie no", function()
		t.eq(BlitzRules.isNewBest(0, nil), true)
		t.eq(BlitzRules.isNewBest(7, 6), true)
		t.eq(BlitzRules.isNewBest(6, 6), false)
		t.eq(BlitzRules.isNewBest(5, 6), false)
		t.eq(BlitzRules.isNewBest(1, 0), true)
	end)

	t.test("bestText", function()
		t.eq(BlitzRules.bestText(6), "Previous best 6/10")
		t.eq(BlitzRules.bestText(nil), "First Blitz score")
		t.eq(BlitzRules.bestText(0), "Previous best 0/10")
	end)

	t.test("reviewRows: right, wrong and missing answers", function()
		local rows = BlitzRules.reviewRows({ 12, 9, false, nil, -123456 }, { 12, 10, 7, 5, -123456 })
		t.eq(#rows, 5)
		t.eq(rows[1].q, "Q1")
		t.eq(rows[1].you, "12")
		t.eq(rows[1].ok, true)
		t.eq(rows[2].you, "9")
		t.eq(rows[2].ans, "10")
		t.eq(rows[2].ok, false)
		t.eq(rows[3].you, "\u{2014}")
		t.eq(rows[3].ok, false)
		t.eq(rows[4].you, "\u{2014}")
		t.eq(rows[5].ok, true)
		t.eq(rows[5].ans, "-123456")
	end)

	t.test("reviewRows of ten", function()
		local solutions: { number } = {}
		for i = 1, 10 do
			solutions[i] = i * 3
		end
		local rows = BlitzRules.reviewRows({}, solutions)
		t.eq(#rows, 10)
		t.eq(rows[10].q, "Q10")
		for _, row in rows do
			t.eq(row.ok, false)
		end
	end)

	t.test("difficultyFor ramps over the ten questions", function()
		local seen: { [number]: boolean } = {}
		for i = 1, 10 do
			local d = BlitzRules.difficultyFor(i)
			t.truthy(d >= 1 and d <= 3)
			seen[d] = true
		end
		t.eq(seen[1] and seen[2] and seen[3], true)
		t.eq(BlitzRules.difficultyFor(1), 1)
		t.eq(BlitzRules.difficultyFor(10), 3)
	end)

	t.test("parseAnswerPayload is exact", function()
		local i, a = BlitzRules.parseAnswerPayload({ questionIndex = 4, answer = 56 })
		t.eq(i, 4)
		t.eq(a, 56)
		t.eq(select(1, BlitzRules.parseAnswerPayload({ questionIndex = 10, answer = -5 })), 10)
		local bads: { any } = {
			{ questionIndex = 0, answer = 1 },
			{ questionIndex = 11, answer = 1 },
			{ questionIndex = 1.5, answer = 1 },
			{ questionIndex = 1, answer = 1.5 },
			{ questionIndex = 1, answer = 1e6 + 1 },
			{ questionIndex = 1, answer = "1" },
			{ questionIndex = 1 },
			{ questionIndex = 1, answer = 1, rank = 9 },
			{ questionIndex = NAN, answer = 1 },
			{ questionIndex = 1, answer = NAN },
		}
		for _, bad in bads do
			t.eq(BlitzRules.parseAnswerPayload(bad), nil)
		end
		t.eq(BlitzRules.parseAnswerPayload(nil), nil)
		t.eq(BlitzRules.parseAnswerPayload("x"), nil)
	end)

	t.test("validStart accepts nothing or an empty table", function()
		t.eq(BlitzRules.validStart(nil), true)
		t.eq(BlitzRules.validStart({}), true)
		t.eq(BlitzRules.validStart({ x = 1 }), false)
		t.eq(BlitzRules.validStart(5), false)
	end)
end
