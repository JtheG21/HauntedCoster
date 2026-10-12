--!strict
-- Drives the first-session tutorial (TutorialRules) from live player state, persists the step,
-- and exposes the current hint to the client snapshot. Never blocks normal play.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared:WaitForChild("Config"):WaitForChild("World"))
local TutorialRules = require(Shared:WaitForChild("Rules"):WaitForChild("TutorialRules"))
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local CaptureService = require(script.Parent.CaptureService)
local PlotService = require(script.Parent.PlotService)

local TutorialService = {}

local NEAR_STATION_STUDS = 20
local NEAR_MONSTER_STUDS = 30

local started = false

local function count(t: { [string]: boolean }): number
	local n = 0
	for _ in t do
		n += 1
	end
	return n
end

local function nearMonster(pos: Vector3): boolean
	local folder = Workspace:FindFirstChild("Monsters")
	for _, m in (if folder then folder:GetChildren() else {}) :: { Instance } do
		if m:IsA("Model") and m.PrimaryPart and (m.PrimaryPart.Position - pos).Magnitude <= NEAR_MONSTER_STUDS then
			return true
		end
	end
	return false
end

local function ctxFor(player: Player): TutorialRules.Ctx?
	local profile = PlayerDataService.get(player)
	if not profile then
		return nil
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local pos = if root and root:IsA("BasePart") then root.Position else nil
	local index = PlotService.plotIndex(player)
	local plot = index and PlotService.plotModel(index)
	local track = plot and plot:FindFirstChild("Track")
	local station = track and track:FindFirstChild("Station")
	return {
		nearTrain = pos ~= nil
			and station ~= nil
			and station:IsA("BasePart")
			and (station.Position - pos).Magnitude <= NEAR_STATION_STUDS,
		viewedCollection = profile.flags.journalOpened == true or profile.flags.mansionOpened == true,
		inGraveyard = pos ~= nil and World.inRect(World.Graveyard.rect, pos.X, pos.Z),
		nearMonster = pos ~= nil and nearMonster(pos),
		seenCount = count(profile.journal.seen),
		captureTried = profile.flags.captureTried == true,
		carrying = CaptureService.isCarrying(player),
		owned = #profile.owned,
		speedLevel = profile.speedLevel,
		houseTier = profile.houseTier,
		routeCustom = profile.flags.routeCustom == true,
		exhibits = #profile.exhibits,
		rides = profile.stats.rides,
		inCrypt = pos ~= nil and World.inRect(World.Graveyard.crypt, pos.X, pos.Z),
		caughtRare = profile.journal.caught.BellWraith == true,
	}
end

local lastHint: { [Player]: string } = {}

local function tick(player: Player)
	local profile = PlayerDataService.get(player)
	local ctx = ctxFor(player)
	if not (profile and ctx) then
		return
	end
	local step = TutorialRules.advance(profile.tutorialStep, ctx)
	if step ~= profile.tutorialStep then
		PlayerDataService.update(player, function(p)
			p.tutorialStep = step
		end)
	end
	local hint = TutorialRules.hint(step, ctx)
	if hint ~= lastHint[player] then
		lastHint[player] = hint
		StateService.markDirty(player)
	end
end

function TutorialService.start()
	if started then
		return
	end
	started = true
	Players.PlayerRemoving:Connect(function(player)
		lastHint[player] = nil
	end)
	StateService.addProvider(function(player, snap)
		local profile = PlayerDataService.get(player)
		local ctx = ctxFor(player)
		if profile and ctx then
			snap.tutorial = {
				step = profile.tutorialStep,
				total = #TutorialRules.Steps,
				hint = TutorialRules.hint(profile.tutorialStep, ctx),
			}
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				task.spawn(tick, player)
			end
		end
	end)
end

return TutorialService
