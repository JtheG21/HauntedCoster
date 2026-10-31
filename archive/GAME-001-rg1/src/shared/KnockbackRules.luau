--!strict
-- Pure charge and knockback math (TASK-0004). Reused by the finale (TASK-0007).

local KnockbackRules = {}

export type ChargeConfig = {
	MinChargeSeconds: number,
	MaxChargeSeconds: number,
	StaleChargeSeconds: number,
}

-- Charge fraction 0..1 from server-measured times. No recorded start, a NaN, a negative duration or
-- a stale start all give 0 (minimum power), so a client can never claim a full charge.
function KnockbackRules.chargeFraction(startedAt: number?, now: number, config: ChargeConfig): number
	if startedAt == nil or startedAt ~= startedAt or now ~= now then
		return 0
	end
	local held = now - startedAt
	if held < 0 or held > config.StaleChargeSeconds then
		return 0
	end
	local span = config.MaxChargeSeconds - config.MinChargeSeconds
	if span <= 0 then
		return if held >= config.MaxChargeSeconds then 1 else 0
	end
	return math.clamp((held - config.MinChargeSeconds) / span, 0, 1)
end

function KnockbackRules.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

-- Horizontal push direction from `from` to `to`; falls back to `fallback` when they overlap.
function KnockbackRules.pushDirection(from: Vector3, to: Vector3, fallback: Vector3): Vector3
	local flat = Vector3.new(to.X - from.X, 0, to.Z - from.Z)
	if flat.Magnitude < 1e-3 then
		local f = Vector3.new(fallback.X, 0, fallback.Z)
		return if f.Magnitude < 1e-3 then Vector3.new(0, 0, -1) else f.Unit
	end
	return flat.Unit
end

-- True if `point` is within `range` studs and in front of the origin (angle under 90 degrees).
function KnockbackRules.inFront(origin: Vector3, look: Vector3, point: Vector3, range: number): boolean
	local offset = point - origin
	if offset.Magnitude > range then
		return false
	end
	local flatLook = Vector3.new(look.X, 0, look.Z)
	local flatOffset = Vector3.new(offset.X, 0, offset.Z)
	if flatLook.Magnitude < 1e-3 or flatOffset.Magnitude < 1e-3 then
		return true
	end
	return flatLook.Unit:Dot(flatOffset.Unit) > 0
end

return KnockbackRules
