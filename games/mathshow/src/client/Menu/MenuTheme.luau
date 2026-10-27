--!strict
-- MathShow MENU theme additions ("Shards"). Pairs with client/Hud/Theme.luau (colors, fonts, HUD images).
-- Every number is a pixel on the 844x390 reference canvas. The menu root uses the same UIScale rule as the HUD:
-- scale = math.min(viewport.X / 844, viewport.Y / 390), inside ScreenInsets = DeviceSafeInsets.
-- Box = top-left x, y, size w, h, Rotation in degrees (applied to the outer Frame, never to the CanvasGroup).

export type Box = { x: number, y: number, w: number, h: number, rot: number }
export type Tier = {
	rank: number,
	key: string,
	name: string,
	subject: string,
	badge: string,
	glow: string,
	glowColor: Color3,
	pips: number,
}

local function box(x: number, y: number, w: number, h: number, rot: number): Box
	return { x = x, y = y, w = w, h = h, rot = rot }
end

local function deepFreeze<T>(t: T): T
	if type(t) == "table" and not table.isfrozen(t :: any) then
		for _, v in t :: any do
			deepFreeze(v)
		end
		table.freeze(t :: any)
	end
	return t
end

local MenuTheme = {}

MenuTheme.Reference = Vector2.new(844, 390)
MenuTheme.GlowPad = 36 -- every glow image = shard size + 36 px per side; animated CanvasGroups use the same pad
MenuTheme.FocusScale = 1.04 -- UIScale on the focused (gamepad) element, plus SelectionImageObject brackets
MenuTheme.PressScale = 0.95
MenuTheme.DisabledTransparency = 0.55 -- CanvasGroup.GroupTransparency for disabled / cooldown
MenuTheme.LockedInkTransparency = 0.4 -- locked labels are 60% white
MenuTheme.LobbyOverlayTransparency = 0.18 -- menu root: ground #0B0A0D over the live 3D lobby (82% opaque)
MenuTheme.TextStrokeTransparency = 0.6 -- black TextStroke on every white label over a shard
MenuTheme.NameMax = 20 -- see RULES_SPEC truncateName

-- Problem text size by character count of "problem eq" (extends Theme.ProblemSize for longer Skill Test items).
MenuTheme.ProblemSize = function(chars: number): number
	if chars <= 9 then
		return 88
	elseif chars <= 11 then
		return 76
	elseif chars <= 13 then
		return 64
	elseif chars <= 16 then
		return 56
	end
	return 48
end

MenuTheme.Gem = {
	red = Color3.fromRGB(255, 60, 40),
	blue = Color3.fromRGB(60, 140, 255),
	violet = Color3.fromRGB(170, 80, 255),
	green = Color3.fromRGB(90, 255, 80),
	silver = Color3.fromRGB(255, 255, 255), -- used at 0.65 transparency
}

MenuTheme.Color = {
	ButtonHover = Color3.fromRGB(226, 210, 255), -- ImageColor3 on shard-menu-action while hovered
	Locked = Color3.fromRGB(22, 20, 27),
	StepOn = Color3.fromRGB(255, 255, 255),
	StepOffTransparency = 0.82,
	MissUsed = Color3.fromRGB(255, 60, 40),
}

-- Text sizes (all <= 100; Roblox TextSize caps at 100).
MenuTheme.Text = {
	Title = 40, -- MATHSHOW logo (A2: 46 px does not fit the 330x88 shard; the gate decides)
	Primary = 28,
	Secondary = 15,
	Action = 19,
	PanelTitleMax = 58, -- per-screen value in Layout notes; see README
	PanelLine = 16,
	Tag = 11,
	Sticker = 10,
	CardTitle = 30,
	StepNumber = 54,
	StepTitle = 22,
	StepBody = 14,
	PlayerName = 18,
	TierName = 18,
	Subject = 13,
	VsName = 24,
	VsWord = 56,
	Countdown = 100,
	ElapsedClock = 60,
	BlitzClock = 60,
	Choice = 18,
	ChoiceLetter = 15,
	RowName = 15,
	RowSubject = 13,
	ReviewValue = 16,
	SettingLabel = 15, -- A4: 16 px ran into the toggle
	ToggleState = 12,
	Toast = 15, -- A10 follow-up: the toast shard (320x46) has a 28 px tall clear band, so 15 px text is the largest with slack for 6 px
	ActionWaiting = 16, -- A5: "WAITING FOR RIVAL" at 19 px is too wide for the action shard
}
-- Blitz score "n/10": TextScaled label 184x84, UITextSizeConstraint MinTextSize 48, MaxTextSize 84.
-- Panel text stack (A1), shard-local px. Titles are single lines; 3-line panels (Blitz, VS) use TitleSize3, Group uses
-- TitleSizeGroup. Line height is a multiplier: Leading / PanelLine.
MenuTheme.Panel = {
	TagY = 32, -- README 28: the tag ran 2.5 px into the panel's top-left cut
	TitleY = 52,
	LeftPad = 50,
	RightPad = 44,
	TitleSize3 = 50,
	TitleSizeGroup = 44,
	TitleToLines = 6,
	Leading = 20,
	LinesToTags = 8,
	TagGap = 6,
}
-- Toast width = text + 2 * PadX (+ IconExtra when it carries an icon) (A10).
MenuTheme.Toast = { PadX = 36, IconExtra = 24, Height = 46, IconSize = 16, TextY = 15, TextH = 15 }
MenuTheme.TagPadX = 8 -- README: tag padding 2 / 8, 11 px Bold, single line
MenuTheme.TagPadY = 2

MenuTheme.BlitzScoreBox = box(24, 52, 184, 84, 0)

MenuTheme.Layout = {
	-- shared chrome
	TopLabel = box(0, 14, 844, 16, 0), -- centered; VS and Skill Test use LeftTopLabel
	LeftTopLabel = box(170, 14, 630, 16, 0),
	Back = box(44, 332, 112, 44, -1), -- shard-menu-secondary-silver, icon-menu-back 14x14
	ToastTop = box(422, 8, 0, 40, -1), -- AnchorPoint (0.5, 0); width = text + 60
	ToastBottom = box(110, 338, 0, 46, -1), -- in-match, same as HUD Feedback
	-- 01 main
	Title = box(52, 52, 330, 88, -2),
	Play = box(60, 156, 290, 62, -1.5),
	Practice = box(72, 226, 290, 62, 1),
	Settings = box(60, 296, 290, 62, -1),
	PlayerCard = box(404, 56, 360, 156, 2), -- avatar 84x84 at (28,36); text column at (128,30) w 200
	HowToPlay = box(404, 218, 230, 44, 1),
	Leaderboard = box(412, 274, 230, 44, -1),
	DailyChallenge = box(404, 330, 230, 44, 1),
	-- 02 mode select / 18 how to play (same three slots)
	Card1 = box(52, 52, 232, 192, -2),
	Card2 = box(300, 46, 232, 192, 1.5),
	Card3 = box(548, 44, 232, 192, -2.5),
	-- panel screens (03, 04, 09, 11, 12, 15, 19)
	Panel = box(52, 56, 500, 224, -2), -- content padding 28 top, 50 left, 44 right
	Action = box(566, 84, 230, 64, 2), -- README 572: its rotated box ran 2 px into the 44 px right inset
	SideSecondary = box(576, 168, 220, 44, -1), -- README 580: right edge sat on the inset
	Count = box(588, 60, 200, 160, 3),
	RankOld = box(580, 96, 48, 48, 0),
	RankArrow = box(628, 108, 24, 24, 0),
	RankNew = box(652, 60, 120, 120, 0), -- glow-menu-rank-* 192x192 at (616, 24)
	BottomAction = box(60, 304, 230, 64, -1.5), -- 15 results
	BottomSecondary = box(306, 314, 200, 44, 1),
	-- 05 opponent found
	VsYou = box(52, 74, 330, 150, -3),
	VsThem = box(462, 58, 330, 150, 3),
	VsWord = box(382, 112, 80, 56, 0),
	VsCount = box(362, 236, 120, 124, 0), -- STARTS IN tag + 100 px number
	-- in-match (06, 08, 10, 13, 14); HUD boxes are in Theme.Layout
	BlitzClock = box(650, 84, 154, 80, 0), -- "1:42" at 60 px over "LEFT" tag
	HeadToHead = box(504, 6, 296, 44, 1.5), -- shard-score-silver stretched; bar 76x8 centered
	WatchBanner = box(110, 276, 480, 44, 1),
	RankStrip = box(300, 8, 500, 36, 0), -- 10 nodes 24 px (current 32), gap 10; MISSES + 2 slots 18x18
	ChoiceProblem = box(52, 46, 580, 150, -2), -- shard-menu-problem-silver, padding 30 top
	ChoiceTimerBar = box(92, 204, 520, 10, -1),
	ChoiceA = box(52, 222, 290, 54, -1),
	ChoiceB = box(356, 218, 290, 54, 1),
	ChoiceC = box(60, 282, 290, 54, 1),
	ChoiceD = box(364, 278, 290, 54, -1),
	ChoiceLockIn = box(500, 340, 150, 46, -1), -- HUD shard-button
	-- 07 blitz review
	ReviewCard = box(52, 48, 232, 192, -2),
	NewBest = box(196, 34, 104, 26, 6),
	PlayAgain = box(52, 262, 230, 64, -1.5),
	ReviewMenu = box(56, 336, 190, 44, 1),
	ReviewCol1 = box(312, 48, 234, 32, 0), -- 5 rows, pitch 38; header labels at y 32
	ReviewCol2 = box(562, 48, 234, 32, 0),
	-- 16 ladder (row i = 0 top .. 4 bottom); col 1 ranks 4..0, col 2 ranks 9..5
	LadderCol1 = box(52, 84, 340, 34, 0), -- pitch 40, rot alternates -0.8 / 0.8
	LadderCol2 = box(412, 44, 340, 34, 0),
	-- 17 settings
	SettingRow = box(52, 52, 520, 44, 0), -- pitch 50, rot alternates -0.5 / 0.5
	StepMinus = box(200, 0, 44, 44, 0), -- inside the row
	StepBars = box(254, 11, 176, 22, 0), -- 10 plain Frames 14x22, gap 4 (UIListLayout)
	StepValue = box(432, 0, 34, 44, 0),
	StepPlus = box(470, 0, 44, 44, 0),
	Toggle = box(200, 6, 76, 32, 0), -- knob 22x22 at x 48 (on) / 6 (off); state text at x 6 (on) / 34 (off)
	ToggleHint = box(290, 0, 220, 44, 0),
}
MenuTheme.LadderOffsets = { 0, 14, 4, 18, 8 }

-- Upload every PNG in assets/roblox/ and paste the ids. HUD images (shard-input, shard-button, shard-score-silver,
-- shard-problem-blue, shard-row-*, shard-toast-*, glow-toast-*, glow-problem-blue) come from Theme.Image.
MenuTheme.Image = {
	["shard-menu-title-violet"] = "rbxassetid://0",
	["shard-menu-primary-red"] = "rbxassetid://0",
	["shard-menu-primary-blue"] = "rbxassetid://0",
	["shard-menu-primary-silver"] = "rbxassetid://0",
	["shard-menu-secondary-silver"] = "rbxassetid://0",
	["shard-menu-secondary-locked"] = "rbxassetid://0",
	["shard-menu-player-violet"] = "rbxassetid://0",
	["shard-menu-mode-red"] = "rbxassetid://0",
	["shard-menu-mode-blue"] = "rbxassetid://0",
	["shard-menu-mode-violet"] = "rbxassetid://0",
	["shard-menu-mode-locked"] = "rbxassetid://0",
	["shard-menu-panel-red"] = "rbxassetid://0",
	["shard-menu-panel-blue"] = "rbxassetid://0",
	["shard-menu-panel-violet"] = "rbxassetid://0",
	["shard-menu-panel-green"] = "rbxassetid://0",
	["shard-menu-panel-silver"] = "rbxassetid://0",
	["shard-menu-count-blue"] = "rbxassetid://0",
	["shard-menu-count-red"] = "rbxassetid://0",
	["shard-menu-vs-you-green"] = "rbxassetid://0",
	["shard-menu-vs-them-violet"] = "rbxassetid://0",
	["shard-menu-choice-indigo"] = "rbxassetid://0",
	["shard-menu-choice-white"] = "rbxassetid://0",
	["shard-menu-choice-green"] = "rbxassetid://0",
	["shard-menu-choice-red"] = "rbxassetid://0",
	["shard-menu-action"] = "rbxassetid://0",
	["shard-menu-square-silver"] = "rbxassetid://0",
	["shard-menu-toggle-on"] = "rbxassetid://0",
	["shard-menu-toggle-off"] = "rbxassetid://0",
	["shard-menu-banner-violet"] = "rbxassetid://0",
	["shard-menu-problem-silver"] = "rbxassetid://0",
	["glow-menu-title-violet"] = "rbxassetid://0",
	["glow-menu-primary-red"] = "rbxassetid://0",
	["glow-menu-player-violet"] = "rbxassetid://0",
	["glow-menu-mode-red"] = "rbxassetid://0",
	["glow-menu-mode-blue"] = "rbxassetid://0",
	["glow-menu-mode-violet"] = "rbxassetid://0",
	["glow-menu-panel-red"] = "rbxassetid://0",
	["glow-menu-panel-blue"] = "rbxassetid://0",
	["glow-menu-panel-violet"] = "rbxassetid://0",
	["glow-menu-panel-green"] = "rbxassetid://0",
	["glow-menu-panel-silver"] = "rbxassetid://0",
	["glow-menu-count-blue"] = "rbxassetid://0",
	["glow-menu-count-red"] = "rbxassetid://0",
	["glow-menu-vsyou-green"] = "rbxassetid://0",
	["glow-menu-vsthem-violet"] = "rbxassetid://0",
	["glow-menu-choice-green"] = "rbxassetid://0",
	["glow-menu-banner-violet"] = "rbxassetid://0",
	["glow-menu-problem-silver"] = "rbxassetid://0",
	["glow-menu-rank-plastic"] = "rbxassetid://0",
	["glow-menu-rank-bronze"] = "rbxassetid://0",
	["glow-menu-rank-silver"] = "rbxassetid://0",
	["glow-menu-rank-gold"] = "rbxassetid://0",
	["glow-menu-rank-platinum"] = "rbxassetid://0",
	["glow-menu-rank-diamond"] = "rbxassetid://0",
	["glow-menu-rank-demon"] = "rbxassetid://0",
	["glow-menu-rank-white"] = "rbxassetid://0",
	["icon-menu-lock"] = "rbxassetid://0",
	["icon-menu-check"] = "rbxassetid://0",
	["icon-menu-cross"] = "rbxassetid://0",
	["icon-menu-star"] = "rbxassetid://0",
	["icon-menu-chevron"] = "rbxassetid://0",
	["icon-menu-back"] = "rbxassetid://0",
	["icon-menu-clock"] = "rbxassetid://0",
	["icon-menu-alert"] = "rbxassetid://0",
	["icon-menu-focus"] = "rbxassetid://0", -- 9-slice SelectionImageObject, SliceCenter Rect.new(24, 24, 72, 72)
	["rank-plastic"] = "rbxassetid://0",
	["rank-bronze"] = "rbxassetid://0",
	["rank-silver"] = "rbxassetid://0",
	["rank-gold"] = "rbxassetid://0",
	["rank-platinum"] = "rbxassetid://0",
	["rank-diamond"] = "rbxassetid://0",
	["rank-demon-1"] = "rbxassetid://0",
	["rank-demon-2"] = "rbxassetid://0",
	["rank-demon-3"] = "rbxassetid://0",
	["rank-demon-4"] = "rbxassetid://0",
}

-- Rank 0..9. Strings mirror MenuCopy.Rank; RankRules returns these by rank (see RULES_SPEC).
local function tier(rank: number, key: string, name: string, subject: string, badge: string, rgb: Color3, pips: number)
	return {
		rank = rank,
		key = key,
		name = name,
		subject = subject,
		badge = badge,
		glow = "glow-menu-rank-" .. key,
		glowColor = rgb,
		pips = pips,
	} :: Tier
end
local DEMON = Color3.fromRGB(255, 60, 40)
MenuTheme.Tiers = {
	[0] = tier(0, "plastic", "PLASTIC", "Starter", "rank-plastic", Color3.fromRGB(150, 148, 160), 0),
	[1] = tier(1, "bronze", "BRONZE", "Pre-algebra", "rank-bronze", Color3.fromRGB(230, 150, 90), 0),
	[2] = tier(2, "silver", "SILVER", "Algebra", "rank-silver", Color3.fromRGB(220, 228, 240), 0),
	[3] = tier(3, "gold", "GOLD", "Geometry", "rank-gold", Color3.fromRGB(255, 200, 60), 0),
	[4] = tier(4, "platinum", "PLATINUM", "Trigonometry", "rank-platinum", Color3.fromRGB(190, 240, 255), 0),
	[5] = tier(5, "diamond", "DIAMOND", "Precalculus", "rank-diamond", Color3.fromRGB(110, 210, 255), 0),
	[6] = tier(6, "demon", "DEMON I", "Calculus 1, first half", "rank-demon-1", DEMON, 1),
	[7] = tier(7, "demon", "DEMON II", "Calculus 1, second half", "rank-demon-2", DEMON, 2),
	[8] = tier(8, "demon", "DEMON III", "Calculus 2", "rank-demon-3", DEMON, 3),
	[9] = tier(9, "demon", "DEMON IV", "Calculus 3", "rank-demon-4", DEMON, 4),
}
MenuTheme.BadgeSizes = { Row = 24, Card = 48, Hero = 120 }

-- Gem per screen element (pairs with shard-menu-*-{gem} and glow-menu-*-{gem}).
MenuTheme.ModeGem = { blitz = "red", vs = "blue", group = "violet" }
MenuTheme.ResultGem = { win = "green", lose = "red", draw = "violet", forfeit = "green" }

return deepFreeze(MenuTheme)
