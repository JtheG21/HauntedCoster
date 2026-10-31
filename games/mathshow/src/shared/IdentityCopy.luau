--!strict
-- MathShow identity v3: every user-facing string. ALL CAPS live here (no TextTransform).

local function freeze<T>(t: T): T
	if type(t) == "table" then
		for _, v in t :: any do
			if type(v) == "table" and not table.isfrozen(v) then
				freeze(v)
			end
		end
		table.freeze(t :: any)
	end
	return t
end

local Copy = {
	Tier = {
		plastic = "PLASTIC",
		bronze = "BRONZE",
		copper = "COPPER",
		silver = "SILVER",
		gold = "GOLD",
		emerald = "EMERALD",
		platinum = "PLATINUM",
		diamond = "DIAMOND",
		demon = "DEMON",
	},
	Mode = { group = "GROUP", team = "3V3", blitz = "BLITZ" },
	ModeLong = { group = "GROUP BATTLE", team = "3V3", blitz = "BLITZ" },
	Format = { direct = "DIRECT ANSWER", choice = "MULTIPLE CHOICE" },
	TrackSep = " · ", -- U+00B7, in the checked glyph set

	Status = {
		SUBMITTED = "SUBMITTED",
		FIRST_CORRECT = "FIRST CORRECT",
		BOT = "BOT",
		YOU = "YOU",
		PROVISIONAL = "PROVISIONAL",
		CHALLENGE_UNLOCKED = "CHALLENGE UNLOCKED",
		DISCONNECTED = "DISCONNECTED",
		WATCHING = "WATCHING",
	},

	TagFormat = "[%s]",
	BotNameFormat = "BOT %s",
	Emote = "EMOTE",
	TeamHeaderFormat = "TEAM %s · %d %s",
	Point = "PT",
	Points = "PTS",
	TeamName = { A = "BLUE", B = "RED" },

	Stat = {
		CorrectFormat = "%d/%d correct",
		FirstsFormat = " · %d first",
		LeftAtFormat = "left at Q%d",
		WatchedFromFormat = "watched from Q%d",
	},
	Minus = "−", -- U+2212, in the checked glyph set
	Plus = "+",

	Progress = {
		ValueFormat = "%d / 100",
		GainFormat = "%d + %d",
		LossFormat = "%d − %d",
		GainHint = "if you win",
		LossHint = "if you lose",
		Provisional = "PROVISIONAL",
		ProvisionalHintFormat = "%d of %d placement matches",
		StripProvisionalFormat = "%d / %d",
		ChallengeUnlocked = "CHALLENGE UNLOCKED",
		StandingFormat = "STANDING %d",
		StripStandingFormat = "NO. %d",
		NoNextTier = "no next tier",
	},

	Reward = { XpFormat = "+%d XP", Streak = "STREAK", Mvp = "MVP", First = "FIRST" },
}

return freeze(Copy)
