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
end
