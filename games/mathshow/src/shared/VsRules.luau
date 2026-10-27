--!strict
-- Pure VS rules (TASK-0104): strict validation of what the client sends, who wins a sudden-death question, and the
-- queue-state transitions. No Instances, no clock. Nothing here throws on bad input.

local MenuConfig = require(script.Parent.MenuConfig)

local ANSWER_LIMIT = 1e6

local VsRules = {}

-- QueueJoin payload: exactly { mode = "vs" }. (Blitz starts through BlitzStart, Group Battle through JoinShow.)
function VsRules.validQueueJoin(raw: any): boolean
	if typeof(raw) ~= "table" then
		return false
	end
	local count = 0
	for key in raw do
		if key ~= "mode" then
			return false
		end
		count += 1
	end
	return count == 1 and raw.mode == "vs"
end

-- QueueCancel, QueueKeepWaiting, RematchRequest: no data, or an empty table.
function VsRules.validEmpty(raw: any): boolean
	return raw == nil or (typeof(raw) == "table" and next(raw) == nil)
end

-- VsAnswer payload: exactly { questionIndex: integer >= 1, answer: finite integer within +-1e6 }.
function VsRules.parseAnswerPayload(raw: any): (number?, number?)
	if typeof(raw) ~= "table" then
		return nil, nil
	end
	local count = 0
	for key in raw do
		if key ~= "questionIndex" and key ~= "answer" then
			return nil, nil
		end
		count += 1
	end
	if count ~= 2 then
		return nil, nil
	end
	local index, answer = raw.questionIndex, raw.answer
	if typeof(index) ~= "number" or index ~= index or index ~= math.floor(index) or index < 1 or index == math.huge then
		return nil, nil
	end
	if
		typeof(answer) ~= "number"
		or answer ~= answer
		or answer ~= math.floor(answer)
		or answer < -ANSWER_LIMIT
		or answer > ANSWER_LIMIT
	then
		return nil, nil
	end
	return index, answer
end

-- Sudden death: the first correct answer wins. `a` / `b` are each player's elapsed seconds when they answered correctly,
-- or nil (no correct answer). Returns "a", "b", or nil when nobody was right (ask again) or both tied to the instant.
function VsRules.suddenWinner(a: number?, b: number?): string?
	if a ~= nil and b ~= nil then
		if a < b then
			return "a"
		elseif b < a then
			return "b"
		end
		return nil
	end
	if a ~= nil then
		return "a"
	end
	if b ~= nil then
		return "b"
	end
	return nil
end

-- The queue after a wait ran out: keep asking until MenuConfig.VsMaxWaits waits have passed, then give up (19b).
function VsRules.afterTimeout(waits: number): "timeout" | "failed"
	if waits >= MenuConfig.VsMaxWaits then
		return "failed"
	end
	return "timeout"
end

return VsRules
