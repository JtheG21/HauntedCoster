--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuConfig = require(ReplicatedStorage.Shared.MenuConfig)
local ProfileRules = require(ReplicatedStorage.Shared.ProfileRules)
local QuestConfig = require(ReplicatedStorage.Shared.QuestConfig)
local QuestRules = require(ReplicatedStorage.Shared.QuestRules)
local XpConfig = require(ReplicatedStorage.Shared.XpConfig)

local NAN = 0 / 0

local NOW = 1_800_000_000
local WEEK = 604800

local function valid(): { [string]: any }
	return { music = 3, sfx = 4, reducedMotion = true, colorBlind = false, haptics = true }
end

local WINDOW = 900
local SKEW = 300

-- An op taken at NOW (wall) and 0 (monotonic); `settingsPatch` (default: none) are the settings keys it changed.
local function op(sessionId: string, seq: number, delta: number, settingsPatch: { [string]: any }?): ProfileRules.SaveOp
	return {
		sessionId = sessionId,
		seq = seq,
		glyphsDelta = delta,
		createdAt = 0,
		createdAtWall = NOW,
		settingsPatch = settingsPatch or {},
	}
end

-- A callback context: inside the window, not ambiguous, at NOW, unless overridden.
local function ctx(overrides: { [string]: any }?): ProfileRules.SaveContext
	local c: { [string]: any } = { nowWall = NOW, elapsed = 10, ambiguous = false }
	if overrides then
		for key, value in overrides do
			c[key] = value
		end
	end
	return c :: any
end

local function plan(stored: any, saveOp: ProfileRules.SaveOp, overrides: { [string]: any }?): ProfileRules.SavePlan
	return ProfileRules.planSave(stored, saveOp, ctx(overrides))
end

-- planSave's write, failing the test unless the op was applied.
local function save(t: TestRunner.T, stored: any, saveOp: ProfileRules.SaveOp, patch: ProfileRules.Patch?): any
	local decided = plan(stored, saveOp, { patch = patch })
	t.eq(decided.tag, "applied")
	t.truthy(decided.write ~= nil, "an applied plan writes")
	return decided.write
end

local function count(log: any): number
	local n = 0
	for _ in log do
		n += 1
	end
	return n
end

-- 200 receipts of other sessions o1..o200, o1 the oldest: o_i at `newest - (200 - i)`.
local function fullLog(newest: number): { [string]: any }
	local log = {}
	for i = 1, 200 do
		log["o" .. i] = { seq = 1, at = newest - (200 - i) }
	end
	return log
end

return function(t: TestRunner.T)
	t.test("defaults follow MenuConfig and are fresh tables", function()
		local a, b = ProfileRules.defaults(), ProfileRules.defaults()
		t.eq(a.settings.music, MenuConfig.SettingsDefaults.music)
		t.eq(a.bestRank, nil)
		t.truthy(a.settings ~= b.settings, "no shared table")
	end)

	t.test("sanitizeSettings accepts a full valid table and returns a copy", function()
		local input = valid()
		local out = ProfileRules.sanitizeSettings(input) :: ProfileRules.Settings
		t.eq(out.music, 3)
		t.eq(out.reducedMotion, true)
		t.truthy((out :: any) ~= input)
	end)

	t.test("sanitizeSettings accepts the range ends", function()
		local low = valid()
		low.music, low.sfx = 0, 10
		t.truthy(ProfileRules.sanitizeSettings(low))
	end)

	t.test("sanitizeSettings rejects non-tables, missing and extra keys", function()
		t.eq(ProfileRules.sanitizeSettings(nil), nil)
		t.eq(ProfileRules.sanitizeSettings("x"), nil)
		t.eq(ProfileRules.sanitizeSettings({}), nil)
		local missing = valid()
		missing.haptics = nil
		t.eq(ProfileRules.sanitizeSettings(missing), nil)
		local extra = valid()
		extra.admin = true
		t.eq(ProfileRules.sanitizeSettings(extra), nil)
	end)

	t.test("sanitizeSettings rejects out-of-range, fractional, NaN and wrong types", function()
		local bads: { any } = { -1, 11, 2.5, NAN, math.huge, "5", true }
		for _, bad in bads do
			local s = valid()
			s.music = bad
			t.eq(ProfileRules.sanitizeSettings(s), nil, "music " .. tostring(bad))
		end
		local s = valid()
		s.colorBlind = 1
		t.eq(ProfileRules.sanitizeSettings(s), nil)
	end)

	t.test("sanitize keeps valid stored data and drops garbage", function()
		local p = ProfileRules.sanitize({
			settings = { music = 9, sfx = 99, reducedMotion = "yes", colorBlind = true, haptics = false },
			bestRank = 4,
			lastTestRank = 12,
			lastTakenAt = 1000,
			blitzBest = 7,
		})
		t.eq(p.settings.music, 9)
		t.eq(p.settings.sfx, MenuConfig.SettingsDefaults.sfx, "bad field falls back")
		t.eq(p.settings.reducedMotion, MenuConfig.SettingsDefaults.reducedMotion)
		t.eq(p.settings.colorBlind, true)
		t.eq(p.bestRank, 4)
		t.eq(p.lastTestRank, nil)
		t.eq(p.lastTakenAt, 1000)
		t.eq(p.blitzBest, 7)
	end)

	t.test("sanitize handles non-tables and bad ranks", function()
		t.eq(ProfileRules.sanitize(nil).bestRank, nil)
		t.eq(ProfileRules.sanitize("x").settings.music, MenuConfig.SettingsDefaults.music)
		local badRanks: { any } = { -1, 10, 3.5, NAN, "3" }
		for _, bad in badRanks do
			t.eq(ProfileRules.sanitize({ bestRank = bad }).bestRank, nil, tostring(bad))
		end
		t.eq(ProfileRules.sanitize({ blitzBest = MenuConfig.BlitzTotal + 1 }).blitzBest, nil)
		t.eq(ProfileRules.sanitize({ lastTakenAt = -1 }).lastTakenAt, nil)
		t.eq(ProfileRules.sanitize({ lastTakenAt = math.huge }).lastTakenAt, nil)
	end)

	t.test("merge: bests only go up", function()
		local stored = { bestRank = 5, blitzBest = 8 }
		local lower = ProfileRules.merge(stored, { bestRank = 2, blitzBest = 3 })
		t.eq(lower.bestRank, 5)
		t.eq(lower.blitzBest, 8)
		local higher = ProfileRules.merge(stored, { bestRank = 6, blitzBest = 9 })
		t.eq(higher.bestRank, 6)
		t.eq(higher.blitzBest, 9)
		t.eq(ProfileRules.merge(nil, { bestRank = 0 }).bestRank, 0, "rank 0 is a real rank")
	end)

	t.test("merge: settings are last writer wins, invalid settings are ignored", function()
		local stored = { settings = valid() }
		local newer = valid()
		newer.music = 10
		t.eq(ProfileRules.merge(stored, { settings = newer :: any }).settings.music, 10)
		local bad = valid()
		bad.music = 99
		t.eq(ProfileRules.merge(stored, { settings = bad :: any }).settings.music, 3)
	end)

	t.test("merge: the last test follows the newest start time", function()
		local stored = { lastTakenAt = 500, lastTestRank = 2 }
		local older = ProfileRules.merge(stored, { lastTakenAt = 400, lastTestRank = 7 })
		t.eq(older.lastTakenAt, 500)
		t.eq(older.lastTestRank, 2)
		local newer = ProfileRules.merge(stored, { lastTakenAt = 600, lastTestRank = 1 })
		t.eq(newer.lastTakenAt, 600)
		t.eq(newer.lastTestRank, 1)
		local same = ProfileRules.merge(stored, { lastTakenAt = 500, lastTestRank = 3 })
		t.eq(same.lastTestRank, 3, "equal time takes the patch")
	end)

	t.test("merge: an equal time without a rank keeps the stored rank", function()
		local stored = { lastTakenAt = 500, lastTestRank = 2 }
		local merged = ProfileRules.merge(stored, { lastTakenAt = 500 })
		t.eq(merged.lastTestRank, 2)
		t.eq(ProfileRules.merge(stored, { lastTestRank = 9 }).lastTestRank, 2, "a rank without a time is ignored")
		t.eq(ProfileRules.merge(nil, { lastTakenAt = 10, lastTestRank = 0 }).lastTestRank, 0, "rank 0 is real")
	end)

	t.test("merge of a stored profile with its own patch is stable", function()
		local p = ProfileRules.sanitize({
			bestRank = 3,
			blitzBest = 4,
			lastTakenAt = 10,
			lastTestRank = 2,
			settings = valid(),
		})
		local again = ProfileRules.merge(p, ProfileRules.toPatch(p))
		t.eq(again.bestRank, 3)
		t.eq(again.blitzBest, 4)
		t.eq(again.lastTestRank, 2)
		t.eq(again.settings.sfx, 4)
	end)

	t.test("retryAt and toClient", function()
		t.eq(ProfileRules.retryAt(nil, 300), nil)
		t.eq(ProfileRules.retryAt(1000, 300), 1300)
		t.eq(ProfileRules.retryAt(1000, nil), 1000 + MenuConfig.RetakeCooldownSeconds)
		t.eq(ProfileRules.retryAt(NAN, 300), nil)
		local profile = ProfileRules.sanitize({ bestRank = 6, lastTakenAt = 100, lastTestRank = 5 })
		local client = ProfileRules.toClient(profile, "saved")
		t.eq(client.rank, 6)
		t.eq(client.retryAt, 100 + MenuConfig.RetakeCooldownSeconds)
		t.eq(client.persistence, "saved")
		t.eq(client.modes.group, true)
		t.eq(client.modes.vs, true)
		t.eq(client.modes.blitz, true)
		client.settings.music = 0
		t.eq(profile.settings.music, MenuConfig.SettingsDefaults.music, "the client copy is detached")
	end)

	t.test("loadFailure: memory only in a development place", function()
		t.eq(ProfileRules.loadFailure("Studio access to APIs is not allowed", true), "memory")
		t.eq(ProfileRules.loadFailure("Studio access to APIs is not allowed", false), "retry")
		t.eq(ProfileRules.loadFailure("403 Forbidden", true), "memory")
		t.eq(ProfileRules.loadFailure("502 Bad Gateway", true), "retry")
		t.eq(ProfileRules.loadFailure("", true), "retry")
	end)

	t.test("migrate adds glyphsLifetime = 0 to an old profile and raises the version", function()
		local old: { [string]: any } = { version = 1, settings = valid(), bestRank = 3 }
		local out = ProfileRules.migrate(old)
		t.eq(out.glyphsLifetime, 0)
		t.eq(out.version, ProfileRules.defaults().version)
		t.eq(out.bestRank, 3)
		t.eq(out.settings.music, 3)
		t.eq(old.glyphsLifetime, nil, "the input is not mutated")
		t.eq(old.version, 1)
	end)

	t.test("migrate treats a missing or garbage version as the oldest", function()
		t.eq(ProfileRules.migrate({}).version, ProfileRules.defaults().version)
		t.eq(ProfileRules.migrate({ version = "x" }).version, ProfileRules.defaults().version)
		t.eq(ProfileRules.migrate({ version = NAN }).version, ProfileRules.defaults().version)
		t.eq(ProfileRules.migrate({ version = -4 }).glyphsLifetime, 0)
	end)

	t.test("migrate keeps a valid total and is idempotent", function()
		local once = ProfileRules.migrate({ version = 2, glyphsLifetime = 41 })
		t.eq(once.glyphsLifetime, 41)
		local twice = ProfileRules.migrate(once)
		t.eq(twice.glyphsLifetime, 41)
		t.eq(twice.version, once.version)
		local fresh = ProfileRules.migrate({ version = 1 })
		t.eq(ProfileRules.migrate(fresh).glyphsLifetime, 0)
	end)

	t.test("migrate cleans non-finite, negative and fractional totals", function()
		t.eq(ProfileRules.migrate({ glyphsLifetime = NAN }).glyphsLifetime, 0)
		t.eq(ProfileRules.migrate({ glyphsLifetime = math.huge }).glyphsLifetime, 0)
		t.eq(ProfileRules.migrate({ glyphsLifetime = -math.huge }).glyphsLifetime, 0)
		t.eq(ProfileRules.migrate({ glyphsLifetime = -3 }).glyphsLifetime, 0)
		t.eq(ProfileRules.migrate({ glyphsLifetime = 1.5 }).glyphsLifetime, 1)
		t.eq(ProfileRules.migrate({ glyphsLifetime = "9" }).glyphsLifetime, 0)
	end)

	t.test("migrate preserves unknown fields", function()
		local out = ProfileRules.migrate({ version = 1, legacy = { a = 1 }, flag = true })
		t.eq(out.flag, true)
		t.eq(out.legacy.a, 1)
	end)

	t.test("migrate leaves a future version alone", function()
		local future = { version = 99, glyphsLifetime = -5, extra = "x" }
		local out = ProfileRules.migrate(future)
		t.eq(out.version, 99)
		t.eq(out.glyphsLifetime, -5, "not rewritten")
		t.eq(out.extra, "x")
		t.eq(ProfileRules.migrate("not a table"), "not a table")
	end)

	t.test("isNewerVersion flags only a higher numeric version", function()
		t.eq(ProfileRules.isNewerVersion({ version = 99 }), true)
		t.eq(ProfileRules.isNewerVersion({ version = ProfileRules.defaults().version }), false)
		t.eq(ProfileRules.isNewerVersion({ version = 1 }), false)
		t.eq(ProfileRules.isNewerVersion({ version = NAN }), false)
		t.eq(ProfileRules.isNewerVersion({ version = "99" }), false)
		t.eq(ProfileRules.isNewerVersion(nil), false)
		t.eq(ProfileRules.isNewerVersion({}), false)
	end)

	t.test("sanitize keeps the total and a newer version, and never downgrades", function()
		local p = ProfileRules.sanitize({ version = 99, glyphsLifetime = 12 })
		t.eq(p.glyphsLifetime, 12)
		t.eq(p.version, 99)
		t.eq(ProfileRules.sanitize({ version = 1 }).glyphsLifetime, 0)
		t.eq(ProfileRules.sanitize(nil).glyphsLifetime, 0)
	end)

	t.test("addGlyphs adds a valid amount without mutating", function()
		local profile = ProfileRules.defaults()
		local out = ProfileRules.addGlyphs(profile, 5)
		t.eq(out.glyphsLifetime, 5)
		t.eq(profile.glyphsLifetime, 0, "the input is not mutated")
		t.eq(ProfileRules.addGlyphs(out, 1).glyphsLifetime, 6)
	end)

	t.test("addGlyphs ignores invalid amounts", function()
		local profile = ProfileRules.addGlyphs(ProfileRules.defaults(), 7)
		for _, bad in { 0, -1, 1.5, NAN, math.huge, -math.huge } do
			t.eq(ProfileRules.addGlyphs(profile, bad).glyphsLifetime, 7)
		end
		t.eq(ProfileRules.addGlyphs(profile, "3" :: any).glyphsLifetime, 7)
		t.eq(ProfileRules.addGlyphs(profile, nil :: any).glyphsLifetime, 7)
	end)

	t.test("merge adds the glyph delta to the stored total and never lowers it", function()
		t.eq(ProfileRules.merge({ version = 2, glyphsLifetime = 30 }, { glyphsDelta = 10 }).glyphsLifetime, 40)
		t.eq(ProfileRules.merge({ glyphsLifetime = 4 }, {}).glyphsLifetime, 4)
		for _, bad in { -3, 0, NAN, math.huge, 1.5 :: number } do
			local expected = if bad == 1.5 then 5 else 4
			t.eq(ProfileRules.merge({ glyphsLifetime = 4 }, { glyphsDelta = bad }).glyphsLifetime, expected)
		end
		t.eq(ProfileRules.merge({ glyphsLifetime = 4 }, { glyphsDelta = "3" :: any }).glyphsLifetime, 4)
		t.eq(ProfileRules.toPatch(ProfileRules.addGlyphs(ProfileRules.defaults(), 2)).glyphsDelta, nil)
	end)

	t.test("two sessions that overlap lose no glyph, in both orders (AUD-02 F2)", function()
		-- Both load total 10; A collects a common (+1), B a rare (+5).
		local stored: any = { version = 2, glyphsLifetime = 10 }
		stored = save(t, stored, op("A", 1, 1))
		stored = save(t, stored, op("B", 1, 5))
		t.eq(stored.glyphsLifetime, 16)
		local reversed: any = { version = 2, glyphsLifetime = 10 }
		reversed = save(t, reversed, op("B", 1, 5))
		reversed = save(t, reversed, op("A", 1, 1))
		t.eq(reversed.glyphsLifetime, 16)
		t.eq(reversed.applied.A.seq, 1)
		t.eq(reversed.applied.B.seq, 1)
	end)

	t.test("a repeated UpdateAsync callback credits one op once", function()
		local saveOp = op("S", 1, 5)
		local old: any = { version = 3, glyphsLifetime = 10, applied = {} }
		local first = save(t, old, saveOp)
		local again = save(t, old, saveOp) -- the same stored value: the same result, no second credit
		t.eq(first.glyphsLifetime, 15)
		t.eq(again.glyphsLifetime, 15)
		t.eq(old.glyphsLifetime, 10, "the stored table is not mutated")
		t.eq(next(old.applied), nil, "the stored log is not mutated")
		-- The engine replays the callback against a fresher value another server wrote: still +5 once.
		local fresher = save(t, { version = 3, glyphsLifetime = 12, applied = { O = { seq = 4, at = NOW } } }, saveOp)
		t.eq(fresher.glyphsLifetime, 17)
		t.eq(fresher.applied.O.seq, 4, "the other session's receipt is kept")
		-- And a replay against the value this op itself committed is acknowledged, not credited, and writes nothing (R1).
		local replay = plan(first, saveOp)
		t.eq(replay.tag, "acknowledged")
		t.eq(replay.write, nil)
		t.eq(first.glyphsLifetime, 15)
	end)

	t.test("retry window: just below 900 s applies, exactly 900 and above abandon with no candidate", function()
		local stored = { version = 3, glyphsLifetime = 10, applied = {} }
		local below = plan(stored, op("s", 1, 5), { elapsed = WINDOW - 0.001 })
		t.eq(below.tag, "applied")
		t.eq((below.write :: any).glyphsLifetime, 15)
		for _, elapsed in { WINDOW, WINDOW + 0.001, WINDOW + 1, 10 ^ 9, NAN } do
			local late = plan(stored, op("s", 1, 5), { elapsed = elapsed })
			t.eq(late.tag, "abandoned", "elapsed " .. tostring(elapsed))
			t.eq(late.reason, "expired")
			t.eq(late.write, nil, "no write candidate at or past the window")
		end
		local saveOp = op("s", 1, 5)
		t.eq(ProfileRules.expired(saveOp, WINDOW - 0.001), false)
		t.eq(ProfileRules.expired(saveOp, WINDOW), true)
		t.eq(ProfileRules.expired(saveOp, WINDOW + 1), true)
		t.eq(ProfileRules.expired(saveOp, NAN), true)
	end)

	t.test("the Studio window override only shortens the window", function()
		t.eq(ProfileRules.retryWindow(nil), WINDOW)
		t.eq(ProfileRules.retryWindow(5), 5)
		t.eq(ProfileRules.retryWindow(5000), WINDOW)
		for _, bad in { 0, -1, NAN, math.huge } do
			t.eq(ProfileRules.retryWindow(bad), WINDOW, tostring(bad))
		end
		t.eq(plan({}, op("s", 1, 1), { elapsed = 5, window = 5 }).tag, "abandoned")
		t.eq(plan({}, op("s", 1, 1), { elapsed = 4.9, window = 5 }).tag, "applied")
		t.eq(plan({}, op("s", 1, 1), { elapsed = WINDOW, window = 5000 }).tag, "abandoned", "never longer")
	end)

	t.test("a callback replayed across the deadline returns no candidate and abandons cleanly", function()
		local ledger = ProfileRules.credit(ProfileRules.newLedger("s"), 5)
		local taken, saveOp = ProfileRules.takeOp(ledger, false, 100)
		ledger = taken
		-- First callback at elapsed 899 returns a candidate; a conflicting write makes the engine discard it and replay.
		local stored: any = { version = 3, glyphsLifetime = 10, applied = {} }
		t.eq(plan(stored, saveOp :: any, { elapsed = WINDOW - 1 }).tag, "applied")
		local fresher: any = { version = 3, glyphsLifetime = 11, applied = { o = { seq = 1, at = NOW } } }
		local replay = plan(fresher, saveOp :: any, { elapsed = WINDOW })
		t.eq(replay.tag, "abandoned")
		t.eq(replay.write, nil)
		t.eq(fresher.glyphsLifetime, 11, "the store keeps the other server's value")
		ledger = ProfileRules.credit(ledger, 2)
		local settled, terminal = ProfileRules.settle(ledger, { kind = "plan", tag = "abandoned", reason = "expired" })
		t.eq(settled.op, nil)
		t.eq(settled.pending, 2, "later increments stay pending, the abandoned 5 is not returned")
		t.eq((terminal :: any).reason, "expired")
		t.eq((terminal :: any).seq, 1)
		t.eq((terminal :: any).glyphsDelta, 5)
		t.eq((terminal :: any).ambiguous, false, "a cancelled final callback committed nothing")
	end)

	t.test("a candidate submitted before the deadline is confirmed by a late successful response", function()
		local ledger, saveOp = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 5), false, 0)
		local decided = plan({ version = 3, glyphsLifetime = 10 }, saveOp :: any, { elapsed = WINDOW - 0.5 })
		t.eq(decided.tag, "applied")
		-- The response arrives at elapsed 1000: it still confirms what the callback decided.
		t.eq(ProfileRules.expired(saveOp :: any, 1000), true)
		local settled, terminal = ProfileRules.settle(ledger, { kind = "plan", tag = decided.tag })
		t.eq(settled.op, nil)
		t.eq(terminal, nil, "confirmed, not terminal")
		t.eq((decided.write :: any).glyphsLifetime, 15)
	end)

	t.test("ambiguous with a matching receipt is acknowledged; the delta is not added again", function()
		local stored: any = {
			version = 3,
			glyphsLifetime = 15,
			bestRank = 2,
			applied = { s = { seq = 1, at = NOW - 10 }, old = { seq = 1, at = NOW - WEEK - 1 } },
		}
		local ack = plan(stored, op("s", 1, 5, { music = 9 }), { ambiguous = true, patch = { bestRank = 6 } })
		t.eq(ack.tag, "acknowledged")
		t.eq(ack.write, nil, "R1: acknowledging writes nothing, not even bests, settings or a pruned log")
		t.eq(stored.glyphsLifetime, 15)
		t.eq(stored.bestRank, 2)
		t.truthy(stored.applied.old, "the stored log is untouched")
		local lateAck = plan(stored, op("s", 1, 5), { ambiguous = true, elapsed = WINDOW })
		t.eq(lateAck.tag, "acknowledged", "a covering receipt is honoured past the window")
		t.eq(lateAck.write, nil, "and nothing is written")
		t.eq(plan(stored, op("s", 1, 5)).tag, "acknowledged", "also when not marked ambiguous")
	end)

	t.test("ambiguous with a missing or lower-seq receipt is abandoned and writes nothing", function()
		local missing = plan({ version = 3, glyphsLifetime = 15, applied = {} }, op("s", 2, 5), { ambiguous = true })
		t.eq(missing.tag, "abandoned")
		t.eq(missing.reason, "ambiguous_no_receipt")
		t.eq(missing.write, nil)
		local behind = plan(
			{ version = 3, glyphsLifetime = 15, applied = { s = { seq = 1, at = NOW } } },
			op("s", 2, 5),
			{ ambiguous = true }
		)
		t.eq(behind.tag, "abandoned")
		t.eq(behind.reason, "ambiguous_receipt_behind")
		t.eq(behind.write, nil)
		local garbage = plan(
			{ version = 3, applied = { s = { seq = "2", at = NOW } } },
			op("s", 2, 5),
			{ ambiguous = true }
		)
		t.eq(garbage.reason, "ambiguous_no_receipt", "a malformed receipt covers nothing")
	end)

	t.test("ambiguous retry after its receipt was removed is abandoned; the total is unchanged", function()
		-- op 1 committed (+5 -> 15) and errored; a pre-v3 writer then erased the receipt log.
		local committed = save(t, { version = 3, glyphsLifetime = 10, applied = {} }, op("s", 1, 5))
		local erased = table.clone(committed)
		erased.applied = nil
		local decided = plan(erased, op("s", 1, 5), { ambiguous = true })
		t.eq(decided.tag, "abandoned")
		t.eq(decided.write, nil)
		t.eq(erased.glyphsLifetime, 15, "never 20")
	end)

	t.test("a known no-candidate failure retries the unchanged op; ambiguity is sticky", function()
		local ledger, first = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 4), false, 0)
		local afterError = ProfileRules.settle(ledger, { kind = "error", candidate = false })
		t.eq(afterError.ambiguous, false)
		local _, again, fresh = ProfileRules.takeOp(afterError, true, 50)
		t.truthy(again == first, "the same frozen op is retried")
		t.eq(fresh, false)
		t.eq(save(t, { glyphsLifetime = 1 }, again :: any).glyphsLifetime, 5)
		local ambiguous = ProfileRules.settle(afterError, { kind = "error", candidate = true })
		t.eq(ambiguous.ambiguous, true)
		local still = ProfileRules.settle(ambiguous, { kind = "error", candidate = false })
		t.eq(still.ambiguous, true, "a later no-candidate failure does not clear it")
		local capacity = ProfileRules.settle(ambiguous, { kind = "plan", tag = "capacity" })
		t.eq(capacity.ambiguous, true)
		t.truthy(capacity.op == first)
		t.truthy(table.isfrozen(first :: any), "ops are immutable")
	end)

	t.test("abandoned deltas never reappear under a new seq; later increments stay separate", function()
		local stored: any = { version = 3, glyphsLifetime = 100, applied = {} }
		local ledger = ProfileRules.credit(ProfileRules.newLedger("s"), 7)
		local op1: any
		ledger, op1 = ProfileRules.takeOp(ledger, false, 0)
		ledger = ProfileRules.credit(ledger, 2) -- arrives while op 1 is in flight
		ledger = ProfileRules.settle(ledger, { kind = "error", candidate = true }) -- candidate, not committed
		ledger = ProfileRules.credit(ledger, 1)
		local decided = plan(stored, op1, { ambiguous = ledger.ambiguous })
		t.eq(decided.reason, "ambiguous_no_receipt")
		ledger = ProfileRules.settle(ledger, { kind = "plan", tag = decided.tag, reason = decided.reason })
		local op2: any
		ledger, op2 = ProfileRules.takeOp(ledger, false, 10)
		t.eq(op2.seq, 2)
		t.eq(op2.glyphsDelta, 3, "only the increments that arrived later, never the abandoned 7")
		stored = save(t, stored, op2)
		t.eq(stored.glyphsLifetime, 103)
		-- A replay of op 1 can never credit now: the seq 2 receipt covers seq 1.
		t.eq(plan(stored, op1).tag, "acknowledged")
		t.eq(plan(stored, op1, { ambiguous = true }).tag, "acknowledged")
		ledger = ProfileRules.settle(ledger, { kind = "plan", tag = "applied" })
		local _, none = ProfileRules.takeOp(ledger, false, 20)
		t.eq(none, nil, "nothing pending, nothing dirty: no op")
	end)

	t.test("an old shutdown completion arriving while newer increments are pending", function()
		-- op 1 (+5) was submitted at shutdown and its response is lost; 3 more glyphs are pending in the new session's
		-- ledger state. The receipt shows it committed, so the retry acknowledges and only the 3 go out next.
		local committed = save(t, { version = 3, glyphsLifetime = 10, applied = {} }, op("s", 1, 5))
		local ledger, op1 = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 5), false, 0)
		ledger = ProfileRules.settle(ledger, { kind = "error", candidate = true })
		ledger = ProfileRules.credit(ledger, 3)
		local ack = plan(committed, op1 :: any, { ambiguous = true })
		t.eq(ack.tag, "acknowledged")
		ledger = ProfileRules.settle(ledger, { kind = "plan", tag = ack.tag })
		local op2: any
		ledger, op2 = ProfileRules.takeOp(ledger, false, 5)
		t.eq(op2.glyphsDelta, 3)
		t.eq(ack.write, nil, "the acknowledgement writes nothing")
		local final = save(t, committed, op2)
		t.eq(final.glyphsLifetime, 18, "10 + 5 once + 3")
		t.eq(final.applied.s.seq, 2)
	end)

	t.test("leave, autosave and shutdown signals share one op until it resolves", function()
		local ledger, first, fresh = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 4), false, 1)
		t.eq(fresh, true)
		t.eq(ledger.pending, 0, "the op takes all of pending")
		t.eq(ledger.nextSeq, 2)
		ledger = ProfileRules.credit(ledger, 6)
		for _ = 1, 3 do -- autosave, leave and shutdown all ask for the op to save
			local same, again, isNew = ProfileRules.takeOp(ledger, true, 2)
			t.truthy(again == first)
			t.eq(isNew, false)
			t.eq(same.nextSeq, 2, "no seq is spent")
			t.eq(same.pending, 6)
		end
		local idle, zero = ProfileRules.takeOp(ProfileRules.newLedger("t"), true, 0)
		t.eq((zero :: any).glyphsDelta, 0, "dirty settings alone make a zero-delta op")
		t.eq(idle.nextSeq, 2)
		t.eq(ProfileRules.credit(ledger, -1).pending, 6)
		t.eq(ProfileRules.credit(ledger, 1.5).pending, 6)
		t.eq(ProfileRules.credit(ledger, NAN).pending, 6)
	end)

	t.test("shutdown: an unresolved op is reported unconfirmed and stays potentially committed", function()
		local ledger, saveOp = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 4), false, 0)
		local same, terminal = ProfileRules.settle(ledger, { kind = "unconfirmed", candidate = true })
		t.truthy(same.op == saveOp, "the op is kept as it is")
		t.eq((terminal :: any).reason, "unconfirmed_at_shutdown")
		t.eq((terminal :: any).ambiguous, true, "a call in flight may have committed")
		local _, quiet = ProfileRules.settle(ledger, { kind = "unconfirmed", candidate = false })
		t.eq((quiet :: any).ambiguous, false)
		local expired, expiredTerminal =
			ProfileRules.settle(ProfileRules.settle(ledger, { kind = "error", candidate = true }), { kind = "expired" })
		t.eq(expired.op, nil)
		t.eq(expired.ambiguous, false)
		t.eq((expiredTerminal :: any).reason, "expired")
		t.eq((expiredTerminal :: any).ambiguous, true)
		t.eq(select(2, ProfileRules.settle(ProfileRules.newLedger("x"), { kind = "expired" })), nil, "no op, no record")
	end)

	t.test("planSave abandons an op or context without a valid identity", function()
		local stored = { version = 3, glyphsLifetime = 1 }
		local bads: { any } = {
			op("", 1, 1),
			op(string.rep("x", 65), 1, 1),
			op("s", 0, 1),
			op("s", 1.5, 1),
			op("s", NAN, 1),
			op("s", 1, -1),
			op("s", 1, 0.5),
			{ sessionId = "s", seq = 1, glyphsDelta = 1, createdAt = NAN },
			"op",
		}
		for i, bad in bads do
			local decided = ProfileRules.planSave(stored, bad, ctx())
			t.eq(decided.tag, "abandoned", "op " .. i)
			t.eq(decided.reason, "invalid")
			t.eq(decided.write, nil)
		end
		t.eq(plan(stored, op("s", 1, 1), { nowWall = NAN }).reason, "invalid")
		t.eq(plan(stored, op("s", 1, 1), { nowWall = math.huge }).reason, "invalid")
		t.eq(ProfileRules.planSave(stored, op("s", 1, 1), nil :: any).reason, "invalid")
		t.eq(plan(stored, op(string.rep("x", 64), 1, 1)).tag, "applied", "64 characters is allowed")
	end)

	t.test("the total is capped and never overflows", function()
		local top = 2 ^ 53
		t.eq(ProfileRules.merge({ glyphsLifetime = top }, { glyphsDelta = 9 }).glyphsLifetime, top)
	end)

	t.test("merge keeps unknown stored fields, also after migrate -> sanitize (AUD-02 F1)", function()
		local stored = { version = 1, legacy = { a = 1 }, flag = true, bestRank = 2 }
		local loaded = ProfileRules.sanitize(ProfileRules.migrate(stored))
		t.eq((loaded :: any).flag, nil, "the in-memory copy is sanitized")
		local written = ProfileRules.merge(stored, ProfileRules.toPatch(loaded)) :: any
		t.eq(written.flag, true)
		t.eq(written.legacy.a, 1)
		t.eq(written.bestRank, 2)
		t.eq(written.version, 4)
		t.eq(written.glyphsLifetime, 0)
		t.eq(stored.version, 1, "the stored table is not mutated")
	end)

	t.test("merge replaces invalid known fields and keeps the rest", function()
		local written = ProfileRules.merge({ bestRank = 99, blitzBest = 3, extra = "x" }, {}) :: any
		t.eq(written.bestRank, nil)
		t.eq(written.blitzBest, 3)
		t.eq(written.extra, "x")
	end)

	t.test("planSave refuses stored data from a newer build, even one that appeared after load (AUD-02 F1)", function()
		local loaded = ProfileRules.sanitize({ version = 3, glyphsLifetime = 20 })
		local newerNow = { version = 5, extra = "must survive", glyphsLifetime = 20 }
		for _, overrides in { {}, { ambiguous = true }, { elapsed = WINDOW } } do
			local refused = plan(newerNow, op("s", 1, 3), overrides)
			t.eq(refused.tag, "newer_schema")
			t.eq(refused.write, nil, "version 5 is refused, so nothing is erased")
		end
		t.eq(newerNow.extra, "must survive")
		t.eq(plan({ version = 99 }, op("s", 1, 3)).tag, "newer_schema")
		local same = save(t, { version = 3, glyphsLifetime = 20 }, op("s", 1, 3), ProfileRules.toPatch(loaded))
		t.eq(same.glyphsLifetime, 23)
		local older = save(t, { version = 1 }, op("s", 1, 3))
		t.eq(older.version, 4)
		local ledger = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 3), false, 0)
		local settled, terminal = ProfileRules.settle(ledger, { kind = "plan", tag = "newer_schema" })
		t.eq(settled.op, nil)
		t.eq((terminal :: any).reason, "newer_schema")
	end)

	t.test("migrate v2 -> v4 adds an empty save log and keeps unknown fields, the total and settings", function()
		local v2: { [string]: any } =
			{ version = 2, glyphsLifetime = 12, settings = valid(), legacy = { a = 1 }, flag = true }
		local out = ProfileRules.migrate(v2)
		t.eq(out.version, 4)
		t.eq(typeof(out.applied), "table")
		t.eq(next(out.applied), nil)
		t.eq(out.glyphsLifetime, 12)
		t.eq(out.settings.music, 3)
		t.eq(out.legacy.a, 1)
		t.eq(out.flag, true)
		t.eq(v2.applied, nil, "the input is not mutated")
		local keep = ProfileRules.migrate({ version = 3, applied = { s = { seq = 2, at = NOW } } })
		t.eq(keep.applied.s.seq, 2, "a v3 log is not reset")
		-- Existing v3 receipts survive another session's save and still deduplicate their own session.
		local v3: any = { version = 3, glyphsLifetime = 30, applied = { a = { seq = 4, at = NOW - 100 } } }
		local other = save(t, ProfileRules.migrate(v3), op("b", 1, 2))
		t.eq(other.applied.a.seq, 4)
		t.eq(other.applied.a.at, NOW - 100, "the receipt is kept as stored")
		t.eq(other.glyphsLifetime, 32)
		t.eq(plan(other, op("a", 4, 9)).tag, "acknowledged")
		-- Saved through the v3 path, the unknown fields and the total survive and the log gains the op.
		local written = save(t, v2, op("s", 1, 4))
		t.eq(written.version, 4)
		t.eq(written.glyphsLifetime, 16)
		t.eq(written.flag, true)
		t.eq(written.legacy.a, 1)
		t.eq(written.applied.s.seq, 1)
	end)

	t.test("an unknown settings sub-key survives a save and a known key is updated (TASK-0139 3b)", function()
		local storedSettings = valid()
		storedSettings.futureToggle = "keep me"
		local stored = { version = 3, glyphsLifetime = 1, settings = storedSettings }
		local changed = valid()
		changed.music = 9
		local written = save(t, stored, op("s", 1, 0, { music = 9 }))
		t.eq(written.settings.futureToggle, "keep me")
		t.eq(written.settings.music, 9)
		t.eq(written.settings.sfx, 4)
		local snapshot = save(t, stored, op("s", 1, 0), { settings = changed :: any })
		t.eq(snapshot.settings.music, 3, "R2: a full settings table in the attempt patch is never written")
		t.eq(storedSettings.music, 3, "the stored settings table is not mutated")
		local untouched = ProfileRules.merge(stored, {}) :: any
		t.eq(untouched.settings.futureToggle, "keep me", "also when the patch has no settings")
		local garbage = ProfileRules.merge({ settings = "x" }, { settings = changed :: any }) :: any
		t.eq(garbage.settings.music, 9, "a non-table stored settings value is rebuilt")
	end)

	t.test("an adopted unknown settings sub-key stays out of memory, patches and the client", function()
		local storedSettings = valid()
		storedSettings.futureToggle = true
		local current = ProfileRules.sanitize({ version = 3, settings = valid() })
		local adopted = ProfileRules.adopt({ version = 3, settings = storedSettings, extra = 1 }, current, 0)
		t.eq((adopted.settings :: any).futureToggle, nil)
		t.eq((adopted :: any).extra, nil)
		local patch = ProfileRules.toPatch(adopted)
		t.truthy(ProfileRules.sanitizeSettings(patch.settings), "the strict settings check still accepts the patch")
		local stray = ProfileRules.sanitize({ settings = valid() });
		(stray.settings :: any).futureToggle = true
		t.truthy(ProfileRules.sanitizeSettings(ProfileRules.toPatch(stray).settings), "toPatch copies known keys only")
		t.eq(
			(ProfileRules.toClient(stray, "saved").settings :: any).futureToggle,
			nil,
			"the client gets known keys only"
		)
	end)

	t.test(
		"receipts exactly 7 days old are kept, older ones pruned; the own receipt is checked before pruning",
		function()
			local log = ProfileRules.sanitizeApplied({
				edge = { seq = 1, at = NOW - WEEK },
				old = { seq = 1, at = NOW - WEEK - 1 },
				fresh = { seq = 2, at = NOW },
			}, NOW)
			t.truthy(log.edge, "at == now - 604800 is kept")
			t.eq(log.old, nil, "at < now - 604800 is pruned")
			t.eq(log.fresh.seq, 2)
			local written = save(t, {
				version = 3,
				applied = { old = { seq = 1, at = NOW - WEEK - 1 }, edge = { seq = 1, at = NOW - WEEK } },
			}, op("s", 1, 0))
			t.eq(written.applied.old, nil, "a save prunes the stored log")
			t.truthy(written.applied.edge)
			t.truthy(
				ProfileRules.sanitizeApplied({ old = { seq = 1, at = 0 } }, nil).old,
				"without now nothing is aged out"
			)
			-- A covering receipt that pruning would drop still acknowledges: the check runs before pruning.
			local aged = { version = 3, glyphsLifetime = 9, applied = { s = { seq = 3, at = NOW - WEEK - 50 } } }
			local ack = plan(aged, op("s", 3, 4), { ambiguous = true })
			t.eq(ack.tag, "acknowledged")
			t.eq(ack.write, nil, "and nothing is written, so the receipt stays as stored")
			t.eq(aged.glyphsLifetime, 9)
		end
	)

	t.test("at the cap only receipts strictly older than 1200 s are evicted: 1200 kept, 1201 evictable", function()
		t.eq(WINDOW + SKEW, 1200)
		local edge = fullLog(NOW)
		edge.o1.at = NOW - 1200
		local refused = plan({ version = 3, glyphsLifetime = 1, applied = edge }, op("me", 1, 1))
		t.eq(refused.tag, "capacity", "1200 s old is not evictable")
		t.eq(refused.write, nil)
		local over = fullLog(NOW)
		over.o1.at = NOW - 1201
		over.o2.at = NOW - 5000
		local written = save(t, { version = 3, glyphsLifetime = 1, applied = over }, op("me", 1, 1))
		t.eq(count(written.applied), 200)
		t.eq(written.applied.o2, nil, "the oldest evictable receipt goes first")
		t.truthy(written.applied.o1, "only as many as needed are evicted")
		t.truthy(written.applied.me)
		t.eq(written.glyphsLifetime, 2)
		local own = fullLog(NOW)
		own.o200 = nil
		own.me = { seq = 1, at = NOW - 9999 }
		local replaced = save(t, { version = 3, applied = own }, op("me", 2, 1))
		t.eq(count(replaced.applied), 200, "replacing the own receipt needs no room")
	end)

	t.test("an all-young full log refuses with capacity, leaves the store unchanged, and recovers", function()
		local young = fullLog(NOW) -- o1 is 199 s old
		young.o1.at = NOW - 1000
		local stored: any = { version = 3, glyphsLifetime = 50, applied = young }
		local ledger, saveOp = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("me"), 5), false, 0)
		local refused = plan(stored, saveOp :: any, { elapsed = 10 })
		t.eq(refused.tag, "capacity")
		t.eq(refused.write, nil, "nothing written")
		t.eq(stored.glyphsLifetime, 50)
		t.eq(count(stored.applied), 200)
		t.eq(stored.applied.me, nil, "the log is unchanged")
		ledger = ProfileRules.settle(ledger, { kind = "plan", tag = "capacity" })
		t.truthy(ledger.op == saveOp, "the unchanged op is kept for retry")
		-- 201 s later o1 is 1201 s old and evictable; the op is still inside its window.
		local _, retry = ProfileRules.takeOp(ledger, false, 211)
		local recovered = plan(stored, retry :: any, { nowWall = NOW + 201, elapsed = 211 })
		t.eq(recovered.tag, "applied")
		t.eq((recovered.write :: any).glyphsLifetime, 55)
		t.eq((recovered.write :: any).applied.o1, nil)
		-- Past the window the capacity op expires instead of ever being credited.
		t.eq(plan(stored, retry :: any, { nowWall = NOW + 201, elapsed = WINDOW }).tag, "abandoned")
	end)

	t.test("clock skew +300 / -300 s never exposes a live receipt", function()
		-- +300: another server's clock is ahead, its receipts are in our future. They are young: kept, not evictable.
		local ahead = fullLog(NOW + SKEW)
		local refused = plan({ version = 3, applied = ahead }, op("me", 1, 1))
		t.eq(refused.tag, "capacity")
		t.truthy(ProfileRules.sanitizeApplied({ f = { seq = 1, at = NOW + SKEW } }, NOW).f, "a future receipt is kept")
		local ack =
			plan({ version = 3, glyphsLifetime = 4, applied = { me = { seq = 1, at = NOW + SKEW } } }, op("me", 1, 3))
		t.eq(ack.tag, "acknowledged", "a future receipt still deduplicates")
		-- -300: a receipt written at the end of its window by a server 300 s behind reads as 1200 s old here: kept.
		local behind = fullLog(NOW)
		behind.o1.at = NOW - WINDOW - SKEW
		t.eq(plan({ version = 3, applied = behind }, op("me", 1, 1)).tag, "capacity")
		behind.o1.at = NOW - WINDOW - SKEW - 1
		t.eq(plan({ version = 3, applied = behind }, op("me", 1, 1)).tag, "applied")
	end)

	t.test("sanitizeApplied no longer caps the log; only planSave makes room", function()
		local raw = {}
		for i = 1, 201 do
			raw["s" .. i] = { seq = 1, at = NOW - 1000 + i }
		end
		t.eq(count(ProfileRules.sanitizeApplied(raw, NOW)), 201)
	end)

	t.test("malformed save log entries are dropped", function()
		local raw: { [any]: any } = {
			ok = { seq = 3, at = NOW },
			zero = { seq = 0, at = NOW },
			frac = { seq = 1.5, at = NOW },
			nan = { seq = 1, at = NAN },
			inf = { seq = 1, at = math.huge },
			str = { seq = "1", at = NOW },
			notTable = 5,
		}
		raw[""] = { seq = 1, at = NOW }
		raw[string.rep("x", 65)] = { seq = 1, at = NOW }
		raw[1] = { seq = 1, at = NOW }
		local log = ProfileRules.sanitizeApplied(raw, NOW)
		local keys = {}
		for id in log do
			table.insert(keys, id)
		end
		t.eq(#keys, 1)
		t.eq(log.ok.seq, 3)
		t.eq(next(ProfileRules.sanitizeApplied("x", NOW)), nil)
		t.eq(next(ProfileRules.sanitize({ applied = { bad = 1 } }).applied :: any), nil, "sanitize cleans the log too")
	end)

	t.test("adopt takes the stored total and keeps increments that arrived during the save", function()
		-- Stored 16 after this save (another server added 5); 2 more glyphs were collected while it was in flight.
		local current = ProfileRules.sanitize({ version = 2, glyphsLifetime = 11, bestRank = 2 })
		local adopted = ProfileRules.adopt({ version = 2, glyphsLifetime = 16, bestRank = 4 }, current, 2)
		t.eq(adopted.glyphsLifetime, 18)
		t.eq(adopted.bestRank, 4)
		t.eq(ProfileRules.adopt({ version = 2, glyphsLifetime = 16 }, current, 0).glyphsLifetime, 16)
		t.eq(ProfileRules.adopt(nil, current, 0).glyphsLifetime, 0)
	end)
	-- TASK-0141 revision 2 (AUD-20261106-TASK-0141-01): R1-R6 and the R3 load exemption.

	t.test(
		"R1: old session A's acknowledgement after newer session B saved music = 8 leaves music 8, glyphs once",
		function()
			local s8 = valid()
			s8.music = 8
			s8.futureToggle = "keep me"
			-- A's op 1 (+5, music 4) committed (10 -> 15) and errored; then B saved music 8.
			local stored: any = {
				version = 3,
				glyphsLifetime = 15,
				bestRank = 2,
				settings = s8,
				applied = { A = { seq = 1, at = NOW - 100 }, B = { seq = 1, at = NOW - 10 } },
			}
			local aOp = op("A", 1, 5, { music = 4 })
			local ack = plan(stored, aOp, { ambiguous = true, patch = { bestRank = 1 } })
			t.eq(ack.tag, "acknowledged")
			t.eq(ack.write, nil, "nothing is returned, so nothing is written")
			t.eq(ProfileRules.classifyAttempt({ ack }, nil, false), "acknowledged")
			t.eq(stored.settings.music, 8)
			t.eq(stored.glyphsLifetime, 15)
			t.eq(stored.applied.B.seq, 1)
			-- The ledger ends the op without sending its settings again, and the session adopts the stored music 8.
			local before = valid()
			local after = valid()
			after.music = 4
			local ledger = ProfileRules.noteSettings(
				ProfileRules.credit(ProfileRules.newLedger("A"), 5),
				before :: any,
				after :: any
			)
			ledger = ProfileRules.takeOp(ledger, false, 0, NOW - 100)
			ledger = ProfileRules.settle(ledger, { kind = "ambiguous" })
			local done, terminal = ProfileRules.settle(ledger, { kind = "acknowledged" })
			t.eq(done.op, nil)
			t.eq(terminal, nil)
			t.eq(next(done.settingsPatch), nil, "an acknowledged patch is not sent again")
			local view = ProfileRules.adopt(
				stored,
				ProfileRules.sanitize({ settings = after }),
				done.pending,
				done.settingsPatch
			)
			t.eq(view.settings.music, 8)
			t.eq(view.glyphsLifetime, 15)
		end
	)

	t.test(
		"R3: A's delayed in-window retry with settingsPatch {music = 4} after B's newer receipt keeps music 8",
		function()
			local s8 = valid()
			s8.music = 8
			s8.futureToggle = "keep me"
			local stored: any =
				{ version = 3, glyphsLifetime = 10, settings = s8, applied = { B = { seq = 1, at = NOW } } }
			local aOp: ProfileRules.SaveOp = {
				sessionId = "A",
				seq = 1,
				glyphsDelta = 5,
				createdAt = 0,
				createdAtWall = NOW - 120, -- taken two minutes before B saved
				settingsPatch = { music = 4 },
			}
			local decided = plan(stored, aOp, { elapsed = 600 })
			t.eq(decided.tag, "applied")
			t.eq(decided.superseded, true)
			local written = decided.write :: any
			t.eq(written.settings.music, 8, "B's newer setting stays")
			t.eq(written.settings.futureToggle, "keep me")
			t.eq(written.glyphsLifetime, 15, "A's glyph delta is applied")
			t.eq(written.applied.A.seq, 1)
			t.eq(written.applied.B.seq, 1)
			local replay = plan(written, aOp, { elapsed = 601 })
			t.eq(replay.tag, "acknowledged")
			t.eq(replay.write, nil)
			t.eq(written.glyphsLifetime, 15, "applied once, never 20")
			t.eq(ProfileRules.classifyAttempt({ decided }, written, false), "applied")
			local view = ProfileRules.adopt(written, ProfileRules.sanitize({ settings = valid() }), 0, {})
			t.eq(view.settings.music, 8, "the session view comes from what UpdateAsync returned")
			-- The own receipt never supersedes the own patch.
			local own = save(
				t,
				{ version = 3, settings = s8, applied = { A = { seq = 1, at = NOW } } },
				op("A", 2, 0, { music = 4 })
			)
			t.eq(own.settings.music, 4)
		end
	)

	t.test("R3 skew boundary: B.at == createdAtWall - 300 drops the patch, - 301 applies it", function()
		local function withB(at: number): any
			return { version = 3, glyphsLifetime = 1, settings = valid(), applied = { B = { seq = 2, at = at } } }
		end
		local aOp = op("A", 1, 1, { music = 6 })
		local edge = plan(withB(NOW - SKEW), aOp)
		t.eq(edge.tag, "applied")
		t.eq(edge.superseded, true)
		t.eq((edge.write :: any).settings.music, 3)
		t.eq((edge.write :: any).glyphsLifetime, 2)
		local older = plan(withB(NOW - SKEW - 1), aOp)
		t.eq(older.tag, "applied")
		t.eq(older.superseded, nil)
		t.eq((older.write :: any).settings.music, 6)
		local malformed = plan({ version = 3, settings = valid(), applied = { B = { seq = "x", at = NOW } } }, aOp)
		t.eq((malformed.write :: any).settings.music, 6, "a malformed receipt is ignored")
	end)

	t.test("R3 load exemption: a receipt this session saw at load does not drop its patch (server hop)", function()
		-- The player left server X (its last save 20 s ago), joined A and changed music within the first minute.
		local loaded: any =
			{ version = 3, glyphsLifetime = 10, settings = valid(), applied = { X = { seq = 4, at = NOW - 20 } } }
		local known = ProfileRules.receiptSeqs(loaded)
		t.eq(known.X, 4)
		local aOp = op("A", 1, 0, { music = 6 })
		local kept = plan(loaded, aOp, { knownReceipts = known })
		t.eq(kept.superseded, nil)
		t.eq((kept.write :: any).settings.music, 6)
		t.eq(plan(loaded, aOp).superseded, true, "without the exemption R3 drops it")
		-- X saving again after A loaded (seq 5) counts.
		local again: any = { version = 3, settings = valid(), applied = { X = { seq = 5, at = NOW + 10 } } }
		local dropped = plan(again, aOp, { knownReceipts = known })
		t.eq(dropped.superseded, true)
		t.eq((dropped.write :: any).settings.music, 3)
		t.eq(next(ProfileRules.receiptSeqs({ applied = { bad = { seq = 0, at = NOW } } })), nil)
		t.eq(next(ProfileRules.receiptSeqs(nil)), nil)
	end)

	t.test("R2: a settings patch holds only changed keys; an empty patch leaves settings untouched", function()
		local before = valid()
		local after = valid()
		after.music = 7
		local ledger = ProfileRules.noteSettings(ProfileRules.newLedger("s"), before :: any, after :: any)
		t.eq(ledger.settingsPatch.music, 7)
		t.eq(count(ledger.settingsPatch), 1, "only the changed key")
		local back = ProfileRules.noteSettings(ledger, after :: any, before :: any)
		t.eq(back.settingsPatch.music, 3, "changing it back is a change too")
		t.truthy(ProfileRules.noteSettings(ledger, after :: any, after :: any) == ledger, "no change, same ledger")
		local bad = valid()
		bad.music = 99
		t.eq(ProfileRules.noteSettings(ProfileRules.newLedger("s"), before :: any, bad :: any).settingsPatch.music, nil)
		local taken, saveOp = ProfileRules.takeOp(ledger, false, 0, NOW)
		t.eq((saveOp :: any).settingsPatch.music, 7)
		t.truthy(table.isfrozen((saveOp :: any).settingsPatch), "the op's patch is frozen")
		t.eq(next(taken.settingsPatch), nil, "the patch moves into the op")
		t.eq((saveOp :: any).createdAtWall, NOW)
		local _, settingsOnly = ProfileRules.takeOp(ledger, false, 0, NOW)
		t.truthy(settingsOnly ~= nil, "a settings change alone makes an op")
		-- Empty patch: the stored settings (including an unknown sub-key) stay exactly as stored.
		local storedSettings = valid()
		storedSettings.music = 2
		storedSettings.futureToggle = "keep me"
		local stored = { version = 3, settings = storedSettings }
		local untouched = save(t, stored, op("s", 1, 0))
		t.eq(untouched.settings.music, 2)
		t.eq(untouched.settings.sfx, 4)
		t.eq(untouched.settings.futureToggle, "keep me")
		-- A patch writes its valid known keys only; unknown or invalid ones are ignored and unknown stored keys survive.
		local mixed = save(t, stored, op("s", 1, 0, { music = 5, sfx = "x", futureToggle = false }))
		t.eq(mixed.settings.music, 5)
		t.eq(mixed.settings.sfx, 4)
		t.eq(mixed.settings.futureToggle, "keep me")
		t.eq(storedSettings.music, 2, "the stored table is not mutated")
	end)

	t.test("an unconfirmed op's settings return for the next op, still dated from when they were first sent", function()
		local after = valid()
		after.music = 7
		local ledger = ProfileRules.noteSettings(ProfileRules.newLedger("s"), valid() :: any, after :: any)
		ledger = ProfileRules.takeOp(ledger, false, 0, NOW - 50)
		local later = table.clone(after)
		later.sfx = 1
		ledger = ProfileRules.noteSettings(ledger, after :: any, later :: any) -- changed while op 1 was in flight
		local ended, terminal = ProfileRules.settle(ledger, { kind = "expired" })
		t.eq((terminal :: any).reason, "expired")
		t.eq(ended.settingsPatch.music, 7)
		t.eq(ended.settingsPatch.sfx, 1)
		t.eq(ended.settingsWall, NOW - 50)
		local _, second: any = ProfileRules.takeOp(ended, false, 10, NOW)
		t.eq(second.seq, 2)
		t.eq(second.createdAtWall, NOW - 50, "R3 compares the carried settings against their first send")
		t.eq(second.settingsPatch.music, 7)
		t.eq(second.glyphsDelta, 0)
		-- A newer key wins over the requeued value; a confirmed op returns nothing.
		local newer = ProfileRules.noteSettings(ProfileRules.newLedger("s"), valid() :: any, after :: any)
		newer = ProfileRules.takeOp(newer, false, 0, NOW)
		newer = ProfileRules.noteSettings(newer, after :: any, valid() :: any)
		t.eq(ProfileRules.settle(newer, { kind = "abandoned", reason = "ambiguous_no_receipt" }).settingsPatch.music, 3)
		t.eq(
			next(
				ProfileRules.settle(
					ProfileRules.takeOp(
						ProfileRules.noteSettings(ProfileRules.newLedger("s"), valid() :: any, after :: any),
						false,
						0,
						NOW
					),
					{ kind = "applied" }
				).settingsPatch
			),
			nil
		)
	end)

	t.test("R4: an op reported unconfirmed at shutdown, then settling late, has exactly one terminal report", function()
		local ledger, op1: any = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 4), false, 0, NOW)
		local reports = 0
		local reported, terminal = ProfileRules.settle(ledger, { kind = "unconfirmed", candidate = true })
		if terminal ~= nil then
			reports += 1
		end
		t.eq(reported.reportedSeq, 1)
		t.truthy(reported.op == op1, "the op is kept")
		local _, again = ProfileRules.settle(reported, { kind = "unconfirmed", candidate = true })
		t.eq(again, nil, "the shutdown report is not repeated")
		local lates: { any } = {
			{ kind = "abandoned", reason = "ambiguous_no_receipt" },
			{ kind = "expired" },
			{ kind = "newer_schema" },
			{ kind = "plan", tag = "abandoned", reason = "expired" },
		}
		for _, late in lates do
			local ended, lateTerminal = ProfileRules.settle(reported, late :: any)
			t.eq(ended.op, nil, late.kind)
			if lateTerminal ~= nil then
				reports += 1
			end
		end
		t.eq(reports, 1, "exactly one terminal report")
		local confirmed, quiet = ProfileRules.settle(reported, { kind = "applied" })
		t.eq(confirmed.op, nil)
		t.eq(quiet, nil, "a late confirmation is silent")
		-- Credited at most once: the late commit is +4; a replay of op 1 is acknowledged.
		local stored = save(t, { version = 3, glyphsLifetime = 10, applied = {} }, op1)
		t.eq(stored.glyphsLifetime, 14)
		t.eq(plan(stored, op1, { ambiguous = true }).tag, "acknowledged")
		t.eq(confirmed.pending, 0, "nothing returns to pending")
		-- The next op is reported on its own.
		local nextLedger = ProfileRules.takeOp(ProfileRules.credit(confirmed, 1), false, 1, NOW)
		t.truthy(select(2, ProfileRules.settle(nextLedger, { kind = "expired" })) ~= nil, "op 2 gets its own report")
	end)

	t.test(
		"R5: a callback replayed after the shutdown deadline but inside the 900 s window returns no candidate",
		function()
			local stored = { version = 3, glyphsLifetime = 10, applied = {} }
			local saveOp = op("s", 1, 5, { music = 6 })
			local first = plan(stored, saveOp, { elapsed = 20, shutdownLeft = 0.5 })
			t.eq(first.tag, "applied", "before the deadline a candidate is returned")
			for _, left in { 0, -0.001, -5, NAN } do
				local replay = plan(stored, saveOp, { elapsed = 30, shutdownLeft = left })
				t.eq(replay.tag, "deadline", tostring(left))
				t.eq(replay.write, nil)
			end
			t.eq(plan(stored, saveOp, { elapsed = 30 }).tag, "applied", "outside shutdown only the op window applies")
			t.eq(
				plan(stored, saveOp, { elapsed = WINDOW, shutdownLeft = 10 }).reason,
				"expired",
				"the op window still applies"
			)
			local covered = { version = 3, applied = { s = { seq = 1, at = NOW } } }
			local ack = plan(covered, saveOp, { shutdownLeft = 0 })
			t.eq(ack.tag, "acknowledged")
			t.eq(ack.write, nil)
			-- The candidate from before the deadline then a cancelled replay: ambiguous, never confirmed.
			local replay = plan(stored, saveOp, { elapsed = 30, shutdownLeft = 0 })
			t.eq(ProfileRules.classifyAttempt({ first, replay }, nil, false), "ambiguous")
			t.eq(ProfileRules.classifyAttempt({ replay }, nil, false), "retryable_no_candidate")
			local ledger = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 5), false, 0, NOW)
			local kept = ProfileRules.settle(ledger, { kind = "plan", tag = "deadline", reason = "shutdown_deadline" })
			t.truthy(kept.op == ledger.op, "the op stays unresolved")
			t.eq(kept.ambiguous, false)
		end
	)

	t.test("R6: attempt classification table", function()
		local value = { version = 3 }
		local applied: ProfileRules.SavePlan = { tag = "applied", write = value :: any }
		local ack: ProfileRules.SavePlan = { tag = "acknowledged", reason = "receipt" }
		local abandoned: ProfileRules.SavePlan = { tag = "abandoned", reason = "expired" }
		local capacity: ProfileRules.SavePlan = { tag = "capacity" }
		local newer: ProfileRules.SavePlan = { tag = "newer_schema" }
		local deadline: ProfileRules.SavePlan = { tag = "deadline", reason = "shutdown_deadline" }
		local cases: { { any } } = {
			{ { applied }, value, false, "applied" },
			{ { applied, applied }, value, false, "applied" },
			{ { applied }, nil, false, "ambiguous" },
			{ { applied }, nil, true, "ambiguous" },
			{ { applied }, value, true, "ambiguous" },
			{ { applied, abandoned }, nil, false, "ambiguous" },
			{ { applied, ack }, nil, false, "ambiguous" },
			{ { applied, capacity, abandoned }, nil, false, "ambiguous" },
			{ { applied, abandoned }, value, false, "ambiguous" },
			{ { applied, deadline }, nil, false, "ambiguous" },
			{ {}, nil, true, "retryable_no_candidate" },
			{ { capacity }, nil, true, "retryable_no_candidate" },
			{ {}, nil, false, "retryable_no_candidate" },
			{ { deadline }, nil, false, "retryable_no_candidate" },
			{ { ack }, nil, false, "acknowledged" },
			{ { abandoned }, nil, false, "abandoned" },
			{ { abandoned }, value, false, "abandoned" },
			{ { capacity }, nil, false, "capacity" },
			{ { newer }, nil, false, "newer_schema" },
			{ { capacity, newer }, nil, false, "newer_schema" },
		}
		for i, case in cases do
			t.eq(ProfileRules.classifyAttempt(case[1], case[2], case[3]), case[4], "case " .. i)
		end
		t.eq(select(2, ProfileRules.classifyAttempt({ abandoned }, nil, false)), "expired", "the reason comes along")
		-- Ambiguous is never confirmed or retried with a fresh credit: the same op stays, then only ack or abandon.
		local ledger, first: any =
			ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 5), false, 0, NOW)
		ledger = ProfileRules.settle(ledger, { kind = "ambiguous" })
		t.eq(ledger.ambiguous, true)
		local _, same, fresh = ProfileRules.takeOp(ProfileRules.credit(ledger, 2), true, 1, NOW)
		t.truthy(same == first)
		t.eq(fresh, false)
		t.eq(plan({ version = 3, glyphsLifetime = 10, applied = {} }, first, { ambiguous = true }).tag, "abandoned")
		t.eq(ProfileRules.settle(ledger, { kind = "retryable_no_candidate" }).ambiguous, true, "ambiguity is sticky")
	end)
	t.test("AUD-02 F1: a settings change made while an earlier op is unresolved is dated from the change", function()
		local T0 = NOW
		local after = valid()
		after.music = 4
		-- Departed session A: a glyph-only op 1 at T0; the player sets music 4 at T0+5 and leaves.
		local ledger = ProfileRules.credit(ProfileRules.newLedger("A"), 2)
		ledger = ProfileRules.takeOp(ledger, false, 0, T0)
		ledger = ProfileRules.noteSettings(ledger, valid() :: any, after :: any, T0 + 5)
		t.eq(ledger.settingsWall, T0 + 5)
		local later = table.clone(after)
		later.sfx = 1
		t.eq(
			ProfileRules.noteSettings(ledger, after :: any, later :: any, T0 + 50).settingsWall,
			T0 + 5,
			"the earliest pending change dates the patch"
		)
		-- Session B saves music 8 at T0+100. Op 1 then expires, or applies late; op 2 is taken at T0+910.
		local s8 = valid()
		s8.music = 8
		local stored: any =
			{ version = 3, glyphsLifetime = 10, settings = s8, applied = { B = { seq = 1, at = T0 + 100 } } }
		local alone: any = { version = 3, glyphsLifetime = 10, settings = valid(), applied = {} }
		local endings: { any } = { { kind = "expired" }, { kind = "applied" } }
		for _, ending in endings do
			local settled = ProfileRules.settle(ledger, ending)
			local _, op2: any = ProfileRules.takeOp(settled, false, 910, T0 + 910)
			t.eq(op2.seq, 2)
			t.eq(op2.createdAtWall, T0 + 5, ending.kind)
			t.eq(op2.settingsPatch.music, 4)
			local decided = plan(stored, op2, { nowWall = T0 + 910, elapsed = 1 })
			t.eq(decided.tag, "applied")
			t.eq(decided.superseded, true, ending.kind)
			t.eq((decided.write :: any).settings.music, 8, "B's newer music 8 stays")
			-- With no newer session the change still lands.
			local own = plan(alone, op2, { nowWall = T0 + 910, elapsed = 1 })
			t.eq(own.superseded, nil)
			t.eq((own.write :: any).settings.music, 4)
		end
		t.eq(
			ProfileRules.noteSettings(ProfileRules.newLedger("x"), valid() :: any, after :: any).settingsWall,
			nil,
			"without a change time nothing is stamped"
		)
	end)

	-- ---------------------------------------------------------------------------------------------------------------
	-- Schema v4 (TASK-0150): ordered conditional commands applied inside the transform against the STORED state.
	local DAY = 20833
	local NOON = DAY * 86400 + 43200
	local USER = 4242

	local function v4(day: number?, mutate: ((any) -> ())?): any
		local d = day or DAY
		local board = QuestRules.boardFor(USER, d, QuestConfig.CatalogVersion)
		assert(board, "board")
		local stored: any = {
			version = 4,
			xp = 0,
			glyphsLifetime = 5,
			settings = valid(),
			applied = {},
			dailyEpoch = d,
			playXpDay = { day = d, amount = 0 },
			quests = board,
			extra = "keep me",
		}
		if mutate then
			mutate(stored)
		end
		return stored
	end

	local function qop(session: string, seq: number, commands: { any }): ProfileRules.SaveOp
		local o = op(session, seq, 0)
		return table.freeze({
			sessionId = o.sessionId,
			seq = o.seq,
			glyphsDelta = 0,
			createdAt = 0,
			createdAtWall = NOON,
			settingsPatch = {},
			commands = commands,
		}) :: any
	end

	local eventCounter = 0
	local function eid(): string
		eventCounter += 1
		return `e{eventCounter}`
	end

	-- Runs one op of `commands` for `session` against `stored`; returns the plan (and fails unless it wrote).
	local function runOp(
		stored: any,
		session: string,
		seq: number,
		commands: { any },
		overrides: { [string]: any }?
	): any
		local c: { [string]: any } = { nowWall = NOON, userId = USER }
		if overrides then
			for key, value in overrides do
				c[key] = value
			end
		end
		return plan(stored, qop(session, seq, commands), c)
	end

	local function wrote(runner: TestRunner.T, decided: any): any
		runner.eq(decided.tag, "applied")
		return decided.write
	end

	local function progress(board: any, slot: number, amount: number?): any
		local s = board.slots[slot]
		local quest = QuestConfig.Catalog[s.id]
		return {
			type = "progress",
			day = board.day,
			catalogVersion = board.catalogVersion,
			slotId = s.id,
			generation = s.generation,
			kind = quest.kind,
			amount = amount or quest.target,
			eventId = eid(),
		}
	end

	local function claim(board: any, slot: number): any
		return {
			type = "claim",
			day = board.day,
			slot = slot,
			boardRevision = board.boardRevision,
			generation = board.slots[slot].generation,
			eventId = eid(),
		}
	end

	local function rewardOf(board: any, slot: number): number
		return QuestConfig.Catalog[board.slots[slot].id].xp
	end

	local function deepSame(a: any, b: any): boolean
		if typeof(a) ~= typeof(b) then
			return false
		end
		if typeof(a) ~= "table" then
			return a == b
		end
		for key, value in a do
			if not deepSame(value, b[key]) then
				return false
			end
		end
		for key in b do
			if a[key] == nil then
				return false
			end
		end
		return true
	end

	t.test(
		"v3 -> v4 migration keeps settings, ranks, bests, glyph total, receipts and unknown fields; xp 0, daily uninitialised",
		function()
			local v3: any = {
				version = 3,
				settings = valid(),
				bestRank = 4,
				lastTestRank = 3,
				lastTakenAt = NOW - 50,
				blitzBest = 7,
				glyphsLifetime = 33,
				applied = { a = { seq = 2, at = NOW - 10 } },
				unknownField = { 1, 2, 3 },
			}
			local out = ProfileRules.migrate(v3)
			t.eq(out.version, 4)
			t.eq(out.xp, 0)
			t.eq(out.dailyEpoch, nil)
			t.eq(out.playXpDay, nil)
			t.eq(out.quests, nil)
			t.eq(out.settings.music, 3)
			t.eq(out.bestRank, 4)
			t.eq(out.lastTestRank, 3)
			t.eq(out.lastTakenAt, NOW - 50)
			t.eq(out.blitzBest, 7)
			t.eq(out.glyphsLifetime, 33)
			t.eq(out.applied.a.seq, 2)
			t.eq(out.unknownField[3], 3)
			t.eq(ProfileRules.dailyStatus(out, NOON), "uninitialized")
			t.eq(v3.version, 3, "the stored table is not mutated")
		end
	)

	t.test("migration is idempotent and never touches an existing v4 value, damaged or not", function()
		local v3: any = { version = 3, glyphsLifetime = 4 }
		local once = ProfileRules.migrate(v3)
		t.truthy(deepSame(once, ProfileRules.migrate(once)), "migrate(migrate(x)) == migrate(x)")
		local good = v4()
		t.truthy(deepSame(good, ProfileRules.migrate(good)), "a valid v4 value passes through")
		local damaged = v4(nil, function(s)
			s.playXpDay.day = DAY - 1
		end)
		t.truthy(deepSame(damaged, ProfileRules.migrate(damaged)), "a damaged v4 value is not repaired")
	end)

	t.test("a v3 stored value saved with a rollover becomes v4 in the same transform and keeps everything", function()
		local v3: any = { version = 3, glyphsLifetime = 9, bestRank = 2, settings = valid(), extra = "x", applied = {} }
		local written = wrote(t, runOp(v3, "A", 1, { { type = "rollover", newDay = DAY } }))
		t.eq(written.version, 4)
		t.eq(written.xp, 0, "no historical quest is awarded")
		t.eq(written.dailyEpoch, DAY)
		t.eq(written.playXpDay.amount, 0)
		t.eq(written.quests.day, DAY)
		t.eq(written.quests.boardRevision, 1)
		t.eq(written.glyphsLifetime, 9)
		t.eq(written.bestRank, 2)
		t.eq(written.extra, "x")
		t.eq(written.applied.A.seq, 1)
	end)

	t.test("newer than v4 is refused, also while commands are pending", function()
		local newer: any = { version = 5, xp = 10, extra = "must survive" }
		local decided = runOp(newer, "A", 1, { { type = "rollover", newDay = DAY } })
		t.eq(decided.tag, "newer_schema")
		t.eq(decided.write, nil)
		t.eq(newer.xp, 10)
	end)

	t.test(
		"malformed v4 daily fields fail closed: nothing is applied, repaired or re-granted, other data kept",
		function()
			local cases: { { name: string, fn: (any) -> () } } = {
				{
					name = "play day differs from the epoch",
					fn = function(s)
						s.playXpDay.day = DAY - 1
					end,
				},
				{
					name = "quests day differs from the epoch",
					fn = function(s)
						s.quests = QuestRules.boardFor(USER, DAY - 1, 1)
					end,
				},
				{
					name = "amount above the cap",
					fn = function(s)
						s.playXpDay.amount = XpConfig.PlayCap + 1
					end,
				},
				{
					name = "missing quests table",
					fn = function(s)
						s.quests = nil
					end,
				},
				{
					name = "xp is not a number",
					fn = function(s)
						s.xp = "lots"
					end,
				},
				{
					name = "bonus granted without three complete slots",
					fn = function(s)
						s.quests.bonusGranted = true
					end,
				},
			}
			for _, case in cases do
				local stored = v4(nil, case.fn)
				t.eq(ProfileRules.dailyStatus(stored, NOON), "disabled", case.name)
				local decided = runOp(stored, "A", 1, { claim(v4().quests, 1), progress(v4().quests, 1) })
				local out = wrote(t, decided)
				t.eq(out.xp, stored.xp, case.name .. ": xp unchanged")
				t.truthy(deepSame(out.quests, stored.quests), case.name .. ": quests not repaired")
				t.truthy(deepSame(out.playXpDay, stored.playXpDay), case.name .. ": cap amount not lowered")
				t.eq(out.extra, "keep me", case.name)
				t.eq(out.glyphsLifetime, 5, case.name)
				for _, result in decided.results do
					t.eq(result.applied, false, case.name)
					t.eq(result.reason, "daily_disabled", case.name)
				end
			end
		end
	)

	t.test("an unknown catalog version fails closed and is not reinterpreted", function()
		local stored = v4(nil, function(s)
			s.quests.catalogVersion = 99
		end)
		t.eq(ProfileRules.dailyStatus(stored, NOON), "disabled")
		local out = wrote(t, runOp(stored, "A", 1, { { type = "rollover", newDay = DAY + 1 } }))
		t.eq(out.quests.catalogVersion, 99)
		t.eq(out.dailyEpoch, DAY)
		t.eq(out.xp, 0)
		local loaded = ProfileRules.sanitize(stored)
		t.eq(loaded.dailyDisabled, true)
		t.eq(loaded.quests, nil)
	end)

	t.test("two sessions claiming the same quest award it once", function()
		local base = v4()
		local done = wrote(t, runOp(base, "A", 1, { progress(base.quests, 1) }))
		local reward = rewardOf(done.quests, 1)
		local claimCmd = claim(done.quests, 1)
		local first = runOp(done, "A", 2, { claimCmd })
		local afterA = wrote(t, first)
		t.eq(afterA.xp, reward)
		t.eq(first.results[1].xp, reward)
		-- Session B's independent claim of the same quest runs on A's stored result.
		local second = runOp(afterA, "B", 1, { claim(done.quests, 1) })
		local afterB = wrote(t, second)
		t.eq(afterB.xp, reward, "the second claim awards zero")
		t.eq(second.results[1].xp, 0)
		t.eq(second.results[1].reason, "no_award")
		t.eq(afterB.quests.slots[1].claimed, true)
	end)

	t.test("claim versus rollover in both orders pays the quest exactly once", function()
		local base = v4()
		local done = wrote(t, runOp(base, "A", 1, { progress(base.quests, 2) }))
		local reward = rewardOf(done.quests, 2)
		local c = claim(done.quests, 2)
		local rollover = { type = "rollover", newDay = DAY + 1 }
		local tomorrow = { nowWall = (DAY + 1) * 86400 + 100 }
		-- claim, then rollover
		local a = wrote(t, runOp(done, "A", 2, { c, rollover }, tomorrow))
		t.eq(a.xp, reward)
		t.eq(a.dailyEpoch, DAY + 1)
		-- rollover, then claim (the claim names the closed day and is dropped)
		local decided = runOp(done, "A", 2, { rollover, claim(done.quests, 2) }, tomorrow)
		local b = wrote(t, decided)
		t.eq(b.xp, reward, "rollover settled the completed unclaimed quest")
		t.eq(decided.results[2].xp, 0)
		t.eq(decided.droppedOldDay, 1)
		-- the same two orders across two sessions
		local viaRollover = wrote(t, runOp(done, "B", 1, { rollover }, tomorrow))
		local late = runOp(viaRollover, "A", 2, { claim(done.quests, 2) }, tomorrow)
		t.eq(wrote(t, late).xp, reward)
		t.eq(late.results[1].reason, "old_day")
	end)

	t.test("the all-three bonus is paid once through every completion order", function()
		local orders = { { 1, 2, 3 }, { 1, 3, 2 }, { 2, 1, 3 }, { 2, 3, 1 }, { 3, 1, 2 }, { 3, 2, 1 } }
		for _, order in orders do
			local stored = v4()
			local board = stored.quests
			local total = 0
			local current = stored
			for index, slot in order do
				local decided = runOp(current, "A", index, { progress(board, slot) })
				current = wrote(t, decided)
				total += decided.results[1].xp
			end
			t.eq(current.xp, XpConfig.AllThreeBonus, `bonus once: {table.concat(order, ",")}`)
			t.eq(current.quests.bonusGranted, true)
			-- claiming afterwards never pays the bonus again
			local seq = #order
			for _, slot in order do
				seq += 1
				current = wrote(t, runOp(current, "A", seq, { claim(current.quests, slot) }))
			end
			local rewards = rewardOf(board, 1) + rewardOf(board, 2) + rewardOf(board, 3)
			t.eq(current.xp, rewards + XpConfig.AllThreeBonus, "claims pay the quests and no second bonus")
			-- a claim in the middle of the sequence changes nothing about the bonus
			local mixed = v4()
			local m = wrote(t, runOp(mixed, "A", 1, { progress(board, order[1]), claim(board, order[1]) }))
			m = wrote(t, runOp(m, "A", 2, { progress(board, order[2]), progress(board, order[3]) }))
			t.eq(m.quests.bonusGranted, true)
			t.eq(m.xp, rewardOf(board, order[1]) + XpConfig.AllThreeBonus)
		end
	end)

	t.test("cap contention 390 + 10 + 10 across two sessions ends at 400", function()
		local stored = v4(nil, function(s)
			s.playXpDay.amount = 390
			s.xp = 390
		end)
		local play = function(n: number): any
			return { type = "play", day = DAY, source = "glyph", nominal = n, eventId = eid() }
		end
		local first = runOp(stored, "A", 1, { play(10) })
		local afterA = wrote(t, first)
		local second = runOp(afterA, "B", 1, { play(10) })
		local afterB = wrote(t, second)
		t.eq(afterA.playXpDay.amount, 400)
		t.eq(afterB.playXpDay.amount, 400)
		t.eq(afterB.xp, 400, "xp grew by exactly what the cap permitted")
		t.eq(second.results[1].reason, "cap")
		-- one op carrying both: 390 + 10 + 10 in order
		local both = wrote(t, runOp(stored, "A", 1, { play(10), play(10) }))
		t.eq(both.xp, 400)
		-- quest XP bypasses the cap: a claim still pays at 400
		local board = stored.quests
		local atCap = wrote(t, runOp(afterB, "A", 2, { progress(board, 1), claim(board, 1) }))
		t.eq(atCap.xp, 400 + rewardOf(board, 1))
		t.eq(atCap.playXpDay.amount, 400)
	end)

	t.test("callback replay recomputes from the supplied value and never mutates the op or the stored value", function()
		local base = v4()
		local commands = table.freeze({ progress(base.quests, 1), claim(base.quests, 1) })
		local frozenOp = qop("A", 1, commands)
		local c = ctx({ userId = USER, nowWall = NOON })
		local first = ProfileRules.planSave(base, frozenOp, c)
		local replay = ProfileRules.planSave(base, frozenOp, c)
		t.truthy(deepSame(first.write, replay.write), "the same supplied value gives the same candidate")
		t.eq(base.xp, 0, "the stored value is untouched")
		-- the engine replays with the newer value another server wrote meanwhile
		local newer = v4(nil, function(s)
			s.quests.slots[1].progress = QuestConfig.Catalog[s.quests.slots[1].id].target
			s.quests.slots[1].claimed = true
			s.xp = 100
		end)
		local again = ProfileRules.planSave(newer, frozenOp, c)
		t.eq(again.tag, "applied")
		t.eq((again.write :: any).xp, 100, "recomputed against the newer value: the claim awards zero")
		-- once committed, a replay is acknowledged by the receipt and writes nothing
		local committed = first.write :: any
		local ack = ProfileRules.planSave(committed, frozenOp, c)
		t.eq(ack.tag, "acknowledged")
		t.eq(ack.write, nil)
	end)

	t.test("missing or evicted receipt: an ambiguous op is abandoned and never credits twice", function()
		local base = v4()
		local frozenOp = qop("A", 1, { progress(base.quests, 1), claim(base.quests, 1) })
		local c = ctx({ userId = USER, nowWall = NOON })
		local first = ProfileRules.planSave(base, frozenOp, c)
		local committed = first.write :: any
		t.eq(committed.xp, rewardOf(base.quests, 1))
		-- the commit happened but the client saw an error; the receipt got evicted by a cap squeeze elsewhere
		local evicted = table.clone(committed)
		evicted.applied = {}
		local ambiguous =
			ProfileRules.planSave(evicted, frozenOp, ctx({ userId = USER, nowWall = NOON, ambiguous = true }))
		t.eq(ambiguous.tag, "abandoned")
		t.eq(ambiguous.write, nil, "no second credit without proof it did not commit")
		-- the receipt is present: an ambiguous op is acknowledged instead
		local withReceipt =
			ProfileRules.planSave(committed, frozenOp, ctx({ userId = USER, nowWall = NOON, ambiguous = true }))
		t.eq(withReceipt.tag, "acknowledged")
	end)

	t.test(
		"ambiguous commit then rejoin: a new session's commands are new facts, the old op is never regenerated",
		function()
			local base = v4()
			local old = qop("OLD", 1, { progress(base.quests, 1) })
			local committed = ProfileRules.planSave(base, old, ctx({ userId = USER, nowWall = NOON })).write :: any
			-- the player rejoins with a fresh session id and its own seq 1
			local fresh = wrote(t, runOp(committed, "NEW", 1, { progress(base.quests, 2) }))
			t.eq(
				fresh.quests.slots[1].progress,
				QuestConfig.Catalog[base.quests.slots[1].id].target,
				"old op's progress stays once"
			)
			t.eq(fresh.quests.slots[2].progress, QuestConfig.Catalog[base.quests.slots[2].id].target)
			t.eq(fresh.applied.OLD.seq, 1)
			t.eq(fresh.applied.NEW.seq, 1)
		end
	)

	t.test("abandonment without regeneration: an abandoned op's commands are gone and never re-queued", function()
		local base = v4()
		local ledger = ProfileRules.newLedger("A")
		local queued
		ledger, queued = ProfileRules.queueCommand(ledger, progress(base.quests, 1))
		t.eq(queued, true)
		local taken, frozen = ProfileRules.takeOp(ledger, false, 0, NOON)
		t.eq(#(frozen :: any).commands, 1)
		t.eq(#taken.queue, 0)
		local settled, terminal = ProfileRules.settle(taken, { kind = "abandoned", reason = "ambiguous_no_receipt" })
		t.eq(settled.op, nil)
		t.eq(#settled.queue, 0, "nothing returns to the queue")
		t.truthy(terminal ~= nil, "logged once")
		local _, again = ProfileRules.takeOp(settled, false, 1, NOON)
		t.eq(again, nil, "no new op is invented from an abandoned one")
		local expiredLedger = ProfileRules.settle(taken, { kind = "expired" })
		t.eq(#expiredLedger.queue, 0)
	end)

	t.test("progress during an unresolved save waits for the next op and never joins the frozen one", function()
		local base = v4()
		local ledger = ProfileRules.newLedger("A")
		ledger = ProfileRules.queueCommand(ledger, progress(base.quests, 1))
		local taken, frozen = ProfileRules.takeOp(ledger, false, 0, NOON)
		taken = ProfileRules.queueCommand(taken, progress(base.quests, 2))
		t.eq(#(frozen :: any).commands, 1, "the frozen op is unchanged")
		local same, op2, fresh = ProfileRules.takeOp(taken, false, 5, NOON)
		t.eq(op2, frozen, "the unresolved op is retried as it was")
		t.eq(fresh, false)
		t.eq(#same.queue, 1)
		t.eq(ProfileRules.pendingCommands(same), 2)
		local resolved = ProfileRules.settle(same, { kind = "applied" })
		local _, next2 = ProfileRules.takeOp(resolved, false, 6, NOON)
		t.eq(#(next2 :: any).commands, 1)
		t.eq((next2 :: any).seq, 2)
	end)

	t.test("stale day, generation and board revision change nothing", function()
		local base = v4()
		local done = wrote(t, runOp(base, "A", 1, { progress(base.quests, 1) }))
		local board = done.quests
		local staleRevision = claim(board, 1)
		staleRevision.boardRevision = board.boardRevision + 1
		local staleGeneration = claim(board, 1)
		staleGeneration.generation = board.slots[1].generation + 1
		local staleDay = claim(board, 1)
		staleDay.day = DAY - 1
		local futureDay = claim(board, 1)
		futureDay.day = DAY + 1
		local decided = runOp(done, "A", 2, { staleRevision, staleGeneration, staleDay, futureDay })
		local out = wrote(t, decided)
		t.eq(out.xp, 0)
		t.eq(out.quests.slots[1].claimed, false)
		t.eq(decided.results[1].reason, "no_award")
		t.eq(decided.results[2].reason, "no_award")
		t.eq(decided.results[3].reason, "old_day")
		t.eq(decided.results[4].reason, "future_day")
		local badGeneration = progress(board, 2)
		badGeneration.generation = 2
		local noMatch = runOp(done, "A", 3, { badGeneration })
		t.eq(noMatch.results[1].reason, "no_match")
	end)

	t.test("multiple missed days: one rollover settles the old board once and opens the new day", function()
		local base = v4()
		local done = wrote(t, runOp(base, "A", 1, { progress(base.quests, 1), progress(base.quests, 3) }))
		local missed = DAY + 3
		local out = wrote(
			t,
			runOp(done, "A", 2, { { type = "rollover", newDay = missed } }, { nowWall = missed * 86400 + 100 })
		)
		t.eq(out.dailyEpoch, missed)
		t.eq(out.playXpDay.day, missed)
		t.eq(out.quests.day, missed)
		t.eq(out.quests.boardRevision, 2)
		t.eq(out.xp, rewardOf(base.quests, 1) + rewardOf(base.quests, 3))
		local again =
			wrote(t, runOp(out, "A", 3, { { type = "rollover", newDay = missed } }, { nowWall = missed * 86400 + 100 }))
		t.eq(again.xp, out.xp, "a repeated rollover settles nothing")
		local backwards = runOp(
			out,
			"A",
			4,
			{ { type = "rollover", newDay = DAY } },
			{ nowWall = missed * 86400 + 100 }
		)
		t.eq(backwards.results[1].reason, "not_later")
	end)

	t.test("clock skew around midnight: an adjacent stored day is kept, beyond the bound it is disabled", function()
		local midnight = (DAY + 1) * 86400
		-- this server is 100 s before midnight; another server already rolled to DAY + 1: adjacentAhead
		local ahead = v4(DAY + 1)
		local nowLocal = midnight - 100
		t.eq(ProfileRules.dailyStatus(ahead, nowLocal), "ok")
		local behindPlay = { type = "play", day = DAY, source = "glyph", nominal = 1, eventId = eid() }
		local currentPlay = { type = "play", day = DAY + 1, source = "glyph", nominal = 1, eventId = eid() }
		local decided = runOp(ahead, "A", 1, { behindPlay, currentPlay }, { nowWall = nowLocal })
		local out = wrote(t, decided)
		t.eq(decided.results[1].reason, "old_day", "behind-day commands are rejected")
		t.eq(decided.results[2].applied, true, "the stored epoch's own day resumes")
		t.eq(out.dailyEpoch, DAY + 1, "the adjacent epoch is preserved, never moved back")
		t.eq(out.xp, 1)
		-- 400 s before midnight is outside the 300 s bound: a stored next day is invalid
		t.eq(ProfileRules.dailyStatus(ahead, midnight - XpConfig.DailySkewSeconds - 100), "disabled")
		-- exactly at the bound is still adjacent
		t.eq(ProfileRules.dailyStatus(ahead, midnight - XpConfig.DailySkewSeconds), "ok")
		-- two days ahead is corrupt at any time of day
		t.eq(ProfileRules.dailyStatus(v4(DAY + 2), midnight - 1), "disabled")
		-- the other side: this server is 100 s past midnight, the stored day is one behind (lagging server): ordinary rollover
		local lagging = v4(DAY)
		local rolled =
			wrote(t, runOp(lagging, "A", 1, { { type = "rollover", newDay = DAY + 1 } }, { nowWall = midnight + 100 }))
		t.eq(rolled.dailyEpoch, DAY + 1)
		-- a rollover to a day the clock has not reached is refused
		local early = runOp(lagging, "A", 1, { { type = "rollover", newDay = DAY + 3 } }, { nowWall = midnight + 100 })
		t.eq(early.results[1].reason, "bad_day")
	end)

	t.test("an uninitialised daily state is opened only by a rollover; everything else is dropped", function()
		local migrated = ProfileRules.migrate({ version = 3, glyphsLifetime = 2 })
		local base = v4().quests
		local decided = runOp(migrated, "A", 1, {
			progress(base, 1),
			{ type = "play", day = DAY, source = "glyph", nominal = 1, eventId = eid() },
			claim(base, 1),
		})
		local out = wrote(t, decided)
		for _, result in decided.results do
			t.eq(result.reason, "uninitialized")
		end
		t.eq(out.xp, 0)
		t.eq(out.quests, nil)
	end)

	t.test(
		"queueCommand: duplicate event ids queue once, shapes are validated, the queue is bounded, increments fold",
		function()
			local ledger = ProfileRules.newLedger("A")
			local board = v4().quests
			local first = progress(board, 1, 2)
			first.eventId = "dup"
			local queued, reason
			ledger, queued = ProfileRules.queueCommand(ledger, first)
			t.eq(queued, true)
			local same = ProfileRules.queueCommand(ledger, first)
			local _, again, why = ProfileRules.queueCommand(ledger, first)
			t.eq(again, false)
			t.eq(why, "duplicate")
			t.eq(same, ledger)
			-- the same quest again folds into the last command
			local second = progress(board, 1, 3)
			ledger = ProfileRules.queueCommand(ledger, second)
			t.eq(#ledger.queue, 1)
			t.eq(ledger.queue[1].amount, 5)
			-- malformed commands
			local bad: { any } = {
				"nope",
				{ type = "mint", amount = 99 },
				{ type = "play", day = DAY, source = "glyph", nominal = 1.5, eventId = "x" },
				{ type = "play", day = DAY, source = "cheat", nominal = 1, eventId = "x" },
				{ type = "play", day = DAY, source = "glyph", nominal = 1, eventId = "x", extra = true },
				{ type = "play", day = NAN, source = "glyph", nominal = 1, eventId = "x" },
				{ type = "play", day = DAY, source = "glyph", nominal = XpConfig.PlayCap + 1, eventId = "x" },
				{ type = "claim", day = DAY, slot = 4, boardRevision = 1, generation = 1 },
				{ type = "rollover", newDay = -1 },
				{
					type = "progress",
					day = DAY,
					catalogVersion = 1,
					slotId = "A_E_15",
					generation = 1,
					kind = "correct",
					amount = 0,
					eventId = "x",
				},
			}
			for index, command in bad do
				local unchanged
				ledger, unchanged, reason = ProfileRules.queueCommand(ledger, command)
				t.eq(unchanged, false, `bad command {index}`)
				t.eq(reason, "invalid", `bad command {index}`)
			end
			-- the cap
			local full = ProfileRules.newLedger("B")
			for i = 1, 64 do
				full = ProfileRules.queueCommand(
					full,
					{ type = "claim", day = DAY, slot = 1 + i % 3, boardRevision = i, generation = 1, eventId = `c{i}` }
				)
			end
			t.eq(#full.queue, 64)
			local _, over, overWhy =
				ProfileRules.queueCommand(full, { type = "rollover", newDay = DAY, eventId = "late" })
			t.eq(over, false)
			t.eq(overWhy, "queue_full")
			-- a frozen op carries at most the queue and all of it, in order
			local _, frozen = ProfileRules.takeOp(full, false, 0, NOON)
			t.eq(#(frozen :: any).commands, 64)
			t.eq((frozen :: any).commands[1].boardRevision, 1)
			t.eq((frozen :: any).commands[64].boardRevision, 64)
		end
	)

	t.test(
		"parseClaimPayload accepts exactly four integers and refuses unknown fields, fractions, NaN and infinity",
		function()
			local good = { day = DAY, slot = 2, boardRevision = 1, generation = 1 }
			t.truthy(ProfileRules.parseClaimPayload(good) ~= nil)
			local cases: { any } = {
				"x",
				{},
				{ day = DAY, slot = 2, boardRevision = 1 },
				{ day = DAY, slot = 2, boardRevision = 1, generation = 1, xp = 999 },
				{ day = DAY, slot = 2.5, boardRevision = 1, generation = 1 },
				{ day = NAN, slot = 2, boardRevision = 1, generation = 1 },
				{ day = math.huge, slot = 2, boardRevision = 1, generation = 1 },
				{ day = DAY, slot = 0, boardRevision = 1, generation = 1 },
				{ day = DAY, slot = 4, boardRevision = 1, generation = 1 },
				{ day = DAY, slot = 1, boardRevision = 0, generation = 1 },
				{ day = DAY, slot = 1, boardRevision = 1, generation = "1" },
				{ day = -1, slot = 1, boardRevision = 1, generation = 1 },
			}
			for index, case in cases do
				t.eq(ProfileRules.parseClaimPayload(case), nil, `payload {index}`)
			end
		end
	)

	t.test(
		"sanitize carries xp and a valid board into the session profile; a damaged board marks the daily feature disabled",
		function()
			local loaded = ProfileRules.sanitize(v4(nil, function(s)
				s.xp = 250
			end))
			t.eq(loaded.xp, 250)
			t.eq(loaded.dailyEpoch, DAY)
			t.eq((loaded.quests :: any).day, DAY)
			t.eq(loaded.dailyDisabled, nil)
			local hugeXp = ProfileRules.sanitize({ version = 4, xp = 2 ^ 60 })
			t.eq(hugeXp.xp, 0)
			t.eq(hugeXp.dailyDisabled, true)
			local fresh = ProfileRules.sanitize(ProfileRules.migrate({ version = 3 }))
			t.eq(fresh.xp, 0)
			t.eq(fresh.dailyEpoch, nil)
			t.eq(fresh.dailyDisabled, nil)
		end
	)

	t.test(
		"merge and adopt keep the stored daily fields exactly, so a settings save never resets or lowers them",
		function()
			local stored = v4(nil, function(s)
				s.xp = 321
				s.playXpDay.amount = 77
			end)
			local merged = ProfileRules.merge(stored, { blitzBest = 3 }) :: any
			t.eq(merged.xp, 321)
			t.eq(merged.playXpDay.amount, 77)
			t.truthy(deepSame(merged.quests, stored.quests))
			local damaged = v4(nil, function(s)
				s.playXpDay.day = 1
			end)
			local kept = ProfileRules.merge(damaged, { blitzBest = 3 }) :: any
			t.eq(kept.playXpDay.day, 1, "damaged daily fields are carried through, not repaired")
			local adopted = ProfileRules.adopt(stored, ProfileRules.sanitize(stored), 0, nil)
			t.eq(adopted.xp, 321)
			-- a plain glyph/settings op (no commands) on a v4 value changes no daily field
			local plain = wrote(t, plan(stored, op("A", 1, 4), { userId = USER, nowWall = NOON }))
			t.eq(plain.xp, 321)
			t.eq(plain.glyphsLifetime, 9)
			t.truthy(deepSame(plain.quests, stored.quests))
		end
	)
end
