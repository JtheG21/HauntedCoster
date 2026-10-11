--!strict
-- Pure telemetry aggregation (TASK-0008) for EXP-0001. The match record holds raw UserIds; the
-- summary replaces them with a per-match index ("P1".."Pn"), so no id or name is ever logged.

local TelemetryRules = {}

export type Stats = { n: number, median: number?, max: number? }

export type MatchRecord = {
	matchIndex: number,
	players: { number }, -- UserIds in match order (anonymised as P1..Pn in this order)
	factions: { [number]: string },
	firstPower: { [number]: number }, -- seconds from join to first power use (onboarding trial)
	trialTimeouts: number, -- trials that ended without using the power
	gateWaits: { number }, -- seconds from the first arrival at a gate to its opening
	gateOpens: number,
	shrineOpens: number,
	echoEarned: { [string]: number },
	echoSpent: { [string]: number },
	courseSeconds: number?,
	finaleSeconds: number?,
	totalSeconds: number?,
	finishers: { number },
	speed: number?,
	teamwork: number?,
	combatWinner: number?,
	combatDraw: { number },
	eliminations: number,
	serverErrors: number,
	rejections: number,
	ended: string, -- "results" (full match) or "empty" (everyone left)
}

local function round(x: number): number
	return math.floor(x * 10 + 0.5) / 10
end

-- Count, median and max of a list. NaN and infinite values are ignored.
function TelemetryRules.summarize(values: { number }): Stats
	local clean = {}
	for _, v in values do
		if v == v and v ~= math.huge and v ~= -math.huge then
			table.insert(clean, v)
		end
	end
	if #clean == 0 then
		return { n = 0, median = nil, max = nil }
	end
	table.sort(clean)
	local mid = #clean // 2
	local median = if #clean % 2 == 1 then clean[mid + 1] else (clean[mid] + clean[mid + 1]) / 2
	return { n = #clean, median = round(median), max = round(clean[#clean]) }
end

-- UserId -> "P<index>" in the given order. Unknown ids get "P?".
function TelemetryRules.anonymize(players: { number }): (id: number?) -> string?
	local labels: { [number]: string } = {}
	for i, id in players do
		labels[id] = `P{i}`
	end
	return function(id: number?): string?
		if id == nil then
			return nil
		end
		return labels[id] or "P?"
	end
end

-- The one-line summary table for a match. Contains no UserIds or names.
function TelemetryRules.buildSummary(m: MatchRecord): { [string]: any }
	local label = TelemetryRules.anonymize(m.players)
	local function tagged(id: number?): string?
		local l = label(id)
		if not l or id == nil then
			return nil
		end
		local faction = m.factions[id]
		return if faction then `{l}:{faction}` else l
	end
	local factionCounts: { [string]: number } = {}
	local firstPower = {}
	for _, id in m.players do
		local faction = m.factions[id]
		if faction then
			factionCounts[faction] = (factionCounts[faction] or 0) + 1
		end
		local seconds = m.firstPower[id]
		if seconds then
			table.insert(firstPower, seconds)
		end
	end
	local draw = {}
	for _, id in m.combatDraw do
		table.insert(draw, tagged(id))
	end
	return {
		v = 1,
		match = m.matchIndex,
		ended = m.ended,
		players = #m.players,
		factions = factionCounts,
		firstPowerS = TelemetryRules.summarize(firstPower),
		trialTimeouts = m.trialTimeouts,
		gateOpens = m.gateOpens,
		gateWaitS = TelemetryRules.summarize(m.gateWaits),
		shrineOpens = m.shrineOpens,
		echoEarned = m.echoEarned,
		echoSpent = m.echoSpent,
		courseS = if m.courseSeconds then round(m.courseSeconds) else nil,
		finaleS = if m.finaleSeconds then round(m.finaleSeconds) else nil,
		totalS = if m.totalSeconds then round(m.totalSeconds) else nil,
		finishers = #m.finishers,
		speed = tagged(m.speed),
		teamwork = tagged(m.teamwork),
		combat = tagged(m.combatWinner),
		combatDraw = if #draw > 0 then draw else nil,
		eliminations = m.eliminations,
		serverErrors = m.serverErrors,
		rejections = m.rejections,
	}
end

return TelemetryRules
