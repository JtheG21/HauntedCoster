--!strict
-- Home plots: builds them, assigns one per player, spawns players at home, and answers ownership questions.
-- Clients never name a plot; every lookup goes through the server's player -> plot map.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("World"))
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

function PlotService.ownerOf(index: number): Player?
	return owners[index]
end

-- World position of a plot-local point for the player's own plot.
function PlotService.toWorld(player: Player, localPos: Vector3): Vector3?
	local i = byPlayer[player]
	return if i then World.PlotCenters[i] + localPos else nil
end

function PlotService.isInOwnPlot(player: Player, pos: Vector3): boolean
	local i = byPlayer[player]
	if not i then
		return false
	end
	local o = World.PlotCenters[i]
	local s = World.PlotSize
	return math.abs(pos.X - o.X) <= s.X / 2 and math.abs(pos.Z - o.Z) <= s.Y / 2
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
	local caught, variants, clues = 0, 0, 0
	for _ in profile.journal.caught do
		caught += 1
	end
	for _ in profile.journal.variants do
		variants += 1
	end
	for _ in profile.journal.clues do
		clues += 1
	end
	PlotBuilder.buildTrophies(plots[i], i, caught, variants, clues)
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
	local pos = World.PlotCenters[i] + World.Plot.spawn
	local target = CFrame.lookAt(pos, pos + Vector3.new(0, 0, -1))
	-- Roblox places a new character at a SpawnLocation just after CharacterAdded fires, which would undo
	-- an immediate teleport. Move after that has happened, and re-check once in case it was late.
	for _, delay in { 0.2, 0.8 } do
		task.wait(delay)
		if character.Parent == nil or player.Character ~= character then
			return
		end
		-- Only correct a character Roblox left on the avenue spawn; never undo a move made since.
		local avenue = Vector3.new(0, 0, 40)
		local fromAvenue = Vector3.new(root.Position.X - avenue.X, 0, root.Position.Z - avenue.Z)
		if fromAvenue.Magnitude < 15 then
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
	for i = 1, #plots do
		if not owners[i] then
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
	PlotBuilder.buildTrophies(plots[i], i, 0, 0, 0)
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
	-- Neutral spawn on the avenue; players are moved home once their plot is assigned.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "AvenueSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, 0.5, 40)
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
