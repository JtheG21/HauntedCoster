--!strict
-- Capture meter sessions (server-timed), carrying the capture home under a timer, escape on failure,
-- and securing it at the player's own containment pen.
--
-- The expedition state (session, carried capture) lives only in memory and is never saved; only a
-- secured monster becomes part of the profile. Failing an expedition never touches owned monsters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local Rules = Shared:WaitForChild("Rules")
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local World = require(Config:WaitForChild("World"))
local Economy = require(Config:WaitForChild("Economy"))
local CaptureRules = require(Rules:WaitForChild("CaptureRules"))
local ProfileRules = require(Rules:WaitForChild("ProfileRules"))
local EconomyRules = require(Rules:WaitForChild("EconomyRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)
local MovementService = require(script.Parent.MovementService)
local EncounterService = require(script.Parent.EncounterService)
local LandmarkService = require(script.Parent.LandmarkService)

local CaptureService = {}

local START_DISTANCE = 18
local SECURE_DISTANCE = 14

type Session = {
	encounter: EncounterService.Encounter,
	startedAt: number,
	period: number,
	zoneCenter: number,
	zoneWidth: number,
	hits: number,
	misses: number,
	hitsNeeded: number,
	missesAllowed: number,
	lastRelease: number,
}

type Carry = {
	species: string,
	variant: string,
	deadline: number, -- os.clock()
	deadlineServer: number, -- workspace:GetServerTimeNow()
	returnSeconds: number,
	cage: BasePart?,
	conns: { RBXScriptConnection },
	lastPos: Vector3?, -- server-side speed check (WalkSpeed lives on the client-owned character)
	lastAt: number,
	strikes: number,
}

local started = false
local rng = Random.new()
local sessions: { [Player]: Session } = {}
local carries: { [Player]: Carry } = {}
local securedCallbacks: { (Player, ProfileRules.OwnedMonster) -> () } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function CaptureService.isCarrying(player: Player): boolean
	return carries[player] ~= nil
end

function CaptureService.onSecured(cb: (Player, ProfileRules.OwnedMonster) -> ())
	table.insert(securedCallbacks, cb)
end

local function endSession(player: Player, result: string)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	if result ~= "success" and result ~= "fled" then
		EncounterService.release(s.encounter)
	end
	Remotes.event("CaptureEnded"):FireClient(player, { result = result })
end

local function clearCarry(player: Player)
	local c = carries[player]
	if not c then
		return
	end
	carries[player] = nil
	for _, conn in c.conns do
		conn:Disconnect()
	end
	if c.cage then
		c.cage:Destroy()
	end
	MovementService.setCarrying(player, false)
	StateService.markDirty(player)
end

local checkCarrySpeed: (Player, Carry, number) -> ()

local function escape(player: Player, why: string)
	local c = carries[player]
	if not c then
		return
	end
	clearCarry(player)
	local species = Monsters.Species[c.species]
	PlayerDataService.update(player, function(p)
		p.stats.escapes += 1
	end)
	EncounterService.respawnEscaped(c.species, c.variant)
	if player.Parent then
		StateService.toast(
			player,
			`{why} The {species and species.name or "monster"} escaped back to the graveyard. Your collection is safe.`,
			"error"
		)
	end
end

-- The carry slowdown is a WalkSpeed value on a character the client simulates, so an exploiter could
-- undo it. Measure horizontal speed on the server; repeated speeding drops the capture.
local SPEED_TOLERANCE = 1.35
local SPEED_STRIKES = 3

checkCarrySpeed = function(player: Player, c: Carry, now: number)
	local root = rootOf(player)
	if not root then
		return
	end
	local pos = root.Position
	local last = c.lastPos
	local dt = now - c.lastAt
	c.lastPos = pos
	c.lastAt = now
	if not last or dt <= 0 then
		return
	end
	local profile = PlayerDataService.get(player)
	local allowed = EconomyRules.walkSpeed(if profile then profile.speedLevel else 0, true)
	local flat = Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
	if flat > allowed * dt * SPEED_TOLERANCE + 2 then
		c.strikes += 1
		if c.strikes >= SPEED_STRIKES then
			escape(player, "The jar shattered as you sped off!")
		end
	else
		c.strikes = math.max(0, c.strikes - 1)
	end
end

-- Server-initiated moves (tests, future teleports) must not count as speeding.
function CaptureService.noteTeleport(player: Player)
	local c = carries[player]
	if c then
		c.lastPos = nil
	end
end

-- Studio test helper: make the current carry's timer run out on the next tick (real timeout path).
function CaptureService.expireCarryForTest(player: Player)
	local c = carries[player]
	if c then
		c.deadline = os.clock()
	end
end

-- Number of monsters of a species currently being carried (counts toward spawn caps).
function CaptureService.carriedCount(speciesId: string): number
	local n = 0
	for _, c in carries do
		if c.species == speciesId then
			n += 1
		end
	end
	return n
end

local function makeCage(player: Player, speciesId: string, variantId: string): BasePart?
	local root = rootOf(player)
	if not root then
		return nil
	end
	local species = Monsters.Species[speciesId]
	local variant = Variants.ById[variantId]
	local cage = Instance.new("Part")
	cage.Name = "CaptureJar"
	cage.Shape = Enum.PartType.Ball
	cage.Size = Vector3.new(2.2, 2.2, 2.2)
	cage.Material = Enum.Material.ForceField
	cage.Color = if variant and variant.glow then variant.glow else Monsters.RarityColor[species.rarity]
	cage.CanCollide = false
	cage.CanTouch = false
	cage.CanQuery = false
	cage.Massless = true
	cage.Anchored = false
	cage.CFrame = root.CFrame * CFrame.new(0, 1.5, 1.6)
	local weld = Instance.new("Weld")
	weld.Part0 = root
	weld.Part1 = cage
	weld.C0 = CFrame.new(0, 1.5, 1.6)
	weld.Parent = cage
	local light = Instance.new("PointLight")
	light.Color = cage.Color
	light.Range = 10
	light.Parent = cage
	cage.Parent = player.Character
	return cage
end

local function startCarry(player: Player, speciesId: string, variantId: string)
	local species = Monsters.Species[speciesId]
	local tuning = Monsters.Capture[species.rarity]
	local c: Carry = {
		species = speciesId,
		variant = variantId,
		deadline = os.clock() + tuning.returnSeconds,
		deadlineServer = workspace:GetServerTimeNow() + tuning.returnSeconds,
		returnSeconds = tuning.returnSeconds,
		cage = makeCage(player, speciesId, variantId),
		conns = {},
		lastPos = nil,
		lastAt = os.clock(),
		strikes = 0,
	}
	carries[player] = c
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		table.insert(
			c.conns,
			humanoid.Died:Connect(function()
				escape(player, "You fell!")
			end)
		)
	end
	table.insert(
		c.conns,
		player.CharacterRemoving:Connect(function()
			escape(player, "You vanished!")
		end)
	)
	MovementService.setCarrying(player, true)
	PlayerDataService.update(player, function(p)
		p.flags.captureTried = true
	end)
	StateService.toast(player, `Captured the {species.name}! Get it home within {tuning.returnSeconds}s.`, "success")
end

local function onCaptureStart(player: Player, model: any): { [string]: any }
	if not Remotes.allow(player, "CaptureStart", 2, 4) then
		return { ok = false, reason = "Slow down" }
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return { ok = false, reason = "Still loading" }
	end
	if not PlotService.plotIndex(player) then
		return { ok = false, reason = "You need a home plot first" }
	end
	if carries[player] then
		return { ok = false, reason = "You're already carrying a monster home!" }
	end
	if sessions[player] then
		return { ok = false, reason = "Already capturing" }
	end
	if #profile.owned >= ProfileRules.capacity(profile) then
		return { ok = false, reason = "Your containment pen is full. Upgrade your house for more room." }
	end
	local e = EncounterService.get(model)
	if not e or not e.alive then
		return { ok = false, reason = "It's gone" }
	end
	local root = rootOf(player)
	if not root or (root.Position - e.root.Position).Magnitude > START_DISTANCE then
		return { ok = false, reason = "Get closer" }
	end
	local species = Monsters.Species[e.species]
	if species.requiresFlag and not profile.flags[species.requiresFlag] then
		return { ok = false, reason = "It ignores you. Investigate the Bell Tower first." }
	end
	local zone = World.zoneById(e.zone)
	if zone and zone.gated and not LandmarkService.cryptOpen(profile) then
		return { ok = false, reason = "You don't have crypt access yet" }
	end
	if not EncounterService.claim(e, player) then
		return { ok = false, reason = "Someone else is capturing it" }
	end
	local tuning = Monsters.Capture[species.rarity]
	local s: Session = {
		encounter = e,
		startedAt = os.clock(),
		period = tuning.period,
		zoneCenter = CaptureRules.zoneCenter(rng, tuning.zoneWidth),
		zoneWidth = tuning.zoneWidth,
		hits = 0,
		misses = 0,
		hitsNeeded = tuning.hitsNeeded,
		missesAllowed = tuning.missesAllowed,
		lastRelease = 0,
	}
	sessions[player] = s
	PlayerDataService.update(player, function(p)
		p.flags.captureTried = true
		p.journal.seen[e.species] = true
	end)
	return {
		ok = true,
		name = species.name,
		rarity = species.rarity,
		variantLabel = Variants.label(e.variant),
		period = s.period,
		zoneCenter = s.zoneCenter,
		zoneWidth = s.zoneWidth,
		hitsNeeded = s.hitsNeeded,
		missesAllowed = s.missesAllowed,
	}
end

local function onCaptureRelease(player: Player): { [string]: any }
	local s = sessions[player]
	if not s then
		return { outcome = "none" }
	end
	local now = os.clock()
	if now - s.lastRelease < CaptureRules.MinReleaseGap then
		return { outcome = "ignored", hits = s.hits, misses = s.misses }
	end
	s.lastRelease = now
	local root = rootOf(player)
	if
		not root
		or not s.encounter.alive
		or (root.Position - s.encounter.root.Position).Magnitude > START_DISTANCE + 10
	then
		endSession(player, "cancelled")
		return { outcome = "cancelled" }
	end
	-- Judge from the server's clock, compensating for the round trip.
	-- GetNetworkPing is already a round trip (client display starts half a trip late, the press arrives half
	-- a trip late), so subtract it once.
	local latency = math.clamp(player:GetNetworkPing(), 0, 0.3)
	local elapsed = now - s.startedAt - latency
	local hit = CaptureRules.judge(elapsed, s.period, s.zoneCenter, s.zoneWidth, CaptureRules.LatencySlack)
	local outcome
	outcome, s.hits, s.misses = CaptureRules.applyRelease(hit, s.hits, s.misses, s.hitsNeeded, s.missesAllowed)
	if outcome == "success" then
		local e = s.encounter
		endSession(player, "success")
		EncounterService.remove(e)
		startCarry(player, e.species, e.variant)
	elseif outcome == "fled" then
		local e = s.encounter
		endSession(player, "fled")
		EncounterService.remove(e)
		StateService.toast(player, "It slipped away into the dark! Find another.", "error")
	elseif outcome == "hit" then
		-- Each hit moves the green zone for the next attempt.
		s.zoneCenter = CaptureRules.zoneCenter(rng, s.zoneWidth)
	end
	return { outcome = outcome, hits = s.hits, misses = s.misses, zoneCenter = s.zoneCenter }
end

-- Entry points shared by the remotes and the Studio test scenarios.
CaptureService.requestStart = onCaptureStart
CaptureService.requestRelease = onCaptureRelease

function CaptureService.secure(player: Player, plotIndex: number)
	local c = carries[player]
	if not c then
		StateService.toast(player, "Capture a monster in the graveyard and bring it here to secure it.", "info")
		return
	end
	if PlotService.ownerOf(plotIndex) ~= player then
		StateService.toast(player, "That's not your pen!", "error")
		return
	end
	local root = rootOf(player)
	local padPos = World.PlotCenters[plotIndex] + World.Plot.pen
	if not root or (root.Position - padPos).Magnitude > SECURE_DISTANCE + 8 then
		return
	end
	local profile = PlayerDataService.get(player)
	if not profile then
		return
	end
	if #profile.owned >= ProfileRules.capacity(profile) then
		StateService.toast(player, "Your pen is full! Upgrade your house.", "error")
		return
	end
	local speciesId, variantId = c.species, c.variant
	clearCarry(player)
	local owned: ProfileRules.OwnedMonster? = nil
	local firstTime = false
	PlayerDataService.update(player, function(p)
		local m = {
			uid = `m{p.nextUid}`,
			species = speciesId,
			variant = variantId,
			acquiredAt = os.time(),
		}
		p.nextUid += 1
		table.insert(p.owned, m)
		p.journal.caught[speciesId] = true
		p.journal.seen[speciesId] = true
		if variantId ~= Variants.Normal then
			p.journal.variants[speciesId .. ":" .. variantId] = true
		end
		p.stats.captures += 1
		if not p.flags.onboarded then
			p.flags.onboarded = true
			firstTime = true
			EconomyRules.addCoins(p, Economy.OnboardingReward)
		end
		owned = m
	end)
	local species = Monsters.Species[speciesId]
	local label = Variants.label(variantId)
	StateService.toast(
		player,
		`Secured {label and label .. " " or ""}{species.name}! It earns coins after {Economy.AcclimationSeconds}s of settling in.`,
		"success"
	)
	if firstTime then
		StateService.toast(player, `First catch bonus: +{Economy.OnboardingReward} coins!`, "success")
	end
	PlotService.rebuildTrophies(player)
	if owned then
		for _, cb in securedCallbacks do
			task.spawn(cb, player, owned)
		end
	end
end

function CaptureService.start()
	if started then
		return
	end
	started = true
	Remotes.func("CaptureStart").OnServerInvoke = onCaptureStart
	Remotes.func("CaptureRelease").OnServerInvoke = function(player)
		if not Remotes.allow(player, "CaptureRelease", 8, 8) then
			return { outcome = "ignored" }
		end
		return onCaptureRelease(player)
	end
	Remotes.event("CaptureCancel").OnServerEvent:Connect(function(player)
		endSession(player, "cancelled")
	end)

	for i = 1, #World.PlotCenters do
		local plot = PlotService.plotModel(i)
		local pen = plot and plot:FindFirstChild("Pen")
		local pad = pen and pen:FindFirstChild("PenPad")
		if pad and pad:IsA("BasePart") then
			local prompt = Instance.new("ProximityPrompt")
			prompt.Name = "Secure"
			prompt.ActionText = "Secure Monster"
			prompt.ObjectText = "Containment Pen"
			prompt.HoldDuration = 0.3
			prompt.MaxActivationDistance = SECURE_DISTANCE
			prompt.RequiresLineOfSight = false
			prompt.Parent = pad
			prompt.Triggered:Connect(function(player)
				CaptureService.secure(player, i)
			end)
		end
	end

	StateService.addProvider(function(player, snap)
		local c = carries[player]
		if c then
			local species = Monsters.Species[c.species]
			snap.carrying = {
				species = c.species,
				name = species.name,
				variantLabel = Variants.label(c.variant),
				deadline = c.deadlineServer,
				returnSeconds = c.returnSeconds,
			}
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for player, c in carries do
				if now >= c.deadline then
					escape(player, "Time's up!")
				else
					checkCarrySpeed(player, c, now)
				end
			end
			for player, s in sessions do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if now - s.startedAt > CaptureRules.SessionTimeout then
					endSession(player, "timeout")
				elseif not humanoid or humanoid.Health <= 0 then
					-- Dying (or despawning) mid-capture frees the monster straight away.
					endSession(player, "cancelled")
				end
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		local s = sessions[player]
		if s then
			sessions[player] = nil
			EncounterService.release(s.encounter)
		end
		local c = carries[player]
		if c then
			clearCarry(player)
			EncounterService.respawnEscaped(c.species, c.variant)
		end
	end)
end

return CaptureService
