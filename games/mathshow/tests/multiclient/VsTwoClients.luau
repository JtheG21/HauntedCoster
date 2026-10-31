--!strict
-- Studio multi-client scenario (TASK-0104): two real clients through the VS server logic. Run from the Studio Edit data
-- model (see 05 Engineering/Multi-Client Testing.md):
--   StudioTestService:ExecuteMultiplayerTestAsync(2, { scenario = "VsTwoClients", timeout = 150 })
-- It drives the same handlers the remotes call (VsService._test), so it needs the clients only as real Player objects whose
-- remotes receive the messages. Returns { ok, checks = {name = bool}, trace = {...} }.

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

return function(_args: any): any
	local checks: { [string]: boolean } = {}
	local trace: { string } = {}
	local function note(text: string)
		table.insert(trace, string.format("%.1f %s", os.clock() % 1000, text))
	end
	local VsService = require(ServerScriptService.Server.Services.VsService)
	local ProfileService = require(ServerScriptService.Server.Services.ProfileService)
	local T = VsService._test

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
	local joined = waitFor(function()
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
	checks.twoPlayersReady = joined
	if not joined then
		return { ok = false, checks = checks, trace = trace, infra = true }
	end
	local p1, p2 = players[1], players[2]

	-- 1. Cancel: a searching player who cancels is never paired.
	T.join(p1, { mode = "vs" })
	task.wait(0.3)
	T.cancel(p1, nil)
	task.wait(1.2) -- (the action limit is 4 per 10 s per player)
	T.join(p2, { mode = "vs" })
	task.wait(1)
	checks.cancelledPlayerNotPaired = T.matchOf(p1) == nil and T.matchOf(p2) == nil
	T.cancel(p2, nil)
	task.wait(0.3)

	-- 2. Pairing: two searchers get the same match.
	T.join(p1, { mode = "vs" })
	T.join(p2, { mode = "vs" })
	checks.paired = waitFor(function()
		return T.matchOf(p1) ~= nil and T.matchOf(p1) == T.matchOf(p2)
	end, 5)
	local match = T.matchOf(p1)
	if not match then
		return { ok = false, checks = checks, trace = trace }
	end
	note("paired")

	-- 3. Play six questions: both players answer wrong every time, so the match ties 0-0 and goes to sudden death.
	local seatCount = #match.seats
	checks.twoSeats = seatCount == 2
	for q = 1, 6 do
		local ok = waitFor(function()
			return match.phase == "Question" and match.index == q
		end, 12)
		checks["question" .. q] = ok
		if not ok then
			break
		end
		local problem = match.problem
		if problem then
			T.answer(p1, { questionIndex = q, answer = problem.answer + 1 })
			-- a second, valid answer from the same player must not count
			T.answer(p1, { questionIndex = q, answer = problem.answer })
			T.answer(p2, { questionIndex = q, answer = problem.answer + 1 })
			-- an answer for the wrong question index is ignored
			T.answer(p2, { questionIndex = q + 1, answer = problem.answer })
		end
	end
	checks.tieAtZero = waitFor(function()
		return match.phase == "SuddenCountdown" or match.suddenDeath
	end, 15) and match.seats[1].score == 0 and match.seats[2].score == 0
	note("tied, sudden death")

	-- 4. Sudden death: the first correct answer wins. p2 answers correctly, p1 wrongly.
	checks.suddenQuestion = waitFor(function()
		return match.phase == "Question" and match.suddenDeath and match.index == 7
	end, 10)
	local sd = match.problem
	if sd then
		T.answer(p1, { questionIndex = 7, answer = sd.answer + 1 })
		T.answer(p2, { questionIndex = 7, answer = sd.answer })
	end
	checks.matchEnds = waitFor(function()
		return match.over
	end, 15)
	note("match over")

	-- 5. Rematch: both ask inside the window and a fresh match starts with the scores reset.
	T.rematch(p1, nil)
	T.rematch(p2, nil)
	checks.rematchStarts = waitFor(function()
		local m = T.matchOf(p1)
		return m ~= nil and m ~= match and not m.over
	end, 25)
	local second = T.matchOf(p1)
	checks.rematchScoresReset = second ~= nil and second.seats[1].score == 0 and second.seats[2].score == 0
	note("rematch started")

	-- 6. Forfeit: p2 leaves mid-match and the match ends by forfeit for p1.
	if second then
		waitFor(function()
			return second.phase == "Question"
		end, 10)
		p2:Kick("VS test: leaving mid-match")
		checks.forfeit = waitFor(function()
			return second.over and second.forfeited
		end, 8)
	end
	local ok = true
	for _, passed in checks do
		ok = ok and passed
	end
	return { ok = ok, checks = checks, trace = trace }
end
