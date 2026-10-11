--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProfileRules = require(ReplicatedStorage.Shared.Rules.ProfileRules)

return function(t: TestRunner.T)
	local now = 1_800_000_000

	t.test("nil gives a clean default with no repairs", function()
		local p, repaired = ProfileRules.sanitize(nil, now)
		t.eq(p.coins, 0)
		t.eq(#p.owned, 0)
		t.eq(#repaired, 0)
		t.eq(p.schema, ProfileRules.Schema)
	end)

	t.test("garbage root is replaced and reported", function()
		local p, repaired = ProfileRules.sanitize("lol", now)
		t.eq(p.coins, 0)
		t.eq(repaired[1], "root")
	end)

	t.test("numbers are clamped and NaN rejected", function()
		local p = ProfileRules.sanitize({ coins = -50, speedLevel = 99, houseTier = 0 / 0 }, now)
		t.eq(p.coins, 0)
		t.eq(p.speedLevel, 3)
		t.eq(p.houseTier, 0)
		local q = ProfileRules.sanitize({ coins = 12.7 }, now)
		t.eq(q.coins, 12)
	end)

	t.test("unknown species and duplicate uids are dropped", function()
		local p = ProfileRules.sanitize({
			owned = {
				{ uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 5 },
				{ uid = "m1", species = "Hound", variant = "Normal", acquiredAt = 5 },
				{ uid = "m2", species = "Dragon", variant = "Normal", acquiredAt = 5 },
				{ uid = "m7", species = "Hound", variant = "Bogus", acquiredAt = now + 999 },
			},
		}, now)
		t.eq(#p.owned, 2)
		t.eq(p.owned[2].variant, "Normal")
		t.eq(p.owned[2].acquiredAt, now)
		t.eq(p.nextUid, 8)
	end)

	t.test("owned monsters are always marked caught", function()
		local p =
			ProfileRules.sanitize({ owned = { { uid = "m1", species = "Gentleman", variant = "Spectral" } } }, now)
		t.eq(p.journal.caught.Gentleman, true)
		t.eq(p.journal.variants["Gentleman:Spectral"], true)
	end)

	t.test("unknown top-level fields are preserved", function()
		local p = ProfileRules.sanitize({ futureThing = { a = 1 } }, now)
		t.eq((p :: any).futureThing.a, 1)
	end)

	t.test("exhibits must reference owned monsters in unlocked slots", function()
		local p = ProfileRules.sanitize({
			houseTier = 0,
			owned = { { uid = "m1", species = "Wisp" }, { uid = "m2", species = "Hound" } },
			exhibits = { { slot = 1, uid = "m1" }, { slot = 3, uid = "m2" }, { slot = 2, uid = "m9" } },
		}, now)
		t.eq(#p.exhibits, 1)
		t.eq(p.exhibits[1].uid, "m1")
	end)

	t.test("bad route is discarded, good route kept", function()
		local bad = ProfileRules.sanitize({ route = { points = { { x = "a", z = 1 } } } }, now)
		t.eq(bad.route, nil)
		local good = ProfileRules.sanitize({
			route = {
				points = { { x = 1, z = 2 }, { x = 3, z = 4 } },
				pieces = { { i = 1, kind = "ScareArch" }, { i = 9, kind = "ScareArch" } },
			},
		}, now)
		t.truthy(good.route)
		t.eq(#(good.route :: any).pieces, 1)
	end)

	t.test("unknown flags are dropped", function()
		local p = ProfileRules.sanitize({ flags = { shortcut = true, godMode = true } }, now)
		t.eq(p.flags.shortcut, true)
		t.eq(p.flags.godMode, nil)
	end)
end
