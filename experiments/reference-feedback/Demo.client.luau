--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local modules = game:GetService("ReplicatedStorage"):WaitForChild("FeedbackDemo")
local State = require(modules:WaitForChild("State"))
local Theme = require(modules:WaitForChild("Theme"))
local gui = Instance.new("ScreenGui")
gui.Name = "ReferenceFeedbackDemo"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
local background = Theme.frame(gui, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0 })
local card = Theme.panel(
	background,
	{ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.new(0.94, 0, 0, 490) }
)
local limit = Instance.new("UISizeConstraint")
limit.MaxSize = Vector2.new(560, 490)
limit.Parent = card
Theme.pad(card, 24)
Theme.label(card, "RESERVE / FEEDBACK LAB", { Font = Theme.Bold, TextSize = 18, Size = UDim2.new(1, 0, 0, 30) })
Theme.label(
	card,
	"Isolated reference experiment · client presentation only",
	{ Position = UDim2.fromOffset(0, 35), TextColor3 = Theme.Colors.dim, TextSize = 13, Size = UDim2.new(1, 0, 0, 36) }
)
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
Theme.corner(track, 7)
local fill = Theme.frame(
	track,
	{ Size = UDim2.fromScale(1, 1), BackgroundColor3 = Theme.Colors.good, BackgroundTransparency = 0 }
)
Theme.corner(fill, 7)
local lamp = Theme.panel(card, { Position = UDim2.fromOffset(0, 178), Size = UDim2.new(1, 0, 0, 64) })
local lampText = Theme.label(
	lamp,
	"LAMP READY",
	{ Position = UDim2.fromOffset(16, 0), Size = UDim2.new(1, -32, 1, 0), Font = Theme.Bold, TextSize = 18 }
)
local hint =
	Theme.label(card, "", { Position = UDim2.fromOffset(0, 254), Size = UDim2.new(1, 0, 0, 38), TextSize = 15 })
local charge, running, lit = 100, false, false
local render: () -> ()
local action = Theme.button(card, "Lamp: off", function()
	if charge > 0 then
		lit = not lit
		render()
	end
end, { Position = UDim2.fromOffset(0, 306), Size = UDim2.new(0.48, 0, 0, 48) })
local run: TextButton
run = Theme.button(card, "Run drain", function()
	running = not running
	render()
end, { Position = UDim2.new(0.52, 0, 0, 306), Size = UDim2.new(0.48, 0, 0, 48) })
local presets = { { label = "Normal", charge = 100 }, { label = "Low", charge = 20 }, { label = "Empty", charge = 0 } }
for i, preset in presets do
	Theme.button(card, preset.label, function()
		charge = preset.charge
		running = false
		lit = charge > 0
		render()
	end, { Position = UDim2.new((i - 1) * 0.34, 0, 0, 370), Size = UDim2.new(0.32, 0, 0, 48), TextSize = 14 })
end
Theme.label(
	card,
	"Normal >25% · Low 1–25% · Depleted 0%",
	{ Position = UDim2.fromOffset(0, 426), Size = UDim2.new(1, 0, 0, 20), TextSize = 12, TextColor3 = Theme.Colors.dim }
)
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
	fill.Size = UDim2.fromScale(value.charge / 100, 1)
	fill.BackgroundColor3 = color
	hint.Text = value.hint
	lamp.BackgroundColor3 = if lit then color else Theme.Colors.panel2
	lampText.TextColor3 = if lit then Theme.Colors.panel else Theme.Colors.text
	lampText.Text = if not value.enabled then "LAMP UNAVAILABLE" elseif lit then "LAMP ON" else "LAMP READY"
	action.Text = if not value.enabled then "Lamp: unavailable" elseif lit then "Lamp: on" else "Lamp: off"
	Theme.setEnabled(action, value.enabled)
	run.Text = if running then "Pause drain" else "Run drain"
	Theme.setEnabled(run, value.enabled)
	gui:SetAttribute("Phase", value.phase)
	gui:SetAttribute("Charge", value.charge)
	gui:SetAttribute("LampOn", lit)
end
RunService.Heartbeat:Connect(function(dt)
	if running then
		charge = State.drain(charge, dt, lit)
		render()
	end
end)
render()
gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
