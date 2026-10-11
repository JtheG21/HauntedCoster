--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ResultRules = require(ReplicatedStorage.Shared.ResultRules)

return function(t: TestRunner.T)
	local center = Vector3.new(120, 0, -100)

	t.test("ring-out below the deck, outside the radius, or on a NaN position", function()
		t.eq(ResultRules.isRingOut(Vector3.new(120, 63, -100), center, 60, 20, 70), false)
		t.eq(ResultRules.isRingOut(Vector3.new(120, 41, -100), center, 60, 20, 70), false)
		t.eq(ResultRules.isRingOut(Vector3.new(120, 39, -100), center, 60, 20, 70), true)
		t.eq(ResultRules.isRingOut(Vector3.new(200, 80, -100), center, 60, 20, 70), true)
		local nan = 0 / 0
		t.eq(ResultRules.isRingOut(Vector3.new(nan, 63, -100), center, 60, 20, 70), true)
	end)

	t.test("finale ends at one player left, nobody left, or the time limit", function()
		t.eq(ResultRules.finaleOver(3, 2, 5, 60), false)
		t.eq(ResultRules.finaleOver(3, 1, 5, 60), true)
		t.eq(ResultRules.finaleOver(2, 0, 5, 60), true)
		t.eq(ResultRules.finaleOver(3, 3, 60, 60), true)
	end)

	t.test("a solo finale runs until the player is out", function()
		t.eq(ResultRules.finaleOver(1, 1, 5, 60), false)
		t.eq(ResultRules.finaleOver(1, 0, 5, 60), true)
	end)

	t.test("the last player standing wins combat", function()
		local r = ResultRules.combat({ 7 }, { 3 }, 2)
		t.eq(r.winner, 7)
		t.eq(#r.draw, 0)
	end)

	t.test("a simultaneous last elimination is a draw", function()
		local r = ResultRules.combat({}, { 9, 4 }, 2)
		t.eq(r.winner, nil)
		t.eq(#r.draw, 2)
		t.eq(r.draw[1], 4) -- sorted, so the result never depends on table order
		t.eq(r.draw[2], 9)
	end)

	t.test("several survivors at the time limit share a draw", function()
		local r = ResultRules.combat({ 5, 2, 8 }, {}, 3)
		t.eq(r.winner, nil)
		t.eq(table.concat(r.draw, ","), "2,5,8")
	end)

	t.test("a solo player who falls wins nothing", function()
		local r = ResultRules.combat({}, { 1 }, 1)
		t.eq(r.winner, nil)
		t.eq(#r.draw, 0)
	end)

	t.test("in a multi-player finale a single last-out player never yields 'nobody' (audit F1)", function()
		local r = ResultRules.combat({}, { 6 }, 2)
		t.eq(r.winner, 6)
		t.eq(#r.draw, 0)
	end)

	t.test("speed is the first finisher", function()
		t.eq(ResultRules.speed({ 4, 2 }), 4)
		t.eq(ResultRules.speed({}), nil)
	end)

	t.test("teamwork is the most contributions", function()
		t.eq(ResultRules.teamwork({ [1] = 2, [2] = 5, [3] = 1 }, {}), 2)
	end)

	t.test("teamwork ties go to the earlier finisher, then the lower UserId", function()
		t.eq(ResultRules.teamwork({ [10] = 3, [20] = 3 }, { 20, 10 }), 20)
		t.eq(ResultRules.teamwork({ [10] = 3, [20] = 3 }, { 10 }), 10)
		t.eq(ResultRules.teamwork({ [30] = 3, [20] = 3 }, {}), 20)
	end)

	t.test("nobody wins teamwork with zero contributions", function()
		t.eq(ResultRules.teamwork({ [1] = 0 }, { 1 }), nil)
		t.eq(ResultRules.teamwork({}, {}), nil)
	end)
end
