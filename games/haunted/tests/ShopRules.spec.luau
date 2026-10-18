--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local ShopRules = require(ReplicatedStorage.Shared.Rules.ShopRules)

local cat: CosmeticRules.Catalog = {
	Items = {
		WispSkin = { category = "Skin", name = "Wisp Skin" },
		GlowAura = { category = "Aura" },
		MossTheme = { category = "Theme", tiers = { 0 } },
		Lantern = { category = "Decoration" },
	},
	Rewards = { HabitatOne = { grants = { "MossTheme" } } },
}

local function state(): CosmeticRules.State
	local s = CosmeticRules.default()
	s.entitlements.WispSkin = true
	s.entitlements.Gone = true -- owned, but the catalog doesn't list it
	s.ghostLooks.u1 = { skin = "WispSkin" }
	return s
end

local function ids(v: ShopRules.View): { string }
	local out = {}
	for _, c in v.cards do
		table.insert(out, c.id)
	end
	return out
end

return function(t: TestRunner.T)
	t.test("unknown ownership is loading, never unowned", function()
		t.eq(ShopRules.view({ catalog = cat, cosmetics = nil, persistence = "saved" }, "Shop").status, "loading")
		t.eq(ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "loading" }, "Shop").status, "loading")
	end)

	t.test("a catalog that failed to load is unavailable, not empty", function()
		local v = ShopRules.view({ catalog = nil, cosmetics = state(), persistence = "saved" }, "Shop")
		t.eq(v.status, "unavailable")
		t.eq(#v.cards, 0)
	end)

	t.test("an empty catalog and no entitlements read as empty", function()
		local empty: CosmeticRules.Catalog = { Items = {}, Rewards = {} }
		local inp = { catalog = empty, cosmetics = CosmeticRules.default(), persistence = "saved" }
		t.eq(ShopRules.view(inp, "Shop").status, "empty")
		t.eq(ShopRules.view(inp, "Owned").status, "empty")
	end)

	t.test("cards carry owned, equipped and acquisition honestly, and nothing is buyable", function()
		local v = ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "saved" }, "Shop")
		t.eq(v.status, "ready")
		local by = {}
		for _, c in v.cards do
			by[c.id] = c
			t.eq(c.canBuy, false, `{c.id} canBuy`)
		end
		t.eq(by.WispSkin.owned, true)
		t.eq(by.WispSkin.equipped, true)
		t.eq(by.WispSkin.equippedOn[1], "ghost:u1")
		t.eq(by.WispSkin.name, "Wisp Skin")
		t.eq(by.GlowAura.owned, false)
		t.eq(by.GlowAura.acquisition, "notYet")
		t.eq(by.GlowAura.name, "GlowAura", "name falls back to the ID")
		t.eq(by.MossTheme.acquisition, "earnable")
		t.eq(by.MossTheme.rewardId, "HabitatOne")
		t.eq(ShopRules.acquisitionLabel(by.WispSkin), "Owned, in use")
		t.eq(ShopRules.acquisitionLabel(by.GlowAura), "Not available yet")
	end)

	t.test("the Owned tab keeps entitlements the catalog no longer lists", function()
		local v = ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "saved" }, "Owned")
		local got = ids(v)
		t.eq(#got, 2)
		t.truthy(table.find(got, "Gone") ~= nil, "unlisted item shown")
		for _, c in v.cards do
			if c.id == "Gone" then
				t.eq(c.listed, false)
				t.eq(c.category, nil)
			end
		end
	end)

	t.test("filters narrow by category, ownership and acquisition", function()
		local inp = { catalog = cat, cosmetics = state(), persistence = "saved" }
		t.eq(#ShopRules.view(inp, "Shop", { category = "Skin" }).cards, 1)
		t.eq(ids(ShopRules.view(inp, "Shop", { ownership = "owned" }))[1], "WispSkin")
		t.eq(#ShopRules.view(inp, "Shop", { ownership = "unowned" }).cards, 3)
		t.eq(ids(ShopRules.view(inp, "Shop", { acquisition = "earnable" }))[1], "MossTheme")
		t.eq(ShopRules.view(inp, "Shop", { category = "Skin", ownership = "unowned" }).status, "noMatch")
		t.eq(ShopRules.view(inp, "Owned", { category = "Skin" }).cards[1].id, "WispSkin")
	end)

	t.test("saving problems surface as a notice without hiding known ownership", function()
		local ro = ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "readonly" }, "Shop")
		t.eq(ro.status, "ready")
		t.truthy(ro.notice ~= nil, "readonly notice")
		local mem = ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "memory" }, "Shop")
		t.truthy(mem.notice ~= nil, "memory notice")
		t.eq(ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "saved" }, "Shop").notice, nil)
	end)

	t.test("ordering is stable: unowned first, then by name", function()
		local v = ShopRules.view({ catalog = cat, cosmetics = state(), persistence = "saved" }, "Shop")
		t.eq(ids(v)[#v.cards], "WispSkin", "owned sorts last in the Shop")
		t.eq(ids(v)[1], "GlowAura")
	end)
end
