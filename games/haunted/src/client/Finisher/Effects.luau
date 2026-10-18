--!strict
-- Effect handler for the finisher: one function that starts each "effect" cue and returns its undo.
-- Kinds: lock, tint, flash, rune, shockwave, vortex, aura, sparks, burst, pillar, orb. A kind whose
-- meshes did not load is skipped.

local ContextActionService = game:GetService("ContextActionService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Assets = require(ReplicatedStorage.Shared.Config.FinisherAssets)
local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local Meshes = require(script.Parent.Meshes)
local Orb = require(script.Parent.Orb)
local Util = require(script.Parent.Util)

local Effects = {}

type Ctx = Util.Ctx
type Undo = (() -> ())?

local LOCKED_ACTIONS = {
	Enum.PlayerActions.CharacterForward,
	Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump,
}
local LOCK_PRIORITY = 3000 -- above the default movement bindings
local RUNE_FADE_IN = 0.8
local PALE_BLUE = Color3.new(0.9, 0.95, 1)
local SHOCK_START_SIZE = 4 -- studs across when a shockwave ring is born
local SHOCK_THICKNESS = 0.3
local SHOCK_LIFT = 0.6 -- above the ground, so it never z-fights
local PILLAR_ALPHA = 0.55
local ESSENCE_SIZE = 4 -- studs across
local ESSENCE_FADE_IN = 0.6
local ESSENCE_FADE_OUT = 1.0
local ESSENCE_ALPHA = 0.35
local PILLAR_ALPHA_REDUCED = 0.75

-- Height of the ground under the monster, or a sensible guess when nothing is hit.
local function groundY(ctx: Ctx): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { ctx.fx, ctx.target }
	local hit = Workspace:Raycast(ctx.target.Position + Vector3.new(0, 3, 0), Vector3.new(0, -80, 0), params)
	return if hit then hit.Position.Y + 0.15 else ctx.target.Position.Y - 3
end

-- The player's own movement controls, if their module is present (it is on any normal client).
local function playerControls(): any?
	local player = Players.LocalPlayer
	local scripts = player and player:FindFirstChild("PlayerScripts")
	local module = scripts and scripts:FindFirstChild("PlayerModule")
	if not module or not module:IsA("ModuleScript") then
		return nil
	end
	local ok, controls = pcall(function()
		return (require(module) :: any):GetControls()
	end)
	return if ok then controls else nil
end

-- Blocks movement and jump for the whole run: the default controls are switched off and the character
-- actions are sunk, under a name unique to this run so one run's undo never unbinds another's.
local function lock(ctx: Ctx): Undo
	if not RunService:IsClient() then
		return nil
	end
	local name = "FinisherLock_" .. ctx.runId
	ContextActionService:BindActionAtPriority(name, function()
		return Enum.ContextActionResult.Sink
	end, false, LOCK_PRIORITY, table.unpack(LOCKED_ACTIONS))
	local controls = playerControls()
	if controls then
		controls:Disable()
	end
	return function()
		ContextActionService:UnbindAction(name)
		if controls then
			controls:Enable()
		end
	end
end

local function tint(cue: Sequence.Cue, p: { [string]: any }): Undo
	local colour = Util.color(p.color) -- first, so a bad cue errors before anything is added to Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FinisherTint_" .. cue.id
	cc.Parent = Lighting
	TweenService:Create(cc, TweenInfo.new(0.6), { TintColor = colour, Brightness = p.brightness or 0 }):Play()
	return function()
		cc:Destroy()
	end
end

local function flash(cue: Sequence.Cue, p: { [string]: any }, reduced: boolean): Undo
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FinisherFlash_" .. cue.id
	cc.Parent = Lighting
	local peak = FinisherRules.scale("flash", p.strength or 0.5, reduced)
	TweenService:Create(cc, TweenInfo.new(0.08), { Brightness = peak }):Play()
	task.delay(0.1, function()
		if cc.Parent then
			TweenService:Create(cc, TweenInfo.new(0.22), { Brightness = 0 }):Play()
		end
	end)
	return function()
		cc:Destroy()
	end
end

-- A magic circle on the ground: mandala texture over spinning concentric rings, recoloured per phase.
local function rune(ctx: Ctx, p: { [string]: any }, floor: Vector3): Undo
	local size: number = p.size or 24
	local disc = Instance.new("Part")
	disc.Name = "FinisherRune"
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanQuery = false
	disc.Transparency = 1
	disc.Size = Vector3.new(size, 0.1, size)
	disc.CFrame = CFrame.new(floor)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.LightInfluence = 0
	gui.Brightness = FinisherRules.scale("brightness", 3, ctx.reduced)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.Parent = disc
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.fromScale(1, 1)
	img.AnchorPoint = Vector2.new(0.5, 0.5)
	img.Position = UDim2.fromScale(0.5, 0.5)
	img.Image = Assets.Textures.mandala
	img.ImageTransparency = 1
	img.Parent = gui
	disc.Parent = ctx.fx
	local rings = Meshes.get("groundRings", Color3.new(1, 1, 1), 0.6)
	if rings then
		rings.Size = Vector3.new(size * 0.9, 0.08, size * 0.9)
		rings.Parent = ctx.fx
	end
	local keys: { { at: number, c: { number } } } = p.colors
	local ringsAt = floor + Vector3.new(0, 0.05, 0)
	local stop = Util.every(function(t)
		local c = Util.color(keys[1].c)
		for _, key in keys do
			if t >= key.at then
				c = Util.color(key.c)
			end
		end
		local fade = math.min(t / RUNE_FADE_IN, 1)
		img.ImageColor3 = c
		img.Rotation = (t * 25) % 360
		img.ImageTransparency = 1 - fade * 0.15
		if rings then
			rings.Color = c
			rings.CFrame = CFrame.new(ringsAt) * CFrame.Angles(0, -t * 1.5, 0)
			rings.Transparency = 1 - fade * 0.45
		end
	end)
	return function()
		stop()
		disc:Destroy()
		if rings then
			rings:Destroy()
		end
	end
end

-- A flat ring that rushes outward along the ground and fades.
local function shockwave(ctx: Ctx, cue: Sequence.Cue, p: { [string]: any }, floor: Vector3): Undo
	local ring = Meshes.get("shockRing", Util.color(p.color), 0)
	if not ring then
		return nil
	end
	local reach: number = p.size or 40
	local duration: number = cue.duration or 1
	local startAlpha = if ctx.reduced then 0.5 else 0 -- reduced mode never shows a full-bright ring
	ring.Size = Vector3.new(SHOCK_START_SIZE, SHOCK_THICKNESS, SHOCK_START_SIZE)
	ring.CFrame = CFrame.new(floor + Vector3.new(0, SHOCK_LIFT, 0))
	ring.Transparency = startAlpha
	ring.Parent = ctx.fx
	local stop = Util.every(function(t)
		local k = math.clamp(t / duration, 0, 1)
		local s = SHOCK_START_SIZE + (reach - SHOCK_START_SIZE) * (1 - (1 - k) ^ 3)
		ring.Size = Vector3.new(s, SHOCK_THICKNESS + 1.2 * (1 - k), s)
		ring.Transparency = startAlpha + (1 - startAlpha) * k ^ 1.5
	end)
	return function()
		stop()
		ring:Destroy()
	end
end

-- A helix that spins around the pillar during the peak.
local function vortex(ctx: Ctx, p: { [string]: any }): Undo
	local helix = Meshes.get("vortex", Util.color(p.color), 0.2)
	if not helix then
		return nil
	end
	local middle = ctx.anchor.Position + Vector3.new(0, 18, 0)
	helix.Size = Vector3.new(24, 52, 24)
	helix.Parent = ctx.fx
	local stop = Util.every(function(t)
		helix.CFrame = CFrame.new(middle) * CFrame.Angles(0, t * 5, 0)
	end)
	return function()
		stop()
		helix:Destroy()
	end
end

-- The captured spirit: a soft glowing sphere with a halo that hovers where the monster was, takes the phase
-- colours, and fades out before the sequence ends. The monster itself is already gone when this plays.
local function essence(ctx: Ctx, cue: Sequence.Cue, p: { [string]: any }): Undo
	local keys: { { at: number, c: { number } } } = p.colors
	local duration: number = cue.duration or 12
	local ball = Instance.new("Part")
	ball.Name = "FinisherEssence"
	ball.Shape = Enum.PartType.Ball
	ball.Anchored = true
	ball.CanCollide = false
	ball.CanQuery = false
	ball.CastShadow = false
	ball.Material = Enum.Material.Neon
	ball.Transparency = 1
	ball.Size = Vector3.one * ESSENCE_SIZE
	ball.Position = ctx.anchor.Position + Vector3.new(0, FinisherRules.CENTER_HEIGHT, 0)
	ball.Parent = ctx.fx
	local halo = Util.billboard(ball, Assets.Textures.sparkle, Util.color(keys[1].c))
	local haloImage = halo:FindFirstChildOfClass("ImageLabel") :: ImageLabel
	local stop = Util.every(function(t)
		local c = Util.color(keys[1].c)
		for _, key in keys do
			if t >= key.at then
				c = Util.color(key.c)
			end
		end
		local fade = math.min(t / ESSENCE_FADE_IN, 1) * math.clamp((duration - t) / ESSENCE_FADE_OUT, 0, 1)
		local pulse = 1 + 0.06 * math.sin(t * 3)
		ball.Color = c
		ball.Size = Vector3.one * ESSENCE_SIZE * pulse
		ball.Transparency = 1 - fade * (1 - ESSENCE_ALPHA)
		halo.Size = UDim2.fromScale(ESSENCE_SIZE * 2.6 * pulse, ESSENCE_SIZE * 2.6 * pulse)
		haloImage.ImageColor3 = c
		haloImage.ImageTransparency = 1 - fade * 0.7
	end)
	return function()
		stop()
		ball:Destroy()
	end
end

local function aura(ctx: Ctx, p: { [string]: any }): Undo
	local rate: number = FinisherRules.scale("rate", p.rate or 20, ctx.reduced)
	local glow = Util.emitter(
		ctx.anchor,
		Util.color(p.color),
		Assets.Textures.glow,
		rate,
		NumberRange.new(2, 7),
		NumberRange.new(0.9, 1.7),
		2.2
	)
	local spark = Util.emitter(
		ctx.anchor,
		Color3.new(1, 1, 1),
		Assets.Textures.sparkle,
		rate * 0.5,
		NumberRange.new(3, 9),
		NumberRange.new(0.8, 1.5),
		0.9
	)
	return function()
		glow:Destroy()
		spark:Destroy()
	end
end

-- The lightning stack: two bolt textures flickering around the pillar.
local function sparks(ctx: Ctx, p: { [string]: any }): Undo
	local rate: number = FinisherRules.scale("rate", p.rate or 30, ctx.reduced)
	local range = NumberRange.new(12, 30)
	local life = NumberRange.new(0.15, 0.35)
	local a = Util.emitter(
		ctx.anchor,
		PALE_BLUE,
		Assets.Textures.lightningA,
		rate * 0.5,
		range,
		life,
		FinisherRules.scale("bolt", 14, ctx.reduced)
	)
	local b = Util.emitter(
		ctx.anchor,
		PALE_BLUE,
		Assets.Textures.lightningB,
		rate * 0.5,
		range,
		life,
		FinisherRules.scale("bolt", 16, ctx.reduced)
	)
	a.Rotation = NumberRange.new(0, 360)
	b.Rotation = NumberRange.new(0, 360)
	return function()
		a:Destroy()
		b:Destroy()
	end
end

local function burst(ctx: Ctx, p: { [string]: any }): Undo
	local c = Util.color(p.color)
	local e =
		Util.emitter(ctx.anchor, c, Assets.Textures.sparkle, 0, NumberRange.new(10, 26), NumberRange.new(0.6, 1.2), 2)
	e:Emit(math.floor(FinisherRules.scale("rate", p.count or 40, ctx.reduced)))
	local flare = Util.emitter(
		ctx.anchor,
		c,
		Assets.Textures.radialBurst,
		0,
		NumberRange.new(0, 0),
		NumberRange.new(0.5, 0.5),
		38
	)
	flare.SpreadAngle = Vector2.new(0, 0)
	flare:Emit(1)
	return function()
		e:Destroy()
		flare:Destroy()
	end
end

local function pillar(ctx: Ctx, p: { [string]: any }): Undo
	local height: number = p.height or 60
	local column: BasePart
	local alpha = if ctx.reduced then PILLAR_ALPHA_REDUCED else PILLAR_ALPHA
	local tube = Meshes.get("tube", Color3.new(1, 1, 1), alpha)
	if tube then
		tube.Size = Vector3.new(4, height, 4)
		column = tube
	else
		local fallback = Instance.new("Part")
		fallback.Anchored = true
		fallback.CanCollide = false
		fallback.CanQuery = false
		fallback.Material = Enum.Material.Neon
		fallback.Color = Color3.new(1, 1, 1)
		fallback.Size = Vector3.new(3.5, height, 3.5)
		column = fallback
	end
	column.Name = "FinisherPillar"
	column.Position = ctx.anchor.Position + Vector3.new(0, height / 2 - 4, 0)
	local light = Instance.new("PointLight")
	light.Range = 40
	light.Brightness = FinisherRules.scale("brightness", 2, ctx.reduced)
	light.Parent = column
	column.Transparency = 1
	column.Parent = ctx.fx
	TweenService:Create(column, TweenInfo.new(0.5), { Transparency = alpha }):Play()
	return function()
		column:Destroy()
	end
end

function Effects.new(ctx: Ctx): (cue: Sequence.Cue) -> (() -> ())?
	local floor = Vector3.new(ctx.anchor.Position.X, groundY(ctx), ctx.anchor.Position.Z)
	return function(cue)
		local p: { [string]: any } = cue.params or {}
		local kind = p.effect
		if kind == "lock" then
			return lock(ctx)
		elseif kind == "tint" then
			return tint(cue, p)
		elseif kind == "flash" then
			return flash(cue, p, ctx.reduced)
		elseif kind == "essence" then
			return essence(ctx, cue, p)
		elseif kind == "rune" then
			return rune(ctx, p, floor)
		elseif kind == "shockwave" then
			return shockwave(ctx, cue, p, floor)
		elseif kind == "vortex" then
			return vortex(ctx, p)
		elseif kind == "aura" then
			return aura(ctx, p)
		elseif kind == "sparks" then
			return sparks(ctx, p)
		elseif kind == "burst" then
			return burst(ctx, p)
		elseif kind == "pillar" then
			return pillar(ctx, p)
		elseif kind == "orb" then
			return Orb.start(ctx, cue)
		end
		warn(`Finisher: unknown effect {tostring(kind)} in cue {cue.id}`)
		return nil
	end
end

return Effects
