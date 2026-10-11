--!strict
-- Echo charges (TASK-0005): in-match, server-owned inventory of borrowed powers, earned by passing
-- a Convergence Gate. Mirrored to read-only Player attributes `Echo_<Power>` for the HUD.
-- Spending them is the finale's job (TASK-0007).

local Players = game:GetService("Players")

local EchoService = {}

local inventory: { [Player]: { [string]: number } } = {}
local started = false

function EchoService.add(player: Player, power: string, amount: number?)
	local bag = inventory[player]
	if not bag then
		bag = {}
		inventory[player] = bag
	end
	bag[power] = (bag[power] or 0) + (amount or 1)
	player:SetAttribute(`Echo_{power}`, bag[power])
end

function EchoService.get(player: Player, power: string): number
	local bag = inventory[player]
	return if bag then bag[power] or 0 else 0
end

-- Clears a player's charges (match end; TASK-0006).
function EchoService.reset(player: Player)
	local bag = inventory[player]
	if bag then
		for power in bag do
			player:SetAttribute(`Echo_{power}`, nil)
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
