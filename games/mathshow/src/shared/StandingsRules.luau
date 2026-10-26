--!strict
-- Pure Results-screen rules (TASK-0094). No Instances, no services. Nothing here throws on bad input.
-- Ordering matches RoundService.scores(): points descending, then userId ascending. Ties share a rank (1, 1, 3).

local HudCopy = require(script.Parent.HudCopy)
local Net = require(script.Parent.Net)
local StandingsConfig = require(script.Parent.StandingsConfig)

export type Row = { rank: number, userId: number, name: string, points: number, isYou: boolean }
export type Model = {
	empty: boolean,
	podium: { Row },
	others: { Row },
	you: Row?, -- the local player's row, only when it is outside podium and others
	hiddenCount: number, -- rows beyond podium and others, not counting `you`
}

local ELLIPSIS = "\u{2026}"

local StandingsRules = {}

local function isFinite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

local function isInteger(value: any): boolean
	return isFinite(value) and value == math.floor(value)
end

function StandingsRules.isValidScores(scores: any): boolean
	if typeof(scores) ~= "table" then
		return false
	end
	local count = 0
	for key in scores do
		if typeof(key) ~= "number" then
			return false
		end
		count += 1
	end
	if count ~= #scores then
		return false -- hole, or non-sequence keys
	end
	local seen: { [number]: boolean } = {}
	for index = 1, count do
		local entry = scores[index]
		if typeof(entry) ~= "table" then
			return false
		end
		if not isInteger(entry.userId) or seen[entry.userId] then
			return false
		end
		seen[entry.userId] = true
		if typeof(entry.name) ~= "string" then
			return false
		end
		if not isFinite(entry.points) or entry.points < 0 or entry.points ~= math.floor(entry.points) then
			return false
		end
	end
	return true
end

function StandingsRules.cleanPoints(points: any): number
	if not isFinite(points) or points < 0 then
		return 0
	end
	return math.min(math.floor(points), StandingsConfig.MaxPoints)
end

function StandingsRules.displayName(name: any): string
	if typeof(name) ~= "string" or name == "" then
		return "?"
	end
	local length = utf8.len(name)
	if length == nil then
		return "?" -- not valid UTF-8
	end
	local max = StandingsConfig.MaxNameChars
	if length <= max then
		return name
	end
	local cut = utf8.offset(name, max) -- byte where character `max` starts, so keep max - 1 characters
	if cut == nil then
		return "?"
	end
	return name:sub(1, cut - 1) .. ELLIPSIS
end

-- The points a player has in a scores list; 0 when the list is malformed or does not hold them.
function StandingsRules.scoreFor(scores: any, userId: any): number
	if not StandingsRules.isValidScores(scores) then
		return 0
	end
	for _, entry in scores :: { Net.ScoreEntry } do
		if entry.userId == userId then
			return StandingsRules.cleanPoints(entry.points)
		end
	end
	return 0
end

-- 1102 -> "1,102".
function StandingsRules.formatNumber(value: any): string
	local text = tostring(StandingsRules.cleanPoints(value))
	local formatted = text:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^,", ""))
end

-- "1,102 PTS".
function StandingsRules.pointsLabel(points: any): string
	return HudCopy.Points:format(StandingsRules.formatNumber(points))
end

-- "+3 MORE" for the rows beyond the list; "" when there are none.
function StandingsRules.moreLabel(hiddenCount: any): string
	if not isFinite(hiddenCount) or hiddenCount <= 0 then
		return ""
	end
	return HudCopy.More:format(hiddenCount)
end

-- First-place tag: "TIED FOR FIRST" when second place shares rank 1, else "TOP SCORE".
function StandingsRules.topTag(model: Model): string
	local second = model.podium[2]
	return if second ~= nil and second.rank == 1 then HudCopy.TiedFirst else HudCopy.TopScore
end

-- The message card text for an empty board; nil when there are rows to show.
function StandingsRules.emptyMessage(model: Model): string?
	return if model.empty then HudCopy.NoScores else nil
end

function StandingsRules.build(scores: any, localUserId: any): Model
	local model: Model = { empty = true, podium = {}, others = {}, you = nil, hiddenCount = 0 }
	if not StandingsRules.isValidScores(scores) or #scores == 0 then
		return model
	end
	model.empty = false

	local sorted: { Net.ScoreEntry } = {}
	for _, entry in scores :: { Net.ScoreEntry } do
		table.insert(sorted, entry)
	end
	table.sort(sorted, function(a, b)
		local pa, pb = StandingsRules.cleanPoints(a.points), StandingsRules.cleanPoints(b.points)
		if pa ~= pb then
			return pa > pb
		end
		return a.userId < b.userId
	end)

	local rows: { Row } = {}
	local rank, previous = 0, nil :: number?
	for index, entry in sorted do
		local points = StandingsRules.cleanPoints(entry.points)
		if points ~= previous then
			rank = index
			previous = points
		end
		table.insert(rows, {
			rank = rank,
			userId = entry.userId,
			name = StandingsRules.displayName(entry.name),
			points = points,
			isYou = entry.userId == localUserId,
		})
	end

	local podiumEnd = StandingsConfig.PodiumSize
	local listEnd = podiumEnd + StandingsConfig.ListRows
	for index, row in rows do
		if index <= podiumEnd then
			table.insert(model.podium, row)
		elseif index <= listEnd then
			table.insert(model.others, row)
		else
			if row.isYou then
				model.you = row
			else
				model.hiddenCount += 1
			end
		end
	end
	return model
end

return table.freeze(StandingsRules)
