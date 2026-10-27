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
	Title = 46, -- MATHSHOW logo (Art v2: the 330x104 title shard holds 46 px; README, the gate decides)
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
	LadderName = 15, -- 16 rank ladder rungs: Art v2 rows are 38 px tall and hold README 15
	RowSubject = 13,
	ReviewQ = 13, -- Blitz review question number (README 13)
	ReviewValue = 16,
	SettingLabel = 16, -- README 16 (Art v2 row; the gate decides)
	ToggleState = 12,
	WatchBanner = 17, -- README 17 (Art v2 banner is 48 px tall with 20 px end slants)
	Toast = 18, -- Art v2 toast (46 px tall, flat middle): README 18
	H2HPoints = 20, -- head-to-head points (README 20)
	CountDraw = 100, -- sudden-death count number (README 100)
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
MenuTheme.Toast = { PadX = 24, IconExtra = 24, Height = 46, IconSize = 16, TextY = 14, TextH = 18 }
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
	Title = box(52, 44, 330, 104, -2), -- Art v2 title shard is 104 tall
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
	SkillProblem = box(52, 46, 580, 186, -2), -- 13: HUD Problem box
	SkillTimerBar = box(92, 244, 520, 10, -1),
	SkillInput = box(110, 270, 260, 58, 1),
	SkillLock = box(382, 270, 150, 58, 1),
	SkillSeconds = box(646, 64, 154, 130, 0),
	LadderLink = box(172, 332, 200, 44, 1), -- RANK LADDER beside BACK on the Practice home (not in the README: the ladder had no entry)
	SideSecondary = box(576, 168, 220, 44, -1), -- README 580: right edge sat on the inset
	Count = box(588, 48, 200, 184, 3), -- Art v2 count shard is 200x184
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
	HeadToHead = box(456, 2, 344, 52, 1.5), -- Art v2 h2h shard (fixed width, 344x52)
	WatchBanner = box(110, 274, 480, 48, 1), -- Art v2 banner is 48 tall
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

local UNSET = "rbxassetid://0"

-- Upload every PNG in assets/roblox/ and paste the ids. HUD images (shard-input, shard-button, shard-score-silver,
-- shard-problem-blue, shard-row-*, shard-toast-*, glow-toast-*, glow-problem-blue) come from Theme.Image.
MenuTheme.Image = {
	-- Art v2 (TASK-0107): ids stay unset until jg approves the upload (art/menu/UPLOAD_LIST.md).
	["shard-menu-row-indigo-v2"] = UNSET,
	["shard-menu-row-green-v2"] = UNSET,
	["shard-menu-toast-silver-v2"] = UNSET,
	["shard-menu-toast-green-v2"] = UNSET,
	["shard-menu-toast-red-v2"] = UNSET,
	["shard-menu-banner-violet-v2"] = UNSET,
	["shard-menu-h2h-silver-v2"] = UNSET,
	["shard-menu-count-blue-v2"] = UNSET,
	["shard-menu-count-red-v2"] = UNSET,
	["shard-menu-title-violet-v2"] = UNSET,
	["glow-menu-toast-silver-v2"] = UNSET,
	["glow-menu-toast-green-v2"] = UNSET,
	["glow-menu-toast-red-v2"] = UNSET,
	["glow-menu-banner-violet-v2"] = UNSET,
	["glow-menu-count-blue-v2"] = UNSET,
	["glow-menu-count-red-v2"] = UNSET,
	["glow-menu-title-violet-v2"] = UNSET,
	["shard-menu-title-violet"] = "rbxassetid://102403330056161",
	["shard-menu-primary-red"] = "rbxassetid://126024347039405",
	["shard-menu-primary-blue"] = "rbxassetid://80197953804871",
	["shard-menu-primary-silver"] = "rbxassetid://88300202955867",
	["shard-menu-secondary-silver"] = "rbxassetid://95740430669771",
	["shard-menu-secondary-locked"] = "rbxassetid://131488153339495",
	["shard-menu-player-violet"] = "rbxassetid://99835397323227",
	["shard-menu-mode-red"] = "rbxassetid://136320020746075",
	["shard-menu-mode-blue"] = "rbxassetid://100516437199349",
	["shard-menu-mode-violet"] = "rbxassetid://84371801101424",
	["shard-menu-mode-locked"] = "rbxassetid://133330341386528",
	["shard-menu-panel-red"] = "rbxassetid://133746810401781",
	["shard-menu-panel-blue"] = "rbxassetid://131374651429309",
	["shard-menu-panel-violet"] = "rbxassetid://100889601182553",
	["shard-menu-panel-green"] = "rbxassetid://88000396355205",
	["shard-menu-panel-silver"] = "rbxassetid://96121625575449",
	["shard-menu-count-blue"] = "rbxassetid://71441288492317",
	["shard-menu-count-red"] = "rbxassetid://106208815679051",
	["shard-menu-vs-you-green"] = "rbxassetid://86607639766851",
	["shard-menu-vs-them-violet"] = "rbxassetid://93621972673360",
	["shard-menu-choice-indigo"] = "rbxassetid://120235739822157",
	["shard-menu-choice-white"] = "rbxassetid://126665919174262",
	["shard-menu-choice-green"] = "rbxassetid://116683324957790",
	["shard-menu-choice-red"] = "rbxassetid://73986525497608",
	["shard-menu-action"] = "rbxassetid://102588518215625",
	["shard-menu-square-silver"] = "rbxassetid://98880782544501",
	["shard-menu-toggle-on"] = "rbxassetid://119708765044385",
	["shard-menu-toggle-off"] = "rbxassetid://127981081649174",
	["shard-menu-banner-violet"] = "rbxassetid://85212404973787",
	["shard-menu-problem-silver"] = "rbxassetid://84038403383406",
	["glow-menu-title-violet"] = "rbxassetid://120819457094077",
	["glow-menu-primary-red"] = "rbxassetid://98480043803237",
	["glow-menu-player-violet"] = "rbxassetid://119473148108653",
	["glow-menu-mode-red"] = "rbxassetid://84346940078072",
	["glow-menu-mode-blue"] = "rbxassetid://104294247619342",
	["glow-menu-mode-violet"] = "rbxassetid://91605041780275",
	["glow-menu-panel-red"] = "rbxassetid://90828958429511",
	["glow-menu-panel-blue"] = "rbxassetid://138133596712375",
	["glow-menu-panel-violet"] = "rbxassetid://110167451928399",
	["glow-menu-panel-green"] = "rbxassetid://92974644531683",
	["glow-menu-panel-silver"] = "rbxassetid://104704416495994",
	["glow-menu-count-blue"] = "rbxassetid://124809710019869",
	["glow-menu-count-red"] = "rbxassetid://134888431177617",
	["glow-menu-vsyou-green"] = "rbxassetid://93717619689755",
	["glow-menu-vsthem-violet"] = "rbxassetid://111904964733526",
	["glow-menu-choice-green"] = "rbxassetid://90526642699159",
	["glow-menu-banner-violet"] = "rbxassetid://77334504897541",
	["glow-menu-problem-silver"] = "rbxassetid://81814962886977",
	["glow-menu-rank-plastic"] = "rbxassetid://70873948287922",
	["glow-menu-rank-bronze"] = "rbxassetid://111062229030052",
	["glow-menu-rank-silver"] = "rbxassetid://101041988264770",
	["glow-menu-rank-gold"] = "rbxassetid://104313110881742",
	["glow-menu-rank-platinum"] = "rbxassetid://92088657383376",
	["glow-menu-rank-diamond"] = "rbxassetid://92128747592566",
	["glow-menu-rank-demon"] = "rbxassetid://133724102142798",
	["glow-menu-rank-white"] = "rbxassetid://78810274916373",
	["icon-menu-lock"] = "rbxassetid://78843681765955",
	["icon-menu-check"] = "rbxassetid://92309109602421",
	["icon-menu-cross"] = "rbxassetid://76010664492672",
	["icon-menu-star"] = "rbxassetid://88637810156913",
	["icon-menu-chevron"] = "rbxassetid://118026919922148",
	["icon-menu-back"] = "rbxassetid://132037123252728",
	["icon-menu-clock"] = "rbxassetid://79777596747861",
	["icon-menu-alert"] = "rbxassetid://83733046426117",
	["icon-menu-focus"] = "rbxassetid://115480997303635", -- 9-slice SelectionImageObject, SliceCenter Rect.new(24, 24, 72, 72)
	["rank-plastic"] = "rbxassetid://138823236050317",
	["rank-bronze"] = "rbxassetid://74109575771510",
	["rank-silver"] = "rbxassetid://73562210912899",
	["rank-gold"] = "rbxassetid://136933130868948",
	["rank-platinum"] = "rbxassetid://122930887718750",
	["rank-diamond"] = "rbxassetid://85981585508106",
	["rank-demon-1"] = "rbxassetid://130324768909238",
	["rank-demon-2"] = "rbxassetid://94720484488807",
	["rank-demon-3"] = "rbxassetid://130283705731751",
	["rank-demon-4"] = "rbxassetid://124282519465338",
}

-- Horizontal 9-slice art (Art v2): SliceCenter in image px, SliceScale 0.5 for the 2x PNGs. Rows and toasts stretch their
-- flat middle; every other shard is fixed width and keeps ScaleType.Stretch.
MenuTheme.Slice = {
	["shard-menu-row-indigo-v2"] = { center = Rect.new(52, 0, 548, 76), scale = 0.5 },
	["shard-menu-row-green-v2"] = { center = Rect.new(52, 0, 548, 76), scale = 0.5 },
	["shard-menu-toast-silver-v2"] = { center = Rect.new(48, 0, 592, 92), scale = 0.5 },
	["shard-menu-toast-green-v2"] = { center = Rect.new(48, 0, 592, 92), scale = 0.5 },
	["shard-menu-toast-red-v2"] = { center = Rect.new(48, 0, 592, 92), scale = 0.5 },
	["glow-menu-toast-silver-v2"] = { center = Rect.new(120, 0, 664, 236), scale = 0.5 },
	["glow-menu-toast-green-v2"] = { center = Rect.new(120, 0, 664, 236), scale = 0.5 },
	["glow-menu-toast-red-v2"] = { center = Rect.new(120, 0, 664, 236), scale = 0.5 },
}
MenuTheme.RowHeight = 38 -- Art v2 rows are drawn 38 tall, centred in their old slots (settings rows keep their 44 px slot)

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
