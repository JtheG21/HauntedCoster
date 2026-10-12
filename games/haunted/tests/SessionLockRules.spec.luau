--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SessionLockRules = require(ReplicatedStorage.Shared.Rules.SessionLockRules)

return function(t: TestRunner.T)
	local now = 1_800_000_000
	local stale = SessionLockRules.StaleSeconds

	t.test("a new player gets an empty record with our lock", function()
		local rec, profile, locked = SessionLockRules.claim(nil, "A", now, false)
		t.eq(locked, false)
		t.eq(profile, nil)
		t.eq((rec :: any).lock.job, "A")
		t.eq((rec :: any).lock.t, now)
	end)

	t.test("a second server can't load a profile another server holds", function()
		local held = { profile = { coins = 9 }, lock = { job = "A", t = now - 10 } }
		local rec, profile, locked = SessionLockRules.claim(held, "B", now, false)
		t.eq(rec, nil)
		t.eq(profile, nil)
		t.eq(locked, true)
		t.eq(held.lock.job, "A")
	end)

	t.test("a stale lock or our own lock can be claimed", function()
		local old = { profile = { coins = 9 }, lock = { job = "A", t = now - stale } }
		local rec, profile, locked = SessionLockRules.claim(old, "B", now, false)
		t.eq(locked, false)
		t.eq((profile :: any).coins, 9)
		t.eq((rec :: any).lock.job, "B")
		local _, _, again = SessionLockRules.claim({ lock = { job = "B", t = now } }, "B", now, false)
		t.eq(again, false)
		local _, _, nearlyStale = SessionLockRules.claim({ lock = { job = "A", t = now - stale + 1 } }, "B", now, false)
		t.eq(nearlyStale, true)
	end)

	t.test("after waiting, a live lock is taken over", function()
		local held = { profile = { coins = 9 }, lock = { job = "A", t = now } }
		local rec, profile, locked = SessionLockRules.claim(held, "B", now, true)
		t.eq(locked, false)
		t.eq((profile :: any).coins, 9)
		t.eq((rec :: any).lock.job, "B")
	end)

	t.test("a released profile loads on the next server", function()
		local rec = SessionLockRules.release({ profile = { coins = 3 }, lock = { job = "A", t = now } }, "A")
		t.eq((rec :: any).lock, nil)
		local _, profile, locked = SessionLockRules.claim(rec, "B", now, false)
		t.eq(locked, false)
		t.eq((profile :: any).coins, 3)
	end)

	t.test("saving keeps the lock; a release save clears it", function()
		local rec, lost = SessionLockRules.save({ lock = { job = "A", t = now - 50 } }, "A", now, { coins = 4 }, false)
		t.eq(lost, false)
		t.eq((rec :: any).profile.coins, 4)
		t.eq((rec :: any).lock.t, now)
		local released = SessionLockRules.save({ lock = { job = "A", t = now } }, "A", now, { coins = 5 }, true)
		t.eq((released :: any).profile.coins, 5)
		t.eq((released :: any).lock, nil)
	end)

	t.test("a server that lost the lock never writes", function()
		local taken = { profile = { coins = 100 }, lock = { job = "B", t = now } }
		local rec, lost = SessionLockRules.save(taken, "A", now, { coins = 1 }, false)
		t.eq(rec, nil)
		t.eq(lost, true)
		t.eq(taken.profile.coins, 100)
		local rec2, lost2 = SessionLockRules.save({ profile = { coins = 100 } }, "A", now, { coins = 1 }, true)
		t.eq(rec2, nil)
		t.eq(lost2, true)
	end)

	t.test("release only clears our own lock", function()
		local theirs = { lock = { job = "B", t = now } }
		t.eq(SessionLockRules.release(theirs, "A"), nil)
		t.eq(theirs.lock.job, "B")
		t.eq(SessionLockRules.release({}, "A"), nil)
		t.eq(SessionLockRules.release(nil, "A"), nil)
	end)
end
