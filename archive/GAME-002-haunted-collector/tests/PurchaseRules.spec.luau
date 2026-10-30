--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage.Shared.Config.Catalog)
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local ProfileRules = require(ReplicatedStorage.Shared.Rules.ProfileRules)
local PurchaseRules = require(ReplicatedStorage.Shared.Rules.PurchaseRules)

local cat: CosmeticRules.Catalog = {
	Items = {
		Moss = { name = "Mossy Skin", category = "Skin", coinPrice = 100 },
		Free = { category = "Aura" }, -- no price: not for sale
		Bad = { category = "Aura", coinPrice = -5 },
		Frac = { category = "Aura", coinPrice = 1.5 },
		Huge = { category = "Aura", coinPrice = 1e12 },
	},
	Rewards = {},
}

local function profile(coins: number): ProfileRules.Profile
	local p = ProfileRules.default()
	p.coins = coins
	return p
end

return function(t: TestRunner.T)
	t.test("parse accepts good ids and rejects the rest", function()
		t.truthy(PurchaseRules.parse("Moss", "req-1_a") ~= nil)
		t.eq(PurchaseRules.parse(5, "r1"), nil)
		t.eq(PurchaseRules.parse("a b", "r1"), nil)
		t.eq(PurchaseRules.parse("Moss", nil), nil)
		t.eq(PurchaseRules.parse("Moss", ""), nil)
		t.eq(PurchaseRules.parse("Moss", string.rep("x", 41)), nil)
		t.eq(PurchaseRules.parse("Moss", "has space"), nil)
		t.eq(PurchaseRules.parse("Moss", {}), nil)
	end)

	t.test("price comes only from a sane catalog value", function()
		t.eq(PurchaseRules.price(cat, "Moss"), 100)
		t.eq(PurchaseRules.price(cat, "Free"), nil)
		t.eq(PurchaseRules.price(cat, "Bad"), nil)
		t.eq(PurchaseRules.price(cat, "Frac"), nil)
		t.eq(PurchaseRules.price(cat, "Huge"), nil)
		t.eq(PurchaseRules.price(cat, "Nope"), nil)
	end)

	t.test("a purchase debits exactly the price and grants once", function()
		local p = profile(250)
		local ok, why = PurchaseRules.apply(p, cat, "Moss")
		t.truthy(ok)
		t.eq(why, nil)
		t.eq(p.coins, 150)
		t.eq(p.cosmetics.entitlements.Moss, true)
	end)

	t.test("a repeat or double submit never charges twice", function()
		local p = profile(500)
		PurchaseRules.apply(p, cat, "Moss")
		local ok, why = PurchaseRules.apply(p, cat, "Moss")
		t.eq(ok, false)
		t.eq(why, "alreadyOwned")
		t.eq(p.coins, 400)
	end)

	t.test("insufficient funds states the exact shortfall and changes nothing", function()
		local p = profile(60)
		local q = PurchaseRules.quote(p.coins, p.cosmetics, cat, "Moss")
		t.eq(q.ok, false)
		t.eq(q.reason, "insufficient")
		t.eq(q.need, 40)
		local ok, why = PurchaseRules.apply(p, cat, "Moss")
		t.eq(ok, false)
		t.eq(why, "insufficient")
		t.eq(p.coins, 60)
		t.eq(p.cosmetics.entitlements.Moss, nil)
		t.eq(PurchaseRules.message(why, cat.Items.Moss, q), "You need 40 more Coins for Mossy Skin.")
	end)

	t.test("exactly enough coins buys it and leaves zero", function()
		local p = profile(100)
		t.truthy(PurchaseRules.apply(p, cat, "Moss"))
		t.eq(p.coins, 0)
	end)

	t.test("unknown and unpriced items are refused with no change", function()
		local p = profile(1000)
		local ok1, why1 = PurchaseRules.apply(p, cat, "Nope")
		t.eq(ok1, false)
		t.eq(why1, "unknown")
		local ok2, why2 = PurchaseRules.apply(p, cat, "Free")
		t.eq(ok2, false)
		t.eq(why2, "notBuyable")
		t.eq(p.coins, 1000)
		t.eq(next(p.cosmetics.entitlements), nil)
	end)

	t.test("a full collection refuses and keeps the coins", function()
		local p = profile(500)
		for i = 1, 500 do
			p.cosmetics.entitlements["Filler" .. i] = true
		end
		local ok, why = PurchaseRules.apply(p, cat, "Moss")
		t.eq(ok, false)
		t.eq(why, "full")
		t.eq(p.coins, 500)
		t.eq(p.cosmetics.entitlements.Moss, nil)
	end)

	t.test("receipts return the same answer for a retried request and stay bounded", function()
		local receipts: { PurchaseRules.Receipt } = {}
		PurchaseRules.remember(receipts, { id = "r1", itemId = "Moss", ok = true, message = nil })
		local again = PurchaseRules.recall(receipts, "r1", "Moss")
		t.truthy(again ~= nil and again.ok)
		t.eq(PurchaseRules.recall(receipts, "r2", "Moss"), nil)
		for i = 2, PurchaseRules.MaxReceipts + 5 do
			PurchaseRules.remember(receipts, { id = "r" .. i, itemId = "Moss", ok = false, message = "x" })
		end
		t.eq(#receipts, PurchaseRules.MaxReceipts)
		t.eq(PurchaseRules.recall(receipts, "r1", "Moss"), nil) -- the oldest fell off
	end)

	t.test("a receipt answers only the same item, and only final refusals are remembered", function()
		local receipts: { PurchaseRules.Receipt } = {}
		PurchaseRules.remember(receipts, { id = "r1", itemId = "Moss", ok = true, message = "Bought" })
		t.eq(PurchaseRules.recall(receipts, "r1", "Other"), nil) -- same ID, different item: a new request
		t.eq(PurchaseRules.isFinal("insufficient"), false) -- coins can be earned, so a retry is judged afresh
		t.eq(PurchaseRules.isFinal("full"), false)
		t.eq(PurchaseRules.isFinal("alreadyOwned"), true)
		t.eq(PurchaseRules.isFinal("notBuyable"), true)
		t.eq(PurchaseRules.isFinal(nil), true)
	end)

	t.test("rapid distinct requests for one item charge once", function()
		local p = profile(1000)
		local charged = 0
		for _ = 1, 10 do
			local before = p.coins
			PurchaseRules.apply(p, cat, "Moss")
			charged += before - p.coins
		end
		t.eq(charged, 100)
		t.eq(p.coins, 900)
	end)

	t.test("the shipped catalog prices are whole, positive and never Robux", function()
		for id, item in Catalog.Items do
			local price = item.coinPrice
			if price ~= nil then
				t.truthy(
					PurchaseRules.price({ Items = Catalog.Items, Rewards = Catalog.Rewards }, id) == price,
					`{id} price`
				)
			end
			t.eq((item :: any).product, nil)
			t.eq((item :: any).robux, nil)
		end
	end)

	t.test("messages never mention Robux", function()
		for _, reason in { "insufficient", "alreadyOwned", "notBuyable", "unknown", "full", "zzz" } do
			local m = PurchaseRules.message(reason, { name = "X" }, { ok = false, cost = 5, need = 3 })
			t.eq(string.find(string.lower(m), "robux"), nil)
		end
	end)
end
