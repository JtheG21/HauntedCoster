--!strict
-- Pure faction assignment rules (TASK-0003).

local FactionRules = {}

-- The faction with the fewest members; ties go to the earliest in `order`.
function FactionRules.pickBalanced(counts: { [string]: number }, order: { string }): string
	local best = order[1]
	local bestCount = math.huge
	for _, faction in order do
		local count = counts[faction] or 0
		if count < bestCount then
			best, bestCount = faction, count
		end
	end
	return best
end

-- True when every active faction's count is within 1 of every other.
function FactionRules.isBalanced(counts: { [string]: number }, order: { string }): boolean
	local low, high = math.huge, -math.huge
	for _, faction in order do
		local count = counts[faction] or 0
		low = math.min(low, count)
		high = math.max(high, count)
	end
	return #order == 0 or high - low <= 1
end

-- If counts differ by more than 1, the move that fixes it: one player from the largest faction
-- (ties: latest in order) to the smallest (ties: earliest in order). Returns nil when balanced.
function FactionRules.rebalanceMove(counts: { [string]: number }, order: { string }): (string?, string?)
	if FactionRules.isBalanced(counts, order) then
		return nil, nil
	end
	local from, fromCount = nil, -math.huge
	for _, faction in order do
		local count = counts[faction] or 0
		if count >= fromCount then
			from, fromCount = faction, count
		end
	end
	return from, FactionRules.pickBalanced(counts, order)
end

return FactionRules
