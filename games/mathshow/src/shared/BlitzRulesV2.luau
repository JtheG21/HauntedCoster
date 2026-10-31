--!strict
-- Blitz sprint rules (blueprint section 8): one clock for the whole run, a skip consumes a slot. The prototype's
-- BlitzRules (120 s) is untouched. Pure: the caller supplies event times (`at`, seconds since the run began).
--
-- A run ends after the last slot or when time expires, whichever is first. Events after the end are ignored, so
-- replaying an event stream is idempotent. An event whose `at` is past TotalSeconds does not count: it ends the run
-- as expired at TotalSeconds. `at` is clamped to be finite and not earlier than the previous event; NaN counts as
-- the previous time.

local BlitzConfigV2 = require(script.Parent.BlitzConfigV2)

export type Slot = "correct" | "wrong" | "skipped"
export type Run = { slots: { Slot }, elapsed: number, finished: boolean, expired: boolean }
export type Event =
	{ kind: "submit", correct: boolean, at: number }
	| { kind: "skip", at: number }
	| { kind: "expire", at: number }
export type Summary = { correct: number, wrong: number, skipped: number, unreached: number, elapsed: number }

local BlitzRulesV2 = {}

function BlitzRulesV2.newRun(): Run
	return { slots = {}, elapsed = 0, finished = false, expired = false }
end

local function clampAt(at: any, last: number): number
	if type(at) ~= "number" or at ~= at then
		return last
	end
	return math.max(at, last)
end

-- Returns a new run; the input is never mutated.
function BlitzRulesV2.apply(run: Run, event: Event): Run
	if run.finished then
		return run
	end
	local total = BlitzConfigV2.TotalSeconds
	local at = clampAt(event.at, run.elapsed)
	if event.kind == "expire" or at > total then
		return { slots = run.slots, elapsed = total, finished = true, expired = true }
	end

	local slots = table.clone(run.slots)
	if event.kind == "submit" then
		table.insert(slots, if event.correct == true then "correct" else "wrong")
	elseif event.kind == "skip" then
		table.insert(slots, "skipped")
	else
		return run -- unknown event kind: ignored
	end
	local last = #slots >= BlitzConfigV2.Questions
	return { slots = slots, elapsed = at, finished = last, expired = false }
end

function BlitzRulesV2.summarize(run: Run): Summary
	local s: Summary = { correct = 0, wrong = 0, skipped = 0, unreached = 0, elapsed = run.elapsed }
	for _, slot in run.slots do
		if slot == "correct" then
			s.correct += 1
		elseif slot == "wrong" then
			s.wrong += 1
		else
			s.skipped += 1
		end
	end
	s.unreached = BlitzConfigV2.Questions - #run.slots
	return s
end

-- 1 when `a` is better, -1 when `b` is, 0 when equal: more correct wins, then lower elapsed.
function BlitzRulesV2.compareRuns(a: Run, b: Run): number
	local sa, sb = BlitzRulesV2.summarize(a), BlitzRulesV2.summarize(b)
	if sa.correct ~= sb.correct then
		return if sa.correct > sb.correct then 1 else -1
	end
	if sa.elapsed ~= sb.elapsed then
		return if sa.elapsed < sb.elapsed then 1 else -1
	end
	return 0
end

-- Strictly better only: a tie is not a new best. With no previous run, any run with a correct answer is a best.
function BlitzRulesV2.isNewBest(previous: Run?, current: Run): boolean
	if previous == nil then
		return BlitzRulesV2.summarize(current).correct > 0
	end
	return BlitzRulesV2.compareRuns(current, previous) > 0
end

-- Personal-best key per format and difficulty band; nil for an unknown format or a band that is not a positive integer.
function BlitzRulesV2.bestKey(format: any, band: any): string?
	if format ~= "direct" and format ~= "choice" then
		return nil
	end
	if type(band) ~= "number" or band ~= band or band < 1 or band % 1 ~= 0 or band == math.huge then
		return nil
	end
	return `{format}:band{band}`
end

return BlitzRulesV2
