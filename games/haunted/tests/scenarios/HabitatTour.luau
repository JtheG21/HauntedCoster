--!strict
-- Studio-only visual tour (TASK-0044/0045 evidence): activates each habitat module in rotation order and holds it
-- for `seconds`, publishing the active id as ReplicatedStorage.HC_Tour so captures can follow. No checks beyond
-- the swaps themselves; everything visual is judged from captures. `tier` buys house tiers first (TEST SHORTCUT:
-- coins granted, memory-mode profiles only), e.g. tier 1 opens the Sealed Crypt for this player.
--   ExecutePlayModeAsync({ scenario = "HabitatTour", seconds = 90, tier = 1 })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local HabitatService = require(Services.HabitatService) :: any
local PlayerDataService = require(Services.PlayerDataService) :: any
local EconomyService = require(Services.EconomyService) :: any

return function(args: any): { [string]: any }
	local seconds = math.clamp((type(args) == "table" and tonumber(args.seconds)) or 90, 10, 600)
	local checks: { { name: string, ok: boolean } } = {}
	local tier = (type(args) == "table" and tonumber(args.tier)) or 0
	if tier > 0 then
		local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
		local profile = PlayerDataService.waitFor(player, 30)
		if not profile or PlayerDataService.persistence(player) ~= "memory" then
			return { ok = false, error = "HabitatTour tiers run only on memory-mode profiles" }
		end
		task.wait(3)
		while profile.houseTier < tier do
			profile.coins += 3000 -- TEST SHORTCUT
			if not EconomyService.purchase(player, "house", profile.houseTier) then
				break
			end
		end
		table.insert(checks, { name = "house tier reached", ok = profile.houseTier >= tier })
	end
	local startId = HabitatService.activeId()
	for _, def in Habitats.List do
		if HabitatService.activeId() ~= def.id then
			HabitatService.activate(def.id)
		end
		ReplicatedStorage:SetAttribute("HC_Tour", def.id)
		table.insert(checks, { name = `{def.id} active`, ok = HabitatService.activeId() == def.id })
		task.wait(seconds)
	end
	ReplicatedStorage:SetAttribute("HC_Tour", nil)
	if startId then
		HabitatService.activate(startId)
	end
	local ok = true
	for _, c in checks do
		ok = ok and c.ok
	end
	return { ok = ok, checks = checks }
end
