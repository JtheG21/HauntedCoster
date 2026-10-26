--!strict
-- Builds the MathShowHud ScreenGui and exposes typed setters. No remote or round logic lives here.
-- Layout follows the design spec (phone landscape 844x390): scale positions, capped text and input sizes.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudConfig = require(Shared:WaitForChild("HudConfig"))
local StandingsConfig = require(Shared:WaitForChild("StandingsConfig"))
local StandingsRules = require(Shared:WaitForChild("StandingsRules"))

local Theme = require(script.Parent.Theme)

export type FeedbackTone = "good" | "bad" | "info"

export type View = {
	gui: ScreenGui,
	input: TextBox,
	submitButton: TextButton,
	setQuestion: (text: string, visible: boolean) -> (),
	setTimer: (fraction: number, label: string, visible: boolean, warning: boolean) -> (),
	setInputVisible: (visible: boolean) -> (),
	setInputEnabled: (enabled: boolean) -> (),
	setInputText: (text: string) -> (),
	setFeedback: (text: string, tone: FeedbackTone) -> (),
	clearFeedback: () -> (),
	-- model nil and message nil hides the panel; message alone shows just the title and that line.
	setResults: (model: StandingsRules.Model?, message: string?) -> (),
	feedbackLabel: TextLabel,
	destroy: () -> (),
}

local C = Theme.Colors
local make = Theme.make

local Strings = HudConfig.Strings
local LIST_ROW_HEIGHT = 22
local MIN_TEXT = 12
-- Podium columns by rank slot: 1st centre and tallest, 2nd left, 3rd right.
local PODIUM_X = { 0.5, 0.2, 0.8 }
local PODIUM_HEIGHT = { 1, 0.78, 0.62 }

local View = {}

local function newLabel(parent: Instance, name: string, font: Enum.Font, maxSize: number): TextLabel
	local l = make("TextLabel", {
		Name = name,
		BackgroundTransparency = 1,
		Font = font,
		TextColor3 = C.text,
		TextScaled = true,
		Text = "",
	}, parent) :: TextLabel
	Theme.textLimit(l, maxSize, MIN_TEXT)
	return l
end

local function rowText(row: StandingsRules.Row): string
	return `{row.rank}. {row.name} - {Strings.PointsFormat:format(row.points)}`
end

function View.build(parent: Instance): View
	local gui = make("ScreenGui", {
		Name = "MathShowHud",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = false,
	}, nil) :: ScreenGui

	local timerTrack = make("Frame", {
		Name = "Timer",
		Position = UDim2.fromScale(0.05, 0.04),
		Size = UDim2.new(0.9, 0, 0, 12),
		BackgroundColor3 = C.field,
		BorderSizePixel = 0,
		Visible = false,
	}, gui) :: Frame
	Theme.corner(timerTrack, 6)
	local timerFill = make("Frame", {
		Name = "Fill",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = C.accent,
		BorderSizePixel = 0,
	}, timerTrack) :: Frame
	Theme.corner(timerFill, 6)
	local timerLabel = make("TextLabel", {
		Name = "TimerSeconds",
		Position = UDim2.new(0.5, 0, 0.04, 16),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 28),
		BackgroundTransparency = 1,
		Font = Theme.Body,
		TextColor3 = C.text,
		TextScaled = true,
		Text = "",
		Visible = false,
	}, gui) :: TextLabel
	Theme.textLimit(timerLabel, 24)
	Theme.outline(timerLabel)

	local question = make("TextLabel", {
		Name = "Question",
		Position = UDim2.fromScale(0.5, 0.12),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.9, 0, 0, 96),
		BackgroundTransparency = 1,
		Font = Theme.Bold,
		TextColor3 = C.white,
		TextScaled = true,
		Text = "",
	}, gui) :: TextLabel
	Theme.textLimit(question, 56)
	Theme.outline(question)

	local row = make("Frame", {
		Name = "AnswerRow",
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.7, 0, 0, 72),
		BackgroundTransparency = 1,
		Visible = false,
	}, gui) :: Frame
	Theme.sizeLimit(row, Vector2.new(560, 72))
	local input = make("TextBox", {
		Name = "AnswerInput",
		Size = UDim2.new(1, -136, 1, 0),
		BackgroundColor3 = C.field,
		Font = Theme.Body,
		TextColor3 = C.text,
		PlaceholderColor3 = C.buttonOff,
		PlaceholderText = "",
		Text = "",
		TextScaled = true,
		ClearTextOnFocus = false,
		TextEditable = true,
	}, row) :: TextBox
	Theme.corner(input, 10)
	Theme.textLimit(input, 36)
	local submit = make("TextButton", {
		Name = "Submit",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.new(0, 128, 1, 0),
		BackgroundColor3 = C.button,
		Font = Theme.Bold,
		TextColor3 = C.white,
		TextScaled = true,
		Text = "",
		AutoButtonColor = true,
	}, row) :: TextButton
	Theme.corner(submit, 10)
	Theme.textLimit(submit, 28)

	local feedback = make("TextLabel", {
		Name = "Feedback",
		Position = UDim2.fromScale(0.5, 0.7),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.8, 0, 0, 44),
		BackgroundTransparency = 1,
		Font = Theme.Bold,
		TextColor3 = C.info,
		TextScaled = true,
		Text = "",
		Visible = false,
	}, gui) :: TextLabel
	Theme.textLimit(feedback, 28)
	Theme.outline(feedback)

	-- Results panel: every label is created here; setResults only changes text and visibility.
	local panel = make("Frame", {
		Name = "Results",
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.94),
		BackgroundColor3 = C.panel,
		BackgroundTransparency = 0.1,
		BorderSizePixel = 0,
		Visible = false,
	}, gui) :: Frame
	Theme.corner(panel, 12)
	Theme.sizeLimit(panel, Vector2.new(640, 360))
	local resultsTitle = newLabel(panel, "Title", Theme.Bold, 28)
	resultsTitle.Position = UDim2.fromScale(0.5, 0.01)
	resultsTitle.AnchorPoint = Vector2.new(0.5, 0)
	resultsTitle.Size = UDim2.new(0.9, 0, 0, 30)
	resultsTitle.TextColor3 = C.white
	resultsTitle.Text = Strings.ResultsTitle
	local resultsMessage = newLabel(panel, "Message", Theme.Body, 24)
	resultsMessage.Position = UDim2.fromScale(0.5, 0.5)
	resultsMessage.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsMessage.Size = UDim2.new(0.8, 0, 0, 36)
	resultsMessage.Visible = false

	local podiumArea = make("Frame", {
		Name = "Podium",
		Position = UDim2.new(0.05, 0, 0, 38),
		Size = UDim2.fromScale(0.9, 0.36),
		BackgroundTransparency = 1,
	}, panel) :: Frame
	local columns: { { frame: Frame, rank: TextLabel, name: TextLabel, points: TextLabel } } = {}
	for slot = 1, StandingsConfig.PodiumSize do
		local column = make("Frame", {
			Name = `Podium{slot}`,
			Position = UDim2.fromScale(PODIUM_X[slot], 1),
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromScale(0.28, PODIUM_HEIGHT[slot]),
			BackgroundColor3 = C.field,
			BorderSizePixel = 0,
			Visible = false,
		}, podiumArea) :: Frame
		Theme.corner(column, 8)
		local rank = newLabel(column, "Rank", Theme.Bold, 22)
		rank.Size = UDim2.fromScale(1, 0.34)
		rank.TextColor3 = C.accent
		local name = newLabel(column, "Name", Theme.Body, 18)
		name.Position = UDim2.fromScale(0, 0.34)
		name.Size = UDim2.fromScale(1, 0.33)
		local points = newLabel(column, "Points", Theme.Body, 16)
		points.Position = UDim2.fromScale(0, 0.67)
		points.Size = UDim2.fromScale(1, 0.33)
		points.TextColor3 = C.good
		columns[slot] = { frame = column, rank = rank, name = name, points = points }
	end

	local listArea = make("Frame", {
		Name = "List",
		Position = UDim2.new(0.5, 0, 0.42, 38),
		AnchorPoint = Vector2.new(0.5, 0),
		Size = UDim2.new(0.8, 0, 0, LIST_ROW_HEIGHT * (StandingsConfig.ListRows + 2)),
		BackgroundTransparency = 1,
	}, panel) :: Frame
	local listLayout = Instance.new("UIListLayout")
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = listArea
	local function listLabel(name: string, order: number): TextLabel
		local l = newLabel(listArea, name, Theme.Body, 18)
		l.LayoutOrder = order
		l.Size = UDim2.new(1, 0, 0, LIST_ROW_HEIGHT)
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Visible = false
		return l
	end
	local listRows: { TextLabel } = {}
	for i = 1, StandingsConfig.ListRows do
		listRows[i] = listLabel(`Row{i}`, i)
	end
	local youRow = listLabel("You", StandingsConfig.ListRows + 1)
	youRow.TextColor3 = C.accent
	local moreRow = listLabel("More", StandingsConfig.ListRows + 2)
	moreRow.TextColor3 = C.buttonOff

	local function showPodium(model: StandingsRules.Model)
		for slot, column in columns do
			local entry = model.podium[slot]
			column.frame.Visible = entry ~= nil
			if entry then
				column.rank.Text = tostring(entry.rank)
				column.name.Text = entry.name
				column.points.Text = Strings.PointsFormat:format(entry.points)
				column.name.TextColor3 = if entry.isYou then C.accent else C.text
				column.frame.BackgroundColor3 = if entry.isYou then C.button else C.field
			end
		end
		for i, l in listRows do
			local entry = model.others[i]
			l.Visible = entry ~= nil
			if entry then
				l.Text = rowText(entry)
				l.TextColor3 = if entry.isYou then C.accent else C.text
			end
		end
		local you = model.you
		youRow.Visible = you ~= nil
		if you then
			youRow.Text = rowText(you)
		end
		moreRow.Visible = model.hiddenCount > 0
		moreRow.Text = Strings.MoreFormat:format(model.hiddenCount)
	end

	local view = {} :: any
	view.gui = gui
	view.input = input
	view.submitButton = submit
	view.feedbackLabel = feedback

	function view.setQuestion(text: string, visible: boolean)
		question.Text = text
		question.Visible = visible
	end

	function view.setTimer(fraction: number, label: string, visible: boolean, warning: boolean)
		timerTrack.Visible = visible
		timerLabel.Visible = visible
		timerFill.Size = UDim2.fromScale(fraction, 1)
		timerFill.BackgroundColor3 = if warning then C.warn else C.accent
		timerLabel.Text = label
		timerLabel.Font = if warning then Theme.Bold else Theme.Body
		timerLabel.TextColor3 = if warning then C.warn else C.text
	end

	function view.setInputVisible(visible: boolean)
		row.Visible = visible
	end

	function view.setInputEnabled(enabled: boolean)
		input.TextEditable = enabled
		submit.Active = enabled
		submit.AutoButtonColor = enabled
		submit.BackgroundColor3 = if enabled then C.button else C.buttonOff
	end

	function view.setInputText(text: string)
		input.Text = text
	end

	function view.setFeedback(text: string, tone: FeedbackTone)
		feedback.Text = text
		feedback.TextColor3 = if tone == "good" then C.good elseif tone == "bad" then C.bad else C.info
		feedback.Visible = true
	end

	function view.clearFeedback()
		feedback.Text = ""
		feedback.Visible = false
	end

	function view.setResults(model: StandingsRules.Model?, message: string?)
		local shownMessage = message
		if model ~= nil and model.empty then
			shownMessage = Strings.NoScores
		end
		panel.Visible = model ~= nil or message ~= nil
		resultsMessage.Visible = shownMessage ~= nil
		resultsMessage.Text = shownMessage or ""
		podiumArea.Visible = shownMessage == nil
		listArea.Visible = shownMessage == nil
		if model ~= nil and shownMessage == nil then
			showPodium(model)
		end
	end

	function view.destroy()
		gui:Destroy()
	end

	gui.Parent = parent
	return view :: View
end

return View
