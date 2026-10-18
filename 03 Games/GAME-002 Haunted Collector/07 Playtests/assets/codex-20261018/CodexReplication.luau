-- Temporary, memory-only two-player service/appearance verification; not shipped.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Services = game:GetService("ServerScriptService").Server.Services
local Data = require(Services.PlayerDataService)
local Plots = require(Services.PlotService)
local Cosmetics = require(Services.CosmeticService)
local Containment = require(Services.ContainmentService)
local World = require(RS.Shared.Config.World)
return function()
	local deadline = os.clock() + 90
	while #Players:GetPlayers() < 2 and os.clock() < deadline do task.wait(0.5) end
	local players = Players:GetPlayers()
	if #players < 2 then return { ok = false, infra = true, error = "second client did not join" } end
	local owner = players[1]
	local profile = Data.waitFor(owner, 30)
	assert(profile and Data.persistence(owner) == "memory", "memory-only test required")
	deadline = os.clock() + 25
	while not Plots.plotIndex(owner) and os.clock() < deadline do task.wait(0.2) end
	profile.houseTier = 1
	profile.owned = { { uid = "replica1", species = "Wisp", variant = "Normal", acquiredAt = os.time() - 60 } }
	profile.exhibits = { { slot = 1, uid = "replica1" } }
	for _,id in { "SkinMoss", "AuraEmbers", "ThemeMoonlit", "DecoLantern" } do profile.cosmetics.entitlements[id] = true end
	assert(Cosmetics.equip(owner, "replica1", "skin", "SkinMoss"))
	assert(Cosmetics.equip(owner, "replica1", "aura", "AuraEmbers"))
	assert(Cosmetics.equipTheme(owner, "ThemeMoonlit"))
	Containment.refreshVisuals(owner)
	local plotIndex = Plots.plotIndex(owner)
	for _,player in players do
		local t = os.clock() + 25
		while (not player.Character or not player.Character:FindFirstChild("HumanoidRootPart")) and os.clock() < t do task.wait(0.2) end
		if player.Character then player.Character:PivotTo(World.plotFrame(plotIndex) * CFrame.new(0, 5, -18)) end
	end
	local reports = {}
	local event = RS.CodexObserverResult
	local conn = event.OnServerEvent:Connect(function(player, result) reports[tostring(player.UserId)] = result end)
	workspace:SetAttribute("CodexOwnerPlot", plotIndex)
	deadline = os.clock() + 45
	while os.clock() < deadline do
		local count = 0
		for _ in reports do count += 1 end
		if count >= 2 then break end
		task.wait(0.5)
	end
	conn:Disconnect()
	local count, passed = 0, 0
	for _,report in reports do count += 1; if report.ok then passed += 1 end end
	return { ok = count == 2 and passed == 2, reported = count, passed = passed, reports = reports, plotIndex = plotIndex }
end
