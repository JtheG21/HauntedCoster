--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ScoringConfig = require(ReplicatedStorage.Shared.ScoringConfig)
local SubmissionConfig = require(ReplicatedStorage.Shared.SubmissionConfig)
local SubmissionRules = require(ReplicatedStorage.Shared.SubmissionRules)

type Context = SubmissionRules.Context

-- A context that accepts: open question 2, participant, never submitted, answered only question 1.
local function ctx(overrides: { [string]: any }?): Context
	local base: { [string]: any } = {
		phase = "Question",
		now = 10,
		questionEndsAt = 20,
		questionIndex = 2,
		isParticipant = true,
		lastSubmitAt = nil,
		answeredIndex = 1,
	}
	if overrides then
		for key, value in overrides do
			base[key] = value
		end
	end
	return (base :: any) :: Context
end

return function(t: TestRunner.T)
	t.test("one case per verdict", function()
		local cases: { { name: string, raw: any, ctx: Context, expected: SubmissionRules.Verdict } } = {
			{ name = "ok", raw = "42", ctx = ctx(), expected = "ok" },
			{ name = "badType", raw = 42, ctx = ctx(), expected = "badType" },
			{ name = "badRange", raw = "4a", ctx = ctx(), expected = "badRange" },
			{ name = "notOpen", raw = "42", ctx = ctx({ phase = "Reveal" }), expected = "notOpen" },
			{ name = "rateLimited", raw = "42", ctx = ctx({ lastSubmitAt = 9.9 }), expected = "rateLimited" },
			{ name = "duplicate", raw = "42", ctx = ctx({ answeredIndex = 2 }), expected = "duplicate" },
		}
		for _, case in cases do
			t.eq((SubmissionRules.evaluate(case.raw, case.ctx)), case.expected, case.name)
		end
	end)

	t.test("ok returns the parsed number", function()
		local verdict, parsed = SubmissionRules.evaluate(" 42 ", ctx())
		t.eq(verdict, "ok")
		t.eq(parsed, 42)
	end)

	t.test("ownership: every non-Question phase and a non-participant are notOpen", function()
		for _, phase in { "Intermission", "Reveal", "Results" } do
			t.eq((SubmissionRules.evaluate("42", ctx({ phase = phase }))), "notOpen", phase)
		end
		t.eq((SubmissionRules.evaluate("42", ctx({ isParticipant = false }))), "notOpen", "non-participant")
	end)

	t.test("non-string types are badType", function()
		for _, raw in { 42, true, {}, { "42" } } :: { any } do
			t.eq((SubmissionRules.evaluate(raw, ctx())), "badType", typeof(raw))
		end
		t.eq((SubmissionRules.evaluate(nil, ctx())), "badType", "nil")
	end)

	t.test("precedence: the earlier stage wins", function()
		t.eq((SubmissionRules.evaluate(42, ctx({ isParticipant = false }))), "badType", "non-string + non-participant")
		t.eq((SubmissionRules.evaluate("abc", ctx({ phase = "Reveal" }))), "badRange", "malformed + wrong phase")
		t.eq(
			(SubmissionRules.evaluate("42", ctx({ phase = "Reveal", lastSubmitAt = 9.9 }))),
			"notOpen",
			"wrong phase + rate-limited"
		)
		t.eq(
			(SubmissionRules.evaluate("42", ctx({ lastSubmitAt = 9.9, answeredIndex = 2 }))),
			"rateLimited",
			"rate-limited + duplicate"
		)
	end)

	t.test("range boundary: raw length cap", function()
		local atCap = string.rep(" ", ScoringConfig.RawLengthCap - 1) .. "7"
		local overCap = string.rep(" ", ScoringConfig.RawLengthCap) .. "7"
		t.eq((SubmissionRules.evaluate(atCap, ctx())), "ok", "length at cap")
		t.eq((SubmissionRules.evaluate(overCap, ctx())), "badRange", "length over cap")
	end)

	t.test("range boundary: digit cap", function()
		t.eq((SubmissionRules.evaluate(string.rep("9", ScoringConfig.DigitCap), ctx())), "ok", "digits at cap")
		t.eq(
			(SubmissionRules.evaluate(string.rep("9", ScoringConfig.DigitCap + 1), ctx())),
			"badRange",
			"digits over cap"
		)
	end)

	t.test("rate limit boundary: exactly the interval apart is ok", function()
		local last = 10
		local interval = SubmissionConfig.MinSubmitIntervalSeconds
		t.eq((SubmissionRules.evaluate("42", ctx({ lastSubmitAt = last, now = last + interval }))), "ok", "at interval")
		t.eq(
			(SubmissionRules.evaluate("42", ctx({ lastSubmitAt = last, now = last + interval * 0.99 }))),
			"rateLimited",
			"just under interval"
		)
	end)

	t.test("deadline boundary: open through the grace, closed after", function()
		local endsAt = 20
		local grace = SubmissionConfig.LateGraceSeconds
		t.eq((SubmissionRules.evaluate("42", ctx({ now = endsAt }))), "ok", "at deadline")
		t.eq((SubmissionRules.evaluate("42", ctx({ now = endsAt + grace }))), "ok", "last open instant")
		t.eq((SubmissionRules.evaluate("42", ctx({ now = endsAt + grace + 0.001 }))), "notOpen", "after grace")
	end)

	t.test("duplicate only for the current question", function()
		t.eq((SubmissionRules.evaluate("42", ctx({ answeredIndex = 2 }))), "duplicate", "same index")
		t.eq((SubmissionRules.evaluate("42", ctx({ answeredIndex = 1 }))), "ok", "older index")
		t.eq((SubmissionRules.evaluate("42", ctx({ answeredIndex = 0 }))), "ok", "never answered")
	end)

	t.test("property: only ok returns a number", function()
		local inputs: { { raw: any, ctx: Context } } = {
			{ raw = "42", ctx = ctx() },
			{ raw = 42, ctx = ctx() },
			{ raw = "x", ctx = ctx() },
			{ raw = string.rep("1", 40), ctx = ctx() },
			{ raw = "42", ctx = ctx({ phase = "Results" }) },
			{ raw = "42", ctx = ctx({ now = 30 }) },
			{ raw = "42", ctx = ctx({ isParticipant = false }) },
			{ raw = "42", ctx = ctx({ lastSubmitAt = 10 }) },
			{ raw = "42", ctx = ctx({ answeredIndex = 2 }) },
		}
		for i, input in inputs do
			local verdict, parsed = SubmissionRules.evaluate(input.raw, input.ctx)
			if verdict == "ok" then
				t.truthy(typeof(parsed) == "number", `case {i}: ok without a number`)
			else
				t.eq(parsed, nil, `case {i}: {verdict} returned a number`)
			end
		end
	end)

	t.test("lastSubmitAt advances only on ok and duplicate; replies skip badType and rateLimited", function()
		local advances = { ok = true, duplicate = true }
		local silent = { badType = true, rateLimited = true }
		for _, verdict in { "ok", "badType", "badRange", "notOpen", "rateLimited", "duplicate" } :: { any } do
			t.eq(SubmissionRules.advancesRateLimit(verdict), advances[verdict] == true, `advances {verdict}`)
			t.eq(SubmissionRules.sendsReply(verdict), silent[verdict] ~= true, `replies {verdict}`)
		end
	end)

	t.test("rejectThrottled: rejections inside the reply interval are dropped, ok never is", function()
		local last = 10
		local interval = SubmissionConfig.RejectReplyIntervalSeconds
		for _, verdict in { "badType", "badRange", "notOpen", "rateLimited", "duplicate" } :: { any } do
			t.eq(SubmissionRules.rejectThrottled(verdict, last, nil), false, `{verdict} first rejection`)
			t.eq(SubmissionRules.rejectThrottled(verdict, last + interval * 0.5, last), true, `{verdict} inside`)
			t.eq(SubmissionRules.rejectThrottled(verdict, last + interval, last), false, `{verdict} at interval`)
		end
		t.eq(SubmissionRules.rejectThrottled("ok", last, last), false, "ok inside interval")
	end)
end
