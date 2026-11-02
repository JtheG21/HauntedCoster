--!strict
-- GlyphController (TASK-0121): renders the hub glyphs this player can collect and asks the server for them.
-- Driven only by GlyphState: a glyph appears when its id is in `available` and goes when it leaves, and the counter shows
-- `count`. Standing within CollectRadius of an available glyph sends GlyphCollect for it, at most once per
-- RetryAfterSeconds (GlyphRules.shouldRequest; the timer clears when the glyph leaves or returns); the client never
-- changes its own count. Positions come from the same GlyphSpawn attachments the server reads, learnt as they stream in
-- (the place uses StreamingEnabled), and kept once known. The symbol index is the id's place in the first GlyphState,
-- which the server sends with every glyph available and sorted by id. The pickup burst is cosmetic: pcall-isolated,
-- fails inert and warns, and never touches collection.

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
	CounterDisplayOrder = 4, -- above the HUD (0), below the watching banner (5) and the menu (10)
	MenuGuiName = "MathShowMenu",
	CounterFont = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Bold),
})

type Rendered = {
	part: BasePart,
	base: Vector3,
	rarity: GlyphRules.Rarity,
	phase: number,
	lastRequestAt: number?, -- os.clock() of the last GlyphCollect sent; nil on a new lifetime (respawn clears it)
}

local GlyphController = {}

local started = false
local spawnById: { [string]: GlyphRules.Spawn } = {}
local indexById: { [string]: number } = {}
local indexCount = 0
local wanted: { [string]: boolean } = {} -- the last GlyphState's available ids
local rendered: { [string]: Rendered } = {}
local folder: Folder? = nil
local counter: TextLabel? = nil
local collectRemote: RemoteEvent? = nil

local function learnSpawn(tagged: Instance): string?
	local hub = Workspace:FindFirstChild("Hub")
	local parent = tagged.Parent
	if not hub or not parent or not tagged:IsA("Attachment") or not tagged:IsDescendantOf(hub) then
		return nil
	end
	if spawnById[parent.Name] then
		return nil
	end
	local position = tagged.WorldPosition
	local parsed = GlyphRules.parseSpawns({
		{
			id = parent.Name,
			rarity = tostring(tagged:GetAttribute("Rarity")),
			x = position.X,
			y = position.Y,
			z = position.Z,
		},
	})
	local spawn = parsed[1]
	if not spawn then
		return nil
	end
	spawnById[spawn.id] = spawn
	return spawn.id
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
	return { part = part, base = base, rarity = spawn.rarity, phase = (indexById[id] or 0) * 0.7, lastRequestAt = nil }
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

-- Brings the rendered glyphs in line with `wanted`: removes the ones that left (with the pickup burst for ones we asked
-- for) and adds the wanted ones whose position is known.
local function refresh()
	local parent = folder
	if not parent then
		return
	end
	for id, glyph in rendered do
		if not wanted[id] then
			rendered[id] = nil
			local position, requested = glyph.part.Position, glyph.lastRequestAt ~= nil
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
		local spawn = spawnById[id]
		if spawn and not rendered[id] then
			rendered[id] = makeGlyph(id, spawn, parent)
		end
	end
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
	local nextWanted: { [string]: boolean } = {}
	for _, id in available :: { unknown } do
		if type(id) == "string" then
			nextWanted[id] = true
			if not indexById[id] then
				indexCount += 1
				indexById[id] = indexCount
			end
		end
	end
	wanted = nextWanted
	refresh()
	if counter then
		counter.Text = `Glyphs {count}`
	end
end

local function onSpawnAdded(tagged: Instance)
	local id = learnSpawn(tagged)
	if id and wanted[id] then
		refresh()
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
		local inRange = rootPosition ~= nil and (rootPosition - glyph.base).Magnitude <= GlyphConfig.CollectRadius
		if collectRemote and GlyphRules.shouldRequest(glyph.lastRequestAt, now, inRange, wanted[id] == true) then
			glyph.lastRequestAt = now
			collectRemote:FireServer(id)
		end
	end
end

-- The counter shows only while no menu screen is open. The menu's own ScreenGui is the open/close state: Menu.start builds
-- it enabled and Menu.hide disables it; a missing or destroyed gui counts as closed. Collection is unaffected.
local function watchMenu(counterGui: ScreenGui, playerGui: PlayerGui)
	local menuConnection: RBXScriptConnection? = nil
	local function apply(menu: ScreenGui?)
		counterGui.Enabled = not (menu ~= nil and menu.Enabled)
	end
	local function attach(menu: ScreenGui)
		if menuConnection then
			menuConnection:Disconnect()
		end
		menuConnection = menu:GetPropertyChangedSignal("Enabled"):Connect(function()
			apply(menu)
		end)
		apply(menu)
		menu.Destroying:Connect(function()
			apply(nil)
		end)
	end
	local existing = playerGui:FindFirstChild(GlyphTheme.MenuGuiName)
	if existing and existing:IsA("ScreenGui") then
		attach(existing)
	end
	playerGui.ChildAdded:Connect(function(child)
		if child.Name == GlyphTheme.MenuGuiName and child:IsA("ScreenGui") then
			attach(child)
		end
	end)
end

local function makeCounter()
	local gui = Instance.new("ScreenGui")
	gui.Name = "GlyphHud"
	gui.DisplayOrder = GlyphTheme.CounterDisplayOrder
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
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui") :: PlayerGui
	gui.Parent = playerGui
	counter = label
	watchMenu(gui, playerGui)
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
		local container = Instance.new("Folder")
		container.Name = "Glyphs"
		container.Parent = Workspace
		folder = container
		makeCounter()
		for _, tagged in CollectionService:GetTagged("GlyphSpawn") do
			learnSpawn(tagged)
		end
		CollectionService:GetInstanceAddedSignal("GlyphSpawn"):Connect(onSpawnAdded)
		stateRemote.OnClientEvent:Connect(onState)
		RunService.RenderStepped:Connect(onRender)
	end)
end

return GlyphController
