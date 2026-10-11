--!strict
-- Shinobi Clan "Echo Clone" (TASK-0003): leaves a clone where you stand for a few seconds. The clone
-- counts as a pressure-plate activator. Max one clone per player; removed on leave, respawn or expiry.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local AbilityConfig = require(Shared:WaitForChild("AbilityConfig"))
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))

local PressurePlate = require(script.Parent.Parent.Components.PressurePlate)

local EchoClone = {}

local clones: { [Player]: BasePart } = {}
local started = false

local function removeClone(player: Player)
	local clone = clones[player]
	clones[player] = nil
	if clone then
		clone:Destroy()
	end
end

local function getFolder(): Folder
	local folder = Workspace:FindFirstChild("EchoClones")
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = "EchoClones"
	created.Parent = Workspace
	return created
end

function EchoClone.handler(player: Player, _character: Model, root: BasePart)
	removeClone(player)

	local config = AbilityConfig.EchoClone
	local faction = FactionConfig.Factions.Shinobi
	local clone = Instance.new("Part")
	clone.Name = `EchoClone_{player.UserId}`
	clone.Size = config.Size
	clone.CFrame = root.CFrame
	clone.Anchored = true
	clone.CanCollide = false
	clone.CanTouch = false
	clone.CanQuery = true -- required for pressure-plate detection
	clone.Material = Enum.Material.ForceField
	clone.Color = faction.color
	clone.Transparency = config.Transparency
	clone:SetAttribute("OwnerUserId", player.UserId)
	CollectionService:AddTag(clone, PressurePlate.ActivatorTag)
	clone.Parent = getFolder()
	clones[player] = clone

	task.delay(config.Duration, function()
		if clones[player] == clone then
			removeClone(player)
		else
			clone:Destroy()
		end
	end)
end

-- Test/diagnostic helper.
function EchoClone.getClone(player: Player): BasePart?
	return clones[player]
end

function EchoClone.start()
	if started then
		return
	end
	started = true
	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			removeClone(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end
	Players.PlayerRemoving:Connect(removeClone)
end

return EchoClone
