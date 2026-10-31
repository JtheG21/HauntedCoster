--!strict
-- One menu shard, built like Hud/Shard (TASK-0097) but resolving images through MenuTheme.Image first, then the HUD
-- Theme.Image. Anatomy: root Frame (box, rotation) > CanvasGroup (box + 36 px pad; Fx animates only this) > glow, shard,
-- flash, content. The content Frame carries ShapeKey / ShapeW / ShapeH for the text-fit gate (tests/studio/TextFit).

local HudTheme = require(script.Parent.Parent.Hud.Theme)
local MenuTheme = require(script.Parent.MenuTheme)

local make = HudTheme.make
local PAD = MenuTheme.GlowPad
local UNSET = "rbxassetid://0"

export type Gem = string -- "red" | "blue" | "violet" | "green" | "silver" (Hud Theme.Gem); a plain string keeps literal arrays easy
export type Shard = {
	root: Frame,
	group: CanvasGroup,
	glow: ImageLabel?,
	image: ImageLabel,
	flash: ImageLabel,
	content: Frame,
	scale: UIScale, -- group scale, owned by Fx
	touch: UIScale, -- root scale for focus / press, owned by View
	key: string,
	setImages: (imageKey: string, glowKey: string?, gem: Gem) -> (),
}

local Shard = {}

local warned: { [string]: boolean } = {}

local function idOf(key: string): string?
	local id = (MenuTheme.Image :: { [string]: string })[key] or (HudTheme.Image :: { [string]: string })[key]
	if id == nil or id == UNSET then
		return nil
	end
	return id
end
Shard.idOf = idOf

-- Real image, or a flat placeholder of the same size (shard) / nothing (glow, icon) while the id is unset.
function Shard.setImage(label: ImageLabel, key: string, gem: Gem?, flat: Color3?)
	local id = idOf(key)
	if id then
		label.Image = id
		label.BackgroundTransparency = 1
		return
	end
	if not warned[key] then
		warned[key] = true
		warn(`[MathShow] Menu image {key} has no asset id yet; showing a flat placeholder`)
	end
	label.Image = ""
	if string.sub(key, 1, 5) == "shard" then
		label.BackgroundColor3 = flat or HudTheme.Color.Ground:Lerp(HudTheme.GemColor[(gem or "silver") :: any], 0.45)
		label.BackgroundTransparency = 0.05
	else
		label.BackgroundTransparency = 1
	end
end

function Shard.new(
	parent: Instance,
	name: string,
	box: MenuTheme.Box,
	imageKey: string,
	glowKey: string?,
	gem: Gem
): Shard
	local root = make("Frame", {
		Name = name,
		Position = UDim2.fromOffset(box.x, box.y),
		Size = UDim2.fromOffset(box.w, box.h),
		Rotation = box.rot,
		BackgroundTransparency = 1,
	}, parent) :: Frame
	local touch = make("UIScale", { Name = "Touch" }, root) :: UIScale
	local group = make("CanvasGroup", {
		Name = "Group",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, PAD * 2, 1, PAD * 2),
		BackgroundTransparency = 1,
	}, root) :: CanvasGroup
	local scale = make("UIScale", {}, group) :: UIScale
	local glow: ImageLabel? = nil
	if glowKey then
		glow = make("ImageLabel", {
			Name = "Glow",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Stretch,
			ZIndex = 1,
		}, group) :: ImageLabel
	end
	local inset = { Position = UDim2.fromOffset(PAD, PAD), Size = UDim2.new(1, -PAD * 2, 1, -PAD * 2) }
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
		ImageColor3 = HudTheme.Color.Ink,
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
	content:SetAttribute("ShapeKey", imageKey)
	content:SetAttribute("ShapeW", box.w)
	content:SetAttribute("ShapeH", box.h)

	local shard = { root = root, group = group, glow = glow, image = image, flash = flash, content = content } :: any
	shard.scale, shard.touch, shard.key = scale, touch, imageKey
	function shard.setImages(imageKeyNext: string, glowKey2: string?, gem2: Gem)
		shard.key = imageKeyNext
		content:SetAttribute("ShapeKey", imageKeyNext)
		local flat = if string.find(imageKeyNext, "locked", 1, true) then MenuTheme.Color.Locked else nil
		Shard.setImage(image, imageKeyNext, gem2, flat)
		Shard.setImage(flash, imageKeyNext, gem2, nil)
		flash.BackgroundTransparency = 1
		if glow and glowKey2 then
			Shard.setImage(glow, glowKey2, gem2, nil)
		end
	end
	shard.setImages(imageKey, glowKey, gem)
	return shard :: Shard
end

return Shard
