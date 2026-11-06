--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuConfig = require(ReplicatedStorage.Shared.MenuConfig)
local ProfileRules = require(ReplicatedStorage.Shared.ProfileRules)

local NAN = 0 / 0

local NOW = 1_800_000_000
local WEEK = 604800

local function valid(): { [string]: any }
	return { music = 3, sfx = 4, reducedMotion = true, colorBlind = false, haptics = true }
end

local WINDOW = 900
local SKEW = 300

local function op(sessionId: string, seq: number, delta: number): ProfileRules.SaveOp
	return { sessionId = sessionId, seq = seq, glyphsDelta = delta, createdAt = 0 }
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
		local out = ProfileRules.migrate({ version = 1, quests = { a = 1 }, flag = true })
		t.eq(out.flag, true)
		t.eq(out.quests.a, 1)
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
		-- And a replay against the value this op itself committed is acknowledged, not credited.
		local replay = plan(first, saveOp)
		t.eq(replay.tag, "acknowledged")
		t.eq((replay.write :: any).glyphsLifetime, 15)
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
		local ack = plan(stored, op("s", 1, 5), { ambiguous = true, patch = { bestRank = 6 } })
		t.eq(ack.tag, "acknowledged")
		local written = ack.write :: any
		t.eq(written.glyphsLifetime, 15)
		t.eq(written.bestRank, 6, "idempotent fields are still overlaid")
		t.eq(written.applied.s.seq, 1)
		t.eq(written.applied.old, nil, "acknowledging prunes aged receipts")
		local lateAck = plan(stored, op("s", 1, 5), { ambiguous = true, elapsed = WINDOW })
		t.eq(lateAck.tag, "acknowledged", "a covering receipt is honoured past the window")
		t.eq(lateAck.write, nil, "but nothing is written")
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
		local final = save(t, ack.write, op2)
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
		local stored = { version = 1, quests = { a = 1 }, flag = true, bestRank = 2 }
		local loaded = ProfileRules.sanitize(ProfileRules.migrate(stored))
		t.eq((loaded :: any).flag, nil, "the in-memory copy is sanitized")
		local written = ProfileRules.merge(stored, ProfileRules.toPatch(loaded)) :: any
		t.eq(written.flag, true)
		t.eq(written.quests.a, 1)
		t.eq(written.bestRank, 2)
		t.eq(written.version, 3)
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
		local newerNow = { version = 4, extra = "must survive", glyphsLifetime = 20 }
		for _, overrides in { {}, { ambiguous = true }, { elapsed = WINDOW } } do
			local refused = plan(newerNow, op("s", 1, 3), overrides)
			t.eq(refused.tag, "newer_schema")
			t.eq(refused.write, nil, "version 4 is refused, so nothing is erased")
		end
		t.eq(newerNow.extra, "must survive")
		t.eq(plan({ version = 99 }, op("s", 1, 3)).tag, "newer_schema")
		local same = save(t, { version = 3, glyphsLifetime = 20 }, op("s", 1, 3), ProfileRules.toPatch(loaded))
		t.eq(same.glyphsLifetime, 23)
		local older = save(t, { version = 1 }, op("s", 1, 3))
		t.eq(older.version, 3)
		local ledger = ProfileRules.takeOp(ProfileRules.credit(ProfileRules.newLedger("s"), 3), false, 0)
		local settled, terminal = ProfileRules.settle(ledger, { kind = "plan", tag = "newer_schema" })
		t.eq(settled.op, nil)
		t.eq((terminal :: any).reason, "newer_schema")
	end)

	t.test("migrate v2 -> v3 adds an empty save log and keeps unknown fields, the total and settings", function()
		local v2: { [string]: any } =
			{ version = 2, glyphsLifetime = 12, settings = valid(), quests = { a = 1 }, flag = true }
		local out = ProfileRules.migrate(v2)
		t.eq(out.version, 3)
		t.eq(typeof(out.applied), "table")
		t.eq(next(out.applied), nil)
		t.eq(out.glyphsLifetime, 12)
		t.eq(out.settings.music, 3)
		t.eq(out.quests.a, 1)
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
		t.eq(written.version, 3)
		t.eq(written.glyphsLifetime, 16)
		t.eq(written.flag, true)
		t.eq(written.quests.a, 1)
		t.eq(written.applied.s.seq, 1)
	end)

	t.test("an unknown settings sub-key survives a save and a known key is updated (TASK-0139 3b)", function()
		local storedSettings = valid()
		storedSettings.futureToggle = "keep me"
		local stored = { version = 3, glyphsLifetime = 1, settings = storedSettings }
		local changed = valid()
		changed.music = 9
		local written = save(t, stored, op("s", 1, 0), { settings = changed :: any })
		t.eq(written.settings.futureToggle, "keep me")
		t.eq(written.settings.music, 9)
		t.eq(written.settings.sfx, 4)
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
			t.eq((ack.write :: any).glyphsLifetime, 9)
			t.eq((ack.write :: any).applied.s.seq, 3, "and is kept")
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
end
