--!strict
-- Cosmetics (TASK-0047, SYS-Haunted-Monetization-UI): one rate-limited remote for every cosmetic action, the
-- client snapshot, world application (ghost skins/auras, mansion theme, decorations, capture effects) and Robux
-- grants through MarketplaceService.ProcessReceipt. The server validates everything with CosmeticRules; the
-- client only previews and asks. Robux products stay disabled until jg configures real ids in Config.Cosmetics.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics = require(Shared:WaitForChild("Config"):WaitForChild("Cosmetics"))
local CosmeticRules = require(Shared:WaitForChild("Rules"):WaitForChild("CosmeticRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)
local ContainmentService = require(script.Parent.ContainmentService)
local EconomyService = require(script.Parent.EconomyService)
local CaptureService = require(script.Parent.CaptureService)

local CosmeticsService = {}

local started = false

-- Whether this player's cosmetic changes can be kept. Live servers need a saving profile (no purchase, claim or
-- edit while saving is down or the profile is read-only); unpublished Studio places run memory-only for tests.
local function writable(player: Player): (boolean, string?)
	local mode = PlayerDataService.persistence(player)
	if mode == "saved" or (mode == "memory" and RunService:IsStudio()) then
		return true, nil
	end
	return false, "Saving is unavailable right now, so cosmetic changes are paused. Please try again later."
end

local function refreshWorld(player: Player, what: { [string]: boolean })
	if what.ghosts then
		ContainmentService.refreshVisuals(player)
	end
	if what.house then
		PlotService.rebuildHouse(player)
	end
	if what.decor then
		PlotService.rebuildDecorations(player)
	end
	PlayerDataService.markDirty(player)
	StateService.markDirty(player)
end

local function productsLive(): boolean
	return not RunService:IsStudio() or Players:GetAttribute("HC_TestProducts") == true
end

-- Every cosmetic action. Returns ok, reason, data.
local function onAction(player: Player, action: any, a: any, b: any, c: any, d: any, e: any): (boolean, string?, any)
	if not Remotes.allow(player, "Cosmetic", 6, 10) then
		return false, "Slow down", nil
	end
	if type(action) ~= "string" then
		return false, "Unknown action", nil
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "Still loading", nil
	end
	local canWrite, why = writable(player)
	if not canWrite then
		return false, why, nil
	end
	if action == "buy" then
		local ok, reason = CosmeticRules.buyWithCoins(profile, a)
		if ok then
			refreshWorld(player, {})
			StateService.toast(player, `Unlocked {Cosmetics.ById[a].name}!`, "success")
		end
		return ok, reason, nil
	elseif action == "buyRobux" then
		local item: Cosmetics.Item? = if type(a) == "string" then Cosmetics.ById[a] else nil
		local key = item and item.acquire.product
		local product = key and Cosmetics.Products[key]
		if not (item and product and type(product.productId) == "number" and productsLive()) then
			return false, "Not available for purchase yet", nil
		end
		if profile.cosmetics.owned[item.id] then
			return false, "Already owned", nil
		end
		-- The grant happens only in ProcessReceipt; the prompt's own result proves nothing.
		MarketplaceService:PromptProductPurchase(player, product.productId :: number)
		return true, nil, "prompted"
	elseif action == "equip" then
		local ok, reason = CosmeticRules.equipGhost(profile, a, b, c)
		if ok then
			refreshWorld(player, { ghosts = true })
		end
		return ok, reason, nil
	elseif action == "select" then
		local ok, reason = CosmeticRules.select(profile, a, b)
		if ok then
			refreshWorld(player, { house = a == "theme" })
		end
		return ok, reason, nil
	elseif action == "claim" then
		local ok, reason, granted = CosmeticRules.claim(profile, a)
		if ok then
			refreshWorld(player, {})
			local names = {}
			for _, id in granted do
				table.insert(names, Cosmetics.ById[id].name)
			end
			StateService.toast(player, `Reward unlocked: {table.concat(names, ", ")}`, "success")
		end
		return ok, reason, granted
	elseif action == "place" then
		local ok, reason, key = CosmeticRules.place(profile, a, b, c, d, e)
		if ok then
			refreshWorld(player, { decor = true })
		end
		return ok, reason, key
	elseif action == "move" then
		local ok, reason = CosmeticRules.move(profile, a, b, c, d, e)
		if ok then
			refreshWorld(player, { decor = true })
		end
		return ok, reason, nil
	elseif action == "store" then
		local ok, reason = CosmeticRules.store(profile, a)
		if ok then
			refreshWorld(player, { decor = true })
		end
		return ok, reason, nil
	end
	return false, "Unknown action", nil
end

CosmeticsService.action = onAction -- shared by the remote and the Studio scenarios

-- Robux grants. A receipt is applied once (its PurchaseId is remembered in the profile) and acknowledged only
-- after the profile save lands; until then Roblox retries it, and a retry of an already-applied receipt just
-- waits for the save again. Unknown products are left unprocessed.
local function processReceipt(info: any): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local profile = PlayerDataService.waitFor(player, 20)
	if not profile or not writable(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local result = CosmeticRules.applyReceipt(profile, info.PurchaseId, info.ProductId)
	if result == "invalid" then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	PlayerDataService.markDirty(player)
	local saved = PlayerDataService.persistence(player) ~= "saved" or PlayerDataService.saveNow(player)
	if not saved then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	if result == "granted" then
		local id = CosmeticRules.productItem(info.ProductId)
		StateService.toast(player, `Unlocked {id and Cosmetics.ById[id].name or "your item"}!`, "success")
		StateService.markDirty(player)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

CosmeticsService.processReceiptForTest = processReceipt

function CosmeticsService.start()
	if started then
		return
	end
	started = true
	Remotes.func("Cosmetic").OnServerInvoke = onAction
	MarketplaceService.ProcessReceipt = processReceipt
	StateService.addProvider(function(player, snap)
		local profile = PlayerDataService.get(player)
		if profile then
			snap.cosmetics = CosmeticRules.snapshot(profile, productsLive())
			snap.cosmeticsWritable = (writable(player))
		end
	end)
	PlotService.onAssigned(function(player)
		PlotService.rebuildDecorations(player)
	end)
	EconomyService.onTierChanged(function(player)
		local profile = PlayerDataService.get(player)
		if not profile then
			return
		end
		local stored = CosmeticRules.onTierChanged(profile)
		PlotService.rebuildHouse(player)
		PlotService.rebuildDecorations(player)
		if #stored > 0 then
			StateService.toast(player, `{#stored} decoration(s) no longer fit and went back to storage.`, "info")
		end
		PlayerDataService.markDirty(player)
		StateService.markDirty(player)
	end)
	CaptureService.onSecured(function(player)
		local profile = PlayerDataService.get(player)
		local id = profile and profile.cosmetics.capture
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if id and root and root:IsA("BasePart") then
			Remotes.event("CosmeticFx"):FireAllClients({ kind = "capture", id = id, position = root.Position })
		end
	end)
end

return CosmeticsService
