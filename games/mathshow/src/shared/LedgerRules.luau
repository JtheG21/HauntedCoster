--!strict
-- Pure reconciliation of the TextFit gate's historical row ledger (TASK-0114). No Instances: plain tables in and out.
-- Each viewport must hold exactly the expected split, 781 measured and 320 unmeasured rows, so a wrong split fails even
-- when the total of 1101 is right. TASK-0107 set 669 + 284 = 953; TASK-0134 adds the CLOSE and LEAVE controls: +13 measured
-- (12 CLOSE labels, one on each of the two main-screen states for six player fixtures, and 1 LEAVE label on the watching
-- state) and +13 unmeasured (the same 13 Hit [target] rows). Measured in Studio at f93f7ae on all five viewports.
-- TASK-0151 (682 + 297 = 979 -> 781 + 320 = 1101): +99 measured = the level card (LV tag + XP label) on the 10 main
-- renders whose fixture has a level (20), the QUESTS states 21a-21f (4 x 16 + 4 + 5 = 73) and the two toast states over
-- the watching screen (6); +23 unmeasured = QUESTS 21a-21d (4 x 7: top label, bonus, reset, 4 Hit), 21e (2), 21f (3) and
-- the toast states' LEAVE Hit (2), less the 12 COMING SOON stickers the locked DAILY CHALLENGE slot carried on the main
-- renders. Measured in Studio at 2d6baaa (+ the XP label 6 px left) on all five viewports.

local LedgerRules = {}

LedgerRules.ExpectedMeasured = 781
LedgerRules.ExpectedUnmeasured = 320
LedgerRules.ExpectedPerViewport = LedgerRules.ExpectedMeasured + LedgerRules.ExpectedUnmeasured -- 1101

export type Counts = { measured: number, unmeasured: number }

export type Result = {
	ok: boolean,
	failures: { string },
	lines: { string },
	unmeasuredTotal: number,
}

-- `counts` maps viewport name to its row counts. `viewports` is the expected viewport list. Failures name the viewport and
-- both counts; a missing viewport and an extra one fail too. Neither input is mutated.
function LedgerRules.reconcile(counts: { [string]: Counts }, viewports: { string }): Result
	local failures: { string } = {}
	local lines: { string } = {}
	local unmeasuredTotal = 0
	local expected: { [string]: boolean } = {}
	for _, name in viewports do
		expected[name] = true
		local c = counts[name]
		if c == nil then
			table.insert(failures, `{name}: missing, no measured or unmeasured count`)
			table.insert(lines, `{name} | MISSING`)
			continue
		end
		unmeasuredTotal += c.unmeasured
		local sum = c.measured + c.unmeasured
		local ok = c.measured == LedgerRules.ExpectedMeasured
			and c.unmeasured == LedgerRules.ExpectedUnmeasured
			and sum == LedgerRules.ExpectedPerViewport
		table.insert(
			lines,
			`{name} | measured {c.measured} + unmeasured {c.unmeasured} = {sum}, expected {LedgerRules.ExpectedMeasured} + {LedgerRules.ExpectedUnmeasured} = {LedgerRules.ExpectedPerViewport} {if ok
				then "OK"
				else "MISMATCH"}`
		)
		if not ok then
			table.insert(
				failures,
				`{name}: measured {c.measured} (expected {LedgerRules.ExpectedMeasured}), unmeasured {c.unmeasured} (expected {LedgerRules.ExpectedUnmeasured}), total {sum} (expected {LedgerRules.ExpectedPerViewport})`
			)
		end
	end
	local extra: { string } = {}
	for name in counts do
		if not expected[name] then
			table.insert(extra, name)
		end
	end
	table.sort(extra)
	for _, name in extra do
		table.insert(failures, `{name}: unexpected viewport`)
		table.insert(lines, `{name} | UNEXPECTED`)
	end
	return { ok = #failures == 0, failures = failures, lines = lines, unmeasuredTotal = unmeasuredTotal }
end

return LedgerRules
