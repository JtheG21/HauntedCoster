--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureRules = require(ReplicatedStorage.Shared.Rules.CaptureRules)

return function(t: TestRunner.T)
	t.test("needle is a triangle wave", function()
		t.eq(CaptureRules.needle(0, 2), 0)
		t.eq(CaptureRules.needle(0.5, 2), 0.5)
		t.eq(CaptureRules.needle(1, 2), 1)
		t.eq(CaptureRules.needle(1.5, 2), 0.5)
		t.eq(CaptureRules.needle(2, 2), 0)
	end)

	t.test("zone center keeps the zone on the bar", function()
		local rng = Random.new(1)
		for _ = 1, 200 do
			local c = CaptureRules.zoneCenter(rng, 0.3)
			t.truthy(c - 0.15 >= 0 and c + 0.15 <= 1, "zone off bar")
		end
	end)

	t.test("judge hits inside the zone and misses outside", function()
		-- period 2: needle = t for t in [0,1]
		t.eq(CaptureRules.judge(0.5, 2, 0.5, 0.2, 0), true)
		t.eq(CaptureRules.judge(0.2, 2, 0.5, 0.2, 0), false)
		-- latency slack forgives a slightly early press
		t.eq(CaptureRules.judge(0.33, 2, 0.5, 0.2, 0.09), true)
		t.eq(CaptureRules.judge(0.3, 2, 0.5, 0.2, 0.05), false)
	end)

	t.test("release outcomes", function()
		local o, h, m = CaptureRules.applyRelease(true, 0, 0, 1, 3)
		t.eq(o, "success")
		t.eq(h, 1)
		o, h, m = CaptureRules.applyRelease(true, 0, 0, 2, 3)
		t.eq(o, "hit")
		o, h, m = CaptureRules.applyRelease(false, 0, 2, 2, 3)
		t.eq(o, "fled")
		t.eq(m, 3)
		o = CaptureRules.applyRelease(false, 0, 0, 2, 3)
		t.eq(o, "miss")
		local _ = h
	end)
end
