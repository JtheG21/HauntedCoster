--!strict
-- Demo-local skin. Existing game Theme remains unchanged.
local Base = require(script.Parent.Theme)
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Skin = {}
local motionEnabled = true
local activations: { [TextButton]: () -> () } = {}
local scales: { [TextButton]: UIScale } = {}
local tweens: { [TextButton]: Tween } = {}
function Skin.setMotionEnabled(enabled: boolean)
	motionEnabled = enabled
	if not enabled then
		for button, scale in scales do
			if tweens[button] then
				tweens[button]:Cancel()
				tweens[button] = nil
			end
			scale.Scale = 1
		end
	end
end
function Skin.activate(button: TextButton)
	if button.Active and activations[button] then
		activations[button]()
	end
end
Skin.Colors = {
	panel = Color3.fromRGB(90, 43, 20),
	panel2 = Color3.fromRGB(42, 22, 30),
	stroke = Color3.fromRGB(25, 9, 20),
	text = Color3.fromRGB(255, 244, 216),
	dim = Color3.fromRGB(231, 199, 158),
	gold = Color3.fromRGB(255, 191, 70),
	good = Color3.fromRGB(181, 237, 106),
	bad = Color3.fromRGB(255, 118, 96),
	button = Color3.fromRGB(160, 65, 223),
	buttonOff = Color3.fromRGB(83, 58, 68),
}
Skin.Body = Enum.Font.GothamMedium
Skin.Bold = Enum.Font.FredokaOne
Skin.corner = Base.corner
Skin.pad = Base.pad
Skin.stroke = Base.stroke
local function corners(parent: Instance, radius: number)
	for _, child in parent:GetChildren() do
		if child:IsA("UICorner") then
			child.CornerRadius = UDim.new(0, radius)
		end
	end
end
local function gradient(parent: GuiObject, top: Color3, bottom: Color3)
	local value = Instance.new("UIGradient")
	value.Name = "SurfaceGradient"
	value.Color = ColorSequence.new(top, bottom)
	value.Rotation = 90
	value.Parent = parent
	return value
end
function Skin.frame(parent: Instance, props: { [string]: any }?): Frame
	local value = Base.frame(parent, props)
	if not props or not props.BackgroundColor3 then
		value.BackgroundColor3 = Skin.Colors.panel
	end
	value.BackgroundTransparency = 0
	return value
end
function Skin.panel(parent: Instance, props: { [string]: any }?): Frame
	local value = Skin.frame(parent, props)
	Base.corner(value, 5)
	Base.stroke(value, Skin.Colors.stroke, 2)
	local highlight = Instance.new("Frame")
	highlight.Name = "InnerRim"
	highlight.BackgroundTransparency = 1
	highlight.Position = UDim2.fromOffset(2, 2)
	highlight.Size = UDim2.new(1, -4, 1, -4)
	highlight.Parent = value
	Base.corner(highlight, 3)
	Base.stroke(highlight, Color3.fromRGB(162, 94, 46), 1)
	return value
end
function Skin.label(parent: Instance, text: string, props: { [string]: any }?): TextLabel
	local value = Base.label(parent, text, props)
	if not props or not props.TextColor3 then
		value.TextColor3 = Skin.Colors.text
	end
	value.TextStrokeColor3 = Color3.fromRGB(30, 10, 25)
	value.TextStrokeTransparency = 0.1
	return value
end
function Skin.button(parent: Instance, text: string, callback: () -> (), props: { [string]: any }?): TextButton
	local value: TextButton
	local lastActivation = -math.huge
	local function activate()
		if not value or not value.Active then
			return
		end
		local now = os.clock()
		if now - lastActivation < 0.08 then
			return
		end
		lastActivation = now
		callback()
	end
	value = Base.button(parent, text, activate, props)
	value.BackgroundColor3 = Skin.Colors.button
	value.TextColor3 = Skin.Colors.text
	value.TextStrokeColor3 = Color3.fromRGB(29, 8, 30)
	value.TextStrokeTransparency = 0.1
	value.Font = Skin.Bold
	value.TextSize = math.max(value.TextSize, 17)
	value.AutoButtonColor = false
	value.ClipsDescendants = false
	corners(value, 4)
	Base.stroke(value, Skin.Colors.stroke, 2)
	local bevel = Instance.new("Frame")
	bevel.Name = "Bevel"
	bevel.BorderSizePixel = 0
	bevel.BackgroundColor3 = Color3.fromRGB(65, 18, 72)
	bevel.Position = UDim2.new(0, 0, 1, -4)
	bevel.Size = UDim2.new(1, 0, 0, 4)
	bevel.Parent = value
	Base.corner(bevel, 3)
	local rim = Instance.new("Frame")
	rim.Name = "TopHighlight"
	rim.BackgroundColor3 = Color3.fromRGB(255, 214, 154)
	rim.BackgroundTransparency = 0.25
	rim.BorderSizePixel = 0
	rim.Position = UDim2.fromOffset(3, 2)
	rim.Size = UDim2.new(1, -6, 0, 1)
	rim.Parent = value
	local surface = gradient(value, Color3.fromRGB(255, 244, 232), Color3.fromRGB(179, 126, 163))
	local position, size = value.Position, value.Size
	value.AnchorPoint = Vector2.new(0.5, 0.5)
	value.Position = position + UDim2.new(size.X.Scale / 2, size.X.Offset / 2, size.Y.Scale / 2, size.Y.Offset / 2)
	value.Selectable = true
	activations[value] = activate
	local scale = Instance.new("UIScale")
	scale.Name = "InteractionScale"
	scale.Parent = value
	scales[value] = scale
	local selection = Instance.new("Frame")
	selection.BackgroundTransparency = 1
	selection.Size = UDim2.fromScale(1, 1)
	Base.corner(selection, 4)
	Base.stroke(selection, Color3.fromRGB(255, 229, 148), 3)
	value.SelectionImageObject = selection
	local hovered, selected, pressed = false, false, false
	local function feedback()
		local target = if not value.Active or not motionEnabled
			then 1
			elseif pressed then 0.96
			elseif hovered or selected then 1.025
			else 1
		if tweens[value] then
			tweens[value]:Cancel()
		end
		if motionEnabled then
			local tween = TweenService:Create(
				scale,
				TweenInfo.new(0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Scale = target }
			)
			tweens[value] = tween
			tween:Play()
		else
			scale.Scale = 1
		end
		bevel.Visible = not pressed or not value.Active
		surface.Rotation = if (hovered or selected) and value.Active then 78 else 90
	end
	value.MouseEnter:Connect(function()
		hovered = true
		feedback()
	end)
	value.MouseLeave:Connect(function()
		hovered = false
		pressed = false
		feedback()
	end)
	value.SelectionGained:Connect(function()
		selected = true
		feedback()
	end)
	value.SelectionLost:Connect(function()
		selected = false
		pressed = false
		feedback()
	end)
	value.InputBegan:Connect(function(input)
		if
			value.Active
			and (
				input.UserInputType == Enum.UserInputType.MouseButton1
				or input.UserInputType == Enum.UserInputType.Touch
				or input.KeyCode == Enum.KeyCode.ButtonA
			)
		then
			pressed = true
			feedback()
		end
	end)
	local release = UserInputService.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
			or input.KeyCode == Enum.KeyCode.ButtonA
		then
			if pressed then
				pressed = false
				feedback()
			end
		end
	end)
	value:GetPropertyChangedSignal("Active"):Connect(function()
		pressed = false
		feedback()
	end)
	value.Destroying:Connect(function()
		release:Disconnect()
		if tweens[value] then
			tweens[value]:Cancel()
			tweens[value] = nil
		end
		scales[value] = nil
		activations[value] = nil
		selection:Destroy()
	end)
	return value
end
function Skin.setRole(button: TextButton, role: string)
	local accent = if role == "lime"
		then Color3.fromRGB(255, 172, 55)
		elseif role == "wood" then Color3.fromRGB(174, 105, 57)
		else Skin.Colors.button
	button:SetAttribute("Accent", accent)
	button.BackgroundColor3 = accent
	if role == "wood" then
		button.TextColor3 = Skin.Colors.text
		button.TextStrokeTransparency = 0.1
	end
end
function Skin.setEnabled(button: TextButton, enabled: boolean)
	button.Active = enabled
	button.Selectable = enabled
	button.AutoButtonColor = false
	local accent = button:GetAttribute("Accent")
	button.BackgroundColor3 = if not enabled
		then Skin.Colors.buttonOff
		elseif typeof(accent) == "Color3" then accent
		else Skin.Colors.button
	button.TextTransparency = if enabled then 0 else 0.32
	button.TextStrokeTransparency = 0.1
end
return Skin
