--!strict
-- Read-only catalog for the Shop and Owned screens (TASK-0061). Ownership already reaches the client in the
-- State snapshot (`cosmetics`). There is no purchase, equip or claim here: those arrive with later tasks.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = require(script.Parent.Parent.Remotes)
local Catalog = require(ReplicatedStorage.Shared.Config.Catalog)

local ShopService = {}

local started = false

-- A fresh copy, so nothing a client does to its replica can matter and the config stays frozen server-side.
function ShopService.catalog(): { items: { [string]: any }, rewards: { [string]: any } }
	local items: { [string]: any } = {}
	for id, item in Catalog.Items do
		items[id] = table.clone(item)
	end
	local rewards: { [string]: any } = {}
	for id, reward in Catalog.Rewards do
		rewards[id] = { grants = table.clone(reward.grants) }
	end
	return { items = items, rewards = rewards }
end

function ShopService.start()
	if started then
		return
	end
	started = true
	Remotes.func("GetCatalog").OnServerInvoke = function(player)
		if not Remotes.allow(player, "GetCatalog", 1, 4) then
			return nil
		end
		return ShopService.catalog()
	end
end

return ShopService
