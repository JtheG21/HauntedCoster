--!strict
-- Pure rules for the rare capture finisher's reduce-effects option (TASK-0054): how much weaker
-- flashes, shake and particle rates get. Kept free of Roblox services so Lune can test them.

local FinisherRules = {}

FinisherRules.REDUCED = { flash = 0.25, shake = 0.2, rate = 0.5, fovSwing = 0.5, brightness = 0.4, bolt = 0.5 }

-- Returns the strength/amplitude/rate to use for a cue param, given the reduce-effects setting.
function FinisherRules.scale(
	kind: "flash" | "shake" | "rate" | "fovSwing" | "brightness" | "bolt",
	value: number,
	reduced: boolean
): number
	if not reduced then
		return value
	end
	return value * FinisherRules.REDUCED[kind]
end

-- Field of view for a camera cue; reduced mode keeps half of the swing away from the base FOV.
function FinisherRules.fov(base: number, target: number, reduced: boolean): number
	return base + (target - base) * FinisherRules.scale("fovSwing", 1, reduced)
end

-- The orb's orbit around the captured monster: it starts slow and wide, and both its spin and its
-- tightening grow exponentially until the orbit is too small and fast to hold. The orbit plane also
-- tumbles about the X, Y and Z axes (rates tied to the spin), so the orb sweeps all the way around the
-- monster. The combined angular rate is capped near 0.4 rad per frame at 60 fps so it stays smooth.
FinisherRules.ORBIT =
	{ w0 = 1.2, w1 = 18, r0 = 7, r1 = 1.6, size0 = 2.2, size1 = 2.8, tumbleX = 0.2, tumbleY = 0.14, tumbleZ = 0.1 }

export type OrbitState = {
	x: number,
	y: number,
	z: number,
	ax: number,
	ay: number,
	az: number,
	angle: number,
	radius: number,
	size: number,
	speed: number,
	u: number,
}

-- t seconds into an orbit of total length `total`; x, y, z is the offset from the monster's centre.
function FinisherRules.orbit(t: number, total: number): OrbitState
	local o = FinisherRules.ORBIT
	local u = math.clamp(t / total, 0, 1)
	local k = math.log(o.w1 / o.w0)
	local angle = o.w0 * total / k * (math.exp(k * u) - 1)
	local radius = o.r0 * (o.r1 / o.r0) ^ u
	-- circle in the XY plane, then tumble about X, Y and Z
	local x, y, z = math.cos(angle) * radius, math.sin(angle) * radius, 0
	local ax, ay, az = angle * o.tumbleX + 0.6, angle * o.tumbleY + 0.9, angle * o.tumbleZ
	local y1 = y * math.cos(ax) - z * math.sin(ax)
	local z1 = y * math.sin(ax) + z * math.cos(ax)
	local x2 = x * math.cos(ay) + z1 * math.sin(ay)
	local z2 = -x * math.sin(ay) + z1 * math.cos(ay)
	local x3 = x2 * math.cos(az) - y1 * math.sin(az)
	local y3 = x2 * math.sin(az) + y1 * math.cos(az)
	return {
		x = x3,
		y = y3,
		z = z2,
		ax = ax,
		ay = ay,
		az = az,
		angle = angle,
		radius = radius,
		size = o.size0 + (o.size1 - o.size0) * u * u,
		speed = o.w0 * math.exp(k * u),
		u = u,
	}
end

-- Smooth 0..1 ease with zero slope at both ends.
function FinisherRules.smoothstep(k: number): number
	local x = math.clamp(k, 0, 1)
	return x * x * (3 - 2 * x)
end

-- One component of a cubic Hermite curve: leaves p0 with velocity m0 and arrives at p1 with velocity m1
-- (velocities are per whole curve, i.e. already multiplied by its duration). Used for the orb's
-- break-off so it keeps the speed and direction it had on the orbit instead of jumping onto a new path.
function FinisherRules.hermite(p0: number, m0: number, p1: number, m1: number, k: number): number
	local k2 = k * k
	local k3 = k2 * k
	return (2 * k3 - 3 * k2 + 1) * p0 + (k3 - 2 * k2 + k) * m0 + (-2 * k3 + 3 * k2) * p1 + (k3 - k2) * m1
end

return FinisherRules
