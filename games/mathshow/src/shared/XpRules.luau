--!strict
-- Pure XP maths: levels, the daily play cap, top-three selection and day classification.
-- No Instances, no services, no clock or Random: time arrives as an argument. Nothing throws on bad input.

local XpConfig = require(script.Parent.XpConfig)

export type DayClass = "current" | "adjacentAhead" | "behind" | "invalid"
export type Participant = { userId: number, score: number, eligible: boolean }

local XpRules = {}

local function isInt(v: any): boolean
	return typeof(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge and v == math.floor(v)
end

local function finite(v: any): boolean
	return typeof(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

-- XP needed to go from level `level` to `level + 1`.
function XpRules.costOf(level: number): number
	return XpConfig.LevelBaseCost + XpConfig.LevelStepCost * (level - 1)
end

-- Total XP at which `level` is reached (level 1 = 0). Out-of-range or non-integer levels clamp to 1..LevelCap.
function XpRules.totalXpForLevel(level: number): number
	if not finite(level) then
		return 0
	end
	local l = math.clamp(math.floor(level), 1, XpConfig.LevelCap)
	local steps = l - 1
	return XpConfig.LevelBaseCost * steps + XpConfig.LevelStepCost * steps * (steps - 1) // 2
end

function XpRules.levelForXp(xp: number): number
	if not finite(xp) or xp <= 0 then
		return 1
	end
	local whole = math.floor(xp)
	local level = 1
	while level < XpConfig.LevelCap and whole >= XpRules.totalXpForLevel(level + 1) do
		level += 1
	end
	return level
end

-- XP earned inside the current level; 0 at the cap (the bar shows MAX).
function XpRules.xpIntoLevel(xp: number): number
	local level = XpRules.levelForXp(xp)
	if level >= XpConfig.LevelCap then
		return 0
	end
	if not finite(xp) or xp <= 0 then
		return 0
	end
	return math.floor(xp) - XpRules.totalXpForLevel(level)
end

-- XP still needed for the next level; 0 at the cap.
function XpRules.xpForNextLevel(xp: number): number
	local level = XpRules.levelForXp(xp)
	if level >= XpConfig.LevelCap then
		return 0
	end
	return XpRules.costOf(level)
end

-- The play XP actually granted: min(nominal, remaining cap). Invalid or out-of-range inputs award 0.
function XpRules.playAward(storedAmount: number, nominal: number): number
	if not isInt(storedAmount) or not isInt(nominal) or storedAmount < 0 or nominal < 0 then
		return 0
	end
	return math.min(nominal, math.max(0, XpConfig.PlayCap - storedAmount))
end

-- At most three userIds of eligible, positive-score participants: score descending, then userId ascending.
function XpRules.top3(participants: { Participant }): { number }
	local pool: { Participant } = {}
	for _, p in participants do
		if typeof(p) == "table" and p.eligible == true and finite(p.score) and p.score > 0 and isInt(p.userId) then
			table.insert(pool, p)
		end
	end
	table.sort(pool, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.userId < b.userId
	end)
	local out: { number } = {}
	for i = 1, math.min(3, #pool) do
		out[i] = pool[i].userId
	end
	return out
end

-- UTC day number of a wall-clock second count; nil for a non-finite or negative value.
function XpRules.dayOf(wallSeconds: number): number?
	if not finite(wallSeconds) or wallSeconds < 0 then
		return nil
	end
	return math.floor(wallSeconds / XpConfig.SecondsPerDay)
end

-- Compares a stored daily epoch with this server's clock. "adjacentAhead" is a stored day ahead of the local day that is
-- still within the skew bound: floor((wall + DailySkewSeconds) / 86400). Anything else ahead is "invalid".
function XpRules.classifyDay(storedEpoch: number, localWall: number): DayClass
	local localDay = XpRules.dayOf(localWall)
	if localDay == nil or not isInt(storedEpoch) or storedEpoch < 0 then
		return "invalid"
	end
	if storedEpoch == localDay then
		return "current"
	end
	if storedEpoch < localDay then
		return "behind"
	end
	if storedEpoch == math.floor((localWall + XpConfig.DailySkewSeconds) / XpConfig.SecondsPerDay) then
		return "adjacentAhead"
	end
	return "invalid"
end

return XpRules
