--!strict
-- Owns Humanoid.WalkSpeed: speed upgrade level x carry penalty. Re-applied on every respawn.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EconomyRules =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules"):WaitForChild("EconomyRules"))
local PlayerDataService = require(script.Parent.PlayerDataService)

local MovementService = {}

local started = false
local carrying: { [Player]: boolean } = {}

function MovementService.apply(player: Player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local profile = PlayerDataService.get(player)
	if humanoid then
		local level = if profile then profile.speedLevel else 0
		humanoid.WalkSpeed = EconomyRules.walkSpeed(level, carrying[player] == true)
	end
end

function MovementService.setCarrying(player: Player, value: boolean)
	if value then
		carrying[player] = true
	else
		carrying[player] = nil
	end
	MovementService.apply(player)
end

function MovementService.start()
	if started then
		return
	end
	started = true
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			character:WaitForChild("Humanoid", 10)
			MovementService.apply(player)
		end)
		if player.Character then
			MovementService.apply(player)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(function(player)
		carrying[player] = nil
	end)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	PlayerDataService.onLoaded(function(player)
		MovementService.apply(player)
	end)
end

return MovementService
