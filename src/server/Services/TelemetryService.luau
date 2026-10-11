--!strict
-- Prototype telemetry (TASK-0008) for EXP-0001: one anonymised JSON summary line per match, printed to
-- the server output ("[Telemetry] {...}") and kept in memory for tests. No usernames or UserIds are
-- logged (TelemetryRules replaces them with P1..Pn). Nothing is sent anywhere: AnalyticsService custom
-- events are deliberately not used in the prototype.
--
-- A match record opens when the Course starts and is emitted when the match returns to the Lobby.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScriptContext = game:GetService("ScriptContext")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local FactionConfig = require(Shared:WaitForChild("FactionConfig"))
local TelemetryRules = require(Shared:WaitForChild("TelemetryRules"))

local TelemetryService = {}

export type Sources = {
	getMatchPlayers: () -> { Player },
	getFinishOrder: () -> { Player },
	getOutcome: () -> any, -- FinaleService.getLastOutcome
	getRejections: (player: Player) -> number, -- AbilityService.getRejectionCount
}

local MAX_KEPT = 50

local sources: Sources? = nil
local record: TelemetryRules.MatchRecord? = nil
local inMatch: { [Player]: boolean } = {}
local rejectionBaseline: { [Player]: number } = {}
local reportedTrial: { [Player]: boolean } = {} -- each player's onboarding result is reported once
local courseStartedAt = 0
local finaleStartedAt: number? = nil
local matchCount = 0
local summaries: { string } = {}
local started = false

local function rejectionsSinceStart(): number
	local src = sources
	if not src then
		return 0
	end
	local total = 0
	for player, base in rejectionBaseline do
		total += math.max(0, src.getRejections(player) - base)
	end
	return total
end

local function openRecord()
	local src = sources
	if not src then
		return
	end
	matchCount += 1
	table.clear(inMatch)
	table.clear(rejectionBaseline)
	local players = src.getMatchPlayers()
	local ids, factions, firstPower = {}, {}, {}
	local timeouts = 0
	for _, player in players do
		inMatch[player] = true
		rejectionBaseline[player] = src.getRejections(player)
		table.insert(ids, player.UserId)
		local faction = player:GetAttribute(FactionConfig.AttributeName)
		if typeof(faction) == "string" then
			factions[player.UserId] = faction
		end
		if not reportedTrial[player] then
			local reason = player:GetAttribute("TrialEndReason")
			local seconds = player:GetAttribute("FirstPowerSeconds")
			if reason == "power_used" and typeof(seconds) == "number" then
				firstPower[player.UserId] = seconds
				reportedTrial[player] = true
			elseif reason == "timeout" then
				timeouts += 1
				reportedTrial[player] = true
			end
		end
	end
	courseStartedAt = os.clock()
	finaleStartedAt = nil
	record = {
		matchIndex = matchCount,
		players = ids,
		factions = factions,
		firstPower = firstPower,
		trialTimeouts = timeouts,
		gateWaits = {},
		gateOpens = 0,
		shrineOpens = 0,
		echoEarned = {},
		echoSpent = {},
		courseSeconds = nil,
		finaleSeconds = nil,
		totalSeconds = nil,
		finishers = {},
		speed = nil,
		teamwork = nil,
		combatWinner = nil,
		combatDraw = {},
		eliminations = 0,
		serverErrors = 0,
		rejections = 0,
		ended = "empty",
	}
end

local function emit()
	local r = record
	if not r then
		return
	end
	record = nil
	r.totalSeconds = os.clock() - courseStartedAt
	r.rejections = rejectionsSinceStart()
	local ok, line = pcall(function()
		return HttpService:JSONEncode(TelemetryRules.buildSummary(r))
	end)
	if not ok then
		warn(`[Telemetry] summary failed: {line}`)
		return
	end
	print(`[Telemetry] {line}`)
	table.insert(summaries, line)
	if #summaries > MAX_KEPT then
		table.remove(summaries, 1)
	end
	table.clear(inMatch)
	table.clear(rejectionBaseline)
end

local function onState(state: string)
	local src = sources
	if not src then
		return
	end
	if state == "Course" then
		openRecord()
		return
	end
	local r = record
	if not r then
		return
	end
	if state == "Finale" then
		r.courseSeconds = os.clock() - courseStartedAt
		finaleStartedAt = os.clock()
	elseif state == "Results" then
		local finaleStart = finaleStartedAt
		r.finaleSeconds = if finaleStart then os.clock() - finaleStart else nil
		for _, player in src.getFinishOrder() do
			table.insert(r.finishers, player.UserId)
		end
		local outcome = src.getOutcome()
		if typeof(outcome) == "table" then
			r.speed = outcome.speed
			r.teamwork = outcome.teamwork
			r.combatWinner = outcome.combatWinner
			r.combatDraw = outcome.combatDraw or {}
			r.eliminations = outcome.eliminations or 0
		end
		r.ended = "results"
	elseif state == "Lobby" then
		emit()
	end
end

-- Hook targets (wired in init.server.luau).
function TelemetryService.onMatchState(state: string)
	local ok, err = pcall(function()
		onState(state)
	end)
	if not ok then
		warn(`[Telemetry] state {state}: {err}`)
	end
end

function TelemetryService.onEcho(player: Player, power: string, kind: string)
	local r = record
	if not r or not inMatch[player] then
		return
	end
	local bucket = if kind == "spent" then r.echoSpent else r.echoEarned
	bucket[power] = (bucket[power] or 0) + 1
end

function TelemetryService.onGate(kind: string, waitSeconds: number?)
	local r = record
	if not r then
		return
	end
	if kind == "opened" then
		r.gateOpens += 1
		if waitSeconds then
			table.insert(r.gateWaits, waitSeconds)
		end
	elseif kind == "shrine" then
		r.shrineOpens += 1
	end
end

-- Summaries emitted this server session, oldest first (tests and TEST notes).
function TelemetryService.getSummaries(): { string }
	return table.clone(summaries)
end

function TelemetryService.start(newSources: Sources)
	if started then
		return
	end
	started = true
	sources = newSources
	-- Server script errors during a match (EXP-0001 D: unhandled errors per match).
	ScriptContext.Error:Connect(function()
		local r = record
		if r then
			r.serverErrors += 1
		end
	end)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		inMatch[player] = nil
		reportedTrial[player] = nil
		-- A leaver's rejections aren't counted: AbilityService clears their counter on leave, and
		-- max(0, ...) turns that into zero instead of a negative.
	end)
end

return TelemetryService
