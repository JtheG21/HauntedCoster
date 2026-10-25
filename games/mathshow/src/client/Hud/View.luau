--!strict
-- Builds the MathShowHud ScreenGui and exposes typed setters. No remote or round logic lives here.
-- Layout follows the design spec (phone landscape 844x390): scale positions, capped text and input sizes.

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
	feedbackLabel: TextLabel,
	destroy: () -> (),
}

local C = Theme.Colors
local make = Theme.make

local View = {}

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

	function view.destroy()
		gui:Destroy()
	end

	gui.Parent = parent
	return view :: View
end

return View
