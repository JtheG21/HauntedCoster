--!strict
-- Home plots: builds them, assigns one per player, spawns players at home, and answers ownership questions.
-- Clients never name a plot; every lookup goes through the server's player -> plot map.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("World"))
local PlotRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Rules"):WaitForChild("PlotRules"))
local PlotBuilder = require(script.Parent.Parent.World.PlotBuilder)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)

local PlotService = {}

local started = false
local plots: { Model } = {}
local owners: { [number]: Player } = {}
local byPlayer: { [Player]: number } = {}
local assignedCallbacks: { (Player, number) -> () } = {}

function PlotService.plotIndex(player: Player): number?
	return byPlayer[player]
end

function PlotService.plotModel(index: number): Model?
	return plots[index]
end

function PlotService.origin(index: number): Vector3
	return World.PlotCenters[index]
end

function PlotService.frame(index: number): CFrame
	return World.plotFrame(index)
end

function PlotService.ownerOf(index: number): Player?
	return owners[index]
end

-- World position of a plot-local point for the player's own plot.
function PlotService.toWorld(player: Player, localPos: Vector3): Vector3?
	local i = byPlayer[player]
	return if i then World.plotToWorld(i, localPos) else nil
end

-- Measured in plot-local space, so it holds for rotated plots.
function PlotService.isInOwnPlot(player: Player, pos: Vector3): boolean
	local i = byPlayer[player]
	if not i then
		return false
	end
	local l = World.worldToPlot(i, pos)
	local s = World.PlotSize
	return math.abs(l.X) <= s.X / 2 and math.abs(l.Z) <= s.Y / 2
end

function PlotService.onAssigned(cb: (Player, number) -> ())
	table.insert(assignedCallbacks, cb)
	for player, i in byPlayer do
		task.spawn(cb, player, i)
	end
end

function PlotService.rebuildHouse(player: Player)
	local i = byPlayer[player]
	local profile = PlayerDataService.get(player)
	if i and profile then
		PlotBuilder.buildHouse(plots[i], i, profile.houseTier)
	end
end

function PlotService.rebuildTrophies(player: Player)
	local i = byPlayer[player]
	local profile = PlayerDataService.get(player)
	if not (i and profile) then
		return
	end
	local caught, variants = 0, 0
	for _ in profile.journal.caught do
		caught += 1
	end
	for _ in profile.journal.variants do
		variants += 1
	end
	PlotBuilder.buildTrophies(plots[i], i, caught, variants)
end

local function spawnAtHome(player: Player, character: Model)
	local i = byPlayer[player]
	if not i then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not (root and root:IsA("BasePart")) then
		return
	end
	local pos = World.plotToWorld(i, World.Plot.spawn)
	local target = CFrame.lookAt(pos, pos + World.plotDirToWorld(i, Vector3.new(0, 0, -1))) -- facing the hub
	-- Roblox places a new character at a SpawnLocation just after CharacterAdded fires, which would undo
	-- an immediate teleport. Move after that has happened, and re-check once in case it was late.
	for _, delay in { 0.2, 0.8 } do
		task.wait(delay)
		if character.Parent == nil or player.Character ~= character then
			return
		end
		-- Only correct a character Roblox left on the neutral spawn; never undo a move made since.
		local neutral = World.NeutralSpawn
		local fromNeutral = Vector3.new(root.Position.X - neutral.X, 0, root.Position.Z - neutral.Z)
		if fromNeutral.Magnitude < 15 then
			character:PivotTo(target)
		end
	end
end

local function assign(player: Player)
	if byPlayer[player] then
		return
	end
	-- Keep waiting for the profile for as long as the player stays (a slow load must not leave them plotless).
	local profile = nil
	while player.Parent and not profile do
		profile = PlayerDataService.waitFor(player, 30)
	end
	if not profile or not player.Parent then
		return
	end
	local i = PlotRules.firstFree(owners, #plots)
	if i then
		owners[i] = player
		byPlayer[player] = i
		PlotBuilder.setOwner(plots[i], player)
		PlotBuilder.buildHouse(plots[i], i, profile.houseTier)
		player:SetAttribute("PlotIndex", i)
		PlotService.rebuildTrophies(player)
		for _, cb in assignedCallbacks do
			task.spawn(cb, player, i)
		end
		if player.Character then
			task.spawn(spawnAtHome, player, player.Character)
		end
		StateService.markDirty(player)
		return
	end
	warn(`[Plots] no free plot for {player.Name}`)
	StateService.toast(
		player,
		"All plots are taken on this server. You can explore, but progress needs a plot.",
		"error"
	)
end

local function release(player: Player)
	local i = byPlayer[player]
	if not i then
		return
	end
	byPlayer[player] = nil
	owners[i] = nil
	PlotBuilder.setOwner(plots[i], nil)
	PlotBuilder.buildHouse(plots[i], i, 0)
	PlotBuilder.buildTrophies(plots[i], i, 0, 0)
	local residents = plots[i]:FindFirstChild("Pen")
	residents = residents and residents:FindFirstChild("Residents")
	if residents then
		residents:ClearAllChildren()
	end
end

function PlotService.start()
	if started then
		return
	end
	started = true
	local folder = Instance.new("Folder")
	folder.Name = "Plots"
	folder.Parent = Workspace
	for i = 1, #World.PlotCenters do
		plots[i] = PlotBuilder.build(folder, i)
	end
	-- The place's Max Players must not exceed the plots (World.MaxPlayers, TASK-0037). Studio test servers
	-- use their own player count, so only live servers are checked.
	if not RunService:IsStudio() and Players.MaxPlayers > #plots then
		warn(`[Plots] Max Players is {Players.MaxPlayers} but there are only {#plots} plots`)
	end
	-- Neutral spawn on the ring road; players are moved home once their plot is assigned.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NeutralSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = World.NeutralSpawn + Vector3.new(0, 0.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = Workspace

	StateService.addProvider(function(player, snap)
		snap.plotIndex = byPlayer[player]
	end)
	local function onPlayer(player: Player)
		player.CharacterAdded:Connect(function(character)
			spawnAtHome(player, character)
		end)
		task.spawn(assign, player)
	end
	Players.PlayerAdded:Connect(onPlayer)
	Players.PlayerRemoving:Connect(release)
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
end

return PlotService
