--!strict
-- Data-driven monster roster. Add a species here (plus a builder in server/World/MonsterModels)
-- and every system (spawns, capture, income, journal) picks it up.

export type Rarity = "Common" | "Uncommon" | "Rare"

export type Species = {
	id: string,
	name: string,
	family: string,
	rarity: Rarity,
	incomePerSecond: number,
	roamSpeed: number, -- studs/s
	hover: number, -- height of the model root above the ground
	blurb: string,
	clueLandmark: string, -- landmark whose clue describes this species
	requiresFlag: string?, -- profile flag needed to capture (special encounter)
	maxAlive: number?, -- server-wide cap (keeps rares rare)
}

export type CaptureTuning = {
	period: number, -- seconds for the needle to sweep 0 -> 1 -> 0
	zoneWidth: number, -- fraction of the bar
	hitsNeeded: number,
	missesAllowed: number,
	returnSeconds: number,
}

local Monsters = {}

Monsters.Species = {
	Wisp = {
		id = "Wisp",
		name = "Lantern Wisp",
		family = "Ghost",
		rarity = "Common",
		incomePerSecond = 1,
		roamSpeed = 5,
		hover = 4,
		blurb = "A flickering spirit drawn to lantern light.",
		clueLandmark = "Angel",
	},
	Hound = {
		id = "Hound",
		name = "Stitched Hound",
		family = "Distorted Animal",
		rarity = "Common",
		incomePerSecond = 1.5,
		roamSpeed = 7,
		hover = 2.2,
		blurb = "Sewn together from three dogs. Two of them still disagree.",
		clueLandmark = "Hearse",
	},
	Gentleman = {
		id = "Gentleman",
		name = "Hollow Gentleman",
		family = "Unsettling Figure",
		rarity = "Uncommon",
		incomePerSecond = 3,
		roamSpeed = 4,
		hover = 4.5,
		blurb = "Tips his hat. There is nothing under the hat.",
		clueLandmark = "Mausoleum",
	},
	BellWraith = {
		id = "BellWraith",
		name = "Bell Wraith",
		family = "Bizarre",
		rarity = "Rare",
		incomePerSecond = 8,
		roamSpeed = 3,
		hover = 6,
		blurb = "A cracked funeral bell that rings itself. Only answers those who heard the tower's toll.",
		clueLandmark = "BellTower",
		requiresFlag = "bellClue",
		maxAlive = 1,
	},
} :: { [string]: Species }

-- Journal order.
Monsters.Order = { "Wisp", "Hound", "Gentleman", "BellWraith" }

Monsters.Capture = {
	-- Tuned so blind mashing succeeds roughly 50% / 30% / 10% (Common / Uncommon / Rare) while a timed press
	-- is reliable (see CaptureRules.spec "mashing" test).
	Common = { period = 1.6, zoneWidth = 0.2, hitsNeeded = 1, missesAllowed = 2, returnSeconds = 75 },
	Uncommon = { period = 1.2, zoneWidth = 0.14, hitsNeeded = 2, missesAllowed = 3, returnSeconds = 90 },
	Rare = { period = 1.0, zoneWidth = 0.1, hitsNeeded = 3, missesAllowed = 3, returnSeconds = 120 },
} :: { [Rarity]: CaptureTuning }

Monsters.RarityColor = {
	Common = Color3.fromRGB(190, 200, 210),
	Uncommon = Color3.fromRGB(120, 220, 140),
	Rare = Color3.fromRGB(255, 190, 70),
} :: { [Rarity]: Color3 }

return table.freeze(Monsters)
