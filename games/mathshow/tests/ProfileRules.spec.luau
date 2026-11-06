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

local function op(sessionId: string, seq: number, delta: number, patch: ProfileRules.Patch?): ProfileRules.SaveOp
	return { sessionId = sessionId, seq = seq, glyphsDelta = delta, patch = patch or {} }
end

-- planSave's value, failing the test when the write was refused.
local function save(t: TestRunner.T, stored: any, saveOp: ProfileRules.SaveOp, now: number?): (any, boolean)
	local out, already = ProfileRules.planSave(stored, saveOp, now or NOW)
	t.truthy(out ~= nil, "the write was refused")
	return out, already
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
		t.eq(fresher.applied.O.seq, 4, "the other session's entry is kept")
		-- And a replay against the value this op itself committed credits nothing.
		local replay, already = save(t, first, saveOp)
		t.eq(replay.glyphsLifetime, 15)
		t.eq(already, true)
	end)

	t.test("committed then errored: retrying the same op does not credit it again (TASK-0139 3a)", function()
		local stored: any = { version = 3, glyphsLifetime = 15, applied = { s = { seq = 1, at = NOW - 10 } } }
		local retried, already = save(t, stored, op("s", 1, 5))
		t.eq(retried.glyphsLifetime, 15)
		t.eq(already, true)
		t.eq(retried.applied.s.seq, 1)
		local nextOp, nextAlready = save(t, retried, op("s", 2, 2))
		t.eq(nextOp.glyphsLifetime, 17)
		t.eq(nextAlready, false)
		t.eq(nextOp.applied.s.seq, 2)
		t.eq(nextOp.applied.s.at, NOW)
	end)

	t.test("an already-applied op still overlays its idempotent fields", function()
		local stored: any = { version = 3, glyphsLifetime = 15, bestRank = 2, applied = { s = { seq = 3, at = NOW } } }
		local out, already = save(t, stored, op("s", 3, 5, { bestRank = 6 }))
		t.eq(already, true)
		t.eq(out.glyphsLifetime, 15)
		t.eq(out.bestRank, 6)
	end)

	t.test("a lower seq is skipped; the same seq from another session is applied", function()
		local stored: any = { version = 3, glyphsLifetime = 20, applied = { s = { seq = 4, at = NOW } } }
		local lower, lowerAlready = save(t, stored, op("s", 2, 7))
		t.eq(lower.glyphsLifetime, 20)
		t.eq(lowerAlready, true)
		t.eq(lower.applied.s.seq, 4, "the stored seq is not lowered")
		local other, otherAlready = save(t, stored, op("t", 4, 7))
		t.eq(other.glyphsLifetime, 27)
		t.eq(otherAlready, false)
		t.eq(other.applied.t.seq, 4)
		t.eq(other.applied.s.seq, 4)
	end)

	t.test("planSave refuses an op without a valid identity or time", function()
		local stored = { version = 3, glyphsLifetime = 1 }
		local bads: { any } =
			{ op("", 1, 1), op(string.rep("x", 65), 1, 1), op("s", 0, 1), op("s", 1.5, 1), op("s", NAN, 1) }
		for i, bad in bads do
			t.eq(ProfileRules.planSave(stored, bad, NOW), nil, "op " .. i)
		end
		t.eq(ProfileRules.planSave(stored, op("s", 1, 1), NAN), nil, "now NaN")
		t.eq(ProfileRules.planSave(stored, op("s", 1, 1), math.huge), nil, "now inf")
		t.truthy(ProfileRules.planSave(stored, op(string.rep("x", 64), 1, 1), NOW), "64 characters is allowed")
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
		local saveOp = op("s", 1, 3, ProfileRules.toPatch(loaded))
		local newerNow = { version = 4, extra = "must survive", glyphsLifetime = 20 }
		local refused, already = ProfileRules.planSave(newerNow, saveOp, NOW)
		t.eq(refused, nil, "version 4 is refused, so nothing is erased")
		t.eq(already, false)
		t.eq(newerNow.extra, "must survive")
		t.eq(ProfileRules.planSave({ version = 99 }, saveOp, NOW), nil)
		local same = save(t, { version = 3, glyphsLifetime = 20 }, saveOp)
		t.eq(same.glyphsLifetime, 23)
		local older = save(t, { version = 1 }, saveOp)
		t.eq(older.version, 3)
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
		local written = save(t, stored, op("s", 1, 0, { settings = changed :: any }))
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

	t.test("the save log keeps entries exactly 7 days old and drops older ones", function()
		local log = ProfileRules.sanitizeApplied({
			edge = { seq = 1, at = NOW - WEEK },
			old = { seq = 1, at = NOW - WEEK - 1 },
			fresh = { seq = 2, at = NOW },
		}, NOW)
		t.truthy(log.edge, "at == now - 7 days is kept")
		t.eq(log.old, nil, "at < now - 7 days is dropped")
		t.eq(log.fresh.seq, 2)
		local written = save(t, { version = 3, applied = { old = { seq = 1, at = NOW - WEEK - 1 } } }, op("s", 1, 0))
		t.eq(written.applied.old, nil, "a save prunes the stored log")
		t.truthy(
			ProfileRules.sanitizeApplied({ old = { seq = 1, at = 0 } }, nil).old,
			"without now nothing is aged out"
		)
	end)

	t.test("the save log is capped at 200, oldest first, keeping the op being written", function()
		local raw = {}
		for i = 1, 201 do
			raw["s" .. i] = { seq = 1, at = NOW - 1000 + i } -- s1 is the oldest
		end
		local log = ProfileRules.sanitizeApplied(raw, NOW)
		local count = 0
		for _ in log do
			count += 1
		end
		t.eq(count, 200)
		t.eq(log.s1, nil, "the oldest entry is dropped")
		t.truthy(log.s2)
		t.truthy(log.s201)
		local full = {}
		for i = 1, 200 do
			full["s" .. i] = { seq = 1, at = NOW + 50 } -- clock skew: all newer than this server's now
		end
		local written = save(t, { version = 3, applied = full }, op("me", 1, 1))
		count = 0
		for _ in written.applied do
			count += 1
		end
		t.eq(count, 200)
		t.truthy(written.applied.me, "the op just written is never the one capped away")
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
