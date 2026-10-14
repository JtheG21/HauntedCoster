--!strict
-- Cosmetics (TASK-0047): the catalog carries no gameplay, ownership/equipment/purchases/receipts/rewards behave
-- as SYS-Haunted-Monetization-UI requires, placements are validated in plot-local space, and schema-1 profiles
-- migrate with every field kept.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local Cosmetics = require(Shared.Config.Cosmetics)
local CosmeticRules = require(Shared.Rules.CosmeticRules)
local PlacementRules = require(Shared.Rules.PlacementRules)
local ProfileRules = require(Shared.Rules.ProfileRules)
local EconomyRules = require(Shared.Rules.EconomyRules)
local World = require(Shared.Config.World)

return function(t: TestRunner.T)
	local now = 1_800_000_000

	local function profile(extra: { [string]: any }?): any
		local raw: { [string]: any } = {
			coins = 5000,
			owned = {
				{ uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 1 },
				{ uid = "m2", species = "Hound", variant = "Spectral", acquiredAt = 1 },
			},
		}
		for k, v in (extra or {}) :: { [string]: any } do
			raw[k] = v
		end
		return (ProfileRules.sanitize(raw, now))
	end

	t.test("catalog: all five categories, valid acquisition, no gameplay fields", function()
		local seen: { [string]: boolean } = {}
		local gameplay =
			{ "income", "incomePerSecond", "rarity", "speed", "capacity", "capture", "multiplier", "chance", "boost" }
		for _, item in Cosmetics.Items do
			seen[item.category] = true
			local a = item.acquire
			t.truthy(a.coins or a.product or a.reward, `{item.id} has an acquisition route`)
			if a.product then
				t.truthy(Cosmetics.Products[a.product] ~= nil, `{item.id} product listed`)
			end
			if a.reward then
				t.truthy(Cosmetics.MilestoneById[a.reward] ~= nil, `{item.id} reward milestone exists`)
			end
			for _, key in gameplay do
				t.truthy((item :: any)[key] == nil and item.look[key] == nil, `{item.id} has no gameplay field {key}`)
			end
			if item.category == "Decoration" then
				t.truthy(item.footprint and item.limit, `{item.id} has a footprint and a limit`)
			end
		end
		for _, c in Cosmetics.Categories do
			t.truthy(seen[c], `category {c} present`)
		end
	end)

	t.test("no Robux product is live until jg configures a real id", function()
		for key, product in Cosmetics.Products do
			t.eq(product.productId, nil, key)
		end
		local snap = CosmeticRules.snapshot(profile(), true)
		t.eq(next(snap.productsLive), nil)
	end)

	t.test("cosmetics never change income", function()
		local p = profile()
		local before = EconomyRules.incomeRate(p, now + 9999)
		CosmeticRules.buyWithCoins(p, "skin_wisp_candlewick")
		CosmeticRules.equipGhost(p, "skins", "m1", "skin_wisp_candlewick")
		p.cosmetics.owned.aura_motes = true
		CosmeticRules.equipGhost(p, "auras", "m2", "aura_motes")
		t.eq(EconomyRules.incomeRate(p, now + 9999), before)
	end)

	t.test("coin purchase charges once, needs the price, rejects owned items", function()
		local p = profile()
		local ok = CosmeticRules.buyWithCoins(p, "skin_wisp_candlewick")
		t.truthy(ok)
		t.eq(p.coins, 5000 - 400)
		local again, why = CosmeticRules.buyWithCoins(p, "skin_wisp_candlewick")
		t.truthy(not again and why == "Already owned")
		t.eq(p.coins, 4600)
		local poor = profile({ coins = 10 })
		local ok2, why2 = CosmeticRules.buyWithCoins(poor, "theme_bone")
		t.truthy(not ok2 and why2 == "Needs 1500 Coins")
		t.eq(poor.coins, 10)
		t.truthy(not CosmeticRules.buyWithCoins(p, "skin_wisp_moonlit"), "Robux-only item not for Coins")
	end)

	t.test("skins: per ghost, compatible species only, reusable on several ghosts", function()
		local p = profile({
			owned = {
				{ uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 1 },
				{ uid = "m3", species = "Wisp", variant = "Spectral", acquiredAt = 1 },
				{ uid = "m2", species = "Hound", variant = "Normal", acquiredAt = 1 },
			},
		})
		p.cosmetics.owned.skin_wisp_candlewick = true
		t.truthy(CosmeticRules.equipGhost(p, "skins", "m1", "skin_wisp_candlewick"))
		t.truthy(CosmeticRules.equipGhost(p, "skins", "m3", "skin_wisp_candlewick"))
		local ok, why = CosmeticRules.equipGhost(p, "skins", "m2", "skin_wisp_candlewick")
		t.truthy(not ok and string.find(why :: string, "Only fits") ~= nil)
		t.truthy(not CosmeticRules.equipGhost(p, "skins", "m9", "skin_wisp_candlewick"), "unknown ghost")
		t.truthy(not CosmeticRules.equipGhost(p, "skins", "m1", "skin_wisp_moonlit"), "not owned")
		t.truthy(CosmeticRules.equipGhost(p, "skins", "m1", nil), "remove")
		t.eq(p.cosmetics.skins.m1, nil)
		t.eq(p.cosmetics.skins.m3, "skin_wisp_candlewick")
		t.eq(p.owned[2].variant, "Spectral", "natural variant untouched")
	end)

	t.test("receipts are applied once and unknown products are refused", function()
		local p = profile()
		t.eq(CosmeticRules.applyReceipt(p, "r1", 123), "invalid", "unconfigured product")
		local product = Cosmetics.Products.aura_gravemist
		product.productId = 987654 -- test fixture only, restored below
		t.eq(CosmeticRules.applyReceipt(p, "r1", 987654), "granted")
		t.truthy(p.cosmetics.owned.aura_gravemist)
		t.eq(CosmeticRules.applyReceipt(p, "r1", 987654), "duplicate")
		t.eq(#p.cosmetics.receipts, 1)
		product.productId = nil
	end)

	t.test("rewards come from the journal only and are claimed once", function()
		local p = profile()
		local ok = CosmeticRules.claim(p, "variant_first")
		t.truthy(ok, "the Spectral Hound counts")
		t.truthy(p.cosmetics.owned.aura_moths)
		t.truthy(not CosmeticRules.claim(p, "variant_first"), "claimed once")
		local fresh = profile({ owned = {} })
		fresh.cosmetics.owned.skin_hound_bone = true -- owning a reward item does not complete anything
		t.truthy(not CosmeticRules.claim(fresh, "habitat_woodland"))
		local all = CosmeticRules.obtainableVariants()
		t.truthy(all["Gentleman:Ashen"] and not all["Wisp:Ashen"], "Ashen only where the crypt spawns it")
	end)

	t.test("placements: inside the plot, clear of gameplay, house and each other, within limits", function()
		local p = profile()
		p.cosmetics.owned.deco_pumpkin = true
		-- A free spot: west strip behind the pen, clear of the spawn.
		local ok, why, key = CosmeticRules.place(p, "deco_pumpkin", -44, 26, 0)
		t.truthy(ok, why)
		t.truthy(not CosmeticRules.place(p, "deco_pumpkin", -44, 26, 0), "overlap refused")
		t.truthy(not CosmeticRules.place(p, "deco_pumpkin", 10, -20, 0), "track area refused")
		t.truthy(not CosmeticRules.place(p, "deco_pumpkin", World.Plot.pen.X, World.Plot.pen.Z, 0), "pen refused")
		t.truthy(not CosmeticRules.place(p, "deco_pumpkin", 0, 30, 0), "house refused")
		t.truthy(not CosmeticRules.place(p, "deco_pumpkin", 60, 0, 0), "outside refused")
		t.truthy(not CosmeticRules.place(p, "deco_lamp", -44, 34, 0), "not owned")
		t.truthy(CosmeticRules.move(p, key, -44, 30.3, 47, true))
		local placed = p.cosmetics.placements[1]
		t.eq(placed.rot, 45, "rotation snaps")
		t.eq(placed.z, 30.25, "fine step")
		t.truthy(CosmeticRules.store(p, key))
		t.eq(#p.cosmetics.placements, 0)
		t.truthy(p.cosmetics.owned.deco_pumpkin, "storing keeps the unlock")
	end)

	t.test("upgrades keep fitting placements and store the rest", function()
		local p = profile()
		p.cosmetics.owned.deco_pumpkin = true
		-- Right where the Grand Mansion's east wing will stand, but clear of the shack.
		t.truthy((CosmeticRules.place(p, "deco_pumpkin", 21, 33, 0)))
		t.truthy((CosmeticRules.place(p, "deco_pumpkin", -44, 26, 0)))
		p.houseTier = 2
		local stored = CosmeticRules.onTierChanged(p)
		t.eq(#stored, 1)
		t.eq(#p.cosmetics.placements, 1)
		t.eq(PlacementRules.check("deco_pumpkin", -44, 26, 0, 2, {}), "ok")
	end)

	t.test("schema 1 migrates: every field kept, cosmetics start empty, junk is dropped", function()
		local v1 = {
			schema = 1,
			coins = 777,
			houseTier = 1,
			speedLevel = 2,
			owned = { { uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 1 } },
			exhibits = { { slot = 1, uid = "m1" } },
			futureField = { kept = true },
		}
		local p = ProfileRules.sanitize(v1, now)
		t.eq(p.schema, 2)
		t.eq(p.coins, 777)
		t.eq(p.houseTier, 1)
		t.eq(p.exhibits[1].uid, "m1")
		t.truthy(p.futureField and p.futureField.kept)
		t.eq(next(p.cosmetics.owned), nil)
		local junk = ProfileRules.sanitize({
			owned = { { uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 1 } },
			cosmetics = {
				owned = { skin_wisp_candlewick = true, bogus = true },
				skins = { m1 = "skin_wisp_candlewick", m9 = "skin_wisp_candlewick" },
				auras = { m1 = "aura_motes" },
				theme = "theme_bone",
				placements = { { key = "d1", id = "deco_pumpkin", x = -44, z = 26, rot = 0 } },
				receipts = { "r1", 5 :: any },
			},
		}, now)
		local c = junk.cosmetics
		t.truthy(c.owned.skin_wisp_candlewick and not c.owned.bogus)
		t.eq(c.skins.m1, "skin_wisp_candlewick")
		t.eq(c.skins.m9, nil, "released ghost's skin dropped")
		t.eq(c.auras.m1, nil, "unowned aura dropped")
		t.eq(c.theme, nil, "unowned theme dropped")
		t.eq(#c.placements, 0, "unowned decoration dropped")
		t.eq(#c.receipts, 1)
		t.truthy(ProfileRules.isNewerSchema({ schema = 3 }), "a newer schema stays read-only")
	end)
end
