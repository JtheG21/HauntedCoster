--!strict
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local StarterGui = game:GetService("StarterGui")
local Theme = require(script.Parent.DemoTheme)
local Decoration = require(script.Parent.DecorationMotion)

local Motion = {}
function Motion.mount(
	gui: ScreenGui,
	_card: Frame,
	art: ImageLabel,
	fill: Frame,
	edge: UIStroke?,
	scroll: ScrollingFrame,
	ambient: Frame
)
	local connections: { RBXScriptConnection } = {}
	local buttons: { TextButton } = {}
	local requested = true
	local enabled = not GuiService.ReducedMotionEnabled
	local alive = true
	local elapsed, accumulator = 0, 0
	local targetCharge, shownCharge = 100, 100
	local lampOn = false
	local statusColor = Theme.Colors.good
	local decorations = Decoration.mount(art, ambient)
	local onPolicy: (boolean) -> () = function(_enabled: boolean) end
	local oldNavigation, oldAuto = GuiService.GuiNavigationEnabled, GuiService.AutoSelectGuiEnabled
	local oldPlayerList = StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.PlayerList)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
	GuiService.GuiNavigationEnabled = true
	GuiService.AutoSelectGuiEnabled = true
	local function connect(signal: RBXScriptSignal, callback: (...any) -> ())
		table.insert(connections, signal:Connect(callback))
	end
	local function policy()
		enabled = requested and not GuiService.ReducedMotionEnabled
		Theme.setMotionEnabled(enabled)
		gui:SetAttribute("MotionEnabled", enabled)
		if not enabled then
			decorations.step(elapsed, false)
			fill.Size = UDim2.fromScale(targetCharge / 100, 1)
			shownCharge = targetCharge
		end
		onPolicy(enabled)
	end
	local function revealSelection()
		local selected = GuiService.SelectedObject
		if not selected or not selected:IsDescendantOf(scroll) then
			return
		end
		local top = selected.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
		local bottom = top + selected.AbsoluteSize.Y
		local target = scroll.CanvasPosition.Y
		if top < target + 12 then
			target = top - 12
		elseif bottom > target + scroll.AbsoluteSize.Y - 12 then
			target = bottom - scroll.AbsoluteSize.Y + 12
		end
		scroll.CanvasPosition =
			Vector2.new(0, math.clamp(target, 0, math.max(0, scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteSize.Y)))
	end
	local function focus(step: number)
		if #buttons == 0 then
			return
		end
		local index = table.find(buttons, GuiService.SelectedObject) or (if step > 0 then 0 else 1)
		for _ = 1, #buttons do
			index = (index - 1 + step) % #buttons + 1
			if buttons[index].Active then
				GuiService.SelectedObject = buttons[index]
				revealSelection()
				return
			end
		end
	end
	connect(UserInputService.InputBegan, function(input)
		if input.KeyCode == Enum.KeyCode.Tab and not UserInputService:GetFocusedTextBox() then
			gui:SetAttribute("NavigationInput", "Tab:Begin")
			focus(
				if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
						or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
					then -1
					else 1
			)
		end
	end)
	ContextActionService:BindActionAtPriority(
		"FeedbackKeyboardNavigation",
		function(_action: string, state: Enum.UserInputState, input: InputObject)
			if UserInputService:GetFocusedTextBox() then
				return Enum.ContextActionResult.Pass
			end
			gui:SetAttribute("NavigationInput", input.KeyCode.Name .. ":" .. state.Name)
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end
			local key = input.KeyCode
			if key == Enum.KeyCode.DPadRight or key == Enum.KeyCode.Right then
				focus(1)
			elseif key == Enum.KeyCode.DPadLeft or key == Enum.KeyCode.Left then
				focus(-1)
			elseif
				key == Enum.KeyCode.DPadDown
				or key == Enum.KeyCode.Down
				or key == Enum.KeyCode.DPadUp
				or key == Enum.KeyCode.Up
			then
				local selected = GuiService.SelectedObject
				local nextButton = if selected
					then (if key == Enum.KeyCode.DPadDown or key == Enum.KeyCode.Down
						then selected.NextSelectionDown
						else selected.NextSelectionUp)
					else nil
				if nextButton and nextButton.Active then
					GuiService.SelectedObject = nextButton
					revealSelection()
				else
					focus(1)
				end
			else
				local selected = GuiService.SelectedObject
				if selected and selected:IsA("TextButton") and table.find(buttons, selected) then
					Theme.activate(selected)
				else
					return Enum.ContextActionResult.Pass
				end
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		6000,
		Enum.KeyCode.Return,
		Enum.KeyCode.Space,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.DPadLeft,
		Enum.KeyCode.DPadRight,
		Enum.KeyCode.DPadUp,
		Enum.KeyCode.DPadDown,
		Enum.KeyCode.Left,
		Enum.KeyCode.Right,
		Enum.KeyCode.Up,
		Enum.KeyCode.Down
	)
	connect(GuiService:GetPropertyChangedSignal("SelectedObject"), revealSelection)
	connect(GuiService:GetPropertyChangedSignal("ReducedMotionEnabled"), policy)
	connect(UserInputService.LastInputTypeChanged, function(input)
		if
			string.find(input.Name, "Gamepad")
			and (not GuiService.SelectedObject or not GuiService.SelectedObject:IsDescendantOf(gui))
		then
			focus(1)
		end
	end)
	connect(RunService.Heartbeat, function(dt)
		if not alive then
			return
		end
		accumulator += dt
		if accumulator < 1 / 30 then
			return
		end
		local delta = accumulator
		accumulator = 0
		elapsed += delta
		decorations.step(elapsed, enabled)
		if enabled then
			shownCharge += (targetCharge - shownCharge) * (1 - math.exp(-18 * delta))
			fill.Size = UDim2.fromScale(shownCharge / 100, 1)
		else
			fill.Size = UDim2.fromScale(targetCharge / 100, 1)
		end
		if edge then
			edge.Color = if lampOn
				then statusColor:Lerp(
					Color3.fromRGB(255, 231, 165),
					if enabled then 0.08 + 0.07 * math.sin(elapsed * 2.2) else 0
				)
				else Color3.fromRGB(144, 78, 45)
		end
	end)
	local controller = {}
	function controller.status(charge: number, lit: boolean, color: Color3)
		targetCharge = charge
		lampOn = lit
		statusColor = color
		if charge == 0 or not enabled then
			shownCharge = charge
			fill.Size = UDim2.fromScale(charge / 100, 1)
		end
	end
	function controller.bind(list: { TextButton }, update: (boolean) -> ())
		buttons = list
		onPolicy = update
		for i, button in buttons do
			button.NextSelectionRight = buttons[i % #buttons + 1]
			button.NextSelectionLeft = buttons[(i - 2) % #buttons + 1]
			button.NextSelectionDown = button.NextSelectionRight
			button.NextSelectionUp = button.NextSelectionLeft
			connect(button:GetPropertyChangedSignal("Active"), function()
				if not button.Active and GuiService.SelectedObject == button then
					focus(1)
				end
			end)
		end
		-- Match the physical two-button / three-preset rows.
		buttons[1].NextSelectionDown = buttons[3]
		buttons[2].NextSelectionDown = buttons[4]
		buttons[3].NextSelectionUp = buttons[1]
		buttons[4].NextSelectionUp = buttons[2]
		buttons[5].NextSelectionUp = buttons[2]
		policy()
	end
	function controller.toggle()
		requested = not requested
		policy()
	end
	function controller.reveal()
		-- Structural frame stays fixed, including on open.
	end
	connect(gui.Destroying, function()
		alive = false
		for _, connection in connections do
			connection:Disconnect()
		end
		ContextActionService:UnbindAction("FeedbackKeyboardNavigation")
		if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(gui) then
			GuiService.SelectedObject = nil
		end
		GuiService.GuiNavigationEnabled = oldNavigation
		GuiService.AutoSelectGuiEnabled = oldAuto
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, oldPlayerList)
	end)
	return controller
end
return Motion
