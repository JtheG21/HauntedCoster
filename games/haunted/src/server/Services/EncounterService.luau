--!strict
-- Spawns monsters inside their zones, rolls variants, roams them (server-side tweened CFrame, no physics),
-- and serves the pre-capture Inspect card. Also moves startled monsters (a missed capture press) and
-- escaped captures fleeing from the player who dropped them (Round 20; GDD v0.3).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Habitats = require(Config:WaitForChild("Habitats"))
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local ChaseRules = require(Shared:WaitForChild("Rules"):WaitForChild("ChaseRules"))
local EconomyRules = require(Shared.Rules:WaitForChild("EconomyRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local MonsterModels = require(script.Parent.Parent.World.MonsterModels)
local PlayerDataService = require(script.Parent.PlayerDataService)

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
	startledUntil: number, -- os.clock(); no capture until it lands from a startle hop
	progress: { [Player]: { hits: number, misses: number } }, -- capture counters kept between attempts
	fleeing: Player?, -- set while it runs from the player whose capture escaped
	claimEpoch: number, -- bumped by every claim, so a late startle release can't drop a newer claim
	pursuing: Player?, -- set while it chases the player who failed to capture it (TASK-0031)
}

local SPAWN_INTERVAL = 4
local INSPECT_DISTANCE = 22
local STARTLE_HOP_SECONDS = 0.5
local STARTLE_SETTLE_SECONDS = 0.8
local FLEE_STEP_SECONDS = 0.6

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
	return Variants.roll(zoneId, roll)
end

-- Extra count of a species outside the world (e.g. being carried home), wired from CaptureService.
local outsideCount: (string) -> number = function(_speciesId: string)
	return 0
end

function EncounterService.setOutsideCounter(fn: (string) -> number)
	outsideCount = fn
end

local function randomPoint(zone: World.Zone): Vector3
	local r = zone.rect
	return Vector3.new(rng:NextNumber(r.x1 + 4, r.x2 - 4), 0, rng:NextNumber(r.z1 + 4, r.z2 - 4))
end

local function roam(e: Encounter)
	local zone = Habitats.zoneById(e.zone)
	local species = Monsters.Species[e.species]
	if not zone or not species then
		return
	end
	while e.alive do
		if not e.claimedBy and not e.pursuing then
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
				while e.alive and not e.claimedBy and not e.pursuing and os.clock() - t0 < duration do
					task.wait(0.2)
				end
				-- Only stop this roam tween: a startle hop or flee step may already own e.tween.
				if e.tween == tween then
					if e.claimedBy or e.pursuing then
						tween:Cancel()
					end
					e.tween = nil
				end
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
	local zone = Habitats.zoneById(e.zone)
	local locked: string? = nil
	if zone and zone.gated and not (profile and EconomyRules.cryptOpen(profile.houseTier)) then
		locked = "Restore your house to capture monsters in the Sealed Crypt."
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
	local zone = Habitats.zoneById(zoneId)
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
	-- Its own key (R), so Inspect never competes with the E prompts players use near monsters (Grab, Secure,
	-- ride prompts); with both on E only one prompt shows (hands-on playtest, TEST-20261011-03).
	prompt.KeyboardKeyCode = Enum.KeyCode.R
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonY
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
		startledUntil = 0,
		progress = {},
		fleeing = nil,
		claimEpoch = 0,
		pursuing = nil,
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
	for _, zone in Habitats.active().zones do
		local speciesId = pickWeighted(zone.spawns)
		local species = speciesId and Monsters.Species[speciesId]
		if species and species.maxAlive and aliveOf(species.id) + outsideCount(species.id) >= species.maxAlive then
			speciesId = nil
		end
		-- A capped rare (the Bell Wraith) ignores the zone cap: ordinary monsters fill the zone first and
		-- never despawn, so it would otherwise never get a slot (hands-on playtest, TEST-20261011-03).
		-- Its own maxAlive check above still applies.
		if not (species and species.maxAlive) and countIn(zone.id) >= zone.maxMonsters then
			speciesId = nil
		end
		if speciesId then
			EncounterService.spawn(speciesId, EncounterService.rollVariant(zone.id, rng), zone.id)
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
	e.claimEpoch += 1
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

local function tweenTo(e: Encounter, target: Vector3, seconds: number, style: Enum.EasingStyle)
	if e.tween then
		e.tween:Cancel()
	end
	local from = e.root.Position
	local flat = Vector3.new(target.X - from.X, 0, target.Z - from.Z)
	local goal = if flat.Magnitude > 0.1
		then CFrame.lookAt(target, target + flat.Unit)
		else CFrame.new(target) * e.root.CFrame.Rotation
	local tween =
		TweenService:Create(e.root, TweenInfo.new(seconds, style, Enum.EasingDirection.Out), { CFrame = goal })
	e.tween = tween
	tween:Play()
end

-- A missed capture press startles the monster: it hops away inside its zone and can't be captured again
-- until it settles. The capturing player keeps the claim during the hop, then the monster roams again.
function EncounterService.startle(e: Encounter, from: Vector3)
	local zone = Habitats.zoneById(e.zone)
	if not e.alive or not zone then
		return
	end
	local claimer, epoch = e.claimedBy, e.claimEpoch
	e.startledUntil = os.clock() + STARTLE_SETTLE_SECONDS
	tweenTo(
		e,
		ChaseRules.startleTarget(zone.rect, e.root.Position, from, rng),
		STARTLE_HOP_SECONDS,
		Enum.EasingStyle.Quad
	)
	task.delay(STARTLE_SETTLE_SECONDS, function()
		if e.alive and e.claimedBy == claimer and e.claimEpoch == epoch then
			e.claimedBy = nil
		end
	end)
end

function EncounterService.isStartled(e: Encounter): boolean
	return os.clock() < e.startledUntil
end

-- An escaped capture reappears beside the player who dropped it and runs. Only that player can grab it;
-- `untilClock` ends the chase (CaptureService then sends it home with respawnEscaped).
function EncounterService.spawnFleeing(
	speciesId: string,
	variantId: string,
	owner: Player,
	near: Vector3,
	headStart: number,
	speed: number,
	untilClock: number
): Encounter?
	local species = Monsters.Species[speciesId]
	if not species then
		return nil
	end
	local habitat: string? = nil
	for _, zone in Habitats.active().zones do
		if zone.spawns[speciesId] then
			habitat = zone.id
			break
		end
	end
	if not habitat then
		return nil
	end
	local region, avoid = ChaseRules.fleeRegion(near)
	local start = ChaseRules.fleeStep(region, near, nil, headStart, rng, avoid)
	local e = EncounterService.spawn(speciesId, variantId, habitat, Vector3.new(start.X, 0, start.Z))
	if not e then
		return nil
	end
	e.claimedBy = owner
	e.fleeing = owner
	local inspect = e.root:FindFirstChild("Inspect")
	if inspect and inspect:IsA("ProximityPrompt") then
		inspect.Enabled = false
	end
	task.spawn(function()
		while e.alive and e.fleeing == owner and os.clock() < untilClock do
			local character = owner.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local chaser = if root and root:IsA("BasePart") then root.Position else nil
			-- The region is re-read every step: a habitat swap moves the chase out to the ring road
			-- (relocateFleeing), and the regions are disjoint, so it never crosses a wall.
			region, avoid = ChaseRules.fleeRegion(e.root.Position)
			local target = ChaseRules.fleeStep(region, e.root.Position, chaser, speed * FLEE_STEP_SECONDS, rng, avoid)
			tweenTo(e, target, FLEE_STEP_SECONDS, Enum.EasingStyle.Linear)
			task.wait(FLEE_STEP_SECONDS)
		end
	end)
	return e
end

-- A habitat swap (ADR-0007 "evacuate to the gates"): a fleeing escaped capture follows its player out of
-- the hub, landing a head start away from `near` on the open ring, and the chase continues there.
function EncounterService.relocateFleeing(e: Encounter, near: Vector3, headStart: number)
	if not e.alive then
		return
	end
	if e.tween then
		e.tween:Cancel()
	end
	local region = ChaseRules.fleeRegion(near)
	local at = ChaseRules.fleeStep(region, near, nil, headStart, rng)
	local hover = e.root.Position.Y
	e.root.CFrame = CFrame.new(at.X, hover, at.Z) * e.root.CFrame.Rotation
end

-- Retaliation (TASK-0031) ------------------------------------------------------------------------------

function EncounterService.byId(id: number): Encounter?
	for _, e in encounters do
		if e.id == id then
			return e
		end
	end
	return nil
end

-- Monsters that could join a pursuit: wild, unclaimed, not fleeing, startled or already pursuing.
function EncounterService.candidatesForPursuit(): { { id: number, at: Vector3, available: boolean } }
	local out = {}
	for _, e in encounters do
		table.insert(out, {
			id = e.id,
			at = e.root.Position,
			available = e.alive
				and not e.claimedBy
				and not e.fleeing
				and not e.pursuing
				and not EncounterService.isStartled(e),
		})
	end
	return out
end

-- Starts (`player`) or ends (nil) a pursuit for `e`. Starting needs a free, wild monster; ending lets it
-- roam again from where it stands.
function EncounterService.setPursuing(e: Encounter, player: Player?): boolean
	if player then
		if not e.alive or e.claimedBy or e.fleeing or e.pursuing then
			return false
		end
		if e.tween then
			e.tween:Cancel()
		end
		e.pursuing = player
		local inspect = e.root:FindFirstChild("Inspect")
		if inspect and inspect:IsA("ProximityPrompt") then
			inspect.Enabled = false
		end
		return true
	end
	e.pursuing = nil
	-- Re-enables Inspect unconditionally: a pursuer is always a free, wild monster (checked above when the
	-- pursuit started, and capture start refuses a pursuer), so nothing else had it disabled meanwhile. If
	-- another state ever disables Inspect while a monster pursues, restore it from that state instead.
	local inspect = e.root:FindFirstChild("Inspect")
	if inspect and inspect:IsA("ProximityPrompt") then
		inspect.Enabled = true
	end
	return true
end

function EncounterService.pursuingOf(e: Encounter): Player?
	return e.pursuing
end

-- One pursuit step (the server decides the target; RetaliationRules keeps it inside its region).
function EncounterService.stepTo(e: Encounter, target: Vector3, seconds: number)
	if e.alive then
		tweenTo(e, target, seconds, Enum.EasingStyle.Linear)
	end
end

-- An escaped capture runs back to a zone where its species lives (ADR-0005).
function EncounterService.respawnEscaped(speciesId: string, variantId: string)
	local species = Monsters.Species[speciesId]
	if species and species.maxAlive and aliveOf(speciesId) + outsideCount(speciesId) >= species.maxAlive then
		return
	end
	for _, zone in Habitats.active().zones do
		-- A capped rare skips the zone cap, as in fillZones.
		if zone.spawns[speciesId] and ((species and species.maxAlive) or countIn(zone.id) < zone.maxMonsters) then
			EncounterService.spawn(speciesId, variantId, zone.id)
			return
		end
	end
	-- Every zone is full: the spawner will repopulate later.
end

-- Removes every wild monster (for a habitat swap, TASK-0027). A fleeing escaped capture belongs to its
-- player, not to the habitat, and is kept. Returns how many were removed.
function EncounterService.clearWild(): number
	local n = 0
	for _, e in encounters do
		if not e.fleeing then
			EncounterService.remove(e)
			n += 1
		end
	end
	return n
end

-- Initial population of the active habitat: its guaranteed monster for the tutorial (a Wisp by the
-- central landmark), then a few spawner passes. Called at start and after each habitat swap.
function EncounterService.populate()
	if not started then
		return
	end
	local starter = Habitats.active().starter
	if starter then
		EncounterService.spawn(starter.species, Variants.Normal, starter.zone, starter.at)
	end
	for _ = 1, 3 do
		fillZones()
	end
end

-- Every live encounter's species and zone (scenarios check a swap left nothing behind).
function EncounterService.snapshot(): { { species: string, zone: string, fleeing: boolean, claimed: boolean } }
	local out = {}
	for _, e in encounters do
		table.insert(
			out,
			{ species = e.species, zone = e.zone, fleeing = e.fleeing ~= nil, claimed = e.claimedBy ~= nil }
		)
	end
	return out
end

function EncounterService.start()
	if started then
		return
	end
	started = true
	folder = Instance.new("Folder")
	folder.Name = "Monsters"
	folder.Parent = Workspace
	EncounterService.populate()
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
			e.progress[player] = nil
		end
	end)
end

return EncounterService
