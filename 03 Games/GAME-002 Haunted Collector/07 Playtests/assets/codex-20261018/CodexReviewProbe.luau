-- Studio-only temporary verification module, not part of the Rojo game source.
-- TEST SHORTCUTS: memory-only profile, test Coins, owned roster, journal entries and reward grants.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Services = game:GetService("ServerScriptService").Server.Services
local Data = require(Services.PlayerDataService)
local Cosmetics = require(Services.CosmeticService)
local Buy = require(Services.PurchaseService)
local Economy = require(Services.EconomyService)
local Plots = require(Services.PlotService)
local Containment = require(Services.ContainmentService)
local State = require(Services.StateService)
local Placement = require(RS.Shared.Rules.PlacementRules)
local CosmeticRules = require(RS.Shared.Rules.CosmeticRules)
local Catalog = require(RS.Shared.Config.Catalog)
local ProfileRules = require(RS.Shared.Rules.ProfileRules)
local H = game:GetService("HttpService")
return function(args)
	local checks = {}
	local function check(name, ok, detail)
		table.insert(checks, { name = name, ok = ok == true, detail = tostring(detail or "") })
	end
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local p = Data.waitFor(player, 30)
	assert(p and Data.persistence(player) == "memory", "refuse staging persistent profiles")
	local untilTime = os.clock() + 20
	while not Plots.plotIndex(player) and os.clock() < untilTime do task.wait(0.2) end
	check("isolated memory mode", Data.persistence(player) == "memory")
	local passed, failed = require(game.TestService.Tests.TestRunner).run()
	check("fresh Server specs", failed == 0, tostring(passed) .. " passed, " .. tostring(failed) .. " failed")
	p.coins = 1000
	local ok, msg = Buy.buy(player, "SkinMoss", "codex-skin")
	check("buy debit/grant", ok and p.coins == 700 and p.cosmetics.entitlements.SkinMoss, msg)
	ok = Buy.buy(player, "SkinMoss", "codex-skin")
	check("same request once", ok and p.coins == 700)
	ok = Buy.buy(player, "SkinMoss", "codex-skin-again")
	check("new request already-owned refusal", not ok and p.coins == 700)
	p.coins = 100
	ok, msg = Buy.buy(player, "AuraEmbers", "codex-short")
	check("shortfall exact and unchanged", not ok and p.coins == 100 and not p.cosmetics.entitlements.AuraEmbers and string.find(msg, "150", 1, true) ~= nil, msg)
	p.coins = 10000
	check("buy aura", Buy.buy(player, "AuraEmbers", "codex-aura"))
	check("buy decoration", Buy.buy(player, "DecoLantern", "codex-deco"))
	p.owned = {
		{ uid = "codex1", species = "Wisp", variant = "Normal", acquiredAt = os.time() - 60 },
		{ uid = "codex2", species = "Hound", variant = "Spectral", acquiredAt = os.time() - 60 },
		{ uid = "codex3", species = "Gentleman", variant = "Ashen", acquiredAt = os.time() - 60 },
		{ uid = "codex4", species = "BellWraith", variant = "Normal", acquiredAt = os.time() - 60 },
	}
	p.nextUid = 20
	check("normal skin", Cosmetics.equip(player, "codex1", "skin", "SkinMoss"))
	check("aura independent", Cosmetics.equip(player, "codex1", "aura", "AuraEmbers"))
	ok = Cosmetics.equip(player, "codex2", "skin", "SkinMoss")
	check("Spectral skin refused", not ok and p.cosmetics.ghostLooks.codex2 == nil)
	ok = Cosmetics.equip(player, "codex3", "skin", "SkinMoss")
	check("Ashen skin refused", not ok and p.cosmetics.ghostLooks.codex3 == nil)
	ok = Cosmetics.equipCaptureEffect(player, "FxSparks")
	check("unowned effect refused", not ok and p.cosmetics.captureEffect == nil)
	ok = Cosmetics.claimReward(player, "bestiary_half")
	check("ineligible reward refused", not ok and not p.cosmetics.rewardsClaimed.bestiary_half)
	p.journal.caught.Wisp = true
	p.journal.caught.Hound = true
	check("eligible claim grants effect", Cosmetics.claimReward(player, "bestiary_half") and p.cosmetics.entitlements.FxSparks)
	ok = Cosmetics.claimReward(player, "bestiary_half")
	check("reward replay refused", not ok and p.cosmetics.rewardsClaimed.bestiary_half)
	check("effect equip", Cosmetics.equipCaptureEffect(player, "FxSparks") and p.cosmetics.captureEffect == "FxSparks")
	p.cosmetics.entitlements.ThemeMoonlit = true
	ok = Cosmetics.equipTheme(player, "ThemeMoonlit")
	check("Shack theme refused", not ok and p.cosmetics.mansionTheme == nil)
	check("upgrade to manor", Economy.purchase(player, "house", 0))
	check("manor theme equip", Cosmetics.equipTheme(player, "ThemeMoonlit"))
	local plotIndex = Plots.plotIndex(player)
	local plot = Plots.plotModel(plotIndex)
	check("theme tint replicated anchor", plot.House.HouseArt:GetAttribute("Tint_Walls") ~= nil)
	local x, z = Placement.firstSpot({ x = 2, z = 2 }, 0, p.houseTier)
	check("place", Cosmetics.editDecoration(player, "place", "DecoLantern", x, z, 0))
	check("rotate", Cosmetics.editDecoration(player, "move", 1, x, z, 90) and p.cosmetics.placements[1].r == 90)
	local before = H:JSONEncode(p.cosmetics.placements)
	ok = Cosmetics.editDecoration(player, "move", 1, 0, 0, 0)
	check("blocked move unchanged", not ok and H:JSONEncode(p.cosmetics.placements) == before)
	check("store", Cosmetics.editDecoration(player, "store", 1) and #p.cosmetics.placements == 0)
	-- Find a real tier-1-valid cell blocked by the tier-2 house to test upgrade storage.
	local ux, uz
	for a = -56, 56, 2 do
		for b = -56, 56, 2 do
			if not Placement.refusal(a, b, { x = 2, z = 2 }, 0, 1) and Placement.refusal(a, b, { x = 2, z = 2 }, 0, 2) then ux, uz = a, b; break end
		end
		if ux then break end
	end
	check("upgrade collision test cell exists", ux ~= nil)
	if ux then check("place before upgrade", Cosmetics.editDecoration(player, "place", "DecoLantern", ux, uz, 0)) end
	-- TEST SHORTCUT: the shipped theme covers both tiers, so temporarily restrict its test catalog coverage.
	local tiers = Catalog.Items.ThemeMoonlit.tiers
	Catalog.Items.ThemeMoonlit.tiers = { 1 }
	local upgradeOk, upgradeResult = pcall(Economy.purchase, player, "house", 1)
	Catalog.Items.ThemeMoonlit.tiers = tiers
	check("upgrade to mansion", upgradeOk and upgradeResult, upgradeResult)
	check("theme fallback clears selection, keeps ownership", p.cosmetics.mansionTheme == nil and p.cosmetics.entitlements.ThemeMoonlit)
	check("upgrade stores colliding placement", not ux or #p.cosmetics.placements == 0)
	check("re-equip sample theme", Cosmetics.equipTheme(player, "ThemeMoonlit"))
	x, z = Placement.firstSpot({ x = 2, z = 2 }, 0, 2)
	check("place after upgrade", Cosmetics.editDecoration(player, "place", "DecoLantern", x, z, 0))
	-- Reload probe uses an isolated copy, not a save: confirms known invalid-placement retention.
	local copy = ProfileRules.default()
	copy.houseTier = 2
	copy.cosmetics.entitlements.DecoLantern = true
	copy.cosmetics.placements = { { id = "DecoLantern", x = 0, z = 0, r = 0 } }
	local clean = ProfileRules.sanitize(copy, os.time())
	check("KNOWN GAP: reload rejects blocked cell", #clean.cosmetics.placements == 0)
	p.exhibits = { { slot = 1, uid = "codex1" } }
	Containment.refreshVisuals(player)
	State.markDirty(player)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then player.Character:PivotTo(require(RS.Shared.Config.World).plotFrame(plotIndex) * CFrame.new(0, 6, -40)) end
	local bake = require(Services.ArtBakeService).stats()
	local stats = game:GetService("Stats")
	local count = 0
	for _, c in checks do if c.ok then count += 1 end end
	local result = { ok = count == #checks, checks = checks, passed = count, failed = #checks - count, artBake = bake, serverMemoryMb = stats:GetTotalMemoryUsageMb() }
	workspace:SetAttribute("CodexReviewResult", H:JSONEncode(result))
	workspace:SetAttribute("CodexReviewStaged", true)
	local deadline = os.clock() + (tonumber(args.seconds) or 180)
	while os.clock() < deadline and not workspace:GetAttribute("CodexReviewFinish") do task.wait(1) end
	return result
end
