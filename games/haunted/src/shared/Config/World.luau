--!strict
-- World layout: plots, graveyard zones and landmarks. Positions are world studs (ground top is y = 0)
-- unless marked plot-local. Plot-local axes match world axes (plots are not rotated); -Z faces the graveyard.

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

export type Landmark = {
	id: string,
	name: string,
	zone: string,
	position: Vector3,
	clue: string,
	requiresFlag: string?, -- the landmark only gives its clue once this flag is set
	setsFlag: string?,
}

local World = {}

World.PlotCenters = {
	Vector3.new(-250, 0, 85),
	Vector3.new(-150, 0, 85),
	Vector3.new(-50, 0, 85),
	Vector3.new(50, 0, 85),
	Vector3.new(150, 0, 85),
	Vector3.new(250, 0, 85),
}
World.PlotSize = Vector2.new(100, 90)

-- Plot-local layout
World.Plot = {
	spawn = Vector3.new(-30, 3, 6),
	house = Vector3.new(0, 0, 30),
	pen = Vector3.new(-34, 0, -22),
	penSize = 16,
	beacon = Vector3.new(-44, 0, 40),
	trophies = Vector3.new(38, 0, 38),
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

World.Graveyard = {
	rect = { x1 = -130, x2 = 130, z1 = -370, z2 = -160 } :: Rect,
	gate = Vector3.new(0, 0, -160),
	gateWidth = 24,
	shortcut = Vector3.new(-130, 0, -180), -- west fence gap opened by the Old Well
	shortcutWidth = 10,
	crypt = { x1 = -72, x2 = 17, z1 = -367, z2 = -323 } :: Rect,
	cryptGate = Vector3.new(-30, 0, -323),
	cryptGateWidth = 10,
	cryptLandmarksNeeded = 3,
}

World.Zones = {
	{
		id = "Gate",
		name = "Gate Path",
		rect = { x1 = -40, x2 = 40, z1 = -205, z2 = -165 },
		dark = false,
		gated = false,
		maxMonsters = 2,
		spawns = { Wisp = 1 },
	},
	{
		id = "OldRows",
		name = "Old Rows",
		rect = { x1 = -125, x2 = -20, z1 = -310, z2 = -210 },
		dark = false,
		gated = false,
		maxMonsters = 3,
		spawns = { Wisp = 2, Hound = 2 },
	},
	{
		id = "Hollow",
		name = "Mausoleum Hollow",
		rect = { x1 = 22, x2 = 125, z1 = -335, z2 = -210 },
		dark = true,
		gated = false,
		maxMonsters = 3,
		spawns = { Hound = 2, Gentleman = 2 },
	},
	{
		id = "Crypt",
		name = "Sealed Crypt",
		rect = { x1 = -66, x2 = 11, z1 = -362, z2 = -328 },
		dark = true,
		gated = true,
		maxMonsters = 2,
		spawns = { Gentleman = 2, BellWraith = 1 },
	},
} :: { Zone }

World.Landmarks = {
	{
		id = "Angel",
		name = "Weeping Angel",
		zone = "Gate",
		position = Vector3.new(0, 0, -190),
		clue = "Lantern Wisps drift toward lit lanterns near the gate. Marked: Wisps now glow on your screen.",
	},
	{
		id = "Hearse",
		name = "Broken Hearse",
		zone = "OldRows",
		position = Vector3.new(-75, 0, -255),
		clue = "Paw prints in three sizes. Stitched Hounds prowl the Old Rows. Marked: Hounds now glow.",
	},
	{
		id = "Mausoleum",
		name = "Hollow Mausoleum",
		zone = "Hollow",
		position = Vector3.new(75, 0, -292),
		clue = "An empty top hat on the steps. The Hollow Gentleman walks the dark Hollow. Marked: Gentlemen glow.",
	},
	{
		id = "OldWell",
		name = "Old Well",
		zone = "OldRows",
		position = Vector3.new(-108, 0, -196),
		clue = "A rope ladder leads to a gap in the west fence. Shortcut home unlocked!",
		setsFlag = "shortcut",
	},
	{
		id = "BellTower",
		name = "Bell Tower",
		zone = "Hollow",
		position = Vector3.new(58, 0, -352),
		clue = "The tower tolls for you. A Bell Wraith now answers your call inside the Sealed Crypt.",
		requiresFlag = "bellHint",
		setsFlag = "bellClue",
	},
} :: { Landmark }

function World.zoneById(id: string): Zone?
	for _, z in World.Zones do
		if z.id == id then
			return z
		end
	end
	return nil
end

function World.landmarkById(id: string): Landmark?
	for _, l in World.Landmarks do
		if l.id == id then
			return l
		end
	end
	return nil
end

function World.inRect(rect: Rect, x: number, z: number): boolean
	return x >= rect.x1 and x <= rect.x2 and z >= rect.z1 and z <= rect.z2
end

return World
