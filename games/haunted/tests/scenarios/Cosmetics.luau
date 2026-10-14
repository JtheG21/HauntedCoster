--!strict
-- Studio-only cosmetics walk-through (TASK-0047 AC3/AC4): drives CosmeticsService.action like the remote does and
-- checks the authoritative results and the world (ghost attributes, house theme tints, decorations), a Robux
-- receipt with a TEST FIXTURE product id (never a real product; restored afterwards), and the tier upgrade
-- reconcile. TEST SHORTCUT: coins granted and owned ghosts written into a memory-mode profile only.
--   ExecutePlayModeAsync({ scenario = "Cosmetics" })

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Cosmetics = require(ReplicatedStorage.Shared.Config.Cosmetics)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local PlotService = require(Services.PlotService) :: any
local EconomyService = require(Services.EconomyService) :: any
local ContainmentService = require(Services.ContainmentService) :: any
local CosmeticsService = require(Services.CosmeticsService) :: any

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 30)
	if not profile or PlayerDataService.persistence(player) ~= "memory" then
		return { ok = false, error = "Cosmetics runs only on memory-mode profiles" }
	end
	local t0 = os.clock()
	while not PlotService.plotIndex(player) and os.clock() - t0 < 20 do
		task.wait(0.2)
	end
	local index = PlotService.plotIndex(player)
	local plot = index and PlotService.plotModel(index)
	profile.coins = 20000 -- TEST SHORTCUT
	table.insert(profile.owned, { uid = "cw1", species = "Wisp", variant = "Normal", acquiredAt = os.time() - 60 })
	table.insert(profile.owned, { uid = "cw2", species = "Hound", variant = "Spectral", acquiredAt = os.time() - 60 })
	local act = CosmeticsService.action
	local function a(...): (boolean, string?, any)
		task.wait(0.25) -- stay under the remote's rate limit
		return act(player, ...)
	end

	local coins = profile.coins
	check("buy skin with Coins", (a("buy", "skin_wisp_candlewick")))
	check("Coins charged once", profile.coins == coins - 400, profile.coins)
	check("second buy refused", not (a("buy", "skin_wisp_candlewick")))
	check("equip on the Wisp", (a("equip", "skins", "cw1", "skin_wisp_candlewick")))
	local _, why = a("equip", "skins", "cw2", "skin_wisp_candlewick")
	check("incompatible species refused", why ~= nil and string.find(why, "Only fits") ~= nil, why)
	check("unknown action refused", not (a("hack", 1)))
	local residents = plot and plot:FindFirstChild("Pen") and plot.Pen:FindFirstChild("Residents")
	local skinned = false
	for _, m in (residents and residents:GetChildren() or {}) do
		if m:GetAttribute("Skin") == "skin_wisp_candlewick" then
			skinned = true
		end
	end
	check("pen Wisp model carries the skin", skinned)
	check("Robux item not prompted while unconfigured", not (a("buyRobux", "skin_wisp_moonlit")))

	check("buy theme", (a("buy", "theme_bone")))
	check("select theme", (a("select", "theme", "theme_bone")))
	local art = plot and plot:FindFirstChild("House") and plot.House:FindFirstChild("HouseArt")
	check(
		"house art tinted",
		art ~= nil and art:GetAttribute("Tint_Walls") == Cosmetics.ById.theme_bone.look.tint.Walls
	)

	check("buy decoration", (a("buy", "deco_pumpkin")))
	local okPlace, whyPlace, key = a("place", "deco_pumpkin", -44, 26, 0)
	check("place decoration", okPlace, whyPlace)
	check("blocked spot refused", not (a("place", "deco_pumpkin", 10, -20, 0)))
	local deco = plot and plot:FindFirstChild("Decorations")
	check("decoration built on the plot", deco ~= nil and deco:FindFirstChild(key) ~= nil)
	check("move decoration", (a("move", key, -44, 30, 90)))

	-- Reward: the Spectral Hound counts as a natural variant discovery.
	profile.journal.variants["Hound:Spectral"] = true
	local okClaim, _, granted = a("claim", "variant_first")
	check("claim reward once", okClaim and type(granted) == "table" and granted[1] == "aura_moths")
	check("second claim refused", not (a("claim", "variant_first")))

	-- Robux receipt with a TEST FIXTURE id (restored afterwards; never a real product).
	local product = Cosmetics.Products.capture_bats
	product.productId = 424242
	local info = { PlayerId = player.UserId, PurchaseId = "test-receipt-1", ProductId = 424242 }
	local first = CosmeticsService.processReceiptForTest(info)
	local second = CosmeticsService.processReceiptForTest(info)
	product.productId = nil
	check(
		"receipt granted",
		first == Enum.ProductPurchaseDecision.PurchaseGranted and profile.cosmetics.owned.capture_bats == true
	)
	check(
		"duplicate receipt acknowledged without a second grant",
		second == Enum.ProductPurchaseDecision.PurchaseGranted and #profile.cosmetics.receipts == 1
	)
	local unknown =
		CosmeticsService.processReceiptForTest({ PlayerId = player.UserId, PurchaseId = "x", ProductId = 99 })
	check("unknown product left unprocessed", unknown == Enum.ProductPurchaseDecision.NotProcessedYet)

	-- Upgrade to the Grand Mansion: the pumpkin (west strip) keeps its place.
	while profile.houseTier < 2 do
		profile.coins += 3000 -- TEST SHORTCUT
		if not EconomyService.purchase(player, "house", profile.houseTier) then
			break
		end
	end
	task.wait(1)
	check("tier 2 reached", profile.houseTier == 2)
	check("placement kept after upgrade", #profile.cosmetics.placements == 1)
	check("theme kept (covers every tier)", profile.cosmetics.theme == "theme_bone")
	ContainmentService.refreshVisuals(player)
	task.wait(tonumber(_args and _args.hold) or 2)
	local ok = true
	for _, c in checks do
		ok = ok and c.ok
	end
	return { ok = ok, checks = checks }
end
