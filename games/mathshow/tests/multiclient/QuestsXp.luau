--!strict
-- Studio multi-client scenario (TASK-0150): two real clients, each must get only its own QuestState and its own XP. Run from
-- the Studio Edit data model against the PRIVATE test experience only (see 05 Engineering/Multi-Client Testing.md):
--   StudioTestService:ExecuteMultiplayerTestAsync(2, { scenario = "QuestsXp", timeout = 120 })
-- It drives the real hook functions and the QuestService test seam (Studio-only), so it needs the clients only as real
-- Player objects. Returns { ok, checks = {name = bool}, trace = {...} }.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

return function(_args: any): any
	local checks: { [string]: boolean } = {}
	local trace: { string } = {}
	local function note(text: string)
		table.insert(trace, string.format("%.1f %s", os.clock() % 1000, text))
	end
	local QuestService: any = require(ServerScriptService.Server.Services.QuestService)
	local ProfileService = require(ServerScriptService.Server.Services.ProfileService)
	local T = QuestService._test

	local function waitFor(condition: () -> boolean, seconds: number): boolean
		local deadline = os.clock() + seconds
		while os.clock() < deadline do
			if condition() then
				return true
			end
			task.wait(0.1)
		end
		return condition()
	end

	local players = Players:GetPlayers()
	checks.twoPlayersReady = waitFor(function()
		players = Players:GetPlayers()
		if #players < 2 then
			return false
		end
		for _, p in players do
			if ProfileService.get(p) == nil then
				return false
			end
		end
		return true
	end, 60)
	if not checks.twoPlayersReady then
		return { ok = false, checks = checks, trace = trace, infra = true }
	end
	local p1, p2 = players[1], players[2]
	local function xpOf(p: Player): number
		local profile = ProfileService.get(p)
		return if profile ~= nil then profile.xp or 0 else -1
	end
	local base1, base2 = xpOf(p1), xpOf(p2)
	note(`baseline xp p1={base1} p2={base2}`)

	-- 1. Three glyph pickups for p1 only: +3 play XP for p1, nothing for p2.
	for _ = 1, 3 do
		QuestService.glyph(p1, QuestService.newId(), "common")
	end
	checks.p1SettledOwnXp = waitFor(function()
		return xpOf(p1) == base1 + 3
	end, 25)
	task.wait(1)
	checks.p2XpUnchanged = xpOf(p2) == base2
	note(`after glyphs xp p1={xpOf(p1)} p2={xpOf(p2)}`)

	-- 2. Each player's last QuestState is built from that player's own profile.
	T.request(p2)
	task.wait(1)
	local s1, s2 = T.lastSent(p1), T.lastSent(p2)
	checks.bothHaveState = s1 ~= nil and s2 ~= nil
	if s1 ~= nil and s2 ~= nil then
		checks.stateXpIsOwn = s1.xp == xpOf(p1) and s2.xp == xpOf(p2)
		checks.p1StateShowsPickups = s1.xp == base1 + 3
		checks.p2StateNotP1 = s2.xp == base2
	end

	-- 3. p2 cannot claim with p1's board identity: p2's own stored board decides, and p1 is untouched.
	local before1 = xpOf(p1)
	if s1 ~= nil and s1.day ~= nil and s1.boardRevision ~= nil and #s1.slots == 3 then
		T.claim(p2, { day = s1.day, slot = 3, boardRevision = s1.boardRevision, generation = s1.slots[3].generation })
	end
	task.wait(8)
	checks.crossClaimDidNotTouchP1 = xpOf(p1) == before1
	checks.crossClaimNoXpForP2 = xpOf(p2) == base2
	-- 4. Attributes are per player and derive from confirmed XP.
	checks.attributesPerPlayer = p1:GetAttribute("Level") ~= nil and p2:GetAttribute("Level") ~= nil
	local ok = true
	for _, passed in checks do
		ok = ok and passed
	end
	return { ok = ok, checks = checks, trace = trace }
end
