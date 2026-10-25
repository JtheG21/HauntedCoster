--!strict
-- MathShow's own HUD look (colours from the design spec) plus tiny constructors so View stays short.

local Theme = {}

Theme.Colors = {
	panel = Color3.fromHex("#111923"),
	field = Color3.fromHex("#1b2732"),
	text = Color3.fromHex("#dbe3ed"),
	white = Color3.fromHex("#ffffff"),
	accent = Color3.fromHex("#67e8ce"),
	good = Color3.fromHex("#8ee7d3"),
	warn = Color3.fromHex("#f6c453"),
	bad = Color3.fromHex("#ff8a8a"),
	info = Color3.fromHex("#dbe3ed"),
	button = Color3.fromHex("#2b8f7e"),
	buttonOff = Color3.fromHex("#3a4654"),
}

Theme.Body = Enum.Font.GothamMedium
Theme.Bold = Enum.Font.GothamBlack
Theme.MinTouchHeight = 56

type Props = { [string]: any }

function Theme.apply(inst: Instance, props: Props?)
	if props then
		for key, value in props do
			(inst :: any)[key] = value
		end
	end
end

function Theme.corner(parent: Instance, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 10)
	corner.Parent = parent
end

function Theme.textLimit(parent: Instance, maxSize: number, minSize: number?)
	local limit = Instance.new("UITextSizeConstraint")
	limit.MaxTextSize = maxSize
	limit.MinTextSize = minSize or 8
	limit.Parent = parent
end

function Theme.sizeLimit(parent: Instance, maxSize: Vector2)
	local limit = Instance.new("UISizeConstraint")
	limit.MaxSize = maxSize
	limit.Parent = parent
end

function Theme.make<T>(className: string, props: Props, parent: Instance?): T
	local inst = Instance.new(className)
	Theme.apply(inst, props)
	inst.Parent = parent
	return inst :: any
end

return Theme
