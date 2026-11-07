--!strict
-- Pure daily-quest rules: board selection, progress, claim, all-three bonus, rollover and fail-closed validation.
-- No Instances, no services, no clock, no Random: the day and the userId arrive as arguments and selection is a pure
-- integer hash. Every function returns fresh tables and never mutates its input. Nothing throws on bad input.

local QuestConfig = require(script.Parent.QuestConfig)
local XpConfig = require(script.Parent.XpConfig)

export type Slot = { id: string, generation: number, progress: number, claimed: boolean }
export type Board = {
	day: number,
	catalogVersion: number,
	boardRevision: number, -- structural changes only (a new board); progress and claims do not bump it
	slots: { Slot },
	bonusGranted: boolean,
}
export type Fact = {
	day: number,
	catalogVersion: number,
	slotId: string,
	generation: number,
	kind: QuestConfig.Kind,
	amount: number,
}
export type Validity = "ok" | "invalid"
-- The stored daily state as a whole: one authoritative epoch that every day field must equal.
export type DailyState = { dailyEpoch: number, playXpDay: { day: number, amount: number }, quests: Board }

local QuestRules = {}

local MOD = 4294967296
-- The six ways to give the three categories one distinct difficulty each (index into QuestConfig.Difficulties).
local PERMUTATIONS: { { number } } = {
	{ 1, 2, 3 },
	{ 1, 3, 2 },
	{ 2, 1, 3 },
	{ 2, 3, 1 },
	{ 3, 1, 2 },
	{ 3, 2, 1 },
}

local function isInt(v: any): boolean
	return typeof(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge and v == math.floor(v)
end

-- Folds one non-negative integer into the hash state. Products stay below 2^53, so the arithmetic is exact.
local function mix(h: number, x: number): number
	local lo = x % MOD
	local hi = math.floor(x / MOD) % MOD
	for _, part in { lo, hi } do
		h = bit32.bxor(h, part)
		h = (h * 65599 + 40503) % MOD
		h = bit32.bxor(h, bit32.rshift(h, 15))
	end
	return h
end

local function hashOf(userId: number, day: number, catalogVersion: number, salt: number): number
	local h = 2166136261
	h = mix(h, userId)
	h = mix(h, day)
	h = mix(h, catalogVersion)
	h = mix(h, salt)
	return h
end

local function copyBoard(board: Board): Board
	local slots: { Slot } = {}
	for i, s in board.slots do
		slots[i] = { id = s.id, generation = s.generation, progress = s.progress, claimed = s.claimed }
	end
	return {
		day = board.day,
		catalogVersion = board.catalogVersion,
		boardRevision = board.boardRevision,
		slots = slots,
		bonusGranted = board.bonusGranted,
	}
end

-- The deterministic board for this player and day, or nil for an invalid userId/day or an unknown catalog version.
-- Every day has one quest per category and one per difficulty.
function QuestRules.boardFor(userId: number, day: number, catalogVersion: number): Board?
	if not isInt(userId) or userId < 0 or not isInt(day) or day < 0 or catalogVersion ~= QuestConfig.CatalogVersion then
		return nil
	end
	local perm = PERMUTATIONS[hashOf(userId, day, catalogVersion, 0) % #PERMUTATIONS + 1]
	local slots: { Slot } = {}
	for c, category in QuestConfig.Categories do
		local difficulty = QuestConfig.Difficulties[perm[c]]
		local cell = QuestConfig.Cells[category][difficulty]
		local id = cell[hashOf(userId, day, catalogVersion, c) % #cell + 1]
		slots[c] = { id = id, generation = 1, progress = 0, claimed = false }
	end
	return { day = day, catalogVersion = catalogVersion, boardRevision = 1, slots = slots, bonusGranted = false }
end

local function validSlot(slot: any, category: string): boolean
	if typeof(slot) ~= "table" or typeof(slot.id) ~= "string" then
		return false
	end
	local quest = QuestConfig.Catalog[slot.id]
	if quest == nil or quest.category ~= category then
		return false
	end
	if not isInt(slot.generation) or slot.generation < 1 then
		return false
	end
	if not isInt(slot.progress) or slot.progress < 0 or slot.progress > quest.target then
		return false
	end
	if typeof(slot.claimed) ~= "boolean" then
		return false
	end
	-- a claimed slot must be complete; a bonus without three complete slots is handled at board level
	return not slot.claimed or slot.progress == quest.target
end

local function complete(slot: Slot): boolean
	local quest = QuestConfig.Catalog[slot.id]
	return quest ~= nil and slot.progress >= quest.target
end

local function allComplete(board: Board): boolean
	for _, slot in board.slots do
		if not complete(slot) then
			return false
		end
	end
	return true
end

local function boardValid(board: any): boolean
	if typeof(board) ~= "table" or board.catalogVersion ~= QuestConfig.CatalogVersion then
		return false
	end
	if not isInt(board.day) or board.day < 0 or not isInt(board.boardRevision) or board.boardRevision < 1 then
		return false
	end
	if typeof(board.bonusGranted) ~= "boolean" or typeof(board.slots) ~= "table" then
		return false
	end
	if #board.slots ~= QuestConfig.SlotCount then
		return false
	end
	for c, category in QuestConfig.Categories do
		if not validSlot(board.slots[c], category) then
			return false
		end
	end
	return not board.bonusGranted or allComplete(board)
end

-- Fail closed: "invalid" for an unknown catalog version, mismatched day fields or out-of-range values. `stored` is the
-- whole daily state; quests.day and playXpDay.day must both equal dailyEpoch.
function QuestRules.validate(stored: DailyState): Validity
	if typeof(stored) ~= "table" or not isInt(stored.dailyEpoch) or stored.dailyEpoch < 0 then
		return "invalid"
	end
	local play = stored.playXpDay
	if typeof(play) ~= "table" or play.day ~= stored.dailyEpoch then
		return "invalid"
	end
	if not isInt(play.amount) or play.amount < 0 or play.amount > XpConfig.PlayCap then
		return "invalid"
	end
	if not boardValid(stored.quests) or stored.quests.day ~= stored.dailyEpoch then
		return "invalid"
	end
	return "ok"
end

-- Applies one progress fact. Matches only on day, catalogVersion, slot id, generation and kind; caps at the target.
-- Returns the new board and whether anything changed. The input board is never mutated.
function QuestRules.applyProgress(board: Board, fact: Fact): (Board, boolean)
	if not boardValid(board) or typeof(fact) ~= "table" then
		return board, false
	end
	if fact.day ~= board.day or fact.catalogVersion ~= board.catalogVersion then
		return board, false
	end
	if not isInt(fact.amount) or fact.amount <= 0 or not isInt(fact.generation) then
		return board, false
	end
	for i, slot in board.slots do
		if slot.id == fact.slotId then
			local quest = QuestConfig.Catalog[slot.id]
			if slot.generation ~= fact.generation or quest.kind ~= fact.kind then
				return board, false
			end
			local progress = math.min(quest.target, slot.progress + fact.amount)
			if progress == slot.progress then
				return board, false
			end
			local out = copyBoard(board)
			out.slots[i].progress = progress
			return out, true
		end
	end
	return board, false
end

-- Claims one completed, unclaimed slot of the matching day, board revision and generation. Returns the new board and the
-- XP awarded; 0 (and the same board) when incomplete, already claimed, stale or invalid.
function QuestRules.claim(
	board: Board,
	day: number,
	slot: number,
	expectedBoardRevision: number,
	generation: number
): (Board, number)
	if not boardValid(board) or day ~= board.day or expectedBoardRevision ~= board.boardRevision then
		return board, 0
	end
	if not isInt(slot) or slot < 1 or slot > QuestConfig.SlotCount then
		return board, 0
	end
	local target = board.slots[slot]
	if target.generation ~= generation or target.claimed or not complete(target) then
		return board, 0
	end
	local out = copyBoard(board)
	out.slots[slot].claimed = true
	return out, QuestConfig.Catalog[target.id].xp
end

-- Grants the all-three bonus once, as soon as all three slots are complete (claim order does not matter).
function QuestRules.bonus(board: Board): (Board, number)
	if not boardValid(board) or board.bonusGranted or not allComplete(board) then
		return board, 0
	end
	local out = copyBoard(board)
	out.bonusGranted = true
	return out, XpConfig.AllThreeBonus
end

-- Closes `board` and opens `newDay`: settles every complete-but-unclaimed slot and an eligible bonus exactly once, and
-- returns (xpToGrant, freshBoard). The fresh board is the deterministic board for `userId` with the next board revision.
-- An invalid board, an invalid day or a day that is not strictly later changes nothing (epochs never go backwards).
function QuestRules.rollover(board: Board, newDay: number, userId: number): (number, Board)
	if not boardValid(board) or not isInt(newDay) or newDay <= board.day then
		return 0, board
	end
	local fresh = QuestRules.boardFor(userId, newDay, board.catalogVersion)
	if fresh == nil then
		return 0, board
	end
	local xp = 0
	for _, slot in board.slots do
		if complete(slot) and not slot.claimed then
			xp += QuestConfig.Catalog[slot.id].xp
		end
	end
	if allComplete(board) and not board.bonusGranted then
		xp += XpConfig.AllThreeBonus
	end
	fresh.boardRevision = board.boardRevision + 1
	return xp, fresh
end

return QuestRules
