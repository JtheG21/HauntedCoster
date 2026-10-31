--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VsRules = require(ReplicatedStorage.Shared.VsRules)

local NAN = 0 / 0

return function(t: TestRunner.T)
	t.test("validQueueJoin accepts only { mode = vs }", function()
		t.eq(VsRules.validQueueJoin({ mode = "vs" }), true)
		t.eq(VsRules.validQueueJoin({ mode = "blitz" }), false)
		t.eq(VsRules.validQueueJoin({ mode = "group" }), false)
		t.eq(VsRules.validQueueJoin({ mode = "vs", extra = 1 }), false)
		t.eq(VsRules.validQueueJoin({}), false)
		t.eq(VsRules.validQueueJoin("vs"), false)
		t.eq(VsRules.validQueueJoin(nil), false)
	end)

	t.test("validEmpty accepts nothing or an empty table", function()
		t.eq(VsRules.validEmpty(nil), true)
		t.eq(VsRules.validEmpty({}), true)
		t.eq(VsRules.validEmpty({ a = 1 }), false)
		t.eq(VsRules.validEmpty(0), false)
	end)

	t.test("parseAnswerPayload is exact", function()
		local i, a = VsRules.parseAnswerPayload({ questionIndex = 3, answer = -5 })
		t.eq(i, 3)
		t.eq(a, -5)
		local bads: { any } = {
			{ questionIndex = 0, answer = 1 },
			{ questionIndex = 1.5, answer = 1 },
			{ questionIndex = 1, answer = 1.5 },
			{ questionIndex = 1, answer = 1e6 + 1 },
			{ questionIndex = 1, answer = "1" },
			{ questionIndex = 1 },
			{ questionIndex = 1, answer = 1, x = 1 },
			{ questionIndex = NAN, answer = 1 },
			{ questionIndex = 1, answer = NAN },
			{ questionIndex = math.huge, answer = 1 },
		}
		for _, bad in bads do
			t.eq(VsRules.parseAnswerPayload(bad), nil)
		end
		t.eq(VsRules.parseAnswerPayload(nil), nil)
		t.eq(VsRules.parseAnswerPayload("x"), nil)
	end)

	t.test("suddenWinner: the first correct answer wins", function()
		t.eq(VsRules.suddenWinner(2.5, 4), "a")
		t.eq(VsRules.suddenWinner(4, 2.5), "b")
		t.eq(VsRules.suddenWinner(1, nil), "a")
		t.eq(VsRules.suddenWinner(nil, 1), "b")
		t.eq(VsRules.suddenWinner(nil, nil), nil)
		t.eq(VsRules.suddenWinner(3, 3), nil, "an exact tie asks again")
		t.eq(VsRules.suddenWinner(0, 5), "a")
	end)

	t.test("afterTimeout gives up after VsMaxWaits waits", function()
		t.eq(VsRules.afterTimeout(1), "timeout")
		t.eq(VsRules.afterTimeout(2), "failed")
		t.eq(VsRules.afterTimeout(5), "failed")
		t.eq(VsRules.afterTimeout(0), "timeout")
	end)
end
