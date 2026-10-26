--!strict
-- One shard panel, built the same way everywhere (TASK-0097). Anatomy:
--
--   root   Frame        base Position / Size / Rotation from Theme.Layout; never animated
--   group  CanvasGroup  the Fx target (Position offset, Rotation, GroupTransparency, UIScale); shard + a 36 px pad
--     glow    ImageLabel  glow-*.png fills the group (optional)
--     image   ImageLabel  shard-*.png, inset by the pad so it fills the shard box
--     flash   ImageLabel  the same shape in white, transparent until Fx.flash
--     content Frame       the shard box; labels go here with coordinates relative to the shard
--
-- A CanvasGroup clips to its bounds, so the group is the shard plus the glow pad on every side and the root keeps the
-- shard's own box. Shards whose width follows their text (toast, chip) get a hidden sizer TextLabel; the root's width is
-- set from its measured width (never AutomaticSize on the root: the scale-sized group would feed back into it).

local Theme = require(script.Parent.Theme)

local Shard = {}

export type Shard = {
	root: Frame,
	group: CanvasGroup,
	glow: ImageLabel?,
	image: ImageLabel,
	flash: ImageLabel,
	content: Frame,
	scale: UIScale,
	sizer: TextLabel?,
	gem: Theme.Gem,
	setImages: (imageKey: string, glowKey: string?, gem: Theme.Gem) -> (),
	setSizerText: (text: string) -> (),
}

export type Options = {
	glowKey: string?,
	gem: Theme.Gem,
	-- Width follows the text: pass the font size and the padding on each side of the sizer text.
	autoWidth: { textSize: number, padX: number, maxWidth: number? }?,
	zIndex: number?,
}

local make = Theme.make
local PAD = Theme.GlowPad

local function flashImage(label: ImageLabel, key: string)
	local id = (Theme.Image :: { [string]: string })[key]
	label.Image = if id ~= nil and id ~= "rbxassetid://0" then id else ""
end

function Shard.new(parent: Instance, name: string, layout: Theme.Box, imageKey: string, options: Options): Shard
	local auto = options.autoWidth
	local root = make("Frame", {
		Name = name,
		Position = UDim2.fromOffset(layout.x, layout.y),
		Size = if auto then UDim2.fromOffset(0, layout.h) else UDim2.fromOffset(layout.w, layout.h),
		Rotation = layout.rot,
		BackgroundTransparency = 1,
		ZIndex = options.zIndex or 1,
	}, parent) :: Frame

	local group = make("CanvasGroup", {
		Name = "Group",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, PAD * 2, 1, PAD * 2),
		BackgroundTransparency = 1,
	}, root) :: CanvasGroup
	local scale = make("UIScale", {}, group) :: UIScale

	local glow: ImageLabel? = nil
	if options.glowKey then
		glow = make("ImageLabel", {
			Name = "Glow",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = 1,
		}, group) :: ImageLabel
	end
	local inset = {
		Position = UDim2.fromOffset(PAD, PAD),
		Size = UDim2.new(1, -PAD * 2, 1, -PAD * 2),
		BackgroundTransparency = 1,
	}
	local image = make("ImageLabel", {
		Name = "Shard",
		Position = inset.Position,
		Size = inset.Size,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 2,
	}, group) :: ImageLabel
	local flash = make("ImageLabel", {
		Name = "Flash",
		Position = inset.Position,
		Size = inset.Size,
		BackgroundTransparency = 1,
		ImageColor3 = Theme.Color.Ink,
		ImageTransparency = 1,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 3,
	}, group) :: ImageLabel
	local content = make("Frame", {
		Name = "Content",
		Position = inset.Position,
		Size = inset.Size,
		BackgroundTransparency = 1,
		ZIndex = 4,
	}, group) :: Frame

	local sizer: TextLabel? = nil
	if auto then
		local fit = Theme.label(root, "", auto.textSize, {
			Name = "Sizer",
			TextTransparency = 1,
			TextStrokeTransparency = 1,
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
		})
		make("UIPadding", {
			Name = "Padding",
			PaddingLeft = UDim.new(0, auto.padX),
			PaddingRight = UDim.new(0, auto.padX),
		}, fit)
		-- AbsoluteSize is in screen pixels, so undo every UIScale above the sizer to get layout units.
		local function fitWidth()
			local factor = 1
			local ancestor: Instance? = root.Parent
			while ancestor do
				local uiScale = ancestor:FindFirstChildOfClass("UIScale")
				if uiScale then
					factor *= uiScale.Scale
				end
				ancestor = ancestor.Parent
			end
			local width = fit.AbsoluteSize.X / math.max(factor, 0.01)
			if auto.maxWidth then
				width = math.min(width, auto.maxWidth)
			end
			root.Size = UDim2.fromOffset(math.ceil(width), layout.h)
		end
		fit:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitWidth)
		sizer = fit
	end

	local shard = {
		root = root,
		group = group,
		glow = glow,
		image = image,
		flash = flash,
		content = content,
		scale = scale,
		sizer = sizer,
		gem = options.gem,
	} :: Shard

	function shard.setImages(imageKeyNext: string, glowKey: string?, gem: Theme.Gem)
		shard.gem = gem
		Theme.setImage(image, imageKeyNext, gem)
		flashImage(flash, imageKeyNext)
		if glow and glowKey then
			Theme.setImage(glow, glowKey, gem)
		end
	end

	function shard.setSizerText(text: string)
		if sizer then
			sizer.Text = text
		end
	end

	shard.setImages(imageKey, options.glowKey, options.gem)
	return shard
end

return Shard
