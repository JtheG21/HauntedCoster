--!strict
-- Player profiles: load, validate, session-lock and save through DataStores.
--
-- Safety rules:
--  * Every load and every save passes through ProfileRules.sanitize, so malformed values are never kept.
--  * Saves use UpdateAsync with a session lock ({ job = JobId }). If another server owns the lock, this
--    server stops saving that profile instead of overwriting newer progress.
--  * Saves per player are serialised (one in flight, at most one queued).
--  * If DataStores are unavailable in a development place (Studio, or an unpublished place) the server
--    runs in "memory" mode: the game works and a banner says progress is not saved. On a live server the
--    same errors are retried and end in "readonly", never memory (SessionLockRules.loadFailure, TASK-0036).
--  * If a load fails for any other reason the profile is "readonly": the player can play but nothing is
--    written, so a temporary outage can never overwrite a real save with defaults.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ProfileRules = require(Shared:WaitForChild("Rules"):WaitForChild("ProfileRules"))
local SessionLockRules = require(Shared:WaitForChild("Rules"):WaitForChild("SessionLockRules"))

type Profile = ProfileRules.Profile
export type Persistence = "saved" | "memory" | "readonly" | "loading"

local PlayerDataService = {}

local STORE_NAME = "HauntedCollector_Profiles_v1"
local AUTOSAVE_SECONDS = 60
-- Wait up to LOCK_WAIT_TRIES x 5 s for another server to release a live lock, then take it over (the
-- other server's later saves then abort because the lock is no longer theirs).
local LOCK_WAIT_TRIES = 6
local RETRIES = 4

local started = false
local store: DataStore? = nil
local serverMode: "datastore" | "memory" = "datastore"
local memoryReason = ""

type Session = {
	profile: Profile?,
	persistence: Persistence,
	saving: boolean,
	queued: boolean,
	queuedRelease: boolean,
	released: boolean,
}
local sessions: { [Player]: Session } = {}
local loadedCallbacks: { (Player, Profile) -> () } = {}
local dirtyCallbacks: { (Player) -> () } = {}

-- Studio or an unpublished place: the only places where DataStores may legitimately be off (TASK-0036).
local DEVELOPMENT_PLACE = RunService:IsStudio() or game.PlaceId == 0

local function goMemory(reason: string)
	if serverMode ~= "memory" then
		serverMode = "memory"
		memoryReason = reason
		warn(`[PlayerData] DataStores unavailable, running in memory-only mode: {reason}`)
	end
end

local function getStore(): DataStore?
	if store or serverMode == "memory" then
		return store
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	elseif DEVELOPMENT_PLACE then
		goMemory(tostring(result)) -- unchanged in Studio: no store means memory mode
	else
		-- Live server: no store this time. The caller treats the profile as readonly and the next
		-- caller tries again; the server never switches to memory mode.
		warn(`[PlayerData] GetDataStore failed: {result}`)
	end
	return store
end

local function keyFor(player: Player): string
	return `p_{player.UserId}`
end

local releaseLock: (Player) -> ()

local function deepCopy<T>(v: T): T
	if type(v) ~= "table" then
		return v
	end
	local out = {}
	for k, x in v :: any do
		out[k] = deepCopy(x)
	end
	return out :: any
end

local function fireDirty(player: Player)
	for _, cb in dirtyCallbacks do
		task.spawn(cb, player)
	end
end

local function loadRecord(player: Player): (string, any)
	local ds = getStore()
	if not ds then
		return if serverMode == "memory" then "memory" else "readonly", nil
	end
	local jobId = if game.JobId ~= "" then game.JobId else "studio"
	local key = keyFor(player)
	local lockTries = 0
	local errTries = 0
	while player.Parent do
		local locked = false
		local loaded: any = nil
		local ok, err = pcall(function()
			ds:UpdateAsync(key, function(old: any)
				-- Aborts (nil) while another server still owns this profile and we may keep waiting.
				local rec
				rec, loaded, locked = SessionLockRules.claim(old, jobId, os.time(), lockTries >= LOCK_WAIT_TRIES)
				return rec
			end)
		end)
		if ok and not locked then
			return "saved", loaded
		elseif ok and locked then
			lockTries += 1
			task.wait(5)
		else
			local msg = tostring(err)
			if SessionLockRules.loadFailure(msg, DEVELOPMENT_PLACE) == "memory" then
				goMemory(msg)
				return "memory", nil
			end
			errTries += 1
			warn(`[PlayerData] load failed for {player.Name} (try {errTries}): {msg}`)
			if errTries >= RETRIES then
				return "readonly", nil
			end
			task.wait(2 ^ errTries)
		end
	end
	return "readonly", nil
end

local function saveNow(player: Player, release: boolean)
	local session = sessions[player]
	if not session or not session.profile or session.persistence ~= "saved" or session.released then
		return
	end
	if session.saving then
		session.queued = true
		session.queuedRelease = session.queuedRelease or release
		return
	end
	session.saving = true
	local ds = getStore()
	local jobId = if game.JobId ~= "" then game.JobId else "studio"
	local profile = session.profile :: Profile
	profile.lastSeen = os.time()
	-- Re-validate the snapshot so a bug elsewhere can never write an impossible value.
	local snapshot = ProfileRules.sanitize(deepCopy(profile), os.time())
	local lost = false
	for attempt = 1, RETRIES do
		if not ds then
			break
		end
		local ok, err = pcall(function()
			ds:UpdateAsync(keyFor(player), function(old: any)
				-- Our session always holds the lock between load and release; a missing or foreign lock means
				-- another server took the profile over, so the write is aborted.
				local rec
				rec, lost = SessionLockRules.save(old, jobId, os.time(), snapshot, release)
				return rec
			end)
		end)
		if ok then
			break
		end
		warn(`[PlayerData] save failed for {player.Name} (try {attempt}): {err}`)
		if attempt < RETRIES then
			task.wait(2 ^ attempt)
		end
	end
	if lost then
		warn(`[PlayerData] {player.Name}'s profile is locked by another server; this server stops saving it`)
		session.persistence = "readonly"
		fireDirty(player)
	end
	if release then
		session.released = true
	end
	session.saving = false
	if session.queued and not session.released then
		local rel = session.queuedRelease
		session.queued = false
		session.queuedRelease = false
		saveNow(player, rel)
	end
end

-- Clears our session lock without writing the profile (used when we must not save it).
releaseLock = function(player: Player)
	local ds = getStore()
	if not ds then
		return
	end
	local jobId = if game.JobId ~= "" then game.JobId else "studio"
	pcall(function()
		ds:UpdateAsync(keyFor(player), function(old: any)
			return SessionLockRules.release(old, jobId)
		end)
	end)
end

local function onPlayerAdded(player: Player)
	if sessions[player] then
		return
	end
	local session: Session = {
		profile = nil,
		persistence = "loading",
		saving = false,
		queued = false,
		queuedRelease = false,
		released = false,
	}
	sessions[player] = session
	local mode, raw = loadRecord(player)
	if not player.Parent then
		if mode == "saved" then
			task.spawn(releaseLock, player)
		end
		return
	end
	if mode == "saved" and ProfileRules.persistenceFor(mode, raw) == "readonly" then
		-- Saved by a newer game version: play with a cleaned copy but never write it back, so this
		-- (older) server can't strip fields it doesn't understand. The newer server will save it.
		warn(`[PlayerData] {player.Name}'s profile has a newer schema; this server won't save it`)
		mode = "readonly"
		task.spawn(releaseLock, player)
	end
	local now = os.time()
	local profile, repaired = ProfileRules.sanitize(raw, now)
	if #repaired > 0 then
		warn(`[PlayerData] repaired fields for {player.Name}: {table.concat(repaired, ", ")}`)
	end
	session.profile = profile
	session.persistence = mode :: Persistence
	for _, cb in loadedCallbacks do
		task.spawn(cb, player, profile)
	end
	fireDirty(player)
end

local function onPlayerRemoving(player: Player)
	local session = sessions[player]
	if not session then
		return
	end
	saveNow(player, true)
	-- Wait for an in-flight save (and its queued follow-up) before forgetting the session.
	local deadline = os.clock() + 30
	while session.saving and os.clock() < deadline do
		task.wait(0.1)
	end
	sessions[player] = nil
end

function PlayerDataService.start()
	if started then
		return
	end
	started = true
	getStore()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayerAdded, p)
	end
	task.spawn(function()
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player in sessions do
				task.spawn(saveNow, player, false)
			end
		end
	end)
	game:BindToClose(function()
		-- Snapshot the sessions: PlayerRemoving may clear the map while we wait.
		local list: { Session } = {}
		for player, session in sessions do
			table.insert(list, session)
			task.spawn(saveNow, player, true)
		end
		-- saveNow only queues when a save is already in flight (e.g. the leave save), so wait until every
		-- session has finished both its in-flight and its queued save, or has released its lock.
		local deadline = os.clock() + 25
		while os.clock() < deadline do
			local busy = false
			for _, session in list do
				if session.persistence == "saved" and (session.saving or session.queued or not session.released) then
					busy = true
					break
				end
			end
			if not busy then
				break
			end
			task.wait(0.1)
		end
	end)
end

function PlayerDataService.get(player: Player): Profile?
	local s = sessions[player]
	return if s then s.profile else nil
end

-- Yields until the player's profile has loaded (or they leave / time out).
function PlayerDataService.waitFor(player: Player, timeout: number?): Profile?
	local deadline = os.clock() + (timeout or 60)
	while player.Parent and os.clock() < deadline do
		local p = PlayerDataService.get(player)
		if p then
			return p
		end
		task.wait(0.1)
	end
	return nil
end

function PlayerDataService.persistence(player: Player): Persistence
	local s = sessions[player]
	return if s then s.persistence else "loading"
end

function PlayerDataService.memoryReason(): string
	return memoryReason
end

-- Mutate a profile. Changes are pushed to the client and picked up by the next save.
function PlayerDataService.update(player: Player, fn: (Profile) -> ()): boolean
	local p = PlayerDataService.get(player)
	if not p then
		return false
	end
	fn(p)
	fireDirty(player)
	return true
end

function PlayerDataService.markDirty(player: Player)
	fireDirty(player)
end

function PlayerDataService.onLoaded(cb: (Player, Profile) -> ())
	table.insert(loadedCallbacks, cb)
	for player, s in sessions do
		if s.profile then
			task.spawn(cb, player, s.profile)
		end
	end
end

function PlayerDataService.onDirty(cb: (Player) -> ())
	table.insert(dirtyCallbacks, cb)
end

-- Test helper: force a save now (used by the Studio persistence probe).
function PlayerDataService.saveNow(player: Player)
	saveNow(player, false)
end

return PlayerDataService
