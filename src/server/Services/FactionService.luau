--!strict
-- Faction assignment (TASK-0003). The server assigns factions on join with auto-balance, rebalances
-- when a player leaves, and publishes them as a Player attribute (public, read by clients for UI).
-- M2 note: a rebalance can switch a player's faction mid-round; the match flow (TASK-0006) may
-- restrict switching to the lobby.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local FactionRules = require(Shared:WaitForChild("FactionRules"))

local FactionService = {}

local started = false
local joinOrder: { [Player]: number } = {}
local joinCounter = 0

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
	if joinOrder[player] == nil then
		joinCounter += 1
		joinOrder[player] = joinCounter
	end
	if player:GetAttribute(FactionConfig.AttributeName) ~= nil then
		return
	end
	local faction = FactionRules.pickBalanced(counts(player), FactionConfig.Active)
	player:SetAttribute(FactionConfig.AttributeName, faction)
end

-- After a leave, move the most recent joiners from the largest to the smallest faction until
-- counts are within 1. Keeps every faction's powers available (gates need them).
local function rebalance(leaving: Player)
	joinOrder[leaving] = nil
	for _ = 1, #Players:GetPlayers() do
		local from, to = FactionRules.rebalanceMove(counts(leaving), FactionConfig.Active)
		if not from or not to then
			return
		end
		local candidate: Player? = nil
		for _, player in Players:GetPlayers() do
			if player ~= leaving and player:GetAttribute(FactionConfig.AttributeName) == from then
				if candidate == nil or (joinOrder[player] or 0) > (joinOrder[candidate] or 0) then
					candidate = player
				end
			end
		end
		if candidate == nil then
			return
		end
		candidate:SetAttribute(FactionConfig.AttributeName, to)
	end
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
	Players.PlayerRemoving:Connect(rebalance)
	for _, player in Players:GetPlayers() do
		assign(player)
	end
end

return FactionService
