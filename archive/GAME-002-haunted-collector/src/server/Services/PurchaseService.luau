--!strict
-- Coin purchases of catalog cosmetics (TASK-0067). The client names an item and a request ID; the server reads
-- the price from the catalog, debits and grants in one update, and remembers the answer by request ID, so a
-- retry or a double submit returns the same result and never charges twice. Coins only: nothing here opens a
-- Robux prompt. A purchase is saved with the normal autosave; debit and grant live in one profile table, so a
-- crash loses both or neither.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.Config.Catalog)
local PurchaseRules = require(Shared.Rules.PurchaseRules)
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)

local PurchaseService = {}

local started = false
local receipts: { [Player]: { PurchaseRules.Receipt } } = {}

local function catalog()
	return { Items = Catalog.Items, Rewards = Catalog.Rewards }
end

-- Shared by the BuyItem remote and the Studio scenarios. Returns ok and a player-facing message.
function PurchaseService.buy(player: Player, itemId: any, requestId: any): (boolean, string?)
	local req, bad = PurchaseRules.parse(itemId, requestId)
	if not req then
		return false, bad
	end
	local list = receipts[player]
	if not list then
		list = {}
		receipts[player] = list
	end
	local seen = PurchaseRules.recall(list, req.requestId, req.itemId)
	if seen then
		return seen.ok, seen.message -- a retry gets the first answer; nothing is charged again
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return false, "Your data is still loading." -- not remembered, so a retry can succeed
	end
	local cat = catalog()
	local quote = PurchaseRules.quote(profile.coins, profile.cosmetics, cat, req.itemId)
	local item = cat.Items[req.itemId]
	local okApply, reason = false, nil :: string?
	local applied = PlayerDataService.update(player, function(p)
		okApply, reason = PurchaseRules.apply(p, cat, req.itemId)
	end)
	if not applied then
		return false, "Your data is still loading."
	end
	local message: string? = nil
	if okApply then
		local name = (item and item.name) or req.itemId
		message = `Bought {name} for {quote.cost} Coins.`
		StateService.toast(player, message :: string, "success")
	else
		message = PurchaseRules.message(reason, item, quote)
	end
	if PurchaseRules.isFinal(reason) then
		PurchaseRules.remember(list, { id = req.requestId, itemId = req.itemId, ok = okApply, message = message })
	end
	StateService.markDirty(player)
	return okApply, message
end

function PurchaseService.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		receipts[player] = nil
	end)
	Remotes.func("BuyItem").OnServerInvoke = function(player, itemId, requestId)
		if not Remotes.allow(player, "BuyItem", 3, 6) then
			return false, "Slow down."
		end
		return PurchaseService.buy(player, itemId, requestId)
	end
end

return PurchaseService
