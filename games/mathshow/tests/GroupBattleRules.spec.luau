--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.GroupBattleRules)

local function sub(id: string, correct: boolean, at: number, order: number): Rules.Submission
	return { playerId = id, correct = correct, acceptedAt = at, order = order }
end

local function resolve(deadline: number, subs: { Rules.Submission }): Rules.QuestionResult
	return Rules.resolveQuestion({ deadline = deadline, submissions = subs })
end

return function(t: TestRunner.T)
	t.test("closingDeadline is the earlier of the original and first-correct + closing", function()
		t.eq(Rules.closingDeadline(30, 10, 3), 13)
		t.eq(Rules.closingDeadline(30, 29, 3), 30)
		t.eq(Rules.closingDeadline(30, 30, 3), 30)
	end)

	t.test("first correct scores 150, later correct 100, wrong 0", function()
		local r = resolve(30, { sub("a", true, 5, 1), sub("b", true, 6, 2), sub("c", false, 7, 3) })
		t.eq(r.players.a.points, 150)
		t.eq(r.players.a.isFirst, true)
		t.eq(r.players.b.points, 100)
		t.eq(r.players.b.isFirst, false)
		t.eq(r.players.c.points, 0)
		t.eq(r.players.c.correct, false)
		t.eq(r.firstCorrectPlayer, "a")
		t.eq(r.closingDeadline, 8)
	end)

	t.test("answers after the closing deadline are invalid", function()
		local r = resolve(30, { sub("a", true, 5, 1), sub("b", true, 8, 2), sub("c", true, 8.001, 3) })
		t.eq(r.players.b.points, 100, "exactly at the closing deadline still counts")
		t.eq(r.players.c.points, 0)
		t.eq(r.players.c.valid, false)
	end)

	t.test("a late first-correct never extends the question", function()
		local r = resolve(30, { sub("a", true, 29, 1), sub("b", true, 31, 2) })
		t.eq(r.closingDeadline, 30)
		t.eq(r.players.b.points, 0)
	end)

	t.test("correct answers after the original deadline are not first and score 0", function()
		local r = resolve(30, { sub("a", true, 31, 1) })
		t.eq(r.firstCorrectPlayer, nil)
		t.eq(r.closingDeadline, nil)
		t.eq(r.players.a.points, 0)
		t.eq(r.players.a.valid, false)
	end)

	t.test("nobody correct: original deadline stands, no countdown", function()
		local r = resolve(30, { sub("a", false, 5, 1), sub("b", false, 29, 2) })
		t.eq(r.closingDeadline, nil)
		t.eq(r.firstCorrectPlayer, nil)
		t.eq(r.players.b.valid, true)
		t.eq(r.players.b.points, 0)
	end)

	t.test("only the first submission per player counts", function()
		local r = resolve(30, { sub("a", false, 5, 1), sub("a", true, 6, 2), sub("b", true, 7, 3) })
		t.eq(r.players.a.points, 0)
		t.eq(r.players.b.isFirst, true)
		t.eq(r.players.b.points, 150)
		-- the order of the list does not matter, `order` does
		local r2 = resolve(30, { sub("a", true, 6, 2), sub("a", false, 5, 1) })
		t.eq(r2.players.a.points, 0)
	end)

	t.test("simultaneous acceptedAt is resolved by order, not player id", function()
		local r = resolve(30, { sub("a", true, 5, 2), sub("z", true, 5, 1) })
		t.eq(r.firstCorrectPlayer, "z")
		t.eq(r.players.z.points, 150)
		t.eq(r.players.a.points, 100)
	end)

	t.test("no submissions resolve to an empty result", function()
		local r = resolve(30, {})
		t.eq(r.firstCorrectPlayer, nil)
		t.eq(next(r.players), nil)
	end)

	t.test("NaN times and orders never score", function()
		local nan = 0 / 0
		local r = resolve(30, { sub("a", true, nan, 1), sub("b", true, 5, nan), sub("c", true, 6, 2) })
		t.eq(r.players.a.points, 0)
		t.eq(r.players.b, nil)
		t.eq(r.firstCorrectPlayer, "c")
	end)

	t.test("allCommitted ignores disconnected and ineligible entries", function()
		local roster: { Rules.RosterEntry } = {
			{ playerId = "a", connected = true, eligible = true },
			{ playerId = "b", connected = true, eligible = true },
			{ playerId = "c", connected = false, eligible = true },
			{ playerId = "d", connected = true, eligible = false },
		}
		t.eq(Rules.allCommitted(roster, { sub("a", true, 1, 1) }), false)
		t.eq(Rules.allCommitted(roster, { sub("a", true, 1, 1), sub("b", false, 2, 2) }), true)
		t.eq(Rules.allCommitted({}, {}), true)
	end)

	t.test("standings use competition ranking and never tie-break by player id", function()
		local s = Rules.standings({
			{ playerId = "z", points = 300, firstCorrects = 1, seat = 3 },
			{ playerId = "a", points = 300, firstCorrects = 1, seat = 1 },
			{ playerId = "m", points = 500, firstCorrects = 2, seat = 2 },
			{ playerId = "k", points = 100, firstCorrects = 0, seat = 4 },
		})
		t.eq(s[1].playerId, "m")
		t.eq(s[1].placement, 1)
		t.eq(s[2].playerId, "a", "display order for ties follows seat")
		t.eq(s[2].placement, 2)
		t.eq(s[3].playerId, "z")
		t.eq(s[3].placement, 2)
		t.eq(s[4].placement, 4)
	end)

	t.test("first-correct count separates equal points", function()
		local s = Rules.standings({
			{ playerId = "a", points = 300, firstCorrects = 0, seat = 1 },
			{ playerId = "b", points = 300, firstCorrects = 2, seat = 2 },
		})
		t.eq(s[1].playerId, "b")
		t.eq(s[1].placement, 1)
		t.eq(s[2].placement, 2)
	end)

	t.test("three-way tie shares first and the next placement is 4", function()
		local s = Rules.standings({
			{ playerId = "a", points = 100, firstCorrects = 0, seat = 1 },
			{ playerId = "b", points = 100, firstCorrects = 0, seat = 2 },
			{ playerId = "c", points = 100, firstCorrects = 0, seat = 3 },
			{ playerId = "d", points = 0, firstCorrects = 0, seat = 4 },
		})
		t.eq(s[3].placement, 1)
		t.eq(s[4].placement, 4)
		t.eq(#Rules.standings({}), 0)
	end)
end
