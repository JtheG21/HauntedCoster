--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RankRules = require(ReplicatedStorage.Shared.RankRules)

return function(t: TestRunner.T)
	t.test("tierOf returns the table for 0-9", function()
		local plastic = RankRules.tierOf(0) :: RankRules.Tier
		t.eq(plastic.name, "PLASTIC")
		t.eq(plastic.subject, "Starter")
		t.eq(plastic.badge, "rank-plastic")
		local d3 = RankRules.tierOf(8) :: RankRules.Tier
		t.eq(d3.name, "DEMON III")
		t.eq(d3.badge, "rank-demon-3")
		t.eq(d3.key, "demon")
		t.eq((RankRules.tierOf(9) :: RankRules.Tier).subject, "Calculus 3")
	end)

	t.test("tierOf rejects out-of-range, fractional and non-numbers", function()
		t.eq(RankRules.tierOf(-1), nil)
		t.eq(RankRules.tierOf(10), nil)
		t.eq(RankRules.tierOf(3.5), nil)
		t.eq(RankRules.tierOf(0 / 0), nil)
		t.eq(RankRules.tierOf(nil :: any), nil)
		t.eq(RankRules.tierOf("3" :: any), nil)
	end)

	t.test("demonPips and isDemon", function()
		for rank = 0, 5 do
			t.eq(RankRules.demonPips(rank), 0)
			t.eq(RankRules.isDemon(rank), false)
		end
		t.eq(RankRules.demonPips(6), 1)
		t.eq(RankRules.demonPips(9), 4)
		t.eq(RankRules.isDemon(6), true)
		t.eq(RankRules.isDemon(9), true)
		t.eq(RankRules.demonPips(12), 0)
		t.eq(RankRules.isDemon(10), false)
		t.eq(RankRules.isDemon(-1), false)
	end)

	t.test("ladderMark", function()
		t.eq(RankRules.ladderMark(3, 3), "current")
		t.eq(RankRules.ladderMark(0, 3), "cleared")
		t.eq(RankRules.ladderMark(4, 3), "locked")
		t.eq(RankRules.ladderMark(0, nil), "locked")
		t.eq(RankRules.ladderMark(0, 0), "current")
	end)

	t.test("resultKind", function()
		t.eq(RankRules.resultKind(nil, 2), "first")
		t.eq(RankRules.resultKind(nil, nil), "first")
		t.eq(RankRules.resultKind(2, 3), "up")
		t.eq(RankRules.resultKind(3, 3), "held")
		t.eq(RankRules.resultKind(3, 1), "held")
		t.eq(RankRules.resultKind(3, nil), "held")
	end)

	t.test("newBest never goes down", function()
		t.eq(RankRules.newBest(nil, nil), nil)
		t.eq(RankRules.newBest(nil, 2), 2)
		t.eq(RankRules.newBest(4, nil), 4)
		t.eq(RankRules.newBest(4, 2), 4)
		t.eq(RankRules.newBest(2, 4), 4)
	end)

	t.test("ladderLayout covers ranks 0-9 once, higher ranks higher", function()
		local slots = RankRules.ladderLayout()
		t.eq(#slots, 10)
		local seen: { [number]: boolean } = {}
		for _, slot in slots do
			t.eq(seen[slot.rank], nil, "rank " .. slot.rank .. " twice")
			seen[slot.rank] = true
		end
		for rank = 0, 9 do
			t.eq(seen[rank], true, "rank " .. rank)
		end
		t.eq(slots[1].rank, 4)
		t.eq(slots[5].rank, 0)
		t.eq(slots[6].rank, 9)
		t.eq(slots[10].rank, 5)
		t.eq(slots[1].column, 1)
		t.eq(slots[6].column, 2)
		t.eq(slots[10].row, 5)
	end)
end
