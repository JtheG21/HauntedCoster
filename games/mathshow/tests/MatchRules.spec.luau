--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchRules = require(ReplicatedStorage.Shared.MatchRules)

local NAN = 0 / 0

return function(t: TestRunner.T)
	t.test("vsResult compares points and a forfeit beats everything", function()
		t.eq(MatchRules.vsResult(500, 300, false), "win")
		t.eq(MatchRules.vsResult(300, 500, false), "lose")
		t.eq(MatchRules.vsResult(400, 400, false), "draw")
		t.eq(MatchRules.vsResult(0, 0, false), "draw")
		t.eq(MatchRules.vsResult(0, 900, true), "forfeit")
		t.eq(MatchRules.vsResult(900, 0, true), "forfeit")
	end)

	t.test("vsResult survives bad numbers", function()
		t.eq(MatchRules.vsResult(NAN, 5, false), "lose")
		t.eq(MatchRules.vsResult(-5, 0, false), "draw")
		t.eq(MatchRules.vsResult(10.9, 10, false), "draw", "points are whole numbers")
		t.eq(MatchRules.vsResult("9" :: any, 8, false), "lose")
	end)

	t.test("headToHeadPct follows RULES_SPEC", function()
		t.eq(MatchRules.headToHeadPct(362, 540), 40)
		t.eq(MatchRules.headToHeadPct(0, 0), 50)
		t.eq(MatchRules.headToHeadPct(100, 0), 100)
		t.eq(MatchRules.headToHeadPct(0, 100), 0)
		t.eq(MatchRules.headToHeadPct(1, 1), 50)
		t.eq(MatchRules.headToHeadPct(1, 2), 33)
		t.eq(MatchRules.headToHeadPct(NAN, NAN), 50)
	end)

	t.test("searchPhase", function()
		t.eq(MatchRules.searchPhase(0, 60), "searching")
		t.eq(MatchRules.searchPhase(59.9, 60), "searching")
		t.eq(MatchRules.searchPhase(60, 60), "timeout")
		t.eq(MatchRules.searchPhase(120, 60), "timeout")
		t.eq(MatchRules.searchPhase(NAN, 60), "searching")
	end)
end
