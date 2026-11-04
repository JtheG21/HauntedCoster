--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MenuConfig = require(ReplicatedStorage.Shared.MenuConfig)
local ProfileRules = require(ReplicatedStorage.Shared.ProfileRules)

local NAN = 0 / 0

local function valid(): { [string]: any }
	return { music = 3, sfx = 4, reducedMotion = true, colorBlind = false, haptics = true }
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

	t.test("merge only raises the total, so older in-memory data cannot lower it", function()
		local merged = ProfileRules.merge({ version = 2, glyphsLifetime = 30 }, { glyphsLifetime = 10 })
		t.eq(merged.glyphsLifetime, 30)
		t.eq(ProfileRules.merge({ glyphsLifetime = 4 }, { glyphsLifetime = 9 }).glyphsLifetime, 9)
		t.eq(ProfileRules.merge({ glyphsLifetime = 4 }, {}).glyphsLifetime, 4)
		t.eq(ProfileRules.merge({ version = 99 }, { glyphsLifetime = 1 }).version, 99)
		t.eq(ProfileRules.toPatch(ProfileRules.addGlyphs(ProfileRules.defaults(), 2)).glyphsLifetime, 2)
	end)
end
