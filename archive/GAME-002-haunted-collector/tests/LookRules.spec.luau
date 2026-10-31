--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local LookRules = require(ReplicatedStorage.Shared.Rules.LookRules)

local cat: CosmeticRules.Catalog = {
	Items = {
		Moss = { category = "Skin" },
		WispOnly = { category = "Skin", species = { "Wisp" } },
		Embers = { category = "Aura" },
		Lantern = { category = "Decoration" },
	},
	Rewards = {},
}

local function owned(): { { uid: string, species: string, variant: string } }
	return {
		{ uid = "b", species = "Wisp", variant = "Normal" },
		{ uid = "a", species = "Wisp", variant = "Spectral" },
		{ uid = "c", species = "Ghoul", variant = "Normal" },
	}
end

local function state(): CosmeticRules.State
	local s = CosmeticRules.default()
	s.entitlements.Moss = true
	s.entitlements.WispOnly = true
	s.entitlements.Embers = true
	return s
end

return function(t: TestRunner.T)
	t.test("parse accepts a valid request and a removal", function()
		local r = LookRules.parse("u1", "skin", "Moss")
		t.truthy(r and r.uid == "u1" and r.slot == "skin" and r.id == "Moss")
		local rm = LookRules.parse("u1", "aura", nil)
		t.truthy(rm and rm.id == nil)
	end)

	t.test("parse rejects bad input", function()
		t.eq(LookRules.parse(5, "skin", "Moss"), nil)
		t.eq(LookRules.parse("", "skin", "Moss"), nil)
		t.eq(LookRules.parse(string.rep("x", 65), "skin", "Moss"), nil)
		t.eq(LookRules.parse("u1", "hat", "Moss"), nil)
		t.eq(LookRules.parse("u1", "skin", 7), nil)
		t.eq(LookRules.parse("u1", "skin", "has space"), nil)
		t.eq(LookRules.parse("u1", "skin", {}), nil)
	end)

	t.test("rare variants refuse skins but take auras", function()
		t.truthy(LookRules.variantRefusal("skin", "Spectral") ~= nil)
		t.truthy(LookRules.variantRefusal("skin", "Ashen") ~= nil)
		t.eq(LookRules.variantRefusal("skin", "Normal"), nil)
		t.eq(LookRules.variantRefusal("aura", "Ashen"), nil)
	end)

	t.test("message never leaks internals", function()
		t.truthy(string.find(LookRules.message("notOwned"), "own") ~= nil)
		t.eq(LookRules.message("nonsense"), "Something went wrong. Try again.")
		t.eq(LookRules.message(nil), "Something went wrong. Try again.")
	end)

	t.test("appearance shows only owned, listed, compatible looks", function()
		local s = state()
		s.ghostLooks.b = { skin = "Moss", aura = "Embers" }
		local a = LookRules.appearance(s, cat, "b", "Wisp", "Normal")
		t.eq(a.skin, "Moss")
		t.eq(a.aura, "Embers")
	end)

	t.test("appearance falls back to natural when a look is stale", function()
		local s = state()
		s.ghostLooks.b = { skin = "Gone", aura = "Lantern" } -- unlisted, wrong category
		local a = LookRules.appearance(s, cat, "b", "Wisp", "Normal")
		t.eq(a.skin, nil)
		t.eq(a.aura, nil)
		s.ghostLooks.c = { skin = "WispOnly" } -- species mismatch
		t.eq(LookRules.appearance(s, cat, "c", "Ghoul", "Normal").skin, nil)
		s.entitlements.Moss = false
		s.ghostLooks.b = { skin = "Moss" } -- no longer owned
		t.eq(LookRules.appearance(s, cat, "b", "Wisp", "Normal").skin, nil)
	end)

	t.test("appearance keeps rare variants natural but allows the aura", function()
		local s = state()
		s.ghostLooks.a = { skin = "Moss", aura = "Embers" }
		local a = LookRules.appearance(s, cat, "a", "Wisp", "Spectral")
		t.eq(a.skin, nil)
		t.eq(a.aura, "Embers")
	end)

	t.test("appearance with no cosmetics state is natural", function()
		local a = LookRules.appearance(nil, cat, "b", "Wisp", "Normal")
		t.eq(a.skin, nil)
		t.eq(a.aura, nil)
	end)

	t.test("targets list every owned ghost, sorted, with reasons", function()
		local s = state()
		s.ghostLooks.b = { skin = "WispOnly" }
		local list = LookRules.targets(s, cat, owned(), "WispOnly")
		t.eq(#list, 3)
		t.eq(list[1].uid, "c") -- Ghoul sorts before Wisp
		t.eq(list[1].reason, "incompatible")
		t.eq(list[2].uid, "a")
		t.eq(list[2].reason, "variant")
		t.eq(list[3].uid, "b")
		t.eq(list[3].equipped, true)
		t.eq(list[3].reason, nil)
	end)

	t.test("targets are empty for non-look items and unknown ids", function()
		t.eq(#LookRules.targets(state(), cat, owned(), "Lantern"), 0)
		t.eq(#LookRules.targets(state(), cat, owned(), "Nope"), 0)
	end)

	t.test("equip through CosmeticRules respects ownership and species", function()
		local s = state()
		local ok = CosmeticRules.equipLook(s, cat, "b", "Wisp", "skin", "Moss")
		t.truthy(ok)
		local bad, why = CosmeticRules.equipLook(s, cat, "c", "Ghoul", "skin", "WispOnly")
		t.eq(bad, false)
		t.eq(why, "incompatible")
		s.entitlements.Moss = false
		local ok2, why2 = CosmeticRules.equipLook(s, cat, "b", "Wisp", "skin", "Moss")
		t.eq(ok2, false)
		t.eq(why2, "notOwned")
		CosmeticRules.removeLook(s, "b", "skin")
		t.eq(s.ghostLooks.b, nil)
	end)
end
