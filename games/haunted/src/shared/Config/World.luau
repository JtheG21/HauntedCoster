--!strict
-- Persistent world layout (ADR-0007): six home plots in a ring around a central hunting footprint, a ring
-- road between them, and a hub wall with three gates. The active habitat (Config.Habitats) fills the
-- footprint. Positions are world studs (ground top is y = 0) unless marked plot-local.
--
-- Plot-local space: each plot has a frame (World.plotFrame) whose -Z faces the hub. Every plot-local point
-- or direction goes through plotToWorld / worldToPlot / plotDirToWorld; never add a local offset to a
-- plot centre directly, since plots are rotated.

export type Rect = { x1: number, x2: number, z1: number, z2: number }

export type Zone = {
	id: string,
	name: string,
	rect: Rect,
	dark: boolean,
	gated: boolean,
	maxMonsters: number,
	spawns: { [string]: number }, -- species id -> weight
}

-- Landmarks are scenery and navigation points. Clue hunting was removed from the MVP (ADR-0007); the
-- investigate flow can be restored from git history (LandmarkService before TASK-0025).
export type Landmark = {
	id: string,
	name: string,
	zone: string?, -- the spawn zone it stands in, if any (checked by HabitatRules.validate)
	position: Vector3,
}

local World = {}

-- Angles are degrees around the hub, measured from +Z towards +X: a point at angle a and radius r is
-- hub + (sin a, 0, cos a) * r.
World.Hub = {
	center = Vector3.new(0, 0, 0),
	wallRadius = 115, -- persistent hub wall; the habitat footprint is inside it
	moduleRadius = 112, -- habitat geometry and spawn zones must stay inside this disc
	ringInner = 120, -- ring road
	ringOuter = 132,
	gateAngles = { 0, 120, 240 }, -- one gate between each pair of plots, so every plot is equally far from one
	gateWidth = 16,
	gateCorridor = 20, -- studs inside each gate that habitats keep clear
}

-- Plots: centres on a ring, entrances facing the hub. No plot is axis-aligned, so tests on plot 1 exercise
-- the rotation.
World.PlotSize = Vector2.new(100, 90) -- plot-local X (across) by Z (depth)
World.PlotRing = {
	radius = 185, -- inner edge at 140: clears the ring road (132) and its neighbours (53 studs apart)
	firstAngle = 30,
	step = 60,
	count = 6,
}

local function polar(angle: number, radius: number): Vector3
	local a = math.rad(angle)
	return World.Hub.center + Vector3.new(math.sin(a), 0, math.cos(a)) * radius
end
World.polar = polar

World.PlotAngles = {} :: { number }
World.PlotCenters = {} :: { Vector3 }
local frames: { CFrame } = {}
for i = 1, World.PlotRing.count do
	local angle = World.PlotRing.firstAngle + (i - 1) * World.PlotRing.step
	local centre = polar(angle, World.PlotRing.radius)
	World.PlotAngles[i] = angle
	World.PlotCenters[i] = centre
	-- CFrame.lookAt points -Z (the plot's front) at the hub.
	frames[i] = CFrame.lookAt(centre, Vector3.new(World.Hub.center.X, centre.Y, World.Hub.center.Z))
end

function World.plotFrame(index: number): CFrame
	return frames[index]
end

function World.plotToWorld(index: number, localPos: Vector3): Vector3
	return frames[index]:PointToWorldSpace(localPos)
end

function World.worldToPlot(index: number, worldPos: Vector3): Vector3
	return frames[index]:PointToObjectSpace(worldPos)
end

function World.plotDirToWorld(index: number, localDir: Vector3): Vector3
	return frames[index]:VectorToWorldSpace(localDir)
end

-- Plot-local layout
World.Plot = {
	spawn = Vector3.new(-30, 3, 6),
	house = Vector3.new(0, 0, 30),
	pen = Vector3.new(-34, 0, -22),
	penSize = 16,
	beacon = Vector3.new(-44, 0, 40),
	trophies = Vector3.new(38, 0, 38),
	entrance = Vector3.new(0, 0, -45), -- the gap in the front wall, facing the hub
	entranceWidth = 24,
	-- Track editor bounds (plot-local x/z)
	trackBounds = { x1 = -18, x2 = 46, z1 = -40, z2 = 12 } :: Rect,
	exhibitSlots = {
		Vector3.new(14, 0, -14),
		Vector3.new(-16, 0, 4),
		Vector3.new(47, 0, -36),
		Vector3.new(47, 0, 6),
	},
	starterRoute = {
		Vector2.new(-10, -30),
		Vector2.new(30, -34),
		Vector2.new(42, -12),
		Vector2.new(30, 6),
		Vector2.new(0, 8),
		Vector2.new(-12, -8),
	},
	-- The fixed starter ride shows one scare from the first ride (Round 20 Q4). Its one display is
	-- exhibit slot 2, which sits beside the loop (TrackRules.spec checks both).
	starterPieces = {
		{ i = 4, kind = "ScareArch" },
	},
}

-- Hub gates, on the wall, in gateAngles order.
function World.gatePosition(gate: number): Vector3
	return polar(World.Hub.gateAngles[gate], World.Hub.wallRadius)
end

-- A point on the radial line through a gate, `radius` studs from the hub centre (inside or outside it).
function World.gatePoint(gate: number, radius: number): Vector3
	return polar(World.Hub.gateAngles[gate], radius)
end

-- Where players arrive before their plot is assigned: on the ring road in front of plot 1.
World.NeutralSpawn = polar(World.PlotRing.firstAngle, (World.Hub.ringInner + World.Hub.ringOuter) / 2)

function World.hubDistance(x: number, z: number): number
	return Vector3.new(x - World.Hub.center.X, 0, z - World.Hub.center.Z).Magnitude
end

-- Inside the hub wall (the active habitat's footprint).
function World.inHub(x: number, z: number): boolean
	return World.hubDistance(x, z) <= World.Hub.wallRadius
end

function World.inRect(rect: Rect, x: number, z: number): boolean
	return x >= rect.x1 and x <= rect.x2 and z >= rect.z1 and z <= rect.z2
end

return World
