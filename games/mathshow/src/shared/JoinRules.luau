--!strict
-- Pure rules for joining the Group Battle match (TASK-0100). No Instances, no clock. Nothing here throws on bad input.
-- A player is JOINED once they press JOIN SHOW. They become a PARTICIPANT (can answer, score, appear in standings) only
-- when a match starts with them already joined; joining mid-match means watching until the next match.

local JoinRules = {}

-- Decides participation as a Question opens. Only question 1 admits new participants; later questions keep whoever
-- already is one, so a late joiner can never score in a match already under way.
function JoinRules.participantAt(joined: boolean, questionIndex: number, wasParticipant: boolean): boolean
	if questionIndex == 1 then
		return joined == true
	end
	return wasParticipant == true
end

-- The WATCHING banner shows for a joined player who is not in this match, from the moment their match is under way until
-- the next Intermission starts.
function JoinRules.isWatching(joined: boolean, participant: boolean, phase: string): boolean
	return joined == true and participant ~= true and phase ~= "Intermission"
end

-- JoinShow carries no data: FireServer() with nothing, or an empty table. Anything else is rejected.
function JoinRules.validJoin(raw: any): boolean
	if raw == nil then
		return true
	end
	return typeof(raw) == "table" and next(raw) == nil
end

-- ShowState from the server: exactly { joined: boolean, participant: boolean }.
function JoinRules.isValidShowState(raw: any): boolean
	if typeof(raw) ~= "table" then
		return false
	end
	local count = 0
	for key in raw do
		if key ~= "joined" and key ~= "participant" then
			return false
		end
		count += 1
	end
	return count == 2 and typeof(raw.joined) == "boolean" and typeof(raw.participant) == "boolean"
end

return JoinRules
