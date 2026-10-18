--!strict
-- Coin purchases of catalog cosmetics (TASK-0067). Pure, so every outcome is unit-tested. The server is the only
-- place a price is read: it comes from the catalog (`coinPrice`), never from the client. A purchase debits and
-- grants in one synchronous step, so it either does both or neither, and owning an item makes a repeat a no-op.
-- Coins only: there is no Robux path here, and a refusal never offers one. Prices in the catalog are
-- PLACEHOLDERS that need jg's tuning from measured income.

local CatalogConfig = require(script.Parent.Parent.Config.Catalog)
local CosmeticRules = require(script.Parent.CosmeticRules)
local EconomyRules = require(script.Parent.EconomyRules)
local ProfileRules = require(script.Parent.ProfileRules)

local PurchaseRules = {}

PurchaseRules.MaxReceipts = 20 -- remembered request IDs per player (a session cache, not saved)

export type Request = { itemId: string, requestId: string }
export type Quote = { ok: boolean, reason: string?, cost: number, need: number }
export type Receipt = { id: string, itemId: string, ok: boolean, message: string? }

-- Untrusted remote arguments: an item ID and a client-made request ID that makes a retry safe.
function PurchaseRules.parse(itemId: any, requestId: any): (Request?, string?)
	if not CosmeticRules.isId(itemId) then
		return nil, "Something went wrong. Try again."
	end
	if
		type(requestId) ~= "string"
		or #requestId == 0
		or #requestId > 40
		or string.match(requestId, "^[%w_%-]+$") == nil
	then
		return nil, "Something went wrong. Try again."
	end
	return { itemId = itemId :: string, requestId = requestId }, nil
end

-- The price of an item in Coins, or nil if it can't be bought with Coins.
function PurchaseRules.price(catalog: CosmeticRules.Catalog, itemId: string): number?
	local item = catalog.Items[itemId] :: CatalogConfig.Item?
	local price = item and item.coinPrice
	if type(price) == "number" and price > 0 and price == math.floor(price) and price <= 1e9 then
		return price
	end
	return nil
end

-- Whether `coins` buys `itemId` for a player with this cosmetic state. `need` is the exact shortfall.
function PurchaseRules.quote(
	coins: number,
	state: CosmeticRules.State,
	catalog: CosmeticRules.Catalog,
	itemId: string
): Quote
	local item = catalog.Items[itemId]
	if item == nil then
		return { ok = false, reason = "unknown", cost = 0, need = 0 }
	end
	local cost = PurchaseRules.price(catalog, itemId)
	if cost == nil then
		return { ok = false, reason = "notBuyable", cost = 0, need = 0 }
	end
	if state.entitlements[itemId] then
		return { ok = false, reason = "alreadyOwned", cost = cost, need = 0 }
	end
	if coins < cost then
		return { ok = false, reason = "insufficient", cost = cost, need = cost - coins }
	end
	return { ok = true, cost = cost, need = 0 }
end

-- Debits and grants in place. Returns (ok, reason). On any failure nothing changes: the grant happens first
-- (it can refuse a full collection), the debit only after it succeeded. No yield between the two.
function PurchaseRules.apply(
	profile: ProfileRules.Profile,
	catalog: CosmeticRules.Catalog,
	itemId: string
): (boolean, string?)
	local q = PurchaseRules.quote(profile.coins, profile.cosmetics, catalog, itemId)
	if not q.ok then
		return false, q.reason
	end
	local ok, why = CosmeticRules.grant(profile.cosmetics, catalog, itemId)
	if not ok then
		return false, why
	end
	EconomyRules.addCoins(profile, -q.cost)
	return true, nil
end

-- Whether a refusal is permanent for this item (so remembering it is right). A shortfall or a full collection can
-- change, so those are never remembered and a retry is judged afresh.
function PurchaseRules.isFinal(reason: string?): boolean
	return reason == nil or reason == "alreadyOwned" or reason == "notBuyable" or reason == "unknown"
end

function PurchaseRules.message(reason: string?, item: { name: string? }?, quote: Quote?): string
	local name = (item and item.name) or "that item"
	if reason == "insufficient" and quote then
		return `You need {quote.need} more Coins for {name}.`
	elseif reason == "alreadyOwned" then
		return `You already own {name}.`
	elseif reason == "notBuyable" then
		return "That isn't for sale yet."
	elseif reason == "unknown" then
		return "That item isn't available."
	elseif reason == "full" then
		return "Your collection is full."
	end
	return "Something went wrong. Try again."
end

-- A bounded list of recent results by request ID, so a retried request returns the same answer and never
-- charges twice. Oldest entries fall off.
function PurchaseRules.remember(receipts: { Receipt }, receipt: Receipt)
	table.insert(receipts, receipt)
	while #receipts > PurchaseRules.MaxReceipts do
		table.remove(receipts, 1)
	end
end

-- A receipt answers only the same request ID for the same item, so reusing an ID for another item is a new request.
function PurchaseRules.recall(receipts: { Receipt }, requestId: string, itemId: string): Receipt?
	for _, r in receipts do
		if r.id == requestId and r.itemId == itemId then
			return r
		end
	end
	return nil
end

return PurchaseRules
