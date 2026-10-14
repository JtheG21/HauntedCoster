--!strict
-- The cosmetic catalog (TASK-0047, SYS-Haunted-Monetization-UI, ADR-0011): ghost skins, auras, capture effects,
-- mansion themes and exterior decorations. Cosmetics carry looks only; nothing here (or in CosmeticRules) is
-- read by income, rarity, speed, capacity, capture or retaliation code, and a spec proves the catalog has no
-- gameplay fields.
--
-- DRAFT (needs jg's approval before release): the launch assortment, every Coin price, the reward milestones and
-- the decoration placement limits below are proposals. Robux products are listed by key only: a product stays
-- disabled until jg configures its real id in `Products` (no fake prices; the Shop shows no Robux button for an
-- unconfigured product).

local Cosmetics = {}

export type Category = "Skin" | "Aura" | "CaptureEffect" | "Theme" | "Decoration"

export type Acquire = {
	coins: number?, -- earned-Coin price (draft)
	product: string?, -- key into Cosmetics.Products (direct Robux)
	reward: string?, -- milestone id in Cosmetics.Milestones
}

export type Item = {
	id: string,
	category: Category,
	name: string,
	blurb: string,
	species: { string }?, -- skins and auras: compatible species (nil = every species)
	tiers: { number }?, -- themes: supported house tiers (truthful coverage)
	acquire: Acquire,
	look: { [string]: any }, -- client-only presentation data (tints, materials, effect parameters, art keys)
	footprint: { x: number, z: number }?, -- decorations: plot-local footprint in studs (before rotation)
	limit: number?, -- decorations: copies that may be placed at once (one unlock, reusable placements)
	order: number,
}

Cosmetics.Categories = { "Skin", "Aura", "CaptureEffect", "Theme", "Decoration" } :: { Category }
Cosmetics.CategoryNames = {
	Skin = "Ghost Skins",
	Aura = "Auras",
	CaptureEffect = "Capture Effects",
	Theme = "Mansion Themes",
	Decoration = "Decorations",
}

local function c3(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local items: { Item } = {
	-- Ghost skins: per-part tints and materials over the creature art; natural variants still apply on top.
	{
		id = "skin_wisp_candlewick",
		category = "Skin",
		name = "Candlewick Wisp",
		blurb = "Dripping wax and a warm wick. The lantern burns a little brighter.",
		species = { "Wisp" },
		acquire = { coins = 400 },
		look = {
			tint = {
				Body = c3(255, 226, 170),
				ArmL = c3(255, 226, 170),
				ArmR = c3(255, 226, 170),
				Lamp = c3(255, 170, 70),
			},
		},
		order = 1,
	},
	{
		id = "skin_wisp_moonlit",
		category = "Skin",
		name = "Moonlit Wisp",
		blurb = "Silvered by a cold moon, with a pale blue lantern.",
		species = { "Wisp" },
		acquire = { product = "skin_wisp_moonlit" },
		look = {
			tint = {
				Body = c3(190, 214, 255),
				ArmL = c3(190, 214, 255),
				ArmR = c3(190, 214, 255),
				Lamp = c3(150, 200, 255),
			},
		},
		order = 2,
	},
	{
		id = "skin_hound_calico",
		category = "Skin",
		name = "Calico Hound",
		blurb = "Three patterns, three heads' worth of opinions.",
		species = { "Hound" },
		acquire = { coins = 600 },
		look = {
			tint = {
				Body = c3(255, 186, 120),
				Head = c3(255, 240, 220),
				Head2 = c3(150, 110, 80),
				Tail = c3(255, 186, 120),
			},
		},
		order = 3,
	},
	{
		id = "skin_hound_bone",
		category = "Skin",
		name = "Bone-Plated Hound",
		blurb = "Polished bone over the stitches. Rattles when it runs.",
		species = { "Hound" },
		acquire = { reward = "habitat_woodland" },
		look = {
			tint = { Body = c3(255, 246, 225), Head = c3(255, 246, 225), Head2 = c3(255, 246, 225) },
			material = { Body = "Marble", Head = "Marble", Head2 = "Marble" },
		},
		order = 4,
	},
	{
		id = "skin_gentleman_crimson",
		category = "Skin",
		name = "Crimson Gentleman",
		blurb = "A velvet coat for the finest of empty heads.",
		species = { "Gentleman" },
		acquire = { coins = 900 },
		look = {
			tint = { Body = c3(255, 90, 100), ArmL = c3(255, 90, 100), ArmR = c3(255, 90, 100), Hat = c3(140, 50, 60) },
		},
		order = 5,
	},
	{
		id = "skin_gentleman_tweed",
		category = "Skin",
		name = "Tweed Gentleman",
		blurb = "Country tweed and a hunting cap. Still no face.",
		species = { "Gentleman" },
		acquire = { product = "skin_gentleman_tweed" },
		look = {
			tint = {
				Body = c3(220, 190, 140),
				ArmL = c3(220, 190, 140),
				ArmR = c3(220, 190, 140),
				Hat = c3(200, 170, 120),
			},
			material = { Body = "Fabric", ArmL = "Fabric", ArmR = "Fabric" },
		},
		order = 6,
	},
	{
		id = "skin_bellwraith_bronze",
		category = "Skin",
		name = "Bronze Bell Wraith",
		blurb = "Freshly cast bronze. It tolls a full tone lower.",
		species = { "BellWraith" },
		acquire = { reward = "habitat_cemetery" },
		look = { tint = { Body = c3(255, 170, 90), Clapper = c3(200, 130, 60) }, material = { Body = "Metal" } },
		order = 7,
	},
	-- Auras: one particle layer around the creature, readable next to the natural variant cues.
	{
		id = "aura_motes",
		category = "Aura",
		name = "Wisp Motes",
		blurb = "Drifting sparks of soft light.",
		acquire = { coins = 500 },
		look = { effect = "motes", color = c3(255, 214, 140), rate = 6 },
		order = 10,
	},
	{
		id = "aura_gravemist",
		category = "Aura",
		name = "Grave Mist",
		blurb = "A low green fog that follows at the heels.",
		acquire = { product = "aura_gravemist" },
		look = { effect = "mist", color = c3(120, 230, 150), rate = 3 },
		order = 11,
	},
	{
		id = "aura_moths",
		category = "Aura",
		name = "Moth Swarm",
		blurb = "Pale moths that circle and never land.",
		acquire = { reward = "variant_first" },
		look = { effect = "moths", color = c3(232, 226, 210), rate = 4 },
		order = 12,
	},
	-- Capture effects: a short burst when a capture is secured. Timing, success and the meter never change.
	{
		id = "capture_sparks",
		category = "CaptureEffect",
		name = "Soul Sparks",
		blurb = "The jar seals in a spray of violet sparks.",
		acquire = { coins = 300 },
		look = { effect = "sparks", color = c3(190, 130, 255) },
		order = 20,
	},
	{
		id = "capture_bats",
		category = "CaptureEffect",
		name = "Bat Flurry",
		blurb = "A flurry of bats bursts from the jar.",
		acquire = { product = "capture_bats" },
		look = { effect = "bats", color = c3(30, 24, 36) },
		order = 21,
	},
	{
		id = "capture_chains",
		category = "CaptureEffect",
		name = "Spectral Chains",
		blurb = "Ghostly chains wrap the jar, then fade.",
		acquire = { reward = "bestiary_half" },
		look = { effect = "chains", color = c3(140, 230, 255) },
		order = 22,
	},
	-- Mansion themes: per-part tints over every house tier's art (all three tiers share the part names).
	{
		id = "theme_bone",
		category = "Theme",
		name = "Bone & Ash",
		blurb = "Bleached siding, charcoal shingles and bone-white trim.",
		tiers = { 0, 1, 2 },
		acquire = { coins = 1500 },
		look = {
			tint = {
				Walls = c3(196, 188, 172),
				Trim = c3(64, 60, 58),
				Roof = c3(44, 42, 46),
				Glass = c3(255, 236, 190),
			},
		},
		order = 30,
	},
	{
		id = "theme_harvest",
		category = "Theme",
		name = "Pumpkin Harvest",
		blurb = "Burnt-orange boards, moss-green trim and candle-gold windows.",
		tiers = { 0, 1, 2 },
		acquire = { product = "theme_harvest" },
		look = {
			tint = {
				Walls = c3(150, 78, 36),
				Trim = c3(70, 92, 52),
				Roof = c3(52, 40, 34),
				Glass = c3(255, 190, 90),
			},
		},
		order = 31,
	},
	{
		id = "theme_frost",
		category = "Theme",
		name = "Moonlit Frost",
		blurb = "Ice-blue walls, silver trim and cold white windows.",
		tiers = { 0, 1, 2 },
		acquire = { reward = "bestiary_complete" },
		look = {
			tint = {
				Walls = c3(92, 112, 140),
				Trim = c3(200, 212, 228),
				Roof = c3(48, 58, 78),
				Glass = c3(200, 230, 255),
			},
		},
		order = 32,
	},
	-- Exterior decorations: one unlock, placed up to `limit` times on the owner's plot.
	{
		id = "deco_pumpkin",
		category = "Decoration",
		name = "Jack-o'-Lantern",
		blurb = "A grinning pumpkin with a candle inside.",
		acquire = { coins = 150 },
		look = { art = "pumpkin_lit", scale = 1 },
		footprint = { x = 2, z = 2 },
		limit = 8,
		order = 40,
	},
	{
		id = "deco_lamp",
		category = "Decoration",
		name = "Iron Lamp Post",
		blurb = "A tall lamp with a warm hanging lantern.",
		acquire = { coins = 400 },
		look = { art = "lamp_post", scale = 1, light = true },
		footprint = { x = 2, z = 2 },
		limit = 4,
		order = 41,
	},
	{
		id = "deco_headstone",
		category = "Decoration",
		name = "Mossy Headstone",
		blurb = "Name worn away. Probably nobody you knew.",
		acquire = { coins = 250 },
		look = { art = "grave_headstone", scale = 1 },
		footprint = { x = 3, z = 2 },
		limit = 6,
		order = 42,
	},
	{
		id = "deco_cross",
		category = "Decoration",
		name = "Celtic Cross",
		blurb = "Carved knotwork on weathered stone.",
		acquire = { coins = 300 },
		look = { art = "grave_cross", scale = 1 },
		footprint = { x = 3, z = 2 },
		limit = 6,
		order = 43,
	},
	{
		id = "deco_haybale",
		category = "Decoration",
		name = "Hay Bale",
		blurb = "Good for sitting on. Something lives inside.",
		acquire = { coins = 200 },
		look = { art = "hay_bale", scale = 1 },
		footprint = { x = 4, z = 3 },
		limit = 6,
		order = 44,
	},
	{
		id = "deco_coffin",
		category = "Decoration",
		name = "Open Coffin",
		blurb = "The lid is ajar. The occupant is out.",
		acquire = { product = "deco_coffin" },
		look = { art = "coffin", scale = 1 },
		footprint = { x = 3, z = 7 },
		limit = 3,
		order = 45,
	},
	{
		id = "deco_angel",
		category = "Decoration",
		name = "Little Weeping Angel",
		blurb = "A garden-sized angel. Don't blink.",
		acquire = { reward = "habitat_spider" },
		look = { art = "landmark_angel", scale = 0.4 },
		footprint = { x = 4, z = 4 },
		limit = 2,
		order = 46,
	},
	{
		id = "deco_candles",
		category = "Decoration",
		name = "Candle Cluster",
		blurb = "Half-melted candles that never quite go out.",
		acquire = { reward = "habitat_settlement" },
		look = { art = "candles", scale = 1, light = true },
		footprint = { x = 2, z = 2 },
		limit = 8,
		order = 47,
	},
}

Cosmetics.Items = items
Cosmetics.ById = {} :: { [string]: Item }
for _, item in items do
	Cosmetics.ById[item.id] = item
end

-- Direct-Robux products by key. `productId` stays nil until jg configures a real developer product in the
-- Creator Dashboard; an unconfigured product cannot be bought (no prompt, no price shown).
Cosmetics.Products = {
	skin_wisp_moonlit = { productId = nil :: number?, item = "skin_wisp_moonlit" },
	skin_gentleman_tweed = { productId = nil :: number?, item = "skin_gentleman_tweed" },
	aura_gravemist = { productId = nil :: number?, item = "aura_gravemist" },
	capture_bats = { productId = nil :: number?, item = "capture_bats" },
	theme_harvest = { productId = nil :: number?, item = "theme_harvest" },
	deco_coffin = { productId = nil :: number?, item = "deco_coffin" },
} :: { [string]: { productId: number?, item: string } }

-- Collection milestones (cosmetic rewards only). Habitat completion = every species that spawns there caught;
-- `bestiary_half` / `bestiary_complete` count species and natural variants discovered.
export type Milestone = { id: string, name: string, kind: string, habitat: string?, need: number? }
Cosmetics.Milestones = {
	{ id = "habitat_cemetery", name = "Ghost Cemetery complete", kind = "habitat", habitat = "Cemetery" },
	{ id = "habitat_woodland", name = "Whispering Woodland complete", kind = "habitat", habitat = "Woodland" },
	{ id = "habitat_spider", name = "Spider Woodland complete", kind = "habitat", habitat = "SpiderWoodland" },
	{ id = "habitat_settlement", name = "Zombie Settlement complete", kind = "habitat", habitat = "Settlement" },
	{ id = "variant_first", name = "First natural variant", kind = "variants", need = 1 },
	{ id = "bestiary_half", name = "Half the Bestiary", kind = "bestiary", need = 0.5 },
	{ id = "bestiary_complete", name = "Complete Bestiary", kind = "bestiary", need = 1 },
} :: { Milestone }
Cosmetics.MilestoneById = {} :: { [string]: Milestone }
for _, m in Cosmetics.Milestones do
	Cosmetics.MilestoneById[m.id] = m
end

-- Placement bounds (plot-local studs) and caps for exterior decorations.
Cosmetics.Placement = {
	maxPlaced = 24, -- all decorations on one plot
	grid = 1, -- snap step
	fine = 0.25, -- finer step allowed inside the editor
	rotationStep = 15, -- degrees
	margin = 1.5, -- clearance kept from walls, gameplay areas and other decorations
}

return Cosmetics
