--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AmbientRules = require(ReplicatedStorage.Shared.AmbientRules)

local SHAPE: AmbientRules.StreakShape = {
	distance = 400,
	elevationMinDegrees = 25,
	elevationMaxDegrees = 55,
	travel = 90,
	dropFraction = 0.35,
}

return function(t: TestRunner.T)
	t.test("nextDelay stays inside its band and clamps bad samples", function()
		t.eq(AmbientRules.nextDelay(6, 14, 0), 6, "low end")
		t.eq(AmbientRules.nextDelay(6, 14, 1), 14, "high end")
		t.truthy(AmbientRules.nextDelay(6, 14, 0.5) > 6 and AmbientRules.nextDelay(6, 14, 0.5) < 14, "middle")
		t.eq(AmbientRules.nextDelay(6, 14, -3), 6, "below range clamps")
		t.eq(AmbientRules.nextDelay(6, 14, 9), 14, "above range clamps")
	end)

	t.test("every streak starts at the stated distance, inside the elevation band, and falls", function()
		for i = 0, 10 do
			for j = 0, 10 do
				for k = 0, 1 do
					local s = AmbientRules.streak(SHAPE, i / 10, j / 10, k)
					local o, d = s.offset, s.direction
					local dist = math.sqrt(o.x * o.x + o.y * o.y + o.z * o.z)
					t.truthy(math.abs(dist - SHAPE.distance) < 1e-6, "distance")
					local elevation = math.deg(math.asin(o.y / dist))
					t.truthy(elevation >= SHAPE.elevationMinDegrees - 1e-6, "elevation floor")
					t.truthy(elevation <= SHAPE.elevationMaxDegrees + 1e-6, "elevation ceiling")
					local len = math.sqrt(d.x * d.x + d.y * d.y + d.z * d.z)
					t.truthy(math.abs(len - 1) < 1e-6, "direction is a unit vector")
					t.truthy(d.y < 0, "streak never climbs")
				end
			end
		end
	end)

	t.test("direction runs along the horizon tangent, not toward or away from the camera", function()
		local s = AmbientRules.streak(SHAPE, 0.3, 0.5, 0)
		local o, d = s.offset, s.direction
		local radial = (o.x * d.x + o.z * d.z) / math.sqrt(o.x * o.x + o.z * o.z)
		t.truthy(math.abs(radial) < 1e-6, "no horizontal radial component")
	end)

	t.test("flip reverses the horizontal travel side", function()
		local a = AmbientRules.streak(SHAPE, 0.2, 0.5, 0.1)
		local b = AmbientRules.streak(SHAPE, 0.2, 0.5, 0.9)
		t.truthy(math.abs(a.direction.x + b.direction.x) < 1e-9, "x mirrors")
		t.truthy(math.abs(a.direction.z + b.direction.z) < 1e-9, "z mirrors")
		t.eq(a.direction.y, b.direction.y, "drop is the same")
	end)

	t.test("transparency fades in, holds solid, fades out", function()
		t.eq(AmbientRules.transparency(0, 0.25), 1, "invisible at start")
		t.eq(AmbientRules.transparency(0.5, 0.25), 0, "solid in the middle")
		t.eq(AmbientRules.transparency(1, 0.25), 1, "invisible at end")
		t.truthy(
			AmbientRules.transparency(0.125, 0.25) > 0 and AmbientRules.transparency(0.125, 0.25) < 1,
			"partial while fading"
		)
	end)
end
