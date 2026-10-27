--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = require(ReplicatedStorage.Shared.BlitzRulesV2)
local Config = require(ReplicatedStorage.Shared.BlitzConfigV2)

local function play(events: { Rules.Event }): Rules.Run
	local run = Rules.newRun()
	for _, e in events do
		run = Rules.apply(run, e)
	end
	return run
end

local function answers(n: number, correct: boolean, step: number): { Rules.Event }
	local out: { Rules.Event } = {}
	for i = 1, n do
		out[i] = { kind = "submit", correct = correct, at = i * step }
	end
	return out
end

return function(t: TestRunner.T)
	t.test("ten correct answers inside the clock finish the run at the last slot", function()
		local run = play(answers(10, true, 0.9))
		local s = Rules.summarize(run)
		t.eq(run.finished, true)
		t.eq(run.expired, false)
		t.eq(s.correct, 10)
		t.eq(s.unreached, 0)
		t.eq(s.elapsed, 9)
	end)

	t.test("a skip consumes a slot", function()
		local run = play({
			{ kind = "submit", correct = true, at = 1 },
			{ kind = "skip", at = 2 },
			{ kind = "submit", correct = false, at = 3 },
		})
		local s = Rules.summarize(run)
		t.eq(s.correct, 1)
		t.eq(s.skipped, 1)
		t.eq(s.wrong, 1)
		t.eq(s.unreached, Config.Questions - 3)
		t.eq(run.finished, false)
	end)

	t.test("expire ends the run at TotalSeconds with the rest unreached", function()
		local run = play({ { kind = "submit", correct = true, at = 1 }, { kind = "expire", at = 10 } })
		local s = Rules.summarize(run)
		t.eq(run.expired, true)
		t.eq(s.elapsed, Config.TotalSeconds)
		t.eq(s.unreached, 9)
	end)

	t.test("an event past the clock does not count and expires the run", function()
		local run =
			play({ { kind = "submit", correct = true, at = 1 }, { kind = "submit", correct = true, at = 10.5 } })
		t.eq(Rules.summarize(run).correct, 1)
		t.eq(run.expired, true)
		t.eq(run.elapsed, Config.TotalSeconds)
	end)

	t.test("an event exactly at TotalSeconds still counts", function()
		local run = play({ { kind = "submit", correct = true, at = Config.TotalSeconds } })
		t.eq(Rules.summarize(run).correct, 1)
		t.eq(run.expired, false)
	end)

	t.test("events after the run ends are ignored and apply never mutates its input", function()
		local run = play(answers(10, true, 0.5))
		t.eq(Rules.apply(run, { kind = "skip", at = 6 }), run)
		local fresh = Rules.newRun()
		Rules.apply(fresh, { kind = "skip", at = 1 })
		t.eq(#fresh.slots, 0)
		local expired = play({ { kind = "expire", at = 3 } })
		t.eq(Rules.apply(expired, { kind = "submit", correct = true, at = 4 }), expired)
	end)

	t.test("non-monotonic and NaN times are clamped", function()
		local run = play({
			{ kind = "submit", correct = true, at = 4 },
			{ kind = "submit", correct = true, at = 2 },
			{ kind = "submit", correct = true, at = 0 / 0 },
		})
		t.eq(run.elapsed, 4)
		t.eq(Rules.summarize(run).correct, 3)
	end)

	t.test("compareRuns: more correct wins, then lower elapsed", function()
		local fast = play({ { kind = "submit", correct = true, at = 2 }, { kind = "submit", correct = true, at = 4 } })
		local slow = play({ { kind = "submit", correct = true, at = 3 }, { kind = "submit", correct = true, at = 6 } })
		local one = play({ { kind = "submit", correct = true, at = 1 } })
		t.eq(Rules.compareRuns(fast, one), 1)
		t.eq(Rules.compareRuns(one, fast), -1)
		t.eq(Rules.compareRuns(fast, slow), 1)
		t.eq(Rules.compareRuns(slow, fast), -1)
		t.eq(Rules.compareRuns(fast, fast), 0)
	end)

	t.test("isNewBest is strict: a tie is not a new best", function()
		local a = play({ { kind = "submit", correct = true, at = 2 } })
		local b = play({ { kind = "submit", correct = true, at = 2 } })
		local better = play({ { kind = "submit", correct = true, at = 1 } })
		t.eq(Rules.isNewBest(a, b), false)
		t.eq(Rules.isNewBest(a, better), true)
		t.eq(Rules.isNewBest(better, a), false)
	end)

	t.test("first run is a best only when something was correct", function()
		t.eq(Rules.isNewBest(nil, play({ { kind = "submit", correct = true, at = 1 } })), true)
		t.eq(Rules.isNewBest(nil, play({ { kind = "submit", correct = false, at = 1 } })), false)
		t.eq(Rules.isNewBest(nil, Rules.newRun()), false)
	end)

	t.test("bestKey is per format and difficulty band", function()
		t.eq(Rules.bestKey("direct", 2), "direct:band2")
		t.eq(Rules.bestKey("choice", 1), "choice:band1")
		t.eq(Rules.bestKey("essay", 1), nil)
		t.eq(Rules.bestKey("direct", 0), nil)
		t.eq(Rules.bestKey("direct", 1.5), nil)
		t.eq(Rules.bestKey("direct", 0 / 0), nil)
		t.eq(Rules.bestKey("direct", "2"), nil)
	end)
end
