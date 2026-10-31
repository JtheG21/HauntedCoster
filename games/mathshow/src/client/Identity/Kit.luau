--!strict
-- Shared helpers for the identity builders (TASK-0106): asset lookup, the shard anatomy, fixed-size text and the
-- headshot loader. Anatomy matches Menu/Shard: root Frame > CanvasGroup (box + 36 px pad) > glow, shard, flash,
-- content. Content coordinates are shard-local. Every cosmetic is pcall-isolated, fails inert and warns once.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local HudTheme = require(script.Parent.Parent.Hud.Theme)
local MenuTheme = require(script.Parent.Parent.Menu.MenuTheme)
local AssetIds = require(script.Parent.AssetIds)
local IdentityTheme = require(script.Parent.IdentityTheme)
local IdentityRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("IdentityRules"))

local make = HudTheme.make
local PAD = MenuTheme.GlowPad
local UNSET = "rbxassetid://0"

export type Parts = {
	root: Frame,
	group: CanvasGroup,
	glow: ImageLabel?,
	image: ImageLabel,
	flash: ImageLabel,
	content: Frame,
}

local Kit = {}

local warned: { [string]: boolean } = {}

local function warnOnce(key: string, message: string)
	if not warned[key] then
		warned[key] = true
		warn(`[MathShow] {message}`)
	end
end

-- AssetIds first ("" = not uploaded; a bare number or a full rbxassetid:// string both work), then the menu and HUD
-- tables for reused art. nil when no id exists yet.
function Kit.assetId(key: string): string?
	local own = AssetIds[key]
	if own ~= nil and own ~= "" then
		return if string.find(own, "rbxassetid://", 1, true) then own else `rbxassetid://{own}`
	end
	local reused = (MenuTheme.Image :: { [string]: string })[key] or (HudTheme.Image :: { [string]: string })[key]
	if reused ~= nil and reused ~= UNSET and reused ~= "" then
		return reused
	end
	return nil
end

-- Real image, a flat placeholder of the same size for a shard while the id is unset, or nothing for art that is not a
-- shard. Never errors.
function Kit.setImage(label: ImageLabel, key: string, flat: Color3?)
	local id = Kit.assetId(key)
	if id then
		label.Image = id
		label.BackgroundTransparency = 1
		return
	end
	warnOnce(key, `identity image {key} has no asset id yet; showing a flat placeholder`)
	label.Image = ""
	if string.sub(key, 1, 5) == "shard" then
		label.BackgroundColor3 = flat or HudTheme.Color.Ground:Lerp(HudTheme.GemColor.silver, 0.45)
		label.BackgroundTransparency = 0.05
	else
		label.BackgroundTransparency = 1
	end
end

function Kit.icon(parent: Instance, key: string, x: number, y: number, size: number, tint: Color3?): ImageLabel
	local label = make("ImageLabel", {
		Name = key,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size, size),
		BackgroundTransparency = 1,
		ImageColor3 = tint or Color3.new(1, 1, 1),
		ScaleType = Enum.ScaleType.Fit,
	}, parent) :: ImageLabel
	Kit.setImage(label, key, nil)
	return label
end

-- One shard. `slice` makes it a horizontal 9-slice (ScaleType.Slice at `sliceScale`, default 0.5 for 2x art).
function Kit.shard(
	parent: Instance,
	name: string,
	box: { x: number, y: number, w: number, h: number },
	imageKey: string,
	slice: Rect?,
	glowKey: string?,
	sliceScale: number?
): Parts
	local root = make("Frame", {
		Name = name,
		Position = UDim2.fromOffset(box.x, box.y),
		Size = UDim2.fromOffset(box.w, box.h),
		BackgroundTransparency = 1,
	}, parent) :: Frame
	local group = make("CanvasGroup", {
		Name = "Group",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, PAD * 2, 1, PAD * 2),
		BackgroundTransparency = 1,
	}, root) :: CanvasGroup
	local inset = { Position = UDim2.fromOffset(PAD, PAD), Size = UDim2.new(1, -PAD * 2, 1, -PAD * 2) }
	local function layer(layerName: string, z: number, props: { [string]: any }?): ImageLabel
		local label = make("ImageLabel", {
			Name = layerName,
			Position = inset.Position,
			Size = inset.Size,
			BackgroundTransparency = 1,
			ZIndex = z,
		}, group) :: ImageLabel
		if slice then
			label.ScaleType = Enum.ScaleType.Slice
			label.SliceCenter = slice
			label.SliceScale = sliceScale or IdentityTheme.SliceScale
		else
			label.ScaleType = Enum.ScaleType.Stretch
		end
		HudTheme.apply(label, props)
		return label
	end
	local glow: ImageLabel? = nil
	if glowKey then
		glow = make("ImageLabel", {
			Name = "Glow",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = if slice then Enum.ScaleType.Slice else Enum.ScaleType.Stretch,
			ZIndex = 1,
		}, group) :: ImageLabel
		if slice then
			(glow :: ImageLabel).SliceCenter = IdentityTheme.Slice.CardGlow;
			(glow :: ImageLabel).SliceScale = IdentityTheme.SliceScale
		end
		Kit.setImage(glow :: ImageLabel, glowKey, nil)
	end
	local image = layer("Shard", 2)
	Kit.setImage(image, imageKey, nil)
	local flash = layer("Flash", 3, { ImageColor3 = HudTheme.Color.Ink, ImageTransparency = 1 })
	Kit.setImage(flash, imageKey, nil)
	flash.BackgroundTransparency = 1
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
	return { root = root, group = group, glow = glow, image = image, flash = flash, content = content }
end

-- Single-line text width in px; a character-count estimate when TextService is unavailable.
function Kit.measure(text: string, size: number, font: Font?): number
	local ok, bounds = pcall(function()
		local params = Instance.new("GetTextBoundsParams")
		params.Text = text
		params.Font = font or HudTheme.Font.Body
		params.Size = size
		params.Width = 10000
		return TextService:GetTextBoundsAsync(params)
	end)
	if ok and typeof(bounds) == "Vector2" then
		return bounds.X
	end
	warnOnce("measure", "TextService measure failed; using a width estimate")
	return utf8.len(text) :: number * size * 0.62
end

-- A fixed-size label (never auto-sizes). `truncate` marks the AllowTruncate elements.
function Kit.text(
	parent: Instance,
	text: string,
	size: number,
	box: { x: number, y: number, w: number, h: number },
	props: { [string]: any }?
): TextLabel
	local label = make("TextLabel", {
		Name = "Text",
		Position = UDim2.fromOffset(box.x, box.y),
		Size = UDim2.fromOffset(box.w, box.h),
		BackgroundTransparency = 1,
		FontFace = HudTheme.Font.Body,
		Text = text,
		TextSize = size,
		TextColor3 = HudTheme.Color.Ink,
		TextStrokeColor3 = HudTheme.Color.Tag,
		TextStrokeTransparency = 0.6,
		TextWrapped = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	}, parent) :: TextLabel
	HudTheme.apply(label, props)
	if label:GetAttribute("AllowTruncate") == true then
		label.TextTruncate = Enum.TextTruncate.AtEnd
	end
	return label
end

local PORTRAIT_PLACEHOLDER = Color3.fromRGB(42, 37, 80) -- #2A2550
local BOT_PORTRAIT = Color3.fromRGB(58, 63, 143) -- #3A3F8F

-- Square headshot slot with a 2 px white stroke. Bots always show the bot icon; players show the fallback until the
-- 150x150 headshot loads, and keep it on error or after the timeout. The card is never blocked on the request.
function Kit.portrait(
	parent: Instance,
	x: number,
	y: number,
	size: number,
	stroke: number,
	userId: number?,
	isBot: boolean
)
	local frame = make("Frame", {
		Name = "Portrait",
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = if isBot then BOT_PORTRAIT else PORTRAIT_PLACEHOLDER,
		BorderSizePixel = 0,
	}, parent) :: Frame
	make(
		"UIStroke",
		{ Thickness = stroke, Color = Color3.new(1, 1, 1), ApplyStrokeMode = Enum.ApplyStrokeMode.Border },
		frame
	)
	local icon = make("ImageLabel", {
		Name = "Image",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
	}, frame) :: ImageLabel
	Kit.setImage(icon, if isBot then IdentityTheme.Icon.Bot else IdentityTheme.Icon.PortraitFallback, nil)
	if isBot or userId == nil then
		return frame
	end
	local started = os.clock()
	local state = "pending"
	task.spawn(function()
		local ok, content = pcall(function()
			local image =
				Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150)
			return image
		end)
		local verdict = IdentityRules.headshotState(ok and content ~= nil, not ok, os.clock() - started)
		if verdict == "ready" and frame.Parent ~= nil then
			icon.Image = content :: string
			icon.BackgroundTransparency = 1
			state = "ready"
		else
			state = "fallback"
			if not ok then
				warnOnce("headshot", "headshot request failed; showing the portrait fallback")
			end
		end
	end)
	task.delay(IdentityRules.HeadshotTimeoutSeconds, function()
		if state == "pending" then
			state = "fallback"
			warnOnce("headshot-timeout", "headshot timed out; showing the portrait fallback")
		end
	end)
	frame:SetAttribute("HeadshotTimeout", IdentityRules.HeadshotTimeoutSeconds)
	return frame
end

return Kit
