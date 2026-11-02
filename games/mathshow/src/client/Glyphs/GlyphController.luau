--!strict
-- GlyphController (TASK-0121): renders the hub glyphs this player can collect and asks the server for them.
-- Driven only by GlyphState: a glyph appears when its id is in `available` and goes when it leaves, and the counter shows
-- `count`. Walking within CollectRadius of a glyph sends one GlyphCollect for it per rendered lifetime; the client never
-- changes its own count. Positions come from the same GlyphSpawn attachments the server reads. The pickup burst is
-- cosmetic: pcall-isolated, fails inert and warns, and never touches collection.

local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GlyphConfig = require(Shared:WaitForChild("GlyphConfig"))
local GlyphRules = require(Shared:WaitForChild("GlyphRules"))
local Net = require(Shared:WaitForChild("Net"))

-- Client-only look and layout. Glyphs sit at the spawn point, which the map puts at chest height.
local GlyphTheme = table.freeze({
	PartSize = 1.2,
	Colour = table.freeze({ common = Color3.fromRGB(110, 220, 255), rare = Color3.fromRGB(255, 205, 90) }),
	SymbolColour = Color3.fromRGB(255, 255, 255),
	BillboardStuds = 2.4,
	BobStuds = 0.3,
	BobSeconds = 2.4,
	SpinRadiansPerSecond = 1.2,
	BurstSeconds = 0.35,
	BurstScale = 4,
	PickupSound = "rbxasset://sounds/electronicpingshort.wav",
	CounterSize = UDim2.fromOffset(150, 36),
	CounterPosition = UDim2.new(1, -16, 0, 64),
	CounterTextSize = 22,
	CounterFont = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold),
})

type Rendered = {
	part: BasePart,
	base: Vector3,
	rarity: GlyphRules.Rarity,
	phase: number,
	requested: boolean, -- GlyphCollect already sent for this lifetime
}

local GlyphController = {}

local started = false
local spawnById: { [string]: GlyphRules.Spawn } = {}
local indexById: { [string]: number } = {}
local rendered: { [string]: Rendered } = {}
local folder: Folder? = nil
local counter: TextLabel? = nil
local collectRemote: RemoteEvent? = nil

local function readSpawns()
	local hub = Workspace:WaitForChild("Hub", 30)
	if not hub then
		warn("[MathShow] GlyphController: Workspace.Hub never arrived; no glyphs")
		return
	end
	local records: { GlyphRules.SpawnRecord } = {}
	for _, tagged in CollectionService:GetTagged("GlyphSpawn") do
		if tagged:IsA("Attachment") and tagged:IsDescendantOf(hub) and tagged.Parent then
			local position = tagged.WorldPosition
			table.insert(records, {
				id = tagged.Parent.Name,
				rarity = tostring(tagged:GetAttribute("Rarity")),
				x = position.X,
				y = position.Y,
				z = position.Z,
			})
		end
	end
	table.sort(records, function(a, b)
		return a.id < b.id
	end)
	local spawns = GlyphRules.parseSpawns(records)
	for index, spawn in spawns do
		spawnById[spawn.id] = spawn
		indexById[spawn.id] = index
	end
end

local function symbolFor(id: string): string
	local index = indexById[id] or 1
	return GlyphConfig.Symbols[(index - 1) % #GlyphConfig.Symbols + 1]
end

local function makeGlyph(id: string, spawn: GlyphRules.Spawn, parent: Instance): Rendered
	local base = Vector3.new(spawn.position.x, spawn.position.y, spawn.position.z)
	local part = Instance.new("Part")
	part.Name = id
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.one * GlyphTheme.PartSize
	part.Material = Enum.Material.Neon
	part.Color = GlyphTheme.Colour[spawn.rarity]
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = CFrame.new(base)
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromScale(GlyphTheme.BillboardStuds, GlyphTheme.BillboardStuds)
	billboard.LightInfluence = 0
	billboard.Adornee = part
	billboard.Parent = part
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = symbolFor(id)
	label.TextScaled = true
	label.TextColor3 = GlyphTheme.SymbolColour
	label.FontFace = GlyphTheme.CounterFont
	label.Parent = billboard
	part.Parent = parent
	return { part = part, base = base, rarity = spawn.rarity, phase = (indexById[id] or 0) * 0.7, requested = false }
end

local function playPickup(position: Vector3, rarity: GlyphRules.Rarity)
	local burst = Instance.new("Part")
	burst.Name = "GlyphPickup"
	burst.Shape = Enum.PartType.Ball
	burst.Size = Vector3.one * GlyphTheme.PartSize
	burst.Material = Enum.Material.Neon
	burst.Color = GlyphTheme.Colour[rarity]
	burst.Anchored = true
	burst.CanCollide = false
	burst.CanQuery = false
	burst.CanTouch = false
	burst.CastShadow = false
	burst.CFrame = CFrame.new(position)
	burst.Parent = folder
	local sound = Instance.new("Sound")
	sound.SoundId = GlyphTheme.PickupSound
	sound.Parent = burst
	sound:Play()
	TweenService:Create(burst, TweenInfo.new(GlyphTheme.BurstSeconds), {
		Size = Vector3.one * GlyphTheme.PartSize * GlyphTheme.BurstScale,
		Transparency = 1,
	}):Play()
	Debris:AddItem(burst, GlyphTheme.BurstSeconds + 1)
end

local function onState(raw: unknown)
	if type(raw) ~= "table" then
		return
	end
	local data = raw :: { [string]: unknown }
	local available, count = data.available, data.count
	if type(available) ~= "table" or type(count) ~= "number" then
		return
	end
	local parent = folder
	if not parent then
		return
	end
	local wanted: { [string]: boolean } = {}
	for _, id in available :: { unknown } do
		if type(id) == "string" and spawnById[id] then
			wanted[id] = true
		end
	end
	for id, glyph in rendered do
		if not wanted[id] then
			rendered[id] = nil
			local position, requested = glyph.part.Position, glyph.requested
			local rarity: GlyphRules.Rarity = glyph.rarity
			glyph.part:Destroy()
			if requested then
				local ok, err = pcall(function()
					playPickup(position, rarity)
				end)
				if not ok then
					warn(`[MathShow] glyph pickup effect failed: {err}`)
				end
			end
		end
	end
	for id in wanted do
		if not rendered[id] then
			rendered[id] = makeGlyph(id, spawnById[id], parent)
		end
	end
	if counter then
		counter.Text = `Glyphs {count}`
	end
end

-- The one per-frame connection: spin and bob every glyph, and ask once for each one in reach.
local function onRender()
	local now = os.clock()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local rootPosition = if root and root:IsA("BasePart") then root.Position else nil
	local bobRate = 2 * math.pi / GlyphTheme.BobSeconds
	for id, glyph in rendered do
		local bob = math.sin(now * bobRate + glyph.phase) * GlyphTheme.BobStuds
		glyph.part.CFrame = CFrame.new(glyph.base + Vector3.new(0, bob, 0))
			* CFrame.Angles(0, now * GlyphTheme.SpinRadiansPerSecond + glyph.phase, 0)
		if
			rootPosition
			and not glyph.requested
			and (rootPosition - glyph.base).Magnitude <= GlyphConfig.CollectRadius
			and collectRemote
		then
			glyph.requested = true
			collectRemote:FireServer(id)
		end
	end
end

local function makeCounter()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GlyphHud"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = false
	local label = Instance.new("TextLabel")
	label.Name = "Count"
	label.AnchorPoint = Vector2.new(1, 0)
	label.Size = GlyphTheme.CounterSize
	label.Position = GlyphTheme.CounterPosition
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Right
	label.TextSize = GlyphTheme.CounterTextSize
	label.TextColor3 = GlyphTheme.SymbolColour
	label.TextStrokeTransparency = 0.4
	label.FontFace = GlyphTheme.CounterFont
	label.Text = "Glyphs 0"
	label.Parent = gui
	gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	counter = label
end

function GlyphController.start(): ()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		local stateRemote = remotes:WaitForChild(Net.GlyphState) :: RemoteEvent
		collectRemote = remotes:WaitForChild(Net.GlyphCollect) :: RemoteEvent
		readSpawns()
		local container = Instance.new("Folder")
		container.Name = "Glyphs"
		container.Parent = Workspace
		folder = container
		makeCounter()
		stateRemote.OnClientEvent:Connect(onState)
		RunService.RenderStepped:Connect(onRender)
	end)
end

return GlyphController
