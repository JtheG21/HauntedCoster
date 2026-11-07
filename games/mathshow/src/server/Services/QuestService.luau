--!strict
-- QuestService (TASK-0150): daily quests and XP on the server. It turns accepted gameplay facts into ORDERED CONDITIONAL
-- COMMANDS (ProfileRules play / progress / claim / rollover) and queues them on the player's profile session; the profile
-- save worker freezes them into its next operation and ProfileRules.planSave applies them against the STORED state. This
-- module never awards anything itself: xp, the daily play cap, claims, the all-three bonus and rollover are decided in the
-- persistence transform (SYS-Quests-And-XP, "Persistence operation").
--
-- Hooks (Round / Blitz / SkillTest / Glyph) call the QuestService.* functions below. Each is non-yielding, bounded, and
-- pcall-isolated with a warn, so a quest fault never changes gameplay. Each logical event carries a server-generated id; a
-- repeated id queues once (ProfileRules.queueCommand). Facts that arrive before the profile has loaded wait in a bounded
-- typed buffer (PRELOAD_CAP); beyond it, or for a read-only profile, they are dropped with a warning (disclosed loss).
-- Blitz secrecy: correctness-dependent Blitz facts are not produced at all until BlitzService's existing result boundary
-- (blitzFinished), so nothing about them can reach QuestRequest, QuestState, pending counts or Player attributes earlier.
--
-- Remotes (server-created): QuestRequest() and QuestClaim{day, slot, boardRevision, generation}; the only reply is QuestState
-- to the invoking player. Validation order: type -> range -> ownership (the invoking Player) -> rate -> one pending claim,
-- pending marked before anything yields. Player attributes Level, Title and PlateColor derive from CONFIRMED xp only.

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local LevelRewards = require(Shared:WaitForChild("LevelRewards"))
local Net = require(Shared:WaitForChild("Net"))
local ProfileRules = require(Shared:WaitForChild("ProfileRules"))
local QuestConfig = require(Shared:WaitForChild("QuestConfig"))
local QuestRules = require(Shared:WaitForChild("QuestRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))
local XpConfig = require(Shared:WaitForChild("XpConfig"))
local XpRules = require(Shared:WaitForChild("XpRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local PRELOAD_CAP = 64
local REQUESTS_PER_10S = 4
local MUTATIONS_PER_1S = 2
local MUTATIONS_PER_30S = 10

-- A gameplay fact before it is turned into commands: a play award or a quest progress fact, with its original day.
type Intent = {
	day: number,
	play: { source: string, nominal: number }?,
	fact: { kind: string, amount: number }?,
	eventId: string,
}
type PlayerState = {
	revision: number,
	buffer: { Intent },
	bufferWarned: boolean,
	queuedEpoch: number, -- the highest day a rollover was queued for (-1 none)
	pendingClaim: { slot: number, eventId: string }?,
	requestStamps: { number },
	mutationStamps1: { number },
	mutationStamps30: { number },
	disabledWarned: boolean,
}
export type Participant = { player: Player, score: number, correct: number }

local QuestService = {}

local started = false
local states: { [Player]: PlayerState } = {}

local function safe(label: string, fn: () -> ())
	local ok, err = pcall(function()
		fn()
	end)
	if not ok then
		warn(`[MathShow] quest hook {label} failed: {err}`)
	end
end

local function seedOf(player: Player): number
	return math.abs(math.floor(player.UserId))
end

-- The current UTC day on this server's daily clock (a Studio-only offset applies there).
function QuestService.today(): number
	return XpRules.dayOf(ProfileService.wallNow()) or 0
end

local function persistence(player: Player): string
	return ProfileService.persistence(player) or "unavailable"
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Attributes and QuestState

local function applyAttributes(player: Player, xp: number)
	local level = XpRules.levelForXp(xp)
	local rewards = LevelRewards.rewardsFor(level)
	local title = if rewards ~= nil and rewards.title ~= nil then rewards.title.name else ""
	local plate = if rewards ~= nil then rewards.plate else nil
	safe("attributes", function()
		player:SetAttribute("Level", level)
		player:SetAttribute("Title", title)
		player:SetAttribute("PlateColor", if plate ~= nil then Color3.fromRGB(plate.r, plate.g, plate.b) else nil)
	end)
end

local function buildState(player: Player, st: PlayerState, result: string): Net.QuestStatePayload
	local profile = ProfileService.get(player)
	local xp = if profile ~= nil then profile.xp or 0 else 0
	local board = if profile ~= nil then profile.quests else nil
	local slots: { Net.QuestSlotView } = {}
	if board ~= nil then
		for i = 1, QuestConfig.SlotCount do
			local slot = board.slots[i]
			slots[i] = { id = slot.id, generation = slot.generation, progress = slot.progress, claimed = slot.claimed }
		end
	end
	st.revision += 1
	local claim = st.pendingClaim
	return {
		revision = st.revision,
		result = result,
		persistence = persistence(player),
		day = if board ~= nil then board.day else nil,
		catalogVersion = if board ~= nil then board.catalogVersion else nil,
		boardRevision = if board ~= nil then board.boardRevision else nil,
		slots = slots,
		bonusGranted = board ~= nil and board.bonusGranted,
		xp = xp,
		level = XpRules.levelForXp(xp),
		xpIntoLevel = XpRules.xpIntoLevel(xp),
		nextLevelXp = XpRules.xpForNextLevel(xp),
		pending = ProfileService.pendingCommands(player),
		pendingClaim = if claim ~= nil then claim.slot else nil,
	}
end

local function push(player: Player, result: string)
	local st = states[player]
	if st == nil or player.Parent == nil then
		return
	end
	safe("QuestState", function()
		Remotes.QuestState:FireClient(player, buildState(player, st, result))
	end)
end

local function refreshAttributes(player: Player)
	local profile = ProfileService.get(player)
	if profile ~= nil then
		applyAttributes(player, profile.xp or 0)
	end
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Intents -> commands

local function queue(player: Player, command: ProfileRules.Command): boolean
	local ok, reason = ProfileService.queueCommand(player, command)
	if not ok and reason ~= "duplicate" then
		warn(`[MathShow] quest command {command.type} for {player.Name} not queued: {reason}`)
	end
	return ok or reason == "duplicate"
end

-- Queues a rollover for `day` when neither the stored epoch nor an earlier queued rollover reaches it. False: it could not
-- be queued (the caller then drops the intent: it must never attach to a board of another day).
local function ensureDay(
	player: Player,
	st: PlayerState,
	profile: ProfileRules.Profile,
	day: number,
	eventId: string
): boolean
	local known = math.max(profile.dailyEpoch or -1, st.queuedEpoch)
	if known >= day then
		return true
	end
	if queue(player, { type = "rollover", newDay = day, eventId = `{eventId}:r` }) then
		st.queuedEpoch = day
		return true
	end
	return false
end

local function dispatch(player: Player, st: PlayerState, intent: Intent)
	local profile = ProfileService.get(player)
	if profile == nil then
		return
	end
	if profile.dailyDisabled == true then
		if not st.disabledWarned then
			st.disabledWarned = true
			warn(`[MathShow] daily quests of {player.Name} are disabled (damaged stored state); no XP or progress`)
		end
		return
	end
	if not ensureDay(player, st, profile, intent.day, intent.eventId) then
		return
	end
	local play = intent.play
	if play ~= nil and play.nominal > 0 then
		queue(player, {
			type = "play",
			day = intent.day,
			source = play.source,
			nominal = play.nominal,
			eventId = `{intent.eventId}:p`,
		})
	end
	local fact = intent.fact
	if fact ~= nil then
		local confirmed = profile.quests
		local board: QuestRules.Board? = if confirmed ~= nil and confirmed.day == intent.day
			then confirmed
			else QuestRules.boardFor(seedOf(player), intent.day, QuestConfig.CatalogVersion)
		if board == nil then
			return
		end
		for i = 1, QuestConfig.SlotCount do
			local slot = board.slots[i]
			local quest = QuestConfig.Catalog[slot.id]
			local done = confirmed == board and slot.progress >= quest.target
			if quest.kind == fact.kind and not done then
				queue(player, {
					type = "progress",
					day = intent.day,
					catalogVersion = board.catalogVersion,
					slotId = slot.id,
					generation = slot.generation,
					kind = fact.kind,
					amount = fact.amount,
					eventId = `{intent.eventId}:q{i}`,
				})
			end
		end
	end
end

-- Hands an intent to the queue, or holds it (bounded) while the profile loads. Never yields.
local function submit(player: Player, intent: Intent)
	local st = states[player]
	if st == nil then
		return
	end
	local state = persistence(player)
	if state == "loading" then
		if #st.buffer >= PRELOAD_CAP then
			if not st.bufferWarned then
				st.bufferWarned = true
				warn(
					`[MathShow] quest facts of {player.Name} dropped: more than {PRELOAD_CAP} before the profile loaded`
				)
			end
			return
		end
		for _, held in st.buffer do
			if held.eventId == intent.eventId then
				return
			end
		end
		table.insert(st.buffer, intent)
	elseif state == "saved" or state == "memory" then
		dispatch(player, st, intent)
	else
		warn(`[MathShow] quest fact of {player.Name} dropped: profile {state}`)
	end
end

local function play(source: string, nominal: number): { source: string, nominal: number }
	return { source = source, nominal = nominal }
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Hooks (server-only). Each is wrapped: a failure warns and changes nothing else.

-- Round: one accepted correct answer, after the question lock. `runId` is the match's server-generated id.
function QuestService.roundAnswer(player: Player, runId: string, questionIndex: number)
	safe("roundAnswer", function()
		submit(player, {
			day = QuestService.today(),
			fact = { kind = "correct", amount = 1 },
			eventId = `{runId}:a:{player.UserId}:{questionIndex}`,
		})
	end)
end

-- Round: the match reached Results. One completion per participant with at least one correct answer; the top three by
-- XpRules.top3 (score descending, then userId ascending) also earn the bonus. Called once per run.
function QuestService.roundFinished(runId: string, participants: { Participant })
	safe("roundFinished", function()
		local day = QuestService.today()
		local pool: { XpRules.Participant } = {}
		local byUser: { [number]: Player } = {}
		for _, entry in participants do
			table.insert(pool, { userId = entry.player.UserId, score = entry.score, eligible = entry.correct >= 1 })
			byUser[entry.player.UserId] = entry.player
		end
		for _, entry in participants do
			if entry.correct >= 1 then
				submit(entry.player, {
					day = day,
					play = play("round", XpConfig.PlayAward.RoundFinish),
					fact = { kind = "round_finish", amount = 1 },
					eventId = `{runId}:f:{entry.player.UserId}`,
				})
			end
		end
		for _, userId in XpRules.top3(pool) do
			local winner = byUser[userId]
			if winner then
				submit(winner, {
					day = day,
					play = play("round_top3", XpConfig.PlayAward.RoundTop3Bonus),
					eventId = `{runId}:t:{userId}`,
				})
			end
		end
	end)
end

-- Blitz: the run ended through the existing result boundary (call after the ended guard, never earlier). `correct` is the
-- run's correct count and `day` the day the run started. A run with no correct answer earns nothing.
function QuestService.blitzFinished(player: Player, runId: string, correct: number, day: number?)
	safe("blitzFinished", function()
		if correct < 1 then
			return
		end
		local eventDay = day or QuestService.today()
		submit(player, {
			day = eventDay,
			fact = { kind = "correct", amount = correct },
			eventId = `{runId}:a`,
		})
		submit(player, {
			day = eventDay,
			play = play("blitz", XpConfig.PlayAward.BlitzFinish),
			fact = { kind = "blitz_finish", amount = 1 },
			eventId = `{runId}:f`,
		})
	end)
end

-- Skill Test: one accepted correct answer (answers are revealed at once, so the fact is released at once).
function QuestService.skillAnswer(player: Player, runId: string, attempt: number)
	safe("skillAnswer", function()
		submit(player, {
			day = QuestService.today(),
			fact = { kind = "correct", amount = 1 },
			eventId = `{runId}:a:{attempt}`,
		})
	end)
end

-- Skill Test: the run finished normally (also when the player left during the finished final reveal). The caller owns the
-- once-per-run guard. A run with no correct answer earns nothing.
function QuestService.skillFinished(player: Player, runId: string, correct: number)
	safe("skillFinished", function()
		if correct < 1 then
			return
		end
		submit(player, {
			day = QuestService.today(),
			play = play("skill", XpConfig.PlayAward.SkillFinish),
			fact = { kind = "skill_finish", amount = 1 },
			eventId = `{runId}:f`,
		})
	end)
end

-- Glyph: one accepted pickup after the collection state changed. `pickupId` is a server-generated id for this pickup.
function QuestService.glyph(player: Player, pickupId: string, rarity: string)
	safe("glyph", function()
		local day = QuestService.today()
		submit(player, {
			day = day,
			play = play("glyph", XpConfig.PlayAward.Glyph),
			fact = { kind = "glyph", amount = 1 },
			eventId = `{pickupId}:g`,
		})
		if rarity == "rare" then
			submit(player, { day = day, fact = { kind = "rare", amount = 1 }, eventId = `{pickupId}:r` })
		end
	end)
end

-- A fresh server-generated run / pickup id.
function QuestService.newId(): string
	return HttpService:GenerateGUID(false)
end

-- ---------------------------------------------------------------------------------------------------------------------
-- Remotes

local function onRequest(player: Player)
	local st = states[player]
	if st == nil then
		return
	end
	local allowed
	st.requestStamps, allowed = RateRules.allow(st.requestStamps, os.clock(), REQUESTS_PER_10S, 10)
	if not allowed then
		push(player, "rate")
		return
	end
	local state = persistence(player)
	if state == "loading" then
		push(player, "loading")
		return
	end
	if state ~= "saved" and state ~= "memory" then
		push(player, "unavailable")
		return
	end
	-- Opening today's board is a conditional rollover command like any other; it is never an unconditional grant.
	local profile = ProfileService.get(player)
	if profile ~= nil and profile.dailyDisabled ~= true then
		local today = QuestService.today()
		ensureDay(player, st, profile, today, `req:{QuestService.newId()}`)
	end
	push(player, if ProfileService.pendingCommands(player) > 0 then "pending" else "confirmed")
end

local function onClaim(player: Player, raw: any)
	local st = states[player]
	if st == nil then
		return
	end
	local command = ProfileRules.parseClaimPayload(raw) -- type and range; unknown fields, NaN, fractions refused
	if command == nil then
		return
	end
	local now = os.clock()
	local allowed1, allowed30
	st.mutationStamps1, allowed1 = RateRules.allow(st.mutationStamps1, now, MUTATIONS_PER_1S, 1)
	st.mutationStamps30, allowed30 = RateRules.allow(st.mutationStamps30, now, MUTATIONS_PER_30S, 30)
	if not allowed1 or not allowed30 then
		push(player, "rate")
		return
	end
	local state = persistence(player)
	if state == "loading" then
		push(player, "loading")
		return
	end
	if state ~= "saved" and state ~= "memory" then
		push(player, "unavailable")
		return
	end
	if st.pendingClaim ~= nil then
		push(player, "pending")
		return
	end
	local eventId = `claim:{QuestService.newId()}`
	st.pendingClaim = { slot = command.slot :: number, eventId = eventId } -- marked before anything can yield
	command.eventId = eventId
	local queued, reason = ProfileService.queueCommand(player, command)
	if not queued then
		st.pendingClaim = nil
		push(player, if reason == "loading" then "loading" elseif reason == "queue_full" then "rate" else "unavailable")
		return
	end
	ProfileService.flush(player)
	push(player, "pending")
end

local function resolveClaim(player: Player, st: PlayerState, event: ProfileService.Event): string?
	local claim = st.pendingClaim
	if claim == nil or event.eventIds == nil or table.find(event.eventIds, claim.eventId) == nil then
		return nil
	end
	st.pendingClaim = nil
	if event.outcome ~= "applied" and event.outcome ~= "acknowledged" then
		return "unavailable" -- the op was abandoned or expired: nothing is known to have landed
	end
	local profile = ProfileService.get(player)
	local board = if profile ~= nil then profile.quests else nil
	local slot = if board ~= nil then board.slots[claim.slot] else nil
	return if slot ~= nil and slot.claimed then "confirmed" else "stale"
end

local function onProfileEvent(event: ProfileService.Event)
	local player = event.player
	local st = states[player]
	if st == nil or player.Parent == nil then
		return
	end
	if event.kind == "loaded" then
		local held = st.buffer
		st.buffer = {}
		for _, intent in held do
			submit(player, intent)
		end
		refreshAttributes(player)
		push(player, "confirmed")
	elseif event.kind == "settled" then
		local result = resolveClaim(player, st, event)
		refreshAttributes(player)
		push(player, result or (if ProfileService.pendingCommands(player) > 0 then "pending" else "confirmed"))
	end
end

local function addPlayer(player: Player)
	if states[player] ~= nil then
		return
	end
	states[player] = {
		revision = 0,
		buffer = {},
		bufferWarned = false,
		queuedEpoch = -1,
		pendingClaim = nil,
		requestStamps = {},
		mutationStamps1 = {},
		mutationStamps30 = {},
		disabledWarned = false,
	}
	-- A profile that loaded before this player was seen: attributes and the first state at once.
	if persistence(player) == "saved" or persistence(player) == "memory" then
		onProfileEvent({ kind = "loaded", player = player })
	end
end

-- Idempotent. Start after ProfileService (it provides the queue and the events).
function QuestService.start(): ()
	if started then
		return
	end
	started = true
	ProfileService.subscribe(onProfileEvent)
	Remotes.QuestRequest.OnServerEvent:Connect(function(player: Player, ...: any)
		if select("#", ...) ~= 0 then
			return -- QuestRequest carries no arguments
		end
		safe("QuestRequest", function()
			onRequest(player)
		end)
	end)
	Remotes.QuestClaim.OnServerEvent:Connect(function(player: Player, raw: any)
		safe("QuestClaim", function()
			onClaim(player, raw)
		end)
	end)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		states[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
end

return QuestService
