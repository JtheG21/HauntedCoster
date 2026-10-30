--!strict
-- Plot presentation layout (TASK-0030): the footprint of every house volume per tier, and the plot dressing
-- (entrance gate, lamps), in plot-local studs (local -Z faces the hub). PlotBuilder builds from
-- these numbers and the PlotDecor spec checks them against the gameplay areas, so scenery can never land
-- on the track area, the pen, an exhibit, the spawn or the entrance.

export type Box = { name: string, center: Vector3, size: Vector3 } -- center on the ground, size.Y = height

local PlotDecor = {}

-- Main volumes per house tier. Details (roofs, trims, windows, shutters, columns) stay within a stud of
-- these boxes; the spec checks the boxes grown by `PlotDecor.DetailMargin`.
PlotDecor.Houses = {
	[0] = { -- Shabby Shack: small, crooked, a lean-to and a sagging step
		{ name = "Shack", center = Vector3.new(0, 0, 30), size = Vector3.new(16, 9, 12) },
		{ name = "LeanTo", center = Vector3.new(-11, 0, 31), size = Vector3.new(6, 6, 10) },
		{ name = "Step", center = Vector3.new(0, 0, 22.5), size = Vector3.new(4, 0.6, 3) },
	},
	[1] = { -- Restored Manor: two storeys, pitched roof, west wing, columned porch
		{ name = "Manor", center = Vector3.new(0, 0, 32), size = Vector3.new(26, 13, 14) },
		{ name = "Wing", center = Vector3.new(-18, 0, 33), size = Vector3.new(10, 10, 12) },
		{ name = "Porch", center = Vector3.new(0, 0, 22), size = Vector3.new(12, 0.8, 6) },
	},
	[2] = { -- Grand Mansion: wider and taller, two wings, a tower, a deep porch with a balcony
		{ name = "Manor", center = Vector3.new(0, 0, 32), size = Vector3.new(32, 15, 16) },
		{ name = "WestWing", center = Vector3.new(-21, 0, 33), size = Vector3.new(10, 12, 12) },
		{ name = "EastWing", center = Vector3.new(21, 0, 33), size = Vector3.new(10, 12, 12) },
		{ name = "Tower", center = Vector3.new(11, 0, 38), size = Vector3.new(7, 28, 7) },
		{ name = "Porch", center = Vector3.new(0, 0, 21.5), size = Vector3.new(16, 0.8, 5) },
	},
} :: { [number]: { Box } }

PlotDecor.DetailMargin = 1.5

-- The entrance: two stone pillars with lanterns either side of the front gap, and an iron arch above.
PlotDecor.EntrancePillars = { Vector3.new(-14, 0, -44), Vector3.new(14, 0, -44) }

-- Warm lamps between the pen and the track area, and either side of the porch (the TASK-0028 lamp family).
-- A lamp reaches `LampReach` studs from its post (arm and lantern).
PlotDecor.Lamps = {
	Vector3.new(-21.5, 0, -30),
	Vector3.new(-21.5, 0, -10),
	Vector3.new(-21.5, 0, 14),
	Vector3.new(-12, 0, 20),
	Vector3.new(12, 0, 19),
}

-- Gameplay areas scenery must keep clear of (plot-local rects), with the radius kept clear around each
-- exhibit pedestal and the spawn.
PlotDecor.LampReach = 2
PlotDecor.ExhibitClear = 6
PlotDecor.SpawnClear = 5

return PlotDecor
