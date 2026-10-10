--!strict
-- Pure ability request rules (TASK-0002). No Instances, so tests/luau can cover them.

local AbilityRules = {}

export type ActivationCheck = {
	now: number,
	lastUsed: number?,
	cooldown: number,
}

-- Validates the untrusted remote payload. Only a known ability id string with no extra args is accepted.
function AbilityRules.validateRequest(
	abilityId: unknown,
	extraArgCount: number,
	known: { [string]: any }
): (boolean, string?)
	if typeof(abilityId) ~= "string" then
		return false, "bad_type"
	end
	if #abilityId == 0 or #abilityId > 32 then
		return false, "bad_length"
	end
	if known[abilityId] == nil then
		return false, "unknown_ability"
	end
	if extraArgCount ~= 0 then
		return false, "unexpected_args"
	end
	return true, nil
end

-- Sliding-window rate limit. Returns whether this request is allowed and the pruned timestamp list
-- (including this request when allowed or not, so spam keeps counting against the window).
function AbilityRules.checkRate(
	timestamps: { number },
	now: number,
	window: number,
	maxRequests: number
): (boolean, { number })
	local kept = {}
	for _, t in timestamps do
		if now - t < window then
			table.insert(kept, t)
		end
	end
	table.insert(kept, now)
	-- Bound memory under spam: keeping maxRequests + 1 entries is enough to decide the next request.
	while #kept > maxRequests + 1 do
		table.remove(kept, 1)
	end
	return #kept <= maxRequests, kept
end

-- Cooldown check. The boundary (exactly `cooldown` seconds later) is allowed.
function AbilityRules.canActivate(check: ActivationCheck): (boolean, string?)
	local now = check.now
	if now ~= now then
		return false, "bad_clock"
	end
	local last = check.lastUsed
	if last ~= nil and now - last < check.cooldown then
		return false, "cooldown"
	end
	return true, nil
end

-- Horizontal unit direction from a look vector; falls back to forward (-Z) if the look is vertical.
function AbilityRules.horizontalDirection(look: Vector3): Vector3
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return Vector3.new(0, 0, -1)
	end
	return flat.Unit
end

return AbilityRules
