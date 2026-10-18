--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CaptureRules = require(ReplicatedStorage.Shared.Rules.CaptureRules)
local Monsters = require(ReplicatedStorage.Shared.Config.Monsters)

-- Simulates blind mashing (presses at random times, as fast as the server counts them) and returns the
-- fraction of sessions that end in success.
local function mashRate(tuning: Monsters.CaptureTuning, trials: number, rng: Random): number
	local wins = 0
	for _ = 1, trials do
		local hits, misses = 0, 0
		local t = 0
		local center = CaptureRules.zoneCenter(rng, tuning.zoneWidth)
		local outcome = "miss"
		while outcome == "miss" or outcome == "hit" do
			t += CaptureRules.MinReleaseGap + rng:NextNumber(0, 0.15)
			local hit = CaptureRules.judge(t, tuning.period, center, tuning.zoneWidth, CaptureRules.LatencySlack)
			outcome, hits, misses =
				CaptureRules.applyRelease(hit, hits, misses, tuning.hitsNeeded, tuning.missesAllowed)
			if outcome == "hit" then
				center = CaptureRules.zoneCenter(rng, tuning.zoneWidth)
			end
		end
		if outcome == "success" then
			wins += 1
		end
	end
	return wins / trials
end

return function(t: TestRunner.T)
	t.test("needle is a triangle wave", function()
		t.eq(CaptureRules.needle(0, 2), 0)
		t.eq(CaptureRules.needle(0.5, 2), 0.5)
		t.eq(CaptureRules.needle(1, 2), 1)
		t.eq(CaptureRules.needle(1.5, 2), 0.5)
		t.eq(CaptureRules.needle(2, 2), 0)
	end)

	t.test("zone center keeps the zone on the bar", function()
		local rng = Random.new(1)
		for _ = 1, 200 do
			local c = CaptureRules.zoneCenter(rng, 0.3)
			t.truthy(c - 0.15 >= 0 and c + 0.15 <= 1, "zone off bar")
		end
	end)

	t.test("the drawn zone matches the judged window and stays on the bar", function()
		for rarity, tuning in Monsters.Capture do
			local drawn = CaptureRules.judgedWidth(tuning.zoneWidth, tuning.period, CaptureRules.LatencySlack)
			-- Measure the judged window on the rising half of the needle (position = 2t / period).
			local lo, hi = math.huge, -math.huge
			local step = tuning.period / 4000
			local tt = 0.05 * tuning.period
			while tt < 0.45 * tuning.period do
				if CaptureRules.judge(tt, tuning.period, 0.5, tuning.zoneWidth, CaptureRules.LatencySlack) then
					local pos = CaptureRules.needle(tt, tuning.period)
					lo, hi = math.min(lo, pos), math.max(hi, pos)
				end
				tt += step
			end
			t.truthy(math.abs((hi - lo) - drawn) < 0.002, `{rarity}: judged {hi - lo}, drawn {drawn}`)
			-- The widest drawn zone at the extreme centres still fits on the bar.
			local half = tuning.zoneWidth / 2
			t.truthy(half + 0.08 - drawn / 2 >= -1e-9, `{rarity}: drawn zone can leave the bar`)
		end
	end)

	t.test("judge hits inside the zone and misses outside", function()
		-- period 2: needle = t for t in [0,1]
		t.eq(CaptureRules.judge(0.5, 2, 0.5, 0.2, 0), true)
		t.eq(CaptureRules.judge(0.2, 2, 0.5, 0.2, 0), false)
		-- latency slack forgives a slightly early press
		t.eq(CaptureRules.judge(0.33, 2, 0.5, 0.2, 0.09), true)
		t.eq(CaptureRules.judge(0.3, 2, 0.5, 0.2, 0.05), false)
	end)

	t.test("mashing is unreliable and gets harder with rarity", function()
		local rng = Random.new(42)
		local c = mashRate((Monsters.Capture :: any).Common, 3000, rng)
		local u = mashRate((Monsters.Capture :: any).Uncommon, 3000, rng)
		local r = mashRate((Monsters.Capture :: any).Rare, 3000, rng)
		t.truthy(c < 0.65, `common mash rate {c}`)
		t.truthy(u < c, `uncommon {u} >= common {c}`)
		t.truthy(r < u, `rare {r} >= uncommon {u}`)
		t.truthy(r < 0.2, `rare mash rate {r}`)
	end)

	t.test("a well-timed press always hits", function()
		for _, rarity in { "Common", "Uncommon", "Rare" } do
			local tuning = (Monsters.Capture :: any)[rarity]
			local rng = Random.new(7)
			for _ = 1, 50 do
				local center = CaptureRules.zoneCenter(rng, tuning.zoneWidth)
				-- needle rises 0 -> 1 over half a period, so it reaches `center` at center * period / 2
				local tHit = center * tuning.period / 2
				t.eq(CaptureRules.judge(tHit, tuning.period, center, tuning.zoneWidth, 0), true, rarity)
			end
		end
	end)

	t.test("release outcomes", function()
		local o, h, m = CaptureRules.applyRelease(true, 0, 0, 1, 3)
		t.eq(o, "success")
		t.eq(h, 1)
		o, h, m = CaptureRules.applyRelease(true, 0, 0, 2, 3)
		t.eq(o, "hit")
		o, h, m = CaptureRules.applyRelease(false, 0, 2, 2, 3)
		t.eq(o, "fled")
		t.eq(m, 3)
		o = CaptureRules.applyRelease(false, 0, 0, 2, 3)
		t.eq(o, "miss")
		local _ = h
	end)
	-- Carry speed budget (TASK-0021). Carry walk speed at level 0 is 9.6 studs/s.
	t.test("a carrier walking at the slowed speed stays inside the budget", function()
		local speed = 9.6
		-- 30 s of continuous walking plus a little jitter.
		t.eq(CaptureRules.carryTooFast(speed * 30 * 1.1, 30, speed), false)
		-- Standing still, then walking: still a legal walk.
		t.eq(CaptureRules.carryTooFast(speed * 10, 25, speed), false)
	end)

	t.test("sustained speeding is caught", function()
		local speed = 9.6
		-- Full walk speed (16) instead of the carry speed, for 10 s.
		t.eq(CaptureRules.carryTooFast(16 * 10, 10, speed), true)
	end)

	t.test("alternating bursts are caught by their average", function()
		local speed = 9.6
		local travelled = 0
		local caught = false
		-- 0.25 s ticks alternating 2x and 1x the carry speed (average 1.5x > 1.35x tolerance).
		for i = 1, 160 do
			travelled += speed * 0.25 * (if i % 2 == 0 then 2 else 1)
			if CaptureRules.carryTooFast(travelled, i * 0.25, speed) then
				caught = true
				break
			end
		end
		t.truthy(caught, "alternating speed was never caught")
	end)

	t.test("a teleport to the pen is caught", function()
		local speed = 9.6
		-- 2 s into the carry, 150 studs at once.
		t.eq(CaptureRules.carryTooFast(150, 2, speed), true)
		-- The fixed slack covers a first step, not a jump.
		t.eq(CaptureRules.carryTooFast(CaptureRules.CarrySlackStuds, 0, speed), false)
		t.eq(CaptureRules.carryTooFast(CaptureRules.CarrySlackStuds + 1, 0, speed), true)
	end)

	-- TASK-0038: capture start is refused for every unsafe state, in the server's order, and allowed only
	-- when all of them are clear. The reasons are what the player sees.
	local function clear(): any
		return {
			loaded = true,
			hasPlot = true,
			carrying = false,
			chasing = false,
			inSession = false,
			closing = false,
			owned = 2,
			capacity = 4,
			alive = true,
			fleeing = false,
			pursuing = false,
			startled = false,
			distance = 10,
			maxDistance = 18,
			needsCrypt = false,
			cryptOpen = false,
		}
	end
	t.test("capture start is allowed only when every guard is clear", function()
		t.eq(CaptureRules.startRefusal(clear()), nil)
		local crypt = clear()
		crypt.needsCrypt, crypt.cryptOpen = true, true
		t.eq(CaptureRules.startRefusal(crypt), nil, "crypt monster, crypt open")
		local edge = clear()
		edge.distance = 18
		t.eq(CaptureRules.startRefusal(edge), nil, "exactly at the distance limit")
	end)

	t.test("each unsafe state refuses capture start", function()
		local cases: { { any } } = {
			{
				"not loaded",
				function(f)
					f.loaded = false
				end,
				"Still loading",
			},
			{
				"no plot",
				function(f)
					f.hasPlot = false
				end,
				"You need a home plot first",
			},
			{
				"carrying",
				function(f)
					f.carrying = true
				end,
				"already carrying",
			},
			{
				"chasing",
				function(f)
					f.chasing = true
				end,
				"escaped monster",
			},
			{
				"in a session",
				function(f)
					f.inSession = true
				end,
				"Already capturing",
			},
			{
				"rotation closing",
				function(f)
					f.closing = true
				end,
				"fog",
			},
			{
				"pen full",
				function(f)
					f.owned = 4
				end,
				"pen is full",
			},
			{
				"gone",
				function(f)
					f.alive = false
				end,
				"It's gone",
			},
			{
				"fleeing",
				function(f)
					f.fleeing = true
				end,
				"running from someone",
			},
			{
				"pursuing",
				function(f)
					f.pursuing = true
				end,
				"charging",
			},
			{
				"startled",
				function(f)
					f.startled = true
				end,
				"skittish",
			},
			{
				"too far",
				function(f)
					f.distance = 18.5
				end,
				"Get closer",
			},
			{
				"no character",
				function(f)
					f.distance = nil
				end,
				"Get closer",
			},
			{
				"crypt locked",
				function(f)
					f.needsCrypt = true
				end,
				"Restore your house",
			},
		}
		for _, c in cases do
			local f = clear()
			c[2](f)
			local reason = CaptureRules.startRefusal(f)
			t.eq(reason ~= nil and string.find(reason, c[3], 1, true) ~= nil, true, `{c[1]}: {reason}`)
		end
	end)

	t.test("player-state guards come before monster guards", function()
		local f = clear()
		f.carrying, f.pursuing = true, true
		t.eq(string.find(CaptureRules.startRefusal(f) or "", "already carrying", 1, true) ~= nil, true)
	end)

	t.test("monster guards keep their order: gone, fleeing, pursuing, startled, distance, crypt", function()
		local f = clear()
		f.alive, f.distance, f.needsCrypt = false, nil, true
		t.eq(CaptureRules.startRefusal(f), "It's gone")
		f = clear()
		f.startled, f.distance = true, nil
		t.eq(string.find(CaptureRules.startRefusal(f) or "", "skittish", 1, true) ~= nil, true)
		f = clear()
		f.distance, f.needsCrypt = 30, true
		t.eq(CaptureRules.startRefusal(f), "Get closer")
	end)

	t.test("finisherSeconds: the finisher's length for Rare, nothing for the others", function()
		local Sequence = require(ReplicatedStorage.Shared.Sequence)
		local Finisher = require(ReplicatedStorage.Shared.Config.RareCaptureFinisher)
		t.eq(CaptureRules.finisherSeconds("Rare"), Sequence.duration(Finisher))
		t.truthy(CaptureRules.finisherSeconds("Rare") > 10)
		t.eq(CaptureRules.finisherSeconds("Common"), 0)
		t.eq(CaptureRules.finisherSeconds("Uncommon"), 0)
		t.eq(CaptureRules.finisherSeconds("nonsense"), 0)
		-- every Rare species gets a finisher, and the carry timer grows by exactly its length
		for _, species in Monsters.Species do
			local bonus = CaptureRules.finisherSeconds(species.rarity)
			t.eq(bonus > 0, species.rarity == "Rare", species.id)
		end
	end)
end
