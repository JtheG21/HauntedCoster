--!strict
-- TASK-0024 probe: FullLoop's opening (profile, plot, character, 1 s settle) followed by its first
-- investigate, without the rest of the loop, so the start-of-session landmark check can be repeated in
-- many fresh sessions quickly. Reports why a refused investigate was refused.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "LandmarkStart" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local World = require(ReplicatedStorage:WaitForChild("Shared").Config.World)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local LandmarkService = require(Services.LandmarkService) :: any
local CaptureService = require(Services.CaptureService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	check("profile loads", profile ~= nil)
	if not profile then
		return { ok = false, checks = checks }
	end
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 10 do
		task.wait(0.2)
	end
	local character = player.Character or player.CharacterAdded:Wait()
	character:WaitForChild("HumanoidRootPart")
	task.wait(1)
	local spawnedAt = os.clock() - t0
	character:PivotTo(CFrame.new((World.landmarkById("Angel") :: any).position + Vector3.new(0, 3, 6)))
	CaptureService.noteTeleport(player)
	task.wait(0.3)
	local blocker = LandmarkService.blocker(player, "Angel")
	LandmarkService.investigate(player, "Angel")
	check(
		"landmark records clue",
		profile.journal.clues.Angel == true,
		blocker
			or (if player.Character ~= character then "character was replaced" else nil)
			or (if PlayerDataService.get(player) ~= profile then "profile table was replaced" else nil)
			or string.format("plot+character after %.1fs", spawnedAt)
	)
	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
end
