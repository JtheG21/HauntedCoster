--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GateRules = require(ReplicatedStorage.Shared.GateRules)

local BOTH = { "Shinobi", "Ki" }

return function(t: TestRunner.T)
	t.test("requirements keep only present factions' powers", function()
		t.eq(#GateRules.requirements(BOTH, { "Shinobi", "Ki" }), 2)
		local onlyKi = GateRules.requirements(BOTH, { "Ki" })
		t.eq(#onlyKi, 1)
		t.eq(onlyKi[1], "Ki")
		t.eq(#GateRules.requirements(BOTH, {}), 0)
		t.eq(#GateRules.requirements(BOTH, { "Corsairs" }), 0)
	end)

	t.test("opens only when all required powers are inside the window", function()
		t.eq(GateRules.canOpen(BOTH, { Shinobi = 95, Ki = 100 }, 100, 10), true)
		t.eq(GateRules.canOpen(BOTH, { Shinobi = 89.9, Ki = 100 }, 100, 10), false)
		t.eq(GateRules.canOpen(BOTH, { Ki = 100 }, 100, 10), false)
		t.eq(GateRules.canOpen(BOTH, { Shinobi = 90, Ki = 100 }, 100, 10), true)
	end)

	t.test("future, NaN and empty requirements never open", function()
		t.eq(GateRules.canOpen(BOTH, { Shinobi = 101, Ki = 100 }, 100, 10), false)
		t.eq(GateRules.canOpen(BOTH, { Shinobi = 0 / 0, Ki = 100 }, 100, 10), false)
		t.eq(GateRules.canOpen({}, {}, 100, 10), false)
	end)

	t.test("single-faction requirement opens with one power", function()
		t.eq(GateRules.canOpen({ "Ki" }, { Ki = 100 }, 101, 10), true)
	end)

	t.test("shrine timing", function()
		t.eq(GateRules.shrineDue(nil, false, 100, 20), false)
		t.eq(GateRules.shrineDue(80, false, 99.9, 20), false)
		t.eq(GateRules.shrineDue(80, false, 100, 20), true)
		t.eq(GateRules.shrineDue(80, true, 120, 20), false)
	end)

	t.test("awards one charge per opening power, once", function()
		local first = GateRules.awardFor(BOTH, false)
		t.eq(#first, 2)
		t.eq(#GateRules.awardFor(BOTH, true), 0)
		first[1] = "changed"
		t.eq(BOTH[1], "Shinobi", "award list is a copy")
	end)

	t.test("clone input: a consumed clone that stays never counts again (audit F1)", function()
		local seenAt, consumed = GateRules.cloneInput(true, false, nil, 10)
		t.eq(seenAt, 10)
		-- gate opens: consumed = true, seenAt cleared
		seenAt, consumed = nil, true
		for now = 11, 30 do
			seenAt, consumed = GateRules.cloneInput(true, consumed, seenAt, now)
			t.eq(seenAt, nil, "still the same clone")
		end
		-- clone leaves, then a clone arrives again
		seenAt, consumed = GateRules.cloneInput(false, consumed, seenAt, 31)
		t.eq(consumed, false)
		seenAt, consumed = GateRules.cloneInput(true, consumed, seenAt, 32)
		t.eq(seenAt, 32)
	end)

	t.test("clone input: leaving keeps the last time for the window", function()
		local seenAt = GateRules.cloneInput(false, false, 50, 55)
		t.eq(seenAt, 50)
	end)
end
