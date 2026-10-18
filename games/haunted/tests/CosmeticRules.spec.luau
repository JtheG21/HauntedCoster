--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CosmeticRules = require(ReplicatedStorage.Shared.Rules.CosmeticRules)
local ProfileRules = require(ReplicatedStorage.Shared.Rules.ProfileRules)
local Catalog = require(ReplicatedStorage.Shared.Config.Catalog)

-- A test catalog: the shipped one is empty until the launch assortment is approved.
local cat: CosmeticRules.Catalog = {
	Items = {
		WispSkin = { category = "Skin", species = { "Wisp" } },
		AnySkin = { category = "Skin" },
		GlowAura = { category = "Aura" },
		SparkFx = { category = "CaptureEffect" },
		MossTheme = { category = "Theme", tiers = { 0, 1 } },
		Lantern = { category = "Decoration", placementLimit = 2 },
		Bench = { category = "Decoration" },
	},
	Rewards = {
		HabitatOne = { grants = { "MossTheme", "Lantern" } },
		Broken = { grants = { "Missing" } },
	},
}

local function has(list: { string }, name: string): boolean
	return table.find(list, name) ~= nil
end

local function cosmeticRepairs(list: { string }): number
	local n = 0
	for _, name in list do
		if string.sub(name, 1, 9) == "cosmetics" then
			n += 1
		end
	end
	return n
end

return function(t: TestRunner.T)
	local now = 1_800_000_000

	t.test("shipped catalog has only sample looks and no products", function()
		for id, item in Catalog.Items do
			t.truthy(
				item.category == "Skin"
					or item.category == "Aura"
					or item.category == "CaptureEffect"
					or item.category == "Theme",
				`{id} is not a sample look`
			)
			t.eq((item :: any).price, nil)
			t.eq((item :: any).product, nil)
		end
		for id, reward in Catalog.Rewards do
			t.truthy(#reward.grants > 0, `{id} grants nothing`)
			t.eq((reward :: any).price, nil)
		end
	end)

	t.test("defaults are empty and unequipped", function()
		local s = CosmeticRules.default()
		t.eq(next(s.entitlements), nil)
		t.eq(next(s.ghostLooks), nil)
		t.eq(s.captureEffect, nil)
		t.eq(s.mansionTheme, nil)
		t.eq(#s.placements, 0)
		t.eq(next(s.rewardsClaimed), nil)
	end)

	t.test("grant is catalog-only and idempotent", function()
		local s = CosmeticRules.default()
		t.eq((CosmeticRules.grant(s, cat, "Nope")), false)
		t.eq((CosmeticRules.grant(s, cat, "AnySkin")), true)
		local ok, why = CosmeticRules.grant(s, cat, "AnySkin")
		t.eq(ok, true)
		t.eq(why, "alreadyOwned")
		t.eq(CosmeticRules.owns(s, "AnySkin"), true)
	end)

	t.test("skins and auras are per ghost, independent, and need ownership and compatibility", function()
		local s = CosmeticRules.default()
		local _, why = CosmeticRules.equipLook(s, cat, "m1", "Wisp", "skin", "WispSkin")
		t.eq(why, "notOwned")
		CosmeticRules.grant(s, cat, "WispSkin")
		CosmeticRules.grant(s, cat, "GlowAura")
		_, why = CosmeticRules.equipLook(s, cat, "m2", "Hound", "skin", "WispSkin")
		t.eq(why, "incompatible")
		_, why = CosmeticRules.equipLook(s, cat, "m9", nil, "skin", "WispSkin")
		t.eq(why, "noGhost")
		_, why = CosmeticRules.equipLook(s, cat, "m1", "Wisp", "aura", "WispSkin")
		t.eq(why, "wrongCategory")
		t.eq((CosmeticRules.equipLook(s, cat, "m1", "Wisp", "skin", "WispSkin")), true)
		t.eq((CosmeticRules.equipLook(s, cat, "m3", "Wisp", "skin", "WispSkin")), true) -- reused, no re-buy
		t.eq((CosmeticRules.equipLook(s, cat, "m1", "Wisp", "aura", "GlowAura")), true)
		CosmeticRules.removeLook(s, "m1", "skin")
		t.eq(s.ghostLooks.m1.skin, nil)
		t.eq(s.ghostLooks.m1.aura, "GlowAura")
		CosmeticRules.removeLook(s, "m1", "aura")
		t.eq(s.ghostLooks.m1, nil)
		t.eq(CosmeticRules.owns(s, "WispSkin"), true) -- removing keeps ownership
	end)

	t.test("capture effect is player-wide and clearable", function()
		local s = CosmeticRules.default()
		t.eq((CosmeticRules.setCaptureEffect(s, cat, "SparkFx")), false)
		CosmeticRules.grant(s, cat, "SparkFx")
		t.eq((CosmeticRules.setCaptureEffect(s, cat, "SparkFx")), true)
		t.eq(s.captureEffect, "SparkFx")
		CosmeticRules.setCaptureEffect(s, cat, nil)
		t.eq(s.captureEffect, nil)
	end)

	t.test("theme equip checks tier coverage", function()
		local s = CosmeticRules.default()
		CosmeticRules.grant(s, cat, "MossTheme")
		local _, why = CosmeticRules.setTheme(s, cat, "MossTheme", 2)
		t.eq(why, "tier")
		t.eq((CosmeticRules.setTheme(s, cat, "MossTheme", 1)), true)
		t.eq(s.mansionTheme, "MossTheme")
	end)

	t.test("decorations are reusable up to their limit, inside the plot, on right angles", function()
		local s = CosmeticRules.default()
		CosmeticRules.grant(s, cat, "Lantern")
		CosmeticRules.grant(s, cat, "Bench")
		t.eq((CosmeticRules.place(s, cat, "Lantern", 0, 0, 0)), true)
		t.eq((CosmeticRules.place(s, cat, "Lantern", 5, 5, 90)), true)
		local _, why = CosmeticRules.place(s, cat, "Lantern", 6, 6, 0)
		t.eq(why, "limit")
		_, why = CosmeticRules.place(s, cat, "Bench", CosmeticRules.HalfX + 1, 0, 0)
		t.eq(why, "outOfPlot")
		_, why = CosmeticRules.place(s, cat, "Bench", 0, 0, 45)
		t.eq(why, "rotation")
		_, why = CosmeticRules.place(s, cat, "Bench", 0 / 0, 0, 0)
		t.eq(why, "outOfPlot")
		t.eq((CosmeticRules.place(s, cat, "Bench", 1, 1, 270)), true)
		_, why = CosmeticRules.place(s, cat, "Bench", 2, 2, 0)
		t.eq(why, "limit") -- default limit 1
		t.eq((CosmeticRules.removePlacement(s, 1)), true)
		t.eq((CosmeticRules.place(s, cat, "Lantern", 7, 7, 180)), true) -- stored copy is placeable again
		t.eq((CosmeticRules.removePlacement(s, 99)), false)
	end)

	t.test("a reward is claimed once and grants its items", function()
		local s = CosmeticRules.default()
		t.eq((CosmeticRules.claimReward(s, cat, "HabitatOne")), true)
		t.eq(CosmeticRules.owns(s, "MossTheme"), true)
		t.eq(CosmeticRules.owns(s, "Lantern"), true)
		local _, why = CosmeticRules.claimReward(s, cat, "HabitatOne")
		t.eq(why, "claimed")
		_, why = CosmeticRules.claimReward(s, cat, "Broken")
		t.eq(why, "badReward")
		t.eq(s.rewardsClaimed.Broken, nil)
		_, why = CosmeticRules.claimReward(s, cat, "Nope")
		t.eq(why, "unknown")
	end)

	-- Profile round trip with cosmetics.
	local owned = {
		{ uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 5 },
		{ uid = "m2", species = "Hound", variant = "Normal", acquiredAt = 5 },
	}

	t.test("schema-1 profile migrates to the current schema with empty cosmetics, data intact", function()
		local p, repaired =
			ProfileRules.sanitize({ schema = 1, coins = 30, owned = owned, nextUid = 3, futureThing = 1 }, now)
		t.eq(p.schema, ProfileRules.Schema)
		t.eq(ProfileRules.Schema, 2)
		t.eq(p.coins, 30)
		t.eq(#p.owned, 2)
		t.eq(next(p.cosmetics.entitlements), nil)
		t.eq(#p.cosmetics.placements, 0)
		t.eq((p :: any).futureThing, 1)
		t.eq(cosmeticRepairs(repaired), 0)
	end)

	t.test("a valid cosmetic profile survives sanitize unchanged", function()
		local raw = {
			owned = owned,
			nextUid = 3,
			cosmetics = {
				entitlements = { WispSkin = true, GlowAura = true, SparkFx = true, MossTheme = true, Lantern = true },
				ghostLooks = { m1 = { skin = "WispSkin", aura = "GlowAura" }, m2 = { aura = "GlowAura" } },
				captureEffect = "SparkFx",
				mansionTheme = "MossTheme",
				placements = { { id = "Lantern", x = 3, z = -4, r = 90 } },
				rewardsClaimed = { HabitatOne = true },
			},
		}
		local p, repaired = ProfileRules.sanitize(raw, now, cat)
		t.eq(cosmeticRepairs(repaired), 0)
		local again, repaired2 = ProfileRules.sanitize(p, now, cat)
		t.eq(#repaired2, 0)
		t.eq(again.cosmetics.ghostLooks.m1.skin, "WispSkin")
		t.eq(again.cosmetics.ghostLooks.m2.aura, "GlowAura")
		t.eq(again.cosmetics.captureEffect, "SparkFx")
		t.eq(again.cosmetics.mansionTheme, "MossTheme")
		t.eq(again.cosmetics.placements[1].r, 90)
		t.eq(again.cosmetics.rewardsClaimed.HabitatOne, true)
	end)

	t.test("corrupt cosmetic values are repaired and reported", function()
		local p, repaired = ProfileRules.sanitize({
			owned = owned,
			cosmetics = {
				entitlements = { WispSkin = true, ["bad id!"] = true, Bench = "yes", Lantern = true },
				ghostLooks = {
					m1 = { skin = "AnySkin" }, -- not owned
					m2 = { skin = "WispSkin" }, -- incompatible species
					m9 = { skin = "WispSkin" }, -- ghost not owned
				},
				captureEffect = 5,
				mansionTheme = "Lantern", -- wrong category
				placements = {
					{ id = "Lantern", x = 0, z = 0, r = 0 },
					{ id = "Lantern", x = 999, z = 0, r = 0 },
					{ id = "Lantern", x = 1, z = 1, r = 33 },
					{ id = "Bench", x = 1, z = 1, r = 0 }, -- not owned
					"junk" :: any,
				},
				rewardsClaimed = "x",
			},
		}, now, cat)
		local c = p.cosmetics
		t.eq(c.entitlements.WispSkin, true)
		t.eq(c.entitlements["bad id!"], nil)
		t.eq(c.entitlements.Bench, nil)
		t.eq(next(c.ghostLooks), nil)
		t.eq(c.captureEffect, nil)
		t.eq(c.mansionTheme, nil)
		t.eq(#c.placements, 1)
		t.eq(next(c.rewardsClaimed), nil)
		for _, name in
			{
				"cosmetics.entitlements",
				"cosmetics.ghostLooks",
				"cosmetics.captureEffect",
				"cosmetics.mansionTheme",
				"cosmetics.placements",
				"cosmetics.rewardsClaimed",
			}
		do
			t.truthy(has(repaired, name), name)
		end
		local q, r2 = ProfileRules.sanitize({ cosmetics = "lol" }, now, cat)
		t.eq(next(q.cosmetics.entitlements), nil)
		t.truthy(has(r2, "cosmetics"))
	end)

	t.test("owned items missing from the catalog are kept, never destroyed", function()
		local p = ProfileRules.sanitize({
			owned = owned,
			cosmetics = {
				entitlements = { RetiredSkin = true },
				ghostLooks = { m1 = { skin = "RetiredSkin" } },
			},
		}, now, cat)
		t.eq(p.cosmetics.entitlements.RetiredSkin, true)
		t.eq(p.cosmetics.ghostLooks.m1.skin, "RetiredSkin")
	end)

	t.test("looks for a released ghost are dropped with it", function()
		local p = ProfileRules.sanitize({
			owned = { owned[2] },
			cosmetics = { entitlements = { GlowAura = true }, ghostLooks = { m1 = { aura = "GlowAura" } } },
		}, now, cat)
		t.eq(p.cosmetics.ghostLooks.m1, nil)
		t.eq(p.cosmetics.entitlements.GlowAura, true)
	end)

	t.test("entitlement count is bounded", function()
		local many = {}
		for i = 1, Catalog.MaxEntitlements + 10 do
			many["e" .. i] = true
		end
		local p = ProfileRules.sanitize({ cosmetics = { entitlements = many } }, now, cat)
		local n = 0
		for _ in p.cosmetics.entitlements do
			n += 1
		end
		t.eq(n, Catalog.MaxEntitlements)
	end)

	t.test("a newer-schema profile with cosmetics stays read-only", function()
		local raw = { schema = ProfileRules.Schema + 1, cosmetics = { entitlements = { WispSkin = true } } }
		t.eq(ProfileRules.persistenceFor("saved", raw), "readonly")
	end)

	t.test("a reward that would overflow entitlements grants nothing (all-or-nothing)", function()
		local s = CosmeticRules.default()
		for i = 1, Catalog.MaxEntitlements - 1 do
			s.entitlements["e" .. i] = true
		end
		local _, why = CosmeticRules.claimReward(s, cat, "HabitatOne") -- needs 2 free, has 1
		t.eq(why, "full")
		t.eq(s.entitlements.MossTheme, nil)
		t.eq(s.entitlements.Lantern, nil)
		t.eq(s.rewardsClaimed.HabitatOne, nil)
		s.entitlements.MossTheme = true -- now only 1 new item is needed
		(s.entitlements :: any).e1 = nil
		t.eq((CosmeticRules.claimReward(s, cat, "HabitatOne")), true)
		t.eq(s.entitlements.Lantern, true)
	end)

	t.test("over the entitlement cap, catalog items are kept first, then sorted IDs", function()
		local many = { WispSkin = true }
		for i = 1, Catalog.MaxEntitlements + 5 do
			many[string.format("z%04d", i)] = true
		end
		local p = ProfileRules.sanitize({ cosmetics = { entitlements = many } }, now, cat)
		local e = p.cosmetics.entitlements
		t.eq(e.WispSkin, true)
		t.eq(e.z0001, true)
		t.eq(e[string.format("z%04d", Catalog.MaxEntitlements - 1)], true)
		t.eq(e[string.format("z%04d", Catalog.MaxEntitlements)], nil)
	end)

	t.test("an unknown ID fills only one kind of slot", function()
		local p, repaired = ProfileRules.sanitize({
			owned = owned,
			cosmetics = {
				entitlements = { Mystery = true },
				ghostLooks = { m1 = { skin = "Mystery" }, m2 = { skin = "Mystery", aura = "Mystery" } },
				captureEffect = "Mystery",
				mansionTheme = "Mystery",
				placements = { { id = "Mystery", x = 0, z = 0, r = 0 } },
			},
		}, now, cat)
		local c = p.cosmetics
		t.eq(c.ghostLooks.m1.skin, "Mystery")
		t.eq(c.ghostLooks.m2.skin, "Mystery") -- same kind on another ghost is fine
		t.eq(c.ghostLooks.m2.aura, nil)
		t.eq(c.captureEffect, nil)
		t.eq(c.mansionTheme, nil)
		t.eq(#c.placements, 0)
		t.eq(c.entitlements.Mystery, true)
		for _, name in
			{ "cosmetics.ghostLooks", "cosmetics.captureEffect", "cosmetics.mansionTheme", "cosmetics.placements" }
		do
			t.truthy(has(repaired, name), name)
		end
	end)

	t.test("sanitize is idempotent with an unknown ID spread across slot kinds", function()
		local raw = {
			owned = owned,
			cosmetics = {
				entitlements = { Mystery = true, Lantern = true },
				ghostLooks = { m2 = { aura = "Mystery" }, m1 = { skin = "Mystery" } },
				captureEffect = "Mystery",
				mansionTheme = "Mystery",
				placements = { { id = "Mystery", x = 0, z = 0, r = 0 }, { id = "Lantern", x = 1, z = 1, r = 0 } },
			},
		}
		local once = ProfileRules.sanitize(raw, now, cat)
		local twice, repaired = ProfileRules.sanitize(once, now, cat)
		t.eq(cosmeticRepairs(repaired), 0)
		t.eq(twice.cosmetics.ghostLooks.m1.skin, "Mystery")
		t.eq(twice.cosmetics.ghostLooks.m2, nil)
		t.eq(#twice.cosmetics.placements, 1)
		t.eq(twice.cosmetics.placements[1].id, "Lantern")
		t.eq(twice.cosmetics.captureEffect, nil)
	end)

	t.test("a lowered placement limit drops extra placements but keeps the item", function()
		local raw = {
			cosmetics = {
				entitlements = { Bench = true },
				placements = { { id = "Bench", x = 0, z = 0, r = 0 }, { id = "Bench", x = 2, z = 2, r = 0 } },
			},
		}
		local p, repaired = ProfileRules.sanitize(raw, now, cat) -- Bench limit is 1
		t.eq(#p.cosmetics.placements, 1)
		t.eq(p.cosmetics.entitlements.Bench, true)
		t.truthy(has(repaired, "cosmetics.placements"))
	end)

	t.test("removeLook rejects a bad slot", function()
		local s = CosmeticRules.default()
		local ok, why = CosmeticRules.removeLook(s, "m1", "hat")
		t.eq(ok, false)
		t.eq(why, "badSlot")
	end)
end
