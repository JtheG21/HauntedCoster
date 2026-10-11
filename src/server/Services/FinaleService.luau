--!strict
-- Ring-out finale (TASK-0007): a floating arena where match players knock each other off.
-- Falling below the deck (or being flung out of bounds, or dying) eliminates a player once; the
-- last one standing wins Combat. Also keeps the per-match Teamwork tally (gate contributions) and
-- computes the category results.
-- Published: ReplicatedStorage FinaleRemaining; per player FinaleAlive, FinaleGuard;
-- ReplicatedStorage Result_Speed, Result_Teamwork, Result_Combat (display names, for the HUD).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FinaleConfig = require(Shared:WaitForChild("FinaleConfig"))
local MatchConfig = require(Shared:WaitForChild("MatchConfig"))
local ResultRules = require(Shared:WaitForChild("ResultRules"))

local FinaleService = {}

local active = false
-- Set once the finale is decided (audit F1): no more eliminations, knockback, guards or spends, so
-- the results are read from a frozen snapshot no matter when MatchService asks for them.
local concluded = false
local startedAt = 0
local starters = 0
local alive: { [Player]: boolean } = {}
local lastOut: { number } = {} -- UserIds eliminated in the most recent elimination poll
local guards: { [Player]: number } = {} -- guard expiry (os.clock)
local contributions: { [number]: number } = {}
local names: { [number]: string } = {}
local started = false

local function center(): Vector3
	local zone = (MatchConfig.Zones :: any).Finale :: Vector3
	return Vector3.new(zone.X, FinaleConfig.TopY, zone.Z)
end

local function arenaFolder(): Folder
	local existing = Workspace:FindFirstChild("FinaleArena")
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = "FinaleArena"
	folder.Parent = Workspace
	return folder
end

local function makePart(folder: Folder, name: string, size: Vector3, position: Vector3, color: Color3): BasePart
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		return existing
	end
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Material = Enum.Material.SmoothPlastic
	part.Color = color
	part.Parent = folder
	return part
end

-- Builds the greybox arena from FinaleConfig (matches maps/finale_arena.json).
local function buildArena()
	local folder = arenaFolder()
	local c = center()
	local deck = FinaleConfig.DeckSize
	makePart(folder, "Deck", deck, c - Vector3.new(0, deck.Y / 2, 0), Color3.fromRGB(70, 70, 95))
	local bump = FinaleConfig.BumpSize
	for i = 1, 4 do
		local angle = (i - 1) * math.pi / 2
		local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * FinaleConfig.BumpRadius
		makePart(folder, `Bump{i}`, bump, c + offset + Vector3.new(0, bump.Y / 2, 0), Color3.fromRGB(95, 95, 125))
	end
	local spectate = Vector3.new(c.X, 1, c.Z) + FinaleConfig.SpectateOffset
	makePart(folder, "Spectate", Vector3.new(24, 1, 12), spectate, Color3.fromRGB(120, 120, 140))
end

local function aliveCount(): number
	local n = 0
	for player in alive do
		if alive[player] then
			n += 1
		end
	end
	return n
end

local function publishRemaining()
	ReplicatedStorage:SetAttribute("FinaleRemaining", if active then aliveCount() else nil)
end

local function toSpectate(player: Player)
	local character = player.Character
	if character then
		local c = center()
		character:PivotTo(CFrame.new(Vector3.new(c.X, 4, c.Z) + FinaleConfig.SpectateOffset))
	end
end

local function eliminate(player: Player)
	if not alive[player] then
		return
	end
	alive[player] = false
	guards[player] = nil
	player:SetAttribute("FinaleAlive", false)
	player:SetAttribute("FinaleGuard", nil)
	toSpectate(player)
end

local function isOut(player: Player): boolean
	if player.Parent ~= Players then
		return true
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and root and root:IsA("BasePart")) or humanoid.Health <= 0 then
		return true
	end
	return ResultRules.isRingOut(
		root.Position,
		center(),
		FinaleConfig.TopY,
		FinaleConfig.RingOutDepth,
		FinaleConfig.BoundsRadius
	)
end

local function conclude()
	if active and not concluded then
		concluded = true
		table.clear(guards)
		for player in alive do
			if player.Parent == Players then
				player:SetAttribute("FinaleGuard", nil)
			end
		end
	end
end

local function checkConcluded()
	if
		active
		and not concluded
		and ResultRules.finaleOver(starters, aliveCount(), os.clock() - startedAt, FinaleConfig.MaxSeconds)
	then
		conclude()
	end
end

local function poll()
	if not active or concluded or os.clock() - startedAt < FinaleConfig.StartGraceSeconds then
		return
	end
	local batch = {}
	for player, isAlive in alive do
		if isAlive and isOut(player) then
			table.insert(batch, player)
		end
	end
	if #batch > 0 then
		-- Everyone found in the same poll goes out together (a simultaneous elimination).
		lastOut = {}
		for _, player in batch do
			table.insert(lastOut, player.UserId)
			eliminate(player)
		end
		publishRemaining()
	end
	checkConcluded()
	local now = os.clock()
	for player, expiry in guards do
		if now >= expiry then
			guards[player] = nil
			if player.Parent == Players then
				player:SetAttribute("FinaleGuard", nil)
			end
		end
	end
end

-- Starts the finale with the given match players: teleports them onto the deck.
function FinaleService.begin(players: { Player })
	buildArena()
	table.clear(alive)
	table.clear(guards)
	lastOut = {}
	starters = 0
	active = true
	concluded = false
	startedAt = os.clock()
	local c = center()
	for i, player in players do
		if player.Parent ~= Players then
			continue
		end
		names[player.UserId] = player.DisplayName
		-- A player who is dead or respawning when the course ends doesn't start the finale (audit F4):
		-- counting them would eliminate them on the first poll and hand a rival an instant win.
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not (humanoid and humanoid.Health > 0) then
			alive[player] = false
			player:SetAttribute("FinaleAlive", false)
			continue
		end
		starters += 1
		alive[player] = true
		player:SetAttribute("FinaleAlive", true)
		local spawn = FinaleConfig.Spawns[((i - 1) % #FinaleConfig.Spawns) + 1]
		if character then
			character:PivotTo(CFrame.lookAt(c + spawn, Vector3.new(c.X, c.Y + spawn.Y, c.Z)))
		end
	end
	publishRemaining()
end

function FinaleService.isActive(): boolean
	return active
end

-- Alive and still able to act (false once the finale is decided).
function FinaleService.isAlive(player: Player): boolean
	return active and not concluded and alive[player] == true
end

function FinaleService.isOver(): boolean
	checkConcluded() -- also covers the time limit
	return concluded
end

-- Where a match player should respawn during the finale.
function FinaleService.respawn(player: Player)
	if alive[player] and not concluded then
		-- A respawn means the old character died before the poll saw it.
		lastOut = { player.UserId }
		eliminate(player)
		publishRemaining()
		checkConcluded()
	elseif not alive[player] then
		toSpectate(player)
	end
end

-- Guard (finale Echo Clone): the next knockback within GuardSeconds is absorbed.
function FinaleService.grantGuard(player: Player)
	if not FinaleService.isAlive(player) then
		return
	end
	guards[player] = os.clock() + FinaleConfig.GuardSeconds
	player:SetAttribute("FinaleGuard", true)
end

-- Consumes a guard if the player has one. Returns true if the hit was absorbed.
function FinaleService.consumeGuard(player: Player): boolean
	local expiry = guards[player]
	if expiry and os.clock() < expiry then
		guards[player] = nil
		player:SetAttribute("FinaleGuard", nil)
		return true
	end
	return false
end

-- Alive finale players other than `except`.
function FinaleService.getAliveRivals(except: Player): { Player }
	local list = {}
	for player, isAlive in alive do
		if isAlive and player ~= except and player.Parent == Players then
			table.insert(list, player)
		end
	end
	return list
end

-- Teamwork: one point per Convergence Gate opening a player helped with (TASK-0007).
function FinaleService.recordContribution(player: Player)
	contributions[player.UserId] = (contributions[player.UserId] or 0) + 1
	names[player.UserId] = player.DisplayName
end

function FinaleService.getContributions(player: Player): number
	return contributions[player.UserId] or 0
end

-- Computes and publishes the category results. Returns a one-line summary.
function FinaleService.results(finishOrder: { Player }): string
	local order = {}
	for _, player in finishOrder do
		table.insert(order, player.UserId)
		names[player.UserId] = player.DisplayName
	end
	local survivors = {}
	for player, isAlive in alive do
		if isAlive then
			table.insert(survivors, player.UserId)
		end
	end
	local function nameOf(id: number?): string?
		return if id then names[id] or `#{id}` else nil
	end
	local speed = nameOf(ResultRules.speed(order)) or "nobody finished"
	local teamwork = nameOf(ResultRules.teamwork(contributions, order)) or "no gate help"
	local combat = ResultRules.combat(survivors, lastOut, starters)
	local combatText
	if combat.winner then
		combatText = nameOf(combat.winner) :: string
	elseif #combat.draw > 0 then
		local drawNames = {}
		for _, id in combat.draw do
			table.insert(drawNames, nameOf(id) :: string)
		end
		combatText = "draw: " .. table.concat(drawNames, ", ")
	else
		combatText = "nobody survived"
	end
	ReplicatedStorage:SetAttribute("Result_Speed", speed)
	ReplicatedStorage:SetAttribute("Result_Teamwork", teamwork)
	ReplicatedStorage:SetAttribute("Result_Combat", combatText)
	return `Speed: {speed} · Teamwork: {teamwork} · Combat: {combatText}`
end

-- Ends the finale and clears per-match state (match end).
function FinaleService.reset()
	active = false
	concluded = false
	for player in alive do
		if player.Parent == Players then
			player:SetAttribute("FinaleAlive", nil)
			player:SetAttribute("FinaleGuard", nil)
		end
	end
	table.clear(alive)
	table.clear(guards)
	lastOut = {}
	starters = 0
	publishRemaining()
end

-- Clears the Teamwork tally (match start).
function FinaleService.resetContributions()
	table.clear(contributions)
	table.clear(names)
	ReplicatedStorage:SetAttribute("Result_Speed", nil)
	ReplicatedStorage:SetAttribute("Result_Teamwork", nil)
	ReplicatedStorage:SetAttribute("Result_Combat", nil)
end

function FinaleService.start()
	if started then
		return
	end
	started = true
	buildArena()
	Players.PlayerRemoving:Connect(function(player)
		-- A player who leaves is simply out; they never count as a survivor or as a simultaneous loser.
		alive[player] = nil
		guards[player] = nil
		publishRemaining()
		checkConcluded()
	end)
	task.spawn(function()
		while true do
			local ok, err = pcall(function()
				poll()
			end)
			if not ok then
				warn(`[FinaleService] poll error: {err}`)
			end
			task.wait(FinaleConfig.PollSeconds)
		end
	end)
end

return FinaleService
