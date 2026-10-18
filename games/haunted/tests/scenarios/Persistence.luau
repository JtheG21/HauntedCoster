--!strict
-- Real DataStore persistence (TASK-0019). Needs a published, private place with Studio API access; in an
-- unpublished place the profile is "memory" and every phase fails at the first check.
-- Run the phases in order, each in its own play test:
--   ExecutePlayModeAsync({ scenario = "Persistence", phase = "write" })
--     sets known values, saves, checks a second server can't load the held profile, then kicks the
--     player and checks the leave save released the lock. Returns `fingerprint`.
--   ExecutePlayModeAsync({ scenario = "Persistence", phase = "read", expect = <fingerprint> })
--     checks the rejoined profile matches, then adds 1 coin and ends: the shutdown (BindToClose) save
--     must write it and release the lock (checked from Edit afterwards).
--   ExecutePlayModeAsync({ scenario = "Persistence", phase = "lock" })
--     another server takes the lock: the next save must not write, and the session turns read-only.
--     Afterwards the fake lock is cleared so the next session loads at once.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local PlayerDataService = require(Services.PlayerDataService) :: any
local SessionLockRules = require(ReplicatedStorage.Shared.Rules.SessionLockRules)

local STORE_NAME = "HauntedCollector_Profiles_v1"
local OTHER_JOB = "persistence-test-other-server"

local function sortedKeys(t: any): { string }
	local out = {}
	if type(t) == "table" then
		for k, v in t do
			if v then
				table.insert(out, tostring(k))
			end
		end
	end
	table.sort(out)
	return out
end

-- TASK-0060 cosmetic state, as stable strings.
local function cosmeticsPrint(c: any): { string }
	if type(c) ~= "table" then
		return { "none" }
	end
	local looks = {}
	for uid, look in c.ghostLooks do
		table.insert(looks, `{uid}={look.skin or "-"}/{look.aura or "-"}`)
	end
	table.sort(looks)
	local placed = {}
	for _, pl in c.placements do
		table.insert(placed, `{pl.id}@{pl.x},{pl.z},{pl.r}`)
	end
	return {
		table.concat(sortedKeys(c.entitlements), ";"),
		table.concat(looks, ";"),
		tostring(c.captureEffect),
		tostring(c.mansionTheme),
		table.concat(placed, ";"),
		table.concat(sortedKeys(c.rewardsClaimed), ";"),
	}
end

-- The saved progress AC1 covers, as a stable JSON string.
local function fingerprint(p: any): string
	local owned = {}
	for _, m in p.owned do
		table.insert(owned, `{m.uid}:{m.species}:{m.variant}`)
	end
	local exhibits = {}
	for _, e in p.exhibits do
		table.insert(exhibits, `{e.slot}={e.uid}`)
	end
	local route = "none"
	if p.route then
		local pts = {}
		for _, pt in p.route.points do
			table.insert(pts, `{pt.x},{pt.z}`)
		end
		local pieces = {}
		for _, piece in p.route.pieces do
			table.insert(pieces, `{piece.i}{piece.kind}`)
		end
		route = table.concat(pts, ";") .. "|" .. table.concat(pieces, ";")
	end
	return HttpService:JSONEncode({
		coins = p.coins,
		speedLevel = p.speedLevel,
		houseTier = p.houseTier,
		owned = owned,
		nextUid = p.nextUid,
		exhibits = exhibits,
		route = route,
		cosmetics = cosmeticsPrint(p.cosmetics),
		caught = sortedKeys(p.journal.caught),
		variants = sortedKeys(p.journal.variants),
		clues = sortedKeys(p.journal.clues),
		flags = sortedKeys(p.flags),
		tutorialStep = p.tutorialStep,
	})
end

return function(args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local function result(extra: { [string]: any }?): { [string]: any }
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		local out: { [string]: any } = { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
		for k, v in (extra or {}) :: { [string]: any } do
			out[k] = v
		end
		return out
	end

	local phase = if type(args) == "table" then args.phase else nil
	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local profile = PlayerDataService.waitFor(player, 60)
	check("profile loaded", profile ~= nil)
	check(
		"profile is saved to DataStores (not memory or read-only)",
		PlayerDataService.persistence(player) == "saved",
		PlayerDataService.persistence(player)
	)
	if not profile or PlayerDataService.persistence(player) ~= "saved" then
		return result({ memoryReason = PlayerDataService.memoryReason() })
	end
	local store = DataStoreService:GetDataStore(STORE_NAME)
	local key = `p_{player.UserId}`
	local jobId = if game.JobId ~= "" then game.JobId else "studio"
	local function stored(): any
		local ok, rec = pcall(function()
			return store:GetAsync(key)
		end)
		return if ok then rec else nil
	end
	local function waitSaved(pred: (any) -> boolean, seconds: number): any
		local deadline = os.clock() + seconds
		local rec = stored()
		while not (type(rec) == "table" and pred(rec)) and os.clock() < deadline do
			task.wait(1)
			rec = stored()
		end
		return rec
	end

	if phase == "write" then
		local loaded = fingerprint(profile)
		-- A fresh coin value each run, so the save can't pass on what an earlier run left behind.
		local coins = 4000 + math.random(1, 999)
		if coins == profile.coins then
			coins += 1
		end
		-- TEST SHORTCUT: write known values straight into the profile (no purchases or captures).
		PlayerDataService.update(player, function(p: any)
			p.coins = coins
			p.speedLevel = 2
			p.houseTier = 1
			p.owned = {
				{ uid = "m1", species = "Wisp", variant = "Normal", acquiredAt = os.time() },
				{ uid = "m2", species = "Hound", variant = "Spectral", acquiredAt = os.time() },
			}
			p.nextUid = 3
			p.exhibits = { { slot = 1, uid = "m2" } }
			p.route = {
				points = { { x = 10, z = 20 }, { x = 30, z = 40 }, { x = 50, z = 20 } },
				pieces = { { i = 2, kind = "ScareArch" } },
			}
			p.journal.clues = { Angel = true }
			p.flags.onboarded = true
			p.flags.routeCustom = true
			p.tutorialStep = 7
			-- TASK-0060: IDs the shipped (empty) catalog doesn't list, so this also proves unknown entitlements
			-- and their selections survive a real save and rejoin.
			p.cosmetics = {
				entitlements = { T60Skin = true, T60Aura = true, T60Fx = true, T60Theme = true, T60Lamp = true },
				ghostLooks = { m1 = { skin = "T60Skin", aura = "T60Aura" }, m2 = { aura = "T60Aura" } },
				captureEffect = "T60Fx",
				mansionTheme = "T60Theme",
				placements = { { id = "T60Lamp", x = 4, z = -6, r = 90 } },
				rewardsClaimed = { T60Reward = true },
			}
		end)
		check("the test values differ from what loaded", fingerprint(profile) ~= loaded)
		PlayerDataService.saveNow(player)
		local rec = waitSaved(function(r)
			return type(r.profile) == "table" and r.profile.coins == coins
		end, 20)
		check(
			"the save reached the DataStore",
			type(rec) == "table" and type(rec.profile) == "table" and rec.profile.coins == coins
		)
		check(
			"the session holds the lock",
			type(rec) == "table" and type(rec.lock) == "table" and rec.lock.job == jobId,
			rec and rec.lock and rec.lock.job
		)

		-- AC2: a second server tries to load the held profile with the real UpdateAsync and the same transform.
		local locked, loadedByOther = false, nil
		local ok = pcall(function()
			store:UpdateAsync(key, function(old: any)
				local r
				r, loadedByOther, locked = SessionLockRules.claim(old, OTHER_JOB, os.time(), false)
				return r
			end)
		end)
		check("a second server's load is refused while the lock is held", ok and locked and loadedByOther == nil)
		local after = stored()
		check(
			"the refused load left our lock in place",
			type(after) == "table" and type(after.lock) == "table" and after.lock.job == jobId
		)

		-- AC2: leaving releases the lock (PlayerRemoving save with release).
		player:Kick("Persistence test: leaving")
		local left = waitSaved(function(r)
			return r.lock == nil
		end, 30)
		check("leaving released the lock", type(left) == "table" and left.lock == nil)
		-- The game may move some values on by itself before the leave save (the tutorial advances, sanitize
		-- marks owned species caught), so the rejoin is compared with what the leave save actually wrote.
		local saved = if type(left) == "table" and type(left.profile) == "table" then left.profile else nil
		check(
			"the leave save kept the test values",
			saved ~= nil
				and saved.coins == coins
				and saved.houseTier == 1
				and saved.speedLevel == 2
				and #saved.owned == 2
				and #saved.exhibits == 1
				and saved.route ~= nil
				and saved.journal.clues.Angel == true,
			saved and fingerprint(saved)
		)
		return result({ fingerprint = if saved then fingerprint(saved) else nil, loaded = loaded })
	elseif phase == "read" then
		local got = fingerprint(profile)
		check("every saved value survived leave and rejoin", got == args.expect, got)
		local rec = stored()
		check(
			"the rejoined session took the lock",
			type(rec) == "table" and type(rec.lock) == "table" and rec.lock.job == jobId
		)
		-- For the shutdown check: this coin is only written by the BindToClose save.
		PlayerDataService.update(player, function(p: any)
			p.coins += 1
		end)
		return result({ fingerprint = got, coinsAtEnd = profile.coins })
	elseif phase == "lock" then
		local before = stored()
		local coins0 = type(before) == "table" and type(before.profile) == "table" and before.profile.coins
		-- Another server takes the profile over (as after its 30 s wait).
		local ok = pcall(function()
			store:UpdateAsync(key, function(old: any)
				local r = SessionLockRules.claim(old, OTHER_JOB, os.time(), true)
				return r
			end)
		end)
		check("the other server took the lock", ok)
		PlayerDataService.update(player, function(p: any)
			p.coins = 1
		end)
		PlayerDataService.saveNow(player)
		local deadline = os.clock() + 20
		while PlayerDataService.persistence(player) == "saved" and os.clock() < deadline do
			task.wait(0.5)
		end
		check(
			"the session turned read-only after losing the lock",
			PlayerDataService.persistence(player) == "readonly",
			PlayerDataService.persistence(player)
		)
		local after = stored()
		check(
			"the stale server wrote nothing",
			type(after) == "table" and type(after.profile) == "table" and after.profile.coins == coins0,
			after and after.profile and after.profile.coins
		)
		check(
			"the other server still holds the lock",
			type(after) == "table" and type(after.lock) == "table" and after.lock.job == OTHER_JOB
		)
		-- Cleanup: the "other server" releases its lock so the next session loads without waiting.
		pcall(function()
			store:UpdateAsync(key, function(old: any)
				return SessionLockRules.release(old, OTHER_JOB)
			end)
		end)
		local clean = stored()
		check("cleanup released the fake lock", type(clean) == "table" and clean.lock == nil)
		return result({ coins = coins0 })
	end
	check(`known phase ({tostring(phase)})`, false)
	return result()
end
