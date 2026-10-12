--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local EconomyRules = require(Shared.Rules.EconomyRules)
local ProfileRules = require(Shared.Rules.ProfileRules)
local Economy = require(Shared.Config.Economy)

return function(t: TestRunner.T)
	local now = 1_800_000_000

	local function withOwned(list: { any }): ProfileRules.Profile
		local p = ProfileRules.default()
		p.owned = list
		return p
	end

	t.test("no income while acclimating", function()
		local p = withOwned({ { uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = now } })
		t.eq(EconomyRules.incomeRate(p, now + Economy.AcclimationSeconds - 1), 0)
		t.eq(EconomyRules.incomeRate(p, now + Economy.AcclimationSeconds), 1)
	end)

	t.test("variant multiplier applies", function()
		local p = withOwned({ { uid = "m1", species = "Wisp", variant = "Spectral", acquiredAt = 0 } })
		t.eq(EconomyRules.incomeRate(p, now), 1.5)
	end)

	t.test("exhibited monsters don't earn passive income", function()
		local p = withOwned({ { uid = "m1", species = "Hound", variant = "Normal", acquiredAt = 0 } })
		p.exhibits = { { slot = 1, uid = "m1" } }
		t.eq(EconomyRules.incomeRate(p, now), 0)
	end)

	t.test("purchase checks funds and applies once", function()
		local p = ProfileRules.default()
		p.coins = 74
		local ok, reason = EconomyRules.purchase(p, "speed")
		t.eq(ok, false)
		t.truthy(reason)
		t.eq(p.coins, 74)
		p.coins = 75
		t.eq((EconomyRules.purchase(p, "speed")), true)
		t.eq(p.coins, 0)
		t.eq(p.speedLevel, 1)
	end)

	t.test("house tier purchase and max tier", function()
		local p = ProfileRules.default()
		p.coins = 100000
		t.eq((EconomyRules.purchase(p, "house")), true)
		t.eq((EconomyRules.purchase(p, "house")), true)
		t.eq(p.houseTier, 2)
		t.eq((EconomyRules.purchase(p, "house")), false)
		t.eq((EconomyRules.purchase(p, "rocket")), false)
	end)

	t.test("speed maxes out", function()
		local p = ProfileRules.default()
		p.coins = 100000
		for _ = 1, #Economy.SpeedLevelCosts do
			t.eq((EconomyRules.purchase(p, "speed")), true)
		end
		t.eq((EconomyRules.purchase(p, "speed")), false)
	end)

	t.test("offline income: tier 2 only, capped, no future timestamps", function()
		local p = withOwned({ { uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = 0 } })
		p.lastSeen = now - 100
		t.eq((EconomyRules.offlineIncome(p, now)), 0)
		p.houseTier = 2
		t.eq((EconomyRules.offlineIncome(p, now)), math.floor(1 * 100 * Economy.OfflineRate))
		p.lastSeen = now - 10 * Economy.OfflineCapSeconds
		t.eq((EconomyRules.offlineIncome(p, now)), math.floor(Economy.OfflineCapSeconds * Economy.OfflineRate))
		p.lastSeen = now + 500
		t.eq((EconomyRules.offlineIncome(p, now)), 0)
		p.lastSeen = 0
		t.eq((EconomyRules.offlineIncome(p, now)), 0)
	end)

	t.test("carrying slows movement", function()
		t.eq(EconomyRules.walkSpeed(0, false), Economy.BaseWalkSpeed)
		t.eq(EconomyRules.walkSpeed(0, true), Economy.BaseWalkSpeed * 0.6)
		t.eq(EconomyRules.walkSpeed(2, false), Economy.BaseWalkSpeed + 2 * Economy.SpeedPerLevel)
	end)

	t.test("running shoes shrink the carry penalty level by level (Round 20 Q3)", function()
		local last = 0
		for i = 1, #Economy.SpeedLevelCosts + 1 do
			local level = i - 1
			local m = EconomyRules.carryMultiplier(level)
			t.truthy(m > last, `level {level} penalty is smaller than the level below`)
			last = m
		end
		t.eq(EconomyRules.carryMultiplier(#Economy.SpeedLevelCosts), 0.9)
		-- Out-of-range levels clamp instead of erroring.
		t.eq(EconomyRules.carryMultiplier(-1), 0.6)
		t.eq(EconomyRules.carryMultiplier(99), 0.9)
		t.truthy(
			EconomyRules.walkSpeed(3, true) < EconomyRules.walkSpeed(0, false) + 6,
			"still slower than running free"
		)
	end)
end
