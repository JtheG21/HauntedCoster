--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local ThemeRules = require(ReplicatedStorage.Shared.Rules.ThemeRules)

local cat: CosmeticRules.Catalog = {
	Items = {
		Moon = { name = "Moonlit", category = "Theme", tiers = { 1, 2 } },
		Empty = { category = "Theme" },
		Moss = { category = "Skin" },
	},
	Rewards = {},
}

local function owning(): CosmeticRules.State
	local s = CosmeticRules.default()
	s.entitlements.Moon = true
	s.entitlements.Empty = true
	return s
end

return function(t: TestRunner.T)
	t.test("parse accepts an id or nil and rejects the rest", function()
		t.truthy(ThemeRules.parse("Moon"))
		t.truthy(ThemeRules.parse(nil))
		t.eq((ThemeRules.parse(5)), false)
		t.eq((ThemeRules.parse("a b")), false)
		t.eq((ThemeRules.parse({})), false)
	end)

	t.test("supports needs a Theme that lists the tier", function()
		t.truthy(ThemeRules.supports(cat.Items.Moon :: any, 1))
		t.eq(ThemeRules.supports(cat.Items.Moon :: any, 0), false)
		t.eq(ThemeRules.supports(cat.Items.Empty :: any, 0), false) -- no tiers declared
		t.eq(ThemeRules.supports(cat.Items.Moss :: any, 1), false) -- not a theme
		t.eq(ThemeRules.supports(nil, 1), false)
	end)

	t.test("coverage is honest, including a theme that covers nothing", function()
		t.eq(ThemeRules.coverage(cat.Items.Moon :: any), "Covers: Restored Manor, Grand Mansion")
		t.eq(ThemeRules.coverage(cat.Items.Empty :: any), "Covers no house tier yet.")
		t.eq(ThemeRules.coverage(nil), "Covers no house tier yet.")
	end)

	t.test("equipping an unsupported tier is refused with a reason", function()
		local s = owning()
		local ok, why = CosmeticRules.setTheme(s, cat, "Moon", 0)
		t.eq(ok, false)
		t.eq(why, "tier")
		t.eq(s.mansionTheme, nil)
		t.truthy(string.find(ThemeRules.message(why), "current house") ~= nil)
		local ok2 = CosmeticRules.setTheme(s, cat, "Moon", 1)
		t.truthy(ok2)
		t.eq(s.mansionTheme, "Moon")
	end)

	t.test("resolve shows the theme only at a covered tier", function()
		local s = owning()
		s.mansionTheme = "Moon"
		t.eq(ThemeRules.resolve(s, cat, 1), "Moon")
		t.eq(ThemeRules.resolve(s, cat, 2), "Moon")
		t.eq(ThemeRules.resolve(s, cat, 0), nil)
		s.entitlements.Moon = false
		t.eq(ThemeRules.resolve(s, cat, 1), nil) -- not owned
		s.entitlements.Moon = true
		s.mansionTheme = "Gone"
		t.eq(ThemeRules.resolve(s, cat, 1), nil) -- unlisted
		t.eq(ThemeRules.resolve(nil, cat, 1), nil)
	end)

	t.test("an upgrade that invalidates the theme gives a notice and keeps ownership", function()
		local s = owning()
		s.mansionTheme = "Moon"
		t.eq(ThemeRules.fallbackNotice(s, cat, 2), nil) -- still covered
		s.mansionTheme = "Empty" -- covers nothing
		local note = ThemeRules.fallbackNotice(s, cat, 2)
		t.truthy(note ~= nil and string.find(note, "default look") ~= nil)
		t.truthy(note ~= nil and string.find(note, "Grand Mansion") ~= nil)
		t.eq(s.entitlements.Empty, true)
		s.mansionTheme = nil
		t.eq(ThemeRules.fallbackNotice(s, cat, 2), nil) -- nothing equipped, nothing to say
	end)

	t.test("removing a theme keeps it owned", function()
		local s = owning()
		CosmeticRules.setTheme(s, cat, "Moon", 2)
		CosmeticRules.setTheme(s, cat, nil, 2)
		t.eq(s.mansionTheme, nil)
		t.eq(s.entitlements.Moon, true)
	end)
end
