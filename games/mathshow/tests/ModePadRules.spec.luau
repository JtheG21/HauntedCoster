--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModePadConfig = require(ReplicatedStorage.Shared.ModePadConfig)
local ModePadRules = require(ReplicatedStorage.Shared.ModePadRules)

local NAN = 0 / 0

-- 10 x 0.5 x 20 pad centred at (100, 10, 50): top surface at y = 10.25.
local pad: ModePadRules.Pad = { cx = 100, cy = 10, cz = 50, sx = 10, sy = 0.5, sz = 20, yaw = 0 }
local TOP = 10.25

local function at(x: number, y: number, z: number): ModePadRules.Pos
	return { x = x, y = y, z = z }
end

return function(t: TestRunner.T)
	t.test("isInside: centre and each axis edge, inside and outside", function()
		t.eq(ModePadRules.isInside(pad, at(100, TOP + 3, 50)), true)
		t.eq(ModePadRules.isInside(pad, at(105, TOP + 3, 50)), true) -- x edge
		t.eq(ModePadRules.isInside(pad, at(105.01, TOP + 3, 50)), false)
		t.eq(ModePadRules.isInside(pad, at(95, TOP + 3, 50)), true)
		t.eq(ModePadRules.isInside(pad, at(94.99, TOP + 3, 50)), false)
		t.eq(ModePadRules.isInside(pad, at(100, TOP + 3, 60)), true) -- z edge
		t.eq(ModePadRules.isInside(pad, at(100, TOP + 3, 60.01)), false)
		t.eq(ModePadRules.isInside(pad, at(100, TOP + 3, 39.99)), false)
	end)

	t.test("isInside: vertical tolerance boundary", function()
		t.eq(ModePadRules.isInside(pad, at(100, TOP, 50)), true) -- on the surface
		t.eq(ModePadRules.isInside(pad, at(100, TOP + ModePadConfig.VerticalTolerance, 50)), true)
		t.eq(ModePadRules.isInside(pad, at(100, TOP + ModePadConfig.VerticalTolerance + 0.01, 50)), false)
		t.eq(ModePadRules.isInside(pad, at(100, TOP - 0.01, 50)), false) -- below the top
	end)

	t.test("isInside: rotated pad uses its yawed footprint", function()
		local rotated: ModePadRules.Pad = { cx = 0, cy = 0, cz = 0, sx = 10, sy = 0.5, sz = 20, yaw = math.pi / 2 }
		local y = 0.25 + 3
		-- A 90 degree yaw swaps the axes: the long side (20) now runs along world X.
		t.eq(ModePadRules.isInside(rotated, at(9, y, 0)), true)
		t.eq(ModePadRules.isInside(rotated, at(11, y, 0)), false)
		t.eq(ModePadRules.isInside(rotated, at(0, y, 4)), true)
		t.eq(ModePadRules.isInside(rotated, at(0, y, 6)), false)
		-- 45 degrees: a 10 square becomes a diamond with its corners on the world axes, 7.07 out.
		local square: ModePadRules.Pad = { cx = 0, cy = 0, cz = 0, sx = 10, sy = 0.5, sz = 10, yaw = math.pi / 4 }
		t.eq(ModePadRules.isInside(square, at(6, y, 0)), true)
		t.eq(ModePadRules.isInside(square, at(8, y, 0)), false)
		t.eq(ModePadRules.isInside(square, at(4, y, 4)), false) -- 5.66 along a side normal, past the 5 half-width
		t.eq(ModePadRules.isInside(square, at(3, y, 3)), true)
	end)

	t.test("isInside: non-finite input is outside", function()
		t.eq(ModePadRules.isInside(pad, at(NAN, TOP + 3, 50)), false)
		t.eq(ModePadRules.isInside(pad, at(100, math.huge, 50)), false)
		t.eq(
			ModePadRules.isInside(
				{ cx = 100, cy = 10, cz = 50, sx = NAN, sy = 0.5, sz = 20, yaw = 0 },
				at(100, TOP, 50)
			),
			false
		)
	end)

	local cd = ModePadConfig.CooldownSeconds

	t.test("step: enter triggers, standing never retriggers", function()
		local s: ModePadRules.State = { inside = false }
		local trigger
		s, trigger = ModePadRules.step(s, true, 10)
		t.eq(trigger, true)
		t.eq(s.lastTriggerAt, 10)
		for i = 1, 40 do
			s, trigger = ModePadRules.step(s, true, 10 + i * 0.25)
			t.eq(trigger, false)
		end
	end)

	t.test("step: re-enter inside the cooldown does not trigger, after it does", function()
		local s: ModePadRules.State = { inside = false }
		local trigger
		s = ModePadRules.step(s, true, 10)
		s = ModePadRules.step(s, false, 10.5)
		s, trigger = ModePadRules.step(s, true, 10 + cd - 0.25)
		t.eq(trigger, false)
		t.eq(s.inside, true)
		t.eq(s.lastTriggerAt, 10) -- a suppressed entry does not restart the cooldown
		s = ModePadRules.step(s, false, 10 + cd)
		s, trigger = ModePadRules.step(s, true, 10 + cd) -- exactly the cooldown: allowed
		t.eq(trigger, true)
		t.eq(s.lastTriggerAt, 10 + cd)
		s = ModePadRules.step(s, false, 20)
		s, trigger = ModePadRules.step(s, true, 21)
		t.eq(trigger, true)
	end)

	t.test("step: leaving never triggers; starting inside counts as an entry", function()
		local s: ModePadRules.State = { inside = true, lastTriggerAt = 5 }
		local trigger
		s, trigger = ModePadRules.step(s, false, 6)
		t.eq(trigger, false)
		t.eq(s.inside, false)
		local fresh: ModePadRules.State = { inside = false }
		local _entered
		_entered, trigger = ModePadRules.step(fresh, true, 0)
		t.eq(trigger, true)
	end)

	t.test("step: NaN and bad input never trigger and leave state alone", function()
		local s: ModePadRules.State = { inside = false, lastTriggerAt = 1 }
		local next, trigger = ModePadRules.step(s, true, NAN)
		t.eq(trigger, false)
		t.eq(next, s)
		next, trigger = ModePadRules.step(s, true, math.huge)
		t.eq(trigger, false)
		next, trigger = ModePadRules.step(s, (nil :: any) :: boolean, 50)
		t.eq(trigger, false)
		-- a corrupt lastTriggerAt does not lock the pad forever
		local _corrupt
		_corrupt, trigger = ModePadRules.step({ inside = false, lastTriggerAt = NAN }, true, 50)
		t.eq(trigger, true)
	end)

	t.test("screenFor: configured modes map, unknown modes are rejected", function()
		t.eq(ModePadRules.screenFor("Blitz"), "confirm_blitz")
		t.eq(ModePadRules.screenFor("VS"), "confirm_vs")
		t.eq(ModePadRules.screenFor("Group"), "confirm_group")
		t.eq(ModePadRules.screenFor("Practice"), "practice")
		t.eq(ModePadRules.screenFor("Skill"), "skillintro")
		t.eq(ModePadRules.screenFor("Daily"), "locked:daily")
		t.eq(ModePadRules.screenFor("Ranks"), nil)
		t.eq(ModePadRules.screenFor("blitz"), nil)
		t.eq(ModePadRules.screenFor(""), nil)
		t.eq(ModePadRules.screenFor(nil), nil)
		t.eq(ModePadRules.screenFor(5), nil)
		t.eq(ModePadRules.screenFor("__index"), nil)
	end)
end
