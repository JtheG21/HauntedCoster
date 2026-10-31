--!strict
-- Identity primitives (TASK-0106): pure builders from props to Instances. No state is kept inside; callers rebuild or
-- re-run with new props. Layout numbers come from IdentityTheme (README), wording from IdentityCopy, rules from
-- IdentityRules. Every builder takes `parent` and an absolute `x`/`y` (default 0) and returns its root GuiObject.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudTheme = require(script.Parent.Parent.Hud.Theme)
local IdentityTheme = require(script.Parent.IdentityTheme)
local Kit = require(script.Parent.Kit)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local IdentityCopy = require(Shared:WaitForChild("IdentityCopy"))
local IdentityRules = require(Shared:WaitForChild("IdentityRules"))

local make = HudTheme.make
local T = IdentityTheme

export type Pos = { x: number?, y: number? }
export type ProgressProps = {
	x: number?,
	y: number?,
	kind: "profile" | "strip",
	tier: string,
	mode: "normal" | "gain" | "loss" | "provisional" | "full" | "demon",
	value: number?, -- 0-100 within the tier
	delta: number?, -- previewGain / previewLoss (positive integer)
	played: number?,
	needed: number?,
	standing: number?,
}

local Primitives = {}

local function tierEntry(tier: string): { Image: string, Glow: string, Rgb: Color3 }?
	return (T.Tier :: { [string]: any })[tier]
end

local function box(p: Pos, w: number, h: number): { x: number, y: number, w: number, h: number }
	return { x = p.x or 0, y = p.y or 0, w = w, h = h }
end

-- Rank badge: the tier image, optionally over its glow. Unknown tiers draw nothing.
function Primitives.RankBadge(parent: Instance, props: { tier: string, size: number, glow: boolean? } & Pos): Frame
	local frame = make("Frame", {
		Name = "RankBadge",
		Position = UDim2.fromOffset(props.x or 0, props.y or 0),
		Size = UDim2.fromOffset(props.size, props.size),
		BackgroundTransparency = 1,
	}, parent) :: Frame
	local entry = tierEntry(props.tier)
	if entry == nil then
		warn(`[MathShow] RankBadge: unknown tier {tostring(props.tier)}`)
		return frame
	end
	if props.glow == true then
		local glowSize = props.size * (T.BadgeSizes.HeroGlow / T.BadgeSizes.Hero)
		local glow = make("ImageLabel", {
			Name = "Glow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromOffset(glowSize, glowSize),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
		}, frame) :: ImageLabel
		Kit.setImage(glow, entry.Glow, nil)
	end
	local image = make("ImageLabel", {
		Name = "Badge",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
	}, frame) :: ImageLabel
	Kit.setImage(image, entry.Image, nil)
	return frame
end

local MODE_ICON: { [string]: string } = {
	groupBattle = T.Icon.ModeGroup,
	team3v3 = T.Icon.ModeTeam,
	blitz = T.Icon.ModeBlitz,
}
local FORMAT_ICON: { [string]: string } = { direct = T.Icon.FormatDirect, choice = T.Icon.FormatChoice }

function Primitives.ModeIcon(parent: Instance, props: { mode: string, size: number, tint: Color3? } & Pos): ImageLabel
	local key = MODE_ICON[props.mode]
	if key == nil then
		warn(`[MathShow] ModeIcon: unknown mode {tostring(props.mode)}`)
	end
	return Kit.icon(parent, key or T.Icon.ModeGroup, props.x or 0, props.y or 0, props.size, props.tint)
end

function Primitives.FormatIcon(
	parent: Instance,
	props: { format: string, size: number, tint: Color3? } & Pos
): ImageLabel
	local key = FORMAT_ICON[props.format]
	if key == nil then
		warn(`[MathShow] FormatIcon: unknown format {tostring(props.format)}`)
	end
	return Kit.icon(parent, key or T.Icon.FormatDirect, props.x or 0, props.y or 0, props.size, props.tint)
end

-- Track chip: mode symbol, tier badge, then "TIER · MODE" (standard) or "TIER · MODE · FORMAT" (long); compact is icons
-- only (mode, badge, format marker).
function Primitives.TrackChip(
	parent: Instance,
	props: { tier: string, mode: string, format: string, size: IdentityRules.TrackSize } & Pos
): Frame
	local size = props.size
	local width = (T.Track.Width :: { [string]: number })[if size == "compact"
		then "Compact"
		elseif size == "long" then "Long"
		else "Standard"]
	local shard = Kit.shard(parent, "TrackChip", box(props, width, T.Track.Height), "shard-id-track", T.Slice.Track)
	local c = shard.content
	Primitives.ModeIcon(c, { mode = props.mode, size = T.Track.Mode.Size, x = T.Track.Mode.X, y = T.Track.Mode.Y })
	Primitives.RankBadge(c, {
		tier = props.tier,
		size = T.Track.Badge.Size,
		x = if size == "compact" then T.Track.Badge.CompactX else T.Track.Badge.X,
		y = T.Track.Badge.Y,
	})
	local text = IdentityRules.trackText(props.tier, props.mode, props.format, props.size)
	if text then
		Kit.text(c, text, T.Track.Text.Size, {
			x = T.Track.Text.X,
			y = T.Track.Text.Y,
			w = if size == "long" then T.Track.Text.LongW else T.Track.Text.StandardW,
			h = T.Track.Text.LineHeight,
		})
	end
	if size ~= "long" then
		Primitives.FormatIcon(c, {
			format = props.format,
			size = T.Track.Format.Size,
			x = if size == "compact" then T.Track.Format.CompactX else T.Track.Format.X,
			y = T.Track.Format.Y,
		})
	end
	return shard.root
end

-- "[TAG]" chip; refuses a tag that is not 2-5 characters (nothing is drawn).
function Primitives.TagChip(parent: Instance, props: { tag: string } & Pos): Frame?
	local text = IdentityRules.tagText(props.tag)
	if text == nil then
		return nil
	end
	local width = IdentityRules.tagWidth(Kit.measure(text, T.Tag.TextSize))
	local shard = Kit.shard(parent, "TagChip", box(props, width, T.Tag.Height), "shard-id-tag", T.Slice.Tag)
	local label = Kit.text(shard.content, text, T.Tag.TextSize, {
		x = T.Tag.PadX,
		y = T.Tag.TextY,
		w = width - T.Tag.PadX * 2,
		h = 16,
	}, { TextXAlignment = Enum.TextXAlignment.Center })
	label.Name = "Tag"
	return shard.root
end

local function styleOf(status: string): { Shard: string, Icon: string, Ink: Color3 }?
	return (T.StatusStyle :: { [string]: any })[status]
end

local function statusIcon(
	parent: Instance,
	style: { Shard: string, Icon: string, Ink: Color3 },
	x: number,
	y: number,
	size: number
)
	local tint = if style.Icon == "You" then style.Ink else nil
	return Kit.icon(parent, (T.Icon :: { [string]: string })[style.Icon], x, y, size, tint)
end

-- Status chip: icon 14 and 12 px bold text on the status shard. `status` is an IdentityRules.StatusKey.
function Primitives.StatusChip(parent: Instance, props: { status: string } & Pos): Frame?
	local style = styleOf(props.status)
	local text = (IdentityCopy.Status :: { [string]: string })[props.status]
	if style == nil or text == nil then
		warn(`[MathShow] StatusChip: unknown status {tostring(props.status)}`)
		return nil
	end
	local width = IdentityRules.statusWidth(Kit.measure(text, T.Status.TextSize))
	local shard = Kit.shard(parent, "StatusChip", box(props, width, T.Status.Height), style.Shard, T.Slice.Status)
	statusIcon(shard.content, style, T.Status.IconX, T.Status.IconY, T.Status.IconSize)
	Kit.text(shard.content, text, T.Status.TextSize, {
		x = T.Status.TextX,
		y = T.Status.TextY,
		w = width - T.Status.TextX - T.Status.PadRight,
		h = 16,
	}, { TextColor3 = style.Ink })
	return shard.root
end

-- Icon-only status for the Gameplay card: a 20x20 dark square with the status icon at 14.
function Primitives.StatusSlot(parent: Instance, props: { status: string } & Pos): Frame?
	local style = styleOf(props.status)
	if style == nil then
		warn(`[MathShow] StatusSlot: unknown status {tostring(props.status)}`)
		return nil
	end
	local size = T.StatusSlot.Size
	local slot = make("Frame", {
		Name = "StatusSlot",
		Position = UDim2.fromOffset(props.x or 0, props.y or 0),
		Size = UDim2.fromOffset(size, size),
		BackgroundColor3 = T.StatusSlot.Color,
		BorderSizePixel = 0,
	}, parent) :: Frame
	local inner = (size - T.StatusSlot.IconSize) / 2
	statusIcon(slot, style, inner, inner, T.StatusSlot.IconSize)
	slot:SetAttribute("Status", props.status)
	return slot
end

local function pill(
	parent: Instance,
	name: string,
	p: Pos,
	w: number,
	shardKey: string,
	text: string,
	iconKey: string?
): Frame
	local shard = Kit.shard(parent, name, box(p, w, T.Reveal.Pill.Y), shardKey, T.Slice.Pill)
	local textX = 12
	if iconKey then
		Kit.icon(shard.content, iconKey, textX, 8, T.Results.RankPill.IconSize)
		textX += T.Results.RankPill.IconSize + 4
	end
	Kit.text(shard.content, text, 13, { x = textX, y = 6, w = w - textX - 12, h = 16 }, {
		TextXAlignment = if iconKey then Enum.TextXAlignment.Left else Enum.TextXAlignment.Center,
	})
	return shard.root
end

-- Score-change pill (64x28) for the reveal: green for a gain, silver otherwise. Text is "+150" / "−8" / "0".
function Primitives.DeltaPill(parent: Instance, props: { delta: number } & Pos): Frame
	local key = if props.delta > 0 then "shard-id-pill-green" else "shard-id-pill-silver"
	return pill(parent, "DeltaPill", props, T.Reveal.Pill.X, key, IdentityRules.deltaText(props.delta), nil)
end

-- Rank-change pill (72x28): arrow icon plus the magnitude. Green up, red down, silver unchanged.
function Primitives.RankChangePill(parent: Instance, props: { delta: number } & Pos): Frame
	local kind = IdentityRules.rankChangeKind(props.delta)
	local shardKey = if kind == "up"
		then "shard-id-pill-green"
		elseif kind == "down" then "shard-id-pill-red"
		else "shard-id-pill-silver"
	local iconKey = if kind == "up" then T.Icon.Up elseif kind == "down" then T.Icon.Down else T.Icon.Same
	return pill(
		parent,
		"RankChangePill",
		props,
		T.Results.RankPill.W,
		shardKey,
		IdentityRules.rankChangeText(props.delta),
		iconKey
	)
end

-- Rank progress bar. Profile 300x16 (SliceScale 0.5) or card strip 120x8 (SliceScale 0.25); value text sits outside.
function Primitives.ProgressBar(parent: Instance, props: ProgressProps): Frame
	local entry = tierEntry(props.tier)
	local tint = if entry then entry.Rgb else HudTheme.GemColor.silver
	local size = if props.kind == "strip" then T.Progress.Strip else T.Progress.Profile
	local scale = if props.kind == "strip" then T.Progress.StripSliceScale else T.SliceScale
	local fontSize = if props.kind == "strip" then 11 else 13
	local root = make("Frame", {
		Name = "ProgressBar",
		Position = UDim2.fromOffset(props.x or 0, props.y or 0),
		Size = UDim2.fromOffset(size.X, size.Y),
		BackgroundTransparency = 1,
	}, parent) :: Frame
	local mode = props.mode
	local value = if type(props.value) == "number" then math.clamp(props.value, 0, 100) else 0

	local function bar(
		name: string,
		key: string,
		slice: Rect,
		x: number,
		w: number,
		color: Color3?,
		transparency: number?
	): ImageLabel?
		if w <= 0 then
			return nil
		end
		local shard = Kit.shard(root, name, { x = x, y = 0, w = w, h = size.Y }, key, slice, nil, scale)
		if color then
			shard.image.ImageColor3 = color
		end
		if transparency then
			shard.image.ImageTransparency = transparency
			shard.image.BackgroundTransparency = math.max(0.05, transparency)
		end
		return shard.image
	end
	local function label(text: string, x: number, y: number, w: number, textSize: number)
		return Kit.text(root, text, textSize, { x = x, y = y, w = w, h = textSize + 3 })
	end
	local function tick(x: number)
		make("Frame", {
			Name = "Tick",
			Position = UDim2.fromOffset(x - T.Progress.Tick.X / 2, (size.Y - T.Progress.Tick.Y) / 2),
			Size = UDim2.fromOffset(T.Progress.Tick.X, T.Progress.Tick.Y),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ZIndex = 6,
		}, root)
	end
	local textX = size.X + T.Progress.ValueGap
	local hintY = size.Y + 4

	if mode == "provisional" then
		local P = T.Progress.Provisional
		local played = math.max(0, math.floor(props.played or 0))
		local needed = math.max(1, math.floor(props.needed or P.Segments))
		for i = 1, P.Segments do
			bar(
				`Segment{i}`,
				T.Progress.Fill,
				T.Slice.Progress,
				(i - 1) * (P.SegmentW + P.Gap),
				P.SegmentW,
				P.Color,
				if i <= played then nil else P.UnplayedTransparency
			)
		end
		label(IdentityCopy.Progress.Provisional, 0, hintY, size.X, fontSize)
		label(IdentityRules.provisionalText(played, needed), 0, hintY + fontSize + 4, size.X, fontSize - 2)
		return root
	end

	local openEnd = mode == "demon"
	bar(
		"Track",
		if openEnd then T.Progress.Open else T.Progress.Track,
		if openEnd then T.Slice.ProgressOpen else T.Slice.Progress,
		0,
		size.X,
		nil,
		nil
	)
	if mode == "demon" then
		bar("Fill", T.Progress.Open, T.Slice.ProgressOpen, 0, size.X, T.Tier.demon.Rgb, nil)
		label(IdentityRules.standingText(props.standing, props.kind == "strip"), textX, 0, 120, fontSize)
		label(IdentityCopy.Progress.NoNextTier, 0, hintY, size.X, fontSize - 2)
		return root
	end

	local shown = if mode == "loss" then math.max(0, value - math.max(props.delta or 0, 0)) else value
	if mode == "full" then
		shown = 100
	end
	bar("Fill", T.Progress.Fill, T.Slice.Progress, 0, IdentityRules.fillWidth(shown, size.X), tint, nil)
	if mode == "gain" then
		local to = math.min(100, value + math.max(props.delta or 0, 0))
		local from = IdentityRules.fillWidth(value, size.X)
		local toW = IdentityRules.fillWidth(to, size.X)
		bar(
			"Preview",
			T.Progress.Fill,
			T.Slice.Progress,
			from,
			toW - from,
			T.Progress.Gain,
			T.Progress.PreviewTransparency
		)
		tick(toW)
		label(IdentityRules.gainText(value, props.delta), textX, 0, 120, fontSize)
		label(IdentityCopy.Progress.GainHint, textX, hintY, 120, fontSize - 2)
	elseif mode == "loss" then
		local keep = IdentityRules.fillWidth(shown, size.X)
		local was = IdentityRules.fillWidth(value, size.X)
		bar(
			"Preview",
			T.Progress.Fill,
			T.Slice.Progress,
			keep,
			was - keep,
			T.Progress.Loss,
			T.Progress.PreviewTransparency
		)
		tick(keep)
		label(IdentityRules.lossText(value, props.delta), textX, 0, 120, fontSize)
		label(IdentityCopy.Progress.LossHint, textX, hintY, 120, fontSize - 2)
	elseif mode == "full" then
		label(IdentityCopy.Progress.ChallengeUnlocked, textX, 0, 200, fontSize)
	else
		label(IdentityCopy.Progress.ValueFormat:format(math.floor(value)), textX, 0, 120, fontSize)
	end
	return root
end

return Primitives
