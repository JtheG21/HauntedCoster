--!strict
-- Where startled and fleeing monsters move (Round 20; GDD v0.3). Pure: no services, so it is unit-tested;
-- EncounterService tweens the monster to the points chosen here.

local Shared = script.Parent.Parent
local World = require(Shared.Config.World)

local ChaseRules = {}

ChaseRules.StartleMin = 8 -- studs (Round 20 Q2: a short hop)
ChaseRules.StartleMax = 14
-- Outside the graveyard a fleeing monster stays on the open ground between the plots and the fence.
ChaseRules.OpenGround = { x1 = -295, x2 = 295, z1 = -150, z2 = 125 } :: World.Rect

local function clampTo(rect: World.Rect, inset: number, x: number, z: number): (number, number)
	return math.clamp(x, rect.x1 + inset, rect.x2 - inset), math.clamp(z, rect.z1 + inset, rect.z2 - inset)
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

-- Which region a fleeing monster is kept inside: the crypt, the graveyard, or the open ground outside it,
-- so it never crosses a fence the player has to walk around. The second result is an area inside the
-- region it must stay out of: the sealed crypt, when it runs in the open graveyard (its wall needs access).
function ChaseRules.fleeRegion(at: Vector3): (World.Rect, World.Rect?)
	local g = World.Graveyard
	if World.inRect(g.crypt, at.X, at.Z) then
		return g.crypt, nil
	elseif World.inRect(g.rect, at.X, at.Z) then
		return g.rect, g.crypt
	end
	return ChaseRules.OpenGround, nil
end

-- The next point on a flee path. Runs away from the chaser with a random swerve, clamped to the
-- region and kept out of `avoid`; when cornered it slides along the edge instead of stopping.
function ChaseRules.fleeStep(
	region: World.Rect,
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
		local x, z = clampTo(region, 4, at.X + math.cos(a) * step, at.Z + math.sin(a) * step)
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
