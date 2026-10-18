--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ExhibitRules = require(ReplicatedStorage.Shared.Rules.ExhibitRules)
local ProfileRules = require(ReplicatedStorage.Shared.Rules.ProfileRules)

return function(t: TestRunner.T)
	local function profileWith(houseTier: number)
		local p = ProfileRules.default()
		p.houseTier = houseTier
		table.insert(p.owned, { uid = "m1", species = "Wisp", variant = "Normal" } :: any)
		return p
	end

	t.test("a valid slot with an owned monster, or with none, is allowed", function()
		local p = profileWith(0)
		t.eq(ExhibitRules.setRefusal(p, 1, "m1"), nil)
		t.eq(ExhibitRules.setRefusal(p, 2, nil), nil, "clearing a slot needs no monster")
	end)

	t.test("no profile means still loading", function()
		t.eq(ExhibitRules.setRefusal(nil, 1, "m1"), "Still loading")
	end)

	t.test("slot must be a whole number", function()
		local p = profileWith(0)
		local badSlots: { any } = { "1", 1.5, 0 / 0, math.huge, -math.huge, true, {} }
		for _, bad in badSlots do
			t.eq(ExhibitRules.setRefusal(p, bad, "m1"), "Bad slot", `slot {tostring(bad)}`)
		end
		t.eq(ExhibitRules.setRefusal(p, nil, "m1"), "Bad slot", "nil slot")
	end)

	t.test("slot must be inside the house tier's range", function()
		local p = profileWith(0)
		local outOfRange: { any } = { 0, -1, 3, 100 }
		for _, bad in outOfRange do
			t.eq(ExhibitRules.setRefusal(p, bad, "m1"), "That exhibit slot is locked", `slot {bad}`)
		end
		t.eq(ExhibitRules.setRefusal(profileWith(1), 3, "m1"), nil, "a higher tier opens slot 3")
	end)

	t.test("the monster must be an owned string uid", function()
		local p = profileWith(0)
		local badUids: { any } = { "nope", 5, true, {} }
		for _, bad in badUids do
			t.eq(ExhibitRules.setRefusal(p, 1, bad), "You don't own that monster", `uid {tostring(bad)}`)
		end
	end)

	t.test("checks run in order: loading, slot shape, slot range, ownership", function()
		local p = profileWith(0)
		t.eq(ExhibitRules.setRefusal(nil, "x", "nope"), "Still loading")
		t.eq(ExhibitRules.setRefusal(p, "x", "nope"), "Bad slot")
		t.eq(ExhibitRules.setRefusal(p, 99, "nope"), "That exhibit slot is locked")
		t.eq(ExhibitRules.setRefusal(p, 1, "nope"), "You don't own that monster")
	end)
end
