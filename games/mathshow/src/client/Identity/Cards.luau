--!strict
-- Identity player cards (TASK-0106): GameplayCard (176x44), RevealCard, IntroCard (380x204) and ResultsRow (596x44), each
-- in six variants (default, YOU, bot, first-correct, disconnected, spectating). Pure builders from props to Instances;
-- nothing is mounted anywhere yet. Names truncate only where marked AllowTruncate; scores and numbers never do.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local HudTheme = require(script.Parent.Parent.Hud.Theme)
local IdentityTheme = require(script.Parent.IdentityTheme)
local Kit = require(script.Parent.Kit)
local Primitives = require(script.Parent.Primitives)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local IdentityCopy = require(Shared:WaitForChild("IdentityCopy"))
local IdentityRules = require(Shared:WaitForChild("IdentityRules"))

local make = HudTheme.make
local T = IdentityTheme

export type Player = {
	userId: number?,
	displayName: string,
	isBot: boolean?,
	isYou: boolean?,
	tier: string,
	groupTag: string?,
	score: number?,
	connected: boolean?, -- nil counts as connected
	spectating: boolean?,
	firstCorrect: boolean?,
	submitted: boolean?,
	equippedEmoteId: string?,
}
export type Pos = { x: number?, y: number? }
export type Reward = { kind: "xp" | "streak" | "mvp" | "first", amount: number? }

local Cards = {}

local function box(p: Pos, w: number, h: number): { x: number, y: number, w: number, h: number }
	return { x = p.x or 0, y = p.y or 0, w = w, h = h }
end

local function nameOf(p: Player): string
	if p.isBot == true then
		return IdentityCopy.BotNameFormat:format(p.displayName)
	end
	return p.displayName
end

local function statusOf(p: Player): string?
	return IdentityRules.pickStatus({
		DISCONNECTED = p.connected == false,
		WATCHING = p.spectating == true,
		FIRST_CORRECT = p.firstCorrect == true,
		SUBMITTED = p.submitted == true,
		YOU = p.isYou == true,
		BOT = p.isBot == true,
	})
end

-- Applies the variant look to a finished card: shard, glow, transparency and text dimming.
local function shardFor(variant: IdentityRules.Variant): string
	return (T.CardShard :: { [string]: string })[variant]
end

local function dim(card: { group: CanvasGroup, content: Frame }, variant: string)
	if variant == "Spectating" then
		card.group.GroupTransparency = 0.15
	elseif variant == "Disconnected" then
		for _, d in card.content:GetDescendants() do
			if d:IsA("TextLabel") then
				d.TextTransparency = 0.4 -- 60% white
			elseif d:IsA("ImageLabel") and d.Name == "Image" then
				d.ImageColor3 = Color3.fromRGB(128, 128, 128)
				d.ImageTransparency = 0.5
			end
		end
	end
end

local function build(
	parent: Instance,
	name: string,
	p: Player,
	pos: Pos,
	w: number,
	h: number,
	slice: Rect?
): (Kit.Parts, IdentityRules.Variant)
	local variant: IdentityRules.Variant = IdentityRules.variantOf(p) :: any
	local glow = if variant == "FirstCorrect" then T.CardGlow else nil
	local parts = Kit.shard(parent, name, box(pos, w, h), shardFor(variant), slice or T.Slice.Card, glow)
	parts.root:SetAttribute("Variant", variant)
	return parts, variant
end

-- 176x44: portrait, badge 24, name (AllowTruncate), score, icon-only status slot.
function Cards.GameplayCard(parent: Instance, props: { player: Player } & Pos): Frame
	local p = props.player
	local G = T.Gameplay
	local card, variant = build(parent, "GameplayCard", p, props, G.Size.X, G.Size.Y, nil)
	local c = card.content
	Kit.portrait(c, G.Portrait.X, G.Portrait.Y, G.Portrait.Size, G.Portrait.Stroke, p.userId, p.isBot == true)
	Primitives.RankBadge(c, { tier = p.tier, size = G.Badge.Size, x = G.Badge.X, y = G.Badge.Y })
	local name = Kit.text(c, nameOf(p), G.Name.Size, { x = G.Name.X, y = G.Name.Y, w = G.Name.W, h = G.Name.H })
	name:SetAttribute("AllowTruncate", true)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Name = "Name"
	local score = Kit.text(
		c,
		tostring(math.floor(p.score or 0)),
		G.Score.Size,
		{ x = G.Score.X, y = G.Score.Y, w = G.Score.W, h = G.Score.H }
	)
	score.Name = "Score"
	local status = statusOf(p)
	if status then
		Primitives.StatusSlot(c, { status = status, x = G.Slot.X, y = G.Slot.Y })
	end
	dim(card, variant)
	return card.root
end

-- Gameplay card, 8 gap, delta pill, 8 gap, reaction slot. Cards never resize and every row is 44 tall, so a reorder is a
-- pure Y tween of the returned root.
function Cards.RevealCard(parent: Instance, props: { player: Player, delta: number } & Pos): Frame
	local G, R = T.Gameplay, T.Reveal
	local width = G.Size.X + R.PillGap + R.Pill.X + R.ReactionGap + R.Reaction
	local root = make("Frame", {
		Name = "RevealCard",
		Position = UDim2.fromOffset(props.x or 0, props.y or 0),
		Size = UDim2.fromOffset(width, G.Size.Y),
		BackgroundTransparency = 1,
	}, parent) :: Frame
	Cards.GameplayCard(root, { player = props.player, x = 0, y = 0 })
	local pillX = G.Size.X + R.PillGap
	local pillY = (G.Size.Y - R.Pill.Y) / 2
	Primitives.DeltaPill(root, { delta = props.delta, x = pillX, y = pillY })
	local reaction = make("Frame", {
		Name = "Reaction",
		Position = UDim2.fromOffset(pillX + R.Pill.X + R.ReactionGap, (G.Size.Y - R.Reaction) / 2),
		Size = UDim2.fromOffset(R.Reaction, R.Reaction),
		BackgroundTransparency = 1,
	}, root) :: Frame
	if props.player.equippedEmoteId ~= nil then
		reaction:SetAttribute("EmoteId", props.player.equippedEmoteId)
	end
	return root
end

-- 380x204: portrait frame, tag chip then status chip, two-line name, standard track chip, emote slot.
function Cards.IntroCard(parent: Instance, props: { player: Player, mode: string, format: string } & Pos): Frame
	local p = props.player
	local I = T.Intro
	local parts = Kit.shard(parent, "IntroCard", box(props, I.Size.X, I.Size.Y), I.Shard, nil, I.Glow)
	local variant: IdentityRules.Variant = IdentityRules.variantOf(p) :: any
	parts.root:SetAttribute("Variant", variant)
	local c = parts.content
	Kit.portrait(c, I.Portrait.X, I.Portrait.Y, I.Portrait.Size, I.Portrait.Stroke, p.userId, p.isBot == true)
	local chipX = I.TagX
	if p.groupTag ~= nil then
		local tag = Primitives.TagChip(c, { tag = p.groupTag, x = chipX, y = I.TagY })
		if tag then
			chipX += tag.Size.X.Offset + I.ChipGap
		end
	end
	local status = statusOf(p)
	if status then
		Primitives.StatusChip(c, { status = status, x = chipX, y = I.TagY - 1 })
	end
	local name = Kit.text(c, nameOf(p), I.Name.Size, { x = I.Name.X, y = I.Name.Y, w = I.Name.W, h = I.Name.H }, {
		TextWrapped = true,
		TextYAlignment = Enum.TextYAlignment.Top,
		LineHeight = I.Name.LineHeight / I.Name.Size,
	})
	name:SetAttribute("AllowTruncate", true)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Name = "Name"
	Primitives.TrackChip(c, {
		tier = p.tier,
		mode = props.mode,
		format = props.format,
		size = "standard" :: IdentityRules.TrackSize,
		x = I.Track.X,
		y = I.Track.Y,
	})
	local emote = make("Frame", {
		Name = "Emote",
		Position = UDim2.fromOffset(I.Emote.X, I.Emote.Y),
		Size = UDim2.fromOffset(I.Emote.Size, I.Emote.Size),
		BackgroundTransparency = 1,
	}, c) :: Frame
	if p.equippedEmoteId ~= nil then
		emote:SetAttribute("EmoteId", p.equippedEmoteId)
	end
	dim(parts, variant)
	return parts.root
end

local function rewardText(r: Reward): string?
	if r.kind == "xp" then
		return IdentityCopy.Reward.XpFormat:format(math.max(math.floor(r.amount or 0), 0))
	end
	return (IdentityCopy.Reward :: { [string]: any })[if r.kind == "streak"
		then "Streak"
		elseif r.kind == "mvp" then "Mvp"
		elseif r.kind == "first" then "First"
		else ""]
end

-- 596x44 results row: placement, portrait, name, stat line, rank-change pill and up to three reward chips. `stat` is a
-- ready line (IdentityRules.statLine, or a left-at / watched-from line) so the row stays free of rules.
function Cards.ResultsRow(
	parent: Instance,
	props: {
		player: Player,
		placement: number,
		stat: string,
		rankDelta: number?,
		rewards: { Reward }?,
	} & Pos
): Frame
	local p = props.player
	local R = T.Results
	local card, variant = build(parent, "ResultsRow", p, props, R.Size.X, R.Size.Y, nil)
	local c = card.content
	local place = Kit.text(
		c,
		tostring(math.max(math.floor(props.placement), 1)),
		R.Place.Size,
		{ x = R.Place.X, y = R.Place.Y, w = R.Place.W, h = R.Place.H },
		{
			TextXAlignment = Enum.TextXAlignment.Center,
		}
	)
	place.Name = "Placement"
	Kit.portrait(c, R.Portrait.X, R.Portrait.Y, R.Portrait.Size, R.Portrait.Stroke, p.userId, p.isBot == true)
	local name = Kit.text(c, nameOf(p), R.Name.Size, { x = R.Name.X, y = R.Name.Y, w = R.Name.W, h = R.Name.H })
	name:SetAttribute("AllowTruncate", true)
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.Name = "Name"
	local stat = Kit.text(c, props.stat, R.Stat.Size, { x = R.Stat.X, y = R.Stat.Y, w = R.Stat.W, h = R.Stat.H }, {
		FontFace = HudTheme.Font.Italic,
	})
	stat.Name = "Stat"
	if props.rankDelta ~= nil then
		Primitives.RankChangePill(c, { delta = props.rankDelta, x = R.RankPill.X, y = R.RankPill.Y })
	end
	local shown = 0
	local rewardList: { Reward } = props.rewards or {}
	for _, reward in rewardList do
		if shown >= R.Rewards.Max then
			break
		end
		local text = rewardText(reward)
		if text then
			local chip = Kit.shard(
				c,
				"Reward",
				box(
					{ x = R.Rewards.X + shown * (R.Rewards.W + R.Rewards.Gap), y = R.Rewards.Y },
					R.Rewards.W,
					R.Rewards.H
				),
				"shard-id-status-gold",
				T.Slice.Status
			)
			Kit.text(
				chip.content,
				text,
				T.Status.TextSize,
				{ x = 8, y = T.Status.TextY, w = R.Rewards.W - 16, h = 16 },
				{
					TextXAlignment = Enum.TextXAlignment.Center,
				}
			)
			shown += 1
		end
	end
	dim(card, variant)
	return card.root
end

return Cards
