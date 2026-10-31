--!strict
-- Multi-client scenario (TASK-0003 revision 1): when players leave and factions differ by more
-- than 1, the server moves players so every faction stays represented.
-- Launch: StudioTestService:ExecuteMultiplayerTestAsync(3, { scenario = "FactionRebalance", players = 3, timeout = 50 })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local FactionRules = require(Shared:WaitForChild("FactionRules"))

local function counts(): { [string]: number }
	local result = {}
	for _, player in Players:GetPlayers() do
		local faction = player:GetAttribute(FactionConfig.AttributeName)
		if typeof(faction) == "string" then
			result[faction] = (result[faction] or 0) + 1
		end
	end
	return result
end

return function(args: { [string]: any }): { [string]: any }
	local wanted = if typeof(args.players) == "number" then args.players else 3
	local timeout = if typeof(args.timeout) == "number" then args.timeout else 50
	local deadline = os.clock() + timeout
	while #Players:GetPlayers() < wanted and os.clock() < deadline do
		task.wait(0.2)
	end
	task.wait(1)
	if #Players:GetPlayers() < wanted then
		return { ok = false, error = `only {#Players:GetPlayers()} of {wanted} joined` }
	end
	local before = counts()

	-- Kick every member of the smallest represented faction to force an imbalance.
	local target = FactionRules.pickBalanced(before, FactionConfig.Active)
	local kicked = 0
	for _, player in Players:GetPlayers() do
		if player:GetAttribute(FactionConfig.AttributeName) == target then
			player:Kick("FactionRebalance test")
			kicked += 1
		end
	end
	local waitUntil = os.clock() + 10
	while #Players:GetPlayers() > wanted - kicked and os.clock() < waitUntil do
		task.wait(0.2)
	end
	task.wait(0.5)
	local after = counts()
	return {
		ok = kicked > 0 and FactionRules.isBalanced(after, FactionConfig.Active) and (after[target] or 0) > 0,
		before = before,
		kickedFaction = target,
		kicked = kicked,
		after = after,
		remaining = #Players:GetPlayers(),
	}
end
