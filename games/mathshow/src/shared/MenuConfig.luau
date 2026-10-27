--!strict
-- Tunables for the MathShow menu (client/Menu, MenuRules). Frozen: never mutate at runtime. Strings: MenuCopy.

local MenuConfig = table.freeze({
	-- Mode availability (ModeRules.cardState). Missing or false = locked (COMING SOON). Only Group Battle exists today.
	ModeEnabled = table.freeze({ blitz = true, vs = false, group = true }),
	-- Secondary menu items (ModeRules.secondaryState).
	SecondaryEnabled = table.freeze({
		howto = true,
		practice = true,
		skilltest = true, -- START on the Skill Test intro (TASK-0102); SkillTestService checks it too
		leaderboard = false,
		daily = false,
		drills = false,
	}),
	RetakeCooldownSeconds = 300,
	-- Skill Test (SkillRules, SkillTestService). jg defaults, TASK-0102: ranks 0-4 typed, 5-9 multiple choice.
	BlitzClockSeconds = 120, -- one clock for the whole run (jg default, TASK-0103)
	BlitzNextDelaySeconds = 0.6, -- after an answer, the next question slams in this much later
	BlitzGraceSeconds = 0.25,
	BlitzStartsPer10s = 4,
	BlitzAnswersPer10s = 14,
	SkillChoiceFromRank = 5,
	SkillTypedSeconds = 20,
	SkillChoiceSeconds = 25,
	SkillMaxMisses = 2, -- consecutive misses that end a run
	SkillGraceSeconds = 0.25, -- an answer this late still counts (the HUD's grace)
	SkillRevealSeconds = 3,
	SkillStartsPer10s = 4,
	SkillAnswersPer5s = 6,
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
	JoinsPer10s = 4, -- JoinShow rate limit (ENGINEERING_NEEDS: queue join 4 per 10 s)
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
