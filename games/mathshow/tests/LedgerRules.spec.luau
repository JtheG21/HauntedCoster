--!strict
local TestRunner = require(script.Parent.TestRunner)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LedgerRules = require(ReplicatedStorage.Shared.LedgerRules)

local VIEWPORTS = { "844x390", "1920x1080", "phone 812x375" }

local function good(): { [string]: LedgerRules.Counts }
	local c: { [string]: LedgerRules.Counts } = {}
	for _, name in VIEWPORTS do
		c[name] = { measured = 669, unmeasured = 284 }
	end
	return c
end

local function hasFailure(r: LedgerRules.Result, text: string): boolean
	for _, f in r.failures do
		if string.find(f, text, 1, true) then
			return true
		end
	end
	return false
end

return function(t: TestRunner.T)
	t.test("expected counts are 669 + 284 = 953", function()
		t.eq(LedgerRules.ExpectedMeasured, 669)
		t.eq(LedgerRules.ExpectedUnmeasured, 284)
		t.eq(LedgerRules.ExpectedPerViewport, 953)
	end)

	t.test("all-correct counts pass", function()
		local r = LedgerRules.reconcile(good(), VIEWPORTS)
		t.eq(r.ok, true)
		t.eq(#r.failures, 0)
		t.eq(r.unmeasuredTotal, 284 * #VIEWPORTS)
	end)

	t.test("668 + 285 fails: the total is right, the split is not", function()
		local c = good()
		c["1920x1080"] = { measured = 668, unmeasured = 285 }
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(#r.failures, 1)
		t.eq(
			hasFailure(r, "1920x1080: measured 668 (expected 669), unmeasured 285 (expected 284)"),
			true,
			"names viewport and counts"
		)
	end)

	t.test("670 + 283 fails", function()
		local c = good()
		c["phone 812x375"] = { measured = 670, unmeasured = 283 }
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(hasFailure(r, "phone 812x375: measured 670 (expected 669), unmeasured 283 (expected 284)"), true)
	end)

	t.test("both wrong splits across two viewports fail separately", function()
		local c = good()
		c["844x390"] = { measured = 668, unmeasured = 285 }
		c["1920x1080"] = { measured = 670, unmeasured = 283 }
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(#r.failures, 2)
		t.eq(r.unmeasuredTotal, 285 + 283 + 284, "total of unmeasured still sums, which is why per-viewport matters")
	end)

	t.test("a wrong total fails", function()
		local c = good()
		c["844x390"] = { measured = 669, unmeasured = 283 }
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(hasFailure(r, "total 952 (expected 953)"), true)
	end)

	t.test("a missing viewport fails", function()
		local c = good()
		c["1920x1080"] = nil
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(hasFailure(r, "1920x1080: missing"), true)
	end)

	t.test("an extra viewport fails", function()
		local c = good()
		c["?"] = { measured = 0, unmeasured = 1 }
		local r = LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(r.ok, false)
		t.eq(hasFailure(r, "?: unexpected viewport"), true)
	end)

	t.test("inputs are not mutated", function()
		local c = good()
		LedgerRules.reconcile(c, VIEWPORTS)
		t.eq(c["844x390"].measured, 669)
		t.eq(#VIEWPORTS, 3)
	end)
end
