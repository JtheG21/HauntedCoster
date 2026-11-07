--!strict
-- Player profiles for the menu (TASK-0099): settings, best rank, blitz best and the Skill Test clock, stored in one
-- DataStore per player. Adapted from the Haunted Collector PlayerDataService, simplified: no session lock, because every
-- save is an UpdateAsync that MERGES into what is stored (ProfileRules.merge: bests only go up, settings last writer wins,
-- the glyph total grows by this session's unsaved increments, fields this build does not know are kept), so two servers
-- can never lower a rank or blitz best or lose each other's glyphs. Stored data from a newer build is never rewritten.
-- Glyph saves are at most once (TASK-0141; design in the TASK-0141 note). Each session has a ProfileRules.Ledger and ONE
-- save worker (work()). Debounce, autosave, leave and BindToClose only signal it. The worker takes a frozen operation
-- {sessionId, seq, glyphsDelta, createdAt = os.clock()} before any yield, attempts it with UpdateAsync, and settles the
-- outcome (ProfileRules.classifyAttempt, R6): applied / acknowledged (confirmed), abandoned (logged once, never
-- recredited), capacity and retryable_no_candidate (kept, retried), newer_schema (memory-only), ambiguous (any end after
-- a write candidate other than a returned value: a later attempt then only acknowledges it from a covering receipt or
-- abandons it). Acknowledging writes nothing (R1). An op carries only the settings keys this session changed (R2), and
-- they are dropped when another session saved since the op was created (R3). No write candidate is returned at or past the
-- retry window (monotonic os.clock()) or, during shutdown, the shutdown deadline (R5), checked at dispatch and inside
-- every callback. An op reported unconfirmed at shutdown is never reported again (R4). Increments that arrive meanwhile
-- stay pending for the next op. A left player's session stays in `releasing` until its work is resolved; autosave keeps
-- signalling it.
--
-- Safety: every DataStore call is pcall-isolated and never blocks the match loop. A failed load retries, then the profile is
-- "readonly" (nothing written, so an outage can never overwrite real data with defaults). In Studio or an unpublished place,
-- an "API unavailable" error runs the player in "memory" mode (works, not saved). Remotes: MenuRequest (RemoteFunction) and
-- SettingsSave (RemoteEvent); every client value is validated (type, range, rate) and the server never trusts the client.
--
-- Studio-only test hooks: all read through studioHook(), which returns nil unless RunService:IsStudio() and
-- RunService:IsServer(). They are server workspace attributes (a client's attribute change does not replicate to the
-- server), and this module runs only on the server. Entry points:
--  * MathShowForceProfileFail = true: the next loads fail (load()).
--  * MathShowForceSaveErrorAfterCommit = true: the next attempt whose callback returned a write errors AFTER UpdateAsync
--    committed (consumed once; attempt()).
--  * MathShowForceSaveCandidateThenError = true: consumed by the next attempt; if its callback returns a write, it errors
--    instead, so the call fails with a candidate submitted but nothing committed (attempt()).
--  * MathShowForceSaveFailures = n: the next n attempts fail before dispatch, no candidate (decremented; attempt()).
--  * MathShowProfileRetryWindowS = s: a shorter retry window in seconds (never longer than RETRY_WINDOW_S; retryWindow()).

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local Net = require(Shared:WaitForChild("Net"))
local ProfileConfig = require(Shared:WaitForChild("ProfileConfig"))
local ProfileRules = require(Shared:WaitForChild("ProfileRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))

local Remotes = require(script.Parent.Parent.Remotes)

export type Persistence = "loading" | "saved" | "memory" | "readonly"
type Session = {
	userId: number,
	profile: ProfileRules.Profile,
	persistence: Persistence,
	dirty: boolean, -- idempotent fields (settings, bests, test clock) changed since the last op was taken
	ledger: ProfileRules.Ledger, -- seq, pending glyphs and settings, the unresolved op, its ambiguity and terminal report
	knownReceipts: { [string]: number }, -- other sessions' receipt seqs in the value this session loaded (R3 exemption)
	working: boolean, -- the save worker is running
	signalled: boolean, -- a signal arrived while it was running: loop once more
	attempting: boolean, -- an UpdateAsync call is in flight
	leaving: boolean, -- the player left; the worker retries with backoff until the work is resolved
	overdueSeq: number, -- the op already reported overdue (once)
	token: number, -- debounce: only the newest scheduled save runs
	menuStamps: { number },
	saveStamps: { number },
}

local ProfileService = {}

local STORE_NAME = "MathShow_Profiles_v1"
local RETRIES = 4
local SAVE_DEBOUNCE_SECONDS = 2
local AUTOSAVE_SECONDS = 60
local LOAD_WAIT_SECONDS = 20 -- longer than the load backoff (2 + 4 + 8 s), so a slow load is not reported as unavailable
local REJOIN_WAIT_SECONDS = 30
local LEAVE_ATTEMPTS = 5 -- per leave signal; after them the session stays in `releasing` and autosave signals it again
local SHUTDOWN_ATTEMPTS = 6 -- per session during the BindToClose drain
local DEVELOPMENT_PLACE = RunService:IsStudio() or game.PlaceId == 0

local started = false
local store: DataStore? = nil
local storeError = "no DataStore" -- why GetDataStore failed, so load() can tell "unpublished place" from a real outage
local sessions: { [Player]: Session } = {}
local releasing: { [Session]: true } = {} -- left players whose save work is not resolved yet (a rejoin waits for them)
local shuttingDown = false
local shutdownDeadline = math.huge

local function keyFor(userId: number): string
	return `p_{userId}`
end

local function getStore(): DataStore?
	if store then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		storeError = tostring(result)
		warn(`[MathShow] GetDataStore failed: {result}`)
	end
	return store
end

-- The one gate for every Studio test hook: nil unless this is a Studio server.
local function studioHook(name: string): any
	if RunService:IsStudio() and RunService:IsServer() then
		return workspace:GetAttribute(name)
	end
	return nil
end

local function consumeHook(name: string): boolean
	if studioHook(name) == true then
		workspace:SetAttribute(name, nil)
		return true
	end
	return false
end

local function retryWindow(): number
	local override = studioHook("MathShowProfileRetryWindowS")
	return ProfileRules.retryWindow(if typeof(override) == "number" then override else nil)
end

local function load(player: Player, session: Session)
	local userId = player.UserId
	local tries = 0
	while player.Parent do
		local ds = getStore()
		local ok, result
		if studioHook("MathShowForceProfileFail") == true then
			ok, result = false, "simulated load failure"
		elseif ds then
			ok, result = pcall(function()
				return ds:GetAsync(keyFor(userId))
			end)
		else
			ok, result = false, storeError
		end
		if ok then
			session.profile = ProfileRules.sanitize(ProfileRules.migrate(result))
			session.knownReceipts = ProfileRules.receiptSeqs(result)
			if ProfileRules.isNewerVersion(result) then
				-- Stored by a newer build: play on a copy and never write it back (that would drop its newer fields).
				warn(`[MathShow] profile of {player.Name} is a newer version; running in memory-only mode`)
				session.persistence = "memory"
				return
			end
			session.persistence = "saved"
			return
		end
		local message = tostring(result)
		if ProfileRules.loadFailure(message, DEVELOPMENT_PLACE) == "memory" then
			warn(`[MathShow] DataStores unavailable ({message}); {player.Name} runs in memory-only mode`)
			session.profile = ProfileRules.sanitize(ProfileRules.migrate(session.profile))
			session.persistence = "memory"
			return
		end
		tries += 1
		warn(`[MathShow] profile load failed for {player.Name} (try {tries}): {message}`)
		if tries >= RETRIES then
			session.persistence = "readonly"
			return
		end
		task.wait(2 ^ tries)
	end
end

local function logTerminal(userId: number, terminal: ProfileRules.Terminal)
	warn(
		`[MathShow] profile save op ended unconfirmed for {userId}: reason={terminal.reason} seq={terminal.seq} `
			.. `delta={terminal.glyphsDelta} ambiguous={terminal.ambiguous}`
	)
end

-- Seconds left to the shared shutdown deadline, or nil when the server is not shutting down. Read live (R5).
local function shutdownLeft(): number?
	return if shuttingDown then shutdownDeadline - os.clock() else nil
end

-- One attempt of `op`. Never yields before UpdateAsync. The op window and, during shutdown, the shutdown deadline are
-- checked here (dispatch) and in every callback (R5). How the attempt ended is ProfileRules.classifyAttempt's call (R6).
-- Returns the attempt, the value to adopt (what UpdateAsync returned after a write, else what the last callback saw),
-- and whether the committed write dropped its settings patch as superseded (R3).
local function attempt(session: Session, op: ProfileRules.SaveOp): (ProfileRules.Attempt, any, boolean)
	local window = retryWindow()
	if ProfileRules.expired(op, os.clock(), window) then
		return { kind = "expired" }, nil, false
	end
	local left = shutdownLeft()
	if left ~= nil and left <= 0 then
		return { kind = "retryable_no_candidate", reason = "shutdown_deadline" }, nil, false
	end
	local failures = studioHook("MathShowForceSaveFailures")
	if typeof(failures) == "number" and failures >= 1 then
		workspace:SetAttribute("MathShowForceSaveFailures", if failures > 1 then failures - 1 else nil)
		warn(`[MathShow] simulated save failure before dispatch (Studio hook), op {op.seq}`)
		return { kind = "retryable_no_candidate", reason = "simulated" }, nil, false
	end
	local ds = getStore()
	if not ds then
		return { kind = "retryable_no_candidate", reason = "no_store" }, nil, false
	end
	local patch = ProfileRules.toPatch(session.profile) -- its settings are ignored: the op carries its own patch (R2)
	local ambiguous = session.ledger.ambiguous
	local known = session.knownReceipts
	local failInCallback = consumeHook("MathShowForceSaveCandidateThenError")
	local decisions: { ProfileRules.SavePlan } = {}
	local seen: any = nil
	session.attempting = true
	local ok, result = pcall(function()
		return ds:UpdateAsync(keyFor(session.userId), function(old: any)
			local decided = ProfileRules.planSave(old, op, {
				nowWall = os.time(),
				elapsed = os.clock() - op.createdAt,
				ambiguous = ambiguous,
				patch = patch,
				window = window,
				shutdownLeft = shutdownLeft(),
				knownReceipts = known,
			})
			table.insert(decisions, decided) -- recorded before returning: an error from here on is "possibly committed"
			seen = old
			if decided.write ~= nil and failInCallback then
				error("simulated: write candidate returned, then the call failed (Studio hook)")
			end
			return decided.write
		end)
	end)
	session.attempting = false
	local last = decisions[#decisions]
	if ok and result ~= nil and last ~= nil and last.write ~= nil then
		if consumeHook("MathShowForceSaveErrorAfterCommit") then
			ok, result = false, "simulated: UpdateAsync committed, then errored (Studio hook)"
		end
	end
	-- An error raised inside the transform does not reach the pcall: the engine logs "Transform function error" and
	-- returns nil (seen in Studio, TASK-0141 S4). classifyAttempt treats that nil after a candidate as ambiguous.
	local outcome, reason = ProfileRules.classifyAttempt(decisions, if ok then result else nil, not ok)
	local kind: ProfileRules.AttemptKind = outcome :: any -- Luau widens the returned string union
	if outcome == "ambiguous" or (outcome == "retryable_no_candidate" and not ok) then
		local detail = if ok then "UpdateAsync returned no value after a write candidate" else tostring(result)
		warn(
			`[MathShow] profile save attempt failed for {session.userId} (op {op.seq}, outcome={outcome}, `
				.. `callbacks={#decisions}): {detail}`
		)
		return { kind = kind, reason = reason }, nil, false
	end
	local wrote = outcome == "applied"
	local base = if wrote then result else seen
	return { kind = kind, reason = reason }, base, wrote and last ~= nil and last.superseded == true
end

-- Applies a settled attempt to the session: ledger, terminal log, memory-only switch and profile adoption. `dropped`: the
-- committed write dropped its settings patch as superseded (R3). After an op already reported
-- unconfirmed at shutdown, a late settlement only updates state (R4): no second report of any kind.
local function settleAttempt(session: Session, outcome: ProfileRules.Attempt, base: any, dropped: boolean)
	local op = session.ledger.op
	local seq = if op ~= nil then op.seq else 0
	local quiet = op ~= nil and session.ledger.reportedSeq == seq
	local ledger, terminal = ProfileRules.settle(session.ledger, outcome)
	session.ledger = ledger
	if terminal ~= nil then
		logTerminal(session.userId, terminal)
	end
	local kind = outcome.kind
	if kind == "expired" then
		session.dirty = true -- the abandoned op's idempotent fields go out with the next op (its delta does not)
		return
	elseif kind == "newer_schema" then
		session.persistence = "memory"
		warn(`[MathShow] stored profile of {session.userId} is a newer version; not saving, memory-only from now on`)
		return
	elseif kind == "capacity" then
		if not quiet then
			warn(`[MathShow] profile receipt log of {session.userId} is full; op {seq} kept for retry`)
		end
		return
	elseif kind ~= "applied" and kind ~= "acknowledged" and kind ~= "abandoned" then
		return -- ambiguous / retryable: the op is kept, nothing to adopt
	end
	if not quiet then
		if kind == "acknowledged" then
			warn(`[MathShow] save op {seq} of {session.userId} acknowledged by its receipt; nothing written`)
		elseif dropped then
			warn(`[MathShow] save op {seq} of {session.userId}: settings superseded by a newer session; glyphs applied`)
		end
		if shuttingDown and (kind == "applied" or kind == "acknowledged") then
			print(`[MathShow] shutdown: save op {seq} of {session.userId} confirmed ({kind})`)
		end
	end
	if kind == "abandoned" then
		session.dirty = true -- the abandoned op's bests may not have landed; an acknowledged op's did
	end
	if base ~= nil then
		-- Adopt what is stored (another server may have raised a best, added glyphs or saved newer settings), plus what is
		-- still pending. After an abandon this drops the abandoned delta from the displayed total: the store is the truth.
		session.profile =
			ProfileRules.adopt(base, session.profile, session.ledger.pending, session.ledger.settingsPatch)
	end
end

local function settled(session: Session): boolean
	local ledger = session.ledger
	return ledger.op == nil and ledger.pending <= 0 and next(ledger.settingsPatch) == nil and not session.dirty
end

local function release(session: Session)
	if releasing[session] and (settled(session) or session.persistence ~= "saved") then
		releasing[session] = nil
	end
end

local function drive(session: Session)
	local failures = 0
	while session.persistence == "saved" do
		session.signalled = false
		if shuttingDown and os.clock() >= shutdownDeadline then
			break
		end
		local ledger, op, fresh = ProfileRules.takeOp(session.ledger, session.dirty, os.clock(), os.time())
		if op == nil then
			break
		end
		session.ledger = ledger
		if fresh then
			session.dirty = false
		end
		local outcome, base, dropped = attempt(session, op)
		settleAttempt(session, outcome, base, dropped)
		if session.ledger.op == nil then
			failures = 0
			if not (session.signalled or session.leaving or shuttingDown) then
				break
			end
		else
			-- Unresolved (error or capacity): ordinary saves wait for the next signal; leave and shutdown back off here.
			failures += 1
			local limit = if shuttingDown then SHUTDOWN_ATTEMPTS elseif session.leaving then LEAVE_ATTEMPTS else 0
			if failures >= limit then
				break
			end
			local backoff = if shuttingDown then math.min(2 ^ (failures - 1), 4) else math.min(2 ^ failures, 16)
			if shuttingDown then
				backoff = math.min(backoff, shutdownDeadline - os.clock())
			end
			if backoff > 0 then
				task.wait(backoff)
			end
		end
	end
end

-- The one save worker of a session. Every entry point calls this; a call while it runs only sets `signalled`.
local function work(session: Session)
	if session.working then
		session.signalled = true
		return
	end
	session.working = true
	local ok, err = pcall(function()
		drive(session)
	end)
	session.attempting = false
	session.working = false
	if not ok then
		warn(`[MathShow] profile save worker of {session.userId} failed: {err}`)
	end
	release(session)
end

local function scheduleSave(player: Player, session: Session)
	session.token += 1
	local token = session.token
	task.delay(SAVE_DEBOUNCE_SECONDS, function()
		if session.token == token and not shuttingDown and sessions[player] == session then
			work(session)
		end
	end)
end

-- The player's profile (a copy), or nil while it is still loading or when it could not be loaded.
function ProfileService.get(player: Player): ProfileRules.Profile?
	local session = sessions[player]
	if session and (session.persistence == "saved" or session.persistence == "memory") then
		return ProfileRules.merge(session.profile, {})
	end
	return nil
end

function ProfileService.persistence(player: Player): Persistence?
	local session = sessions[player]
	return if session then session.persistence else nil
end

-- Folds a patch into the player's profile and schedules a debounced save. Returns false when nothing was changed
-- (not loaded, read-only). Later tasks (Skill Test, Blitz) call this; clients never do. A patch's lastTestRank is only kept
-- together with its lastTakenAt (the pair follows the newest test), so always send both.
function ProfileService.apply(player: Player, patch: ProfileRules.Patch): boolean
	local session = sessions[player]
	if not session or (session.persistence ~= "saved" and session.persistence ~= "memory") then
		return false
	end
	local before = session.profile.settings
	session.profile = ProfileRules.merge(session.profile, patch)
	if session.persistence == "saved" then
		if patch.settings ~= nil then
			-- Only the keys that changed go into the next op (R2), never the whole settings table.
			session.ledger = ProfileRules.noteSettings(session.ledger, before, session.profile.settings)
		end
		session.dirty = true
		scheduleSave(player, session)
	end
	return true
end

-- Server-only (TASK-0138): adds `amount` to the lifetime glyph total and returns the new total, or nil when nothing was
-- changed (not loaded, read-only, invalid amount). It only marks the profile dirty: the 60 s autosave, the leave save
-- and BindToClose persist it, so a collect never causes a DataStore write of its own.
function ProfileService.addGlyphs(player: Player, amount: number): number?
	local session = sessions[player]
	if not session or (session.persistence ~= "saved" and session.persistence ~= "memory") then
		return nil
	end
	local updated = ProfileRules.addGlyphs(session.profile, amount)
	local added = (updated.glyphsLifetime or 0) - (session.profile.glyphsLifetime or 0)
	if added <= 0 then
		return nil
	end
	session.profile = updated
	if session.persistence == "saved" then
		session.ledger = ProfileRules.credit(session.ledger, added) -- for the NEXT op; never derived from the total
	end
	return updated.glyphsLifetime
end

-- The lifetime glyph total, or nil while the profile is loading or unavailable.
function ProfileService.glyphsLifetime(player: Player): number?
	local session = sessions[player]
	if session and (session.persistence == "saved" or session.persistence == "memory") then
		return session.profile.glyphsLifetime or 0
	end
	return nil
end

-- Yields until the profile has loaded (or LOAD_WAIT_SECONDS passes). Safe to call from a remote handler.
function ProfileService.waitLoaded(player: Player): Persistence?
	local deadline = os.clock() + LOAD_WAIT_SECONDS
	local session = sessions[player]
	while session and session.persistence == "loading" and os.clock() < deadline and player.Parent do
		task.wait(0.2)
		session = sessions[player]
	end
	return if session then session.persistence else nil
end

local function onMenuRequest(player: Player, raw: any): Net.MenuProfileReply
	local session = sessions[player]
	if not session then
		return { ok = false, reason = "unavailable" }
	end
	if typeof(raw) ~= "table" or raw.kind ~= "profile" then
		return { ok = false, reason = "bad request" }
	end
	for key in raw do
		if key ~= "kind" then
			return { ok = false, reason = "bad request" }
		end
	end
	local allowed
	session.menuStamps, allowed = RateRules.allow(session.menuStamps, os.clock(), MenuConfig.MenuRequestsPer30s, 30)
	if not allowed then
		return { ok = false, reason = "rate" }
	end
	local state = ProfileService.waitLoaded(player)
	local profile = ProfileService.get(player)
	if state == nil or profile == nil then
		return { ok = false, reason = if state == "loading" then "loading" else "unavailable" }
	end
	return { ok = true, profile = ProfileRules.toClient(profile, state :: string) }
end

local function onSettingsSave(player: Player, raw: any)
	local session = sessions[player]
	if not session then
		return
	end
	local settings = ProfileRules.sanitizeSettings(raw)
	if not settings then
		return
	end
	local allowed
	session.saveStamps, allowed = RateRules.allow(
		session.saveStamps,
		os.clock(),
		MenuConfig.SettingsSavesPerWindow,
		MenuConfig.SettingsSaveWindowSeconds
	)
	if not allowed then
		return
	end
	ProfileService.apply(player, { settings = settings })
end

local function releasingFor(userId: number): boolean
	for session in releasing do
		if session.userId == userId then
			return true
		end
	end
	return false
end

local function onPlayerAdded(player: Player)
	if sessions[player] then
		return
	end
	-- A quick rejoin must not read the stored value before the previous visit's save has landed. Past the wait the new
	-- session loads anyway: the old one keeps its own session id and ops, and saves are additive, so nothing is lost.
	local deadline = os.clock() + REJOIN_WAIT_SECONDS
	while releasingFor(player.UserId) and os.clock() < deadline and player.Parent do
		task.wait(0.2)
	end
	local session: Session = {
		userId = player.UserId,
		profile = ProfileRules.defaults(),
		persistence = "loading",
		dirty = false,
		ledger = ProfileRules.newLedger(HttpService:GenerateGUID(false)),
		knownReceipts = {},
		working = false,
		signalled = false,
		attempting = false,
		leaving = false,
		overdueSeq = 0,
		token = 0,
		menuStamps = {},
		saveStamps = {},
	}
	sessions[player] = session
	local ok, err = pcall(function()
		load(player, session)
	end)
	if not ok then
		warn(`[MathShow] profile load crashed for {player.Name}: {err}`)
		session.persistence = "readonly"
	end
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	sessions[player] = nil
	session.leaving = true
	session.token += 1 -- a scheduled debounce for this session no longer fires
	if session.persistence ~= "saved" or settled(session) then
		return
	end
	releasing[session] = true
	task.spawn(work, session)
end

-- Every session that may still have save work: players in game and left players not yet released.
local function allSessions(): { Session }
	local list = {}
	for _, session in sessions do
		table.insert(list, session)
	end
	for session in releasing do
		table.insert(list, session)
	end
	return list
end

-- An op whose window passed while its call is in flight is left to settle (its ownership stays); report it once.
local function markOverdue(session: Session, window: number)
	local op = session.ledger.op
	if
		op ~= nil
		and session.attempting
		and session.overdueSeq ~= op.seq
		and ProfileRules.expired(op, os.clock(), window)
	then
		session.overdueSeq = op.seq
		warn(`[MathShow] save op {op.seq} of {session.userId} is overdue; letting the call in flight settle`)
	end
end

local function drainOnShutdown()
	shuttingDown = true
	shutdownDeadline = os.clock() + ProfileConfig.SHUTDOWN_DEADLINE_S
	local list = allSessions()
	for _, session in list do
		task.spawn(work, session)
	end
	task.wait()
	while os.clock() < shutdownDeadline do
		local busy = false
		for _, session in list do
			if session.working then
				busy = true
			end
		end
		if not busy then
			break
		end
		task.wait(0.2)
	end
	-- Report what is unresolved, once per op: an op still in flight stays potentially committed.
	local unresolved = 0
	for _, session in list do
		if session.persistence == "saved" then
			local op = session.ledger.op
			if op ~= nil then
				-- The op's one terminal report (R4); settle() records it, so a later settlement stays silent.
				local ledger, terminal =
					ProfileRules.settle(session.ledger, { kind = "unconfirmed", candidate = session.attempting })
				session.ledger = ledger
				if terminal ~= nil then
					logTerminal(session.userId, terminal)
				end
			end
			if session.ledger.pending > 0 then
				warn(`[MathShow] {session.ledger.pending} glyphs of {session.userId} not saved before shutdown`)
			end
			if not settled(session) then
				unresolved += 1
			end
		end
	end
	print(`[MathShow] shutdown drain done: {#list} sessions, {unresolved} unresolved`)
end

function ProfileService.start(): ()
	if started then
		return
	end
	started = true

	Remotes.MenuRequest.OnServerInvoke = function(player: Player, raw: any): any
		local ok, reply = pcall(onMenuRequest, player, raw)
		if ok then
			return reply
		end
		warn(`[MathShow] MenuRequest from {player.Name} failed: {reply}`)
		return { ok = false, reason = "unavailable" }
	end
	Remotes.SettingsSave.OnServerEvent:Connect(function(player: Player, raw: any)
		local ok, err = pcall(function()
			onSettingsSave(player, raw)
		end)
		if not ok then
			warn(`[MathShow] SettingsSave from {player.Name} failed: {err}`)
		end
	end)
	Players.PlayerAdded:Connect(function(player: Player)
		task.spawn(onPlayerAdded, player)
	end)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while not shuttingDown do
			task.wait(AUTOSAVE_SECONDS)
			if shuttingDown then
				break
			end
			local window = retryWindow()
			for _, session in allSessions() do
				markOverdue(session, window)
				if session.persistence == "saved" and not settled(session) then
					task.spawn(work, session)
				end
			end
		end
	end)
	game:BindToClose(drainOnShutdown)
end

return ProfileService
