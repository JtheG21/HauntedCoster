--!strict
-- What the Shop and Owned screens show, as data (TASK-0061). Pure, so every state is unit-tested. Ownership
-- comes only from the server's cosmetic state: unknown ownership is "loading", never "unowned". There is no
-- price and no Buy action anywhere: a card is only ever "earnable" through a reward, or "not available yet".

local CosmeticRules = require(script.Parent.CosmeticRules)
local PurchaseRules = require(script.Parent.PurchaseRules)

local ShopRules = {}

ShopRules.Categories = { "Skin", "Aura", "CaptureEffect", "Theme", "Decoration" }

export type Filter = {
	category: string?, -- nil: all categories
	ownership: string?, -- "all" (default) | "owned" | "unowned"
	acquisition: string?, -- "all" (default) | "buyable" | "earnable" | "notYet"
}
export type Card = {
	id: string,
	name: string,
	category: string?, -- nil for an owned ID the catalog no longer lists
	listed: boolean,
	owned: boolean,
	equipped: boolean,
	equippedOn: { string }, -- "ghost:<uid>", "captureEffect", "theme", "placed"
	acquisition: string, -- "owned" | "buyable" | "earnable" | "notYet"
	rewardId: string?,
	price: number?, -- Coins, from the catalog (PurchaseRules.price); nil if not for sale
	canBuy: boolean, -- true only for an unowned item with a Coin price
}
export type View = {
	status: string, -- "loading" | "unavailable" | "empty" | "noMatch" | "ready"
	cards: { Card },
	notice: string?,
}
export type Input = {
	catalog: CosmeticRules.Catalog?, -- nil: the catalog could not be loaded
	cosmetics: CosmeticRules.State?, -- nil: ownership not known yet
	persistence: string?, -- "saved" | "memory" | "readonly" | "loading"
}

local function equippedOn(s: CosmeticRules.State, id: string): { string }
	local out: { string } = {}
	local uids: { string } = {}
	for uid in s.ghostLooks do
		table.insert(uids, uid)
	end
	table.sort(uids)
	for _, uid in uids do
		local look = s.ghostLooks[uid]
		if look.skin == id or look.aura == id then
			table.insert(out, "ghost:" .. uid)
		end
	end
	if s.captureEffect == id then
		table.insert(out, "captureEffect")
	end
	if s.mansionTheme == id then
		table.insert(out, "theme")
	end
	for _, pl in s.placements do
		if pl.id == id then
			table.insert(out, "placed")
			break
		end
	end
	return out
end

local function rewardFor(catalog: CosmeticRules.Catalog, id: string): string?
	local ids: { string } = {}
	for rid in catalog.Rewards do
		table.insert(ids, rid)
	end
	table.sort(ids)
	for _, rid in ids do
		if table.find(catalog.Rewards[rid].grants, id) then
			return rid
		end
	end
	return nil
end

local function card(catalog: CosmeticRules.Catalog, s: CosmeticRules.State, id: string): Card
	local item = catalog.Items[id]
	local owned = s.entitlements[id] == true
	local rewardId = rewardFor(catalog, id)
	local where = equippedOn(s, id)
	local price = if item then PurchaseRules.price(catalog, id) else nil
	local buyable = price ~= nil and not owned
	return {
		id = id,
		name = if item and item.name then item.name else id,
		category = if item then item.category else nil,
		listed = item ~= nil,
		owned = owned,
		equipped = #where > 0,
		equippedOn = where,
		acquisition = (
				if owned then "owned" elseif buyable then "buyable" elseif rewardId then "earnable" else "notYet"
			) :: string,
		rewardId = rewardId,
		price = price,
		canBuy = buyable,
	}
end

local function acquisitionMatches(want: string, have: string): boolean
	return want == "all" or want == have
end

local function passes(c: Card, f: Filter): boolean
	if f.category ~= nil and c.category ~= f.category then
		return false
	end
	if f.ownership == "owned" and not c.owned then
		return false
	elseif f.ownership == "unowned" and c.owned then
		return false
	end
	-- An unowned item that can be bought and earned also shows under "earnable".
	local have = if c.acquisition == "buyable"
			and c.rewardId ~= nil
			and f.acquisition == "earnable"
		then "earnable"
		else c.acquisition
	return acquisitionMatches(f.acquisition or "all", have)
end

local function sorted(a: Card, b: Card): boolean
	if a.owned ~= b.owned then
		return not a.owned -- unowned first in the Shop; the Owned tab only holds owned cards
	end
	if a.name ~= b.name then
		return a.name < b.name
	end
	return a.id < b.id
end

-- tab: "Shop" lists the catalog; "Owned" lists every entitlement, including ones the catalog doesn't list.
function ShopRules.view(input: Input, tab: string, filter: Filter?): View
	local f: Filter = filter or {}
	if input.cosmetics == nil or input.persistence == "loading" then
		return { status = "loading", cards = {} }
	end
	local catalog = input.catalog
	if catalog == nil then
		return { status = "unavailable", cards = {} }
	end
	local s = input.cosmetics
	local notice: string? = nil
	if input.persistence == "readonly" then
		notice = "Saving is unavailable, so changes are off for now."
	elseif input.persistence == "memory" then
		notice = "Progress isn't being saved this session."
	end

	local ids: { string } = {}
	if tab == "Owned" then
		for id in s.entitlements do
			table.insert(ids, id)
		end
	else
		for id in catalog.Items do
			table.insert(ids, id)
		end
	end
	local all: { Card } = {}
	for _, id in ids do
		table.insert(all, card(catalog, s, id))
	end
	local cards: { Card } = {}
	for _, c in all do
		if passes(c, f) then
			table.insert(cards, c)
		end
	end
	table.sort(cards, sorted)
	if #all == 0 then
		return { status = "empty", cards = {}, notice = notice }
	elseif #cards == 0 then
		return { status = "noMatch", cards = {}, notice = notice }
	end
	return { status = "ready", cards = cards, notice = notice }
end

-- Turns the GetCatalog reply into the Catalog shape, or nil if it isn't well-formed (the client treats nil as
-- "couldn't load", never as an empty shop). The reply came over a remote, so every field is checked.
function ShopRules.catalogFromWire(raw: any): CosmeticRules.Catalog?
	if type(raw) ~= "table" or type(raw.items) ~= "table" or type(raw.rewards) ~= "table" then
		return nil
	end
	local items: { [string]: any } = {}
	for id, item in raw.items do
		if
			not CosmeticRules.isId(id)
			or type(item) ~= "table"
			or table.find(ShopRules.Categories, item.category) == nil
		then
			return nil
		end
		if item.name ~= nil and type(item.name) ~= "string" then
			return nil
		end
		items[id] = item
	end
	local rewards: { [string]: any } = {}
	for id, reward in raw.rewards do
		if not CosmeticRules.isId(id) or type(reward) ~= "table" or type(reward.grants) ~= "table" then
			return nil
		end
		rewards[id] = reward
	end
	return { Items = items, Rewards = rewards }
end

function ShopRules.emptyText(status: string, tab: string): string
	if status == "loading" then
		return "Loading..."
	elseif status == "unavailable" then
		return "The shop couldn't load. Close it and try again."
	elseif status == "empty" then
		return if tab == "Owned" then "You don't own any cosmetics yet." else "Nothing is in the shop yet."
	elseif status == "noMatch" then
		return "Nothing matches these filters."
	end
	return ""
end

function ShopRules.acquisitionLabel(c: Card): string
	if c.acquisition == "owned" then
		return if c.equipped then "Owned, in use" else "Owned"
	elseif c.acquisition == "buyable" then
		return if c.rewardId then `Costs {c.price} Coins, or earn it` else `Costs {c.price} Coins`
	elseif c.acquisition == "earnable" then
		return "Earned through a reward"
	end
	return "Not available yet"
end

return ShopRules
