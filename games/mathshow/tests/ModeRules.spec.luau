--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModeRules = require(ReplicatedStorage.Shared.ModeRules)

return function(t: TestRunner.T)
	t.test("cardState with every flag on", function()
		local all = { blitz = true, vs = true, group = true }
		t.eq(ModeRules.cardState("blitz", all), "open")
		t.eq(ModeRules.cardState("vs", all), "open")
		t.eq(ModeRules.cardState("group", all), "open")
	end)

	t.test("cardState treats missing and false as locked", function()
		local flags = { vs = false }
		t.eq(ModeRules.cardState("blitz", flags), "locked")
		t.eq(ModeRules.cardState("vs", flags), "locked")
		t.eq(ModeRules.cardState("group", flags), "locked")
		t.eq(ModeRules.cardState("group", {}), "locked")
	end)

	t.test("cardState mixed flags", function()
		local flags = { blitz = true, vs = false, group = true }
		t.eq(ModeRules.cardState("blitz", flags), "open")
		t.eq(ModeRules.cardState("vs", flags), "locked")
		t.eq(ModeRules.cardState("group", flags), "open")
	end)

	t.test("cardState defaults to config: all three shows are open", function()
		t.eq(ModeRules.cardState("blitz"), "open")
		t.eq(ModeRules.cardState("vs"), "open")
		t.eq(ModeRules.cardState("group"), "open")
	end)

	t.test("secondaryState: how-to-play, practice and the skill test open, the rest locked", function()
		t.eq(ModeRules.secondaryState("howto"), "open")
		t.eq(ModeRules.secondaryState("practice"), "open")
		t.eq(ModeRules.secondaryState("skilltest"), "open")
		t.eq(ModeRules.secondaryState("leaderboard"), "locked")
		t.eq(ModeRules.secondaryState("daily"), "locked")
		t.eq(ModeRules.secondaryState("drills"), "locked")
		t.eq(ModeRules.secondaryState("leaderboard", { leaderboard = true }), "open")
	end)
end
