--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local QuestConfig = require(ReplicatedStorage.Shared.QuestConfig)
local QuestRules = require(ReplicatedStorage.Shared.QuestRules)
local XpConfig = require(ReplicatedStorage.Shared.XpConfig)

local V = QuestConfig.CatalogVersion

local function board(userId: number?, day: number?): QuestRules.Board
	local b = QuestRules.boardFor(userId or 1234, day or 20000, V)
	assert(b, "boardFor returned nil")
	return b
end

local function fact(b: QuestRules.Board, slot: number, amount: number?): QuestRules.Fact
	local s = b.slots[slot]
	return {
		day = b.day,
		catalogVersion = b.catalogVersion,
		slotId = s.id,
		generation = s.generation,
		kind = QuestConfig.Catalog[s.id].kind,
		amount = amount or QuestConfig.Catalog[s.id].target,
	}
end

local function completeSlot(b: QuestRules.Board, slot: number): QuestRules.Board
	local out = QuestRules.applyProgress(b, fact(b, slot))
	return out
end

local function claimSlot(b: QuestRules.Board, slot: number): (QuestRules.Board, number)
	return QuestRules.claim(b, b.day, slot, b.boardRevision, b.slots[slot].generation)
end

local function state(b: QuestRules.Board): QuestRules.DailyState
	return { dailyEpoch = b.day, playXpDay = { day = b.day, amount = 10 }, quests = b }
end

return function(t: TestRunner.T)
	t.test("catalog is immutable and complete", function()
		t.eq(QuestConfig.CatalogVersion, 1)
		t.truthy(table.isfrozen(QuestConfig.Catalog), "Catalog frozen")
		t.truthy(table.isfrozen(QuestConfig.Catalog.P_E_ROUND2), "entry frozen")
		local count = 0
		for id, quest in QuestConfig.Catalog do
			count += 1
			t.eq(quest.id, id, "id matches key")
			t.eq(quest.xp, XpConfig.QuestXp[quest.difficulty], `{id} xp`)
		end
		t.eq(count, 15, "fifteen quests")
		t.eq(QuestConfig.Catalog.G_H_RARE2.target, 2)
		t.eq(QuestConfig.Catalog.A_H_80.xp, 200)
	end)

	t.test("boardFor is deterministic", function()
		local a, b = board(77, 19999), board(77, 19999)
		for i = 1, 3 do
			t.eq(a.slots[i].id, b.slots[i].id, `slot {i}`)
		end
		t.eq(a.boardRevision, 1)
		t.eq(a.bonusGranted, false)
		t.eq(a.slots[1].generation, 1)
		t.eq(a.slots[1].progress, 0)
		t.eq(a.slots[1].claimed, false)
	end)

	t.test("1000 boards each hold all three categories and difficulties", function()
		local seen: { [string]: boolean } = {}
		for n = 1, 1000 do
			local b = board(n * 7919, 19000 + n % 400)
			local cats: { [string]: boolean } = {}
			local diffs: { [string]: boolean } = {}
			for _, slot in b.slots do
				local q = QuestConfig.Catalog[slot.id]
				cats[q.category] = true
				diffs[q.difficulty] = true
				seen[slot.id] = true
			end
			t.truthy(cats.play and cats.answers and cats.glyphs, `categories {n}`)
			t.truthy(diffs.easy and diffs.medium and diffs.hard, `difficulties {n}`)
			t.eq(QuestRules.validate(state(b)), "ok", `valid {n}`)
		end
		local distinct = 0
		for _ in seen do
			distinct += 1
		end
		t.truthy(distinct > 10, "selection varies across players and days")
	end)

	t.test("boardFor rejects bad inputs and unknown catalogs", function()
		t.eq(QuestRules.boardFor(1, 5, 2), nil, "unknown catalog")
		t.eq(QuestRules.boardFor(1, -1, V), nil, "negative day")
		t.eq(QuestRules.boardFor(1, 1.5, V), nil, "fractional day")
		t.eq(QuestRules.boardFor(-4, 5, V), nil, "negative userId")
		t.eq(QuestRules.boardFor(0 / 0, 5, V), nil, "NaN userId")
	end)

	t.test("applyProgress caps at the target and never mutates", function()
		local b = board()
		local target = QuestConfig.Catalog[b.slots[1].id].target
		local out, changed = QuestRules.applyProgress(b, fact(b, 1, 1))
		t.eq(changed, true)
		t.eq(out.slots[1].progress, 1)
		t.eq(b.slots[1].progress, 0, "input untouched")
		out, changed = QuestRules.applyProgress(out, fact(b, 1, target * 10))
		t.eq(out.slots[1].progress, target, "capped")
		local _, again = QuestRules.applyProgress(out, fact(b, 1, 1))
		t.eq(again, false, "no change once full")
	end)

	t.test("applyProgress rejects stale or mismatched facts", function()
		local b = board()
		local function rejected(mutate: (f: any) -> (), label: string)
			local f: any = fact(b, 1, 1)
			mutate(f)
			local out, changed = QuestRules.applyProgress(b, f)
			t.eq(changed, false, label)
			t.eq(out.slots[1].progress, 0, label .. " progress")
		end
		rejected(function(f)
			f.generation = 2
		end, "stale generation")
		rejected(function(f)
			f.day += 1
		end, "other day")
		rejected(function(f)
			f.day -= 1
		end, "old day")
		rejected(function(f)
			f.catalogVersion = 2
		end, "other catalog")
		rejected(function(f)
			f.slotId = "NOPE"
		end, "unknown slot")
		rejected(function(f)
			f.kind = f.kind == "glyph" and "correct" or "glyph"
		end, "wrong kind")
		rejected(function(f)
			f.amount = 0
		end, "zero amount")
		rejected(function(f)
			f.amount = -3
		end, "negative amount")
		rejected(function(f)
			f.amount = 1.5
		end, "fractional amount")
	end)

	t.test("claim awards the quest XP once", function()
		local b = completeSlot(board(), 1)
		local xp = QuestConfig.Catalog[b.slots[1].id].xp
		local claimed, awarded = claimSlot(b, 1)
		t.eq(awarded, xp)
		t.eq(claimed.slots[1].claimed, true)
		t.eq(b.slots[1].claimed, false, "input untouched")
		local _, second = claimSlot(claimed, 1)
		t.eq(second, 0, "second claim")
	end)

	t.test("claim refuses incomplete, stale and malformed requests", function()
		local b = board()
		t.eq(select(2, claimSlot(b, 1)), 0, "not complete")
		b = completeSlot(b, 1)
		t.eq(select(2, QuestRules.claim(b, b.day + 1, 1, b.boardRevision, 1)), 0, "wrong day")
		t.eq(select(2, QuestRules.claim(b, b.day, 1, b.boardRevision + 1, 1)), 0, "stale revision")
		t.eq(select(2, QuestRules.claim(b, b.day, 1, b.boardRevision, 2)), 0, "stale generation")
		t.eq(select(2, QuestRules.claim(b, b.day, 0, b.boardRevision, 1)), 0, "slot 0")
		t.eq(select(2, QuestRules.claim(b, b.day, 4, b.boardRevision, 1)), 0, "slot 4")
		t.eq(select(2, QuestRules.claim(b, b.day, 1.5, b.boardRevision, 1)), 0, "fractional slot")
	end)

	t.test("bonus pays once for every completion order", function()
		local orders = { { 1, 2, 3 }, { 1, 3, 2 }, { 2, 1, 3 }, { 2, 3, 1 }, { 3, 1, 2 }, { 3, 2, 1 } }
		for _, order in orders do
			local b = board()
			local total = 0
			for step, slot in order do
				b = completeSlot(b, slot)
				local bonusXp
				b, bonusXp = QuestRules.bonus(b)
				total += bonusXp
				t.eq(bonusXp, step == 3 and XpConfig.AllThreeBonus or 0, `order {table.concat(order)} step {step}`)
			end
			local _, again = QuestRules.bonus(b)
			t.eq(total, XpConfig.AllThreeBonus, "total once")
			t.eq(again, 0, "repeat call")
			t.eq(b.bonusGranted, true)
		end
	end)

	t.test("bonus does not depend on claiming", function()
		local b = board()
		for slot = 1, 3 do
			b = completeSlot(b, slot)
		end
		local claimed = claimSlot(b, 2)
		local _, xp = QuestRules.bonus(claimed)
		t.eq(xp, XpConfig.AllThreeBonus)
		t.eq(select(2, QuestRules.bonus(board())), 0, "nothing complete")
	end)

	t.test("claim and rollover in either order award once", function()
		local b = completeSlot(board(1234, 20000), 1)
		local xp = QuestConfig.Catalog[b.slots[1].id].xp
		-- claim first, then rollover: the slot is already paid
		local claimed, got = claimSlot(b, 1)
		local settled, next1 = QuestRules.rollover(claimed, 20001, 1234)
		t.eq(got + settled, xp, "claim then rollover")
		t.eq(next1.day, 20001)
		-- rollover first, then a claim against the old board identity: refused
		local settled2, next2 = QuestRules.rollover(b, 20001, 1234)
		t.eq(settled2, xp, "rollover settles it")
		local _, late = QuestRules.claim(next2, 20000, 1, b.boardRevision, 1)
		t.eq(late, 0, "late claim")
		t.eq(settled2 + late, xp, "rollover then claim")
	end)

	t.test("rollover settles slots and the bonus exactly once", function()
		local b = board(55, 20000)
		for slot = 1, 3 do
			b = completeSlot(b, slot)
		end
		local expected = XpConfig.AllThreeBonus
		for _, slot in b.slots do
			expected += QuestConfig.Catalog[slot.id].xp
		end
		local xp, fresh = QuestRules.rollover(b, 20001, 55)
		t.eq(xp, expected, "everything unclaimed")
		t.eq(fresh.day, 20001)
		t.eq(fresh.boardRevision, b.boardRevision + 1, "structural change bumps revision")
		t.eq(fresh.bonusGranted, false)
		local again = QuestRules.rollover(b, 20001, 55)
		t.eq(again, xp, "rollover is a pure function of the old board")
		-- a bonus already paid is not paid again
		local paid = QuestRules.bonus(b)
		local xp2 = QuestRules.rollover(paid, 20001, 55)
		t.eq(xp2, expected - XpConfig.AllThreeBonus, "bonus not repeated")
		-- the fresh board settles nothing
		t.eq((QuestRules.rollover(fresh, 20002, 55)), 0, "empty board")
	end)

	t.test("rollover never moves the epoch backwards", function()
		local b = completeSlot(board(1, 20000), 1)
		local xp, same = QuestRules.rollover(b, 20000, 1)
		t.eq(xp, 0, "same day")
		t.eq(same.day, 20000)
		xp, same = QuestRules.rollover(b, 19999, 1)
		t.eq(xp, 0, "earlier day")
		t.eq(same.slots[1].progress, b.slots[1].progress)
		xp = QuestRules.rollover(b, 20000.5, 1)
		t.eq(xp, 0, "fractional day")
	end)

	t.test("validate accepts a good state and rejects mismatched days", function()
		local b = board()
		t.eq(QuestRules.validate(state(b)), "ok")
		local s = state(b)
		s.playXpDay.day += 1
		t.eq(QuestRules.validate(s), "invalid", "playXpDay ahead")
		s = state(b)
		s.dailyEpoch += 1
		t.eq(QuestRules.validate(s), "invalid", "epoch ahead of board")
		s = state(b)
		s.quests.day -= 1
		t.eq(QuestRules.validate(s), "invalid", "board behind epoch")
	end)

	t.test("validate fails closed on unknown catalog and out-of-range values", function()
		local function bad(mutate: (s: any) -> (), label: string)
			local s: any = state(board())
			mutate(s)
			t.eq(QuestRules.validate(s), "invalid", label)
		end
		bad(function(s)
			s.quests.catalogVersion = 2
		end, "unknown catalog")
		bad(function(s)
			s.quests.slots[1].id = "NOPE"
		end, "unknown quest id")
		bad(function(s)
			s.quests.slots[1].progress = 9999
		end, "progress over target")
		bad(function(s)
			s.quests.slots[1].progress = -1
		end, "negative progress")
		bad(function(s)
			s.quests.slots[1].generation = 0
		end, "generation 0")
		bad(function(s)
			s.quests.slots[1].claimed = true
		end, "claimed while incomplete")
		bad(function(s)
			s.quests.bonusGranted = true
		end, "bonus without three complete")
		bad(function(s)
			s.quests.slots[3] = nil
		end, "two slots")
		bad(function(s)
			s.quests.slots[1], s.quests.slots[2] = s.quests.slots[2], s.quests.slots[1]
		end, "categories out of order")
		bad(function(s)
			s.playXpDay.amount = XpConfig.PlayCap + 1
		end, "play amount over cap")
		bad(function(s)
			s.playXpDay.amount = 1.5
		end, "fractional play amount")
		bad(function(s)
			s.quests.boardRevision = 0
		end, "revision 0")
		bad(function(s)
			s.dailyEpoch = 0 / 0
		end, "NaN epoch")
		t.eq(QuestRules.validate(nil :: any), "invalid", "nil")
	end)

	t.test("rules fail inert on an invalid board", function()
		local b: any = board()
		b.catalogVersion = 9
		local _, changed = QuestRules.applyProgress(b, fact(board(), 1, 1))
		t.eq(changed, false, "applyProgress")
		t.eq(select(2, QuestRules.claim(b, b.day, 1, 1, 1)), 0, "claim")
		t.eq(select(2, QuestRules.bonus(b)), 0, "bonus")
		t.eq((QuestRules.rollover(b, b.day + 1, 1)), 0, "rollover")
	end)
end
