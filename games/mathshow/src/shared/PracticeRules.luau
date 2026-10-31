--!strict
-- Pure rules for the Practice home and Skill Test intro (TASK-0101). No Instances, no clock: callers pass `now`.
-- Nothing here throws on bad input.

export type State = "unavailable" | "cooldown" | "ready"

local PracticeRules = {}

local function finite(value: any): boolean
	return typeof(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

-- Whole seconds left before the next Skill Test (rounded up so the clock never shows 00:00 while still locked).
function PracticeRules.remaining(retryAt: number?, now: number): number
	if retryAt == nil or not finite(retryAt) or not finite(now) then
		return 0
	end
	return math.max(0, math.ceil((retryAt :: number) - now))
end

-- unavailable = the profile did not load (19a); cooldown = retake clock running (11b); ready = TAKE TEST (11a).
function PracticeRules.state(profileOk: boolean, retryAt: number?, now: number): State
	if not profileOk then
		return "unavailable"
	end
	if PracticeRules.remaining(retryAt, now) > 0 then
		return "cooldown"
	end
	return "ready"
end

-- 12b (GET RANKED) for a player who has never taken or ranked in the test, else 12a (HOW HIGH CAN YOU GO?).
function PracticeRules.isFirstTest(bestRank: number?, lastTestRank: number?): boolean
	return bestRank == nil and lastTestRank == nil
end

return PracticeRules
