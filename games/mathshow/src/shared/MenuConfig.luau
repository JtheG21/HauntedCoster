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
	BlitzTotal = 10, -- questions in a Blitz run (BlitzRules, TASK-0103); also the highest stored blitz best
	MenuRequestsPer30s = 5, -- server rate limits, ProfileService (ENGINEERING_NEEDS)
	-- ENGINEERING_NEEDS says 1 per second; a client debounce of 1 s plus network jitter can bunch two saves, so allow 2 per 2 s
	-- (same average) rather than drop the player's latest change.
	SettingsSavesPerWindow = 2,
	SettingsSaveWindowSeconds = 2,
	SettingsSaveDebounceSeconds = 1, -- client: send this long after the last change
	TextFitMargin = 6, -- px between text and the shard edge (audit), enforced by tests/studio/TextFit
})

return MenuConfig
