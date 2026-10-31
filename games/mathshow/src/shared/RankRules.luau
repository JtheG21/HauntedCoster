--!strict
-- Pure rank rules for the menu (RULES_SPEC). No Instances. Ranks are integers 0..9; anything else is invalid.

local MenuCopy = require(script.Parent.MenuCopy)

export type Tier = { rank: number, key: string, name: string, subject: string, badge: string, pips: number }
export type Mark = "current" | "cleared" | "locked"
export type Kind = "first" | "up" | "held"

local KEYS = { "plastic", "bronze", "silver", "gold", "platinum", "diamond", "demon", "demon", "demon", "demon" } -- rank + 1
local BADGES = { -- rank + 1
	"rank-plastic",
	"rank-bronze",
	"rank-silver",
	"rank-gold",
	"rank-platinum",
	"rank-diamond",
	"rank-demon-1",
	"rank-demon-2",
	"rank-demon-3",
	"rank-demon-4",
}

local TIERS: { [number]: Tier } = {}
for rank = 0, 9 do
	local copy = MenuCopy.Rank[rank]
	TIERS[rank] = table.freeze({
		rank = rank,
		key = KEYS[rank + 1],
		name = copy.Name,
		subject = copy.Subject,
		badge = BADGES[rank + 1],
		pips = math.max(0, rank - 5),
	})
end
table.freeze(TIERS)

local RankRules = {}

local function validRank(rank: any): boolean
	return typeof(rank) == "number" and rank == rank and rank >= 0 and rank <= 9 and rank == math.floor(rank)
end

function RankRules.tierOf(rank: number): Tier?
	if not validRank(rank) then
		return nil
	end
	return TIERS[rank]
end

function RankRules.demonPips(rank: number): number
	if not validRank(rank) then
		return 0
	end
	return TIERS[rank].pips
end

function RankRules.isDemon(rank: number): boolean
	return validRank(rank) and rank >= 6
end

function RankRules.ladderMark(rank: number, best: number?): Mark
	if best == nil or not validRank(best) then
		return "locked"
	end
	if rank == best then
		return "current"
	elseif rank < best then
		return "cleared"
	end
	return "locked"
end

-- `cleared` nil means the first question failed: a first test then lands on PLASTIC ("first", rank 0).
function RankRules.resultKind(previousBest: number?, cleared: number?): Kind
	if previousBest == nil then
		return "first"
	end
	if cleared ~= nil and cleared > previousBest then
		return "up"
	end
	return "held"
end

function RankRules.newBest(previousBest: number?, cleared: number?): number?
	if previousBest == nil then
		return cleared
	elseif cleared == nil then
		return previousBest
	end
	return math.max(previousBest, cleared)
end

export type LadderSlot = { rank: number, column: number, row: number }

-- The 16 ladder: two columns of five rows, higher ranks higher up (column 1 holds ranks 4 down to 0, column 2 holds 9
-- down to 5). Row 1 is the top row.
function RankRules.ladderLayout(): { LadderSlot }
	local slots: { LadderSlot } = {}
	for row = 1, 5 do
		table.insert(slots, { rank = 5 - row, column = 1, row = row })
	end
	for row = 1, 5 do
		table.insert(slots, { rank = 10 - row, column = 2, row = row })
	end
	return slots
end

return RankRules
