--!strict
-- Pure geometry and timing for the hub's cosmetic ambient life (TASK-0144, Map Finish B2). No Instances, no clock, no Random:
-- the caller passes uniform [0, 1) samples, so the module is deterministic and testable headless.

local AmbientRules = {}

export type Vec = { x: number, y: number, z: number }

export type StreakShape = {
	distance: number, -- studs from the camera to the streak's start
	elevationMinDegrees: number,
	elevationMaxDegrees: number,
	travel: number, -- studs flown over the streak's life
	dropFraction: number, -- fraction of the travel that is downward (0 = level, 1 = straight down)
}

export type Streak = { offset: Vec, direction: Vec } -- offset from the camera; direction is a unit vector

local function lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

local function clamp01(r: number): number
	return math.clamp(r, 0, 1)
end

-- Seconds until the next streak. r in [0, 1].
function AmbientRules.nextDelay(minSeconds: number, maxSeconds: number, r: number): number
	return lerp(minSeconds, maxSeconds, clamp01(r))
end

-- Start offset (from the camera) and unit travel direction of one streak. Azimuth and elevation set where in the sky it begins;
-- it flies along the horizon tangent (side picked by flip) and sinks by dropFraction, so it always falls and never climbs.
function AmbientRules.streak(shape: StreakShape, azimuthR: number, elevationR: number, flipR: number): Streak
	local az = clamp01(azimuthR) * 2 * math.pi
	local el = math.rad(lerp(shape.elevationMinDegrees, shape.elevationMaxDegrees, clamp01(elevationR)))
	local offset = {
		x = shape.distance * math.cos(el) * math.cos(az),
		y = shape.distance * math.sin(el),
		z = shape.distance * math.cos(el) * math.sin(az),
	}
	local side = if flipR < 0.5 then 1 else -1
	local drop = math.clamp(shape.dropFraction, 0, 1)
	local along = math.sqrt(1 - drop * drop)
	local direction = {
		x = -math.sin(az) * side * along,
		y = -drop,
		z = math.cos(az) * side * along,
	}
	return { offset = offset, direction = direction }
end

-- Part transparency over a streak's life: fades in over the first fadeFraction, out over the last, solid between. t in [0, 1].
function AmbientRules.transparency(t: number, fadeFraction: number): number
	local x = clamp01(t)
	local f = math.clamp(fadeFraction, 0.01, 0.5)
	if x < f then
		return 1 - x / f
	elseif x > 1 - f then
		return (x - (1 - f)) / f
	end
	return 0
end

return AmbientRules
