--!strict
-- Multi-client scenario (TASK-0006): a player who joins mid-match waits in the lobby, and the only
-- match player leaving drops the round back to the lobby without errors.
-- Runs inside the game's server, so it shares module state with the real services.
-- Launch (in the background, it takes about 60-80 s):
--   StudioTestService:ExecuteMultiplayerTestAsync(1, { scenario = "MatchJoinLeave", timeout = 60 })

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local StudioTestService = game:GetService("StudioTestService")

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local MatchService = require(Services:WaitForChild("MatchService")) :: any
local TrialService = require(Services:WaitForChild("TrialService")) :: any

local function waitFor(predicate: () -> boolean, timeout: number): boolean
	local deadline = os.clock() + timeout
	while not predicate() do
		if os.clock() > deadline then
			return false
		end
		task.wait(0.1)
	end
	return true
end

return function(args: { [string]: any }): { [string]: any }
	local timeout = if typeof(args.timeout) == "number" then args.timeout else 60
	if
		not waitFor(function()
			return #Players:GetPlayers() >= 1 and Players:GetPlayers()[1].Character ~= nil
		end, timeout)
	then
		return { ok = false, error = "first player never joined" }
	end
	local p1 = Players:GetPlayers()[1]
	TrialService.complete(p1, "test")
	local result: { [string]: any } = {}
	result.p1InCourse = waitFor(function()
		return MatchService.getState() == "Course" and MatchService.isInMatch(p1)
	end, 20)

	-- A second player joins mid-match.
	StudioTestService:AddPlayers(1)
	local p2: Player? = nil
	waitFor(function()
		for _, player in Players:GetPlayers() do
			if player ~= p1 and player.Character then
				p2 = player
			end
		end
		return p2 ~= nil
	end, timeout)
	if not p2 then
		return { ok = false, error = "second player never joined", partial = result }
	end
	local joiner = p2 :: Player
	TrialService.complete(joiner, "test")
	task.wait(1)
	result.stateWhileJoining = MatchService.getState()
	result.joinerInMatch = MatchService.isInMatch(joiner)
	result.joinerAttr = joiner:GetAttribute("InMatch")

	-- The only match player leaves.
	p1:Kick("MatchJoinLeave test")
	result.fellBackToLobby = waitFor(function()
		local s = MatchService.getState()
		return s == "Lobby" or s == "Countdown"
	end, 5)
	-- The waiting player now gets the next countdown.
	result.joinerGetsNextCountdown = waitFor(function()
		return MatchService.getState() == "Countdown"
	end, 5)

	result.ok = result.p1InCourse
		and result.stateWhileJoining == "Course"
		and result.joinerInMatch == false
		and result.fellBackToLobby
		and result.joinerGetsNextCountdown
	return result
end
