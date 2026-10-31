--!strict
-- Pure tier ladder: nine stable string ids in order. No Instances, no yields. Not wired into gameplay yet; the
-- numeric RankRules of the prototype is untouched.

local TierConfig = require(script.Parent.TierConfig)

export type TierId = string
export type Display = { value: number, max: number?, hasNext: boolean }

local IDS = TierConfig.Ids
local INDEX: { [string]: number } = {}
for i, id in IDS do
	INDEX[id] = i
end

local TierRules = {}

function TierRules.isValid(id: any): boolean
	return type(id) == "string" and INDEX[id] ~= nil
end

function TierRules.indexOf(id: any): number?
	if type(id) ~= "string" then
		return nil
	end
	return INDEX[id]
end

function TierRules.at(index: any): TierId?
	if type(index) ~= "number" or index ~= index or index % 1 ~= 0 then
		return nil
	end
	return IDS[index]
end

-- nil for demon (top) and for an unknown id.
function TierRules.next(id: any): TierId?
	local i = TierRules.indexOf(id)
	return if i then IDS[i + 1] else nil
end

-- nil for plastic (bottom) and for an unknown id.
function TierRules.prev(id: any): TierId?
	local i = TierRules.indexOf(id)
	return if i then IDS[i - 1] else nil
end

-- -1 / 0 / 1 like a sort comparator; nil when either id is unknown.
function TierRules.compare(a: any, b: any): number?
	local ia, ib = TierRules.indexOf(a), TierRules.indexOf(b)
	if not ia or not ib then
		return nil
	end
	return if ia < ib then -1 elseif ia > ib then 1 else 0
end

-- Bar value for tiers 1-8: progress clamped to 0..ProgressPerTier with a next tier. Demon has a standing value with
-- no cap and no next tier. NaN, negative, infinite and non-number input clamp to 0 (or the cap); never errors.
function TierRules.progressDisplay(id: any, progress: any): Display
	local value = 0
	if type(progress) == "number" and progress == progress then
		value = math.max(progress, 0)
	end
	if id == "demon" then
		return { value = if value == math.huge then 0 else math.floor(value), max = nil, hasNext = false }
	end
	local max = TierConfig.ProgressPerTier
	return { value = math.min(value, max), max = max, hasNext = TierRules.isValid(id) }
end

return TierRules
