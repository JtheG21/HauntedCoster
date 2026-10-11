--!strict
-- Pure Convergence Gate rules (TASK-0005). No Instances, so tests/luau can cover them.

local GateRules = {}

-- Powers this gate actually asks for in this match: the gate's configured powers that belong to a
-- faction currently present. Empty means no present faction can open it (Echo Shrine only).
function GateRules.requirements(gatePowers: { string }, presentFactions: { string }): { string }
	local result = {}
	for _, power in gatePowers do
		if table.find(presentFactions, power) then
			table.insert(result, power)
		end
	end
	return result
end

-- True when every required power was applied within `window` seconds of `now`.
-- A power with no recorded time, or a time in the future or NaN, doesn't count.
function GateRules.canOpen(
	required: { string },
	lastApplied: { [string]: number },
	now: number,
	window: number
): boolean
	if #required == 0 then
		return false
	end
	for _, power in required do
		local t = lastApplied[power]
		if t == nil or t ~= t or t > now or now - t > window then
			return false
		end
	end
	return true
end

-- Whether the Echo Shrine bypass should be open: the first arrival is known, the gate is still
-- closed, and the delay has passed.
function GateRules.shrineDue(firstArrival: number?, gateOpen: boolean, now: number, delay: number): boolean
	if gateOpen or firstArrival == nil or firstArrival ~= firstArrival then
		return false
	end
	return now - firstArrival >= delay
end

-- Echo charges a player earns for passing one opening: exactly one per opening power, and only the
-- first time they pass that opening.
function GateRules.awardFor(openingPowers: { string }, alreadyAwarded: boolean): { string }
	if alreadyAwarded then
		return {}
	end
	return table.clone(openingPowers)
end

-- Shinobi clone input (audit F1). A clone counts only when it ARRIVES after the last opening:
-- once an opening consumes it, the same clone standing on the plate never counts again; it must
-- leave and come back. Returns the new (seenAt, consumed).
function GateRules.cloneInput(present: boolean, consumed: boolean, seenAt: number?, now: number): (number?, boolean)
	if not present then
		return seenAt, false
	end
	if consumed then
		return nil, true
	end
	return now, false
end

return GateRules
