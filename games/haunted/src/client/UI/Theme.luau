--!strict
-- The Haunted Collector UI system (TASK-0048; art direction SYS-Haunted-Art-Direction): ink-dark panels with a
-- gilt edge, parchment text, Grenze Gotisch for display and Builder Sans for reading, violet ghost-light accents.
-- Constructors keep every screen consistent: panels, labels, buttons (touch-sized, hover/press feedback, a gilt
-- controller selection ring), chips, modal windows with one close/back behaviour, tabs and empty/loading states.

local TweenService = game:GetService("TweenService")

local Theme = {}

Theme.Colors = {
	panel = Color3.fromRGB(18, 14, 26), -- ink
	panel2 = Color3.fromRGB(34, 26, 46), -- raised ink
	panel3 = Color3.fromRGB(48, 36, 64),
	stroke = Color3.fromRGB(196, 160, 98), -- gilt
	strokeDim = Color3.fromRGB(96, 78, 60),
	text = Color3.fromRGB(240, 230, 210), -- parchment
	dim = Color3.fromRGB(172, 160, 146),
	gold = Color3.fromRGB(238, 190, 92),
	good = Color3.fromRGB(136, 216, 142),
	bad = Color3.fromRGB(236, 100, 90),
	clue = Color3.fromRGB(150, 210, 255),
	ghost = Color3.fromRGB(176, 132, 255), -- violet ghost-light accent
	button = Color3.fromRGB(78, 46, 118),
	buttonOff = Color3.fromRGB(52, 46, 60),
	secondary = Color3.fromRGB(44, 36, 56),
	danger = Color3.fromRGB(120, 38, 40),
	robux = Color3.fromRGB(46, 120, 88),
}

Theme.Title = Enum.Font.GrenzeGotisch
Theme.Body = Enum.Font.BuilderSans
Theme.Bold = Enum.Font.BuilderSansBold
Theme.Medium = Enum.Font.BuilderSansMedium

Theme.MinTouch = 44 -- smallest touch target (px, before the UI scale)

type Props = { [string]: any }

local function apply(inst: Instance, props: Props?)
	if props then
		for k, v in props do
			(inst :: any)[k] = v
		end
	end
end

function Theme.corner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 10)
	c.Parent = parent
end

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.stroke
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
	return s
end

-- A gilt edge that catches the light at the top and darkens at the bottom.
function Theme.gilt(parent: Instance, thickness: number?): UIStroke
	local s = Theme.stroke(parent, Color3.new(1, 1, 1), thickness or 1.5)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(236, 206, 140)),
		ColorSequenceKeypoint.new(0.5, Theme.Colors.stroke),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(110, 84, 52)),
	})
	g.Parent = s
	return s
end

function Theme.pad(parent: Instance, px: number, py: number?)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, py or px)
	p.PaddingBottom = UDim.new(0, py or px)
	p.PaddingLeft = UDim.new(0, px)
	p.PaddingRight = UDim.new(0, px)
	p.Parent = parent
end

function Theme.list(parent: Instance, padding: number, horizontal: boolean?): UIListLayout
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, padding)
	l.FillDirection = if horizontal then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	l.SortOrder = Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

function Theme.frame(parent: Instance, props: Props?): Frame
	local f = Instance.new("Frame")
	f.BackgroundColor3 = Theme.Colors.panel
	f.BackgroundTransparency = 0.06
	f.BorderSizePixel = 0
	apply(f, props)
	f.Parent = parent
	return f
end

-- A raised ink panel: soft top-light gradient and a gilt edge.
function Theme.panel(parent: Instance, props: Props?): Frame
	local f = Theme.frame(parent, props)
	Theme.corner(f, 12)
	Theme.gilt(f)
	local g = Instance.new("UIGradient")
	g.Rotation = 90
	g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(196, 190, 210))
	g.Parent = f
	return f
end

-- A recessed card inside a panel (list rows, catalog tiles).
function Theme.card(parent: Instance, props: Props?): Frame
	local f = Theme.frame(parent, { BackgroundColor3 = Theme.Colors.panel2, BackgroundTransparency = 0 })
	apply(f, props)
	Theme.corner(f, 10)
	Theme.stroke(f, Theme.Colors.strokeDim, 1)
	return f
end

function Theme.label(parent: Instance, text: string, props: Props?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Theme.Colors.text
	l.Font = Theme.Body
	l.TextSize = 16
	l.TextWrapped = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Size = UDim2.new(1, 0, 0, 22)
	apply(l, props)
	l.Parent = parent
	return l
end

-- A display heading in Grenze Gotisch with a soft ink shadow.
function Theme.heading(parent: Instance, text: string, props: Props?): TextLabel
	local l = Theme.label(parent, text, {
		Font = Theme.Title,
		TextSize = 28,
		TextColor3 = Theme.Colors.gold,
		TextStrokeColor3 = Color3.fromRGB(20, 10, 14),
		TextStrokeTransparency = 0.45,
		Size = UDim2.new(1, 0, 0, 34),
	})
	apply(l, props)
	return l
end

-- The controller selection ring shared by every button.
local selectionRing: Frame? = nil
local function ring(): Frame
	if not selectionRing then
		local r = Instance.new("Frame")
		r.Name = "SelectionRing"
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, 8, 1, 8)
		r.Position = UDim2.fromOffset(-4, -4)
		Theme.corner(r, 12)
		Theme.stroke(r, Theme.Colors.gold, 3)
		selectionRing = r
	end
	return selectionRing :: Frame
end

local function feedback(b: GuiButton)
	b.MouseEnter:Connect(function()
		local base = b:GetAttribute("BaseColor")
		if b.Active and typeof(base) == "Color3" then
			TweenService:Create(b, TweenInfo.new(0.12), { BackgroundColor3 = base:Lerp(Color3.new(1, 1, 1), 0.12) })
				:Play()
		end
	end)
	b.MouseLeave:Connect(function()
		local base = b:GetAttribute("BaseColor")
		if b.Active and typeof(base) == "Color3" then
			TweenService:Create(b, TweenInfo.new(0.18), { BackgroundColor3 = base }):Play()
		end
	end)
	b.MouseButton1Down:Connect(function()
		local s = b:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
		s.Parent = b
		TweenService:Create(s, TweenInfo.new(0.06), { Scale = 0.96 }):Play()
	end)
	b.MouseButton1Up:Connect(function()
		local s = b:FindFirstChildOfClass("UIScale")
		if s then
			TweenService:Create(s, TweenInfo.new(0.1), { Scale = 1 }):Play()
		end
	end)
end

-- Buttons: "primary" (violet with gilt edge, default), "secondary" (ink), "danger", "robux".
function Theme.button(parent: Instance, text: string, onClick: () -> (), props: Props?, style: string?): TextButton
	local base = if style == "secondary"
		then Theme.Colors.secondary
		elseif style == "danger" then Theme.Colors.danger
		elseif style == "robux" then Theme.Colors.robux
		else Theme.Colors.button
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = base
	b.AutoButtonColor = false
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Theme.Colors.text
	b.Font = Theme.Bold
	b.TextSize = 17
	b.TextWrapped = true
	b.Size = UDim2.fromOffset(120, Theme.MinTouch)
	b.SelectionImageObject = ring()
	b:SetAttribute("BaseColor", base)
	apply(b, props)
	b:SetAttribute("BaseColor", b.BackgroundColor3)
	Theme.corner(b, 9)
	if style == "secondary" then
		Theme.stroke(b, Theme.Colors.strokeDim, 1)
	else
		Theme.gilt(b, 1.2)
	end
	feedback(b)
	b.Activated:Connect(function()
		if b.Active then
			onClick()
		end
	end)
	b.Parent = parent
	return b
end

function Theme.setEnabled(b: TextButton, enabled: boolean)
	b.Active = enabled
	b.Selectable = enabled
	local base = b:GetAttribute("BaseColor")
	b.BackgroundColor3 = if enabled
		then (if typeof(base) == "Color3" then base else Theme.Colors.button)
		else Theme.Colors.buttonOff
	b.TextTransparency = if enabled then 0 else 0.4
end

-- A small rounded tag (Owned, Equipped, rarity, price).
function Theme.chip(parent: Instance, text: string, color: Color3?, props: Props?): TextLabel
	local l = Theme.label(parent, text, {
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, 22),
		TextSize = 13,
		Font = Theme.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0,
		BackgroundColor3 = color or Theme.Colors.panel3,
		TextWrapped = false,
	})
	Theme.corner(l, 11)
	Theme.pad(l, 8, 0)
	apply(l, props)
	return l
end

-- A key/button hint shown next to actions ("J", "Y"...); the HUD hides hints on touch screens.
function Theme.keyHint(parent: Instance, key: string, props: Props?): TextLabel
	local l = Theme.label(parent, key, {
		Name = "KeyHint",
		Size = UDim2.fromOffset(22, 18),
		TextSize = 12,
		Font = Theme.Bold,
		TextXAlignment = Enum.TextXAlignment.Center,
		BackgroundTransparency = 0.1,
		BackgroundColor3 = Color3.fromRGB(12, 9, 18),
		TextColor3 = Theme.Colors.dim,
	})
	Theme.corner(l, 4)
	apply(l, props)
	return l
end

export type Modal = { root: Frame, body: Frame, title: TextLabel, close: TextButton }

-- A centred window with a display title, a close button and a body area. Sized as a fraction of the screen and
-- capped, so it fits desktop, tablets and phones (the HUD's UIScale handles density).
function Theme.modal(gui: Instance, title: string, onClose: () -> (), width: number?, height: number?): Modal
	local root = Theme.panel(gui, {
		Name = "Modal_" .. title,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.92, 0.84),
		Visible = false,
		ZIndex = 5,
	})
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(width or 760, height or 560)
	cap.Parent = root
	local header = Theme.frame(root, {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 52),
		BackgroundColor3 = Theme.Colors.panel2,
		BackgroundTransparency = 0,
	})
	Theme.corner(header, 12)
	local t = Theme.heading(header, title, {
		Position = UDim2.fromOffset(18, 8),
		Size = UDim2.new(1, -90, 0, 36),
		TextSize = 30,
	})
	local close = Theme.button(header, "X", onClose, {
		Name = "Close",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.fromOffset(Theme.MinTouch, 36),
		TextSize = 18,
	}, "secondary")
	local body = Theme.frame(root, {
		Name = "Body",
		Position = UDim2.fromOffset(14, 62),
		Size = UDim2.new(1, -28, 1, -74),
		BackgroundTransparency = 1,
	})
	return { root = root, body = body, title = t, close = close }
end

-- A vertical scrolling area that grows with its content.
function Theme.scroll(parent: Instance, props: Props?): ScrollingFrame
	local s = Instance.new("ScrollingFrame")
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.Size = UDim2.fromScale(1, 1)
	s.CanvasSize = UDim2.new()
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.ScrollBarThickness = 6
	s.ScrollBarImageColor3 = Theme.Colors.stroke
	s.ScrollingDirection = Enum.ScrollingDirection.Y
	s.SelectionGroup = true
	apply(s, props)
	s.Parent = parent
	return s
end

-- A row of tab buttons; `onPick(name)` fires on selection. Returns a setter for the active tab.
function Theme.tabs(parent: Instance, names: { string }, onPick: (string) -> (), props: Props?): (string) -> ()
	local row = Theme.frame(parent, {
		Name = "Tabs",
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundTransparency = 1,
	})
	apply(row, props)
	Theme.list(row, 6, true)
	local buttons: { [string]: TextButton } = {}
	local function set(active: string)
		for name, b in buttons do
			local on = name == active
			local c = if on then Theme.Colors.button else Theme.Colors.secondary
			b.BackgroundColor3 = c
			b:SetAttribute("BaseColor", c)
			b.TextColor3 = if on then Theme.Colors.gold else Theme.Colors.dim
		end
	end
	for i, name in names do
		local b = Theme.button(row, name, function()
			set(name)
			onPick(name)
		end, {
			LayoutOrder = i,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 38),
			TextSize = 15,
		}, "secondary")
		Theme.pad(b, 12, 0)
		buttons[name] = b
	end
	return set
end

-- Loading / empty / unavailable states for any list area.
function Theme.notice(parent: Instance, text: string, kind: string?): TextLabel
	local color = if kind == "error"
		then Theme.Colors.bad
		elseif kind == "loading" then Theme.Colors.ghost
		else Theme.Colors.dim
	return Theme.label(parent, text, {
		Name = "Notice",
		Size = UDim2.new(1, 0, 0, 60),
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = color,
		TextSize = 17,
		Font = Theme.Medium,
	})
end

function Theme.fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

return Theme
