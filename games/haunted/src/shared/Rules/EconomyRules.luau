--!strict
-- Pure economy rules: passive income, offline income, purchases and movement speed.

local Shared = script.Parent.Parent
local Economy = require(Shared.Config.Economy)
local Monsters = require(Shared.Config.Monsters)
local Variants = require(Shared.Config.Variants)
local ProfileRules = require(script.Parent.ProfileRules)

type Profile = ProfileRules.Profile
type OwnedMonster = ProfileRules.OwnedMonster

local EconomyRules = {}

function EconomyRules.fullRate(m: OwnedMonster): number
	local species = Monsters.Species[m.species]
	if not species then
		return 0
	end
	return species.incomePerSecond * Variants.multiplier(m.variant)
end

-- Seconds of acclimation left (0 = earning).
function EconomyRules.acclimationLeft(m: OwnedMonster, now: number): number
	return math.max(0, Economy.AcclimationSeconds - (now - m.acquiredAt))
end

-- Passive income per second. Monsters on exhibit work the attraction instead of earning here.
function EconomyRules.incomeRate(p: Profile, now: number): number
	local total = 0
	for _, m in p.owned do
		if ProfileRules.exhibitSlotOf(p, m.uid) == nil and EconomyRules.acclimationLeft(m, now) <= 0 then
			total += EconomyRules.fullRate(m)
		end
	end
	return total
end

-- Capped offline income for tiers that unlock it. Invalid or future timestamps earn nothing.
function EconomyRules.offlineIncome(p: Profile, now: number): (number, number)
	local tier = Economy.HouseTiers[p.houseTier + 1]
	if not tier or not tier.offlineIncome or p.lastSeen <= 0 or p.lastSeen > now then
		return 0, 0
	end
	local seconds = math.min(now - p.lastSeen, Economy.OfflineCapSeconds)
	-- Every monster has long since acclimated while the player was away.
	local rate = EconomyRules.incomeRate(p, now + Economy.AcclimationSeconds)
	return math.floor(rate * seconds * Economy.OfflineRate), seconds
end

export type PurchaseQuote = { ok: boolean, reason: string?, cost: number }

function EconomyRules.quote(p: Profile, item: string): PurchaseQuote
	if item == "speed" then
		local cost = Economy.SpeedLevelCosts[p.speedLevel + 1]
		if not cost then
			return { ok = false, reason = "Speed is maxed out", cost = 0 }
		end
		if p.coins < cost then
			return { ok = false, reason = `Need {cost - p.coins} more coins`, cost = cost }
		end
		return { ok = true, cost = cost }
	elseif item == "house" then
		local nextTier = Economy.HouseTiers[p.houseTier + 2]
		if not nextTier then
			return { ok = false, reason = "Your mansion is fully upgraded", cost = 0 }
		end
		if p.coins < nextTier.cost then
			return { ok = false, reason = `Need {nextTier.cost - p.coins} more coins`, cost = nextTier.cost }
		end
		return { ok = true, cost = nextTier.cost }
	end
	return { ok = false, reason = "Unknown item", cost = 0 }
end

-- Applies a purchase in place. Returns false (and changes nothing) when the quote fails.
function EconomyRules.purchase(p: Profile, item: string): (boolean, string?)
	local q = EconomyRules.quote(p, item)
	if not q.ok then
		return false, q.reason
	end
	p.coins -= q.cost
	if item == "speed" then
		p.speedLevel += 1
	else
		p.houseTier += 1
	end
	return true, nil
end

function EconomyRules.carryMultiplier(speedLevel: number): number
	local m = Economy.CarrySpeedMultipliers
	return m[math.clamp(math.floor(speedLevel), 0, #m - 1) + 1]
end

function EconomyRules.walkSpeed(speedLevel: number, carrying: boolean): number
	local base = Economy.BaseWalkSpeed + Economy.SpeedPerLevel * speedLevel
	return if carrying then base * EconomyRules.carryMultiplier(speedLevel) else base
end

function EconomyRules.addCoins(p: Profile, amount: number)
	p.coins = math.clamp(math.floor(p.coins + amount), 0, Economy.MaxCoins)
end

return EconomyRules
