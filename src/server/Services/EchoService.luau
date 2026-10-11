--!strict
-- Echo charges (TASK-0005): in-match, server-owned inventory of borrowed powers, earned by passing
-- a Convergence Gate. Mirrored to read-only Player attributes `Echo_<Power>` for the HUD.
-- Spent in the finale (TASK-0007, `spend`).

local Players = game:GetService("Players")

local EchoService = {}

local inventory: { [Player]: { [string]: number } } = {}
local listeners: { (player: Player, power: string, kind: string) -> () } = {}

local function notify(player: Player, power: string, kind: string)
	for _, listener in listeners do
		task.spawn(listener, player, power, kind)
	end
end
local started = false

function EchoService.add(player: Player, power: string, amount: number?)
	local bag = inventory[player]
	if not bag then
		bag = {}
		inventory[player] = bag
	end
	bag[power] = (bag[power] or 0) + (amount or 1)
	player:SetAttribute(`Echo_{power}`, bag[power])
	notify(player, power, "earned")
end

-- Called (in its own thread) when a charge is earned or spent; kind is "earned" or "spent" (TASK-0008).
function EchoService.onEvent(listener: (player: Player, power: string, kind: string) -> ())
	table.insert(listeners, listener)
end

function EchoService.get(player: Player, power: string): number
	local bag = inventory[player]
	return if bag then bag[power] or 0 else 0
end

-- Spends one charge (finale; TASK-0007). Returns false if the player has none.
function EchoService.spend(player: Player, power: string): boolean
	local bag = inventory[player]
	local count = if bag then bag[power] or 0 else 0
	if not bag or count <= 0 then
		return false
	end
	bag[power] = count - 1
	player:SetAttribute(`Echo_{power}`, if count - 1 > 0 then count - 1 else nil)
	notify(player, power, "spent")
	return true
end

-- Clears a player's charges (match end; TASK-0006).
function EchoService.reset(player: Player)
	-- Clear every Echo_ attribute, not only tracked ones, so the HUD can never show stale charges.
	for name in player:GetAttributes() do
		if string.sub(name, 1, 5) == "Echo_" then
			player:SetAttribute(name, nil)
		end
	end
	inventory[player] = nil
end

function EchoService.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		inventory[player] = nil
	end)
end

return EchoService
