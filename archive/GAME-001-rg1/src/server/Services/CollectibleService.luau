--!strict
-- Server-authoritative coin pickups (T-001). Clients never report pickups; the server
-- validates every Touched event and owns the leaderstats value.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local CollectibleConfig = require(Shared:WaitForChild("CollectibleConfig"))
local CollectibleRules = require(Shared:WaitForChild("CollectibleRules"))

local CollectibleService = {}

local started = false

local function setupLeaderstats(player: Player)
	if player:FindFirstChild("leaderstats") then
		return
	end
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats
	leaderstats.Parent = player
end

local function getCoins(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function setActive(coin: BasePart, active: boolean)
	coin:SetAttribute("Active", active)
	coin.Transparency = if active then 0 else 1
	coin.CanTouch = active
end

local function onTouched(coin: BasePart, hit: BasePart)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = if character then Players:GetPlayerFromCharacter(character) else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil

	local ok = CollectibleRules.canCollect({
		coinActive = coin:GetAttribute("Active") == true,
		isPlayerCharacter = player ~= nil,
		humanoidHealth = if humanoid then humanoid.Health else nil,
		distance = if root and root:IsA("BasePart") then (root.Position - coin.Position).Magnitude else nil,
		maxDistance = CollectibleConfig.MaxPickupDistance,
	})
	if not ok or not player then
		return
	end
	local coins = getCoins(player)
	if not coins then
		return
	end

	-- Deactivate before anything that could yield, so a second touch in the same frame is rejected.
	setActive(coin, false)
	coins.Value = CollectibleRules.award(coins.Value, CollectibleConfig.CoinValue)

	task.delay(CollectibleConfig.RespawnSeconds, function()
		if coin.Parent then
			setActive(coin, true)
		end
	end)
end

local function spawnCoins()
	local folder = Instance.new("Folder")
	folder.Name = CollectibleConfig.FolderName

	for index = 1, CollectibleConfig.Count do
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.4, 2.5, 2.5)
		coin.Anchored = true
		coin.CanCollide = false
		coin.Material = Enum.Material.Neon
		coin.Color = Color3.fromRGB(255, 200, 40)
		coin.Position = CollectibleRules.spawnPosition(
			index,
			CollectibleConfig.Count,
			CollectibleConfig.SpawnCenter,
			CollectibleConfig.SpawnRadius
		)
		setActive(coin, true)
		coin.Touched:Connect(function(hit)
			onTouched(coin, hit)
		end)
		coin.Parent = folder
	end

	folder.Parent = Workspace
end

function CollectibleService.start()
	if started then
		return
	end
	started = true

	Players.PlayerAdded:Connect(setupLeaderstats)
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)
	end
	spawnCoins()
end

return CollectibleService
