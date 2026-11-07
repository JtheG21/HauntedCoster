--!strict
-- Frozen cosmetic unlocks derived from level: a title every 5 levels, a nameplate colour every 10. XP is never spent.
-- Colours are plain RGB (0-255) so this module stays free of Instances.

export type Title = { level: number, name: string }
export type Plate = { level: number, name: string, r: number, g: number, b: number }
export type Rewards = { title: Title?, plate: Plate? }

local function title(level: number, name: string): Title
	return table.freeze({ level = level, name = name })
end

local function plate(level: number, name: string, r: number, g: number, b: number): Plate
	return table.freeze({ level = level, name = name, r = r, g = g, b = b })
end

local Titles: { Title } = table.freeze({
	title(5, "Number Rookie"),
	title(10, "Quick Counter"),
	title(15, "Sum Seeker"),
	title(20, "Times Tamer"),
	title(25, "Fraction Finder"),
	title(30, "Equation Ace"),
	title(35, "Prime Hunter"),
	title(40, "Math Wizard"),
	title(45, "Grand Calculator"),
	title(50, "MathShow Legend"),
})

local Plates: { Plate } = table.freeze({
	plate(10, "Silver Mist", 200, 210, 225),
	plate(20, "Holo Cyan", 63, 224, 240),
	plate(30, "Lamp Amber", 255, 181, 71),
	plate(40, "Menu Violet", 138, 77, 255),
	plate(50, "Pearl White", 245, 245, 250),
})

local LevelRewards = {
	Titles = Titles,
	Plates = Plates,
}

-- The highest title and plate unlocked at `level`, or nil when neither is unlocked yet (or the level is invalid).
function LevelRewards.rewardsFor(level: number): Rewards?
	if typeof(level) ~= "number" or level ~= level then
		return nil
	end
	local current: Title? = nil
	for _, entry in Titles do
		if level >= entry.level then
			current = entry
		end
	end
	local currentPlate: Plate? = nil
	for _, entry in Plates do
		if level >= entry.level then
			currentPlate = entry
		end
	end
	if current == nil and currentPlate == nil then
		return nil
	end
	return { title = current, plate = currentPlate }
end

return table.freeze(LevelRewards)
