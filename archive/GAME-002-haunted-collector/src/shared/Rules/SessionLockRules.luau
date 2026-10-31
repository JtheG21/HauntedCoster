--!strict
-- The record transforms PlayerDataService passes to DataStore UpdateAsync. Pure: no Roblox services, so
-- the session lock and the "never write a newer schema" rule are unit-tested headlessly.
--
-- A stored record is { profile = <Profile>, lock = { job = <JobId>, t = <os.time()> }? }. Each function
-- returns the record to write, or nil to abort the write (UpdateAsync then leaves the key untouched).

local SessionLockRules = {}

-- A lock older than this is from a server that died without releasing it.
SessionLockRules.StaleSeconds = 120

export type Lock = { job: string, t: number }
export type Record = { profile: any, lock: Lock?, [string]: any }

local function asRecord(old: any): Record
	return if type(old) == "table" then old else {}
end

-- True when another server holds a live lock on this record.
function SessionLockRules.heldByOther(old: any, jobId: string, now: number): boolean
	local lock = asRecord(old).lock
	return type(lock) == "table"
		and lock.job ~= jobId
		and type(lock.t) == "number"
		and now - lock.t < SessionLockRules.StaleSeconds
end

-- Load: take the lock and return the stored profile. When another server holds a live lock and we may
-- still wait for it, abort (record nil, locked true). `takeOver` claims it anyway (we waited long enough).
function SessionLockRules.claim(old: any, jobId: string, now: number, takeOver: boolean): (Record?, any, boolean)
	if not takeOver and SessionLockRules.heldByOther(old, jobId, now) then
		return nil, nil, true
	end
	local rec = asRecord(old)
	local profile = rec.profile
	rec.lock = { job = jobId, t = now }
	return rec, profile, false
end

-- Save: write the snapshot only while we still own the lock. A missing or foreign lock means another
-- server took the profile over, so writing would overwrite newer progress (lost = true, record nil).
-- `release` clears the lock in the same write (leave and shutdown saves).
function SessionLockRules.save(
	old: any,
	jobId: string,
	now: number,
	snapshot: any,
	release: boolean
): (Record?, boolean)
	local rec = asRecord(old)
	local lock = rec.lock
	if type(lock) ~= "table" or lock.job ~= jobId then
		return nil, true
	end
	rec.profile = snapshot
	rec.lock = if release then nil else { job = jobId, t = now }
	return rec, false
end

-- Release without writing the profile (read-only sessions, and players who left mid-load). Only our own
-- lock is cleared; anything else aborts so another server's lock is never touched.
function SessionLockRules.release(old: any, jobId: string): Record?
	if type(old) == "table" and type(old.lock) == "table" and old.lock.job == jobId then
		old.lock = nil
		return old
	end
	return nil
end

-- What a failed load means (TASK-0036, AUDIT-003). DataStores are legitimately unavailable only in a
-- development place (Studio, or an unpublished place); there the server runs in memory mode. On a live
-- server the same error text is treated as an outage and retried, so a player whose save exists is never
-- handed a fresh default profile that looks saved.
local UNAVAILABLE = { "publish", "studioaccesstoapisnotallowed", "403", "not allowed", "api services" }

function SessionLockRules.loadFailure(err: string, developmentPlace: boolean): "memory" | "retry"
	local e = string.lower(err)
	for _, needle in UNAVAILABLE do
		if string.find(e, needle, 1, true) then
			return if developmentPlace then "memory" else "retry"
		end
	end
	return "retry"
end

return SessionLockRules
