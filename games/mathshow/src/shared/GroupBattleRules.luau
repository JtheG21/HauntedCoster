--!strict
-- Group Battle v2 question rules: 100 for a correct answer, +50 for the first correct one, and a closing countdown
-- that starts at the first correct answer. Pure: no Instances, no clock. The server supplies `acceptedAt` (its own
-- timestamp) and `order` (a unique, increasing acceptance sequence). Ties are resolved by `order`, never by player id.
-- Not wired into live gameplay; the prototype's continuous speed bonus (ScoringRules) is untouched.

local GroupBattleConfig = require(script.Parent.GroupBattleConfig)

export type Submission = { playerId: string, correct: boolean, acceptedAt: number, order: number }
export type QuestionInput = { deadline: number, submissions: { Submission }, closingSeconds: number? }
export type PlayerResult = { points: number, correct: boolean, isFirst: boolean, valid: boolean }
export type QuestionResult = {
	players: { [string]: PlayerResult },
	closingDeadline: number?,
	firstCorrectPlayer: string?,
}
export type RosterEntry = { playerId: string, connected: boolean, eligible: boolean }
export type StandingEntry = { playerId: string, points: number, firstCorrects: number, seat: number }
export type Standing = {
	playerId: string,
	points: number,
	firstCorrects: number,
	seat: number,
	placement: number,
}

local GroupBattleRules = {}

local function finite(n: any): boolean
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge
end

-- A late first-correct never extends a question: the result is never after the original deadline.
function GroupBattleRules.closingDeadline(
	originalDeadline: number,
	firstCorrectAt: number,
	closingSeconds: number
): number
	return math.min(originalDeadline, firstCorrectAt + closingSeconds)
end

-- Results are returned for every player who sent at least one usable submission; the caller owns the roster.
--   * one counted submission per player: the lowest `order`; later ones are ignored;
--   * first correct = lowest `order` among counted correct submissions accepted at or before the original deadline;
--   * with a first correct, the closing deadline applies and any counted submission after it is invalid (0 points);
--   * wrong, missing or late = 0; correct = CorrectPoints, first correct = CorrectPoints + FirstCorrectBonus;
--   * nobody correct: the original deadline stands and there is no closing countdown.
-- `correct` in the result means "scored as correct" (valid and answered correctly).
function GroupBattleRules.resolveQuestion(input: QuestionInput): QuestionResult
	local deadline = input.deadline
	local closingSeconds = input.closingSeconds or GroupBattleConfig.ClosingSeconds

	local counted: { [string]: Submission } = {}
	for _, sub in input.submissions do
		if finite(sub.order) then
			local seen = counted[sub.playerId]
			if seen == nil or sub.order < seen.order then
				counted[sub.playerId] = sub
			end
		end
	end

	local first: Submission? = nil
	for _, sub in counted do
		if sub.correct and finite(sub.acceptedAt) and sub.acceptedAt <= deadline then
			if first == nil or sub.order < first.order then
				first = sub
			end
		end
	end

	local effective = deadline
	local closing: number? = nil
	if first then
		closing = GroupBattleRules.closingDeadline(deadline, first.acceptedAt, closingSeconds)
		effective = closing :: number
	end

	local players: { [string]: PlayerResult } = {}
	for playerId, sub in counted do
		local valid = finite(sub.acceptedAt) and sub.acceptedAt <= effective
		local scored = valid and sub.correct
		local isFirst = first ~= nil and first.playerId == playerId and scored
		local points = 0
		if scored then
			points = GroupBattleConfig.CorrectPoints + (if isFirst then GroupBattleConfig.FirstCorrectBonus else 0)
		end
		players[playerId] = { points = points, correct = scored, isFirst = isFirst, valid = valid }
	end

	return { players = players, closingDeadline = closing, firstCorrectPlayer = if first then first.playerId else nil }
end

-- True when every connected, eligible roster entry has a valid submission (disconnected or ineligible entries do not
-- block). With nobody to wait for it is true, so a question never waits on an empty room.
function GroupBattleRules.allCommitted(roster: { RosterEntry }, submissions: { Submission }): boolean
	local sent: { [string]: boolean } = {}
	for _, sub in submissions do
		sent[sub.playerId] = true
	end
	for _, entry in roster do
		if entry.connected and entry.eligible and not sent[entry.playerId] then
			return false
		end
	end
	return true
end

-- Sorted by points, then first-correct count, then seat (display order only). Placement uses competition ranking
-- (1, 1, 3): entries equal on points and first-correct count share a placement. Player id never breaks a tie.
function GroupBattleRules.standings(entries: { StandingEntry }): { Standing }
	local indexed = {}
	for i, e in entries do
		indexed[i] = { i = i, e = e }
	end
	table.sort(indexed, function(a, b)
		if a.e.points ~= b.e.points then
			return a.e.points > b.e.points
		end
		if a.e.firstCorrects ~= b.e.firstCorrects then
			return a.e.firstCorrects > b.e.firstCorrects
		end
		if a.e.seat ~= b.e.seat then
			return a.e.seat < b.e.seat
		end
		return a.i < b.i
	end)
	local out: { Standing } = {}
	for rank, item in indexed do
		local e = item.e
		local placement = rank
		local prev = out[rank - 1]
		if prev and prev.points == e.points and prev.firstCorrects == e.firstCorrects then
			placement = prev.placement
		end
		out[rank] = {
			playerId = e.playerId,
			points = e.points,
			firstCorrects = e.firstCorrects,
			seat = e.seat,
			placement = placement,
		}
	end
	return out
end

return GroupBattleRules
