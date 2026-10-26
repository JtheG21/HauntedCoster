--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local NameRules = require(ReplicatedStorage.Shared.NameRules)

return function(t: TestRunner.T)
	t.test("short names are unchanged", function()
		t.eq(NameRules.truncateName("JtheG21"), "JtheG21")
		t.eq(NameRules.truncateName(""), "")
	end)

	t.test("exactly 20 characters is unchanged, 21 is cut to 20 with an ellipsis", function()
		local twenty = string.rep("a", 20)
		t.eq(NameRules.truncateName(twenty), twenty)
		local cut = NameRules.truncateName(string.rep("a", 21))
		t.eq(cut, string.rep("a", 19) .. "\u{2026}")
		t.eq(utf8.len(cut), 20)
	end)

	t.test("the audit example", function()
		t.eq(NameRules.truncateName("SirCountsALot_Official"), "SirCountsALot_Offic\u{2026}")
	end)

	t.test("counts characters, not bytes", function()
		local wide = string.rep("\u{00e9}", 20)
		t.eq(NameRules.truncateName(wide), wide)
		t.eq(utf8.len(NameRules.truncateName(string.rep("\u{00e9}", 25))), 20)
	end)

	t.test("invalid UTF-8 falls back to a byte cut", function()
		local bad = string.rep("\255", 30)
		t.eq(NameRules.truncateName(bad), string.rep("\255", 19) .. "\u{2026}")
		t.eq(NameRules.truncateName("\255\255"), "\255\255")
	end)
end
