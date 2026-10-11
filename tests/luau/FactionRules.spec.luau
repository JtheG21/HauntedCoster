--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FactionRules = require(ReplicatedStorage.Shared.FactionRules)

local ORDER = { "Shinobi", "Ki" }

return function(t: TestRunner.T)
	t.test("empty server picks first in order", function()
		t.eq(FactionRules.pickBalanced({}, ORDER), "Shinobi")
	end)

	t.test("picks the smaller faction", function()
		t.eq(FactionRules.pickBalanced({ Shinobi = 3, Ki = 2 }, ORDER), "Ki")
		t.eq(FactionRules.pickBalanced({ Shinobi = 1 }, ORDER), "Ki")
	end)

	t.test("ties go to order", function()
		t.eq(FactionRules.pickBalanced({ Shinobi = 2, Ki = 2 }, ORDER), "Shinobi")
	end)

	t.test("ignores factions outside the active order", function()
		t.eq(FactionRules.pickBalanced({ Corsairs = 0, Shinobi = 1, Ki = 1 }, ORDER), "Shinobi")
	end)

	t.test("sequential joins stay balanced within 1", function()
		local counts = {}
		for _ = 1, 9 do
			local f = FactionRules.pickBalanced(counts, ORDER)
			counts[f] = (counts[f] or 0) + 1
			t.truthy(FactionRules.isBalanced(counts, ORDER), "balanced after each join")
		end
		t.eq(counts.Shinobi, 5)
		t.eq(counts.Ki, 4)
	end)

	t.test("isBalanced detects imbalance", function()
		t.eq(FactionRules.isBalanced({ Shinobi = 3, Ki = 1 }, ORDER), false)
		t.eq(FactionRules.isBalanced({ Shinobi = 2, Ki = 1 }, ORDER), true)
	end)
end
