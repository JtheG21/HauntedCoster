--!strict
-- Client-only world effects: flashlight, landmark "?" markers, glowing markers on monsters whose clue
-- you've found, your home beacon label, and opening the crypt/shortcut gates for you locally.
-- The server still enforces crypt access, so opening a gate locally grants nothing by itself.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local State = require(script.Parent.State)

local LocalWorld = {}

local player = Players.LocalPlayer
local lightOn = true
local lamp: Part? = nil

local function billboard(
	parent: Instance,
	text: string,
	color: Color3,
	offset: number,
	maxDistance: number,
	size: number
): TextLabel
	local gui = Instance.new("BillboardGui")
	gui.Name = "LocalMarker"
	gui.Size = UDim2.fromOffset(size * 3, size)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offset, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.Parent = gui
	gui.Parent = parent
	return l
end

local function attachLight(character: Model)
	local head = character:WaitForChild("Head", 10)
	if not (head and head:IsA("BasePart")) then
		return
	end
	local p = Instance.new("Part")
	p.Name = "Flashlight"
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Massless = true
	p.CFrame = head.CFrame * CFrame.new(0, 0, -0.6)
	local weld = Instance.new("Weld")
	weld.Part0 = head
	weld.Part1 = p
	weld.C0 = CFrame.new(0, 0, -0.6) * CFrame.Angles(math.rad(-8), 0, 0)
	weld.Parent = p
	local spot = Instance.new("SpotLight")
	spot.Face = Enum.NormalId.Front
	spot.Range = 60
	spot.Angle = 65
	spot.Brightness = 4
	spot.Color = Color3.fromRGB(255, 240, 210)
	spot.Shadows = true
	spot.Parent = p
	local glow = Instance.new("PointLight")
	glow.Range = 12
	glow.Brightness = 0.5
	glow.Color = Color3.fromRGB(200, 200, 255)
	glow.Parent = p
	p.Parent = character
	lamp = p
	spot.Enabled = lightOn
	glow.Enabled = lightOn
end

function LocalWorld.toggleLight(): boolean
	lightOn = not lightOn
	if lamp then
		for _, l in lamp:GetChildren() do
			if l:IsA("Light") then
				l.Enabled = lightOn
			end
		end
	end
	return lightOn
end

local landmarkLabels: { [string]: TextLabel } = {}
local homeLabel: TextLabel? = nil
local homeIndex: number? = nil

local function setupLandmarks()
	local folder = Workspace:WaitForChild("Graveyard", 30)
	local lms = folder and folder:WaitForChild("Landmarks", 10)
	if not lms then
		return
	end
	for _, lm in World.Landmarks do
		local m = lms:WaitForChild(lm.id, 10)
		local anchor = m and m:FindFirstChild("Anchor")
		if anchor and anchor:IsA("BasePart") then
			landmarkLabels[lm.id] = billboard(anchor, "?", Color3.fromRGB(255, 210, 90), 14, 450, 34)
		end
	end
end

local function setGate(name: string, path: { string }, open: boolean)
	local node: Instance? = Workspace
	for _, step in path do
		node = node and node:FindFirstChild(step)
	end
	local gate = node and node:FindFirstChild(name)
	if gate and gate:IsA("BasePart") then
		gate.CanCollide = not open
		gate.Transparency = if open then 0.85 else 0.25
	end
end

local function updateMarkers()
	local snap = State.snap
	if not snap then
		return
	end
	local clues = (snap.journal and snap.journal.clues) or {}
	for id, label in landmarkLabels do
		local lm = World.landmarkById(id)
		if clues[id] then
			label.Text = "✓"
			label.TextColor3 = Color3.fromRGB(120, 230, 140)
		elseif lm and lm.requiresFlag and not (snap.flags and snap.flags[lm.requiresFlag]) then
			label.Text = "?"
			label.TextColor3 = Color3.fromRGB(140, 130, 160)
		else
			label.Text = "?"
			label.TextColor3 = Color3.fromRGB(255, 210, 90)
		end
	end
	setGate("CryptGate", { "Graveyard", "Crypt" }, snap.cryptOpen == true)
	setGate("OvergrownGate", { "Graveyard" }, snap.flags ~= nil and snap.flags.shortcut == true)

	-- Home beacon label on my own plot
	local idx = snap.plotIndex
	if idx and idx ~= homeIndex then
		homeIndex = idx
		if homeLabel then
			(homeLabel.Parent :: Instance):Destroy()
		end
		local plots = Workspace:FindFirstChild("Plots")
		local plot = plots and plots:FindFirstChild(`Plot{idx}`)
		local beacon = plot and plot:FindFirstChild("Beacon")
		if beacon and beacon:IsA("BasePart") then
			homeLabel = billboard(beacon, "HOME", Color3.fromRGB(255, 240, 200), 42, 3000, 30)
		end
	end
end

local function updateMonsterMarkers()
	local snap = State.snap
	local folder = Workspace:FindFirstChild("Monsters")
	if not (snap and folder) then
		return
	end
	local clues = (snap.journal and snap.journal.clues) or {}
	for _, m in folder:GetChildren() do
		if m:IsA("Model") then
			local speciesId = m:GetAttribute("Species")
			local species = type(speciesId) == "string" and Monsters.Species[speciesId] or nil
			-- A special encounter stays invisible (and un-inspectable) for players without its clue.
			local hidden = species ~= nil
				and species.requiresFlag ~= nil
				and not (snap.flags and snap.flags[species.requiresFlag])
			for _, d in m:GetDescendants() do
				if d:IsA("BasePart") then
					d.LocalTransparencyModifier = if hidden then 1 else 0
				elseif d:IsA("ProximityPrompt") or d:IsA("Light") or d:IsA("Sparkles") then
					d.Enabled = not hidden
				end
			end
			local known = species ~= nil and clues[species.clueLandmark] == true and not hidden
			local existing = m:FindFirstChild("ClueMarker")
			if known and not existing and species then
				local h = Instance.new("Highlight")
				h.Name = "ClueMarker"
				h.FillTransparency = 0.75
				h.OutlineTransparency = 0.2
				h.FillColor = Monsters.RarityColor[species.rarity]
				h.OutlineColor = Monsters.RarityColor[species.rarity]
				h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				h.Parent = m
				local root = m.PrimaryPart
				if root then
					local label = billboard(root, species.name, Monsters.RarityColor[species.rarity], 4, 160, 22)
					local variant = m:GetAttribute("Variant")
					if type(variant) == "string" and variant ~= "Normal" then
						label.Text = `{variant} {species.name}`
					end
				end
			end
		end
	end
end

function LocalWorld.start()
	player.CharacterAdded:Connect(attachLight)
	if player.Character then
		task.spawn(attachLight, player.Character)
	end
	task.spawn(setupLandmarks)
	State.Changed:Connect(updateMarkers)
	task.spawn(function()
		while true do
			task.wait(1)
			updateMonsterMarkers()
		end
	end)
end

return LocalWorld
