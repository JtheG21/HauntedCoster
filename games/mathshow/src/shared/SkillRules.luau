--!strict
-- Pure Skill Test rules (TASK-0102): which kind of question each rank asks, the time limits, how a run advances or ends,
-- how a finished run turns into a result, and strict validation of what the client sends. No Instances, no clock.
-- Nothing here throws on bad input.

local MenuConfig = require(script.Parent.MenuConfig)
local RankRules = require(script.Parent.RankRules)

export type Kind = "integer" | "choice"
export type Run = {
	rank: number, -- the rank being asked now (0..9)
	misses: number, -- consecutive misses; the run ends at MenuConfig.SkillMaxMisses
	cleared: number?, -- highest rank answered correctly so far
	finished: boolean,
}
export type Outcome = {
	kind: string, -- "first" | "up" | "held" (RankRules.Kind)
	best: number, -- the player's best rank after this run
	lastTest: number, -- the rank this run cleared (0 when it cleared nothing)
}

local MAX_RANK = 9
local ANSWER_LIMIT = 1e6

local SkillRules = {}

function SkillRules.kindFor(rank: number): Kind
	if typeof(rank) == "number" and rank >= MenuConfig.SkillChoiceFromRank then
		return "choice"
	end
	return "integer"
end

function SkillRules.timeLimit(kind: Kind): number
	return if kind == "choice" then MenuConfig.SkillChoiceSeconds else MenuConfig.SkillTypedSeconds
end

function SkillRules.newRun(): Run
	return { rank = 0, misses = 0, cleared = nil, finished = false }
end

-- A correct answer clears the rank and moves up (rank 9 ends the run); a miss asks another question of the same rank, and
-- two misses in a row end the run. Returns a new table.
function SkillRules.advance(run: Run, correct: boolean): Run
	if run.finished then
		return { rank = run.rank, misses = run.misses, cleared = run.cleared, finished = true }
	end
	if correct then
		if run.rank >= MAX_RANK then
			return { rank = run.rank, misses = 0, cleared = run.rank, finished = true }
		end
		return { rank = run.rank + 1, misses = 0, cleared = run.rank, finished = false }
	end
	local misses = run.misses + 1
	return { rank = run.rank, misses = misses, cleared = run.cleared, finished = misses >= MenuConfig.SkillMaxMisses }
end

-- A run that ends now (no question left to ask); keeps run construction in one place.
function SkillRules.finish(run: Run): Run
	return { rank = run.rank, misses = run.misses, cleared = run.cleared, finished = true }
end

-- A first test that clears nothing still lands on PLASTIC (rank 0, jg default); a later one that clears nothing holds.
function SkillRules.outcome(previousBest: number?, cleared: number?): Outcome
	local kind = RankRules.resultKind(previousBest, cleared)
	local best = RankRules.newBest(previousBest, cleared) or 0
	return { kind = kind, best = best, lastTest = cleared or 0 }
end

-- The answer to the question on screen, from the client: a finite integer within +-1e6, or a choice index 1..4.
function SkillRules.validAnswer(kind: Kind, raw: any): number?
	if typeof(raw) ~= "number" or raw ~= raw or raw ~= math.floor(raw) then
		return nil
	end
	if kind == "choice" then
		return if raw >= 1 and raw <= 4 then raw else nil
	end
	return if raw >= -ANSWER_LIMIT and raw <= ANSWER_LIMIT then raw else nil
end

-- SkillAnswer payload: exactly { attempt: integer >= 1, answer: number }. Returns the attempt and the raw answer, or nil.
function SkillRules.parseAnswerPayload(raw: any): (number?, number?)
	if typeof(raw) ~= "table" then
		return nil, nil
	end
	local count = 0
	for key in raw do
		if key ~= "attempt" and key ~= "answer" then
			return nil, nil
		end
		count += 1
	end
	if count ~= 2 then
		return nil, nil
	end
	local attempt = raw.attempt
	if typeof(attempt) ~= "number" or attempt ~= attempt or attempt ~= math.floor(attempt) or attempt < 1 then
		return nil, nil
	end
	if typeof(raw.answer) ~= "number" then
		return nil, nil
	end
	return attempt, raw.answer
end

-- SkillStart carries no data: nothing, or an empty table.
function SkillRules.validStart(raw: any): boolean
	return raw == nil or (typeof(raw) == "table" and next(raw) == nil)
end

return SkillRules
