--!strict
-- Builds the MathShowMenu ScreenGui (TASK-0098): every menu screen and component as Shards on the 844x390 reference
-- canvas. Instances live only here; navigation and settings state live in init. Each screen is rebuilt by render(), which
-- returns nothing the caller must keep: handlers fire for every action. Fx calls are isolated inside Hud/Fx.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudRules = require(Shared:WaitForChild("HudRules"))
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))
local BlitzRules = require(Shared:WaitForChild("BlitzRules"))
local CooldownRules = require(Shared:WaitForChild("CooldownRules"))
local ModeRules = require(Shared:WaitForChild("ModeRules"))
local HudRulesSkill = HudRules
local PracticeRules = require(Shared:WaitForChild("PracticeRules"))
local TextFitRules = require(Shared:WaitForChild("TextFitRules"))
local NameRules = require(Shared:WaitForChild("NameRules"))
local RankRules = require(Shared:WaitForChild("RankRules"))

local Fx = require(script.Parent.Parent.Hud.Fx)
local HudTheme = require(script.Parent.Parent.Hud.Theme)
local MenuTheme = require(script.Parent.MenuTheme)
local Shard = require(script.Parent.Shard)

export type Player = { name: string, userId: number?, rank: number?, failed: boolean? }
export type Settings = {
	music: number,
	sfx: number,
	reducedMotion: boolean,
	colorBlind: boolean,
	haptics: boolean,
}
export type PracticeModel = {
	rank: number?,
	lastTestRank: number?,
	retryRemaining: number?,
	failed: boolean?,
	loading: boolean?,
}
export type SkillModel = {
	kind: string, -- "integer" | "choice"
	rank: number, -- the rank being asked (0..9)
	problem: string,
	choices: { string }?,
	misses: number,
	total: number, -- seconds the question lasts (the tag shows it)
	phase: string, -- "question" | "reveal"
	selected: number?, -- choice index picked but not locked
	locked: boolean, -- an answer was sent for this question
	chosen: number?, -- reveal: the index the player locked
	correct: boolean?, -- reveal
	correctValue: number?, -- reveal, typed
	correctIndex: number?, -- reveal, choice
}
export type BlitzModel = {
	index: number, -- question 1..10
	problem: string,
	total: number, -- seconds the run clock lasts
	locked: boolean, -- an answer was sent for this question
}
export type ReviewModel = {
	correct: number,
	answers: { any }, -- number, or false for a question not answered
	solutions: { number },
	previousBest: number?,
	newBest: boolean,
}
export type ResultModel = {
	kind: string, -- "first" | "up" | "held"
	best: number,
	cleared: number?,
	previousBest: number?,
	retryRemaining: number,
}
export type Model = {
	flags: { [string]: boolean }?,
	secondary: { [string]: boolean }?,
	player: Player?,
	settings: Settings?,
	best: string?, -- "6/10": the white BEST tag on the Blitz panel
	waiting: boolean?, -- 03b action after FIND OPPONENT is pressed in a preview
	toast: string?,
	practice: PracticeModel?,
	holdToast: boolean?,
	skill: SkillModel?,
	result: ResultModel?,
	blitz: BlitzModel?,
	review: ReviewModel?,
	quiet: boolean?, -- re-render without entrances (a selection changed, a timer tick) -- Preview only: keep the toast on screen
}
export type Handlers = {
	go: (id: string) -> (),
	back: () -> (),
	locked: (what: string) -> (),
	join: () -> (),
	retry: () -> (),
	skillSelect: (index: number) -> (),
	skillLock: (value: number) -> (),
	blitzLock: (value: number) -> (),
	setting: (key: string, value: number | boolean) -> (),
}
export type Options = { overlay: boolean?, name: string?, displayOrder: number? }
export type View = {
	gui: ScreenGui,
	root: Frame,
	render: (id: string, model: Model) -> (),
	toast: (text: string, icon: boolean, hold: boolean?) -> (),
	setRetakeLabel: (text: string) -> (),
	setSkillTimer: (fraction: number, seconds: number) -> (),
	setBlitzClock: (fraction: number, text: string) -> (),
	defaultFocus: () -> GuiObject?,
	setReduced: (on: boolean) -> (),
	destroy: () -> (),
}

local C = HudTheme.Color
local L = MenuTheme.Layout
local T = MenuTheme.Text
local make = HudTheme.make
local FONT = HudTheme.Font

local View = {}

local function gemOf(mode: string): Shard.Gem
	return if mode == "blitz" then "red" elseif mode == "vs" then "blue" else "violet"
end

------------------------------------------------------------------------------------------------------------------
-- Small constructors
------------------------------------------------------------------------------------------------------------------

type Item = { shard: Shard.Shard, hit: TextButton?, name: string }

local function text(
	parent: Instance,
	name: string,
	str: string,
	size: number,
	x: number,
	y: number,
	w: number,
	h: number,
	props: HudTheme.Props?
): TextLabel
	local label = make("TextLabel", {
		Name = name,
		BackgroundTransparency = 1,
		FontFace = FONT.Body,
		Text = str,
		TextSize = size,
		TextColor3 = C.Ink,
		TextStrokeColor3 = C.Tag,
		TextStrokeTransparency = MenuTheme.TextStrokeTransparency,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
	}, nil) :: TextLabel
	HudTheme.apply(label, props)
	label.Parent = parent
	return label
end

-- A black (or white status) single-line tag that sizes to its text.
local function tag(parent: Instance, name: string, str: string, white: boolean?, order: number?): TextLabel
	local label = make("TextLabel", {
		Name = name,
		BackgroundColor3 = if white then C.Ink else C.Tag,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		FontFace = FONT.Body,
		Text = str,
		TextSize = T.Tag,
		TextColor3 = if white then C.Tag else C.Ink,
		TextStrokeTransparency = 1,
		TextWrapped = false,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		LayoutOrder = order or 0,
	}, nil) :: TextLabel
	make("UIPadding", {
		PaddingLeft = UDim.new(0, MenuTheme.TagPadX),
		PaddingRight = UDim.new(0, MenuTheme.TagPadX),
		PaddingTop = UDim.new(0, MenuTheme.TagPadY),
		PaddingBottom = UDim.new(0, MenuTheme.TagPadY),
	}, label)
	label.Parent = parent
	return label
end

local function row(parent: Instance, name: string, x: number, y: number, w: number, gap: number): Frame
	local frame = make("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, 20),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, parent) :: Frame
	make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}, frame)
	return frame
end

local function icon(parent: Instance, name: string, key: string, x: number, y: number, size: number): ImageLabel
	local label = make("ImageLabel", {
		Name = name,
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size, size),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 5,
	}, parent) :: ImageLabel
	Shard.setImage(label, key, nil, nil)
	if label.Image == "" then
		-- No art yet: a small white square keeps the mark visible.
		label.BackgroundColor3 = C.Ink
		label.BackgroundTransparency = 0.2
	end
	return label
end

-- GuiObject.SelectionImageObject: icon-menu-focus as a 9-slice, 8 px out on each side. Without art, a white outline.
local function focusBrackets(): ImageLabel
	local frame = make("ImageLabel", {
		Name = "FocusBrackets",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 16, 1, 16),
		Position = UDim2.fromOffset(-8, -8),
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(24, 24, 72, 72),
		SliceScale = 0.5,
	}, nil) :: ImageLabel
	local id = Shard.idOf("icon-menu-focus")
	if id then
		frame.Image = id
	else
		make("UIStroke", { Color = C.Ink, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, frame)
	end
	return frame
end

-- Measured width of a toast label (single line), with a rough fallback if the text service fails.
local function measureWidth(str: string, size: number): number
	local ok, width = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text, params.Font, params.Size, params.Width = str, FONT.Body, size, 10000
		return TextService:GetTextBoundsAsync(params).X
	end)
	if ok and typeof(width) == "number" then
		return width
	end
	return #str * size * 0.7
end

------------------------------------------------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------------------------------------------------

-- overlay = no ground and no edge text: a banner drawn over the HUD (Menu/Watching) instead of a menu screen.
function View.build(parent: Instance, handlers: Handlers, options: Options?): View
	local overlay = options ~= nil and options.overlay == true
	local gui = make("ScreenGui", {
		Name = if options and options.name then options.name else "MathShowMenu",
		ResetOnSpawn = false,
		DisplayOrder = if options and options.displayOrder then options.displayOrder else 10,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	}, nil) :: ScreenGui

	if not overlay then
		make("Frame", {
			Name = "Ground",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = C.Ground,
			BackgroundTransparency = MenuTheme.LobbyOverlayTransparency,
			BorderSizePixel = 0,
		}, gui)
	end
	local root = make("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(MenuTheme.Reference.X, MenuTheme.Reference.Y),
		BackgroundTransparency = 1,
	}, gui) :: Frame
	local rootScale = make("UIScale", {}, root) :: UIScale
	local function rescale()
		local size = gui.AbsoluteSize
		rootScale.Scale = HudRules.rootScale(size.X, size.Y)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(rescale)
	rescale()

	local screen: Frame? = nil
	local toastLayer = make(
		"Frame",
		{ Name = "Toasts", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 50 },
		root
	) :: Frame
	local stops: { () -> () } = {}
	local reduced = false
	local firstSelectable: GuiObject? = nil
	local retakeLabel: TextLabel? = nil
	local skillFill: Frame? = nil
	local skillSeconds: TextLabel? = nil
	local blitzClock: TextLabel? = nil
	local quiet = false
	local toastToken = 0
	local selection = focusBrackets()

	local function clearScreen()
		for _, stop in stops do
			stop()
		end
		table.clear(stops)
		if screen then
			screen:Destroy()
			screen = nil
		end
		firstSelectable = nil
		retakeLabel = nil
		skillFill = nil
		skillSeconds = nil
		blitzClock = nil
	end

	-- A button's interaction layer: full-box TextButton, brackets + 1.04 on gamepad focus, 0.95 while pressed.
	local function interactive(item: Item, onActivated: () -> (), hoverScale: number?)
		local shard = item.shard
		local box = shard.root.Size
		local hit = make("TextButton", {
			Name = "Hit",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(box.X.Offset, box.Y.Offset),
			Selectable = true,
			SelectionImageObject = selection,
			ZIndex = 20,
		}, shard.content) :: TextButton
		item.hit = hit
		local pressed, hovered = false, false
		local function refresh()
			shard.touch.Scale = if pressed then MenuTheme.PressScale elseif hovered and hoverScale then hoverScale else 1
		end
		hit.MouseEnter:Connect(function()
			hovered = true
			refresh()
		end)
		hit.MouseLeave:Connect(function()
			hovered, pressed = false, false
			refresh()
		end)
		hit.MouseButton1Down:Connect(function()
			pressed = true
			refresh()
		end)
		hit.MouseButton1Up:Connect(function()
			pressed = false
			refresh()
		end)
		hit.SelectionGained:Connect(function()
			shard.touch.Scale = MenuTheme.FocusScale
		end)
		hit.SelectionLost:Connect(function()
			shard.touch.Scale = 1
		end)
		hit.Activated:Connect(onActivated)
		if firstSelectable == nil then
			firstSelectable = hit
		end
	end

	local function link(a: Item?, direction: string, b: Item?)
		if a and b and a.hit and b.hit then
			(a.hit :: any)["NextSelection" .. direction] = b.hit
			local opposite = ({ Up = "Down", Down = "Up", Left = "Right", Right = "Left" } :: { [string]: string })[direction];
			(b.hit :: any)["NextSelection" .. opposite] = a.hit
		end
	end

	local function newShard(
		name: string,
		box: MenuTheme.Box,
		imageKey: string,
		glowKey: string?,
		gem: Shard.Gem
	): Shard.Shard
		return Shard.new(screen :: Frame, name, box, imageKey, glowKey, gem)
	end

	local function playFx(name: string, target: GuiObject, delay: number?)
		if quiet then
			return
		end
		local fn = (Fx :: any)[name]
		if fn then
			fn(target, delay)
		end
	end

	local function glowLoop(item: Item, offset: number)
		local glow = item.shard.glow
		if glow then
			table.insert(stops, Fx.breathe(glow, offset))
			if reduced or Fx.reducedMotion() then
				glow.ImageTransparency = 0.2
			end
		end
	end

	------------------------------------------------------------------------------------------------------------
	-- Components
	------------------------------------------------------------------------------------------------------------

	local function topLabel(str: string, left: boolean?)
		local x, w = 0, 844
		if left then
			x, w = L.LeftTopLabel.x, L.LeftTopLabel.w
		end
		text(screen :: Frame, "TopLabel", str, 13, x, L.TopLabel.y, w, 16, {
			TextXAlignment = if left then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center,
			TextTransparency = 0.5,
			TextStrokeTransparency = 1,
		})
	end

	local function primary(
		name: string,
		box: MenuTheme.Box,
		label: string,
		gem: Shard.Gem,
		glow: boolean,
		lockedState: boolean
	): Item
		local shard =
			newShard(name, box, "shard-menu-primary-" .. gem, if glow then "glow-menu-primary-red" else nil, gem)
		local item: Item = { shard = shard, name = name }
		local x = 30
		if lockedState then
			icon(shard.content, "Lock", "icon-menu-lock", 26, 21, 20)
			x = 56
		end
		local l = text(shard.content, "Label", label, T.Primary, x, 0, 200, box.h)
		if lockedState then
			l.TextTransparency = MenuTheme.DisabledTransparency
			shard.image.ImageTransparency = MenuTheme.DisabledTransparency
		else
			icon(shard.content, "Chevron", "icon-menu-chevron", 246, 22, 18)
		end
		return item
	end

	local function sticker(host: Instance, str: string)
		local s = tag(host, "Sticker", str, true)
		s.TextSize = T.Sticker
		s.AnchorPoint = Vector2.new(1, 0)
		s.Position = UDim2.new(1, -8, 0, -9)
		s.Rotation = 4
		s.ZIndex = 8
		s:SetAttribute("FitSticker", true)
		return s
	end

	local function secondary(name: string, box: MenuTheme.Box, label: string, locked: boolean, fontSize: number?): Item
		local shard = newShard(
			name,
			box,
			if locked then "shard-menu-secondary-locked" else "shard-menu-secondary-silver",
			nil,
			"silver"
		)
		local item: Item = { shard = shard, name = name }
		local l = text(shard.content, "Label", label, fontSize or T.Secondary, 0, 0, box.w, box.h, {
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		if locked then
			l.TextTransparency = MenuTheme.LockedInkTransparency
			icon(shard.content, "Lock", "icon-menu-lock", 18, 15, 14)
			sticker(shard.content, MenuCopy.Common.ComingSoon)
		end
		return item
	end

	local function backButton(label: string): Item
		local shard = newShard("Back", L.Back, "shard-menu-secondary-silver", nil, "silver")
		local item: Item = { shard = shard, name = "Back" }
		icon(shard.content, "Icon", "icon-menu-back", 22, 15, 14)
		text(shard.content, "Label", label, T.Secondary, 44, 0, 60, 44)
		interactive(item, handlers.back, nil)
		return item
	end

	local function action(box: MenuTheme.Box, label: string, enabled: boolean, clock: boolean, size: number?): Item
		local shard = newShard("Action", box, "shard-menu-action", nil, "silver")
		local item: Item = { shard = shard, name = "Action" }
		local x = 0
		if clock then
			local square = make("Frame", {
				Name = "ClockSquare",
				Position = UDim2.fromOffset(22, 21),
				Size = UDim2.fromOffset(22, 22),
				BackgroundColor3 = C.ButtonInk,
				BorderSizePixel = 0,
			}, shard.content)
			icon(square, "Clock", "icon-menu-clock", 3, 3, 16)
			x = 28
		end
		local l = text(shard.content, "Label", label, size or T.Action, x, 0, box.w, box.h, {
			TextXAlignment = Enum.TextXAlignment.Center,
			TextColor3 = C.ButtonInk,
			TextStrokeTransparency = 1,
		})
		if not enabled then
			l.TextTransparency = MenuTheme.DisabledTransparency
			shard.image.ImageTransparency = MenuTheme.DisabledTransparency
		end
		return item
	end

	local function modeCard(name: string, box: MenuTheme.Box, mode: string, locked: boolean, onPress: () -> ()): Item
		local gem = gemOf(mode)
		local copy = (MenuCopy.Mode :: any)[if mode == "blitz" then "Blitz" elseif mode == "vs" then "Vs" else "Group"]
		local shard = newShard(
			name,
			box,
			if locked then "shard-menu-mode-locked" else "shard-menu-mode-" .. gem,
			if locked then nil else "glow-menu-mode-" .. gem,
			gem
		)
		local item: Item = { shard = shard, name = name }
		local titleX = 24
		if locked then
			icon(shard.content, "Lock", "icon-menu-lock", 24, 30, 22)
			titleX = 54
		end
		local title = text(shard.content, "Title", copy.Title, T.CardTitle, titleX, 26, 208 - titleX, 62, {
			TextWrapped = true,
			TextYAlignment = Enum.TextYAlignment.Top,
			LineHeight = 31 / T.CardTitle,
		})
		if locked then
			title.TextTransparency = MenuTheme.LockedInkTransparency
			local soon = tag(shard.content, "ComingSoon", MenuCopy.Common.ComingSoon, true)
			soon.Position = UDim2.fromOffset(24, 118)
		else
			local r1 = row(shard.content, "TagsA", 24, 118, 184, 6)
			tag(r1, "Players", copy.Players, false, 1)
			local r2 = row(shard.content, "TagsB", 24, 146, 184, 6)
			tag(r2, "Questions", copy.Questions, false, 1)
			tag(r2, "Feedback", copy.Feedback, false, 2)
		end
		interactive(item, onPress, 1.02)
		return item
	end

	local function playerCard(box: MenuTheme.Box, player: Player): Item
		local shard = newShard("PlayerCard", box, "shard-menu-player-violet", "glow-menu-player-violet", "violet")
		local glowImage = shard.glow :: ImageLabel
		glowImage.ImageTransparency = 0.4
		local item: Item = { shard = shard, name = "PlayerCard" }
		local head = make("ImageLabel", {
			Name = "Headshot",
			Position = UDim2.fromOffset(28, 36),
			Size = UDim2.fromOffset(84, 84),
			BackgroundColor3 = C.Ground,
			BorderSizePixel = 0,
			ZIndex = 5,
		}, shard.content) :: ImageLabel
		make("UIStroke", { Color = C.Ink, Thickness = 2 }, head)
		if player.userId then
			task.spawn(function()
				local ok, url = pcall(function()
					return game:GetService("Players"):GetUserThumbnailAsync(
						player.userId :: number,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size100x100
					)
				end)
				if ok and head.Parent then
					head.Image = url
				elseif not ok then
					warn(`[MathShow] Menu headshot failed: {url}`)
				end
			end)
		end
		tag(shard.content, "Contestant", MenuCopy.Main.Contestant).Position = UDim2.fromOffset(128, 30)
		local name = text(shard.content, "Name", NameRules.truncateName(player.name), T.PlayerName, 128, 52, 200, 24, {
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		name:SetAttribute("AllowTruncate", true)
		local tier = if player.rank then RankRules.tierOf(player.rank) else nil
		if player.failed then
			icon(shard.content, "Alert", "icon-menu-alert", 128, 94, 20)
			text(shard.content, "Unavailable", MenuCopy.Main.RankUnavailable, 14, 154, 90, 190, 28)
		elseif tier then
			local badge = icon(shard.content, "Badge", tier.badge, 128, 84, MenuTheme.BadgeSizes.Card)
			badge.BackgroundTransparency = if Shard.idOf(tier.badge) then 1 else 0.2
			text(shard.content, "Tier", tier.name, T.TierName, 184, 84, 150, 22)
			text(shard.content, "Subject", tier.subject, T.Subject, 184, 108, 150, 18, { FontFace = FONT.Italic })
		else
			text(shard.content, "Unranked", MenuCopy.Skill.Unranked, 14, 128, 96, 200, 28)
		end
		return item
	end

	-- Panel: tag, one-line title, three lines, tag row (README 03; stack numbers from MenuTheme.Panel, audit A1).
	local function panel(
		gem: Shard.Gem,
		tagText: string,
		title: string,
		titleSize: number,
		lines: { string },
		tags: { { any } }
	): Item
		local P = MenuTheme.Panel
		local shard = newShard("Panel", L.Panel, "shard-menu-panel-" .. gem, "glow-menu-panel-" .. gem, gem)
		local item: Item = { shard = shard, name = "Panel" }
		tag(shard.content, "Tag", tagText).Position = UDim2.fromOffset(P.LeftPad, P.TagY)
		text(shard.content, "Title", title, titleSize, P.LeftPad, P.TitleY, 406, titleSize, {})
		local linesY = P.TitleY + titleSize + P.TitleToLines
		text(
			shard.content,
			"Lines",
			table.concat(lines, "\n"),
			T.PanelLine,
			P.LeftPad,
			linesY,
			406,
			#lines * P.Leading,
			{
				FontFace = FONT.Italic,
				TextYAlignment = Enum.TextYAlignment.Top,
				LineHeight = P.Leading / T.PanelLine,
			}
		)
		local tagsRow =
			row(shard.content, "Tags", P.LeftPad, linesY + #lines * P.Leading + P.LinesToTags, 406, P.TagGap)
		for index, spec in tags do
			tag(tagsRow, "Tag" .. index, spec[1] :: string, spec[2] == true, index)
		end
		return item
	end

	-- style: silver | green | red toast art; iconKey: an icon before the text; bottom: the in-match position (110, 338).
	local function toastAt(str: string, iconKey: string?, kind: string, bottom: boolean, hold: boolean?)
		toastToken += 1
		local token = toastToken
		for _, child in toastLayer:GetChildren() do
			child:Destroy()
		end
		local TO = MenuTheme.Toast
		local width = math.ceil(measureWidth(str, T.Toast)) + TO.PadX * 2 + (if iconKey then TO.IconExtra else 0)
		local at = if bottom then L.ToastBottom else L.ToastTop
		local box = { x = if bottom then at.x else 422 - width // 2, y = at.y, w = width, h = TO.Height, rot = at.rot }
		local shard = Shard.new(
			toastLayer,
			"Toast",
			box,
			"shard-toast-" .. kind,
			"glow-toast-" .. kind,
			if kind == "silver" then "silver" elseif kind == "green" then "green" else "red"
		)
		local x = TO.PadX
		if iconKey then
			icon(shard.content, "Mark", iconKey, TO.PadX, 15, TO.IconSize)
			x += TO.IconExtra
		end
		text(shard.content, "Label", str, T.Toast, x, TO.TextY, width - x - TO.PadX, TO.TextH)
		playFx("pop", shard.group, 0)
		if hold then
			return
		end
		task.delay(MenuConfig.ToastSeconds, function()
			if toastToken == token and shard.root.Parent then
				shard.root:Destroy()
			end
		end)
	end

	local function toast(str: string, withIcon: boolean, hold: boolean?)
		toastAt(str, if withIcon then "icon-menu-lock" else nil, "silver", false, hold)
	end

	------------------------------------------------------------------------------------------------------------
	-- Screens
	------------------------------------------------------------------------------------------------------------

	local function edges()
		for index, side in { "Left", "Right" } do
			local label = text(screen :: Frame, "Edge" .. side, string.rep("MATHSHOW · ", 2), 28, 0, 0, 340, 32, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(if index == 1 then 22 else 822, 195),
				Rotation = if index == 1 then -90 else 90,
				TextTransparency = 0.945,
				TextStrokeTransparency = 1,
				ZIndex = 0, -- no clipping: it is ignored on a rotated label and would hide most of the text
			})
			label:SetAttribute("FitEdge", true)
			table.insert(stops, Fx.drift(label))
		end
	end

	local function sparkles()
		for index, spec in { { 646, 236, 10, 22 }, { 670, 262, 6, 12 }, { 470, 24, 8, 16 } } do
			local side = (spec[3] + spec[4]) / 2 * 0.7
			local d = make("Frame", {
				Name = "Spark" .. index,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(spec[1], spec[2]),
				Size = UDim2.fromOffset(side, side),
				Rotation = 45,
				BackgroundColor3 = C.Ink,
				BorderSizePixel = 0,
			}, screen :: Frame)
			make("UIScale", {}, d)
			table.insert(stops, Fx.twinkle(d :: Frame, (index - 1) * 0.6))
		end
	end

	local function lockedPress(item: Item, what: string)
		interactive(item, function()
			playFx("shake", item.shard.group, 0)
			handlers.locked(what)
		end, 1.02)
	end

	local function buildMain(model: Model)
		local sec = model.secondary
		local player = model.player or { name = "Player", userId = nil, rank = nil, failed = nil }
		topLabel("")
		local title = newShard("Title", L.Title, "shard-menu-title-violet", "glow-menu-title-violet", "violet")
		text(title.content, "Title", MenuCopy.Main.Title, T.Title, 30, 28, 262, 40)
		local titleTag = tag(title.content, "Tag", MenuCopy.Main.TitleTag)
		titleTag.AnchorPoint = Vector2.new(0, 0.5)
		titleTag.Position = UDim2.fromOffset(30, 0)
		titleTag.Rotation = -2
		titleTag:SetAttribute("FitSticker", true)

		local playItem = primary(
			"Play",
			L.Play,
			MenuCopy.Main.Play,
			"red",
			true,
			ModeRules.cardState("group", model.flags) == "locked"
		)
		interactive(playItem, function()
			handlers.go("modes")
		end, 1.02)
		local practiceLocked = ModeRules.secondaryState("practice", sec) == "locked"
		local practice = primary("Practice", L.Practice, MenuCopy.Main.Practice, "blue", false, practiceLocked)
		if practiceLocked then
			lockedPress(practice, "practice")
		else
			interactive(practice, function()
				handlers.go("practice")
			end, 1.02)
		end
		local settings = primary("Settings", L.Settings, MenuCopy.Main.Settings, "silver", false, false)
		interactive(settings, function()
			handlers.go("settings")
		end, 1.02)

		local card = playerCard(L.PlayerCard, player)
		local howLocked = ModeRules.secondaryState("howto", sec) == "locked"
		local how = secondary("HowToPlay", L.HowToPlay, MenuCopy.Main.HowToPlay, howLocked, 15)
		if howLocked then
			lockedPress(how, "howto")
		else
			interactive(how, function()
				handlers.go("howto")
			end, nil)
		end
		local board = secondary("Leaderboard", L.Leaderboard, MenuCopy.Main.Leaderboard, true, 15)
		lockedPress(board, "leaderboard")
		local daily = secondary("Daily", L.DailyChallenge, MenuCopy.Main.DailyChallenge, true, 15)
		lockedPress(daily, "daily")

		link(playItem, "Down", practice)
		link(practice, "Down", settings)
		link(how, "Down", board)
		link(board, "Down", daily)
		link(playItem, "Right", how)
		link(practice, "Right", board)
		link(settings, "Right", daily)

		table.insert(stops, Fx.breathe(title.glow :: ImageLabel, 0))
		glowLoop(playItem, 0.3)
		sparkles()
		playFx("slam", title.group, 0)
		playFx("slide", titleTag, 0.22)
		playFx("flyLeft", playItem.shard.group, 0.12)
		playFx("flyLeft", practice.shard.group, 0.2)
		playFx("flyLeft", settings.shard.group, 0.28)
		playFx("slamRight", card.shard.group, 0.2)
		playFx("rowIn", how.shard.group, 0.4)
		playFx("rowIn", board.shard.group, 0.46)
		playFx("rowIn", daily.shard.group, 0.52)
		if model.toast then
			toast(model.toast, true, model.holdToast)
		end
	end

	local function buildModes(model: Model)
		topLabel(MenuCopy.Top.ChooseShow)
		local boxes = { L.Card1, L.Card2, L.Card3 }
		local modes = { "blitz", "vs", "group" }
		local items: { Item } = {}
		for index, mode in modes do
			local locked = ModeRules.cardState(mode, model.flags) == "locked"
			local item = modeCard("Card" .. index, boxes[index], mode, locked, function()
				if locked then
					handlers.locked(mode)
				else
					handlers.go("confirm_" .. mode)
				end
			end)
			if locked then
				-- Locked cards stay focusable, shake and toast, and never navigate.
				local hit = item.hit :: TextButton
				hit.Activated:Connect(function()
					playFx("shake", item.shard.group, 0)
				end)
			end
			items[index] = item
			playFx("slam", item.shard.group, (index - 1) * 0.1)
			if not locked then
				glowLoop(item, (index - 1) * 0.3)
			end
		end
		local back = backButton(MenuCopy.Common.Back)
		link(items[1], "Right", items[2])
		link(items[2], "Right", items[3])
		for _, item in items do
			link(item, "Down", back)
		end
		playFx("rise", back.shard.group, 0.4)
	end

	local function buildConfirm(mode: string, model: Model)
		local P = MenuTheme.Panel
		local copy = (MenuCopy.Mode :: any)[if mode == "blitz" then "Blitz" elseif mode == "vs" then "Vs" else "Group"]
		local gem = gemOf(mode)
		topLabel(MenuCopy.Top.Play)
		local tags: { { any } } = { { copy.Players }, { copy.Questions }, { copy.Feedback } }
		if mode == "blitz" and model.best then
			local best = string.gsub(MenuCopy.Mode.Blitz.Best, "{best}", model.best)
			local entry: { any } = { best, true }
			table.insert(tags, entry)
		end
		local size = if mode == "group" then P.TitleSizeGroup else P.TitleSize3
		local p = panel(gem, copy.Tag, copy.Title, size, copy.Lines, tags)
		local waiting = model.waiting == true
		local act = action(
			L.Action,
			if waiting then "WAITING FOR RIVAL" else copy.Action,
			not waiting,
			waiting,
			if waiting then T.ActionWaiting else nil
		)
		local locked = ModeRules.cardState(mode, model.flags) == "locked"
		if not waiting then
			interactive(act, function()
				if locked then
					playFx("shake", act.shard.group, 0)
					handlers.locked(mode)
				elseif mode == "group" then
					handlers.join()
				elseif mode == "blitz" then
					handlers.go("blitz")
				end
			end, nil)
		end
		local back = backButton(MenuCopy.Common.Back)
		link(act, "Down", back)
		glowLoop(p, 0)
		playFx("slam", p.shard.group, 0)
		playFx("pop", act.shard.group, 0.36)
		playFx("rise", back.shard.group, 0.4)
	end

	local function stepperRow(index: number, key: string, label: string, value: number): Item
		local box = {
			x = L.SettingRow.x,
			y = L.SettingRow.y + (index - 1) * 50,
			w = 520,
			h = 44,
			rot = if index % 2 == 1 then -0.5 else 0.5,
		}
		local shard = newShard("Row" .. key, box, "shard-row-indigo", nil, "blue")
		local item: Item = { shard = shard, name = key }
		text(shard.content, "Label", label, T.SettingLabel, 26, 0, 168, 44)
		local max = MenuConfig.SettingMax
		local function square(name: string, str: string, x: number, off: boolean, delta: number)
			local b = make("ImageLabel", {
				Name = name,
				Position = UDim2.fromOffset(x, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundTransparency = 1,
				ZIndex = 15, -- above the row's own Hit (10): siblings stack by ZIndex, so a lower value hides the buttons
			}, shard.content) :: ImageLabel
			Shard.setImage(b, "shard-menu-square-silver", "silver", nil)
			if off then
				b.ImageTransparency = MenuTheme.DisabledTransparency
			end
			local l = text(b, "Glyph", str, 18, 0, 0, 44, 44, { TextXAlignment = Enum.TextXAlignment.Center })
			if off then
				l.TextTransparency = MenuTheme.DisabledTransparency
			end
			local hit = make("TextButton", {
				Name = "Hit" .. name,
				Text = "",
				AutoButtonColor = false,
				BackgroundTransparency = 1,
				Size = UDim2.fromOffset(44, 44),
				Selectable = false,
				ZIndex = 30,
			}, b) :: TextButton
			hit.Activated:Connect(function()
				handlers.setting(key, math.clamp(value + delta, 0, max))
			end)
		end
		square("Minus", "\u{2212}", L.StepMinus.x, value <= 0, -1)
		local bars = make("Frame", {
			Name = "Bars",
			Position = UDim2.fromOffset(L.StepBars.x, L.StepBars.y),
			Size = UDim2.fromOffset(L.StepBars.w, L.StepBars.h),
			BackgroundTransparency = 1,
		}, shard.content)
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}, bars)
		for bar = 1, max do
			make("Frame", {
				Name = "Bar" .. bar,
				LayoutOrder = bar,
				Size = UDim2.fromOffset(14, 22),
				BackgroundColor3 = C.Ink,
				BackgroundTransparency = if bar <= value then 0 else MenuTheme.Color.StepOffTransparency,
				BorderSizePixel = 0,
			}, bars)
		end
		text(
			shard.content,
			"Value",
			tostring(value),
			18,
			L.StepValue.x,
			0,
			L.StepValue.w,
			44,
			{ TextXAlignment = Enum.TextXAlignment.Center }
		)
		square("Plus", "+", L.StepPlus.x, value >= max, 1)
		local rowHit = make("TextButton", {
			Name = "Hit",
			Text = "",
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(520, 44),
			Selectable = true,
			SelectionImageObject = selection,
			ZIndex = 10,
		}, shard.content) :: TextButton
		rowHit:SetAttribute("Setting", key)
		rowHit:SetAttribute("Kind", "stepper")
		rowHit:SetAttribute("Value", value)
		item.hit = rowHit
		rowHit.SelectionGained:Connect(function()
			shard.touch.Scale = MenuTheme.FocusScale
		end)
		rowHit.SelectionLost:Connect(function()
			shard.touch.Scale = 1
		end)
		if firstSelectable == nil then
			firstSelectable = rowHit
		end
		return item
	end

	local function toggleRow(index: number, key: string, label: string, hint: string, on: boolean): Item
		local box = {
			x = L.SettingRow.x,
			y = L.SettingRow.y + (index - 1) * 50,
			w = 520,
			h = 44,
			rot = if index % 2 == 1 then -0.5 else 0.5,
		}
		local shard = newShard("Row" .. key, box, "shard-row-indigo", nil, "blue")
		local item: Item = { shard = shard, name = key }
		text(shard.content, "Label", label, T.SettingLabel, 26, 0, 168, 44)
		local t = make("ImageLabel", {
			Name = "Toggle",
			Position = UDim2.fromOffset(L.Toggle.x, L.Toggle.y),
			Size = UDim2.fromOffset(76, 32),
			BackgroundTransparency = 1,
			ZIndex = 5,
		}, shard.content) :: ImageLabel
		Shard.setImage(
			t,
			if on then "shard-menu-toggle-on" else "shard-menu-toggle-off",
			if on then "green" else "silver",
			if on then nil else MenuTheme.Color.Locked
		)
		text(
			t,
			"State",
			if on then MenuCopy.Settings.On else MenuCopy.Settings.Off,
			T.ToggleState,
			if on then 6 else 34,
			0,
			36,
			32
		)
		make("Frame", {
			Name = "Knob",
			Position = UDim2.fromOffset(if on then 48 else 6, 5),
			Size = UDim2.fromOffset(22, 22),
			BackgroundColor3 = C.Ink,
			BorderSizePixel = 0,
			ZIndex = 6,
		}, t)
		text(shard.content, "Hint", hint, 13, L.ToggleHint.x, 0, L.ToggleHint.w, 44, { FontFace = FONT.Italic })
		interactive(item, function()
			handlers.setting(key, not on)
		end, nil)
		return item
	end

	local function buildSettings(model: Model)
		local s = model.settings or MenuConfig.SettingsDefaults
		topLabel(MenuCopy.Top.Settings)
		local rows: { Item } = {
			stepperRow(1, "music", MenuCopy.Settings.Music, s.music),
			stepperRow(2, "sfx", MenuCopy.Settings.Sfx, s.sfx),
			toggleRow(
				3,
				"reducedMotion",
				MenuCopy.Settings.ReducedMotion,
				MenuCopy.Settings.ReducedMotionHint,
				s.reducedMotion
			),
			toggleRow(4, "colorBlind", MenuCopy.Settings.ColorBlind, MenuCopy.Settings.ColorBlindHint, s.colorBlind),
			toggleRow(5, "haptics", MenuCopy.Settings.Haptics, MenuCopy.Settings.HapticsHint, s.haptics),
		}
		local back = backButton(MenuCopy.Common.Back)
		for index = 1, #rows - 1 do
			link(rows[index], "Down", rows[index + 1])
		end
		link(rows[#rows], "Down", back)
		for index, item in rows do
			playFx("rowIn", item.shard.group, (index - 1) * 0.05)
		end
		playFx("rise", back.shard.group, 0.4)
	end

	local function buildHowTo()
		topLabel(MenuCopy.Top.HowTo)
		local boxes = { L.Card1, L.Card2, L.Card3 }
		local gems = ({ "red", "blue", "violet" } :: any) :: { Shard.Gem }
		for index, step in MenuCopy.HowTo do
			local gem = gems[index]
			local shard =
				newShard("Step" .. index, boxes[index], "shard-menu-mode-" .. gem, "glow-menu-mode-" .. gem, gem)
			text(shard.content, "Num", step.Num, T.StepNumber, 24, 14, 80, 60)
			text(shard.content, "Title", step.Title, T.StepTitle, 24, 78, 184, 50, {
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				LineHeight = 1,
			})
			local body = text(shard.content, "Body", step.Body, T.StepBody, 24, 132, 180, 36, {
				FontFace = FONT.Italic,
				TextWrapped = true,
				TextYAlignment = Enum.TextYAlignment.Top,
				LineHeight = 1.2,
			})
			playFx("slam", shard.group, (index - 1) * 0.1)
			playFx("fade", body, 0.36 + (index - 1) * 0.1)
			glowLoop({ shard = shard, name = "Step" }, (index - 1) * 0.3)
		end
		local back = backButton(MenuCopy.Common.Back)
		playFx("rise", back.shard.group, 0.4)
	end

	local function badgeIcon(host: Instance, tier: RankRules.Tier, x: number, y: number, size: number): ImageLabel
		local badge = icon(host, "Badge", tier.badge, x, y, size)
		badge.BackgroundTransparency = if Shard.idOf(tier.badge) then 1 else 0.2
		return badge
	end

	-- 11 Practice home (11a ready, 11b retake clock running) and 19a (profile did not load).
	local function buildPractice(model: Model)
		local pr: PracticeModel = model.practice or {}
		topLabel(MenuCopy.Top.Practice)
		if pr.failed then
			local p = panel(
				"silver",
				MenuCopy.Skill.Tag,
				MenuCopy.Main.RankUnavailable,
				36,
				MenuCopy.Skill.UnavailableLines,
				{
					{ MenuCopy.Skill.UnavailableTag, true },
				}
			)
			local retry = action(L.Action, MenuCopy.Common.Retry, true, false)
			interactive(retry, handlers.retry, nil)
			local back = backButton(MenuCopy.Common.Back)
			link(retry, "Down", back)
			playFx("slam", p.shard.group, 0)
			playFx("pop", retry.shard.group, 0.36)
			playFx("rise", back.shard.group, 0.4)
			return
		end
		local P = MenuTheme.Panel
		local p = panel("green", MenuCopy.Skill.Tag, MenuCopy.Skill.HomeTitle, 42, {}, {})
		local tier = if pr.rank then RankRules.tierOf(pr.rank) else nil
		local rowY = P.TitleY + 42 + 10
		if tier then
			badgeIcon(p.shard.content, tier, P.LeftPad, rowY, MenuTheme.BadgeSizes.Card)
			text(p.shard.content, "Tier", tier.name, 20, P.LeftPad + 58, rowY + 2, 240, 24)
			text(
				p.shard.content,
				"Subject",
				tier.subject,
				14,
				P.LeftPad + 58,
				rowY + 26,
				240,
				18,
				{ FontFace = FONT.Italic }
			)
		else
			text(p.shard.content, "Unranked", MenuCopy.Skill.Unranked, 20, P.LeftPad, rowY + 12, 240, 24)
		end
		local last = if pr.lastTestRank then RankRules.tierOf(pr.lastTestRank) else nil
		if last then
			local lastTag =
				tag(p.shard.content, "LastTest", (string.gsub(MenuCopy.Skill.LastTest, "{tier}", last.name)))
			lastTag.Position = UDim2.fromOffset(P.LeftPad, rowY + 62)
		end
		local remaining = pr.retryRemaining or 0
		local cooling = remaining > 0
		local loading = pr.loading == true -- the profile has not answered yet: show the button disabled, not a wrong state
		local act = action(
			L.Action,
			if cooling then CooldownRules.retakeLabel(remaining) else MenuCopy.Skill.TakeTest,
			not (cooling or loading),
			cooling
		)
		if cooling then
			retakeLabel = act.shard.content:FindFirstChild("Label") :: TextLabel?
		elseif not loading then
			-- While loading the button stays disabled until the profile arrives (init re-renders the screen then).
			interactive(act, function()
				handlers.go("skillintro")
			end, nil)
		end
		local drills = secondary("Drills", L.SideSecondary, MenuCopy.Skill.TopicDrills, true)
		lockedPress(drills, "drills")
		local ladder = secondary("LadderLink", L.LadderLink, MenuCopy.Skill.Ladder, false)
		interactive(ladder, function()
			handlers.go("ladder")
		end, nil)
		local back = backButton(MenuCopy.Common.Back)
		link(act, "Down", drills)
		link(drills, "Down", back)
		link(back, "Right", ladder)
		if cooling then
			firstSelectable = back.hit -- the disabled action is skipped: BACK is the default
		end
		glowLoop(p, 0)
		playFx("slam", p.shard.group, 0)
		playFx("pop", act.shard.group, 0.36)
		playFx("rise", drills.shard.group, 0.44)
		playFx("rise", back.shard.group, 0.4)
	end

	-- 12 Skill Test intro (12a, and 12b for a first test). START is locked until the Skill Test exists (TASK-0102).
	local function buildSkillIntro(model: Model)
		local pr: PracticeModel = model.practice or {}
		topLabel(MenuCopy.Top.SkillTestHeader)
		local first = PracticeRules.isFirstTest(pr.rank, pr.lastTestRank)
		local p
		if first then
			p = panel("green", MenuCopy.Skill.FirstTag, MenuCopy.Skill.FirstTitle, 54, MenuCopy.Skill.FirstLines, {
				{ MenuCopy.Skill.Unranked, true },
			})
		else
			local tier = if pr.rank then RankRules.tierOf(pr.rank) else nil
			local best = if tier then string.gsub(MenuCopy.Skill.Best, "{tier}", tier.name) else MenuCopy.Skill.Unranked
			p = panel("green", MenuCopy.Skill.Tag, MenuCopy.Skill.IntroTitle, 32, MenuCopy.Skill.IntroLines, {
				{ best, true },
				{ MenuCopy.Skill.Formats },
			})
		end
		local act = action(L.Action, MenuCopy.Common.Start, true, false)
		local locked = ModeRules.secondaryState("skilltest", model.secondary) == "locked"
		interactive(act, function()
			if locked then
				playFx("shake", act.shard.group, 0)
				handlers.locked("skilltest")
			else
				handlers.go("skill")
			end
		end, nil)
		local back = backButton(MenuCopy.Common.Back)
		link(act, "Down", back)
		glowLoop(p, 0)
		playFx("slam", p.shard.group, 0)
		playFx("pop", act.shard.group, 0.36)
		playFx("rise", back.shard.group, 0.4)
	end

	-- 16 Rank ladder: two columns of five rungs, higher ranks higher up. Display only; BACK is the one focus target.
	local function buildLadder(model: Model)
		topLabel(MenuCopy.Top.Ladder)
		local pm: PracticeModel = model.practice or {}
		local best = pm.rank
		local offsets = MenuTheme.LadderOffsets
		for _, slot in RankRules.ladderLayout() do
			local column = if slot.column == 1 then L.LadderCol1 else L.LadderCol2
			local box = {
				x = column.x + offsets[slot.row],
				y = column.y + (slot.row - 1) * 40,
				w = column.w,
				h = column.h,
				rot = if slot.row % 2 == 1 then -0.8 else 0.8,
			}
			local mark = RankRules.ladderMark(slot.rank, best)
			local tier = RankRules.tierOf(slot.rank) :: RankRules.Tier
			local current = mark == "current"
			local dim = if mark == "locked" then 0.45 else 0
			local shard = newShard(
				"Rung" .. slot.rank,
				box,
				if current then "shard-row-green" else "shard-row-indigo",
				if current then "glow-menu-choice-green" else nil,
				if current then "green" else "blue"
			)
			shard.image.ImageTransparency = dim
			-- Audit A9: badge 22 and a 20 px left / right inset keep the content 6 px off the stretched row's cuts.
			local badge = badgeIcon(shard.content, tier, 20, 6, 22)
			badge.ImageTransparency = dim
			-- The row art (stretched HUD shard-row) has a deep cut at the bottom left and a notch at the top right: left of x 125
			-- only y 10..22 clears 6 px, so rank names are 10 px here (README 15; 11 px leaves no slack for the +-0.8 degree tilt). A 38 px row would hold 15 px (Claude Design).
			local nameLabel = text(shard.content, "Name", tier.name, T.LadderName, 50, 11, 94, 10)
			nameLabel.TextTransparency = dim
			local subjectWidth = if current then 104 else 150
			local subject = text(shard.content, "Subject", tier.subject, T.RowSubject, 146, 0, subjectWidth, 34, {
				FontFace = FONT.Italic,
				TextTruncate = Enum.TextTruncate.AtEnd,
			})
			subject:SetAttribute("AllowTruncate", true)
			subject.TextTransparency = dim
			if current then
				local you = tag(shard.content, "You", MenuCopy.Common.You, true)
				you.TextSize = T.Sticker
				you.Position = UDim2.fromOffset(254, 11)
			end
			local square = make("Frame", {
				Name = "Mark",
				Position = UDim2.fromOffset(302, 8),
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = C.ButtonInk,
				BackgroundTransparency = dim,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, shard.content)
			local markIcon =
				icon(square, "Icon", if mark == "locked" then "icon-menu-lock" else "icon-menu-check", 3, 3, 12)
			markIcon.ImageTransparency = dim
			playFx("rowIn", shard.group, (slot.row - 1) * 0.04)
			if current then
				glowLoop({ shard = shard, name = "Rung" }, 0)
			end
		end
		local back = backButton(MenuCopy.Common.Back)
		playFx("rise", back.shard.group, 0.4)
	end

	-- 13 / 14: one Skill Test question (typed or multiple choice), or its reveal.
	local function buildSkill(model: Model)
		local sk = model.skill :: SkillModel
		local integer = sk.kind == "integer"
		local reveal = sk.phase == "reveal"
		topLabel(MenuCopy.Top.SkillTest, true)

		-- Rank strip: ten badges (current 32 px with brackets, cleared opaque, above faded) then MISSES and two slots.
		local strip = make("Frame", {
			Name = "RankStrip",
			Position = UDim2.fromOffset(L.RankStrip.x, L.RankStrip.y),
			Size = UDim2.fromOffset(L.RankStrip.w, L.RankStrip.h),
			BackgroundTransparency = 1,
		}, screen :: Frame) :: Frame
		local sx = 0
		for rank = 0, 9 do
			local size = if rank == sk.rank then 32 else 24
			local node = badgeIcon(strip, RankRules.tierOf(rank) :: RankRules.Tier, sx, (36 - size) / 2, size)
			node.Name = "Node" .. rank
			if rank > sk.rank then
				node.ImageTransparency = 0.7
				node.BackgroundTransparency = 0.9
			elseif rank == sk.rank then
				make("UIStroke", { Color = C.Ink, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, node)
			end
			sx += size + 10
		end
		local misses = make("Frame", {
			Name = "Misses",
			Position = UDim2.fromOffset(sx + 6, 9),
			Size = UDim2.fromOffset(0, 18),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
		}, strip) :: Frame
		make("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}, misses)
		tag(misses, "Tag", MenuCopy.Common.Misses, false, 1)
		for slot = 1, 2 do
			local used = slot <= sk.misses
			local box = make("Frame", {
				Name = "Slot" .. slot,
				LayoutOrder = slot + 1,
				Size = UDim2.fromOffset(18, 18),
				BackgroundColor3 = if used then MenuTheme.Color.MissUsed else C.Ground,
				BackgroundTransparency = if used then 0 else 0.5,
				BorderSizePixel = 0,
			}, misses) :: Frame
			make("UIStroke", { Color = C.Ink, Transparency = 0.55, Thickness = 1 }, box)
			if used then
				icon(box, "Cross", "icon-menu-cross", 3, 3, 12)
			end
		end

		-- Problem shard with a measured size (audit A8): the largest of the tiers that fits one line, else two lines at 40.
		local box = if integer then L.SkillProblem else L.ChoiceProblem
		local problem = newShard("Problem", box, "shard-menu-problem-silver", "glow-menu-problem-silver", "silver")
		local tier = RankRules.tierOf(sk.rank) :: RankRules.Tier
		local label =
			string.gsub(string.gsub(MenuCopy.Skill.QuestionTag, "{n}", tostring(sk.rank + 1)), "{tier}", tier.name)
		label = string.gsub(label, "{time}", tostring(sk.total))
		-- (60, 40): the problem shard has a tab cut out of its top left; anything higher or further left is inside the cut.
		tag(problem.content, "Tag", label).Position = UDim2.fromOffset(60, 40)
		local shown = sk.problem
		if reveal then
			local answer = if integer
				then tostring(sk.correctValue)
				else ((sk.choices or {})[sk.correctIndex or 0] or "")
			shown = string.gsub(shown, "%?%s*$", answer)
		end
		local sizes = if integer then { 88, 76, 64, 56, 48, 40 } else { 64, 56, 48, 40 } -- the choice box is 150 tall, not 186
		local fit = TextFitRules.fitSize(measureWidth, shown, sizes, 456)
		local labelHeight = fit.size * fit.lines
		local problemLabel =
			text(problem.content, "Text", shown, fit.size, 62, if integer then 60 else 55, 456, labelHeight, {
				TextWrapped = fit.lines > 1,
				TextYAlignment = Enum.TextYAlignment.Center,
				LineHeight = 1,
			})
		problemLabel.TextXAlignment = Enum.TextXAlignment.Center
		glowLoop({ shard = problem, name = "Problem" }, 0)
		playFx("slam", problem.group, 0)

		-- Timer bar and the seconds column.
		local bar = if integer then L.SkillTimerBar else L.ChoiceTimerBar
		local track = make("Frame", {
			Name = "TimerBar",
			Position = UDim2.fromOffset(bar.x, bar.y),
			Size = UDim2.fromOffset(bar.w, bar.h),
			Rotation = bar.rot,
			BackgroundColor3 = C.Ink,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
		}, screen :: Frame)
		skillFill = make("Frame", {
			Name = "Fill",
			Size = UDim2.fromScale(if reveal then 0 else 1, 1),
			BackgroundColor3 = C.Ink,
			BorderSizePixel = 0,
		}, track) :: Frame
		local sec = L.SkillSeconds
		tag(screen :: Frame, "SecTag", if reveal then MenuCopy.Common.NextUp else MenuCopy.Common.Sec).Position =
			UDim2.fromOffset(sec.x + 4, sec.y)
		skillSeconds = text(
			screen :: Frame,
			"Seconds",
			if reveal then "0" else tostring(sk.total),
			100,
			sec.x,
			sec.y + 22,
			sec.w,
			108,
			{
				TextXAlignment = Enum.TextXAlignment.Right,
			}
		)

		-- Feedback toast at the bottom (silver LOCKED IN, green CORRECT, red NOT QUITE).
		if reveal then
			if sk.correct then
				toastAt(MenuCopy.Skill.Correct, "icon-menu-check", "green", true, true)
			else
				toastAt(
					if sk.misses >= 2 then MenuCopy.Skill.NotQuiteMisses else MenuCopy.Skill.NotQuiteMiss,
					"icon-menu-cross",
					"red",
					true,
					true
				)
			end
		elseif sk.locked then
			toastAt(MenuCopy.Common.LockedIn, "icon-menu-lock", "silver", true, true)
		end

		local canAnswer = not (reveal or sk.locked)
		if integer then
			local inputShard = newShard("Input", L.SkillInput, "shard-input", nil, "silver")
			local lockShard = newShard("LockIn", L.SkillLock, "shard-button", nil, "silver")
			local answerBox = make("TextBox", {
				Name = "Answer",
				Size = UDim2.fromOffset(L.SkillInput.w, L.SkillInput.h),
				BackgroundTransparency = 1,
				FontFace = FONT.Body,
				Text = "",
				PlaceholderText = MenuCopy.Common.TypeAnswer,
				PlaceholderColor3 = C.InkDim,
				TextSize = 30,
				TextColor3 = C.Ink,
				TextXAlignment = Enum.TextXAlignment.Left,
				ClearTextOnFocus = false,
				TextEditable = canAnswer,
				SelectionImageObject = selection,
				ZIndex = 12,
			}, inputShard.content) :: TextBox
			make("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 18) }, answerBox)
			local lockLabel =
				text(lockShard.content, "Label", MenuCopy.Common.LockIn, T.Action, 0, 0, L.SkillLock.w, L.SkillLock.h, {
					TextXAlignment = Enum.TextXAlignment.Center,
					TextColor3 = C.ButtonInk,
					TextStrokeTransparency = 1,
				})
			local lockItem: Item = { shard = lockShard, name = "LockIn" }
			local function submit()
				local digits = HudRulesSkill.sanitizeInput(answerBox.Text)
				if canAnswer and digits ~= "" then
					handlers.skillLock(tonumber(digits) :: number)
				end
			end
			answerBox:GetPropertyChangedSignal("Text"):Connect(function()
				local clean = HudRulesSkill.sanitizeInput(answerBox.Text)
				if clean ~= answerBox.Text then
					answerBox.Text = clean
				end
			end)
			answerBox.FocusLost:Connect(function(enter: boolean)
				if enter then
					submit()
				end
			end)
			if canAnswer then
				interactive(lockItem, submit, nil)
				firstSelectable = firstSelectable or answerBox
			else
				lockLabel.TextTransparency = MenuTheme.DisabledTransparency
				lockShard.image.ImageTransparency = MenuTheme.DisabledTransparency
			end
			playFx("rise", inputShard.group, 0.28)
			playFx("pop", lockShard.group, 0.3)
			return
		end

		local boxes = { L.ChoiceA, L.ChoiceB, L.ChoiceC, L.ChoiceD }
		local items: { Item } = {}
		for index = 1, 4 do
			local isChosen = if reveal then sk.chosen == index else sk.selected == index
			local isCorrect = reveal and sk.correctIndex == index
			local isWrongPick = reveal and sk.chosen == index and not isCorrect
			local key = if isCorrect
				then "shard-menu-choice-green"
				elseif isWrongPick then "shard-menu-choice-red"
				elseif isChosen then "shard-menu-choice-white"
				else "shard-menu-choice-indigo"
			local gem = if isCorrect then "green" elseif isWrongPick then "red" else "blue"
			local shard =
				newShard("Choice" .. index, boxes[index], key, if isChosen then "glow-menu-choice-green" else nil, gem)
			local item: Item = { shard = shard, name = "Choice" .. index }
			local ink = if key == "shard-menu-choice-white" then C.ButtonInk else C.Ink
			local dim = if (reveal or sk.locked) and not (isChosen or isCorrect)
				then MenuTheme.DisabledTransparency
				else 0
			shard.image.ImageTransparency = if dim > 0 then dim else 0
			local square = make("Frame", {
				Name = "Letter",
				Position = UDim2.fromOffset(16, 13),
				Size = UDim2.fromOffset(28, 28),
				BackgroundColor3 = C.Tag,
				BackgroundTransparency = dim,
				BorderSizePixel = 0,
				ZIndex = 5,
			}, shard.content)
			local letter = text(square, "Text", string.char(64 + index), T.ChoiceLetter, 0, 0, 28, 28, {
				TextXAlignment = Enum.TextXAlignment.Center,
				TextStrokeTransparency = 1,
			})
			letter.TextTransparency = dim
			local answerLabel =
				text(shard.content, "Answer", (sk.choices or {})[index] or "", T.Choice, 56, 0, 190, 54, {
					TextScaled = true,
					TextColor3 = ink,
					TextStrokeTransparency = if ink == C.ButtonInk then 1 else MenuTheme.TextStrokeTransparency,
					TextXAlignment = Enum.TextXAlignment.Left,
				})
			make("UITextSizeConstraint", { MinTextSize = 14, MaxTextSize = 18 }, answerLabel)
			answerLabel.TextTransparency = dim
			local mark: string? = if isCorrect
				then "icon-menu-check"
				elseif isWrongPick then "icon-menu-cross"
				elseif sk.locked and isChosen and not reveal then "icon-menu-lock"
				else nil
			if mark then
				icon(shard.content, "Mark", mark, 250, 17, 20)
			end
			if canAnswer then
				interactive(item, function()
					if sk.selected == index then
						handlers.skillLock(index)
					else
						handlers.skillSelect(index)
					end
				end, 1.02)
			end
			items[index] = item
			playFx("rowIn", shard.group, 0.28 + (index - 1) * 0.06)
		end
		if canAnswer then
			local lockShard = newShard("LockIn", L.ChoiceLockIn, "shard-button", nil, "silver")
			local lockItem: Item = { shard = lockShard, name = "LockIn" }
			local ready = sk.selected ~= nil
			local lockLabel = text(
				lockShard.content,
				"Label",
				MenuCopy.Common.LockIn,
				T.Action,
				0,
				0,
				L.ChoiceLockIn.w,
				L.ChoiceLockIn.h,
				{
					TextXAlignment = Enum.TextXAlignment.Center,
					TextColor3 = C.ButtonInk,
					TextStrokeTransparency = 1,
				}
			)
			if ready then
				interactive(lockItem, function()
					handlers.skillLock(sk.selected :: number)
				end, nil)
			else
				lockLabel.TextTransparency = MenuTheme.DisabledTransparency
				lockShard.image.ImageTransparency = MenuTheme.DisabledTransparency
			end
			link(items[1], "Right", items[2])
			link(items[3], "Right", items[4])
			link(items[1], "Down", items[3])
			link(items[2], "Down", items[4])
			if ready then
				link(items[4], "Down", lockItem)
				link(items[3], "Down", lockItem)
			end
		end
	end

	-- 15 Skill Test result (first rank / rank up / rank held).
	local function buildSkillResult(model: Model)
		local r = model.result :: ResultModel
		local P = MenuTheme.Panel
		topLabel(MenuCopy.Top.SkillResult)
		local gems = { first = "green", up = "violet", held = "silver" }
		local titles = { first = MenuCopy.Skill.FirstRank, up = MenuCopy.Skill.RankUp, held = MenuCopy.Skill.Held }
		local sizes = { first = 50, up = 58, held = 58 }
		local kind = if r.kind == "up" or r.kind == "held" then r.kind else "first"
		local tier = RankRules.tierOf(r.best) :: RankRules.Tier
		local p = panel(
			(gems :: { [string]: string })[kind],
			if kind == "first" then MenuCopy.Skill.FirstRankTag else MenuCopy.Top.SkillResult,
			(titles :: { [string]: string })[kind],
			(sizes :: { [string]: number })[kind],
			{},
			{}
		)
		local size = (sizes :: { [string]: number })[kind]
		local rowY = P.TitleY + size + 6
		badgeIcon(p.shard.content, tier, P.LeftPad, rowY, MenuTheme.BadgeSizes.Card)
		text(p.shard.content, "Tier", tier.name, 20, P.LeftPad + 58, rowY + 2, 240, 24)
		text(
			p.shard.content,
			"Subject",
			tier.subject,
			14,
			P.LeftPad + 58,
			rowY + 26,
			240,
			18,
			{ FontFace = FONT.Italic }
		)
		local line = if kind == "held"
			then string.gsub(
				MenuCopy.Skill.HeldLine,
				"{tier}",
				(RankRules.tierOf(r.cleared or 0) :: RankRules.Tier).name
			)
			else string.gsub(MenuCopy.Skill.RetakeLine, "{time}", CooldownRules.formatClock(r.retryRemaining))
		text(p.shard.content, "Line", line, T.PanelLine, P.LeftPad, rowY + 56, 406, 20, { FontFace = FONT.Italic })

		-- Badges on the right: the old one faded with an arrow (rank up only), the new one large on its tier glow.
		local glowKey = "glow-menu-rank-" .. tier.key
		local glow = make("ImageLabel", {
			Name = "TierGlow",
			Position = UDim2.fromOffset(616, 24),
			Size = UDim2.fromOffset(192, 192),
			BackgroundTransparency = 1,
			ZIndex = 3,
		}, screen :: Frame) :: ImageLabel
		Shard.setImage(glow, glowKey, nil, nil)
		table.insert(stops, Fx.breathe(glow, 0))
		local newBadge = badgeIcon(screen :: Frame, tier, L.RankNew.x, L.RankNew.y, MenuTheme.BadgeSizes.Hero)
		newBadge.Name = "NewBadge"
		newBadge.ZIndex = 6
		make("UIScale", {}, newBadge)
		if kind == "up" and r.previousBest ~= nil then
			local old = badgeIcon(
				screen :: Frame,
				RankRules.tierOf(r.previousBest) :: RankRules.Tier,
				L.RankOld.x,
				L.RankOld.y,
				48
			)
			old.Name = "OldBadge"
			old.ImageTransparency = 0.4
			icon(screen :: Frame, "Arrow", "icon-menu-chevron", L.RankArrow.x, L.RankArrow.y, 24)
		end
		local done = action(L.BottomAction, MenuCopy.Common.Done, true, false)
		interactive(done, handlers.back, nil)
		local ladder = secondary("Ladder", L.BottomSecondary, MenuCopy.Skill.Ladder, false)
		interactive(ladder, function()
			handlers.go("ladder")
		end, nil)
		link(done, "Right", ladder)
		glowLoop(p, 0)
		playFx("slam", p.shard.group, 0)
		playFx("badgeSlam", newBadge, 0.45)
		playFx("flash", p.shard.flash, 0.62)
		playFx("pop", done.shard.group, 0.6)
		playFx("rise", ladder.shard.group, 0.66)
	end

	-- 06 Blitz question: the HUD question layout with neutral pips, a dash for the score and one run clock. No right or wrong
	-- is ever shown here; the review (07) is the only place that tells.
	local function buildBlitz(model: Model)
		local bm = model.blitz :: BlitzModel
		local count = MenuConfig.BlitzTotal
		topLabel(string.gsub(MenuCopy.Top.BlitzQuestion, "{n}", tostring(bm.index)), true)
		for pip = 1, count do
			local alpha = if pip < bm.index then 0 elseif pip == bm.index then 0.25 else 0.82
			make("Frame", {
				Name = "Pip" .. pip,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(318 + (pip - 1) * 13, 22),
				Size = UDim2.fromOffset(8, 8),
				Rotation = 45,
				BackgroundColor3 = C.Ink,
				BackgroundTransparency = alpha,
				BorderSizePixel = 0,
			}, screen :: Frame)
		end
		-- Score stays a dash for the whole run.
		local scoreBox = { x = 650, y = 10, w = 150, h = 44, rot = 1.5 }
		local score = newShard("Score", scoreBox, "shard-score-silver", nil, "silver")
		text(score.content, "Tag", MenuCopy.Common.Score, T.Tag, 20, 0, 60, 44, { TextTransparency = 0.3 })
		text(
			score.content,
			"Value",
			MenuCopy.Common.ScoreHidden,
			18, -- 18 px at y 15..33: the score shard is a sliver along its top edge, only y 14..34 clears 6 px at this x
			80,
			15,
			50,
			18,
			{ TextXAlignment = Enum.TextXAlignment.Right }
		)

		local problem =
			newShard("Problem", L.SkillProblem, "shard-menu-problem-silver", "glow-menu-problem-silver", "silver")
		tag(problem.content, "Tag", (string.gsub(MenuCopy.Blitz.QuestionTag, "{n}", tostring(bm.index)))).Position =
			UDim2.fromOffset(60, 40)
		local shown = bm.problem .. " = ?"
		local fit = TextFitRules.fitSize(measureWidth, shown, { 88, 76, 64, 56, 48, 40 }, 456)
		local problemLabel = text(problem.content, "Text", shown, fit.size, 62, 60, 456, fit.size * fit.lines, {
			TextWrapped = fit.lines > 1,
			LineHeight = 1,
		})
		problemLabel.TextXAlignment = Enum.TextXAlignment.Center
		glowLoop({ shard = problem, name = "Problem" }, 0)
		playFx("slam", problem.group, 0)

		-- One run clock: the bar and the column on the right show the total time left.
		local bar = L.SkillTimerBar
		local track = make("Frame", {
			Name = "TimerBar",
			Position = UDim2.fromOffset(bar.x, bar.y),
			Size = UDim2.fromOffset(bar.w, bar.h),
			Rotation = bar.rot,
			BackgroundColor3 = C.Ink,
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
		}, screen :: Frame)
		skillFill = make(
			"Frame",
			{ Name = "Fill", Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.Ink, BorderSizePixel = 0 },
			track
		) :: Frame
		local clock = L.BlitzClock
		tag(screen :: Frame, "ClockTag", MenuCopy.Common.Left).Position = UDim2.fromOffset(clock.x + 4, clock.y)
		blitzClock = text(
			screen :: Frame,
			"Clock",
			CooldownRules.formatShort(bm.total),
			60,
			clock.x,
			clock.y + 22,
			clock.w,
			64,
			{
				TextXAlignment = Enum.TextXAlignment.Right,
				TextScaled = true,
			}
		)
		make("UITextSizeConstraint", { MinTextSize = 36, MaxTextSize = 60 }, blitzClock)

		if bm.locked then
			toastAt(MenuCopy.Common.LockedIn, "icon-menu-lock", "silver", true, true)
		end
		local inputShard = newShard("Input", L.SkillInput, "shard-input", nil, "silver")
		local lockShard = newShard("LockIn", L.SkillLock, "shard-button", nil, "silver")
		local answerBox = make("TextBox", {
			Name = "Answer",
			Size = UDim2.fromOffset(L.SkillInput.w, L.SkillInput.h),
			BackgroundTransparency = 1,
			FontFace = FONT.Body,
			Text = "",
			PlaceholderText = MenuCopy.Common.TypeAnswer,
			PlaceholderColor3 = C.InkDim,
			TextSize = 30,
			TextColor3 = C.Ink,
			TextXAlignment = Enum.TextXAlignment.Left,
			ClearTextOnFocus = false,
			TextEditable = not bm.locked,
			SelectionImageObject = selection,
			ZIndex = 12,
		}, inputShard.content) :: TextBox
		make("UIPadding", { PaddingLeft = UDim.new(0, 22), PaddingRight = UDim.new(0, 18) }, answerBox)
		local lockLabel =
			text(lockShard.content, "Label", MenuCopy.Common.LockIn, T.Action, 0, 0, L.SkillLock.w, L.SkillLock.h, {
				TextXAlignment = Enum.TextXAlignment.Center,
				TextColor3 = C.ButtonInk,
				TextStrokeTransparency = 1,
			})
		local function submit()
			local digits = HudRulesSkill.sanitizeInput(answerBox.Text)
			if not bm.locked and digits ~= "" then
				handlers.blitzLock(tonumber(digits) :: number)
			end
		end
		answerBox:GetPropertyChangedSignal("Text"):Connect(function()
			local clean = HudRulesSkill.sanitizeInput(answerBox.Text)
			if clean ~= answerBox.Text then
				answerBox.Text = clean
			end
		end)
		answerBox.FocusLost:Connect(function(enter: boolean)
			if enter then
				submit()
			end
		end)
		if bm.locked then
			lockLabel.TextTransparency = MenuTheme.DisabledTransparency
			lockShard.image.ImageTransparency = MenuTheme.DisabledTransparency
		else
			interactive({ shard = lockShard, name = "LockIn" }, submit, nil)
			firstSelectable = firstSelectable or answerBox
		end
		playFx("rise", inputShard.group, 0.28)
		playFx("pop", lockShard.group, 0.3)
	end

	-- 07 Blitz review: the score card and the ten answers in two columns (green + check right, indigo + cross wrong).
	local function buildBlitzReview(model: Model)
		local rv = model.review :: ReviewModel
		topLabel(MenuCopy.Top.BlitzReview)
		local card = newShard("Card", L.ReviewCard, "shard-menu-mode-violet", "glow-menu-mode-violet", "violet")
		tag(card.content, "Tag", MenuCopy.Blitz.FinalTag).Position = UDim2.fromOffset(24, 24)
		local scoreLabel = text(card.content, "Score", BlitzRules.scoreText(rv.correct), 84, 24, 52, 184, 84, {
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
		make("UITextSizeConstraint", { MinTextSize = 48, MaxTextSize = 84 }, scoreLabel)
		text(
			card.content,
			"Best",
			BlitzRules.bestText(rv.previousBest),
			15,
			24,
			144,
			184,
			24,
			{ FontFace = FONT.Italic }
		)
		if rv.newBest then
			local newBestTag = tag(screen :: Frame, "NewBest", MenuCopy.Blitz.NewBest, true)
			newBestTag.TextSize = 13
			newBestTag.Position = UDim2.fromOffset(L.NewBest.x, L.NewBest.y)
			newBestTag.Rotation = L.NewBest.rot
			newBestTag.ZIndex = 20
			newBestTag:SetAttribute("FitSticker", true)
		end
		local rows = BlitzRules.reviewRows(rv.answers, rv.solutions)
		for column = 1, 2 do
			local origin = if column == 1 then L.ReviewCol1 else L.ReviewCol2
			local captions: { { string | number } } = {
				{ MenuCopy.Blitz.ColQ, 12 },
				{ MenuCopy.Blitz.ColYou, 70 },
				{ MenuCopy.Blitz.ColAnswer, 150 },
			}
			for _, entry in captions do
				local caption, offset = entry[1] :: string, entry[2] :: number
				local header = text(
					screen :: Frame,
					"Header" .. column .. caption,
					caption,
					10,
					origin.x + offset,
					32,
					70,
					14,
					{ TextTransparency = 0.45, TextStrokeTransparency = 1 }
				)
				header:SetAttribute("FitEdge", true)
			end
			for slot = 1, 5 do
				local entry = rows[(column - 1) * 5 + slot]
				if entry then
					local box = { x = origin.x, y = origin.y + (slot - 1) * 38, w = origin.w, h = origin.h, rot = 0 }
					local shard = newShard(
						"Row" .. ((column - 1) * 5 + slot),
						box,
						if entry.ok then "shard-row-green" else "shard-row-indigo",
						nil,
						if entry.ok then "green" else "blue"
					)
					-- Audit A9 / TASK-0103: the 32 px row art leaves 10 px clear left of x 88 and 14 px right of it, so the question
					-- number is 9 px in the left zone and the two answers are 12 px (README 13 / 16) from x 92. 38 px rows fix it.
					text(shard.content, "Q", entry.q, 9, 44, 10.7, 40, 9, { TextTransparency = 0.3 })
					local markSquare = make("Frame", {
						Name = "Mark",
						Position = UDim2.fromOffset(18, 7),
						Size = UDim2.fromOffset(18, 18),
						BackgroundColor3 = C.ButtonInk,
						BorderSizePixel = 0,
						ZIndex = 5,
					}, shard.content)
					icon(markSquare, "Icon", if entry.ok then "icon-menu-check" else "icon-menu-cross", 3, 3, 12)
					text(shard.content, "You", entry.you, 12, 92, 10, 62, 12)
					local ans = text(shard.content, "Answer", entry.ans, 12, 160, 10, 64, 12)
					ans.TextTransparency = 0.4
					playFx("rowIn", shard.group, 0.3 + ((column - 1) * 5 + slot) * 0.05)
				end
			end
		end
		local again = action(L.PlayAgain, MenuCopy.Blitz.PlayAgain, true, false)
		interactive(again, function()
			handlers.go("blitz")
		end, nil)
		local menuButton = secondary("Menu", L.ReviewMenu, MenuCopy.Common.Menu, false)
		interactive(menuButton, handlers.back, nil)
		link(again, "Down", menuButton)
		glowLoop({ shard = card, name = "Card" }, 0)
		playFx("slam", card.group, 0)
		playFx("pop", again.shard.group, 0.42)
		playFx("rise", menuButton.shard.group, 0.48)
	end

	local function buildWatching()
		local shard = newShard("Banner", L.WatchBanner, "shard-menu-banner-violet", "glow-menu-banner-violet", "violet")
		-- The banner shard (480x44) has a cut along the top right and the bottom left: only y 14..30 clears 6 px at every x, so
		-- the label is 15 px (README 17) and centred.
		text(shard.content, "Label", MenuCopy.Mode.Group.Watching, T.WatchBanner, 0, 0, 480, 44, {
			TextXAlignment = Enum.TextXAlignment.Center,
		})
		glowLoop({ shard = shard, name = "Banner" }, 0)
		playFx("rise", shard.group, 0.3)
	end

	local function render(id: string, model: Model)
		clearScreen()
		quiet = model.quiet == true
		-- A screen builds the toast it needs (CORRECT, LOCKED IN, ...); one left from the previous screen or question goes.
		for _, child in toastLayer:GetChildren() do
			child:Destroy()
		end
		local frame = make(
			"Frame",
			{ Name = "Screen_" .. id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 },
			root
		) :: Frame
		screen = frame
		if not overlay then
			edges()
		end
		local ok, err = pcall(function()
			if id == "watching" then
				buildWatching()
			elseif id == "blitz" and model.blitz then
				buildBlitz(model)
			elseif id == "blitzreview" and model.review then
				buildBlitzReview(model)
			elseif id == "skill" and model.skill then
				buildSkill(model)
			elseif id == "skillresult" and model.result then
				buildSkillResult(model)
			elseif id == "practice" then
				buildPractice(model)
			elseif id == "skillintro" then
				buildSkillIntro(model)
			elseif id == "ladder" then
				buildLadder(model)
			elseif id == "main" then
				buildMain(model)
			elseif id == "modes" then
				buildModes(model)
			elseif id == "confirm_blitz" then
				buildConfirm("blitz", model)
			elseif id == "confirm_vs" then
				buildConfirm("vs", model)
			elseif id == "confirm_group" then
				buildConfirm("group", model)
			elseif id == "settings" then
				buildSettings(model)
			elseif id == "howto" then
				buildHowTo()
			else
				warn(`[MathShow] Menu has no screen {id}`)
			end
		end)
		if not ok then
			warn(`[MathShow] Menu screen {id} failed: {err}`)
		end
	end

	gui.Parent = parent
	local view: View = {
		gui = gui,
		root = root,
		render = render,
		toast = toast,
		setBlitzClock = function(fraction: number, str: string)
			if skillFill then
				skillFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			end
			if blitzClock then
				blitzClock.Text = str
			end
		end,
		setSkillTimer = function(fraction: number, seconds: number)
			if skillFill then
				skillFill.Size = UDim2.fromScale(math.clamp(fraction, 0, 1), 1)
			end
			if skillSeconds then
				skillSeconds.Text = tostring(math.max(0, math.ceil(seconds)))
			end
		end,
		setRetakeLabel = function(str: string)
			if retakeLabel then
				retakeLabel.Text = str
			end
		end,
		defaultFocus = function()
			return firstSelectable
		end,
		setReduced = function(on: boolean)
			reduced = on
		end,
		destroy = function()
			clearScreen()
			gui:Destroy()
		end,
	}
	return view
end

return View
