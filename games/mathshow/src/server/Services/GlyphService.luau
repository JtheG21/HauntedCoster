--!strict
-- GlyphService (TASK-0121): the hub's collectable glyphs. Spawns come from the GlyphSpawn-tagged attachments under
-- Workspace.Hub (id = the attachment's parent part). Each player has their own GlyphRules state, in memory only: it
-- starts fresh on join and is dropped on leave. Each collect also adds its rarity value to the profile's lifetime total
-- (ProfileService.addGlyphs, TASK-0138), which the autosave persists. The client asks with GlyphCollect(id); the server checks it against
-- its own clock and the character's HumanoidRootPart and answers only with GlyphState. Rejections are silent to the
-- client; the server warns at most once per reason per player per WARN_WINDOW seconds, for debugging.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GlyphConfig = require(Shared:WaitForChild("GlyphConfig"))
local GlyphRules = require(Shared:WaitForChild("GlyphRules"))
local Net = require(Shared:WaitForChild("Net"))
local RateRules = require(Shared:WaitForChild("RateRules"))

local Remotes = require(script.Parent.Parent.Remotes)
local ProfileService = require(script.Parent.ProfileService)

local WARN_WINDOW = 5
local PROFILE_WAIT_SECONDS = 45 -- longer than ProfileService's rejoin wait (30 s) plus a load
local STUDIO = RunService:IsStudio()

type Entry = {
	state: GlyphRules.PlayerState,
	rawStamps: { number }, -- every GlyphCollect, success or fail (RawRequestLimit per RateWindowSeconds)
	warnStamps: { [string]: { number } },
	pendingLifetime: number, -- collected before the profile was available; added to the total once it is
}

local GlyphService = {}

local started = false
local spawns: { GlyphRules.Spawn } = {}
local entries: { [Player]: Entry } = {}
local stats = { accepted = 0, throttled = 0, collected = 0 }

-- Studio only: counters on this ModuleScript, so a Play-mode check can read them without reaching module state.
local function publishStats()
	if not STUDIO then
		return
	end
	local count = 0
	for _ in entries do
		count += 1
	end
	script:SetAttribute("Players", count)
	script:SetAttribute("Spawns", #spawns)
	script:SetAttribute("RawAccepted", stats.accepted)
	script:SetAttribute("RawThrottled", stats.throttled)
	script:SetAttribute("Collected", stats.collected)
end

local function debugWarn(player: Player, entry: Entry, reason: string, detail: string?)
	local allowed
	entry.warnStamps[reason], allowed = RateRules.allow(entry.warnStamps[reason] or {}, os.clock(), 1, WARN_WINDOW)
	if allowed then
		warn(`[MathShow] GlyphCollect from {player.Name} rejected: {reason}{if detail then ` ({detail})` else ""}`)
	end
end

local function readSpawns(): { GlyphRules.Spawn }
	local hub = Workspace:FindFirstChild("Hub")
	if not hub then
		warn("[MathShow] GlyphService: Workspace.Hub is missing; no glyphs")
		return {}
	end
	local records: { GlyphRules.SpawnRecord } = {}
	for _, tagged in CollectionService:GetTagged("GlyphSpawn") do
		if tagged:IsA("Attachment") and tagged:IsDescendantOf(hub) and tagged.Parent then
			local position = tagged.WorldPosition
			table.insert(records, {
				id = tagged.Parent.Name,
				rarity = tostring(tagged:GetAttribute("Rarity")),
				x = position.X,
				y = position.Y,
				z = position.Z,
			})
		end
	end
	table.sort(records, function(a, b)
		return a.id < b.id
	end)
	local parsed, warnings = GlyphRules.parseSpawns(records)
	for _, message in warnings do
		warn(`[MathShow] GlyphService: spawn dropped, {message}`)
	end
	return parsed
end

local function payload(player: Player, state: GlyphRules.PlayerState): Net.GlyphStatePayload
	local available: { string } = {}
	for _, spawn in spawns do
		local glyph = state.glyphs[spawn.id]
		if glyph and not glyph.collected then
			table.insert(available, spawn.id)
		end
	end
	return { available = available, count = state.sessionCount, lifetime = ProfileService.glyphsLifetime(player) or 0 }
end

local function sendState(player: Player, entry: Entry)
	local ok, err = pcall(function()
		Remotes.GlyphState:FireClient(player, payload(player, entry.state))
	end)
	if not ok then
		warn(`[MathShow] GlyphState to {player.Name} failed: {err}`)
	end
end

local function availableCount(state: GlyphRules.PlayerState): number
	local count = 0
	for _, glyph in state.glyphs do
		if not glyph.collected then
			count += 1
		end
	end
	return count
end

-- Nothing in here yields: the throttle stamp, validation and apply all happen in the same resumption.
local function onCollect(player: Player, raw: unknown)
	local entry = entries[player]
	if not entry then
		return
	end
	local allowed
	entry.rawStamps, allowed =
		RateRules.allow(entry.rawStamps, os.clock(), GlyphConfig.RawRequestLimit, GlyphConfig.RateWindowSeconds)
	if not allowed then
		stats.throttled += 1
		publishStats()
		debugWarn(player, entry, "throttled", `over {GlyphConfig.RawRequestLimit}/{GlyphConfig.RateWindowSeconds}s`)
		return
	end
	stats.accepted += 1
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		publishStats()
		debugWarn(player, entry, "no_character")
		return
	end
	local position = root.Position
	local now = os.clock()
	local ok, reason =
		GlyphRules.validateCollect(entry.state, raw, { x = position.X, y = position.Y, z = position.Z }, now, spawns)
	if not ok then
		publishStats()
		debugWarn(player, entry, reason, if type(raw) == "string" then string.sub(raw, 1, 40) else typeof(raw))
		return
	end
	local glyph = entry.state.glyphs[raw :: string]
	entry.state = GlyphRules.applyCollect(entry.state, raw :: string, now)
	if glyph then
		-- The value comes from the server's own spawn table. While the profile loads it is held back, not lost.
		local value = GlyphConfig.Value[glyph.rarity]
		if ProfileService.addGlyphs(player, value) == nil then
			entry.pendingLifetime += value
		end
	end
	stats.collected += 1
	publishStats()
	sendState(player, entry)
end

local function addPlayer(player: Player)
	if entries[player] then
		return
	end
	local entry: Entry =
		{ state = GlyphRules.newPlayerState(spawns), rawStamps = {}, warnStamps = {}, pendingLifetime = 0 }
	entries[player] = entry
	publishStats()
	sendState(player, entry)
	-- The profile loads after the join (a quick rejoin waits for the last visit's save first, so there may be no session
	-- yet): send the saved total as soon as it is known, or stop waiting when the profile is read-only.
	task.spawn(function()
		local deadline = os.clock() + PROFILE_WAIT_SECONDS
		while
			entries[player] == entry
			and ProfileService.glyphsLifetime(player) == nil
			and ProfileService.persistence(player) ~= "readonly"
			and os.clock() < deadline
		do
			task.wait(0.5)
		end
		if entries[player] == entry then
			if entry.pendingLifetime > 0 and ProfileService.addGlyphs(player, entry.pendingLifetime) ~= nil then
				entry.pendingLifetime = 0
			end
			sendState(player, entry)
		end
	end)
end

-- One loop for every player: O(players x spawns) per tick, and a GlyphState only when a glyph came back.
local function respawnLoop()
	while true do
		task.wait(1)
		local now = os.clock()
		for player, entry in entries do
			local before = availableCount(entry.state)
			local nextState = GlyphRules.tickRespawns(entry.state, now)
			if availableCount(nextState) ~= before then
				entry.state = nextState
				sendState(player, entry)
			end
		end
	end
end

function GlyphService.start(): ()
	if started then
		return
	end
	started = true
	spawns = readSpawns()
	print(`[MathShow] GlyphService: {#spawns} glyph spawns`)
	Remotes.GlyphCollect.OnServerEvent:Connect(function(player: Player, raw: unknown)
		local ok, err = pcall(function()
			onCollect(player, raw)
		end)
		if not ok then
			warn(`[MathShow] GlyphCollect from {player.Name} failed: {err}`)
		end
	end)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player: Player)
		entries[player] = nil
		publishStats()
	end)
	for _, player in Players:GetPlayers() do
		addPlayer(player)
	end
	task.spawn(respawnLoop)
	publishStats()
end

return GlyphService
