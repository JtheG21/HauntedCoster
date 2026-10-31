--!strict
-- MathShow identity v3: layout, color and asset tables. Deep-frozen. Values match README.

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

local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

export type TierKey = "plastic" | "bronze" | "copper" | "silver" | "gold" | "emerald" | "platinum" | "diamond" | "demon"

local Theme = {
	TierOrder = { "plastic", "bronze", "copper", "silver", "gold", "emerald", "platinum", "diamond", "demon" },

	Tier = {
		plastic = { Image = "rank-plastic-v3", Glow = "glow-menu-rank-plastic-v3", Rgb = rgb(235, 230, 215) },
		bronze = { Image = "rank-bronze", Glow = "glow-menu-rank-bronze", Rgb = rgb(230, 150, 90) },
		copper = { Image = "rank-copper", Glow = "glow-menu-rank-copper", Rgb = rgb(214, 112, 70) },
		silver = { Image = "rank-silver", Glow = "glow-menu-rank-silver", Rgb = rgb(220, 228, 240) },
		gold = { Image = "rank-gold", Glow = "glow-menu-rank-gold", Rgb = rgb(255, 200, 60) },
		emerald = { Image = "rank-emerald", Glow = "glow-menu-rank-emerald", Rgb = rgb(40, 214, 140) },
		platinum = { Image = "rank-platinum", Glow = "glow-menu-rank-platinum", Rgb = rgb(190, 240, 255) },
		diamond = { Image = "rank-diamond-v3", Glow = "glow-menu-rank-diamond-v3", Rgb = rgb(110, 210, 255) },
		demon = { Image = "rank-demon", Glow = "glow-menu-rank-demon", Rgb = rgb(255, 60, 40) },
	},
	BadgeSizes = { Row = 24, Card = 48, Hero = 120, HeroGlow = 192 },

	Icon = {
		ModeGroup = "icon-mode-group",
		ModeTeam = "icon-mode-team",
		ModeBlitz = "icon-mode-blitz",
		FormatDirect = "icon-format-direct",
		FormatChoice = "icon-format-choice",
		Bot = "icon-id-bot",
		You = "icon-id-you",
		Provisional = "icon-id-provisional",
		Unlock = "icon-id-unlock",
		Disconnect = "icon-id-disconnect",
		Eye = "icon-id-eye",
		Up = "icon-id-up",
		Down = "icon-id-down",
		Same = "icon-id-same",
		PortraitFallback = "icon-id-portrait-fallback",
		Check = "icon-menu-check",
		Star = "icon-menu-star",
	},

	-- SliceCenter in image px (2x PNGs). Horizontal 9-slice only.
	Slice = {
		Track = Rect.new(32, 0, 368, 76),
		Tag = Rect.new(24, 0, 136, 60),
		Status = Rect.new(28, 0, 292, 64),
		Card = Rect.new(36, 0, 364, 88),
		Pill = Rect.new(24, 0, 104, 56),
		Progress = Rect.new(16, 0, 224, 32),
		ProgressOpen = Rect.new(16, 0, 239, 32),
		CardGlow = Rect.new(108, 0, 436, 232),
	},
	SliceScale = 0.5, -- 2x art at 1x layout; progress card strip uses 0.25

	Track = {
		Height = 38,
		Width = { Compact = 96, Standard = 248, Long = 352 },
		Mode = { X = 12, Y = 9, Size = 20 },
		Badge = { X = 38, CompactX = 36, Y = 7, Size = 24 },
		Text = { X = 68, Y = 11, Size = 13, LineHeight = 16, StandardW = 148, LongW = 272 },
		Format = { X = 220, CompactX = 66, Y = 11, Size = 16 },
	},

	Tag = { Height = 30, PadX = 10, MinWidth = 48, TextSize = 13, TextY = 7 },
	Status = { Height = 32, IconX = 11, IconY = 9, IconSize = 14, TextX = 31, TextY = 9, TextSize = 12, PadRight = 11 },
	StatusSlot = { Size = 20, IconSize = 14, Color = rgb(11, 10, 13) },
	StatusStyle = {
		SUBMITTED = { Shard = "shard-id-status-silver", Icon = "Check", Ink = rgb(255, 255, 255) },
		FIRST_CORRECT = { Shard = "shard-id-status-gold", Icon = "Star", Ink = rgb(255, 255, 255) },
		BOT = { Shard = "shard-id-status-indigo", Icon = "Bot", Ink = rgb(255, 255, 255) },
		YOU = { Shard = "shard-id-status-white", Icon = "You", Ink = rgb(11, 10, 13) },
		PROVISIONAL = { Shard = "shard-id-status-violet", Icon = "Provisional", Ink = rgb(255, 255, 255) },
		CHALLENGE_UNLOCKED = { Shard = "shard-id-status-green", Icon = "Unlock", Ink = rgb(255, 255, 255) },
		DISCONNECTED = { Shard = "shard-id-status-red", Icon = "Disconnect", Ink = rgb(255, 255, 255) },
		WATCHING = { Shard = "shard-id-status-ink", Icon = "Eye", Ink = rgb(255, 255, 255) },
	},
	StatusPriority = { "DISCONNECTED", "WATCHING", "FIRST_CORRECT", "SUBMITTED", "YOU", "BOT" },

	CardShard = {
		Default = "shard-id-card-indigo",
		You = "shard-id-card-green",
		Bot = "shard-id-card-indigo",
		FirstCorrect = "shard-id-card-gold",
		Disconnected = "shard-id-card-ink",
		Spectating = "shard-id-card-ghost",
	},
	CardGlow = "glow-id-card-gold",

	Gameplay = {
		Size = Vector2.new(176, 44),
		Portrait = { X = 16, Y = 8, Size = 28, Stroke = 2 },
		Badge = { X = 52, Y = 10, Size = 24 },
		Name = { X = 82, Y = 8, W = 56, H = 14, Size = 13 },
		Score = { X = 82, Y = 22, W = 56, H = 14, Size = 13 },
		Slot = { X = 144, Y = 12 },
	},
	Reveal = { PillGap = 8, Pill = Vector2.new(64, 28), ReactionGap = 8, Reaction = 28 },
	Intro = {
		Size = Vector2.new(380, 204),
		Shard = "shard-id-intro-violet",
		Glow = "glow-id-intro-violet",
		Portrait = { X = 20, Y = 22, Size = 112, Stroke = 2 },
		TagY = 22,
		TagX = 148,
		ChipGap = 6,
		Name = { X = 148, Y = 60, W = 212, H = 42, Size = 17, LineHeight = 21, MaxLines = 2 },
		Track = { X = 20, Y = 146 },
		Emote = { X = 300, Y = 128, Size = 56 },
	},
	Results = {
		Size = Vector2.new(596, 44),
		Pitch = 50,
		Place = { X = 14, Y = 8, W = 26, H = 28, Size = 22 },
		Portrait = { X = 46, Y = 7, Size = 30, Stroke = 2 },
		Name = { X = 84, Y = 8, W = 150, H = 14, Size = 13 },
		Stat = { X = 84, Y = 22, W = 150, H = 15, Size = 13 },
		RankPill = { X = 244, Y = 8, W = 72, H = 28, IconSize = 12 },
		Rewards = { X = 326, Y = 6, W = 80, H = 32, Gap = 6, Max = 3 },
	},

	Rail = {
		GroupBattle = { X = 44, Y = 58, Pitch = 50 },
		TeamHeaderH = 18,
		ThreeVThree = { X = 44, HeaderY = { 54, 218 }, CardY = { { 76, 122, 168 }, { 240, 286, 332 } } },
		QuestionShift = { ProblemX = 232, ProblemW = 400, TimerX = 262, TimerW = 360, AnswerX = 240 },
		ProblemSize = { 64, 56, 48 },
	},

	Team = {
		A = { Color = rgb(63, 168, 255), Marker = "diamond" },
		B = { Color = rgb(255, 90, 106), Marker = "square" },
	},

	Progress = {
		Profile = Vector2.new(300, 16),
		Strip = Vector2.new(120, 8),
		StripSliceScale = 0.25,
		Track = "shard-id-progress-track",
		Fill = "shard-id-progress-fill",
		Open = "shard-id-progress-open",
		MinFill = 16,
		PreviewTransparency = 0.45,
		Tick = Vector2.new(2, 24),
		Gain = rgb(90, 255, 80),
		Loss = rgb(255, 60, 40),
		Provisional = { Color = rgb(170, 80, 255), Segments = 5, SegmentW = 56, Gap = 4, UnplayedTransparency = 0.8 },
		ValueGap = 16,
	},

	Fx = {
		RowIn = { Time = 0.34, Stagger = 0.06 },
		Reorder = 0.40,
		PillPop = 0.36,
		Flash = 0.42,
		Breathe = 2.4,
		FillTween = 0.60,
		PreviewBlink = 0.8,
		IntroSlam = 0.52,
		UnlockPop = 0.38,
	},
}

return freeze(Theme)
