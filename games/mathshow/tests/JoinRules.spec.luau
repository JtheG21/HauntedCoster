--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local JoinRules = require(ReplicatedStorage.Shared.JoinRules)

return function(t: TestRunner.T)
	t.test("participantAt: only question 1 admits new participants", function()
		t.eq(JoinRules.participantAt(true, 1, false), true)
		t.eq(JoinRules.participantAt(false, 1, false), false)
		t.eq(JoinRules.participantAt(false, 1, true), false, "a new match starts from who is joined now")
	end)

	t.test("participantAt: a late joiner never becomes a participant mid-match", function()
		for question = 2, 6 do
			t.eq(JoinRules.participantAt(true, question, false), false, "q" .. question)
			t.eq(JoinRules.participantAt(true, question, true), true, "q" .. question)
			t.eq(
				JoinRules.participantAt(false, question, true),
				true,
				"leaving the menu state does not remove a participant"
			)
		end
	end)

	t.test("participantAt tolerates odd question indices", function()
		t.eq(JoinRules.participantAt(true, 0, false), false)
		t.eq(JoinRules.participantAt(true, -1, false), false)
		t.eq(JoinRules.participantAt(true, 7, true), true)
	end)

	t.test("isWatching: joined, not in the match, and a match is under way", function()
		for _, phase in { "Question", "Reveal", "Results" } do
			t.eq(JoinRules.isWatching(true, false, phase), true, phase)
			t.eq(JoinRules.isWatching(true, true, phase), false, phase)
			t.eq(JoinRules.isWatching(false, false, phase), false, phase)
		end
		t.eq(JoinRules.isWatching(true, false, "Intermission"), false, "the banner goes away at the next Intermission")
	end)

	t.test("validJoin accepts nothing or an empty table only", function()
		t.eq(JoinRules.validJoin(nil), true)
		t.eq(JoinRules.validJoin({}), true)
		t.eq(JoinRules.validJoin({ x = 1 }), false)
		t.eq(JoinRules.validJoin({ 1 }), false)
		t.eq(JoinRules.validJoin("join"), false)
		t.eq(JoinRules.validJoin(true), false)
		t.eq(JoinRules.validJoin(0), false)
	end)

	t.test("isValidShowState is exact", function()
		t.eq(JoinRules.isValidShowState({ joined = true, participant = false }), true)
		t.eq(JoinRules.isValidShowState({ joined = false, participant = false }), true)
		t.eq(JoinRules.isValidShowState({ joined = true }), false)
		t.eq(JoinRules.isValidShowState({ joined = true, participant = "no" }), false)
		t.eq(JoinRules.isValidShowState({ joined = true, participant = true, extra = 1 }), false)
		t.eq(JoinRules.isValidShowState(nil), false)
		t.eq(JoinRules.isValidShowState("x"), false)
	end)
end
