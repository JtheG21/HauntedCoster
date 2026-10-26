--!strict
-- Builds the MathShowHud ScreenGui ("Shards" pass, TASK-0097) and exposes typed setters. Instances live only
-- here; no remote or round logic does. Everything is laid out on the 844x390 reference canvas (Theme.Layout) in
-- one root Frame scaled to the safe area, so the same numbers hold from a phone to a 1920x1080 window.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudConfig = require(Shared:WaitForChild("HudConfig"))
local HudCopy = require(Shared:WaitForChild("HudCopy"))
local HudRules = require(Shared:WaitForChild("HudRules"))
local StandingsConfig = require(Shared:WaitForChild("StandingsConfig"))
local StandingsRules = require(Shared:WaitForChild("StandingsRules"))

local Fx = require(script.Parent.Fx)
local Shard = require(script.Parent.Shard)
local Theme = require(script.Parent.Theme)

export type View = {
	gui: ScreenGui,
	input: TextBox,
	submitButton: TextButton,
	-- Top label, pips and the score shard.
	setTop: (model: HudRules.TopModel, alert: boolean) -> (),
	setScore: (tag: string, value: string) -> (),
	-- Intermission: the lobby card, or the get-ready card with its countdown shard.
	setIntermission: (mode: string) -> (),
	setCountdown: (text: string) -> (),
	-- Question and Reveal.
	setProblem: (model: HudRules.ProblemModel?, gem: Theme.Gem, revealed: boolean) -> (),
	setTimer: (fraction: number, label: string, visible: boolean, warning: boolean, tag: string, dimmed: boolean) -> (),
	setInputVisible: (visible: boolean) -> (),
	setInputLocked: (locked: boolean) -> (),
	setSubmitEnabled: (enabled: boolean) -> (),
	setInputText: (text: string) -> (),
	setToast: (toast: HudRules.Toast?, reveal: boolean) -> (),
	setSolvers: (model: HudRules.SolversModel?) -> (),
	-- Results. model nil and message nil hides the screen; a message (or an empty model) shows the message card.
	setResults: (model: StandingsRules.Model?, message: string?) -> (),
	-- What Fx animates.
	intermissionParts: (mode: string) -> Fx.IntermissionParts,
	questionParts: Fx.QuestionParts,
	revealParts: () -> Fx.RevealParts,
	toastParts: Fx.ToastParts,
	resultsParts: () -> Fx.ResultsParts,
	tickParts: Fx.TickParts,
	scoreGroup: GuiObject,
	visibleGlows: () -> { GuiObject }, -- glows of the breathing shards that are on screen
	ambient: { sparks: { GuiObject }, edges: { GuiObject } },
	destroy: () -> (),
}

local C = Theme.Color
local L = Theme.Layout
local make = Theme.make
local FONT = Theme.Font

local View = {}

------------------------------------------------------------------------------------------------------------------
-- Small constructors
------------------------------------------------------------------------------------------------------------------

local function list(
	parent: Instance,
	direction: Enum.FillDirection,
	gap: number,
	horizontal: Enum.HorizontalAlignment?,
	vertical: Enum.VerticalAlignment?
): UIListLayout
	return make("UIListLayout", {
		FillDirection = direction,
		Padding = UDim.new(0, gap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = horizontal or Enum.HorizontalAlignment.Left,
		VerticalAlignment = vertical or Enum.VerticalAlignment.Top,
	}, parent) :: UIListLayout
end

local function pad(parent: Instance, left: number, top: number, right: number, bottom: number)
	make("UIPadding", {
		PaddingLeft = UDim.new(0, left),
		PaddingTop = UDim.new(0, top),
		PaddingRight = UDim.new(0, right),
		PaddingBottom = UDim.new(0, bottom),
	}, parent)
end

-- A transparent CanvasGroup that sizes to its content: the unit Fx fades and slides for text blocks.
local function block(parent: Instance, name: string, order: number?): CanvasGroup
	return make("CanvasGroup", {
		Name = name,
		BackgroundTransparency = 1,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		LayoutOrder = order or 0,
	}, parent) :: CanvasGroup
end

local function outlineTag(tag: TextLabel)
	make("UIStroke", {
		Color = C.Ink,
		Transparency = 0.75,
		Thickness = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, tag)
end

-- A small white diamond (a square turned 45 degrees) centred at (cx, cy); carries a UIScale for Fx.twinkle.
local function diamond(parent: Instance, name: string, cx: number, cy: number, w: number, h: number): Frame
	local side = (w + h) / 2 * 0.7
	local frame = make("Frame", {
		Name = name,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(cx, cy),
		Size = UDim2.fromOffset(side, side),
		Rotation = 45,
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
	}, parent) :: Frame
	make("UIScale", {}, frame)
	return frame
end

------------------------------------------------------------------------------------------------------------------
-- Build
------------------------------------------------------------------------------------------------------------------

function View.build(parent: Instance): View
	local gui = make("ScreenGui", {
		Name = "MathShowHud",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	}, nil) :: ScreenGui

	-- Ground behind everything, so the bars around a scaled canvas on other aspect ratios match it.
	make("Frame", {
		Name = "Ground",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.Ground,
		BorderSizePixel = 0,
		ZIndex = 0,
	}, gui)
	local root = make("Frame", {
		Name = "Root",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(HudConfig.ReferenceWidth, HudConfig.ReferenceHeight),
		BackgroundColor3 = C.Ground,
		BorderSizePixel = 0,
		ClipsDescendants = true,
	}, gui) :: Frame
	local rootScale = make("UIScale", {}, root) :: UIScale
	local function fit()
		rootScale.Scale = HudRules.rootScale(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)

	local breathers: { Shard.Shard } = {}

	----- Edge text: MATHSHOW running up both sides, drifting.
	local edges: { GuiObject } = {}
	for index, x in { 8, HudConfig.ReferenceWidth - 8 - 34 } do
		local clip = make("Frame", {
			Name = `Edge{index}`,
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(34, HudConfig.ReferenceHeight),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
		}, root)
		local text = Theme.label(clip, string.rep("MATHSHOW · ", 5), 28, {
			Name = "Text",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromOffset(17, HudConfig.ReferenceHeight / 2),
			Rotation = 90,
			TextTransparency = 0.945,
			TextStrokeTransparency = 1,
		})
		table.insert(edges, text)
	end

	----- Top label and pips
	local top = make("Frame", {
		Name = "Top",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromOffset(HudConfig.ReferenceWidth / 2, L.TopLabel.y),
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
	}, root) :: Frame
	list(top, Enum.FillDirection.Horizontal, 12, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local topLabel = Theme.label(top, "", 13, {
		Name = "Label",
		TextColor3 = C.InkDim,
		TextStrokeTransparency = 1,
		LayoutOrder = 1,
	})
	local pipRow = make("Frame", {
		Name = "Pips",
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Visible = false,
	}, top) :: Frame
	list(pipRow, Enum.FillDirection.Horizontal, 5, nil, Enum.VerticalAlignment.Center)
	local pips: { Frame } = {}
	for index = 1, 6 do
		local slot = make("Frame", {
			Name = `Slot{index}`,
			Size = UDim2.fromOffset(8, 8),
			BackgroundTransparency = 1,
			LayoutOrder = index,
		}, pipRow)
		pips[index] = diamond(slot, "Pip", 4, 4, 8, 8)
		pips[index].Size = UDim2.fromOffset(6, 6)
	end

	----- Score shard
	local score =
		Shard.new(root, "Score", L.Score, "shard-score-silver", { glowKey = "glow-score-silver", gem = "silver" })
	list(
		score.content,
		Enum.FillDirection.Horizontal,
		8,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)
	local scoreTag = Theme.tag(score.content, HudCopy.Score, 10, { Name = "Tag", LayoutOrder = 1 })
	local scoreValue = Theme.label(score.content, "0", 21, { Name = "Value", LayoutOrder = 2 })

	----- Intermission: lobby card, get-ready card and its countdown shard
	local function card(
		name: string,
		layout: Theme.Box,
		imageKey: string,
		glowKey: string,
		gem: Theme.Gem,
		padLeft: number,
		padTop: number,
		tagText: string,
		titleText: string,
		titleSize: number,
		subText: string,
		subSize: number,
		subWidth: number?
	): (Shard.Shard, Fx.IntermissionParts)
		local shard = Shard.new(root, name, layout, imageKey, { glowKey = glowKey, gem = gem })
		shard.root.Visible = false
		table.insert(breathers, shard)
		pad(shard.content, padLeft, padTop, 0, 0)
		list(shard.content, Enum.FillDirection.Vertical, 8)
		local tagBlock = block(shard.content, "TagBlock", 1)
		Theme.tag(tagBlock, tagText, 11, { Name = "Tag" })
		local titleBlock = block(shard.content, "TitleBlock", 2)
		Theme.label(titleBlock, titleText, titleSize, { Name = "Title" })
		local subBlock = block(shard.content, "SubBlock", 3)
		Theme.label(subBlock, subText, subSize, {
			Name = "Sub",
			FontFace = FONT.Italic,
			TextTransparency = 0.1,
			TextWrapped = subWidth ~= nil,
			Size = if subWidth then UDim2.fromOffset(subWidth, 0) else UDim2.new(),
			AutomaticSize = if subWidth then Enum.AutomaticSize.Y else Enum.AutomaticSize.XY,
		})
		return shard,
			{
				Card = shard.group,
				Countdown = nil,
				Tag = tagBlock,
				Title = titleBlock,
				Sub = subBlock,
			}
	end
	local lobby, lobbyParts = card(
		"LobbyCard",
		L.LobbyCard,
		"shard-card-silver",
		"glow-card-silver",
		"silver",
		58,
		32,
		HudCopy.WaitingTag,
		HudCopy.WaitingTitle,
		48,
		HudCopy.WaitingSub,
		17,
		nil
	)
	local ready, readyParts = card(
		"ReadyCard",
		L.ReadyCard,
		"shard-card-red",
		"glow-card-red",
		"red",
		50,
		48,
		HudCopy.ReadyTag,
		HudCopy.ReadyTitle,
		58,
		HudCopy.ReadySub,
		16,
		400
	)
	local countdown = Shard.new(
		root,
		"Countdown",
		L.Countdown,
		"shard-count-violet",
		{ glowKey = "glow-count-violet", gem = "violet" }
	)
	countdown.root.Visible = false
	table.insert(breathers, countdown)
	local countNumber = Theme.label(countdown.content, "", 140, {
		Name = "Number",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	make("UIScale", {}, countNumber)
	readyParts.Countdown = countdown.group

	----- Question: problem shard
	local problem =
		Shard.new(root, "Problem", L.Problem, "shard-problem-green", { glowKey = "glow-problem-green", gem = "green" })
	problem.root.Visible = false
	table.insert(breathers, problem)
	local problemTagBlock = block(problem.content, "TagBlock")
	problemTagBlock.Position = UDim2.fromOffset(52, 38)
	local problemTag = Theme.tag(problemTagBlock, "", 11, { Name = "Tag" })
	local problemTextBlock = block(problem.content, "TextBlock")
	problemTextBlock.Position = UDim2.fromOffset(52, 64)
	local problemRow = list(problemTextBlock, Enum.FillDirection.Horizontal, 22, nil, Enum.VerticalAlignment.Center)
	local problemLead = Theme.label(problemTextBlock, "", 88, { Name = "Lead", LayoutOrder = 1 })
	local problemTail = Theme.label(problemTextBlock, "", 88, {
		Name = "Tail",
		LayoutOrder = 2,
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	make("UIScale", {}, problemTail)
	local TAIL_DIM = C.Ink:Lerp(C.Ground, 0.45)

	----- Seconds column and timer bar
	local secondsCol = make("Frame", {
		Name = "Seconds",
		Position = UDim2.fromOffset(L.Seconds.x, L.Seconds.y),
		Size = UDim2.fromOffset(L.Seconds.w, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
	}, root) :: Frame
	list(secondsCol, Enum.FillDirection.Vertical, 4, Enum.HorizontalAlignment.Center)
	local secondsNumber = Theme.label(secondsCol, "", 100, {
		Name = "Number",
		LayoutOrder = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	make("UIScale", {}, secondsNumber)
	local secondsTag = Theme.tag(secondsCol, HudCopy.SecondsLabel, 10, { Name = "Tag", LayoutOrder = 2 })
	outlineTag(secondsTag)

	local bar = make("Frame", {
		Name = "TimerBar",
		Position = UDim2.fromOffset(L.TimerBar.x, L.TimerBar.y),
		Size = UDim2.fromOffset(L.TimerBar.w, L.TimerBar.h),
		Rotation = L.TimerBar.rot,
		BackgroundColor3 = C.Ink,
		BackgroundTransparency = 0.88,
		BorderSizePixel = 0,
		Visible = false,
	}, root) :: Frame
	local barClip = make("Frame", {
		Name = "Clip",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
	}, bar) :: Frame
	local barFill = make("Frame", {
		Name = "Fill",
		Size = UDim2.fromOffset(L.TimerBar.w, L.TimerBar.h),
		BackgroundColor3 = C.Ink,
		BorderSizePixel = 0,
	}, barClip) :: Frame

	----- Answer row
	local inputGroup = make("CanvasGroup", {
		Name = "InputRow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(L.InputRow.x + L.InputRow.w / 2, L.InputRow.y + L.InputRow.h / 2),
		Size = UDim2.fromOffset(L.InputRow.w, L.InputRow.h),
		Rotation = L.InputRow.rot,
		BackgroundTransparency = 1,
		Visible = false,
	}, root) :: CanvasGroup
	make("UIScale", {}, inputGroup)
	local inputImage = make("ImageLabel", {
		Name = "Shard",
		Size = UDim2.fromOffset(260, 58),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
	}, inputGroup) :: ImageLabel
	Theme.setImage(inputImage, "shard-input", "silver")
	local input = make("TextBox", {
		Name = "AnswerInput",
		Size = UDim2.fromOffset(260, 58),
		BackgroundTransparency = 1,
		FontFace = FONT.Body,
		TextColor3 = C.Ink,
		TextSize = Theme.PlaceholderSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = HudCopy.InputPlaceholder,
		PlaceholderColor3 = C.Ink:Lerp(C.Ground, 0.6),
		Text = "",
		ClearTextOnFocus = false,
		TextEditable = true,
		ZIndex = 2,
	}, inputGroup) :: TextBox
	pad(input, 22, 0, 22, 0)
	input:GetPropertyChangedSignal("Text"):Connect(function()
		input.TextSize = if input.Text == "" then Theme.PlaceholderSize else Theme.InputSize
	end)

	local submitWrap = make("Frame", {
		Name = "SubmitWrap",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(260 + 12 + 75, 29),
		Size = UDim2.fromOffset(150, 58),
		BackgroundTransparency = 1,
	}, inputGroup) :: Frame
	make("UIScale", {}, submitWrap)
	local submitImage = make("ImageLabel", {
		Name = "Shard",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
	}, submitWrap) :: ImageLabel
	Theme.setImage(submitImage, "shard-button", "silver")
	local flatButton = submitImage.Image == ""
	if flatButton then
		submitImage.BackgroundColor3 = C.Ink -- the ink text needs a light panel even while the art is not uploaded
	end
	local submit = make("TextButton", {
		Name = "Submit",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = FONT.Body,
		Text = HudCopy.Submit,
		TextSize = 18,
		TextColor3 = C.ButtonInk,
		AutoButtonColor = false,
		ZIndex = 2,
	}, submitWrap) :: TextButton
	local submitPress = make("UIScale", { Name = "Press" }, submit) :: UIScale
	local function tint(color: Color3)
		submitImage.ImageColor3 = color
		if flatButton then
			submitImage.BackgroundColor3 = color
		end
	end
	submit.MouseEnter:Connect(function()
		tint(C.ButtonHover)
	end)
	submit.MouseLeave:Connect(function()
		tint(C.Ink)
		submitPress.Scale = 1
	end)
	submit.MouseButton1Down:Connect(function()
		submitPress.Scale = 0.95
	end)
	submit.MouseButton1Up:Connect(function()
		submitPress.Scale = 1
	end)

	----- Feedback toast
	local toast = Shard.new(root, "Toast", L.Feedback, "shard-toast-silver", {
		glowKey = "glow-toast-silver",
		gem = "silver",
		autoWidth = { textSize = 20, padX = 30 },
	})
	toast.root.Visible = false
	local toastRow =
		make("Frame", { Name = "Row", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, toast.content)
	list(toastRow, Enum.FillDirection.Horizontal, 10, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
	local toastText = Theme.label(toastRow, "", 19, { Name = "Text", LayoutOrder = 1 })
	local toastPoints = Theme.label(toastRow, "", 22, { Name = "Points", LayoutOrder = 2 })
	local toastSparks: { GuiObject } = {}
	for index, size in
		{ Vector2.new(10, 14), Vector2.new(8, 12), Vector2.new(10, 16), Vector2.new(7, 10), Vector2.new(8, 12) }
	do
		local spark = diamond(toast.content, `Spark{index}`, 44, 23, size.X, size.Y)
		spark.BackgroundTransparency = 1
		spark.ZIndex = 5
		toastSparks[index] = spark
	end

	----- Reveal: solvers row
	local solverRow = make("Frame", {
		Name = "Solvers",
		Position = UDim2.fromOffset(L.Solvers.x, L.Solvers.y),
		Size = UDim2.fromOffset(L.Solvers.w, L.Solvers.h),
		BackgroundTransparency = 1,
		Visible = false,
	}, root) :: Frame
	list(solverRow, Enum.FillDirection.Horizontal, 8, nil, Enum.VerticalAlignment.Center)
	local solvedByBlock = block(solverRow, "SolvedBy", 1)
	outlineTag(Theme.tag(solvedByBlock, HudCopy.SolvedBy, 10, { Name = "Tag" }))
	local chips: { { shard: Shard.Shard, name: TextLabel, points: TextLabel } } = {}
	for index = 1, HudConfig.MaxSolverNames do
		local chip = Shard.new(
			solverRow,
			`Chip{index}`,
			{ x = 0, y = 0, w = 0, h = 34, rot = 0 },
			"shard-chip-violet",
			{
				gem = "violet",
				autoWidth = { textSize = 14, padX = 18, maxWidth = 180 },
			}
		)
		chip.root.LayoutOrder = 1 + index
		chip.root.Visible = false
		local row =
			make("Frame", { Name = "Row", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, chip.content)
		list(row, Enum.FillDirection.Horizontal, 8, Enum.HorizontalAlignment.Center, Enum.VerticalAlignment.Center)
		pad(row, 18, 0, 18, 0)
		local name = Theme.label(row, "", 14, {
			Name = "Name",
			LayoutOrder = 1,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		make("UISizeConstraint", { MaxSize = Vector2.new(100, math.huge) }, name)
		local points = Theme.label(row, "", 14, { Name = "Points", LayoutOrder = 2 })
		chips[index] = { shard = chip, name = name, points = points }
	end
	local moreBlock = block(solverRow, "More", 10)
	local moreText =
		Theme.label(moreBlock, "", 13, { Name = "Text", TextColor3 = C.InkDim, TextStrokeTransparency = 1 })
	local nobodyBlock = block(solverRow, "Nobody", 11)
	Theme.label(nobodyBlock, HudCopy.Nobody, 17, { Name = "Text", TextColor3 = C.InkDim, TextStrokeTransparency = 1 })

	----- Results: podium
	type Pod = { shard: Shard.Shard, rank: TextLabel, tag: TextLabel?, name: TextLabel, points: TextLabel }
	local function pod(
		name: string,
		layout: Theme.Box,
		imageKey: string,
		glowKey: string,
		gem: Theme.Gem,
		numeral: number,
		nameSize: number,
		pointsSize: number,
		padLeft: number,
		padRight: number,
		gap: number,
		withTag: boolean,
		maxName: number
	): Pod
		local shard = Shard.new(root, name, layout, imageKey, { glowKey = glowKey, gem = gem })
		shard.root.Visible = false
		local row =
			make("Frame", { Name = "Row", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 }, shard.content)
		list(row, Enum.FillDirection.Horizontal, gap, nil, Enum.VerticalAlignment.Center)
		pad(row, padLeft, 0, padRight, 0)
		local rank = Theme.label(row, "", numeral, { Name = "Rank", LayoutOrder = 1 })
		local column = make("Frame", {
			Name = "Info",
			Size = UDim2.new(),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 2,
		}, row)
		list(column, Enum.FillDirection.Vertical, if withTag then 5 else 3)
		local tag: TextLabel? = nil
		if withTag then
			tag = Theme.tag(column, "", 9, {
				Name = "Tag",
				LayoutOrder = 1,
				BackgroundColor3 = C.Ink,
				TextColor3 = C.ButtonInk,
			})
		end
		local label = Theme.label(column, "", nameSize, {
			Name = "Name",
			LayoutOrder = 2,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		make("UISizeConstraint", { MaxSize = Vector2.new(maxName, math.huge) }, label)
		local points = Theme.tag(column, "", pointsSize, { Name = "Points", LayoutOrder = 3 })
		return { shard = shard, rank = rank, tag = tag, name = label, points = points }
	end
	local pods: { Pod } = {
		pod("Pod1", L.Pod1, "shard-pod1-red", "glow-pod1-red", "red", 76, 23, 13, 34, 44, 16, true, 230),
		pod("Pod2", L.Pod2, "shard-pod2-violet", "glow-pod2-violet", "violet", 56, 19, 12, 30, 44, 14, false, 240),
		pod("Pod3", L.Pod3, "shard-pod3-blue", "glow-pod3-blue", "blue", 46, 17, 11, 30, 54, 14, false, 200),
	}
	table.insert(breathers, pods[1].shard)

	----- Results: list rows 4..8, then a pinned row for the local player and "+N MORE"
	local listFrame = make("Frame", {
		Name = "List",
		Position = UDim2.fromOffset(L.List.x, L.List.y),
		Size = UDim2.fromOffset(L.List.w, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Visible = false,
	}, root) :: Frame
	list(listFrame, Enum.FillDirection.Vertical, 5)
	type Row = { wrap: Frame, shard: Shard.Shard, rank: TextLabel, name: TextLabel, points: TextLabel }
	local function row(order: number, slot: number): Row
		local offset = Theme.RowOffsets[math.min(slot, #Theme.RowOffsets)] or 0 -- the pinned row takes the last
		local rowTop = L.List.y + (slot - 1) * (L.List.h + 5)
		-- Rows that reach the touch jump area stop short of it and borrow room on the left, where the podium
		-- is not (the pinned row sits below the second podium shard, so it can borrow more).
		local narrowed = rowTop + L.List.h > Theme.JumpZone.top
		local right = if narrowed then Theme.JumpZone.left else L.List.x + L.List.w
		local borrow = if not narrowed then 0 elseif rowTop > Theme.PodiumBottom then 70 else 24
		local width = right - L.List.x - offset + borrow
		local wrap = make("Frame", {
			Name = `Row{order}`,
			Size = UDim2.new(1, 0, 0, L.List.h),
			BackgroundTransparency = 1,
			LayoutOrder = order,
			Visible = false,
		}, listFrame) :: Frame
		local shard = Shard.new(
			wrap,
			"Shard",
			{ x = offset - borrow, y = 0, w = width, h = L.List.h, rot = 0 },
			"shard-row-indigo",
			{
				gem = "violet",
			}
		)
		local rank = Theme.label(shard.content, "", 16, {
			Name = "Rank",
			Position = UDim2.fromOffset(16, L.List.h / 2),
			AnchorPoint = Vector2.new(0, 0.5),
			TextTransparency = 0.3,
		})
		local points = Theme.label(shard.content, "", 15, {
			Name = "Points",
			Position = UDim2.new(1, -22, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
		})
		local name = Theme.label(shard.content, "", 15, {
			Name = "Name",
			Position = UDim2.fromOffset(54, L.List.h / 2),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.new(1, -(54 + 22 + 58), 0, 20),
			AutomaticSize = Enum.AutomaticSize.None,
			TextTruncate = Enum.TextTruncate.AtEnd,
		})
		return { wrap = wrap, shard = shard, rank = rank, name = name, points = points }
	end
	local rows: { Row } = {}
	for slot = 1, StandingsConfig.ListRows do
		rows[slot] = row(slot, slot)
	end
	local gap = make("Frame", {
		Name = "Gap",
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundTransparency = 1,
		LayoutOrder = StandingsConfig.ListRows + 1,
		Visible = false,
	}, listFrame) :: Frame
	Theme.label(gap, HudCopy.Gap, 13, {
		Name = "Dots",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		TextColor3 = C.InkDim,
		TextStrokeTransparency = 1,
		TextXAlignment = Enum.TextXAlignment.Center,
	})
	local pinned = row(StandingsConfig.ListRows + 2, StandingsConfig.ListRows + 2)
	local moreWrap = make("Frame", {
		Name = "More",
		Size = UDim2.new(1, 0, 0, 20),
		BackgroundTransparency = 1,
		LayoutOrder = StandingsConfig.ListRows + 3,
		Visible = false,
	}, listFrame) :: Frame
	local listMore = Theme.label(moreWrap, "", 12, {
		Name = "Text",
		Position = UDim2.fromOffset(16, 6),
		TextColor3 = C.InkDim,
		TextStrokeTransparency = 1,
	})

	----- Results: message card (empty or unavailable)
	local message = Shard.new(
		root,
		"MessageCard",
		L.MessageCard,
		"shard-card-silver",
		{ glowKey = "glow-card-silver", gem = "silver" }
	)
	message.root.Visible = false
	pad(message.content, 60, 0, 0, 0)
	list(message.content, Enum.FillDirection.Vertical, 6, nil, Enum.VerticalAlignment.Center)
	outlineTag(Theme.tag(message.content, HudCopy.FinalStandings, 10, { Name = "Tag", LayoutOrder = 1 }))
	local messageText = Theme.label(message.content, "", 30, { Name = "Text", LayoutOrder = 2 })

	----- Sparkles (always on)
	local sparks: { GuiObject } = {}
	for index, spark in
		{
			{ 640, 234, 10, 22 },
			{ 664, 262, 6, 12 },
			{ 470, 40, 8, 16 },
			{ 46, 240, 6, 12 },
		}
	do
		sparks[index] =
			diamond(root, `Spark{index}`, spark[1] + spark[3] / 2, spark[2] + spark[4] / 2, spark[3], spark[4])
	end

	gui.Parent = parent
	fit()

	------------------------------------------------------------------------------------------------------------
	-- Setters
	------------------------------------------------------------------------------------------------------------
	local view = {} :: any
	view.gui = gui
	view.input = input
	view.submitButton = submit
	view.scoreGroup = score.group
	view.ambient = { sparks = sparks, edges = edges }

	function view.setTop(model: HudRules.TopModel, alert: boolean)
		topLabel.Text = model.label
		local states = model.pips
		pipRow.Visible = states ~= nil
		if states then
			for index, pip in pips do
				local state = states[index]
				pip.BackgroundColor3 = C.Ink
				if state == "done" then
					pip.BackgroundTransparency = 0
				elseif state == "current" then
					pip.BackgroundColor3 = if alert then C.Alert else C.Ink
					pip.BackgroundTransparency = if alert then 0 else 0.25
				else
					pip.BackgroundTransparency = 0.82
				end
			end
		end
	end

	function view.setScore(tag: string, value: string)
		scoreTag.Text = tag
		scoreValue.Text = value
	end

	function view.setIntermission(mode: string)
		lobby.root.Visible = mode == "waiting"
		ready.root.Visible = mode == "ready"
		countdown.root.Visible = mode == "ready"
	end

	function view.setCountdown(text: string)
		countNumber.Text = text
	end

	function view.setProblem(model: HudRules.ProblemModel?, gem: Theme.Gem, revealed: boolean)
		problem.root.Visible = model ~= nil
		if model == nil then
			return
		end
		if problem.gem ~= gem then
			problem.setImages(`shard-problem-{gem}`, `glow-problem-{gem}`, gem)
		end
		problemTag.Text = model.tag
		problemLead.Text, problemLead.TextSize = model.lead, model.size
		problemTail.Text, problemTail.TextSize = model.tail, model.size
		problemTail.TextColor3 = if revealed then C.Ink else TAIL_DIM
		problemRow.Padding = UDim.new(0, model.gap)
	end

	function view.setTimer(
		fraction: number,
		label: string,
		visible: boolean,
		warning: boolean,
		tag: string,
		dimmed: boolean
	)
		secondsCol.Visible = visible
		bar.Visible = visible
		secondsNumber.Text = label
		secondsTag.Text = tag
		local color = if warning then C.Alert elseif dimmed then C.InkDim else C.Ink
		secondsNumber.TextColor3 = color
		barFill.BackgroundColor3 = if dimmed then C.InkDim else color
		barFill.Size = UDim2.fromOffset(math.floor(L.TimerBar.w * fraction + 0.5), L.TimerBar.h)
	end

	function view.setInputVisible(visible: boolean)
		inputGroup.Visible = visible
	end

	function view.setInputLocked(locked: boolean)
		input.TextEditable = not locked
		input.TextTransparency = if locked then 0.5 else 0
		inputImage.ImageTransparency = if locked then 0.5 else 0
	end

	function view.setSubmitEnabled(enabled: boolean)
		submit.Active = enabled
		submit.TextTransparency = if enabled then 0 else 0.55
		submitImage.ImageTransparency = if enabled then 0 else 0.55
		if flatButton then
			submitImage.BackgroundTransparency = if enabled then 0.05 else 0.6
		end
	end

	function view.setInputText(text: string)
		input.Text = text
	end

	function view.setToast(model: HudRules.Toast?, reveal: boolean)
		toast.root.Visible = model ~= nil
		if model == nil then
			return
		end
		local gem: Theme.Gem = Theme.FeedbackGem[model.kind] or "silver"
		toast.setImages(`shard-toast-{gem}`, `glow-toast-{gem}`, gem)
		toast.root.Position = UDim2.fromOffset(L.Feedback.x, if reveal then Theme.FeedbackRevealY else L.Feedback.y)
		toastText.Text, toastPoints.Text = model.text, model.points
		toast.setSizerText(if model.points ~= "" then `{model.text} {model.points}` else model.text)
	end

	function view.setSolvers(model: HudRules.SolversModel?)
		solverRow.Visible = model ~= nil
		if model == nil then
			return
		end
		solvedByBlock.Visible = #model.chips > 0
		for index, chip in chips do
			local entry = model.chips[index]
			chip.shard.root.Visible = entry ~= nil
			if entry then
				local gem: Theme.Gem = if entry.isYou then "green" else "violet"
				chip.shard.setImages(`shard-chip-{gem}`, nil, gem)
				chip.name.Text, chip.points.Text = entry.name, entry.points
				chip.shard.setSizerText(`{entry.name} {entry.points}`)
			end
		end
		moreBlock.Visible = model.more ~= ""
		moreText.Text = model.more
		nobodyBlock.Visible = model.nobody
	end

	local function setPod(slot: number, entry: StandingsRules.Row?, topTag: string)
		local p = pods[slot]
		local dim = if entry == nil then 0.75 else 0
		p.rank.Text = if entry then tostring(entry.rank) else ""
		p.name.Text = if entry then string.upper(entry.name) else "—"
		p.points.Text = StandingsRules.pointsLabel(if entry then entry.points else 0)
		if p.tag then
			p.tag.Text = topTag
			p.tag.Visible = entry ~= nil
		end
		for _, label in { p.rank, p.name, p.points } do
			label.TextTransparency = dim
		end
		p.shard.image.ImageTransparency = dim
		if p.shard.glow then
			p.shard.glow.Visible = entry ~= nil
		end
	end

	local function setRow(r: Row, entry: StandingsRules.Row?)
		r.wrap.Visible = entry ~= nil
		if entry == nil then
			return
		end
		local gem: Theme.Gem = if entry.isYou then "green" else "violet"
		r.shard.setImages(if entry.isYou then "shard-row-green" else "shard-row-indigo", nil, gem)
		r.rank.Text = tostring(entry.rank)
		r.name.Text = string.upper(entry.name)
		r.points.Text = StandingsRules.formatNumber(entry.points)
	end

	function view.setResults(model: StandingsRules.Model?, text: string?)
		local shownMessage = text
		if shownMessage == nil and model ~= nil then
			shownMessage = StandingsRules.emptyMessage(model)
		end
		message.root.Visible = shownMessage ~= nil
		messageText.Text = shownMessage or ""
		local board = if shownMessage == nil then model else nil
		listFrame.Visible = board ~= nil
		for slot, p in pods do
			p.shard.root.Visible = board ~= nil
			if board then
				setPod(slot, board.podium[slot], StandingsRules.topTag(board))
			end
		end
		if board == nil then
			return
		end
		for slot, r in rows do
			setRow(r, board.others[slot])
		end
		gap.Visible = board.you ~= nil
		setRow(pinned, board.you)
		local moreLabel = StandingsRules.moreLabel(board.hiddenCount)
		moreWrap.Visible = moreLabel ~= ""
		listMore.Text = moreLabel
	end

	------------------------------------------------------------------------------------------------------------
	-- Fx parts
	------------------------------------------------------------------------------------------------------------
	function view.intermissionParts(mode: string): Fx.IntermissionParts
		return if mode == "waiting" then lobbyParts else readyParts
	end

	view.questionParts = {
		Problem = problem.group,
		Tag = problemTagBlock,
		ProblemText = problemTextBlock,
		Seconds = secondsNumber,
		TimerFill = barClip,
		InputRow = inputGroup,
		Submit = submitWrap,
	} :: Fx.QuestionParts

	function view.revealParts(): Fx.RevealParts
		local shown: { GuiObject } = {}
		if solvedByBlock.Visible then
			table.insert(shown, solvedByBlock)
		end
		for _, chip in chips do
			if chip.shard.root.Visible then
				table.insert(shown, chip.shard.group)
			end
		end
		if moreBlock.Visible then
			table.insert(shown, moreBlock)
		end
		if nobodyBlock.Visible then
			table.insert(shown, nobodyBlock)
		end
		return { Problem = problem.group, ProblemFlash = problem.flash, Answer = problemTail, Chips = shown }
	end

	view.toastParts = {
		Toast = toast.group,
		ToastFlash = toast.flash,
		Sparks = toastSparks,
		InputRow = inputGroup,
	} :: Fx.ToastParts

	function view.resultsParts(): Fx.ResultsParts
		local shown: { GuiObject } = {}
		for _, r in rows do
			if r.wrap.Visible then
				table.insert(shown, r.shard.group)
			end
		end
		if pinned.wrap.Visible then
			table.insert(shown, pinned.shard.group)
		end
		return {
			Pod1 = pods[1].shard.group,
			Pod2 = pods[2].shard.group,
			Pod3 = pods[3].shard.group,
			Pod1Flash = pods[1].shard.flash,
			Rows = shown,
		}
	end

	view.tickParts = {
		Seconds = secondsNumber,
		Problem = problem.group,
		CountNumber = countNumber,
	} :: Fx.TickParts

	function view.visibleGlows(): { GuiObject }
		local glows: { GuiObject } = {}
		for _, shard in breathers do
			if shard.glow and shard.root.Visible then
				table.insert(glows, shard.glow)
			end
		end
		return glows
	end

	function view.destroy()
		gui:Destroy()
	end

	return view :: View
end

return View
