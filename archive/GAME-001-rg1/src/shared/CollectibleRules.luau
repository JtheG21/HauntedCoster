--!strict
-- Pure rules for collectibles. No Instances, so they can be unit-tested (tests/luau).

local CollectibleRules = {}

export type PickupCheck = {
	coinActive: boolean,
	isPlayerCharacter: boolean,
	humanoidHealth: number?,
	distance: number?,
	maxDistance: number,
}

-- Returns whether a touch may collect the coin, plus a reason when it may not.
function CollectibleRules.canCollect(check: PickupCheck): (boolean, string?)
	if not check.coinActive then
		return false, "inactive"
	end
	if not check.isPlayerCharacter then
		return false, "not_character"
	end
	local health = check.humanoidHealth
	if health == nil or health <= 0 then
		return false, "dead"
	end
	local distance = check.distance
	-- distance ~= distance catches NaN
	if distance == nil or distance ~= distance or distance > check.maxDistance then
		return false, "too_far"
	end
	return true, nil
end

-- New balance after an award. Non-positive or fractional values never reduce the balance.
function CollectibleRules.award(current: number, value: number): number
	return current + math.max(0, math.floor(value))
end

-- Evenly spaced positions on a circle around the center (deterministic).
function CollectibleRules.spawnPosition(index: number, count: number, center: Vector3, radius: number): Vector3
	local angle = (index - 1) / math.max(count, 1) * 2 * math.pi
	return center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
end

return CollectibleRules
