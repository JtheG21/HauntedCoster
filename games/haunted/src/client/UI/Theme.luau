--!strict
-- Shared look for the haunted-attraction UI, plus tiny constructors so screens stay short.

local Sfx = require(script.Parent.Parent.Sfx)

local Theme = {}

Theme.Colors = {
	panel = Color3.fromRGB(24, 18, 34),
	panel2 = Color3.fromRGB(38, 28, 54),
	stroke = Color3.fromRGB(150, 100, 230),
	text = Color3.fromRGB(240, 232, 255),
	dim = Color3.fromRGB(170, 160, 190),
	gold = Color3.fromRGB(255, 205, 90),
	good = Color3.fromRGB(120, 230, 140),
	bad = Color3.fromRGB(255, 110, 100),
	clue = Color3.fromRGB(150, 210, 255),
	button = Color3.fromRGB(95, 55, 150),
	buttonOff = Color3.fromRGB(60, 52, 72),
}

Theme.Title = Enum.Font.Creepster
Theme.Body = Enum.Font.GothamMedium
Theme.Bold = Enum.Font.GothamBold

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

function Theme.stroke(parent: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Theme.Colors.stroke
	s.Thickness = thickness or 1.5
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = parent
end

function Theme.pad(parent: Instance, px: number)
	local p = Instance.new("UIPadding")
	p.PaddingTop = UDim.new(0, px)
	p.PaddingBottom = UDim.new(0, px)
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
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	apply(f, props)
	f.Parent = parent
	return f
end

function Theme.panel(parent: Instance, props: Props?): Frame
	local f = Theme.frame(parent, props)
	Theme.corner(f, 12)
	Theme.stroke(f)
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

function Theme.button(parent: Instance, text: string, onClick: () -> (), props: Props?): TextButton
	local b = Instance.new("TextButton")
	b.BackgroundColor3 = Theme.Colors.button
	b.AutoButtonColor = true
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Theme.Colors.text
	b.Font = Theme.Bold
	b.TextSize = 16
	b.TextWrapped = true
	b.Size = UDim2.fromOffset(120, 40)
	apply(b, props)
	Theme.corner(b, 8)
	b.Activated:Connect(function()
		Sfx.play("ui_click")
		onClick()
	end)
	b.Parent = parent
	return b
end

function Theme.setEnabled(b: TextButton, enabled: boolean)
	b.Active = enabled
	b.AutoButtonColor = enabled
	b.BackgroundColor3 = if enabled then Theme.Colors.button else Theme.Colors.buttonOff
	b.TextTransparency = if enabled then 0 else 0.35
end

function Theme.fmt(n: number): string
	local s = tostring(math.floor(n))
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (out:gsub("^,", ""))
end

return Theme
