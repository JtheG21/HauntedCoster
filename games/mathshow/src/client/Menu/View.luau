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
local ModeRules = require(Shared:WaitForChild("ModeRules"))
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
export type Model = {
	flags: { [string]: boolean }?,
	secondary: { [string]: boolean }?,
	player: Player?,
	settings: Settings?,
	best: string?, -- "6/10": the white BEST tag on the Blitz panel
	waiting: boolean?, -- 03b action after FIND OPPONENT is pressed in a preview
	toast: string?,
}
export type Handlers = {
	go: (id: string) -> (),
	back: () -> (),
	locked: (what: string) -> (),
	join: () -> (),
	setting: (key: string, value: number | boolean) -> (),
}
export type View = {
	gui: ScreenGui,
	root: Frame,
	render: (id: string, model: Model) -> (),
	toast: (text: string, icon: boolean) -> (),
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

function View.build(parent: Instance, handlers: Handlers): View
	local gui = make("ScreenGui", {
		Name = "MathShowMenu",
		ResetOnSpawn = false,
		DisplayOrder = 10,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	}, nil) :: ScreenGui

	make("Frame", {
		Name = "Ground",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Ground,
		BackgroundTransparency = MenuTheme.LobbyOverlayTransparency,
		BorderSizePixel = 0,
	}, gui)
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

	local function topLabel(str: string)
		text(screen :: Frame, "TopLabel", str, 13, 0, L.TopLabel.y, 844, 16, {
			TextXAlignment = Enum.TextXAlignment.Center,
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

	local function toast(str: string, withIcon: boolean)
		toastToken += 1
		local token = toastToken
		toastToken = token
		for _, child in toastLayer:GetChildren() do
			child:Destroy()
		end
		local TO = MenuTheme.Toast
		local width = math.ceil(measureWidth(str, T.Toast)) + TO.PadX * 2 + (if withIcon then TO.IconExtra else 0)
		local box = { x = 422 - width // 2, y = L.ToastTop.y, w = width, h = TO.Height, rot = L.ToastTop.rot }
		local shard = Shard.new(toastLayer, "Toast", box, "shard-toast-silver", "glow-toast-silver", "silver")
		local x = TO.PadX
		if withIcon then
			icon(shard.content, "Lock", "icon-menu-lock", TO.PadX, 12, TO.IconSize)
			x += TO.IconExtra
		end
		text(shard.content, "Label", str, T.Toast, x, 0, width - x - TO.PadX, TO.Height)
		playFx("pop", shard.group, 0)
		task.delay(MenuConfig.ToastSeconds, function()
			if toastToken == token and shard.root.Parent then
				shard.root:Destroy()
			end
		end)
	end

	------------------------------------------------------------------------------------------------------------
	-- Screens
	------------------------------------------------------------------------------------------------------------

	local function edges()
		for index, side in { "Left", "Right" } do
			local label = text(screen :: Frame, "Edge" .. side, string.rep("MATHSHOW · ", 4), 28, 0, 0, 400, 32, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromOffset(if index == 1 then 22 else 822, 195),
				Rotation = if index == 1 then -90 else 90,
				TextTransparency = 0.945,
				TextStrokeTransparency = 1,
				ClipsDescendants = true,
				ZIndex = 0,
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
			toast(model.toast, true)
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
		text(shard.content, "Label", label, T.SettingLabel, 20, 0, 170, 44)
		local max = MenuConfig.SettingMax
		local function square(name: string, str: string, x: number, off: boolean, delta: number)
			local b = make("ImageLabel", {
				Name = name,
				Position = UDim2.fromOffset(x, 0),
				Size = UDim2.fromOffset(44, 44),
				BackgroundTransparency = 1,
				ZIndex = 5,
			}, shard.content) :: ImageLabel
			Shard.setImage(b, "shard-menu-square-silver", "silver", nil)
			if off then
				b.ImageTransparency = MenuTheme.DisabledTransparency
			end
			local l = text(b, "Glyph", str, 22, 0, 0, 44, 44, { TextXAlignment = Enum.TextXAlignment.Center })
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
		text(shard.content, "Label", label, T.SettingLabel, 20, 0, 170, 44)
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

	local function render(id: string, model: Model)
		clearScreen()
		local frame = make(
			"Frame",
			{ Name = "Screen_" .. id, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 },
			root
		) :: Frame
		screen = frame
		edges()
		local ok, err = pcall(function()
			if id == "main" then
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
