--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TutorialRules = require(ReplicatedStorage.Shared.Rules.TutorialRules)

return function(t: TestRunner.T)
	local function ctx(over: { [string]: any }?): TutorialRules.Ctx
		local c: { [string]: any } = {
			nearTrain = false,
			viewedCollection = false,
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

	-- Cumulative state that satisfies steps 1..n (index n). Brief §12 has 12 steps.
	local reached: { { [string]: any } } = {
		{ nearTrain = true },
		{ inGraveyard = true },
		{ inGraveyard = true, angelClue = true, clueCount = 1 },
		{ clueCount = 1, seenCount = 1 },
		{ clueCount = 1, seenCount = 1, captureTried = true },
		{ clueCount = 1, seenCount = 1, captureTried = true, carrying = true },
		{ owned = 1 },
		{ owned = 1, viewedCollection = true },
		{ owned = 1, viewedCollection = true, speedLevel = 1 },
		{ owned = 1, speedLevel = 1, houseTier = 1, routeCustom = true },
		{ owned = 1, speedLevel = 1, houseTier = 1, routeCustom = true, rides = 1, bellHint = true },
		{ owned = 1, speedLevel = 1, houseTier = 1, routeCustom = true, rides = 1, bellHint = true, bellClue = true },
	}

	t.test("there are 12 steps, matching brief §12", function()
		t.eq(#TutorialRules.Steps, 12)
		t.eq(#reached, #TutorialRules.Steps)
	end)

	t.test("every step: stays put while its condition is false, advances one step when true", function()
		for n = 1, #TutorialRules.Steps do
			local before = if n == 1 then ctx() else ctx(reached[n - 1])
			t.eq(TutorialRules.advance(n, before), n)
			t.eq(TutorialRules.advance(n, ctx(reached[n])), n + 1)
		end
	end)

	t.test("step 1 needs the station, not a timer", function()
		t.eq(TutorialRules.advance(1, ctx({ nearTrain = false })), 1)
		t.eq(TutorialRules.advance(1, ctx({ nearTrain = true })), 2)
	end)

	t.test("step 8 completes on opening the Mansion or Journal", function()
		t.eq(TutorialRules.advance(8, ctx({ owned = 1 })), 8)
		t.eq(TutorialRules.advance(8, ctx({ owned = 1, viewedCollection = true })), 9)
	end)

	t.test("owning a monster skips the whole early tutorial", function()
		t.eq(TutorialRules.advance(1, ctx({ owned = 1 })), 8)
	end)

	t.test("buying tier 1 directly skips the collection and speed steps", function()
		t.eq(TutorialRules.advance(8, ctx({ owned = 1, houseTier = 1 })), 10)
	end)

	t.test("escape during return shows a recovery hint, not a dead end", function()
		local hint = TutorialRules.hint(7, ctx({ carrying = false }))
		t.truthy(string.find(hint, "got away", 1, true) ~= nil)
		t.eq(TutorialRules.advance(7, ctx({ carrying = false })), 7)
	end)

	t.test("resume: a saved step is kept until its condition is met, never reset", function()
		-- Rejoining at step 10 with no route yet stays on 10 (not back to 1) and shows the editor hint.
		local c = ctx({ owned = 1, houseTier = 1 })
		t.eq(TutorialRules.advance(10, c), 10)
		t.truthy(string.find(TutorialRules.hint(10, c), "Edit Track", 1, true) ~= nil)
		-- A step saved before a later state still lands on the first unmet step.
		t.eq(TutorialRules.advance(2, c), 10)
		-- A saved step beyond the end shows the completion text.
		t.eq(TutorialRules.hint(99, c), TutorialRules.CompleteText)
	end)

	t.test("completed tutorial returns the completion hint", function()
		local done = ctx({
			owned = 2,
			houseTier = 1,
			speedLevel = 1,
			routeCustom = true,
			rides = 1,
			bellClue = true,
		})
		local s = TutorialRules.advance(1, done)
		t.eq(s, #TutorialRules.Steps + 1)
		t.eq(TutorialRules.hint(s, done), TutorialRules.CompleteText)
	end)
end
