--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RateRules = require(ReplicatedStorage.Shared.RateRules)

return function(t: TestRunner.T)
	t.test("allows up to maxCount calls per window, then refuses", function()
		local stamps: { number } = {}
		local ok: boolean
		for i = 1, 5 do
			stamps, ok = RateRules.allow(stamps, 100 + i * 0.1, 5, 30)
			t.eq(ok, true, "call " .. i)
		end
		stamps, ok = RateRules.allow(stamps, 101, 5, 30)
		t.eq(ok, false)
		t.eq(#stamps, 5, "a refused call is not recorded")
	end)

	t.test("calls expire after the window", function()
		local stamps, ok = RateRules.allow({ 100 }, 100.99, 1, 1)
		t.eq(ok, false, "just inside the window")
		stamps, ok = RateRules.allow({ 100 }, 101, 1, 1)
		t.eq(ok, true, "a call exactly one window old has expired")
		t.eq(#stamps, 1)
	end)

	t.test("does not mutate its input and survives bad data", function()
		local input = { 1, 2 }
		RateRules.allow(input, 3, 5, 30)
		t.eq(#input, 2)
		local _, ok = RateRules.allow(input, 0 / 0, 5, 30)
		t.eq(ok, false)
		local kept = RateRules.allow({ "x" :: any, 0 / 0, 500 }, 10, 2, 30)
		t.eq(#kept, 1, "garbage and future stamps are dropped, the new call is kept")
	end)

	t.test("zero maxCount never allows", function()
		local _, ok = RateRules.allow({}, 1, 0, 10)
		t.eq(ok, false)
	end)
end
