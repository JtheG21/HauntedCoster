--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared
local TrackRules = require(Shared.Rules.TrackRules)
local World = require(Shared.Config.World)
local Track = require(Shared.Config.Track)

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

	t.test("points too close rejected", function()
		local pts = starter()
		table.insert(pts, 2, { x = pts[1].x + 1, z = pts[1].z })
		t.eq(TrackRules.validate(pts, {}, bounds).ok, false)
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
