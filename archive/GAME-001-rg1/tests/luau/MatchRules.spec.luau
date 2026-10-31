--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchRules = require(ReplicatedStorage.Shared.MatchRules)

return function(t: TestRunner.T)
	t.test("the happy path loop is allowed", function()
		local state = "Lobby"
		for _, nextState in { "Countdown", "Course", "Finale", "Results", "Lobby" } do
			local newState, err = MatchRules.transition(state, nextState)
			t.eq(err, nil, `{state} -> {nextState}`)
			state = newState
		end
		t.eq(state, "Lobby")
	end)

	t.test("invalid transitions are rejected and keep the state", function()
		local state, err = MatchRules.transition("Lobby", "Course")
		t.eq(state, "Lobby")
		t.eq(err, "invalid_transition")
		t.eq(select(2, MatchRules.transition("Results", "Course")), "invalid_transition")
		t.eq(select(2, MatchRules.transition("Lobby", "Lobby")), "invalid_transition")
	end)

	t.test("unknown states are rejected", function()
		t.eq(select(2, MatchRules.transition("Lobby", "Party")), "unknown_state")
		t.eq(select(2, MatchRules.transition("Nope", "Lobby")), "unknown_state")
		t.eq(MatchRules.isState(5), false)
	end)

	t.test("every in-match state can fall back to Lobby", function()
		for _, s in { "Countdown", "Course", "Finale", "Results" } do
			t.eq(MatchRules.canTransition(s, "Lobby"), true, s)
		end
	end)

	t.test("joining only before the match starts", function()
		t.eq(MatchRules.canJoinMatch("Lobby"), true)
		t.eq(MatchRules.canJoinMatch("Countdown"), true)
		t.eq(MatchRules.canJoinMatch("Course"), false)
		t.eq(MatchRules.canJoinMatch("Finale"), false)
	end)

	t.test("course end conditions", function()
		t.eq(MatchRules.courseOver(1, 2, 10, 120), false)
		t.eq(MatchRules.courseOver(2, 2, 10, 120), true)
		t.eq(MatchRules.courseOver(0, 2, 120, 120), true)
		t.eq(MatchRules.courseOver(0, 0, 0, 120), true)
	end)

	t.test("countdown needs enough players", function()
		t.eq(MatchRules.shouldCountdown(0, 1), false)
		t.eq(MatchRules.shouldCountdown(1, 1), true)
		t.eq(MatchRules.shouldCountdown(1, 2), false)
	end)
end
