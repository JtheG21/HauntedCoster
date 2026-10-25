--!strict
-- Tunables for SubmissionRules. Frozen: never mutate at runtime.

local SubmissionConfig = table.freeze({
	MinSubmitIntervalSeconds = 0.3, -- per player; counted from the last ok or duplicate submission
	LateGraceSeconds = 0.25, -- lag allowance past the question deadline; a late correct answer earns base points
})

return SubmissionConfig
