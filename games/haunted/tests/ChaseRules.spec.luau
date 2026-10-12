--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local ChaseRules = require(Shared.Rules.ChaseRules)
local World = require(Shared.Config.World)

local function flat(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

local function inside(rect: World.Rect, p: Vector3): boolean
	return World.inRect(rect, p.X, p.Z)
end

return function(t: TestRunner.T)
	local rng = Random.new(20)

	t.test("a startle hops 8-14 studs away from the player, inside the zone (Round 20 Q2)", function()
		local zone = World.zoneById("Gate") :: World.Zone
		local at = Vector3.new(0, 4, -185)
		local from = Vector3.new(-4, 3, -185)
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
		local zone = World.zoneById("Gate") :: World.Zone
		local r = zone.rect
		-- Against the east edge, pressed from the west: straight away is blocked.
		local at = Vector3.new(r.x2 - 4, 4, (r.z1 + r.z2) / 2)
		local p = ChaseRules.startleTarget(r, at, at - Vector3.new(5, 0, 0), rng)
		t.truthy(flat(p, at) >= ChaseRules.StartleMin - 1e-6, "still a real hop")
		t.truthy(inside(r, p), "stays in its zone")
	end)

	t.test("flee region never crosses a fence", function()
		local g = World.Graveyard
		t.eq(ChaseRules.fleeRegion(Vector3.new(-30, 0, -345)), g.crypt)
		local inYard, avoid = ChaseRules.fleeRegion(Vector3.new(60, 0, -250))
		t.eq(inYard, g.rect)
		t.eq(avoid, g.crypt, "the open graveyard avoids the sealed crypt")
		t.eq(ChaseRules.fleeRegion(World.PlotCenters[3]), ChaseRules.OpenGround)
		-- The open ground and the graveyard don't overlap (the fence lies between them).
		t.truthy(ChaseRules.OpenGround.z1 > g.rect.z2, "open ground ends before the graveyard fence")
	end)

	t.test("a fleeing monster runs away from the chaser and stays in its region (Round 20 Q1)", function()
		local region = ChaseRules.OpenGround
		local at = Vector3.new(0, 4, 0)
		local chaser = Vector3.new(0, 3, 10)
		for _ = 1, 50 do
			local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng)
			t.truthy(inside(region, p), "inside the region")
			t.truthy(flat(p, chaser) > flat(at, chaser), "the gap to the chaser grows")
			t.truthy(flat(p, at) <= 7.5 + 1e-6, "no more than one step")
		end
	end)

	t.test("a fleeing monster in the graveyard never enters the sealed crypt", function()
		local g = World.Graveyard
		local region, avoid = ChaseRules.fleeRegion(Vector3.new(-30, 0, -310))
		-- Just north of the crypt wall, chased from the north: straight away is into the crypt.
		local at = Vector3.new(-30, 4, g.crypt.z2 + 4)
		local chaser = at + Vector3.new(0, 0, 8)
		for _ = 1, 50 do
			local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng, avoid)
			t.truthy(not inside(g.crypt, p), "stays out of the crypt")
			t.truthy(inside(region, p), "inside the graveyard")
		end
	end)

	t.test("a cornered fleeing monster slides along the edge", function()
		local region = ChaseRules.OpenGround
		local at = Vector3.new(region.x2 - 4, 4, region.z1 + 4)
		local chaser = at + Vector3.new(-6, 0, 6) -- pinned into the corner
		local p = ChaseRules.fleeStep(region, at, chaser, 7.5, rng)
		t.truthy(inside(region, p), "inside the region")
		t.truthy(flat(p, at) > 1, "keeps moving")
	end)
end
