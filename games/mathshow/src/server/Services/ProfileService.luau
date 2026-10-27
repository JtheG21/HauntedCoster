--!strict
-- Player profiles for the menu (TASK-0099): settings, best rank, blitz best and the Skill Test clock, stored in one
-- DataStore per player. Adapted from the Haunted Collector PlayerDataService, simplified: no session lock, because every
-- save is an UpdateAsync that MERGES into what is stored (ProfileRules.merge: bests only go up, settings last writer wins),
-- so two servers can never lower a rank or blitz best.
--
-- Safety: every DataStore call is pcall-isolated and never blocks the match loop. A failed load retries, then the profile is
-- "readonly" (nothing written, so an outage can never overwrite real data with defaults). In Studio or an unpublished place,
-- an "API unavailable" error runs the player in "memory" mode (works, not saved). Remotes: MenuRequest (RemoteFunction) and
-- SettingsSave (RemoteEvent); every client value is validated (type, range, rate) and the server never trusts the client.
--
-- Studio-only test hook: set workspace attribute MathShowForceProfileFail = true before a player joins to simulate a load
-- failure (ignored outside Studio).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local Net = require(Shared:WaitForChild("Net"))
local ProfileRules = require(Shared:WaitForChild("ProfileRules"))
local RateRules = require(Shared:WaitForChild("RateRules"))

local Remotes = require(script.Parent.Parent.Remotes)

export type Persistence = "loading" | "saved" | "memory" | "readonly"
type Session = {
	profile: ProfileRules.Profile,
	persistence: Persistence,
	dirty: boolean,
	saving: boolean,
	queued: boolean,
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
local DEVELOPMENT_PLACE = RunService:IsStudio() or game.PlaceId == 0

local started = false
local store: DataStore? = nil
local storeError = "no DataStore" -- why GetDataStore failed, so load() can tell "unpublished place" from a real outage
local sessions: { [Player]: Session } = {}
local releasing: { [number]: Session } = {} -- leave saves still in flight, by userId (a rejoin must wait for them)

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

local function forcedFailure(): boolean
	return RunService:IsStudio() and workspace:GetAttribute("MathShowForceProfileFail") == true
end

local function load(player: Player, session: Session)
	local userId = player.UserId
	local tries = 0
	while player.Parent do
		local ds = getStore()
		local ok, result
		if forcedFailure() then
			ok, result = false, "simulated load failure"
		elseif ds then
			ok, result = pcall(function()
				return ds:GetAsync(keyFor(userId))
			end)
		else
			ok, result = false, storeError
		end
		if ok then
			session.profile = ProfileRules.sanitize(result)
			session.persistence = "saved"
			return
		end
		local message = tostring(result)
		if ProfileRules.loadFailure(message, DEVELOPMENT_PLACE) == "memory" then
			warn(`[MathShow] DataStores unavailable ({message}); {player.Name} runs in memory-only mode`)
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

-- One save in flight per player, at most one queued behind it. Merges into the stored value (see header).
local function saveNow(userId: number, session: Session)
	if session.persistence ~= "saved" or not session.dirty then
		return
	end
	if session.saving then
		session.queued = true
		return
	end
	local ds = getStore()
	if not ds then
		return
	end
	session.saving = true
	session.dirty = false
	local patch = ProfileRules.toPatch(session.profile)
	local ok, result = pcall(function()
		return ds:UpdateAsync(keyFor(userId), function(old: any)
			return ProfileRules.merge(old, patch)
		end)
	end)
	session.saving = false
	if ok then
		-- Adopt what is stored if another server raised a best meanwhile.
		session.profile = ProfileRules.merge(result, ProfileRules.toPatch(session.profile))
	else
		session.dirty = true
		warn(`[MathShow] profile save failed for {userId}: {result}`)
	end
	if session.queued then
		session.queued = false
		saveNow(userId, session)
	end
end

local function scheduleSave(player: Player, session: Session)
	session.token += 1
	local token = session.token
	local userId = player.UserId
	task.delay(SAVE_DEBOUNCE_SECONDS, function()
		if session.token == token then
			saveNow(userId, session)
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
	session.profile = ProfileRules.merge(session.profile, patch)
	if session.persistence == "saved" then
		session.dirty = true
		scheduleSave(player, session)
	end
	return true
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

local function onPlayerAdded(player: Player)
	if sessions[player] then
		return
	end
	-- A quick rejoin must not read the stored value before the previous visit's save has landed.
	local deadline = os.clock() + 30
	while releasing[player.UserId] and os.clock() < deadline and player.Parent do
		task.wait(0.2)
	end
	local session: Session = {
		profile = ProfileRules.defaults(),
		persistence = "loading",
		dirty = false,
		saving = false,
		queued = false,
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
	local userId = player.UserId
	releasing[userId] = session
	task.spawn(function()
		-- A failed leave save is retried a few times: once the session is dropped nothing else would write it.
		for attempt = 1, 4 do
			saveNow(userId, session)
			while session.saving do
				task.wait(0.1)
			end
			if not session.dirty or session.persistence ~= "saved" then
				break
			end
			if attempt < 4 then
				task.wait(2)
			else
				warn(`[MathShow] giving up saving the profile of {userId} after the player left`)
			end
		end
		if sessions[player] == session then
			sessions[player] = nil
		end
		if releasing[userId] == session then
			releasing[userId] = nil
		end
	end)
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
		while true do
			task.wait(AUTOSAVE_SECONDS)
			for player, session in sessions do
				if session.dirty then
					task.spawn(saveNow, player.UserId, session)
				end
			end
		end
	end)
	game:BindToClose(function()
		local deadline = os.clock() + 25
		for player, session in sessions do
			task.spawn(saveNow, player.UserId, session)
		end
		task.wait()
		local pending = true
		while pending and os.clock() < deadline do
			pending = false
			for _, session in sessions do
				if session.saving or session.queued then
					pending = true
				end
			end
			if pending then
				task.wait(0.2)
			end
		end
	end)
end

return ProfileService
