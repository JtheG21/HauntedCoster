--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local TrackRules = require(Shared.Rules.TrackRules)
local World = require(Shared.Config.World)
local Track = require(Shared.Config.Track)
local Economy = require(Shared.Config.Economy)

return function(t: TestRunner.T)
	local bounds = World.Plot.trackBounds
	local function starter(): { TrackRules.P }
		local pts = {}
		for _, v in World.Plot.starterRoute do
			table.insert(pts, { x = v.X, z = v.Y })
		end
		return pts
	end

	t.test("starter route is valid", function()
		local v = TrackRules.validate(starter(), {}, bounds)
		t.eq(v.ok, true, v.reason)
		local s = v.sampled :: TrackRules.Sampled
		t.truthy(s.length >= Track.MinLength and s.length <= Track.MaxLength)
	end)

	t.test("starter ride has one scare and one display beside the loop (Round 20 Q4)", function()
		local pieces = World.Plot.starterPieces :: { any }
		local v = TrackRules.validate(starter(), pieces, bounds)
		t.eq(v.ok, true, v.reason)
		local scares = 0
		for _, piece in pieces do
			if piece.kind == "ScareArch" then
				scares += 1
			end
		end
		t.eq(scares, 1, "exactly one Scare Arch")
		-- The starter house (tier 0) unlocks the first slots; at least one of them must count for the ride.
		local sampled = v.sampled :: TrackRules.Sampled
		local inRange = 0
		for i = 1, Economy.HouseTiers[1].exhibitSlots do
			local pos = World.Plot.exhibitSlots[i]
			if TrackRules.nearestDistance(sampled, pos.X, pos.Z) <= Economy.ExhibitRange then
				inRange += 1
			end
		end
		t.truthy(inRange >= 1, "a starter exhibit slot sits beside the starter loop")
	end)

	t.test("too few points rejected", function()
		local v = TrackRules.validate({ { x = 0, z = 0 }, { x = 10, z = 0 }, { x = 0, z = 10 } }, {}, bounds)
		t.eq(v.ok, false)
	end)

	t.test("out of bounds rejected", function()
		local pts = starter()
		pts[1] = { x = bounds.x2 + 10, z = 0 }
		t.eq(TrackRules.validate(pts, {}, bounds).ok, false)
	end)

	t.test("non-number input rejected", function()
		t.eq(TrackRules.validate("nope", {}, bounds).ok, false)
		local pts: { any } = starter()
		pts[2] = { x = "1", z = 2 }
		t.eq(TrackRules.validate(pts, {}, bounds).ok, false)
		t.eq(TrackRules.validate(starter(), { { i = 1, kind = "Laser" } }, bounds).ok, false)
		t.eq(TrackRules.validate(starter(), { { i = 99, kind = "ScareArch" } }, bounds).ok, false)
	end)

	t.test("too short rejected", function()
		local pts = { { x = 0, z = 0 }, { x = 7, z = 0 }, { x = 7, z = 7 }, { x = 0, z = 7 } }
		local v = TrackRules.validate(pts, {}, bounds)
		t.eq(v.ok, false)
	end)

	t.test("self-crossing figure eight rejected", function()
		local pts = { { x = -10, z = -30 }, { x = 30, z = 0 }, { x = 30, z = -30 }, { x = -10, z = 0 } }
		local v = TrackRules.validate(pts, {}, bounds)
		t.eq(v.ok, false)
		t.eq(v.reason, "The track crosses itself")
	end)

	-- A thin loop: control points are all >= MinPointSpacing apart, so only the clearance rule can reject it.
	local function thinLoop(gap: number): { TrackRules.P }
		local z0 = -36
		return {
			{ x = -8, z = z0 },
			{ x = 38, z = z0 },
			{ x = 44, z = z0 + gap / 2 },
			{ x = 38, z = z0 + gap },
			{ x = -8, z = z0 + gap },
			{ x = -14, z = z0 + gap / 2 },
		}
	end

	t.test("near-parallel passes rejected by clearance", function()
		local v = TrackRules.validate(thinLoop(3), {}, bounds)
		t.eq(v.ok, false)
		t.eq(v.reason, "Two parts of the track pass too close together")
	end)

	t.test("a hairpin with enough clearance stays valid", function()
		local v = TrackRules.validate(thinLoop(8), {}, bounds)
		t.eq(v.ok, true, v.reason)
	end)

	t.test("NaN, inf, too many and sparse inputs rejected", function()
		local nan = 0 / 0
		for _, bad in { nan, math.huge, -math.huge } do
			local pts: { any } = starter()
			pts[2] = { x = bad, z = 0 }
			local v = TrackRules.validate(pts, {}, bounds)
			t.eq(v.ok, false)
			t.eq(v.reason, "Bad point")
		end
		local many = {}
		for i = 1, Track.MaxPoints + 1 do
			local a = (i / (Track.MaxPoints + 1)) * 2 * math.pi
			table.insert(many, { x = 14 + 25 * math.cos(a), z = -14 + 20 * math.sin(a) })
		end
		t.eq(TrackRules.validate(many, {}, bounds).reason, `At most {Track.MaxPoints} points`)
		local sparse: { any } = starter()
		sparse[#sparse + 2] = { x = 0, z = 0 } -- a hole; # is unreliable
		t.eq(TrackRules.validate(sparse, {}, bounds).ok, false)
		local extra: { [any]: any } = starter()
		extra.junk = true
		t.eq(TrackRules.validate(extra, {}, bounds).reason, "Bad point")
		local sparsePieces: { any } = { { i = 1, kind = "ScareArch" } }
		sparsePieces[3] = { i = 2, kind = "FogTunnel" }
		t.eq(TrackRules.validate(starter(), sparsePieces, bounds).ok, false)
	end)

	t.test("points too close rejected", function()
		local pts = starter()
		table.insert(pts, 2, { x = pts[1].x + 1, z = pts[1].z })
		t.eq(TrackRules.validate(pts, {}, bounds).ok, false)
	end)

	t.test("quality is clamped at both ends", function()
		-- Floor: a plain square at the minimum length scores QualityMin (the formula's base equals the floor).
		local square: TrackRules.Sampled = {
			points = { { x = 0, z = 0 }, { x = 20, z = 0 }, { x = 20, z = 20 }, { x = 0, z = 20 } },
			length = Track.MinLength,
		}
		t.truthy(
			math.abs(TrackRules.quality(square, {}) - Track.QualityMin) < 1e-9,
			tostring(TrackRules.quality(square, {}))
		)
		-- Ceiling: maximum length, constant zig-zag turning and every piece slot would score above
		-- QualityMax unclamped (0.9 + 0.12 + 0.08 + 3 x 0.06 = 1.28), so this fails without the clamp.
		local zig: { TrackRules.P } = {}
		for i = 1, 60 do
			table.insert(zig, { x = i * 3, z = if i % 2 == 0 then 0 else 3 })
		end
		local maxed: TrackRules.Sampled = { points = zig, length = Track.MaxLength }
		local pieces = { { i = 1, kind = "ScareArch" }, { i = 2, kind = "ScareArch" }, { i = 3, kind = "ScareArch" } }
		t.eq(TrackRules.quality(maxed, pieces), Track.QualityMax)
		t.truthy(TrackRules.quality(maxed, {}) < Track.QualityMax, "the ceiling needs the pieces")
	end)

	t.test("quality stays in range and pieces raise it", function()
		local s = TrackRules.sample(starter())
		local q0 = TrackRules.quality(s, {})
		local q1 = TrackRules.quality(s, { { i = 1, kind = "ScareArch" }, { i = 2, kind = "FogTunnel" } })
		t.truthy(q0 >= Track.QualityMin and q0 <= Track.QualityMax)
		t.truthy(q1 > q0)
		t.truthy(q1 <= Track.QualityMax)
	end)

	t.test("payout counts only exhibits in range", function()
		local s = TrackRules.sample(starter())
		local far = TrackRules.payout(s, {}, 1, { { rarity = "Rare", variantMultiplier = 1, x = 500, z = 500 } })
		t.eq(far.counted, 0)
		local near = TrackRules.payout(s, {}, 1, { { rarity = "Rare", variantMultiplier = 1, x = -10, z = -30 } })
		t.eq(near.counted, 1)
		t.truthy(near.total > far.total)
		local tier = TrackRules.payout(s, {}, 2.5, {})
		t.truthy(tier.total > far.total)
	end)

	t.test("pointAt walks the loop", function()
		local s = TrackRules.sample(starter())
		local p0 = TrackRules.pointAt(s, 0)
		t.eq(p0.x, s.points[1].x)
		local len = TrackRules.loopLength(s)
		local pEnd = TrackRules.pointAt(s, len)
		t.truthy(math.abs(pEnd.x - s.points[1].x) < 0.01 and math.abs(pEnd.z - s.points[1].z) < 0.01)
	end)
end
