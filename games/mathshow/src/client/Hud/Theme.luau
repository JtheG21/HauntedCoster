--!strict
-- MathShow Hud theme ("Shards" pass, TASK-0097): fonts, colours, image ids, layout numbers and the tiny
-- constructors View uses. Layout numbers are pixels on the 844x390 reference canvas; View scales the root
-- with a UIScale (HudRules.rootScale) inside the device safe insets.

local Theme = {}

local function deepFreeze<T>(value: T): T
	if typeof(value) == "table" then
		for _, child in value :: any do
			deepFreeze(child)
		end
		table.freeze(value :: any)
	end
	return value
end

Theme.Reference = Vector2.new(844, 390)
Theme.GlowPad = 36 -- glow images are the shard size plus 36 px on every side
Theme.PlaceholderSize = 18 -- TextBox TextSize while empty; InputSize once digits are typed
Theme.InputSize = 30
-- Roblox text has no letter-spacing, so tags get wider side padding instead of the design's tracking.
Theme.TagPadX = 12
Theme.TagPadY = 2

local MERRIWEATHER = "rbxasset://fonts/families/Merriweather.json"
Theme.Font = deepFreeze({
	Display = Font.new(MERRIWEATHER, Enum.FontWeight.Bold),
	Body = Font.new(MERRIWEATHER, Enum.FontWeight.Bold),
	Italic = Font.new(MERRIWEATHER, Enum.FontWeight.Regular, Enum.FontStyle.Italic),
})

Theme.Color = deepFreeze({
	Ground = Color3.fromRGB(11, 10, 13),
	Ink = Color3.fromRGB(255, 255, 255),
	InkDim = Color3.fromRGB(150, 150, 158), -- 42-60% white on ground
	Tag = Color3.fromRGB(0, 0, 0),
	Alert = Color3.fromRGB(255, 84, 64), -- last 3 s: number, bar, current pip
	ButtonInk = Color3.fromRGB(11, 10, 13),
	ButtonHover = Color3.fromRGB(226, 210, 255), -- ImageColor3 tint on shard-button
})

export type Gem = "red" | "blue" | "violet" | "green" | "silver"

Theme.GemColor = deepFreeze({
	red = Color3.fromRGB(255, 60, 40),
	blue = Color3.fromRGB(60, 140, 255),
	violet = Color3.fromRGB(170, 80, 255),
	green = Color3.fromRGB(90, 255, 80),
	silver = Color3.fromRGB(150, 150, 158),
})

-- Upload every PNG in games/mathshow/art/hud/ and paste the ids here (UPLOAD_LIST.md). Names match the files.
local UNSET = "rbxassetid://0"
Theme.Image = deepFreeze({
	["shard-problem-green"] = "rbxassetid://95815984904238",
	["shard-problem-blue"] = "rbxassetid://91720662516603",
	["shard-problem-red"] = "rbxassetid://122503913642987",
	["shard-card-red"] = "rbxassetid://85363792812698",
	["shard-card-silver"] = "rbxassetid://95514984537964",
	["shard-count-violet"] = "rbxassetid://72271819138824",
	["shard-pod1-red"] = "rbxassetid://112435953815986",
	["shard-pod2-violet"] = "rbxassetid://130933945427591",
	["shard-pod3-blue"] = "rbxassetid://77014659559983",
	["shard-toast-green"] = "rbxassetid://96230616342388",
	["shard-toast-red"] = "rbxassetid://119562216254828",
	["shard-toast-silver"] = "rbxassetid://137752466273305",
	["shard-chip-violet"] = "rbxassetid://111813153806359",
	["shard-chip-green"] = "rbxassetid://99625001479622",
	["shard-row-indigo"] = "rbxassetid://114241458536556",
	["shard-row-green"] = "rbxassetid://96158020076537",
	["shard-input"] = "rbxassetid://118400266569785",
	["shard-button"] = "rbxassetid://119492115691251",
	["shard-score-silver"] = "rbxassetid://83847348985733",
	["glow-problem-green"] = "rbxassetid://77448251701799",
	["glow-problem-blue"] = "rbxassetid://104583637684083",
	["glow-problem-red"] = "rbxassetid://117875748162948",
	["glow-card-red"] = "rbxassetid://120378652469447",
	["glow-card-silver"] = "rbxassetid://129294547516302",
	["glow-count-violet"] = "rbxassetid://73991663797356",
	["glow-pod1-red"] = "rbxassetid://73214434609368",
	["glow-pod2-violet"] = "rbxassetid://71723387385818",
	["glow-pod3-blue"] = "rbxassetid://96217164263183",
	["glow-toast-green"] = "rbxassetid://72350691742389",
	["glow-toast-red"] = "rbxassetid://95225799585652",
	["glow-toast-silver"] = "rbxassetid://82761926541075",
	["glow-score-silver"] = "rbxassetid://105260858572740",
})

-- Gem by difficulty tier (RoundConfig.DifficultyByQuestion): Q1-2 green, Q3-4 blue, Q5-6 red.
Theme.TierGem = deepFreeze(({ "green", "blue", "red" } :: any) :: { Gem })
Theme.FeedbackGem = deepFreeze(({
	sent = "silver",
	correct = "green",
	wrong = "red",
	timesup = "red",
	rejected = "red",
	sendfail = "red",
} :: any) :: { [string]: Gem })

export type Box = { x: number, y: number, w: number, h: number, rot: number }
local function box(x: number, y: number, w: number, h: number, rot: number): Box
	return { x = x, y = y, w = w, h = h, rot = rot }
end

-- Top-left position, size and Rotation (degrees) of each shard's root Frame.
Theme.Layout = deepFreeze({
	TopLabel = box(0, 14, 844, 16, 0), -- centered text + 6 diamond pips (8x8, 5 px gap)
	Score = box(650, 10, 150, 44, 1.5), -- right edge at the 44 px inset
	Problem = box(52, 46, 580, 186, -2), -- tag at (52, 38) inside, problem text 88 px
	Seconds = box(646, 64, 154, 130, 0), -- 4 px left of the design's 650 so the right edge sits on the inset
	TimerBar = box(92, 244, 520, 10, -1),
	InputRow = box(110, 270, 422, 58, 1), -- input 260x58, 12 px gap, button 150x58
	Feedback = box(110, 338, 0, 46, -1), -- width = text + 60; y = 318 during Reveal
	Solvers = box(96, 268, 700, 34, 0), -- chips max 180 wide, 8 px gap
	LobbyCard = box(60, 92, 600, 190, -1.5),
	ReadyCard = box(44, 72, 520, 210, -2.5),
	Countdown = box(572, 92, 220, 200, 4),
	Pod1 = box(46, 46, 410, 118, -3),
	Pod2 = box(64, 172, 380, 92, 2.5),
	Pod3 = box(46, 272, 350, 84, -1.5),
	List = box(484, 66, 316, 34, 0), -- rows 34 tall, 5 px gap, x offsets below
	MessageCard = box(140, 118, 560, 150, -1.5),
})
Theme.FeedbackRevealY = 318
Theme.RowOffsets = deepFreeze({ 0, 16, 6, 22, 10, 26 })
-- The touch jump button sits bottom-right; list rows that reach below JumpTop stop short of JumpLeft.
Theme.JumpZone = deepFreeze({ left = 664, top = 240 })
Theme.PodiumBottom = 264 -- below this y the second podium shard no longer reaches the list column

export type Props = { [string]: any }

function Theme.apply(inst: Instance, props: Props?)
	if props then
		for key, value in props do
			(inst :: any)[key] = value
		end
	end
end

function Theme.make<T>(className: string, props: Props, parent: Instance?): T
	local inst = Instance.new(className)
	Theme.apply(inst, props)
	inst.Parent = parent
	return inst :: any
end

-- White text with the dark stroke that stands in for the design's text-shadow. Sizes itself to its text.
function Theme.label(parent: Instance?, text: string, size: number, props: Props?): TextLabel
	local label = Theme.make("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font.Body,
		Text = text,
		TextSize = size,
		TextColor3 = Theme.Color.Ink,
		TextStrokeColor3 = Theme.Color.Tag,
		TextStrokeTransparency = 0.6,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, nil) :: TextLabel
	Theme.apply(label, props)
	label.Parent = parent
	return label
end

-- A black single-line tag: wide side padding (no letter-spacing in Roblox), never wraps.
function Theme.tag(parent: Instance?, text: string, size: number, props: Props?): TextLabel
	local tag = Theme.label(nil, text, size, {
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Color.Tag,
		TextStrokeTransparency = 1,
	})
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft, padding.PaddingRight = UDim.new(0, Theme.TagPadX), UDim.new(0, Theme.TagPadX)
	padding.PaddingTop, padding.PaddingBottom = UDim.new(0, Theme.TagPadY), UDim.new(0, Theme.TagPadY)
	padding.Parent = tag
	Theme.apply(tag, props)
	tag.Parent = parent
	return tag
end

local warnedImages: { [string]: boolean } = {}

-- Points an ImageLabel at a baked PNG. While the id is unset (rbxassetid://0) a shard shows a flat gem-coloured
-- panel so it stays visible, and a glow shows nothing; each key warns once.
function Theme.setImage(label: ImageLabel, key: string, gem: Gem?)
	local id = (Theme.Image :: { [string]: string })[key]
	local isGlow = string.sub(key, 1, 4) == "glow"
	if id == nil or id == UNSET then
		if not warnedImages[key] then
			warnedImages[key] = true
			warn(`[MathShow] Hud image {key} has no asset id yet; showing a flat fallback`)
		end
		label.Image = ""
		if isGlow then
			label.BackgroundTransparency = 1
		else
			local ground = Theme.Color.Ground
			label.BackgroundColor3 = ground:Lerp(Theme.GemColor[gem or "silver"], 0.45)
			label.BackgroundTransparency = 0.05
		end
		return
	end
	label.Image = id
	label.BackgroundTransparency = 1
end

return table.freeze(Theme)
