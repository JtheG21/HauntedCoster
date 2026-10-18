--!strict
-- Asset ids for the rare capture finisher (TASK-0054), picked from the VFX Studio Toolbox plugin's
-- library in Place1 on 2026-10-17 (ids read from the plugin's own info panel and mesh parts).
-- RIGHTS ARE UNVERIFIED: these are third-party uploads reached through a plugin; no licence or
-- permission terms were checked. Treat as placeholder visuals until jg decides; if an asset fails to
-- load the effect simply skips it (see client/RareCaptureFinisher.luau).

local FinisherAssets = {}

FinisherAssets.Meshes = {
	groundRings = 2855433036, -- "Chase Whirl": flat concentric rings, about 25 studs across
	tube = 13643725981, -- "HollowedCylinder", 2.5 stud cube; scaled tall for the pillar
	vortex = 5922652488, -- "Shock": tall helix, about 4 x 5 x 4
	shockRing = 6063634156, -- "Wave3": thin flat ring, 2.2 studs across
	windRing = 3454554153, -- "growing wind": wide ring, 10 x 2.4 x 10
}

FinisherAssets.Textures = {
	lightningA = "rbxassetid://12402856027",
	lightningB = "rbxassetid://243043229",
	mandala = "rbxassetid://12402928708",
	sparkle = "rbxassetid://12386386944",
	radialBurst = "rbxassetid://12386392796",
	glow = "rbxassetid://11425477167",
	glowRing = "rbxassetid://12386390257",
}

return FinisherAssets
