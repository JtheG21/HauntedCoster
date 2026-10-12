--!strict
-- Radial plot layout (TASK-0026 AC1-AC3, ADR-0007): plots face the hub, never overlap, clear the ring road,
-- keep their contents inside their bounds, and are equally far from a hub gate.
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local World = require(ReplicatedStorage.Shared.Config.World)

local function corners(index: number): { Vector3 }
	local hx, hz = World.PlotSize.X / 2, World.PlotSize.Y / 2
	local out = {}
	for _, c in { { -hx, -hz }, { hx, -hz }, { hx, hz }, { -hx, hz } } do
		table.insert(out, World.plotToWorld(index, Vector3.new(c[1], 0, c[2])))
	end
	return out
end

-- Separating-axis test for two rotated rectangles on the ground, with a required gap.
local function separated(a: { Vector3 }, b: { Vector3 }, gap: number): boolean
	for _, poly in { a, b } do
		for i = 1, 4 do
			local p, q = poly[i], poly[i % 4 + 1]
			local axis = Vector3.new(-(q.Z - p.Z), 0, q.X - p.X).Unit
			local minA, maxA, minB, maxB = math.huge, -math.huge, math.huge, -math.huge
			for _, v in a do
				local d = v:Dot(axis)
				minA, maxA = math.min(minA, d), math.max(maxA, d)
			end
			for _, v in b do
				local d = v:Dot(axis)
				minB, maxB = math.min(minB, d), math.max(maxB, d)
			end
			if maxA + gap <= minB or maxB + gap <= minA then
				return true
			end
		end
	end
	return false
end

-- Closest distance from the hub centre to a plot (the plot is convex; the centre is outside it).
local function hubClearance(index: number): number
	local l = World.worldToPlot(index, World.Hub.center)
	local hx, hz = World.PlotSize.X / 2, World.PlotSize.Y / 2
	local dx = math.max(math.abs(l.X) - hx, 0)
	local dz = math.max(math.abs(l.Z) - hz, 0)
	return math.sqrt(dx * dx + dz * dz)
end

return function(t: TestRunner.T)
	local n = #World.PlotCenters

	t.test("six plots, 60 degrees apart; plot 1 is rotated (so tests on plot 1 exercise rotation)", function()
		t.eq(n, 6)
		for i = 2, n do
			local diff = (World.PlotAngles[i] - World.PlotAngles[i - 1]) % 360
			t.eq(diff, 60, `plot {i}`)
		end
		local look = World.plotFrame(1).LookVector
		t.truthy(math.abs(look.X) > 0.1 and math.abs(look.Z) > 0.1, "plot 1 faces neither world axis")
	end)

	t.test("every plot's front (local -Z) faces the hub", function()
		for i = 1, n do
			local c = World.PlotCenters[i]
			local toHub = Vector3.new(World.Hub.center.X - c.X, 0, World.Hub.center.Z - c.Z).Unit
			t.truthy(World.plotFrame(i).LookVector:Dot(toHub) > 0.9999, `plot {i}`)
			t.truthy(math.abs(World.plotFrame(i).UpVector.Y - 1) < 1e-6, `plot {i} stays level`)
		end
	end)

	t.test("no two plots overlap, with a walkway between neighbours", function()
		for i = 1, n do
			for j = i + 1, n do
				t.truthy(separated(corners(i), corners(j), 20), `plots {i} and {j}`)
			end
		end
	end)

	t.test("every plot clears the ring road and the hub wall", function()
		for i = 1, n do
			t.truthy(hubClearance(i) > World.Hub.ringOuter + 4, `plot {i}: {hubClearance(i)}`)
		end
	end)

	t.test("plot-local to world and back is exact", function()
		for i = 1, n do
			for _, v in { Vector3.new(0, 0, 0), World.Plot.pen, World.Plot.spawn, Vector3.new(46, 1.5, -40) } do
				local back = World.worldToPlot(i, World.plotToWorld(i, v))
				t.truthy((back - v).Magnitude < 1e-4, `plot {i} {v}`)
			end
			local dir = World.plotDirToWorld(i, Vector3.new(1, 0, 0))
			t.truthy(math.abs(dir.Magnitude - 1) < 1e-6, "directions keep their length")
		end
	end)

	t.test("track bounds, exhibit slots, pen and spawn sit inside the plot", function()
		local hx, hz = World.PlotSize.X / 2, World.PlotSize.Y / 2
		local b = World.Plot.trackBounds
		t.truthy(b.x1 >= -hx and b.x2 <= hx and b.z1 >= -hz and b.z2 <= hz, "track bounds")
		for i, s in World.Plot.exhibitSlots do
			t.truthy(math.abs(s.X) + 2 <= hx and math.abs(s.Z) + 2 <= hz, `exhibit slot {i}`)
		end
		for _, p in { World.Plot.pen, World.Plot.spawn, World.Plot.house, World.Plot.beacon } do
			t.truthy(math.abs(p.X) < hx and math.abs(p.Z) < hz, `{p}`)
		end
	end)

	t.test("each plot entrance opens onto the ring road", function()
		for i = 1, n do
			local e = World.plotToWorld(i, World.Plot.entrance)
			local d = World.hubDistance(e.X, e.Z)
			t.truthy(d > World.Hub.ringOuter and d - World.Hub.ringOuter < 12, `plot {i}: entrance at r={d}`)
		end
	end)

	t.test("every plot is equally far from its nearest hub gate (within 1 stud)", function()
		local best: { number } = {}
		for i = 1, n do
			local e = World.plotToWorld(i, World.Plot.entrance)
			local nearest = math.huge
			for g = 1, #World.Hub.gateAngles do
				nearest = math.min(nearest, (World.gatePosition(g) - e).Magnitude)
			end
			best[i] = nearest
		end
		for i = 2, n do
			t.truthy(math.abs(best[i] - best[1]) <= 1, `plot {i}: {best[i]} vs {best[1]}`)
		end
	end)

	t.test("hub gates sit on the wall, between plots", function()
		for g, angle in World.Hub.gateAngles do
			local p = World.gatePosition(g)
			t.truthy(math.abs(World.hubDistance(p.X, p.Z) - World.Hub.wallRadius) < 1e-4, `gate {g}`)
			for _, plotAngle in World.PlotAngles do
				local diff = math.abs((angle - plotAngle + 180) % 360 - 180)
				t.truthy(diff >= 29.9, `gate {g} isn't in front of a plot`)
			end
		end
		t.truthy(not World.inHub(World.NeutralSpawn.X, World.NeutralSpawn.Z), "the neutral spawn is outside the hub")
	end)
end
