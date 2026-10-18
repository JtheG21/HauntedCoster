--!strict
-- Studio-only art showcase (TASK-0043+): stages the player's plot for visual evidence and holds the session.
-- TEST SHORTCUTS: coins granted and house tiers bought through EconomyService; owned monsters, exhibits and a
-- carried capture are written straight into the session profile (never saved: Studio places run memory-only).
--   ExecutePlayModeAsync({ scenario = "ArtShowcase", tier = 2, seconds = 300, carry = "Hound", carryVariant = "Ashen" })
-- Checks only that the staging worked; everything visual is judged from captures.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local EconomyService = require(Services.EconomyService) :: any
local PlotService = require(Services.PlotService) :: any
local ContainmentService = require(Services.ContainmentService) :: any
local CaptureService = require(Services.CaptureService) :: any

local ROSTER = {
	{ "Wisp", "Normal" },
	{ "Hound", "Normal" },
	{ "Gentleman", "Spectral" },
	{ "BellWraith", "Ashen" },
	{ "Hound", "Spectral" },
	{ "Wisp", "Ashen" },
	{ "Gentleman", "Normal" },
	{ "BellWraith", "Normal" },
	{ "Wisp", "Spectral" },
	{ "Hound", "Ashen" },
}

return function(args: any): { [string]: any }
	local a = if type(args) == "table" then args else {}
	local tier = tonumber(a.tier) or 2
	local seconds = math.clamp(tonumber(a.seconds) or 240, 10, 900)
	local checks: { { name: string, ok: boolean } } = {}
	local function check(name: string, ok: boolean)
		table.insert(checks, { name = name, ok = ok == true })
	end
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	if not profile then
		return { ok = false, error = "no profile" }
	end
	-- Never stage over a real save: only memory-mode (unpublished Studio) profiles.
	if PlayerDataService.persistence(player) ~= "memory" then
		return { ok = false, error = "ArtShowcase runs only on memory-mode profiles" }
	end
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	while profile.houseTier < tier do
		profile.coins += 3000 -- TEST SHORTCUT
		local ok = EconomyService.purchase(player, "house", profile.houseTier)
		if not ok then
			break
		end
	end
	check("house tier reached", profile.houseTier >= tier)
	for i, entry in ROSTER do
		if #profile.owned >= 20 then
			break
		end
		profile.nextUid = (profile.nextUid or 1) + 1
		table.insert(profile.owned, {
			uid = `show{i}`,
			species = entry[1],
			variant = entry[2],
			acquiredAt = os.time() - 60,
		})
	end
	table.clear(profile.exhibits)
	for slot = 1, math.min(4, tier + 2) do
		table.insert(profile.exhibits, { slot = slot, uid = `show{slot + 6}` })
	end
	ContainmentService.refreshVisuals(player)
	check("owned staged", #profile.owned >= #ROSTER)
	if type(a.carry) == "string" then
		CaptureService.carryForTest(
			player,
			a.carry,
			if type(a.carryVariant) == "string" then a.carryVariant else "Normal"
		)
		check("carrying", CaptureService.isCarrying(player))
	end
	task.wait(seconds)
	local ok = true
	for _, c in checks do
		ok = ok and c.ok
	end
	return { ok = ok, checks = checks }
end
