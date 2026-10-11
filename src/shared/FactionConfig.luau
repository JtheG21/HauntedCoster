--!strict
-- Factions (TASK-0003). Original archetypes only; see ADR-0003 (no franchise names or likenesses).

export type FactionDef = {
	displayName: string,
	color: Color3,
}

local FactionConfig = table.freeze({
	-- Factions assigned in the current build, in tie-break order. M2 uses two; M3 adds Corsairs and Blades.
	Active = table.freeze({ "Shinobi", "Ki" }),

	Factions = table.freeze({
		Shinobi = table.freeze({ displayName = "Shinobi Clan", color = Color3.fromRGB(70, 90, 160) }),
		Ki = table.freeze({ displayName = "Ki Vanguard", color = Color3.fromRGB(240, 170, 40) }),
		Corsairs = table.freeze({ displayName = "Tide Corsairs", color = Color3.fromRGB(40, 160, 170) }),
		Blades = table.freeze({ displayName = "Spirit Blades", color = Color3.fromRGB(150, 60, 170) }),
	}) :: { [string]: FactionDef },

	AttributeName = "Faction",
})

return FactionConfig
