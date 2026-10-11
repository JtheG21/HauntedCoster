--!strict
-- Holds a 1-player play session open for hands-on checks driven from the client (e.g. through the
-- Studio MCP), after an optional TEST SHORTCUT: coins granted and house tiers bought through the
-- normal EconomyService purchase path. Ends after `seconds` with no checks of its own.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "HoldForManual", tier = 1, seconds = 240 })

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local EconomyService = require(Services.EconomyService) :: any
local PlotService = require(Services.PlotService) :: any

return function(args: any): { [string]: any }
	local tier = (type(args) == "table" and tonumber(args.tier)) or 0
	local seconds = math.clamp((type(args) == "table" and tonumber(args.seconds)) or 120, 10, 900)
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	if not profile then
		return { ok = false, error = "no profile" }
	end
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	while profile.houseTier < tier do
		-- TEST SHORTCUT: grant coins to skip saving up
		profile.coins += 2000
		local ok, why = EconomyService.purchase(player, "house", profile.houseTier)
		if not ok then
			return { ok = false, error = `house purchase failed: {why}` }
		end
	end
	task.wait(seconds)
	return { ok = true, passed = 0, failed = 0, checks = {}, tier = profile.houseTier }
end
