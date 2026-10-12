--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local ChaseRules = require(Shared.Rules.ChaseRules)
local World = require(Shared.Config.World)
local Habitats = require(Shared.Config.Habitats)

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function inside(rect: World.Rect, p: Vector3): boolean
	return World.inRect(rect, p.X, p.Z)
end

return function(t: TestRunner.T)
	local rng = Random.new(20)
	local walls = Habitats.cryptWalls() :: World.Rect

	t.test("a startle hops 8-14 studs away from the player, inside the zone (Round 20 Q2)", function()
		local zone = Habitats.zoneById("Gate") :: World.Zone
		local at = Vector3.new(0, 4, 5)
		local from = Vector3.new(-4, 3, 5)
		for _ = 1, 50 do
			local p = ChaseRules.startleTarget(zone.rect, at, from, rng)
			local hop = flat(p, at)
			t.truthy(hop >= ChaseRules.StartleMin - 1e-6 and hop <= ChaseRules.StartleMax + 1e-6, `hop {hop}`)
			t.truthy(inside(zone.rect, p), "stays in its zone")
			t.eq(p.Y, at.Y, "keeps its hover height")
		end
		-- Pressed from the west: it lands further east than it started.
		t.truthy(ChaseRules.startleTarget(zone.rect, at, from, rng).X > at.X - 1, "moves away from the player")
	end)

	t.test("a startle near a zone edge darts sideways instead of stalling", function()
		local zone = Habitats.zoneById("Gate") :: World.Zone
		local r = zone.rect
		-- Against the east edge, pressed from the west: straight away is blocked.
		local at = Vector3.new(r.x2 - 4, 4, (r.z1 + r.z2) / 2)
		local p = ChaseRules.startleTarget(r, at, at - Vector3.new(5, 0, 0), rng)
		t.truthy(flat(p, at) >= ChaseRules.StartleMin - 1e-6, "still a real hop")
		t.truthy(inside(r, p), "stays in its zone")
	end)

	t.test("flee region never crosses a wall (crypt, hub, open ring)", function()
		local inCrypt = ChaseRules.fleeRegion(Vector3.new((walls.x1 + walls.x2) / 2, 0, (walls.z1 + walls.z2) / 2))
		t.eq(inCrypt.rect, walls, "inside the crypt it stays in the crypt")
		local inHub, avoid = ChaseRules.fleeRegion(Vector3.new(60, 0, -20))
		t.eq(inHub, ChaseRules.Habitat, "inside the hub wall it stays in the habitat")
		t.eq(avoid, walls, "and keeps out of the crypt")
		t.eq(ChaseRules.fleeRegion(World.PlotCenters[3]), ChaseRules.OpenGround, "near a plot: the open ring")
		t.eq(ChaseRules.fleeRegion(World.NeutralSpawn), ChaseRules.OpenGround, "on the ring road: the open ring")
		-- The open ring lies between the hub wall and the plots.
		local ring = ChaseRules.OpenGround.ring :: { r0: number, r1: number }
		t.truthy(ring.r0 > World.Hub.wallRadius, "starts outside the hub wall")
		t.truthy(ring.r1 < World.PlotRing.radius - World.PlotSize.Y / 2, "ends before the plots")
	end)

	t.test("a fleeing monster runs away from the chaser and stays on the open ring (Round 20 Q1)", function()
		local region = ChaseRules.OpenGround
		local at = World.polar(90, 126) + Vector3.new(0, 4, 0)
		local chaser = World.polar(84, 126) + Vector3.new(0, 3, 0)
		for _ = 1, 50 do
			local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng)
			t.truthy(ChaseRules.contains(region, p.X, p.Z), "inside the region")
			t.truthy(flat(p, chaser) > flat(at, chaser), "the gap to the chaser grows")
			-- Vector3 is 32-bit: about 1e-5 resolution this far from the origin.
			t.truthy(flat(p, at) <= 7.5 + 1e-3, "no more than one step")
		end
	end)

	t.test("a fleeing monster in the habitat never enters the sealed crypt", function()
		local region, avoid = ChaseRules.fleeRegion(Vector3.new(0, 0, 0))
		-- Just east of the crypt's gate wall, chased from the east: straight away is into the crypt.
		local at = Vector3.new(walls.x2 + 4, 4, (walls.z1 + walls.z2) / 2)
		local chaser = at + Vector3.new(8, 0, 0)
		for _ = 1, 50 do
			local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng, avoid)
			t.truthy(not inside(walls, p), "stays out of the crypt")
			t.truthy(ChaseRules.contains(region, p.X, p.Z), "inside the habitat")
		end
	end)

	t.test("a cornered fleeing monster slides along the ring's edge", function()
		local region = ChaseRules.OpenGround
		local ring = region.ring :: { r0: number, r1: number }
		local at = World.polar(90, ring.r0 + 4) + Vector3.new(0, 4, 0)
		local chaser = World.polar(90, ring.r0 + 10) -- pinned against the hub wall
		local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng)
		t.truthy(ChaseRules.contains(region, p.X, p.Z), "inside the region")
		t.truthy(flat(p, at) > 1, "keeps moving")
	end)
end
