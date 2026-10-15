--!strict
-- Client creature art (TASK-0043). The server owns creature models (an invisible Root it tweens, a Hitbox,
-- lights) tagged "Creature" with Species/Variant (and ArtScale/Display for pens and exhibits). This module
-- builds the matching art, applies the natural variant look, and animates it procedurally every frame from
-- the Root's motion: walk cycles scale with measured speed, so roaming, startle hops, chases and pursuits
-- animate without any server change. Parts tagged "CarriedCreature" (the capture jar) get a small copy.
--
-- Natural variants are identities, not cosmetics: Spectral = cold cyan, translucent; Ashen = charcoal with
-- glowing ember cracks (the art's "Ember" part). Cosmetic skins/auras (TASK-0050) must not use either look.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtLoader = require(script.Parent.ArtLoader)
local Effects = require(script.Parent.Effects)
local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Cosmetics"))
local CosmeticRules = require(ReplicatedStorage.Shared:WaitForChild("Rules"):WaitForChild("CosmeticRules"))

local Creatures = {}

type PartRec = { part: BasePart, logical: string, rel: CFrame, pivot: Vector3? }

type Rig = {
	aura: Attachment?, -- equipped aura's emitters (TASK-0047), local to this client
	host: Instance, -- server model or carried jar part
	root: BasePart,
	art: Model,
	species: string,
	scale: number,
	display: boolean,
	carried: boolean,
	near: { PartRec }, -- LOD0 set (plus parts without a twin)
	far: { PartRec }, -- LOD1 set (plus parts without a twin)
	lodFar: boolean,
	lodDistance: number,
	lastPos: Vector3,
	speed: number,
	phase: number,
	seed: number,
	tick: number,
	pivots: { [string]: Vector3 }, -- logical part -> joint pivot (scaled)
}

local KEYS = {
	Wisp = "creature_wisp",
	Hound = "creature_hound",
	Gentleman = "creature_gentleman",
	BellWraith = "creature_bellwraith",
}

-- Where the art sits inside the capture jar (centres each species' body on the jar).
local JAR_OFFSET = {
	Wisp = Vector3.new(0.08, 0.03, 0.03), -- the whole perch (pole and lantern too) centred in the jar
	Hound = Vector3.new(0, 0.05, 0),
	Gentleman = Vector3.new(0, 0.05, 0),
	BellWraith = Vector3.new(0, 0.3, 0),
}

-- Carried copies are shrunk to fit the jar.
local CARRY_SCALE = { Wisp = 0.3, Hound = 0.3, Gentleman = 0.22, BellWraith = 0.24 }

-- Joints that ride on another joint (the child's motion is applied inside its parent's).
local PARENT: { [string]: { [string]: string } } = {
	Wisp = {}, -- rigid perch: body, pole and tray move as one, so the grips never drift (TASK-0043 rev 1)
	Hound = { Jaw = "Head", EarL = "Head", EarR = "Head" },
	Gentleman = {},
	BellWraith = {},
}

local SPECTRAL_TINT = Color3.fromRGB(196, 242, 255)
local SPECTRAL_SHELL = Color3.fromRGB(110, 225, 255)
local ASHEN_TINT = Color3.fromRGB(78, 72, 70)

local rigs: { [Instance]: Rig } = {}
local list: { Rig } = {}

local function about(p: Vector3?, c: CFrame): CFrame
	if not p then
		return c
	end
	return CFrame.new(p) * c * CFrame.new(-p)
end

-- Spectral: a pale, translucent body inside a ForceField shimmer shell (form stays readable through the
-- shell's fresnel). Ashen: charcoal tint plus the art's glowing ember cracks.
local function variantPart(p: BasePart, variant: string, shells: { BasePart })
	if p.Material == Enum.Material.Neon then
		return
	end
	-- An equipped skin shows through the natural variant, which stays dominant (its identity must read first).
	local skin = p:GetAttribute("SkinTint")
	if variant == "Spectral" then
		p.Color = if typeof(skin) == "Color3" then SPECTRAL_TINT:Lerp(skin, 0.35) else SPECTRAL_TINT
		p.Transparency = math.max(p.Transparency, 0.45)
		p.CastShadow = false
		if not p:GetAttribute("Detail") then
			local shell = p:Clone()
			shell.Name = p.Name .. "_Shell"
			shell.Material = Enum.Material.ForceField
			shell.Color = SPECTRAL_SHELL
			shell.Transparency = 0
			shell:SetAttribute("ArtPart", p:GetAttribute("ArtPart"))
			shell.Parent = p.Parent
			table.insert(shells, shell)
		end
	elseif variant == "Ashen" then
		p.Color = if typeof(skin) == "Color3" then ASHEN_TINT:Lerp(skin, 0.2) else ASHEN_TINT
		p.Material = Enum.Material.Slate -- burnt, ashy surface under the glowing cracks
		p.Transparency = 0 -- ash is solid, even on ghosts
	end
end

local function applyVariant(built: ArtLoader.Built, variant: string)
	local shells: { BasePart } = {}
	for logical, parts in built.parts do
		for _, p in parts do
			if logical == "Ember" then
				if variant ~= "Ashen" then
					p:Destroy()
				end
			else
				variantPart(p, variant, shells)
			end
		end
	end
	-- Shells are full-resolution copies: near range only (the far set swaps to ForceField LOD1 below).
	for _, sh in shells do
		table.insert(built.lod0, sh)
	end
	for _, p in built.lod1 do
		if variant == "Ashen" then
			variantPart(p, variant, shells)
		elseif variant == "Spectral" and p.Material ~= Enum.Material.Neon then
			p.Material = Enum.Material.ForceField -- far away the shell alone carries the look
			p.Color = SPECTRAL_SHELL
		end
	end
	if variant == "Spectral" then
		local main = built.parts.Body and built.parts.Body[1]
		if main then
			local pe = Instance.new("ParticleEmitter")
			pe.Name = "SpectralMotes"
			pe.Color = ColorSequence.new(Color3.fromRGB(170, 245, 255))
			pe.LightEmission = 1
			pe.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.3, 0.55),
				NumberSequenceKeypoint.new(1, 1),
			})
			pe.Size = NumberSequence.new(0.18, 0.02)
			pe.Lifetime = NumberRange.new(1.2, 2)
			pe.Rate = 6
			pe.Speed = NumberRange.new(0.3, 0.8)
			pe.SpreadAngle = Vector2.new(180, 180)
			pe.Acceleration = Vector3.new(0, 0.6, 0)
			pe.Parent = main
		end
	end
end

local function record(rig: Rig, built: ArtLoader.Built)
	local origin = rig.art:GetPivot()
	local function rec(p: BasePart): PartRec
		local logical = (p:GetAttribute("ArtPart") :: string?) or p.Name
		local px = p:GetAttribute("PivotX") :: number?
		return {
			part = p,
			logical = logical,
			rel = origin:ToObjectSpace(p.CFrame),
			pivot = if px
				then Vector3.new(px, p:GetAttribute("PivotY") :: number, p:GetAttribute("PivotZ") :: number) * rig.scale
				else nil,
		}
	end
	local lod0: { [BasePart]: boolean } = {}
	for _, p in built.lod0 do
		lod0[p] = true
	end
	for _, p in rig.art:GetChildren() do
		if p:IsA("BasePart") then
			local r = rec(p)
			if r.pivot and not rig.pivots[r.logical] then
				rig.pivots[r.logical] = r.pivot
			end
			local isLod1 = table.find(built.lod1, p) ~= nil
			if isLod1 then
				table.insert(rig.far, r)
			elseif lod0[p] then
				table.insert(rig.near, r)
			else
				table.insert(rig.near, r)
				table.insert(rig.far, r)
			end
		end
	end
end

local function attach(host: Instance)
	if rigs[host] then
		return
	end
	local carried = host:IsA("BasePart")
	local root: BasePart? = if carried then host :: BasePart else (host :: Model).PrimaryPart
	if not root and not carried then
		-- The tag can replicate before the model's children: wait for the Root the server moves.
		local r = host:WaitForChild("Root", 10)
		root = if r and r:IsA("BasePart") then r else nil
		if not root and host.Parent then
			warn(`[Creatures] no Root replicated for {host:GetFullName()}; it stays without art`)
		end
	end
	if not root or rigs[host] then
		return
	end
	local species = host:GetAttribute("Species")
	local variant = host:GetAttribute("Variant")
	local key = type(species) == "string" and KEYS[species] or nil
	if not key then
		return
	end
	-- An equipped skin (TASK-0047): per-part tints/materials from the catalog, only for a compatible species.
	local opts: ArtLoader.Options = { castShadow = not carried }
	local skinId = host:GetAttribute("Skin")
	local skin = if type(skinId) == "string" then Cosmetics.ById[skinId] else nil
	if skin and skin.category == "Skin" and CosmeticRules.compatible(skin, species :: string) then
		opts.tint = skin.look.tint
		local mats: { [string]: Enum.Material } = {}
		for part, name in (skin.look.material or {}) :: { [string]: string } do
			local ok, m = pcall(function()
				return (Enum.Material :: any)[name]
			end)
			if ok and m then
				mats[part] = m
			end
		end
		opts.material = mats
	end
	local built = ArtLoader.build(key, opts)
	if built and rigs[host] then -- attached by another path while this one was building
		built.model:Destroy()
		return
	end
	if not built or not host.Parent then
		if built then
			built.model:Destroy()
		end
		return
	end
	if opts.tint then
		for logical, parts in built.parts do
			local t = (opts.tint :: { [string]: Color3 })[logical]
			if t then
				for _, p in parts do
					p:SetAttribute("SkinTint", t)
				end
			end
		end
	end
	applyVariant(built, if type(variant) == "string" then variant else "Normal")
	local scale = if carried
		then (CARRY_SCALE[species :: string] or 0.3)
		else ((host:GetAttribute("ArtScale") :: number?) or 1)
	local art = built.model
	art.Name = "CreatureArt"
	if scale ~= 1 then
		art:ScaleTo(scale)
	end
	art:PivotTo(CFrame.new())
	local spec = ArtLoader.spec(key)
	local rig: Rig = {
		host = host,
		root = root,
		art = art,
		species = species :: string,
		scale = scale,
		display = host:GetAttribute("Display") == true,
		carried = carried,
		near = {},
		far = {},
		lodFar = false,
		lodDistance = ((spec and spec.attrs.LodDistance) or 60) * math.max(scale, 0.5),
		lastPos = root.Position,
		speed = 0,
		phase = 0,
		seed = math.random() * 100,
		tick = math.random(0, 3), -- staggers the far-range throttle across rigs
		pivots = {},
	}
	record(rig, built)
	for _, r in rig.far do
		if not table.find(rig.near, r) then
			r.part.Parent = nil
		end
	end
	art.Parent = host
	rigs[host] = rig
	table.insert(list, rig)
	local auraId = host:GetAttribute("Aura")
	local aura = if type(auraId) == "string" then Cosmetics.ById[auraId] else nil
	if aura and aura.category == "Aura" then
		rig.aura = Effects.aura(root, aura.look, scale)
	end
end

local function detach(host: Instance)
	local rig = rigs[host]
	if not rig then
		return
	end
	rigs[host] = nil
	local i = table.find(list, rig)
	if i then
		table.remove(list, i)
	end
	for _, r in rig.far do
		r.part:Destroy()
	end
	for _, r in rig.near do
		r.part:Destroy()
	end
	rig.art:Destroy()
	if rig.aura then
		rig.aura:Destroy()
	end
end

-- Per-species pose: returns the whole-body offset and a function giving each logical part's local motion.
local function pose(rig: Rig, t: number): (CFrame, (string) -> CFrame)
	local s = rig.scale
	local move = math.clamp(rig.speed / 8, 0, 1.3)
	local ph = rig.phase
	local idle = t + rig.seed
	if rig.species == "Hound" then
		local bob = math.abs(math.sin(ph)) * 0.14 * move * s
		local body = CFrame.new(0, bob, 0) * CFrame.Angles(math.sin(ph * 2) * 0.03 * move, 0, 0)
		local swing = math.rad(34) * move
		local snap = if rig.speed > 10
			then math.max(0, math.sin(idle * 9))
			else math.max(0, math.sin(idle * 1.3) - 0.85) * 4
		return body,
			function(name: string): CFrame
				if name == "LegFL" or name == "LegBR" then
					return CFrame.Angles(math.sin(ph) * swing, 0, 0)
				elseif name == "LegFR" or name == "LegBL" then
					return CFrame.Angles(-math.sin(ph) * swing, 0, 0)
				elseif name == "Tail" then
					return CFrame.Angles(0.2 * move, math.sin(idle * (5 + 6 * move)) * 0.45, 0)
				elseif name == "Head" then
					return CFrame.Angles(
						math.sin(ph * 2) * 0.05 * move,
						math.sin(idle * 0.7) * 0.25 * (1 - move * 0.7),
						0
					)
				elseif name == "Jaw" then
					return CFrame.Angles(-0.32 * snap, math.sin(idle * 0.7) * 0.25 * (1 - move * 0.7), 0)
				elseif name == "Head2" then
					return CFrame.Angles(
						math.sin(idle * 3.1) * 0.08,
						math.sin(idle * 2.3) * 0.18,
						math.sin(idle * 4.7) * 0.06
					)
				elseif name == "EarL" or name == "EarR" then
					return CFrame.Angles(math.sin(ph * 2 + 1) * 0.15 * move, 0, math.sin(idle * 1.7) * 0.08)
				end
				return CFrame.identity
			end
	elseif rig.species == "Wisp" then
		-- The perch floats as one rigid piece (hands on the pole, toes on the tray). The head looks about and
		-- flinches back at speed; the lantern swings from its ring, lags behind motion and counters the lean. Swing
		-- stays inside +-0.33 rad, the range the art build proves clear of the pole (art/assets/wisp.py).
		local lean = 0.1 * move
		local body = CFrame.new(0, math.sin(idle * 1.6) * 0.12 * s, 0)
			* CFrame.Angles(
				lean + math.sin(idle * 1.1) * 0.035,
				math.sin(idle * 0.45) * 0.08,
				math.sin(idle * 0.9) * 0.045
			)
		local flinch = math.clamp((rig.speed - 9) / 10, 0, 1)
		return body,
			function(name: string): CFrame
				if name == "Head" or name == "Face" or name == "Twine" then
					local look = (math.sin(idle * 0.37) * 0.22 + math.sin(idle * 0.11) * 0.1) * (1 - move * 0.6)
					return CFrame.Angles(
						math.sin(idle * 0.8) * 0.05 - 0.14 * flinch,
						look,
						math.sin(idle * 0.53) * 0.07
					)
				elseif name == "Lamp" or name == "LampGlow" then
					local swingX = math.sin(idle * 1.9) * 0.07 - lean * 1.6 - 0.1 * move
					local swingZ = math.sin(idle * 1.4 + 1.2) * 0.06 - math.sin(idle * 0.9) * 0.045
					return CFrame.Angles(math.clamp(swingX, -0.33, 0.33), 0, math.clamp(swingZ, -0.33, 0.33))
				end
				return CFrame.identity
			end
	elseif rig.species == "Gentleman" then
		local body = CFrame.new(0, math.sin(idle * 1.4) * 0.12 * s, 0)
			* CFrame.Angles(0, 0, math.sin(idle * 0.9) * 0.03)
		local swing = math.rad(16) * move
		return body,
			function(name: string): CFrame
				if name == "LegL" then
					return CFrame.Angles(math.sin(ph) * swing, 0, 0)
				elseif name == "LegR" then
					return CFrame.Angles(-math.sin(ph) * swing, 0, 0)
				elseif name == "ArmL" then
					return CFrame.Angles(
						math.sin(idle * 1.1) * 0.12 - math.sin(ph) * swing * 0.6,
						0,
						math.sin(idle * 1.9) * 0.05
					)
				elseif name == "ArmR" then
					return CFrame.Angles(math.sin(ph) * swing * 0.5, 0, 0)
				elseif name == "Hat" then
					local lift = 0.18 + math.sin(idle * 1.6) * 0.14
					return CFrame.new(0, lift * s, 0)
						* CFrame.Angles(math.sin(idle * 0.8) * 0.08, 0, math.sin(idle * 0.6) * 0.06)
				end
				return CFrame.identity
			end
	else -- BellWraith
		local body = CFrame.new(0, math.sin(idle * 1.2) * 0.35 * s, 0)
			* CFrame.Angles(math.sin(idle * 0.9) * 0.05 + 0.1 * move, 0, math.sin(idle * 1.1) * 0.07)
		return body,
			function(name: string): CFrame
				if name == "Clapper" then
					return CFrame.Angles(math.sin(idle * 2.2) * 0.18, 0, math.sin(idle * 1.7) * 0.15)
				elseif string.sub(name, 1, 6) == "Ribbon" then
					local k = tonumber(string.sub(name, 7)) or 0
					return CFrame.Angles(
						math.sin(idle * 1.5 + k) * 0.1 + 0.15 * move,
						0,
						math.sin(idle * 1.2 + k * 1.7) * 0.08
					)
				elseif name == "ArmL" or name == "ArmR" then
					local side = if name == "ArmL" then 1 else -1
					return CFrame.Angles(
						math.sin(idle * 1.3 + side) * 0.18 - 0.25 * move,
						0,
						side * math.sin(idle * 0.9) * 0.1
					)
				end
				return CFrame.identity
			end
	end
end

local parts: { BasePart } = {}
local cframes: { CFrame } = {}

local function step(dt: number)
	local cam = Workspace.CurrentCamera
	local eye = if cam then cam.CFrame.Position else Vector3.zero
	local t = os.clock()
	table.clear(parts)
	table.clear(cframes)
	for i = #list, 1, -1 do
		local rig = list[i]
		if not rig.host.Parent or not rig.root.Parent then
			detach(rig.host)
			continue
		end
		local rootCF = rig.root.CFrame
		local pos = rootCF.Position
		local dist = (pos - eye).Magnitude
		rig.tick += 1
		-- Far creatures animate at a quarter rate; the walk phase still advances every frame.
		local flat = Vector3.new(pos.X - rig.lastPos.X, 0, pos.Z - rig.lastPos.Z).Magnitude
		local v = if dt > 0 then flat / dt else 0
		rig.speed += (math.min(v, 30) - rig.speed) * math.min(1, dt * 6)
		rig.lastPos = pos
		local stride = if rig.species == "Hound" then 2.6 else 3.2
		rig.phase += dt * rig.speed / (stride * rig.scale) * math.pi
		if rig.display then
			rig.speed = 0
		end
		local wantFar = dist > rig.lodDistance * (if rig.lodFar then 0.9 else 1.1) -- hysteresis at the boundary
		if wantFar ~= rig.lodFar then
			rig.lodFar = wantFar
			local show: { PartRec } = if wantFar then rig.far else rig.near
			local hide: { PartRec } = if wantFar then rig.near else rig.far
			for _, r in hide do
				if not table.find(show, r) then
					r.part.Parent = nil
				end
			end
			for _, r in show do
				r.part.Parent = rig.art
			end
		end
		if dist > 140 and rig.tick % 4 ~= 0 then
			continue
		end
		local body, local_ = pose(rig, t)
		local base = if rig.carried
			then rootCF * CFrame.new(JAR_OFFSET[rig.species] or Vector3.zero) * body
			else rootCF * body
		local parents = PARENT[rig.species] or {}
		local visible: { PartRec } = if rig.lodFar then rig.far else rig.near
		for _, r in visible do
			local joint = about(r.pivot, local_(r.logical))
			local parent = parents[r.logical]
			if parent then
				joint = about(rig.pivots[parent], local_(parent)) * joint
			end
			table.insert(parts, r.part)
			table.insert(cframes, base * joint * r.rel)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

local started = false
function Creatures.start()
	if started then
		return
	end
	started = true
	for _, tag in { "Creature", "CarriedCreature" } do
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			task.spawn(attach, inst)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(detach)
		for _, inst in CollectionService:GetTagged(tag) do
			task.spawn(attach, inst)
		end
	end
	local warned = false
	RunService.RenderStepped:Connect(function(dt)
		local ok, err = pcall(function()
			step(dt)
		end)
		if not ok and not warned then
			warned = true
			warn(`[Creatures] {err}`)
		end
	end)
end

-- Exposed for the Studio showroom and specs: applies a natural variant look to a built creature.
Creatures.applyVariant = applyVariant

function Creatures.count(): number
	return #list
end

-- Jar placement for carried creatures: the art origin sits at the jar centre plus a per-species offset.
function Creatures.jarOffset(species: string): Vector3
	return JAR_OFFSET[species] or Vector3.zero
end

return Creatures
