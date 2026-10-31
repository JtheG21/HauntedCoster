--!strict
-- Tunables for SubmissionRules. Frozen: never mutate at runtime.

local SubmissionConfig = table.freeze({
	MinSubmitIntervalSeconds = 0.3, -- per player; counted from the last ok or duplicate submission
	-- RoundService keeps Question open this long past the shown deadline (Reveal starts this much later), so a
	-- submission delayed by lag at the buzzer still counts; a late correct answer earns base points only.
	LateGraceSeconds = 0.25,
	RejectReplyIntervalSeconds = 0.3, -- per player; rejected submissions inside this window get no reply or log
})

return SubmissionConfig
