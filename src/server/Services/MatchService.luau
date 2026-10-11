--!strict
-- Match flow (TASK-0006): Lobby -> Countdown -> Course -> Finale -> Results -> Lobby.
-- State only changes through MatchRules.transition. Players who join mid-match wait in the lobby;
-- players leaving never break the round (an empty match falls back to the lobby).
-- Published to clients on ReplicatedStorage: MatchState, PhaseEndsAt (Workspace:GetServerTimeNow()
-- time, so clients can count down), LastResults. Per player: InMatch.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MatchConfig = require(Shared:WaitForChild("MatchConfig"))
local MatchRules = require(Shared:WaitForChild("MatchRules"))

local MatchService = {}

local state = "Lobby"
local phaseStarted = 0
local inMatch: { [Player]: boolean } = {}
local finishOrder: { Player } = {}
local matchStartListeners: { () -> () } = {}
local matchEndListeners: { () -> () } = {}
local eligibility: (player: Player) -> boolean = function(_player: Player)
	return true
end
local started = false

local function zone(name: string): BasePart
	local folder = Workspace:FindFirstChild("MatchZones")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "MatchZones"
		folder.Parent = Workspace
	end
	local existing = (folder :: Instance):FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local pad = Instance.new("Part")
	pad.Name = name
	pad.Anchored = true
	pad.Size = Vector3.new(16, 1, 16)
	pad.Position = (MatchConfig.Zones :: any)[name]
	pad.Material = Enum.Material.SmoothPlastic
	pad.Color = if name == "CourseFinish" then Color3.fromRGB(80, 200, 120) else Color3.fromRGB(120, 120, 140)
	pad.Parent = folder
	return pad
end

local function teleport(player: Player, zoneName: string, index: number?)
	local character = player.Character
	if not character then
		return
	end
	local pad = zone(zoneName)
	local i = index or 0
	local offset = Vector3.new((i % 4) * 3 - 4.5, pad.Size.Y / 2 + 3, math.floor(i / 4) * 3)
	character:PivotTo(CFrame.new(pad.Position + offset))
end

local function matchList(): { Player }
	local list = {}
	for player in inMatch do
		if player.Parent == Players then
			table.insert(list, player)
		end
	end
	return list
end

local function setState(to: string, duration: number?): boolean
	local newState, err = MatchRules.transition(state, to)
	if err then
		warn(`[MatchService] rejected {state} -> {to}: {err}`)
		return false
	end
	state = newState
	phaseStarted = os.clock()
	ReplicatedStorage:SetAttribute("MatchState", state)
	ReplicatedStorage:SetAttribute("PhaseEndsAt", if duration then Workspace:GetServerTimeNow() + duration else nil)
	return true
end

local function eligiblePlayers(): { Player }
	local list = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 and eligibility(player) then
			table.insert(list, player)
		end
	end
	return list
end

local function endMatch()
	for i, player in matchList() do
		player:SetAttribute("InMatch", false)
		teleport(player, "Lobby", i)
	end
	table.clear(inMatch)
	for _, listener in matchEndListeners do
		task.spawn(listener)
	end
end

local function startMatch(players: { Player })
	table.clear(inMatch)
	table.clear(finishOrder)
	for _, listener in matchStartListeners do
		local ok, err = pcall(function()
			listener()
		end)
		if not ok then
			warn(`[MatchService] match-start listener failed: {err}`)
		end
	end
	for i, player in players do
		inMatch[player] = true
		player:SetAttribute("InMatch", true)
		teleport(player, "CourseStart", i)
	end
end

local function finishedPlayers(): { Player }
	local pad = zone("CourseFinish")
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { pad }
	local found = {}
	local center = pad.CFrame * CFrame.new(0, 3, 0)
	for _, part in Workspace:GetPartBoundsInBox(center, Vector3.new(pad.Size.X, 5, pad.Size.Z), params) do
		local model = part:FindFirstAncestorOfClass("Model")
		local player = if model then Players:GetPlayerFromCharacter(model) else nil
		if player and inMatch[player] and not table.find(found, player) then
			table.insert(found, player)
		end
	end
	return found
end

local function tick()
	local now = os.clock()
	local elapsed = now - phaseStarted
	if state == "Lobby" then
		if MatchRules.shouldCountdown(#eligiblePlayers(), MatchConfig.MinPlayers) then
			setState("Countdown", MatchConfig.CountdownSeconds)
		end
	elseif state == "Countdown" then
		local eligible = eligiblePlayers()
		if not MatchRules.shouldCountdown(#eligible, MatchConfig.MinPlayers) then
			setState("Lobby")
		elseif elapsed >= MatchConfig.CountdownSeconds then
			startMatch(eligible)
			setState("Course", MatchConfig.CourseMaxSeconds)
		end
	elseif state == "Course" then
		for _, player in finishedPlayers() do
			if not table.find(finishOrder, player) then
				table.insert(finishOrder, player)
			end
		end
		local list = matchList()
		local finishedCount = 0
		for _, player in list do
			if table.find(finishOrder, player) then
				finishedCount += 1
			end
		end
		if #list == 0 then
			endMatch()
			setState("Lobby")
		elseif MatchRules.courseOver(finishedCount, #list, elapsed, MatchConfig.CourseMaxSeconds) then
			for i, player in list do
				teleport(player, "Finale", i)
			end
			setState("Finale", MatchConfig.FinaleSeconds)
		end
	elseif state == "Finale" then
		if #matchList() == 0 then
			endMatch()
			setState("Lobby")
		elseif elapsed >= MatchConfig.FinaleSeconds then
			local first = finishOrder[1]
			ReplicatedStorage:SetAttribute(
				"LastResults",
				if first then `Speed: {first.DisplayName} finished first` else "Speed: nobody finished"
			)
			setState("Results", MatchConfig.ResultsSeconds)
		end
	elseif state == "Results" then
		if elapsed >= MatchConfig.ResultsSeconds then
			endMatch()
			setState("Lobby")
		end
	end
end

function MatchService.getState(): string
	return state
end

function MatchService.isInMatch(player: Player): boolean
	return inMatch[player] == true
end

function MatchService.getMatchPlayers(): { Player }
	return matchList()
end

function MatchService.getFinishOrder(): { Player }
	return table.clone(finishOrder)
end

-- Extra condition for joining a match (TrialService: trial finished).
function MatchService.setEligibility(predicate: (player: Player) -> boolean)
	eligibility = predicate
end

function MatchService.onMatchStart(listener: () -> ())
	table.insert(matchStartListeners, listener)
end

function MatchService.onMatchEnd(listener: () -> ())
	table.insert(matchEndListeners, listener)
end

function MatchService.teleport(player: Player, zoneName: string)
	teleport(player, zoneName)
end

function MatchService.start()
	if started then
		return
	end
	started = true
	for name in MatchConfig.Zones :: { [string]: Vector3 } do
		zone(name)
	end
	ReplicatedStorage:SetAttribute("MatchState", state)
	phaseStarted = os.clock()

	Players.PlayerRemoving:Connect(function(player)
		inMatch[player] = nil
		local index = table.find(finishOrder, player)
		if index then
			table.remove(finishOrder, index)
		end
	end)
	-- Respawns go back to where the player belongs in the current phase.
	local function watch(player: Player)
		player.CharacterAdded:Connect(function()
			task.defer(function()
				if inMatch[player] then
					teleport(player, if state == "Finale" then "Finale" else "CourseStart")
				elseif eligibility(player) then
					teleport(player, "Lobby")
				end
			end)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				tick()
			end)
			if not ok then
				warn(`[MatchService] tick error: {err}`)
			end
			task.wait(MatchConfig.TickSeconds)
		end
	end)
end

return MatchService
