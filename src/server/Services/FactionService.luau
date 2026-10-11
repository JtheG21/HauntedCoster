--!strict
-- Faction assignment (TASK-0003). The server assigns factions on join with auto-balance and
-- publishes them as a Player attribute (public information, read by clients for UI).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local FactionRules = require(Shared:WaitForChild("FactionRules"))

local FactionService = {}

local started = false

local function counts(except: Player?): { [string]: number }
	local result = {}
	for _, player in Players:GetPlayers() do
		if player ~= except then
			local faction = player:GetAttribute(FactionConfig.AttributeName)
			if typeof(faction) == "string" then
				result[faction] = (result[faction] or 0) + 1
			end
		end
	end
	return result
end

local function assign(player: Player)
	if player:GetAttribute(FactionConfig.AttributeName) ~= nil then
		return
	end
	local faction = FactionRules.pickBalanced(counts(player), FactionConfig.Active)
	player:SetAttribute(FactionConfig.AttributeName, faction)
end

function FactionService.getFaction(player: Player): string?
	local faction = player:GetAttribute(FactionConfig.AttributeName)
	return if typeof(faction) == "string" then faction else nil
end

-- Server-only override (tests, future faction-select UI). Rejects unknown or inactive factions.
function FactionService.setFaction(player: Player, faction: string): boolean
	if not table.find(FactionConfig.Active, faction) then
		return false
	end
	player:SetAttribute(FactionConfig.AttributeName, faction)
	return true
end

-- Eligibility helper for AbilityService registrations.
function FactionService.requires(faction: string): (player: Player) -> boolean
	return function(player: Player): boolean
		return FactionService.getFaction(player) == faction
	end
end

function FactionService.start()
	if started then
		return
	end
	started = true
	Players.PlayerAdded:Connect(assign)
	for _, player in Players:GetPlayers() do
		assign(player)
	end
end

return FactionService
