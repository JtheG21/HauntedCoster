--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PracticeRules = require(ReplicatedStorage.Shared.PracticeRules)

local NAN = 0 / 0

return function(t: TestRunner.T)
	t.test("remaining rounds up and never goes negative", function()
		t.eq(PracticeRules.remaining(1300, 1000), 300)
		t.eq(PracticeRules.remaining(1300, 1000.2), 300)
		t.eq(PracticeRules.remaining(1300, 1299.1), 1)
		t.eq(PracticeRules.remaining(1300, 1300), 0)
		t.eq(PracticeRules.remaining(1300, 2000), 0)
	end)

	t.test("remaining survives nil, NaN and infinity", function()
		t.eq(PracticeRules.remaining(nil, 1000), 0)
		t.eq(PracticeRules.remaining(NAN, 1000), 0)
		t.eq(PracticeRules.remaining(1300, NAN), 0)
		t.eq(PracticeRules.remaining(math.huge, 1000), 0)
	end)

	t.test("state: unavailable beats everything", function()
		t.eq(PracticeRules.state(false, 5000, 1000), "unavailable")
		t.eq(PracticeRules.state(false, nil, 1000), "unavailable")
	end)

	t.test("state: cooldown while the retake clock runs, ready after", function()
		t.eq(PracticeRules.state(true, 1300, 1000), "cooldown")
		t.eq(PracticeRules.state(true, 1300, 1299.5), "cooldown")
		t.eq(PracticeRules.state(true, 1300, 1300), "ready")
		t.eq(PracticeRules.state(true, nil, 1000), "ready")
	end)

	t.test("isFirstTest only when nothing was ever recorded", function()
		t.eq(PracticeRules.isFirstTest(nil, nil), true)
		t.eq(PracticeRules.isFirstTest(0, nil), false, "rank 0 is a real rank")
		t.eq(PracticeRules.isFirstTest(nil, 0), false)
		t.eq(PracticeRules.isFirstTest(3, 3), false)
	end)
end
