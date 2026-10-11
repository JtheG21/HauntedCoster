--!strict
-- Multi-client scenario (TASK-0003): with N players joined, factions are auto-balanced within 1.
-- Launch: StudioTestService:ExecuteMultiplayerTestAsync(4, { scenario = "FactionBalance", players = 4 })

local Players = game:GetService("Players")

return function(args: { [string]: any }): { [string]: any }
	local wanted = if typeof(args.players) == "number" then args.players else 2
	local timeout = if typeof(args.timeout) == "number" then args.timeout else 30
	local deadline = os.clock() + timeout
	while #Players:GetPlayers() < wanted and os.clock() < deadline do
		task.wait(0.2)
	end
	task.wait(1)
	local counts: { [string]: number } = {}
	local unassigned = 0
	for _, player in Players:GetPlayers() do
		local faction = player:GetAttribute("Faction")
		if typeof(faction) == "string" then
			counts[faction] = (counts[faction] or 0) + 1
		else
			unassigned += 1
		end
	end
	local low, high = math.huge, 0
	for _, faction in { "Shinobi", "Ki" } do
		local count = counts[faction] or 0
		low = math.min(low, count)
		high = math.max(high, count)
	end
	return {
		ok = #Players:GetPlayers() == wanted and unassigned == 0 and high - low <= 1,
		players = #Players:GetPlayers(),
		wanted = wanted,
		waited = math.floor(os.clock() - (deadline - timeout)),
		counts = counts,
		unassigned = unassigned,
	}
end
