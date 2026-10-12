--!strict
-- Variants are visual overlays on a base species model, kept separate from the species data.

export type Variant = {
	id: string,
	label: string,
	incomeMultiplier: number,
	tint: Color3?, -- recolours the body parts
	glow: Color3?, -- adds a light and sparkle effect
	chance: number, -- roll chance where allowed
	zones: { string }?, -- nil = any zone
}

local Variants = {}

Variants.Normal = "Normal"

Variants.List = {
	{
		id = "Spectral",
		label = "Spectral",
		incomeMultiplier = 1.5,
		tint = Color3.fromRGB(150, 230, 255),
		glow = Color3.fromRGB(120, 220, 255),
		chance = 0.1,
		zones = nil,
	},
	{
		id = "Ashen",
		label = "Ashen",
		incomeMultiplier = 1.75,
		tint = Color3.fromRGB(95, 92, 90),
		glow = Color3.fromRGB(255, 120, 60),
		chance = 0.3,
		zones = { "Crypt" }, -- environmental special variant: only in the Sealed Crypt
	},
} :: { Variant }

Variants.ById = {} :: { [string]: Variant }
for _, v in Variants.List do
	Variants.ById[v.id] = v
end

function Variants.multiplier(variantId: string): number
	local v = Variants.ById[variantId]
	return if v then v.incomeMultiplier else 1
end

-- Rolls a variant for a monster spawning in `zoneId` with ONE draw against cumulative chances, so every
-- allowed variant gets exactly its configured chance (Crypt: Ashen 30%, Spectral 10%, Normal 60%;
-- elsewhere: Spectral 10%). Zone-restricted variants only roll in their zones (ADR-0006 §2 and item 8).
function Variants.roll(zoneId: string, rng: Random): string
	local r = rng:NextNumber()
	local acc = 0
	for _, v in Variants.List do
		if v.zones == nil or table.find(v.zones, zoneId) ~= nil then
			acc += v.chance
			if r < acc then
				return v.id
			end
		end
	end
	return Variants.Normal
end

function Variants.label(variantId: string): string?
	local v = Variants.ById[variantId]
	return if v then v.label else nil
end

return Variants
