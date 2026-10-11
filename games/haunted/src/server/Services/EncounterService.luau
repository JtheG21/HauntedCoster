--!strict
-- Spawns monsters inside their zones, rolls variants, roams them (server-side tweened CFrame, no physics),
-- and serves the pre-capture Inspect card.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local Remotes = require(script.Parent.Parent.Remotes)
local MonsterModels = require(script.Parent.Parent.World.MonsterModels)
local PlayerDataService = require(script.Parent.PlayerDataService)
local LandmarkService = require(script.Parent.LandmarkService)

local EncounterService = {}

export type Encounter = {
	id: number,
	model: Model,
	root: BasePart,
	species: string,
	variant: string,
	zone: string,
	claimedBy: Player?,
	alive: boolean,
	tween: Tween?,
}

local SPAWN_INTERVAL = 4
local INSPECT_DISTANCE = 22

local started = false
local folder: Folder
local rng = Random.new()
local nextId = 0
local encounters: { [Model]: Encounter } = {}

local function countIn(zoneId: string): number
	local n = 0
	for _, e in encounters do
		if e.zone == zoneId then
			n += 1
		end
	end
	return n
end

local function pickWeighted(weights: { [string]: number }): string?
	local total = 0
	for _, w in weights do
		total += w
	end
	if total <= 0 then
		return nil
	end
	local roll = rng:NextNumber(0, total)
	for id, w in weights do
		roll -= w
		if roll <= 0 then
			return id
		end
	end
	return next(weights)
end

function EncounterService.rollVariant(zoneId: string, roll: Random): string
	for _, v in Variants.List do
		local allowed = v.zones == nil or table.find(v.zones, zoneId) ~= nil
		if allowed and roll:NextNumber() < v.chance then
			return v.id
		end
	end
	return Variants.Normal
end

local function randomPoint(zone: World.Zone): Vector3
	local r = zone.rect
	return Vector3.new(rng:NextNumber(r.x1 + 4, r.x2 - 4), 0, rng:NextNumber(r.z1 + 4, r.z2 - 4))
end

local function roam(e: Encounter)
	local zone = World.zoneById(e.zone)
	local species = Monsters.Species[e.species]
	if not zone or not species then
		return
	end
	while e.alive do
		if not e.claimedBy then
			local target = randomPoint(zone) + Vector3.new(0, species.hover, 0)
			local from = e.root.Position
			local flat = Vector3.new(target.X, from.Y, target.Z)
			local dist = (flat - from).Magnitude
			if dist > 1 then
				local duration = dist / species.roamSpeed
				local goal = CFrame.lookAt(target, target + (flat - from).Unit)
				local tween =
					TweenService:Create(e.root, TweenInfo.new(duration, Enum.EasingStyle.Linear), { CFrame = goal })
				e.tween = tween
				tween:Play()
				local t0 = os.clock()
				while e.alive and not e.claimedBy and os.clock() - t0 < duration do
					task.wait(0.2)
				end
				if e.claimedBy and e.tween then
					e.tween:Cancel()
				end
				e.tween = nil
			end
			task.wait(rng:NextNumber(1, 3))
		else
			task.wait(0.3)
		end
	end
end

local function inspectPayload(e: Encounter, player: Player): { [string]: any }
	local species = Monsters.Species[e.species]
	local profile = PlayerDataService.get(player)
	local zone = World.zoneById(e.zone)
	local locked: string? = nil
	if species.requiresFlag and not (profile and profile.flags[species.requiresFlag]) then
		locked = "It ignores you. Investigate the Bell Tower first (after your first train ride)."
	elseif zone and zone.gated and not (profile and LandmarkService.cryptOpen(profile)) then
		locked = "Crypt monsters need crypt access."
	end
	local tuning = Monsters.Capture[species.rarity]
	return {
		monster = e.model,
		species = e.species,
		name = species.name,
		family = species.family,
		rarity = species.rarity,
		variant = if e.variant ~= Variants.Normal then e.variant else nil,
		variantLabel = Variants.label(e.variant),
		income = species.incomePerSecond * Variants.multiplier(e.variant),
		blurb = species.blurb,
		hitsNeeded = tuning.hitsNeeded,
		returnSeconds = tuning.returnSeconds,
		locked = locked,
		claimed = e.claimedBy ~= nil and e.claimedBy ~= player,
	}
end

local function onInspect(e: Encounter, player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) or (root.Position - e.root.Position).Magnitude > INSPECT_DISTANCE then
		return
	end
	if not e.alive then
		return
	end
	PlayerDataService.update(player, function(p)
		p.journal.seen[e.species] = true
	end)
	Remotes.event("Inspect"):FireClient(player, inspectPayload(e, player))
end

function EncounterService.spawn(speciesId: string, variantId: string, zoneId: string, at: Vector3?): Encounter?
	local zone = World.zoneById(zoneId)
	local species = Monsters.Species[speciesId]
	if not zone or not species then
		return nil
	end
	nextId += 1
	local model = MonsterModels.build(speciesId, variantId)
	local root = model.PrimaryPart :: BasePart
	local pos = (at or randomPoint(zone)) + Vector3.new(0, species.hover, 0)
	model:PivotTo(CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0))
	model:SetAttribute("EncounterId", nextId)
	model:SetAttribute("Zone", zoneId)
	model:SetAttribute("Rarity", species.rarity)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Inspect"
	prompt.ActionText = "Inspect"
	prompt.ObjectText = (Variants.label(variantId) and (Variants.label(variantId) :: string) .. " " or "")
		.. species.name
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	local e: Encounter = {
		id = nextId,
		model = model,
		root = root,
		species = speciesId,
		variant = variantId,
		zone = zoneId,
		claimedBy = nil,
		alive = true,
		tween = nil,
	}
	encounters[model] = e
	prompt.Triggered:Connect(function(player)
		onInspect(e, player)
	end)
	model.Parent = folder
	task.spawn(roam, e)
	return e
end

local function aliveOf(speciesId: string): number
	local n = 0
	for _, e in encounters do
		if e.species == speciesId then
			n += 1
		end
	end
	return n
end

local function fillZones()
	for _, zone in World.Zones do
		if countIn(zone.id) < zone.maxMonsters then
			local speciesId = pickWeighted(zone.spawns)
			local species = speciesId and Monsters.Species[speciesId]
			if species and species.maxAlive and aliveOf(species.id) >= species.maxAlive then
				speciesId = nil
			end
			if speciesId then
				EncounterService.spawn(speciesId, EncounterService.rollVariant(zone.id, rng), zone.id)
			end
		end
	end
end

function EncounterService.get(model: Instance?): Encounter?
	if typeof(model) ~= "Instance" or not (model :: Instance):IsA("Model") then
		return nil
	end
	return encounters[model :: Model]
end

function EncounterService.claim(e: Encounter, player: Player): boolean
	if not e.alive or (e.claimedBy and e.claimedBy ~= player) then
		return false
	end
	e.claimedBy = player
	if e.tween then
		e.tween:Cancel()
	end
	return true
end

function EncounterService.release(e: Encounter)
	e.claimedBy = nil
end

-- Removes a monster from the world (captured, or scared away).
function EncounterService.remove(e: Encounter)
	e.alive = false
	if e.tween then
		e.tween:Cancel()
	end
	encounters[e.model] = nil
	e.model:Destroy()
end

-- An escaped capture runs back to a zone where its species lives (ADR-0005).
function EncounterService.respawnEscaped(speciesId: string, variantId: string)
	for _, zone in World.Zones do
		if zone.spawns[speciesId] then
			EncounterService.spawn(speciesId, variantId, zone.id)
			return
		end
	end
end

function EncounterService.start()
	if started then
		return
	end
	started = true
	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = Workspace
	-- Initial population: guarantee a Wisp by the gate for the tutorial.
	EncounterService.spawn("Wisp", Variants.Normal, "Gate", Vector3.new(14, 0, -182))
	for _ = 1, 3 do
		fillZones()
	end
	task.spawn(function()
		while true do
			task.wait(SPAWN_INTERVAL)
			fillZones()
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, e in encounters do
			if e.claimedBy == player then
				e.claimedBy = nil
			end
		end
	end)
end

return EncounterService
