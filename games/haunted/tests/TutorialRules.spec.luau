--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialRules = require(ReplicatedStorage.Shared.Rules.TutorialRules)

return function(t: TestRunner.T)
	local function ctx(over: { [string]: any }?): TutorialRules.Ctx
		local c: { [string]: any } = {
			nearTrain = false,
			inGraveyard = false,
			clueCount = 0,
			angelClue = false,
			seenCount = 0,
			captureTried = false,
			carrying = false,
			owned = 0,
			speedLevel = 0,
			houseTier = 0,
			routeCustom = false,
			exhibits = 0,
			rides = 0,
			bellHint = false,
			bellClue = false,
			caughtRare = false,
		}
		for k, v in (over or {}) :: { [string]: any } do
			c[k] = v
		end
		return c :: any
	end

	t.test("fresh player starts at step 1", function()
		t.eq(TutorialRules.advance(1, ctx()), 1)
	end)

	t.test("each step advances in order", function()
		t.eq(TutorialRules.advance(1, ctx({ nearTrain = true })), 2)
		t.eq(TutorialRules.advance(2, ctx({ inGraveyard = true })), 3)
		t.eq(TutorialRules.advance(3, ctx({ angelClue = true, clueCount = 1 })), 4)
		t.eq(TutorialRules.advance(4, ctx({ clueCount = 1, seenCount = 1 })), 5)
		t.eq(TutorialRules.advance(5, ctx({ clueCount = 1, seenCount = 1, carrying = true })), 6)
	end)

	t.test("owning a monster skips the whole early tutorial", function()
		t.eq(TutorialRules.advance(1, ctx({ owned = 1 })), 7)
	end)

	t.test("buying tier 1 directly skips the speed step", function()
		t.eq(TutorialRules.advance(7, ctx({ owned = 1, houseTier = 1 })), 9)
	end)

	t.test("escape during return shows a recovery hint, not a dead end", function()
		local hint = TutorialRules.hint(6, ctx({ carrying = false }))
		t.truthy(string.find(hint, "got away", 1, true) ~= nil)
		t.eq(TutorialRules.advance(6, ctx({ carrying = false })), 6)
	end)

	t.test("late steps advance one at a time", function()
		local base = { owned = 1, clueCount = 1, seenCount = 1 }
		local function with(extra: { [string]: any }): TutorialRules.Ctx
			local c: { [string]: any } = table.clone(base)
			for k, v in extra do
				c[k] = v
			end
			return ctx(c)
		end
		t.eq(TutorialRules.advance(7, with({})), 7)
		t.eq(TutorialRules.advance(7, with({ speedLevel = 1 })), 8)
		t.eq(TutorialRules.advance(8, with({ speedLevel = 1, houseTier = 1 })), 9)
		t.eq(TutorialRules.advance(9, with({ houseTier = 1, routeCustom = true })), 10)
		t.eq(TutorialRules.advance(10, with({ houseTier = 1, routeCustom = true, exhibits = 1 })), 11)
		t.eq(TutorialRules.advance(11, with({ houseTier = 1, routeCustom = true, exhibits = 1, rides = 1 })), 12)
		t.eq(
			TutorialRules.advance(
				12,
				with({ houseTier = 1, routeCustom = true, exhibits = 1, rides = 1, bellClue = true })
			),
			13
		)
	end)

	t.test("resume: a saved step is kept until its condition is met, never reset", function()
		-- Rejoining at step 9 with no route yet stays on 9 (not back to 1) and shows the editor hint.
		local c = ctx({ owned = 1, houseTier = 1 })
		t.eq(TutorialRules.advance(9, c), 9)
		t.truthy(string.find(TutorialRules.hint(9, c), "Edit Track", 1, true) ~= nil)
		-- A saved step beyond the end shows the completion text.
		t.eq(TutorialRules.hint(99, c), TutorialRules.CompleteText)
	end)

	t.test("completed tutorial returns the completion hint", function()
		local done = ctx({
			owned = 2,
			houseTier = 1,
			speedLevel = 1,
			routeCustom = true,
			exhibits = 1,
			rides = 1,
			bellClue = true,
			caughtRare = true,
		})
		local s = TutorialRules.advance(1, done)
		t.eq(s, #TutorialRules.Steps + 1)
		t.eq(TutorialRules.hint(s, done), TutorialRules.CompleteText)
	end)
end
