--!strict
-- Pure SubmitAnswer validation (AGENTS.md: type -> range -> ownership -> rate limit, then duplicate). No
-- Instances, no clock: the caller passes `now` and the question's deadline on one clock (os.clock()).

local RoundRules = require(script.Parent.RoundRules)
local ScoringConfig = require(script.Parent.ScoringConfig)
local ScoringRules = require(script.Parent.ScoringRules)
local SubmissionConfig = require(script.Parent.SubmissionConfig)

export type Verdict = "ok" | "badType" | "badRange" | "notOpen" | "rateLimited" | "duplicate"

export type Context = {
	phase: RoundRules.Phase,
	now: number,
	questionEndsAt: number,
	questionIndex: number,
	isParticipant: boolean,
	lastSubmitAt: number?,
	answeredIndex: number,
}

local SubmissionRules = {}

-- Returns the first failing stage's verdict, or "ok" with the parsed answer. The number is nil for
-- every verdict except "ok".
function SubmissionRules.evaluate(raw: any, ctx: Context): (Verdict, number?)
	if typeof(raw) ~= "string" then
		return "badType", nil
	end
	-- Length cap before parseAnswer, so no pattern ever sees unbounded client text.
	if #raw > ScoringConfig.RawLengthCap then
		return "badRange", nil
	end
	local parsed = ScoringRules.parseAnswer(raw)
	if parsed == nil then
		return "badRange", nil
	end
	if
		ctx.phase ~= "Question"
		or ctx.now > ctx.questionEndsAt + SubmissionConfig.LateGraceSeconds
		or not ctx.isParticipant
	then
		return "notOpen", nil
	end
	local last = ctx.lastSubmitAt
	if last ~= nil and ctx.now < last + SubmissionConfig.MinSubmitIntervalSeconds then
		return "rateLimited", nil
	end
	if ctx.answeredIndex == ctx.questionIndex then
		return "duplicate", nil
	end
	return "ok", parsed
end

-- Whether this verdict moves the player's lastSubmitAt to now.
function SubmissionRules.advancesRateLimit(verdict: Verdict): boolean
	return verdict == "ok" or verdict == "duplicate"
end

-- Whether the sender gets an AnswerResult. Malformed-type and rate-limited traffic is dropped silently.
function SubmissionRules.sendsReply(verdict: Verdict): boolean
	return verdict ~= "badType" and verdict ~= "rateLimited"
end

-- Whether a rejected (non-ok) submission is dropped with no reply and no log, because the player's last reported
-- rejection (lastRejectAt, same clock as now) is inside RejectReplyIntervalSeconds. An ok verdict is never throttled.
function SubmissionRules.rejectThrottled(verdict: Verdict, now: number, lastRejectAt: number?): boolean
	if verdict == "ok" or lastRejectAt == nil then
		return false
	end
	return now < lastRejectAt + SubmissionConfig.RejectReplyIntervalSeconds
end

return table.freeze(SubmissionRules)
