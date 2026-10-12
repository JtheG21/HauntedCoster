--!strict
-- Habitat modules (ADR-0007): interchangeable hunting grounds that fill the hub footprint inside the
-- persistent wall. Every module uses the same footprint (World.Hub.moduleRadius), connects to the same
-- three gates, keeps their corridors clear, and defines its own spawn zones, paths and landmarks.
-- HabitatRules.validate checks a module against this contract. Positions are world studs (the hub
-- centre is the world origin).

local World = require(script.Parent.World)

export type Path = {
	id: string,
	width: number,
	points: { Vector3 }, -- x/z on the ground; the first point of a gate path sits at its gate
}

export type Crypt = {
	rect: World.Rect, -- outer walls
	gateSide: string, -- "x1" | "x2" | "z1" | "z2"
	gateAt: number, -- position of the gate centre along that wall
	gateWidth: number,
}

export type Habitat = {
	id: string,
	name: string,
	zones: { World.Zone },
	landmarks: { World.Landmark },
	paths: { Path },
	gatePaths: { string }, -- path id that starts at each hub gate, in World.Hub.gateAngles order
	plaza: { center: Vector3, radius: number }?,
	crypt: Crypt?,
	starter: { species: string, zone: string, at: Vector3 }?, -- a guaranteed monster for the tutorial
}

local Habitats = {}

-- Where a gate path enters the footprint: on the gate's radial line, at the footprint edge.
local function gateStart(gate: number): Vector3
	return World.gatePoint(gate, World.Hub.moduleRadius)
end

-- Ghost Cemetery: the first module and the visual benchmark. Gates at 0° (south), 120° and 240° lead to a
-- central plaza at the Weeping Angel. Old Rows (east-south), Mausoleum Hollow (north, dark) and the
-- Sealed Crypt with its Bell Tower (west-south) fill the three sectors between the gate paths.
Habitats.Cemetery = {
	id = "Cemetery",
	name = "Ghost Cemetery",
	zones = {
		{
			id = "Gate",
			name = "Angel's Rest",
			rect = { x1 = -22, x2 = 22, z1 = -22, z2 = 22 },
			dark = false,
			gated = false,
			maxMonsters = 2,
			spawns = { Wisp = 1 },
		},
		{
			id = "OldRows",
			name = "Old Rows",
			rect = { x1 = 30, x2 = 90, z1 = 8, z2 = 60 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Wisp = 2, Hound = 2 },
		},
		{
			id = "Hollow",
			name = "Mausoleum Hollow",
			rect = { x1 = -40, x2 = 40, z1 = -98, z2 = -42 },
			dark = true,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 2, Gentleman = 2 },
		},
		{
			id = "Crypt",
			name = "Sealed Crypt",
			rect = { x1 = -88, x2 = -50, z1 = 6, z2 = 46 },
			dark = true,
			gated = true,
			maxMonsters = 2,
			spawns = { Gentleman = 2, BellWraith = 1 },
		},
	},
	landmarks = {
		{ id = "Angel", name = "Weeping Angel", zone = "Gate", position = Vector3.new(0, 0, 0) },
		{ id = "Hearse", name = "Broken Hearse", zone = "OldRows", position = Vector3.new(58, 0, 32) },
		{ id = "OldWell", name = "Old Well", zone = "OldRows", position = Vector3.new(84, 0, 52) },
		{ id = "Mausoleum", name = "Hollow Mausoleum", zone = "Hollow", position = Vector3.new(0, 0, -80) },
		{ id = "BellTower", name = "Bell Tower", position = Vector3.new(-30, 0, 62) },
	},
	paths = {
		{
			id = "SouthPath",
			width = 8,
			points = { gateStart(1), Vector3.new(8, 0, 76), Vector3.new(-6, 0, 44), Vector3.new(0, 0, 24) },
		},
		{
			id = "EastPath",
			width = 8,
			points = {
				gateStart(2),
				Vector3.new(73.3, 0, -33.1),
				Vector3.new(38.6, 0, -29.2),
				Vector3.new(20.8, 0, -12),
			},
		},
		{
			id = "WestPath",
			width = 8,
			points = {
				gateStart(3),
				Vector3.new(-73.3, 0, -33.1),
				Vector3.new(-38.6, 0, -29.2),
				Vector3.new(-20.8, 0, -12),
			},
		},
		-- Side routes: a winding loop through the grave rows, and a walk through the dark Hollow.
		{
			id = "OldRowsLoop",
			width = 6,
			points = {
				Vector3.new(1, 0, 62),
				Vector3.new(38, 0, 66),
				Vector3.new(68, 0, 46),
				Vector3.new(74, 0, 18),
				Vector3.new(68, 0, -32),
			},
		},
		{
			id = "HollowWalk",
			width = 6,
			points = {
				Vector3.new(38.6, 0, -29.2),
				Vector3.new(22, 0, -56),
				Vector3.new(-22, 0, -56),
				Vector3.new(-38.6, 0, -29.2),
			},
		},
		{
			id = "CryptLane",
			width = 6,
			points = { Vector3.new(-20.8, 0, 12), Vector3.new(-32, 0, 22), Vector3.new(-45, 0, 26) },
		},
	},
	gatePaths = { "SouthPath", "EastPath", "WestPath" },
	plaza = { center = Vector3.new(0, 0, 0), radius = 24 },
	-- Opens for house tiers with `unlocksCrypt` (EconomyRules.cryptOpen).
	crypt = {
		rect = { x1 = -92, x2 = -46, z1 = 2, z2 = 50 },
		gateSide = "x2",
		gateAt = 26,
		gateWidth = 10,
	},
	starter = { species = "Wisp", zone = "Gate", at = Vector3.new(12, 0, 12) },
} :: Habitat

-- Cursed Woodland: a forest clearing ringed by standing stones, a dark thicket round the Hollow Oak to the
-- north, and the hound dens east and west. Weighted to Hounds (ADR-0007).
Habitats.Woodland = {
	id = "Woodland",
	name = "Cursed Woodland",
	zones = {
		{
			id = "Clearing",
			name = "Stone Clearing",
			rect = { x1 = -22, x2 = 22, z1 = -22, z2 = 22 },
			dark = false,
			gated = false,
			maxMonsters = 2,
			spawns = { Wisp = 2, Hound = 1 },
		},
		{
			id = "Thicket",
			name = "Black Thicket",
			rect = { x1 = -40, x2 = 40, z1 = -98, z2 = -42 },
			dark = true,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 3, Gentleman = 1 },
		},
		{
			id = "Dens",
			name = "Hound Dens",
			rect = { x1 = 30, x2 = 88, z1 = 6, z2 = 58 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 3, Wisp = 1 },
		},
		{
			id = "Bramble",
			name = "Bramble Hollow",
			rect = { x1 = -88, x2 = -30, z1 = 6, z2 = 58 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 2, Wisp = 1 },
		},
	},
	landmarks = {
		{ id = "StandingStones", name = "Standing Stones", zone = "Clearing", position = Vector3.new(0, 0, 0) },
		{ id = "HollowOak", name = "Hollow Oak", zone = "Thicket", position = Vector3.new(0, 0, -74) },
	},
	paths = {
		{
			id = "SouthTrail",
			width = 7,
			points = {
				gateStart(1),
				Vector3.new(-12, 0, 84),
				Vector3.new(10, 0, 56),
				Vector3.new(-4, 0, 30),
				Vector3.new(0, 0, 20),
			},
		},
		{
			id = "EastTrail",
			width = 7,
			points = { gateStart(2), Vector3.new(70, 0, -50), Vector3.new(52, 0, -22), Vector3.new(20, 0, -10) },
		},
		{
			id = "WestTrail",
			width = 7,
			points = { gateStart(3), Vector3.new(-66, 0, -56), Vector3.new(-46, 0, -26), Vector3.new(-20, 0, -10) },
		},
		{
			id = "DenTrail",
			width = 5,
			points = { Vector3.new(18, 0, 14), Vector3.new(44, 0, 40), Vector3.new(76, 0, 28) },
		},
		{
			id = "BrambleTrail",
			width = 5,
			points = { Vector3.new(-18, 0, 14), Vector3.new(-50, 0, 46), Vector3.new(-76, 0, 22) },
		},
	},
	gatePaths = { "SouthTrail", "EastTrail", "WestTrail" },
	plaza = { center = Vector3.new(0, 0, 0), radius = 20 },
	starter = { species = "Wisp", zone = "Clearing", at = Vector3.new(12, 0, 12) },
} :: Habitat

-- Spider Woodland: webbed trees round a small glade, the Brood Tree's nest to the north, silk thickets
-- east and a cocoon hollow west. Weighted to Gentlemen (ADR-0007).
Habitats.SpiderWoodland = {
	id = "SpiderWoodland",
	name = "Spider Woodland",
	zones = {
		{
			id = "Glade",
			name = "Webbed Glade",
			rect = { x1 = -20, x2 = 20, z1 = -20, z2 = 20 },
			dark = false,
			gated = false,
			maxMonsters = 2,
			spawns = { Wisp = 1, Gentleman = 1 },
		},
		{
			id = "Nest",
			name = "Brood Nest",
			rect = { x1 = -36, x2 = 36, z1 = -96, z2 = -44 },
			dark = true,
			gated = false,
			maxMonsters = 3,
			spawns = { Gentleman = 3, Hound = 1 },
		},
		{
			id = "Silk",
			name = "Silk Thicket",
			rect = { x1 = 30, x2 = 86, z1 = 8, z2 = 58 },
			dark = true,
			gated = false,
			maxMonsters = 3,
			spawns = { Gentleman = 2, Wisp = 1 },
		},
		{
			id = "Cocoons",
			name = "Cocoon Hollow",
			rect = { x1 = -86, x2 = -30, z1 = 8, z2 = 58 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Gentleman = 2, Hound = 1 },
		},
	},
	landmarks = {
		{ id = "BroodTree", name = "Brood Tree", zone = "Nest", position = Vector3.new(0, 0, -72) },
		{ id = "CocoonCluster", name = "Cocoon Cluster", zone = "Cocoons", position = Vector3.new(-60, 0, 30) },
	},
	paths = {
		{
			id = "SouthSilk",
			width = 7,
			points = { gateStart(1), Vector3.new(14, 0, 82), Vector3.new(14, 0, 50), Vector3.new(0, 0, 20) },
		},
		{
			id = "EastSilk",
			width = 7,
			points = { gateStart(2), Vector3.new(78, 0, -30), Vector3.new(44, 0, -40), Vector3.new(18, 0, -14) },
		},
		{
			id = "WestSilk",
			width = 7,
			points = { gateStart(3), Vector3.new(-78, 0, -30), Vector3.new(-44, 0, -40), Vector3.new(-18, 0, -14) },
		},
		{
			id = "WebWalk",
			width = 5,
			points = { Vector3.new(14, 0, 50), Vector3.new(50, 0, 62), Vector3.new(72, 0, 30) },
		},
	},
	gatePaths = { "SouthSilk", "EastSilk", "WestSilk" },
	plaza = { center = Vector3.new(0, 0, 0), radius = 18 },
	starter = { species = "Wisp", zone = "Glade", at = Vector3.new(10, 0, 10) },
} :: Habitat

-- Zombie Settlement: a ruined village. Straight roads from the gates meet at the village square; farm rows
-- east, the chapel yard west and the barn field north. Mixes all three commons (ADR-0007).
Habitats.Settlement = {
	id = "Settlement",
	name = "Zombie Settlement",
	zones = {
		{
			id = "Square",
			name = "Village Square",
			rect = { x1 = -22, x2 = 22, z1 = -22, z2 = 22 },
			dark = false,
			gated = false,
			maxMonsters = 2,
			spawns = { Wisp = 1, Hound = 1, Gentleman = 1 },
		},
		{
			id = "Farm",
			name = "Farm Rows",
			rect = { x1 = 34, x2 = 88, z1 = -6, z2 = 50 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 2, Wisp = 1 },
		},
		{
			id = "ChapelYard",
			name = "Chapel Yard",
			rect = { x1 = -88, x2 = -34, z1 = -6, z2 = 50 },
			dark = true,
			gated = false,
			maxMonsters = 3,
			spawns = { Gentleman = 2, Wisp = 1 },
		},
		{
			id = "BarnField",
			name = "Barn Field",
			rect = { x1 = -38, x2 = 38, z1 = -98, z2 = -44 },
			dark = false,
			gated = false,
			maxMonsters = 3,
			spawns = { Hound = 1, Gentleman = 1, Wisp = 1 },
		},
	},
	landmarks = {
		{ id = "RuinedChapel", name = "Ruined Chapel", zone = "ChapelYard", position = Vector3.new(-62, 0, 18) },
		{ id = "OldBarn", name = "Old Barn", zone = "BarnField", position = Vector3.new(0, 0, -76) },
	},
	paths = {
		{
			id = "SouthRoad",
			width = 10,
			points = { gateStart(1), Vector3.new(0, 0, 60), Vector3.new(0, 0, 28) },
		},
		{
			id = "EastRoad",
			width = 10,
			points = { gateStart(2), Vector3.new(60, 0, -34), Vector3.new(24, 0, -14) },
		},
		{
			id = "WestRoad",
			width = 10,
			points = { gateStart(3), Vector3.new(-60, 0, -34), Vector3.new(-24, 0, -14) },
		},
		{
			id = "Lane",
			width = 6,
			points = { Vector3.new(-56, 0, 40), Vector3.new(0, 0, 40), Vector3.new(56, 0, 40) },
		},
	},
	gatePaths = { "SouthRoad", "EastRoad", "WestRoad" },
	plaza = { center = Vector3.new(0, 0, 0), radius = 28 },
	starter = { species = "Wisp", zone = "Square", at = Vector3.new(12, 0, 12) },
} :: Habitat

-- Rotation order (ADR-0007): Cemetery -> Woodland -> Spider Woodland -> Zombie Settlement.
Habitats.List = { Habitats.Cemetery, Habitats.Woodland, Habitats.SpiderWoodland, Habitats.Settlement } :: { Habitat }

Habitats.ById = {} :: { [string]: Habitat }
for _, h in Habitats.List do
	Habitats.ById[h.id] = h
end

-- The active habitat. The server's HabitatService sets it and mirrors it to the Workspace attribute
-- `ActiveHabitat`; the client copies that attribute here (LocalWorld).
local activeId = Habitats.List[1].id

function Habitats.active(): Habitat
	return Habitats.ById[activeId]
end

function Habitats.setActive(id: string): boolean
	if not Habitats.ById[id] then
		return false
	end
	activeId = id
	return true
end

function Habitats.zoneById(id: string): World.Zone?
	for _, z in Habitats.active().zones do
		if z.id == id then
			return z
		end
	end
	return nil
end

-- A zone of any habitat (the journal lists where a species lives across the whole rotation).
function Habitats.anyZoneById(id: string): (World.Zone?, Habitat?)
	for _, h in Habitats.List do
		for _, z in h.zones do
			if z.id == id then
				return z, h
			end
		end
	end
	return nil, nil
end

function Habitats.landmarkById(id: string): World.Landmark?
	for _, l in Habitats.active().landmarks do
		if l.id == id then
			return l
		end
	end
	return nil
end

-- The active habitat's zone containing (x, z), if any.
function Habitats.zoneAt(x: number, z: number): World.Zone?
	for _, zone in Habitats.active().zones do
		if World.inRect(zone.rect, x, z) then
			return zone
		end
	end
	return nil
end

-- The active habitat's walled crypt (its outer walls), if it has one.
function Habitats.cryptWalls(): World.Rect?
	local crypt = Habitats.active().crypt
	return if crypt then crypt.rect else nil
end

return Habitats
