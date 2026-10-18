--!strict
-- Studio test pads (TASK-0056): judge a texture, icon or effect in context instead of from a preview image.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "TestPads", pad = "vfx", texture = "rbxassetid://..." })
-- args: pad = "ui" | "vfx" | "surface" | "all" (default), texture = an rbxassetid or rbxasset://textures id (a built-in
-- default is used otherwise), keep = true leaves the pad built and returns camera positions to capture from
-- (clean up later with args.cleanup = true). Every pad prints one metrics line and, unless kept, is removed again
-- and the place is checked against its baseline. The UI pad needs a client (PlayerGui); the others run anywhere.
-- Numbers here are aids; jg judges the look. A texture upload is always jg's per-action decision.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")

local PadRules = require(ReplicatedStorage.Shared.Rules.PadRules)

local DEFAULTS = {
	ui = "rbxasset://textures/ui/GuiImagePlaceholder.png",
	vfx = "rbxasset://textures/particles/sparkles_main.dds",
	surface = "rbxasset://textures/SpawnLocation.png",
}
-- Far from any real map; assumed empty (checked only in scratch places), so keep pads out of a populated place.
local ORIGIN = { vfx = Vector3.new(0, 40, -300), surface = Vector3.new(100, 10, -300) }
local FRAME_SAMPLES = 30

-- Everything a pad can add to: the world, the default GUI, and this client's own GUI when there is one.
local function footprint(): number
	local player = Players.LocalPlayer
	local playerGui = if player then player:FindFirstChild("PlayerGui") else nil
	return #Workspace:GetDescendants()
		+ #StarterGui:GetDescendants()
		+ (if playerGui then #playerGui:GetDescendants() else 0)
end

type Handle = {
	name: string,
	root: Instance,
	metrics: { [string]: any },
	cameras: { { distance: number, from: Vector3, to: Vector3 } },
}

local function rgb(c: { number }): Color3
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function averageFrameMs(): number
	local total = 0
	for _ = 1, FRAME_SAMPLES do
		total += RunService.Heartbeat:Wait()
	end
	return total / FRAME_SAMPLES * 1000
end

local function buildUi(texture: string): Handle
	local layout = PadRules.uiLayout()
	local gui = Instance.new("ScreenGui")
	gui.Name = "TestPad_UI"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	local player = Players.LocalPlayer
	gui.Parent = if player then player:WaitForChild("PlayerGui") else StarterGui
	-- one background band per row, then each image at its real pixel size
	local rowHeight = PadRules.UI_SIZES[#PadRules.UI_SIZES] + PadRules.GUTTER
	for i, background in PadRules.BACKGROUND_ORDER do
		local band = Instance.new("Frame")
		band.BorderSizePixel = 0
		band.BackgroundColor3 = rgb(PadRules.BACKGROUNDS[background])
		band.Position = UDim2.fromOffset(0, (i - 1) * rowHeight)
		band.Size = UDim2.fromOffset(layout.width, rowHeight + (if i == 1 then 0 else PadRules.GUTTER))
		band.Parent = gui
	end
	local images: { Instance } = {}
	for _, cell in layout.cells do
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Image = texture
		img.Position = UDim2.fromOffset(cell.x, cell.y)
		img.Size = UDim2.fromOffset(cell.size, cell.size)
		img.Parent = gui
		table.insert(images, img)
	end
	if player then
		-- a server has nothing to render and PreloadAsync can hang there
		game:GetService("ContentProvider"):PreloadAsync(images)
	end
	local loaded = 0
	for _, img in images do
		if (img :: ImageLabel).IsLoaded then
			loaded += 1
		end
	end
	return {
		name = "ui",
		root = gui,
		metrics = { cells = #layout.cells, loaded = loaded, widthPx = layout.width, heightPx = layout.height },
		cameras = {},
	}
end

local function buildVfx(texture: string): Handle
	local folder = Instance.new("Folder")
	folder.Name = "TestPad_Vfx"
	local floor = Instance.new("Part")
	floor.Anchored = true
	floor.Size = Vector3.new(120, 1, 120)
	floor.Position = ORIGIN.vfx - Vector3.new(0, 4, 0)
	floor.Color = Color3.fromRGB(70, 74, 86)
	floor.Parent = folder
	local source = Instance.new("Part")
	source.Name = "Source"
	source.Anchored = true
	source.CanCollide = false
	source.Transparency = 1
	source.Size = Vector3.one
	source.Position = ORIGIN.vfx
	source.Parent = folder
	local rate = 40
	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = texture
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(1.2, 1.8)
	emitter.Speed = NumberRange.new(3, 6)
	emitter.Size = NumberSequence.new(2, 0)
	emitter.LightEmission = 1
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Parent = source
	folder.Parent = Workspace
	local ok, why = PadRules.vfxWithinBudget(1, rate)
	local cameras = {}
	for _, o in PadRules.vfxCameraOffsets() do
		table.insert(
			cameras,
			{ distance = o.distance, from = ORIGIN.vfx + Vector3.new(o.x, o.y, o.z), to = ORIGIN.vfx }
		)
	end
	task.wait(1) -- let the stream fill before measuring
	return {
		name = "vfx",
		root = folder,
		metrics = {
			emitters = 1,
			ratePerSecond = rate,
			withinBudget = ok,
			over = table.concat(why, "; "),
			frameMs = averageFrameMs(),
		},
		cameras = cameras,
	}
end

local function buildSurface(texture: string): Handle
	local folder = Instance.new("Folder")
	folder.Name = "TestPad_Surface"
	local wall = Instance.new("Part")
	wall.Name = "Wall"
	wall.Anchored = true
	wall.Size = Vector3.new(PadRules.WALL.width, PadRules.WALL.height, PadRules.WALL.depth)
	wall.Position = ORIGIN.surface
	wall.Color = Color3.fromRGB(200, 200, 200)
	wall.Parent = folder
	local face = Instance.new("Texture")
	face.Texture = texture
	face.Face = Enum.NormalId.Back -- the +Z face, the side the pad's cameras look from
	face.StudsPerTileU = 6
	face.StudsPerTileV = 6
	face.Parent = wall
	local x = ORIGIN.surface.X - PadRules.WALL.width / 2 - 6
	for _, name in { "white", "grey", "black" } do
		local swatch = Instance.new("Part")
		swatch.Name = "Swatch_" .. name
		swatch.Anchored = true
		swatch.Size = Vector3.new(4, 4, 1)
		swatch.Position = Vector3.new(
			x,
			ORIGIN.surface.Y - 4 + (if name == "grey" then 4.5 elseif name == "black" then 9 else 0),
			ORIGIN.surface.Z
		)
		swatch.Color = rgb(PadRules.SWATCHES[name])
		swatch.Parent = folder
	end
	folder.Parent = Workspace
	local ambient = Lighting.Ambient
	return {
		name = "surface",
		root = folder,
		metrics = {
			wallStuds = `{PadRules.WALL.width}x{PadRules.WALL.height}`,
			clockTime = Lighting.ClockTime,
			brightness = Lighting.Brightness,
			ambient = string.format(
				"%02x%02x%02x",
				math.round(ambient.R * 255),
				math.round(ambient.G * 255),
				math.round(ambient.B * 255)
			),
		},
		cameras = { { distance = 25, from = ORIGIN.surface + Vector3.new(-4, 0, 25), to = ORIGIN.surface } },
	}
end

local builders = { ui = buildUi, vfx = buildVfx, surface = buildSurface }

local function removeAll()
	for _, name in { "TestPad_Vfx", "TestPad_Surface" } do
		local f = Workspace:FindFirstChild(name)
		if f then
			f:Destroy()
		end
	end
	local player = Players.LocalPlayer
	for _, parent in { StarterGui, if player then player:FindFirstChild("PlayerGui") else nil } do
		local g = parent and parent:FindFirstChild("TestPad_UI")
		if g then
			g:Destroy()
		end
	end
end

return function(args: any): { [string]: any }
	local a: { [string]: any } = if type(args) == "table" then args else {}
	if a.cleanup == true then
		removeAll()
		return { passed = true, failed = 0, checks = {}, lines = {} }
	end
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local which: { string } = if a.pad == "ui"
			or a.pad == "vfx"
			or a.pad == "surface"
		then { a.pad }
		else { "vfx", "surface", "ui" }
	local lines: { string } = {}
	local cameras: { string } = {}
	for _, pad in which do
		local texture = a.texture or DEFAULTS[pad]
		check(`{pad}: texture id accepted`, PadRules.isTexture(texture), texture)
		if not PadRules.isTexture(texture) then
			continue
		end
		if pad == "ui" and not Players.LocalPlayer and not a.allowStarterGui then
			-- a server has no PlayerGui and nothing to render: the UI pad belongs on a client (execute_luau, Client).
			-- "all" simply skips it there; asking for it explicitly is a failure.
			if a.pad == "ui" then
				check("ui: runs on a client (or with allowStarterGui)", false, "no LocalPlayer")
			else
				table.insert(lines, PadRules.metricsLine("ui", { skipped = "needs a client" }))
			end
			continue
		end
		local descendantsBefore = footprint()
		local lightingBefore = #Lighting:GetChildren()
		local built, handle = pcall(builders[pad], texture)
		if not built then
			removeAll() -- a half-built pad must not stay behind
			check(`{pad}: builds`, false, handle)
			continue
		end
		table.insert(lines, PadRules.metricsLine(pad, handle.metrics))
		for _, c in handle.cameras do
			table.insert(cameras, `{pad} d={c.distance} from={c.from} to={c.to}`)
		end
		if pad == "ui" then
			check(
				"ui: every cell loaded its image",
				handle.metrics.loaded == handle.metrics.cells,
				`{handle.metrics.loaded}/{handle.metrics.cells}`
			)
		elseif pad == "vfx" then
			check("vfx: within the pad budget", handle.metrics.withinBudget == true, handle.metrics.over)
		end
		if a.keep ~= true then
			handle.root:Destroy()
			task.wait()
			check(
				`{pad}: back to baseline`,
				footprint() == descendantsBefore and #Lighting:GetChildren() == lightingBefore
			)
		end
	end
	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { passed = failed == 0, failed = failed, checks = checks, lines = lines, cameras = cameras }
end
