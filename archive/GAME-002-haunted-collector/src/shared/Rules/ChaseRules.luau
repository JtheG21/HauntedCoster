--!strict
-- Where startled and fleeing monsters move (Round 20; GDD v0.3). Pure: no services, so it is unit-tested;
-- EncounterService tweens the monster to the points chosen here.

local Shared = script.Parent.Parent
local World = require(Shared.Config.World)
local Habitats = require(Shared.Config.Habitats)

local ChaseRules = {}

-- A region a fleeing monster stays inside: a rect, or a ring around the hub centre (r0 = 0 is a disc).
export type Region = { rect: World.Rect?, ring: { r0: number, r1: number }? }

ChaseRules.StartleMin = 8 -- studs (Round 20 Q2: a short hop)
ChaseRules.StartleMax = 14
-- Outside the hub a fleeing monster stays on the open band between the hub wall and the plots (the ring
-- road), so it never crosses the wall or runs into a plot.
ChaseRules.OpenGround = {
	ring = {
		r0 = World.Hub.wallRadius + 3,
		r1 = World.PlotRing.radius - World.PlotSize.Y / 2 - 2,
	},
} :: Region
ChaseRules.Habitat = { ring = { r0 = 0, r1 = World.Hub.moduleRadius } } :: Region

local function clampTo(rect: World.Rect, inset: number, x: number, z: number): (number, number)
	return math.clamp(x, rect.x1 + inset, rect.x2 - inset), math.clamp(z, rect.z1 + inset, rect.z2 - inset)
end

local function clampIn(region: Region, inset: number, x: number, z: number): (number, number)
	local rect, ring = region.rect, region.ring
	if rect then
		return clampTo(rect, inset, x, z)
	elseif ring then
		local c = World.Hub.center
		local dx, dz = x - c.X, z - c.Z
		local d = math.sqrt(dx * dx + dz * dz)
		local lo = if ring.r0 > 0 then ring.r0 + inset else 0
		local target = math.clamp(d, lo, ring.r1 - inset)
		if d < 1e-6 then
			return c.X + target, c.Z
		end
		return c.X + dx / d * target, c.Z + dz / d * target
	end
	return x, z
end

-- Whether (x, z) lies in the region (tests and callers that place a monster directly).
function ChaseRules.contains(region: Region, x: number, z: number): boolean
	local rect, ring = region.rect, region.ring
	if rect then
		return World.inRect(rect, x, z)
	elseif ring then
		local d = World.hubDistance(x, z)
		return d >= ring.r0 - 1e-6 and d <= ring.r1 + 1e-6
	end
	return false
end

-- Where a startled monster lands. Away from `from`, 8-14 studs, kept inside its zone; if the zone
-- edge leaves too short a hop, it darts sideways instead.
function ChaseRules.startleTarget(rect: World.Rect, at: Vector3, from: Vector3, roll: Random): Vector3
	local away = Vector3.new(at.X - from.X, 0, at.Z - from.Z)
	local base = if away.Magnitude > 0.1 then math.atan2(away.Z, away.X) else roll:NextNumber(0, math.pi * 2)
	local dist = roll:NextNumber(ChaseRules.StartleMin, ChaseRules.StartleMax)
	local best: Vector3 = at
	local bestHop = -1
	for _, turn in { 0, math.pi / 3, -math.pi / 3, math.pi / 2, -math.pi / 2, math.pi } do
		local a = base + turn
		local x, z = clampTo(rect, 4, at.X + math.cos(a) * dist, at.Z + math.sin(a) * dist)
		local hop = Vector3.new(x - at.X, 0, z - at.Z).Magnitude
		if hop >= ChaseRules.StartleMin then
			return Vector3.new(x, at.Y, z)
		end
		if hop > bestHop then
			best, bestHop = Vector3.new(x, at.Y, z), hop
		end
	end
	return best
end

-- Which region a fleeing monster is kept inside: the crypt, the habitat inside the hub wall, or the open
-- ring outside it, so it never crosses a wall the player has to walk around. The second result is an area
-- inside the region it must stay out of: the crypt walls, when it runs in the open habitat.
function ChaseRules.fleeRegion(at: Vector3): (Region, World.Rect?)
	local walls = Habitats.cryptWalls()
	if walls and World.inRect(walls, at.X, at.Z) then
		return { rect = walls }, nil
	elseif World.inHub(at.X, at.Z) then
		return ChaseRules.Habitat, walls
	end
	return ChaseRules.OpenGround, nil
end

-- The next point on a flee path. Runs away from the chaser with a random swerve, clamped to the
-- region and kept out of `avoid`; when cornered it slides along the edge instead of stopping.
function ChaseRules.fleeStep(
	region: Region,
	at: Vector3,
	chaser: Vector3?,
	step: number,
	roll: Random,
	avoid: World.Rect?
): Vector3
	local away = if chaser then Vector3.new(at.X - chaser.X, 0, at.Z - chaser.Z) else Vector3.zero
	local base = if away.Magnitude > 0.1 then math.atan2(away.Z, away.X) else roll:NextNumber(0, math.pi * 2)
	local best: Vector3 = at
	local bestScore = -math.huge
	for _, turn in { roll:NextNumber(-0.9, 0.9), 1.2, -1.2, 1.9, -1.9, math.pi } do
		local a = base + turn
		local x, z = clampIn(region, 4, at.X + math.cos(a) * step, at.Z + math.sin(a) * step)
		-- Clamping onto a ring projects along the radius, which can stretch the step a little: cap it,
		-- so a fleeing monster never moves more than one step per tick (the inset keeps it in the region).
		local stretched = Vector3.new(x - at.X, 0, z - at.Z).Magnitude
		if stretched > step then
			x, z = at.X + (x - at.X) * step / stretched, at.Z + (z - at.Z) * step / stretched
		end
		-- 2-stud margin around the avoided area so it never ends up inside the wall.
		local blocked = avoid ~= nil
			and x >= avoid.x1 - 2
			and x <= avoid.x2 + 2
			and z >= avoid.z1 - 2
			and z <= avoid.z2 + 2
		if not blocked then
			local p = Vector3.new(x, at.Y, z)
			local moved = Vector3.new(x - at.X, 0, z - at.Z).Magnitude
			if moved >= step * 0.8 then
				return p
			end
			local gap = if chaser then Vector3.new(x - chaser.X, 0, z - chaser.Z).Magnitude else moved
			local score = moved + gap * 0.1
			if score > bestScore then
				best, bestScore = p, score
			end
		end
	end
	return best
end

return ChaseRules
