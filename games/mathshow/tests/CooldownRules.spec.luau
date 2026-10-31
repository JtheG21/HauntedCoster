--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CooldownRules = require(ReplicatedStorage.Shared.CooldownRules)

local NAN = 0 / 0

return function(t: TestRunner.T)
	t.test("formatClock pads and floors", function()
		t.eq(CooldownRules.formatClock(272), "04:32")
		t.eq(CooldownRules.formatClock(300), "05:00")
		t.eq(CooldownRules.formatClock(59.9), "00:59")
		t.eq(CooldownRules.formatClock(0), "00:00")
	end)

	t.test("formatClock clamps bad input and caps at 99:59", function()
		t.eq(CooldownRules.formatClock(-5), "00:00")
		t.eq(CooldownRules.formatClock(NAN), "00:00")
		t.eq(CooldownRules.formatClock(6000), "99:59")
		t.eq(CooldownRules.formatClock(math.huge), "99:59")
	end)

	t.test("formatShort leaves minutes unpadded", function()
		t.eq(CooldownRules.formatShort(17), "0:17")
		t.eq(CooldownRules.formatShort(102), "1:42")
		t.eq(CooldownRules.formatShort(60), "1:00")
		t.eq(CooldownRules.formatShort(600), "10:00")
		t.eq(CooldownRules.formatShort(5999), "99:59")
		t.eq(CooldownRules.formatShort(NAN), "0:00")
	end)

	t.test("retakeRemaining", function()
		t.eq(CooldownRules.retakeRemaining(1000, nil, 300), 0)
		t.eq(CooldownRules.retakeRemaining(1000, 900, 300), 200)
		t.eq(CooldownRules.retakeRemaining(1000, 600, 300), 0)
		t.eq(CooldownRules.retakeRemaining(1000, 700, 300), 0)
		t.eq(CooldownRules.retakeRemaining(1000, 800, nil), 100) -- config default 300
	end)

	t.test("retakeLabel", function()
		t.eq(CooldownRules.retakeLabel(272), "RETAKE IN 04:32")
		t.eq(CooldownRules.retakeLabel(0), "TAKE TEST")
		t.eq(CooldownRules.retakeLabel(-1), "TAKE TEST")
		t.eq(CooldownRules.retakeLabel(NAN), "TAKE TEST")
	end)
end
