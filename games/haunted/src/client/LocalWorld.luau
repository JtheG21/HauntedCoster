--!strict
-- Client-only world effects: flashlight, glowing name markers on species you've already inspected, your
-- home beacon label, and opening the crypt gate for you locally. Captures inside the crypt are checked on
-- the server, so opening the gate locally grants nothing by itself.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Monsters = require(Config:WaitForChild("Monsters"))
local Habitats = require(Config:WaitForChild("Habitats"))
local HabitatState = require(ReplicatedStorage.Shared:WaitForChild("HabitatState"))
local State = require(script.Parent.State)
local Sfx = require(script.Parent.Sfx)

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

local homeLabel: TextLabel? = nil
local homeIndex: number? = nil

-- Opens or closes a named gate anywhere in the active habitat, for this client only.
local function setGate(name: string, open: boolean)
	local habitat = Workspace:FindFirstChild("Habitat")
	local gate = habitat and habitat:FindFirstChild(name, true)
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
	setGate("CryptGate", snap.cryptOpen == true)

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
	local seen = (snap.journal and snap.journal.seen) or {}
	for _, m in folder:GetChildren() do
		if m:IsA("Model") then
			local speciesId = m:GetAttribute("Species")
			local species = type(speciesId) == "string" and Monsters.Species[speciesId] or nil
			-- Species you've inspected before glow and show their name, so you can spot them again.
			local known = species ~= nil and seen[species.id] == true
			local existing = m:FindFirstChild("KnownMarker")
			if known and not existing and species then
				local h = Instance.new("Highlight")
				h.Name = "KnownMarker"
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

-- Retaliation knockdown (TASK-0031): while the server's `KnockedDownUntil` (server time) is in the future,
-- the character goes limp (Physics state, so it can't walk) and then gets back up. No damage.
local function watchKnockdown(character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	local hum: Humanoid = humanoid
	character:GetAttributeChangedSignal("KnockedDownUntil"):Connect(function()
		local untilT = character:GetAttribute("KnockedDownUntil")
		if type(untilT) ~= "number" then
			return
		end
		local left = untilT - Workspace:GetServerTimeNow()
		if left <= 0 then
			return
		end
		Sfx.play("retaliation_sting")
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			root.AssemblyLinearVelocity += root.CFrame.LookVector * -18 + Vector3.new(0, 14, 0)
		end
		task.delay(left, function()
			if hum.Parent and hum.Health > 0 then
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end)
end

function LocalWorld.start()
	player.CharacterAdded:Connect(watchKnockdown)
	if player.Character then
		task.spawn(watchKnockdown, player.Character)
	end
	player.CharacterAdded:Connect(attachLight)
	if player.Character then
		task.spawn(attachLight, player.Character)
	end
	State.Changed:Connect(updateMarkers)
	-- Follow the server's active habitat (zone names in the Hud and journal), and re-open the crypt gate
	-- locally when the cemetery module is parented back in after a swap.
	local function syncHabitat()
		local id = Workspace:GetAttribute("ActiveHabitat")
		if type(id) == "string" then
			Habitats.setActive(id)
		end
		updateMarkers()
	end
	Workspace:GetAttributeChangedSignal(HabitatState.Attr.active):Connect(syncHabitat)
	-- The swap's fog fade (TASK-0029): thicken this client's haze while the server swaps, then clear it.
	local clearDensity: number? = nil
	local function onFog()
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if not atm then
			return
		end
		if Workspace:GetAttribute(HabitatState.Attr.fog) == true then
			clearDensity = clearDensity or atm.Density
			TweenService:Create(atm, TweenInfo.new(0.7), { Density = 0.85 }):Play()
		elseif clearDensity then
			TweenService:Create(atm, TweenInfo.new(1.5), { Density = clearDensity }):Play()
			clearDensity = nil
		end
	end
	Workspace:GetAttributeChangedSignal(HabitatState.Attr.fog):Connect(onFog)
	task.defer(onFog) -- a player joining mid-swap sees the fog too
	task.spawn(function()
		local folder = Workspace:WaitForChild("Habitat")
		folder.DescendantAdded:Connect(function(d)
			if d.Name == "CryptGate" then
				updateMarkers()
			end
		end)
	end)
	syncHabitat()
	task.spawn(function()
		while true do
			task.wait(1)
			updateMonsterMarkers()
		end
	end)
end

return LocalWorld
