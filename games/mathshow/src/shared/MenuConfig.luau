--!strict
-- Tunables for the MathShow menu (client/Menu, MenuRules). Frozen: never mutate at runtime. Strings: MenuCopy.

local MenuConfig = table.freeze({
	-- Mode availability (ModeRules.cardState). Missing or false = locked (COMING SOON). Only Group Battle exists today.
	ModeEnabled = table.freeze({ blitz = false, vs = false, group = true }),
	-- Secondary menu items (ModeRules.secondaryState).
	SecondaryEnabled = table.freeze({
		howto = true,
		practice = false,
		leaderboard = false,
		daily = false,
		drills = false,
	}),
	RetakeCooldownSeconds = 300,
	NameMax = 20,
	ToastSeconds = 1.6, -- how long the COMING SOON toast stays
	-- Local-only settings defaults (no SettingsSave yet): README 17a values.
	SettingsDefaults = table.freeze({
		music = 7,
		sfx = 8,
		reducedMotion = false,
		colorBlind = true,
		haptics = true,
	}),
	SettingMax = 10,
	TextFitMargin = 6, -- px between text and the shard edge (audit), enforced by tests/studio/TextFit
})

return MenuConfig
