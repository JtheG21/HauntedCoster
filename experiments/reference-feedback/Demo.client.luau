--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("FeedbackDemo")
local State = require(modules:WaitForChild("State"))
local Theme = require(modules:WaitForChild("DemoTheme"))
local FrameArt = require(modules:WaitForChild("FrameArt"))
local DemoMotion = require(modules:WaitForChild("DemoMotion"))
local gui = Instance.new("ScreenGui")
gui.Name = "ReferenceFeedbackDemo"
gui.DisplayOrder = 10
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
local backdrop = Instance.new("ScreenGui")
backdrop.Name = "FeedbackBackdrop"
backdrop.ScreenInsets = Enum.ScreenInsets.None
backdrop.ResetOnSpawn = false
backdrop.DisplayOrder = -1
local ambient = Theme.frame(backdrop, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 13, 35) })
backdrop.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
local background = Instance.new("ScrollingFrame")
background.Name = "ResponsiveCanvas"
background.Size = UDim2.fromScale(1, 1)
background.BackgroundColor3 = Color3.fromRGB(24, 13, 35)
background.BackgroundTransparency = 1
background.BorderSizePixel = 0
background.ScrollBarThickness = 6
background.ScrollingDirection = Enum.ScrollingDirection.Y
background.Parent = gui
local card = Theme.panel(
	background,
	{ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0, 24), Size = UDim2.new(0.94, 0, 0, 490) }
)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(560, 490)
limit.Parent = card
local function layout()
	local height = math.max(background.AbsoluteSize.Y, 538)
	background.CanvasSize = UDim2.fromOffset(0, height)
	card.Position = UDim2.new(0.5, 0, 0, height / 2)
end
background:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
layout()
Theme.pad(card, 24)
card.BackgroundTransparency = 1
for _, child in card:GetChildren() do
	if child:IsA("UIStroke") then
		child.Enabled = false
	end
end
local paintedFrame = FrameArt.mount(card)
local cardRim = card:FindFirstChild("InnerRim")
if cardRim and cardRim:IsA("GuiObject") then
	cardRim.Visible = false
end
local title = Theme.label(card, "RESERVE LAB", {
	Font = Theme.Bold,
	TextSize = 27,
	Position = UDim2.fromOffset(100, 20),
	Size = UDim2.new(1, -100, 0, 30),
	TextXAlignment = Enum.TextXAlignment.Center,
})
local subtitle = Theme.label(card, "Keep your lamp burning.", {
	Position = UDim2.fromOffset(100, 47),
	TextXAlignment = Enum.TextXAlignment.Center,
	TextColor3 = Theme.Colors.dim,
	TextSize = 13,
	Size = UDim2.new(1, -100, 0, 36),
})
-- Center typography against the painted ribbon, independent of card padding.
title.Parent = paintedFrame
subtitle.Parent = paintedFrame
title.AnchorPoint = Vector2.new(0.5, 0)
subtitle.AnchorPoint = Vector2.new(0.5, 0)
local function headerLayout()
	local narrow = card.AbsoluteSize.X < 450
	title.Position = UDim2.new(0.53, 0, 0, if narrow then 82 else 102)
	title.Size = UDim2.new(0.65, 0, 0, 30)
	subtitle.Position = UDim2.new(0.53, 0, 0, if narrow then 109 else 129)
	subtitle.Size = UDim2.new(0.65, 0, 0, 36)
end
card:GetPropertyChangedSignal("AbsoluteSize"):Connect(headerLayout)
headerLayout()
local phase = Theme.label(
	card,
	"NORMAL",
	{ Position = UDim2.fromOffset(0, 88), Font = Theme.Bold, TextSize = 28, Size = UDim2.new(0.65, 0, 0, 38) }
)
local amount = Theme.label(card, "100%", {
	Position = UDim2.new(0.65, 0, 0, 88),
	TextXAlignment = Enum.TextXAlignment.Right,
	Font = Theme.Bold,
	TextSize = 28,
	Size = UDim2.new(0.35, 0, 0, 38),
})
local track = Theme.frame(
	card,
	{ Position = UDim2.fromOffset(0, 140), Size = UDim2.new(1, 0, 0, 14), BackgroundColor3 = Theme.Colors.panel2 }
)
Theme.corner(track, 3)
Theme.stroke(track, Theme.Colors.stroke, 1.5)
local fill = Theme.frame(
	track,
	{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.good, BackgroundTransparency = 0 }
)
Theme.corner(fill, 2)
local lamp = Theme.panel(card, { Position = UDim2.fromOffset(0, 178), Size = UDim2.new(1, 0, 0, 64) })
local lampText = Theme.label(
	lamp,
	"LAMP READY",
	{ Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0), Font = Theme.Bold, TextSize = 18 }
)
local hint =
	Theme.label(card, "", { Position = UDim2.fromOffset(0, 246), Size = UDim2.new(1, 0, 0, 30), TextSize = 15 })
local rim = lamp:FindFirstChild("InnerRim")
local edge = if rim then rim:FindFirstChildOfClass("UIStroke") else nil
local motion = DemoMotion.mount(gui, card, paintedFrame, fill, edge, background, ambient)
local charge, running, lit = 100, false, false
local render: () -> ()
local action = Theme.button(card, "Lamp: off", function()
	if charge > 0 then
		lit = not lit
		render()
	end
end, { Position = UDim2.fromOffset(0, 282), Size = UDim2.new(0.48, 0, 0, 48) })
local run: TextButton
run = Theme.button(card, "Run drain", function()
	running = not running
	render()
end, { Position = UDim2.new(0.52, 0, 0, 282), Size = UDim2.new(0.48, 0, 0, 48) })
Theme.setRole(action, "lime")
Theme.setRole(run, "cyan")
local presets = { { label = "Normal", charge = 100 }, { label = "Low", charge = 20 }, { label = "Empty", charge = 0 } }
local navigation: { TextButton } = { action, run }
for i, preset in presets do
	local presetButton = Theme.button(card, preset.label, function()
		charge = preset.charge
		running = false
		lit = charge > 0
		render()
	end, { Position = UDim2.new((i - 1) * 0.34, 0, 0, 338), Size = UDim2.new(0.32, 0, 0, 48), TextSize = 14 })
	Theme.setRole(presetButton, "wood")
	table.insert(navigation, presetButton)
end
Theme.label(card, "Normal >25% · Low 1–25% · Depleted 0%", {
	Position = UDim2.fromOffset(0, 394),
	TextXAlignment = Enum.TextXAlignment.Center,
	Size = UDim2.new(1, 0, 0, 20),
	TextSize = 12,
	TextColor3 = Theme.Colors.dim,
})
render = function()
	local value = State.describe(charge)
	if not value.enabled then
		lit = false
		running = false
	end
	local color = if value.phase == "NORMAL"
		then Theme.Colors.good
		elseif value.phase == "LOW" then Theme.Colors.gold
		else Theme.Colors.bad
	phase.Text = value.phase
	phase.TextColor3 = color
	amount.Text = string.format("%d%%", math.ceil(value.charge))
	motion.status(value.charge, lit, color)
	fill.BackgroundColor3 = color
	hint.Text = value.hint
	lamp.BackgroundColor3 = Theme.Colors.panel2

	lampText.TextColor3 = if lit then color else Theme.Colors.dim
	lampText.Text = if not value.enabled then "LAMP UNAVAILABLE" elseif lit then "LAMP ON" else "LAMP READY"
	action.Text = if not value.enabled then "Lamp: unavailable" elseif lit then "Lamp: on" else "Lamp: off"
	Theme.setEnabled(action, value.enabled)
	run.Text = if running then "Pause drain" else "Run drain"
	Theme.setEnabled(run, value.enabled)
	gui:SetAttribute("Phase", value.phase)
	gui:SetAttribute("Charge", value.charge)
	gui:SetAttribute("LampOn", lit)
end
local stateTick = RunService.Heartbeat:Connect(function(dt)
	if running then
		charge = State.drain(charge, dt, lit)
		render()
	end
end)
local motionButton = Theme.button(background, "Motion: on", function()
	motion.toggle()
end, {
	AnchorPoint = Vector2.new(0, 0),
	Position = UDim2.new(1, -172, 0, 10),
	Size = UDim2.fromOffset(158, 44),
	TextSize = 14,
})
Theme.setRole(motionButton, "wood")
motionButton.ZIndex = 10
table.insert(navigation, motionButton)
motion.bind(navigation, function(enabled)
	motionButton.Text = if enabled then "Motion: on" else "Motion: reduced"
end)
render()
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
motion.reveal()
gui.Destroying:Connect(function()
	stateTick:Disconnect()
	FrameArt.release()
	backdrop:Destroy()
end)
