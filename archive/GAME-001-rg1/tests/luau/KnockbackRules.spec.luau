--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KnockbackRules = require(ReplicatedStorage.Shared.KnockbackRules)

local CFG = { MinChargeSeconds = 0.5, MaxChargeSeconds = 1.5, StaleChargeSeconds = 5 }

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return function(t: TestRunner.T)
	t.test("no recorded charge gives minimum power", function()
		t.eq(KnockbackRules.chargeFraction(nil, 10, CFG), 0)
	end)

	t.test("charge curve: below min, mid, full, beyond max", function()
		t.eq(KnockbackRules.chargeFraction(10, 10.3, CFG), 0)
		t.truthy(near(KnockbackRules.chargeFraction(10, 11.0, CFG), 0.5), "half")
		t.eq(KnockbackRules.chargeFraction(10, 11.5, CFG), 1)
		t.eq(KnockbackRules.chargeFraction(10, 13, CFG), 1)
	end)

	t.test("stale, negative and NaN charges give minimum power", function()
		t.eq(KnockbackRules.chargeFraction(10, 15.5, CFG), 0)
		t.eq(KnockbackRules.chargeFraction(10, 9, CFG), 0)
		t.eq(KnockbackRules.chargeFraction(0 / 0, 10, CFG), 0)
		t.eq(KnockbackRules.chargeFraction(10, 0 / 0, CFG), 0)
	end)

	t.test("lerp", function()
		t.eq(KnockbackRules.lerp(15, 45, 0), 15)
		t.eq(KnockbackRules.lerp(15, 45, 1), 45)
		t.eq(KnockbackRules.lerp(15, 45, 0.5), 30)
	end)

	t.test("push direction is flat and unit, with fallback", function()
		local d = KnockbackRules.pushDirection(Vector3.zero, Vector3.new(3, 9, 4), Vector3.new(1, 0, 0))
		t.truthy(near(d.Magnitude, 1) and d.Y == 0, "flat unit")
		local f = KnockbackRules.pushDirection(Vector3.zero, Vector3.new(0, 5, 0), Vector3.new(0, 0, 2))
		t.eq(f, Vector3.new(0, 0, 1))
	end)

	t.test("inFront: range and facing", function()
		local look = Vector3.new(0, 0, -1)
		t.eq(KnockbackRules.inFront(Vector3.zero, look, Vector3.new(0, 0, -5), 12), true)
		t.eq(KnockbackRules.inFront(Vector3.zero, look, Vector3.new(0, 0, 5), 12), false)
		t.eq(KnockbackRules.inFront(Vector3.zero, look, Vector3.new(0, 0, -13), 12), false)
	end)
end
