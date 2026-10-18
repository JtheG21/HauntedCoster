--!strict
-- Rare capture finisher player (TASK-0054): maps the finisher sequence's cues onto camera, lighting,
-- particles and meshes through SequencePlayer (ADR-0012). Cosmetic and client-side only; the runner always
-- undoes every cue, so the camera, input and lighting return to normal on finish, cancel or error.
-- Meshes and textures come from Config/FinisherAssets (rights unverified there). Anything that fails to
-- load is skipped, never an error: call RareCaptureFinisher.preload() once, before the first run, to have
-- the meshes ready (creating a MeshPart yields, which a running sequence must not do).

local ContextActionService = game:GetService("ContextActionService")
local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Finisher = require(ReplicatedStorage.Shared.Config.RareCaptureFinisher)
local Assets = require(ReplicatedStorage.Shared.Config.FinisherAssets)
local FinisherRules = require(ReplicatedStorage.Shared.Rules.FinisherRules)
local Sequence = require(ReplicatedStorage.Shared.Sequence)
local SequencePlayer = require(script.Parent.SequencePlayer)

local RareCaptureFinisher = {}

export type Options = { reduced: boolean?, destination: Vector3?, onDone: (() -> ())? }

local LOCKED_ACTIONS = {
	Enum.PlayerActions.CharacterForward,
	Enum.PlayerActions.CharacterBackward,
	Enum.PlayerActions.CharacterLeft,
	Enum.PlayerActions.CharacterRight,
	Enum.PlayerActions.CharacterJump,
}

local meshTemplates: { [string]: MeshPart } = {}
local preloaded = false

-- Loads every mesh once; yields. Safe to call again; failures are skipped.
function RareCaptureFinisher.preload()
	if preloaded then
		return
	end
	preloaded = true
	local ids: { [string]: number } = Assets.Meshes
	for name, id in ids do
		local ok, mesh = pcall(function()
			return InsertService:CreateMeshPartAsync(
				"rbxassetid://" .. id,
				Enum.CollisionFidelity.Box,
				Enum.RenderFidelity.Automatic
			)
		end)
		if ok and mesh then
			meshTemplates[name] = mesh
		else
			warn(`RareCaptureFinisher: mesh {name} ({id}) did not load, skipping it`)
		end
	end
end

-- A neon, non-colliding copy of a preloaded mesh, or nil when it is not available.
local function mesh(name: string, color: Color3, transparency: number): MeshPart?
	local template = meshTemplates[name]
	if not template then
		return nil
	end
	local m = template:Clone()
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.CastShadow = false
	m.Material = Enum.Material.Neon
	m.Color = color
	m.Transparency = transparency
	return m
end

local function color(c: any): Color3
	return Color3.new(c[1], c[2], c[3])
end

local function emitter(
	parent: Instance,
	c: Color3,
	texture: string?,
	rate: number,
	speed: NumberRange,
	life: NumberRange,
	size: number
): ParticleEmitter
	local p = Instance.new("ParticleEmitter")
	p.Color = ColorSequence.new(c)
	p.LightEmission = 0.8
	p.Lifetime = life
	p.Speed = speed
	p.SpreadAngle = Vector2.new(180, 180)
	p.Size = NumberSequence.new(size, 0)
	p.Rate = rate
	if texture then
		p.Texture = texture
	end
	p.Parent = parent
	return p
end

-- Runs fn every frame until the returned stop function is called.
local function every(fn: (t: number, dt: number) -> ()): () -> ()
	local started = os.clock()
	local conn = RunService.Heartbeat:Connect(function(dt)
		fn(os.clock() - started, dt)
	end)
	return function()
		conn:Disconnect()
	end
end

-- Camera rig: every active camera cue contributes; the latest one with a position decides where the
-- camera sits, the latest with a fov sets the field of view, shakes add up. Restores the camera when
-- the last camera cue stops.
local function makeCameraRig(target: BasePart, reduced: boolean)
	local active: { { id: string, startedAt: number, p: { [string]: any } } } = {}
	local conn: RBXScriptConnection? = nil
	local saved: { type: Enum.CameraType, fov: number }? = nil
	local fov = 70

	local function step(dt: number)
		local cam = Workspace.CurrentCamera
		if not cam or #active == 0 then
			return
		end
		local now = os.clock()
		local posCue, fovCue
		local shake = 0
		for _, a in active do
			if a.p.pos then
				posCue = a
			end
			if a.p.fov then
				fovCue = a
			end
			shake += FinisherRules.scale("shake", a.p.shake or 0, reduced)
		end
		local focus = target.Position + Vector3.new(0, 3, 0)
		if posCue then
			local p = posCue.p
			local angle = (now - posCue.startedAt) * 0.5
			local pos
			if p.pos == "low" then
				pos = target.Position + Vector3.new(math.cos(angle) * p.radius, 1.5, math.sin(angle) * p.radius)
			else
				pos = target.Position
					+ Vector3.new(math.cos(angle) * p.radius, p.height or 5, math.sin(angle) * p.radius)
			end
			local offset = Vector3.new(math.noise(now * 20, 1), math.noise(now * 20, 2), math.noise(now * 20, 3))
				* shake
			cam.CFrame = CFrame.lookAt(pos + offset, focus)
		end
		if fovCue then
			local goal = FinisherRules.fov(70, fovCue.p.fov, reduced)
			fov += (goal - fov) * math.min(1, dt * 3)
			cam.FieldOfView = fov
		end
	end

	return function(cue: Sequence.Cue): (() -> ())?
		local cam = Workspace.CurrentCamera
		if not cam or not RunService:IsClient() then
			return nil
		end
		if not saved then
			saved = { type = cam.CameraType, fov = cam.FieldOfView }
			fov = cam.FieldOfView
			cam.CameraType = Enum.CameraType.Scriptable
			conn = RunService.RenderStepped:Connect(step)
		end
		local entry = { id = cue.id, startedAt = os.clock(), p = (cue.params or {}) :: { [string]: any } }
		table.insert(active, entry)
		return function()
			local i = table.find(active, entry)
			if i then
				table.remove(active, i)
			end
			if #active == 0 and saved then
				if conn then
					conn:Disconnect()
					conn = nil
				end
				cam.CameraType = saved.type
				cam.FieldOfView = saved.fov
				saved = nil
			end
		end
	end
end

-- Height of the ground under the monster, or a sensible guess when nothing is hit.
local function groundY(fx: Folder, target: BasePart): number
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { fx, target }
	local hit = Workspace:Raycast(target.Position + Vector3.new(0, 3, 0), Vector3.new(0, -80, 0), params)
	return if hit then hit.Position.Y + 0.15 else target.Position.Y - 3
end

local function makeEffects(
	fx: Folder,
	anchor: BasePart,
	ground: number,
	destination: Vector3,
	reduced: boolean
): SequencePlayer.Handler
	local floorAt = Vector3.new(anchor.Position.X, ground, anchor.Position.Z)
	return function(cue)
		local p: { [string]: any } = cue.params or {}
		local kind = p.effect
		if kind == "lock" then
			if not RunService:IsClient() then
				return nil
			end
			ContextActionService:BindActionAtPriority("FinisherLock", function()
				return Enum.ContextActionResult.Sink
			end, false, 3000, table.unpack(LOCKED_ACTIONS))
			return function()
				ContextActionService:UnbindAction("FinisherLock")
			end
		elseif kind == "tint" then
			local cc = Instance.new("ColorCorrectionEffect")
			cc.Name = "FinisherTint_" .. cue.id
			cc.Parent = Lighting
			TweenService:Create(cc, TweenInfo.new(0.6), { TintColor = color(p.color), Brightness = p.brightness or 0 })
				:Play()
			return function()
				cc:Destroy()
			end
		elseif kind == "flash" then
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
		elseif kind == "rune" then
			-- a magic circle on the ground: mandala texture over spinning concentric rings, recoloured per phase
			local size: number = p.size or 24
			local disc = Instance.new("Part")
			disc.Name = "FinisherRune"
			disc.Anchored = true
			disc.CanCollide = false
			disc.CanQuery = false
			disc.Transparency = 1
			disc.Size = Vector3.new(size, 0.1, size)
			disc.CFrame = CFrame.new(floorAt)
			local gui = Instance.new("SurfaceGui")
			gui.Face = Enum.NormalId.Top
			gui.LightInfluence = 0
			gui.Brightness = 3
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
			disc.Parent = fx
			local rings = mesh("groundRings", Color3.new(1, 1, 1), 0.6)
			if rings then
				rings.Size = Vector3.new(size * 0.9, 0.08, size * 0.9)
				rings.CFrame = CFrame.new(floorAt + Vector3.new(0, 0.05, 0))
				rings.Parent = fx
			end
			local colors: { any } = p.colors or {}
			local stop = every(function(t)
				local c = color(colors[1].c)
				for _, key in colors do
					if t >= key.at then
						c = color(key.c)
					end
				end
				img.ImageColor3 = c
				img.Rotation = (t * 25) % 360
				img.ImageTransparency = 1 - math.min(t / 0.8, 1) * 0.15
				if rings then
					rings.Color = c
					rings.CFrame = CFrame.new(floorAt + Vector3.new(0, 0.05, 0)) * CFrame.Angles(0, -t * 1.5, 0)
					rings.Transparency = 1 - math.min(t / 0.8, 1) * 0.45
				end
			end)
			return function()
				stop()
				disc:Destroy()
				if rings then
					rings:Destroy()
				end
			end
		elseif kind == "shockwave" then
			-- a flat ring that rushes outward along the ground and fades
			local ring = mesh("shockRing", color(p.color), 0)
			if not ring then
				return nil
			end
			local reach: number = p.size or 40
			ring.Size = Vector3.new(4, 0.3, 4)
			ring.CFrame = CFrame.new(floorAt + Vector3.new(0, 0.6, 0))
			ring.Parent = fx
			local duration: number = cue.duration or 1
			local stop = every(function(t)
				local k = math.clamp(t / duration, 0, 1)
				local e = 1 - (1 - k) ^ 3
				local s = 4 + (reach - 4) * e
				ring.Size = Vector3.new(s, 0.3 + 1.2 * (1 - k), s)
				ring.Transparency = k ^ 1.5
			end)
			return function()
				stop()
				ring:Destroy()
			end
		elseif kind == "vortex" then
			-- a helix that spins around the pillar during the peak
			local helix = mesh("vortex", color(p.color), 0.2)
			if not helix then
				return nil
			end
			helix.Size = Vector3.new(24, 52, 24)
			helix.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 18, 0))
			helix.Parent = fx
			local stop = every(function(t)
				helix.CFrame = CFrame.new(anchor.Position + Vector3.new(0, 18, 0)) * CFrame.Angles(0, t * 5, 0)
			end)
			return function()
				stop()
				helix:Destroy()
			end
		elseif kind == "aura" then
			local c = color(p.color)
			local glow = emitter(
				anchor,
				c,
				Assets.Textures.glow,
				FinisherRules.scale("rate", p.rate or 20, reduced),
				NumberRange.new(2, 7),
				NumberRange.new(0.9, 1.7),
				2.2
			)
			local spark = emitter(
				anchor,
				Color3.new(1, 1, 1),
				Assets.Textures.sparkle,
				FinisherRules.scale("rate", (p.rate or 20) * 0.5, reduced),
				NumberRange.new(3, 9),
				NumberRange.new(0.8, 1.5),
				0.9
			)
			return function()
				glow:Destroy()
				spark:Destroy()
			end
		elseif kind == "sparks" then
			-- the lightning stack: two bolt textures flickering around the pillar
			local rate = FinisherRules.scale("rate", p.rate or 30, reduced)
			local a = emitter(
				anchor,
				Color3.fromRGB(190, 230, 255),
				Assets.Textures.lightningA,
				rate * 0.5,
				NumberRange.new(12, 30),
				NumberRange.new(0.12, 0.3),
				6
			)
			local b = emitter(
				anchor,
				Color3.fromRGB(150, 200, 255),
				Assets.Textures.lightningB,
				rate * 0.5,
				NumberRange.new(12, 30),
				NumberRange.new(0.12, 0.3),
				7
			)
			a.Rotation = NumberRange.new(0, 360)
			b.Rotation = NumberRange.new(0, 360)
			return function()
				a:Destroy()
				b:Destroy()
			end
		elseif kind == "burst" then
			local e = emitter(
				anchor,
				color(p.color),
				Assets.Textures.sparkle,
				0,
				NumberRange.new(10, 26),
				NumberRange.new(0.6, 1.2),
				2
			)
			e:Emit(math.floor(FinisherRules.scale("rate", p.count or 40, reduced)))
			local flare = emitter(
				anchor,
				color(p.color),
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
		elseif kind == "pillar" then
			local height: number = p.height or 60
			local pl: BasePart
			local tube = mesh("tube", Color3.new(1, 1, 1), 0.55)
			if tube then
				tube.Size = Vector3.new(4, height, 4)
				pl = tube
			else
				local fallback = Instance.new("Part")
				fallback.Anchored = true
				fallback.CanCollide = false
				fallback.CanQuery = false
				fallback.Material = Enum.Material.Neon
				fallback.Color = Color3.new(1, 1, 1)
				fallback.Size = Vector3.new(3.5, height, 3.5)
				pl = fallback
			end
			pl.Name = "FinisherPillar"
			pl.Position = anchor.Position + Vector3.new(0, height / 2 - 4, 0)
			local light = Instance.new("PointLight")
			light.Range = 40
			light.Brightness = 2
			light.Parent = pl
			pl.Transparency = 1
			pl.Parent = fx
			TweenService:Create(pl, TweenInfo.new(0.5), { Transparency = 0.55 }):Play()
			return function()
				pl:Destroy()
			end
		elseif kind == "orb" then
			local orb = Instance.new("Part")
			orb.Name = "FinisherOrb"
			orb.Shape = Enum.PartType.Ball
			orb.Anchored = true
			orb.CanCollide = false
			orb.CanQuery = false
			orb.Material = Enum.Material.Neon
			orb.Color = color(p.color)
			orb.Size = Vector3.new(2.2, 2.2, 2.2)
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Position = Vector3.new(0, 1.2, 0)
			a1.Position = Vector3.new(0, -1.2, 0)
			a0.Parent, a1.Parent = orb, orb
			local trail = Instance.new("Trail")
			trail.Attachment0, trail.Attachment1 = a0, a1
			trail.Color = ColorSequence.new(color(p.color))
			trail.Lifetime = 0.5
			trail.LightEmission = 0.8
			trail.Transparency = NumberSequence.new(0.2, 1)
			trail.Parent = orb
			-- a rotating glow sprite that follows the orb
			local glowGui = Instance.new("BillboardGui")
			glowGui.AlwaysOnTop = false
			glowGui.LightInfluence = 0
			glowGui.Size = UDim2.fromOffset(0, 0)
			glowGui.Parent = orb
			local glow = Instance.new("ImageLabel")
			glow.BackgroundTransparency = 1
			glow.AnchorPoint = Vector2.new(0.5, 0.5)
			glow.Position = UDim2.fromScale(0.5, 0.5)
			glow.Size = UDim2.fromScale(1, 1)
			glow.Image = Assets.Textures.sparkle
			glow.ImageColor3 = color(p.color)
			glow.Parent = glowGui
			-- a wind ring around the monster that tightens with the orbit
			local wind = mesh("windRing", color(p.color), 0.55)
			if wind then
				wind.Parent = fx
			end
			local orbitTime: number = p.orbitTime or 3.4
			local total: number = cue.duration or 4
			local center = anchor.Position + Vector3.new(0, 7, 0)
			local started = os.clock()
			local breakPos: Vector3? = nil
			local function place(t: number)
				local o = FinisherRules.orbit(t, orbitTime)
				orb.Position = center + Vector3.new(o.x, o.y, o.z)
				local s = o.size
				orb.Size = Vector3.new(s, s, s)
				trail.Lifetime = 0.25 + 0.65 * o.u
				a0.Position = Vector3.new(0, s * 0.45, 0)
				a1.Position = Vector3.new(0, -s * 0.45, 0)
				glowGui.Size = UDim2.fromScale(s * 2.2, s * 2.2)
				glow.Rotation = (t * 200) % 360
				if wind then
					local d = o.radius * 2.2
					wind.Size = Vector3.new(d, 2.4 * (o.radius / FinisherRules.ORBIT.r0) + 0.4, d)
					wind.CFrame = CFrame.new(center)
						* CFrame.Angles(0, 0, o.az)
						* CFrame.Angles(0, o.ay, 0)
						* CFrame.Angles(o.ax, 0, 0)
						* CFrame.Angles(math.pi / 2, 0, 0)
						* CFrame.Angles(0, t * 6, 0)
					wind.Transparency = 0.7 - 0.3 * o.u
				end
			end
			place(0)
			orb.Parent = fx
			local conn = RunService.Heartbeat:Connect(function()
				local t = os.clock() - started
				if t <= orbitTime then
					place(t)
					return
				end
				if not breakPos then
					-- too tight and too fast to hold: a burst of sparks and a radial flare as it lets go
					breakPos = orb.Position
					if wind then
						wind:Destroy()
						wind = nil
					end
					local sparks = emitter(
						orb,
						color(p.color),
						Assets.Textures.sparkle,
						0,
						NumberRange.new(15, 35),
						NumberRange.new(0.2, 0.5),
						1.2
					)
					sparks:Emit(math.floor(FinisherRules.scale("rate", 30, reduced)))
					local flare = emitter(
						orb,
						color(p.color),
						Assets.Textures.radialBurst,
						0,
						NumberRange.new(0, 0),
						NumberRange.new(0.35, 0.35),
						18
					)
					flare.SpreadAngle = Vector2.new(0, 0)
					flare:Emit(1)
				end
				local k = (t - orbitTime) / math.max(total - orbitTime, 0.1)
				local e = FinisherRules.snap(k)
				orb.Position = (breakPos :: Vector3):Lerp(destination, e)
				local s = 4.4 * (1 - e) + 0.8 * e
				orb.Size = Vector3.new(s, s, s)
				glowGui.Size = UDim2.fromScale(s * 2.2, s * 2.2)
			end)
			return function()
				conn:Disconnect()
				orb:Destroy()
				if wind then
					wind:Destroy()
				end
			end
		end
		return nil
	end
end

-- Builds the finisher around `target` (the captured monster's position) without starting it. Call
-- :play() to run it from Heartbeat, or :step(dt) to drive it by hand. :stop() cancels and cleans up.
function RareCaptureFinisher.new(target: BasePart, opts: Options?): SequencePlayer.Player
	local o: Options = opts or {}
	local reduced = o.reduced == true
	local fx = Instance.new("Folder")
	fx.Name = "FinisherFx"
	fx.Parent = Workspace
	local anchor = Instance.new("Part")
	anchor.Name = "FinisherAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = target.Position
	anchor.Parent = fx
	local destination = o.destination or (target.Position + Vector3.new(0, 1.5, 12))
	local handlers: SequencePlayer.Handlers = {
		camera = makeCameraRig(target, reduced),
		effect = makeEffects(fx, anchor, groundY(fx, target), destination, reduced),
	}
	return SequencePlayer.new(Finisher, handlers, function()
		fx:Destroy()
		if o.onDone then
			o.onDone()
		end
	end)
end

function RareCaptureFinisher.play(target: BasePart, opts: Options?): SequencePlayer.Player
	local player = RareCaptureFinisher.new(target, opts)
	player:play()
	return player
end

return RareCaptureFinisher
