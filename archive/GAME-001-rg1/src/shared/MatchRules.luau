--!strict
-- Pure match state machine (TASK-0006). MatchService may only change state through `transition`.

local MatchRules = {}

export type State = "Lobby" | "Countdown" | "Course" | "Finale" | "Results"

-- Allowed transitions. Every state can drop back to Lobby (e.g. everyone left).
local ALLOWED: { [string]: { [string]: boolean } } = {
	Lobby = { Countdown = true },
	Countdown = { Course = true, Lobby = true },
	Course = { Finale = true, Lobby = true },
	Finale = { Results = true, Lobby = true },
	Results = { Lobby = true },
}

function MatchRules.isState(value: unknown): boolean
	return typeof(value) == "string" and ALLOWED[value] ~= nil
end

function MatchRules.canTransition(from: string, to: string): boolean
	local targets = ALLOWED[from]
	return targets ~= nil and targets[to] == true
end

-- Returns the new state if allowed, otherwise the old state plus an error reason.
function MatchRules.transition(from: string, to: string): (string, string?)
	if not MatchRules.isState(from) or not MatchRules.isState(to) then
		return from, "unknown_state"
	end
	if not MatchRules.canTransition(from, to) then
		return from, "invalid_transition"
	end
	return to, nil
end

-- Whether players who join now may enter the current match (only before it starts).
function MatchRules.canJoinMatch(state: string): boolean
	return state == "Lobby" or state == "Countdown"
end

-- The course ends when everyone still in the match has finished, or time runs out.
function MatchRules.courseOver(finished: number, inMatch: number, elapsed: number, maxSeconds: number): boolean
	if inMatch <= 0 then
		return true
	end
	return finished >= inMatch or elapsed >= maxSeconds
end

-- Whether a lobby countdown should run (enough eligible players).
function MatchRules.shouldCountdown(eligible: number, minPlayers: number): boolean
	return eligible >= minPlayers
end

return MatchRules
