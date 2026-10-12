--!strict
-- Capture meter sessions (server-timed), carrying the capture home under a timer, escape on failure,
-- and securing it at the player's own containment pen.
--
-- Round 20 (GDD v0.3): a missed press startles the monster, which hops away; walk up and try again, with
-- hits and misses kept. When the return timer runs out the capture breaks free and runs: catch it within
-- Monsters.Chase.seconds to carry on, or it goes back to its habitat.
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
local HabitatRules = require(Rules:WaitForChild("HabitatRules"))
local Remotes = require(script.Parent.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local StateService = require(script.Parent.StateService)
local PlotService = require(script.Parent.PlotService)
local MovementService = require(script.Parent.MovementService)
local EncounterService = require(script.Parent.EncounterService)

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
	startedAt: number, -- os.clock(); the speed budget grows with the time since
	travelled: number, -- horizontal studs covered on foot (server moves and train rides excluded)
	chased: boolean, -- already broke free once; the next timeout sends it straight home
}

type Chase = {
	encounter: EncounterService.Encounter,
	species: string,
	variant: string,
	deadline: number, -- os.clock()
	deadlineServer: number,
}

local started = false
local rng = Random.new()
local sessions: { [Player]: Session } = {}
local carries: { [Player]: Carry } = {}
local chases: { [Player]: Chase } = {}
local securedCallbacks: { (Player, ProfileRules.OwnedMonster) -> () } = {}
local closing = false -- the last seconds before a habitat swap: no new captures (TASK-0029)
local fledCallbacks: { (Player, EncounterService.Encounter) -> boolean } = {}

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

function CaptureService.isCarrying(player: Player): boolean
	return carries[player] ~= nil
end

function CaptureService.isChasing(player: Player): boolean
	return chases[player] ~= nil
end

-- The fleeing monster's model while `player` chases it (tests and the HUD arrow).
function CaptureService.chaseTarget(player: Player): Model?
	local ch = chases[player]
	return if ch then ch.encounter.model else nil
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
		-- Walking away, timing out or being startled keeps this player's counters for the next attempt.
		s.encounter.progress[player] = { hits = s.hits, misses = s.misses }
		if result ~= "startled" then
			EncounterService.release(s.encounter)
		end
	end
	Remotes.event("CaptureEnded"):FireClient(player, { result = result, missesLeft = s.missesAllowed - s.misses })
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

local checkCarrySpeed: (Player, Carry, number) -> boolean

-- The capture is gone for good this time: back to its habitat, to be found again later (Round 20 Q1).
local function lose(player: Player, speciesId: string, variantId: string, why: string)
	local species = Monsters.Species[speciesId]
	PlayerDataService.update(player, function(p)
		p.stats.escapes += 1
	end)
	EncounterService.respawnEscaped(speciesId, variantId)
	if player.Parent then
		StateService.toast(
			player,
			`{why} The {species and species.name or "monster"} escaped back to its habitat. Find it again later; your collection is safe.`,
			"error"
		)
	end
end

local function endChase(player: Player, why: string?)
	local ch = chases[player]
	if not ch then
		return
	end
	chases[player] = nil
	ch.encounter.fleeing = nil
	if ch.encounter.alive then
		EncounterService.remove(ch.encounter)
	end
	StateService.markDirty(player)
	if why then
		lose(player, ch.species, ch.variant, why)
	end
end

local function startChase(player: Player, c: Carry, root: BasePart): boolean
	local tuning = Monsters.Chase
	local deadline = os.clock() + tuning.seconds
	local e = EncounterService.spawnFleeing(
		c.species,
		c.variant,
		player,
		root.Position,
		tuning.headStart,
		tuning.fleeSpeed,
		deadline
	)
	if not e then
		return false
	end
	chases[player] = {
		encounter = e,
		species = c.species,
		variant = c.variant,
		deadline = deadline,
		deadlineServer = workspace:GetServerTimeNow() + tuning.seconds,
	}
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Grab"
	prompt.ActionText = "Grab!"
	prompt.ObjectText = "Escaped monster"
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.MaxActivationDistance = tuning.grabDistance
	prompt.RequiresLineOfSight = false
	prompt.Parent = e.root
	prompt.Triggered:Connect(function(who)
		if not Remotes.allow(who, "Grab", 4, 4) then
			return
		end
		if who ~= player then
			-- The prompt is visible to everyone; only the player it escaped from can grab it.
			StateService.toast(who, "That's someone else's escaped monster.", "info")
			return
		end
		CaptureService.grab(who)
	end)
	StateService.markDirty(player)
	return true
end

-- `canChase`: the timer ran out on a living player, so the capture breaks free and runs instead of
-- vanishing. Deaths, leaving and the anti-speed check send it straight home.
local function escape(player: Player, why: string, canChase: boolean?)
	local c = carries[player]
	if not c then
		return
	end
	clearCarry(player)
	local root = rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if canChase and not c.chased and root and humanoid and humanoid.Health > 0 and player.Parent then
		if startChase(player, c, root) then
			local species = Monsters.Species[c.species]
			StateService.toast(
				player,
				`{why} The {species.name} broke free! Catch it within {Monsters.Chase.seconds}s (get close, press E).`,
				"error"
			)
			return
		end
	end
	lose(player, c.species, c.variant, why)
end

-- True while the character rides a ghost train cart: the server moves the anchored cart, so that
-- movement isn't the carrier's own and doesn't count toward the speed budget.
local function onTrainSeat(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local cart = seat and seat.Parent
	return cart ~= nil and cart.Name == "GhostCart" and cart:IsA("Model")
end

-- The carry slowdown is a WalkSpeed value on a character the client simulates, so an exploiter could
-- undo it. The server adds up the horizontal path the carrier covers and drops the capture once it exceeds
-- what the slowed walk allows since the carry began (CaptureRules.carryTooFast). Returns false if the
-- capture was dropped.
checkCarrySpeed = function(player: Player, c: Carry, now: number): boolean
	local root = rootOf(player)
	if not root then
		return true
	end
	local pos = root.Position
	local last = c.lastPos
	c.lastPos = pos
	if not last or onTrainSeat(player) then
		return true
	end
	c.travelled += Vector3.new(pos.X - last.X, 0, pos.Z - last.Z).Magnitude
	local profile = PlayerDataService.get(player)
	local allowed = EconomyRules.walkSpeed(if profile then profile.speedLevel else 0, true)
	if CaptureRules.carryTooFast(c.travelled, now - c.startedAt, allowed) then
		escape(player, "The jar shattered as you sped off!")
		return false
	end
	return true
end

-- Server-initiated moves (tests, habitat evacuation, the train cart re-park) must not count as speeding:
-- the next sample starts a new segment instead of measuring across the move. Call it before moving.
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

-- Studio test helper: end the current chase on the next tick (real expiry path).
function CaptureService.expireChaseForTest(player: Player)
	local ch = chases[player]
	if ch then
		ch.deadline = os.clock()
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

local function startCarry(player: Player, speciesId: string, variantId: string, regrab: boolean?)
	local species = Monsters.Species[speciesId]
	local tuning = Monsters.Capture[species.rarity]
	local seconds = if regrab then Monsters.Chase.regrabSeconds else tuning.returnSeconds
	local c: Carry = {
		species = speciesId,
		variant = variantId,
		deadline = os.clock() + seconds,
		deadlineServer = workspace:GetServerTimeNow() + seconds,
		returnSeconds = seconds,
		cage = makeCage(player, speciesId, variantId),
		conns = {},
		lastPos = nil,
		startedAt = os.clock(),
		travelled = 0,
		chased = regrab == true,
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
	if regrab then
		StateService.toast(
			player,
			`Got it back! {seconds}s to get the {species.name} home. It won't break free twice.`,
			"success"
		)
	else
		StateService.toast(player, `Captured the {species.name}! Get it home within {seconds}s.`, "success")
	end
end

-- Studio test helper: start a carry without the timed minigame (CrossPlot tests ownership, not capture;
-- FullLoop covers the real capture path). The carry itself is the real one: same timer, cage and escapes.
function CaptureService.carryForTest(player: Player, speciesId: string, variantId: string)
	if not carries[player] and Monsters.Species[speciesId] then
		startCarry(player, speciesId, variantId)
	end
end

-- Grabbing a fleeing escaped capture (the Grab prompt, or the Studio scenarios). Server-checked: only the
-- player it escaped from, while the chase runs, from within grab distance.
function CaptureService.grab(player: Player): boolean
	local ch = chases[player]
	if not ch or not ch.encounter.alive or os.clock() >= ch.deadline then
		return false
	end
	if carries[player] then
		return false
	end
	local root = rootOf(player)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return false
	end
	local m = ch.encounter.root.Position
	-- Flat distance: monsters hover. +2 studs for the prompt's own reach and replication lag.
	if Vector3.new(m.X - root.Position.X, 0, m.Z - root.Position.Z).Magnitude > Monsters.Chase.grabDistance + 2 then
		return false
	end
	endChase(player, nil)
	startCarry(player, ch.species, ch.variant, true)
	return true
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
	if chases[player] then
		return { ok = false, reason = "Catch your escaped monster first!" }
	end
	if sessions[player] then
		return { ok = false, reason = "Already capturing" }
	end
	if closing then
		return { ok = false, reason = "The fog is rolling in. The hunting ground is about to change!" }
	end
	if #profile.owned >= ProfileRules.capacity(profile) then
		return { ok = false, reason = "Your containment pen is full. Upgrade your house for more room." }
	end
	local e = EncounterService.get(model)
	if not e or not e.alive then
		return { ok = false, reason = "It's gone" }
	end
	if e.fleeing then
		return { ok = false, reason = "It's running from someone else" }
	end
	if e.pursuing then
		return { ok = false, reason = "It's charging! Get clear first." }
	end
	if EncounterService.isStartled(e) then
		return { ok = false, reason = "It's skittish. Give it a moment." }
	end
	local root = rootOf(player)
	if not root or (root.Position - e.root.Position).Magnitude > START_DISTANCE then
		return { ok = false, reason = "Get closer" }
	end
	local species = Monsters.Species[e.species]
	if HabitatRules.needsCrypt(e.zone, e.species, e.variant) and not EconomyRules.cryptOpen(profile.houseTier) then
		return { ok = false, reason = "Restore your house to capture monsters in the Sealed Crypt." }
	end
	if not EncounterService.claim(e, player) then
		return { ok = false, reason = "Someone else is capturing it" }
	end
	local tuning = Monsters.Capture[species.rarity]
	local kept = e.progress[player]
	local s: Session = {
		encounter = e,
		startedAt = os.clock(),
		period = tuning.period,
		zoneCenter = CaptureRules.zoneCenter(rng, tuning.zoneWidth),
		zoneWidth = tuning.zoneWidth,
		hits = if kept then kept.hits else 0,
		misses = if kept then kept.misses else 0,
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
		hits = s.hits,
		misses = s.misses,
	}
end

-- The last miss: the monster gets away. With retaliation wired (TASK-0031) it turns on the player instead
-- of vanishing; otherwise (no handler took it) it slips away as before.
local function onFled(player: Player, s: Session)
	local e = s.encounter
	endSession(player, "fled")
	-- The monster got away from this player: a later attempt on it starts fresh (jg, TASK-0032), not one
	-- miss from fleeing again with counters kept from earlier walk-aways or startles.
	e.progress[player] = nil
	EncounterService.release(e)
	for _, fn in fledCallbacks do
		-- A handler that errors doesn't take the monster: it still slips away below.
		local ok, took = pcall(fn, player, e)
		if not ok then
			warn(`[CaptureService] onFled handler failed: {took}`)
		elseif took then
			return
		end
	end
	EncounterService.remove(e)
	StateService.toast(player, "It slipped away into the dark! Find another.", "error")
end

-- `fn(player, encounter)` returns true when it took the fled monster (RetaliationService).
function CaptureService.onFled(fn: (Player, EncounterService.Encounter) -> boolean)
	table.insert(fledCallbacks, fn)
end

-- Test-only (scenarios): the open session's last miss happens now.
function CaptureService.failForTest(player: Player): boolean
	local s = sessions[player]
	if not s then
		return false
	end
	s.misses = s.missesAllowed
	onFled(player, s)
	return true
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
		onFled(player, s)
	elseif outcome == "miss" then
		-- A miss startles it (Round 20 Q2): the meter closes and it hops away; walk up and try again.
		local e = s.encounter
		endSession(player, "startled")
		EncounterService.startle(e, root.Position)
	elseif outcome == "hit" then
		-- Each hit moves the green zone for the next attempt.
		s.zoneCenter = CaptureRules.zoneCenter(rng, s.zoneWidth)
	end
	return { outcome = outcome, hits = s.hits, misses = s.misses, zoneCenter = s.zoneCenter }
end

-- Entry points shared by the remotes and the Studio test scenarios.
CaptureService.requestStart = onCaptureStart
CaptureService.requestRelease = onCaptureRelease
-- Habitat rotation (TASK-0029, ADR-0007 "evacuate to the gates").
function CaptureService.setClosing(on: boolean)
	closing = on
end

function CaptureService.isClosing(): boolean
	return closing
end

-- At the swap: every open meter session ends. Nothing was caught yet, so nothing is lost; the monster is
-- released (the habitat clears it right after) and the meter closes on the client.
function CaptureService.cancelAllSessions(): number
	local n = 0
	for player in sessions do
		endSession(player, "cancelled")
		StateService.toast(player, "The fog swallowed your monster. The hunting ground is changing!", "info")
		n += 1
	end
	return n
end

-- After players were moved out of the hub: a fleeing escaped capture follows its player out and the chase
-- carries on (the deadline is unchanged). Carried captures need nothing: they aren't tied to a habitat.
function CaptureService.followSwap()
	for player, ch in chases do
		local at = ch.encounter.root.Position
		-- Only chases inside the hub move; one already out on the ring road carries on where it is.
		if ch.encounter.alive and World.inHub(at.X, at.Z) then
			local root = rootOf(player)
			local near = if root then root.Position else World.gatePoint(1, World.Hub.wallRadius + 7)
			EncounterService.relocateFleeing(ch.encounter, near, Monsters.Chase.headStart)
			StateService.toast(
				player,
				`Your escaped {Monsters.Species[ch.species].name} followed you out of the fog. Catch it!`,
				"info"
			)
		end
	end
end

-- Test-only views (scenarios): the open session's encounter, the carry and chase details.
function CaptureService.sessionForTest(player: Player): any
	local s = sessions[player]
	return if s then { encounter = s.encounter } else nil
end

function CaptureService.carryForTestInfo(player: Player): any
	local c = carries[player]
	return if c then { species = c.species, variant = c.variant, deadlineServer = c.deadlineServer } else nil
end

function CaptureService.startForTest(player: Player, model: Model): { [string]: any }
	return onCaptureStart(player, model)
end

function CaptureService.requestCancel(player: Player)
	endSession(player, "cancelled")
end

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
	local padPos = World.plotToWorld(plotIndex, World.Plot.pen)
	if not root or (root.Position - padPos).Magnitude > SECURE_DISTANCE + 8 then
		return
	end
	-- The timer is enforced here too, not only by the 0.25 s tick: a secure after the deadline is the
	-- timeout it is (the capture breaks free).
	local now = os.clock()
	if now >= c.deadline then
		escape(player, "Time's up!", true)
		return
	end
	-- Count the last stretch now, so a teleport to the pen between two ticks can't secure.
	if not checkCarrySpeed(player, c, now) then
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
	Remotes.event("CaptureCancel").OnServerEvent:Connect(CaptureService.requestCancel)

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
		local ch = chases[player]
		if ch then
			snap.chase = {
				name = Monsters.Species[ch.species].name,
				deadline = ch.deadlineServer,
				seconds = Monsters.Chase.seconds,
				monster = ch.encounter.model,
			}
		end
	end)

	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			for player, c in carries do
				if now >= c.deadline then
					escape(player, "Time's up!", true)
				else
					checkCarrySpeed(player, c, now)
				end
			end
			for player, ch in chases do
				local character = player.Character
				local humanoid = character and character:FindFirstChildOfClass("Humanoid")
				if now >= ch.deadline or not ch.encounter.alive then
					endChase(player, "It got away!")
				elseif not humanoid or humanoid.Health <= 0 then
					endChase(player, "You fell!")
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
		local ch = chases[player]
		if ch then
			chases[player] = nil
			if ch.encounter.alive then
				EncounterService.remove(ch.encounter)
			end
			EncounterService.respawnEscaped(ch.species, ch.variant)
		end
	end)
end

return CaptureService
