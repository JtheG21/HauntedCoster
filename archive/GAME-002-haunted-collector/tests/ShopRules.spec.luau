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

	t.test("a priced, unowned item is buyable and shows its cost", function()
		local priced: CosmeticRules.Catalog = {
			Items = {
				Lamp = { name = "Lamp", category = "Decoration", coinPrice = 50 },
				Both = { name = "Both", category = "Skin", coinPrice = 80 },
				Plain = { name = "Plain", category = "Aura" },
			},
			Rewards = { R = { grants = { "Both" } } },
		}
		local inp = { catalog = priced, cosmetics = CosmeticRules.default(), persistence = "saved" }
		local by = {}
		for _, c in ShopRules.view(inp, "Shop").cards do
			by[c.id] = c
		end
		t.eq(by.Lamp.canBuy, true)
		t.eq(by.Lamp.price, 50)
		t.eq(by.Lamp.acquisition, "buyable")
		t.eq(ShopRules.acquisitionLabel(by.Lamp), "Costs 50 Coins")
		t.eq(ShopRules.acquisitionLabel(by.Both), "Costs 80 Coins, or earn it")
		t.eq(by.Plain.canBuy, false)
		t.eq(by.Plain.acquisition, "notYet")
		t.eq(ids(ShopRules.view(inp, "Shop", { acquisition = "buyable" }))[1], "Both")
		t.eq(ids(ShopRules.view(inp, "Shop", { acquisition = "earnable" }))[1], "Both") -- also earnable
		local owned = CosmeticRules.default()
		owned.entitlements.Lamp = true
		local v = ShopRules.view({ catalog = priced, cosmetics = owned, persistence = "saved" }, "Shop")
		for _, c in v.cards do
			if c.id == "Lamp" then
				t.eq(c.canBuy, false) -- owned: nothing to buy
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

	t.test("the GetCatalog reply is converted and malformed replies are rejected", function()
		local good = ShopRules.catalogFromWire({
			items = { WispSkin = { category = "Skin", name = "Wisp" } },
			rewards = { HabitatOne = { grants = { "WispSkin" } } },
		})
		t.truthy(good ~= nil, "well-formed reply")
		t.eq((good :: CosmeticRules.Catalog).Items.WispSkin.category, "Skin")
		t.eq(#(good :: CosmeticRules.Catalog).Rewards.HabitatOne.grants, 1)
		local empty = ShopRules.catalogFromWire({ items = {}, rewards = {} })
		t.truthy(empty ~= nil, "an empty catalog is valid, not a failure")
		local bad: { any } = {
			"x",
			{},
			{ items = {} },
			{ items = { A = { category = "Bogus" } }, rewards = {} },
			{ items = { A = "s" }, rewards = {} },
			{ items = { ["bad id!"] = { category = "Skin" } }, rewards = {} },
			{ items = { A = { category = "Skin", name = 5 } }, rewards = {} },
			{ items = {}, rewards = { R = {} } },
		}
		for i, b in bad do
			t.eq(ShopRules.catalogFromWire(b), nil, `bad reply {i}`)
		end
		t.eq(ShopRules.catalogFromWire(nil), nil, "nil reply")
	end)
end
