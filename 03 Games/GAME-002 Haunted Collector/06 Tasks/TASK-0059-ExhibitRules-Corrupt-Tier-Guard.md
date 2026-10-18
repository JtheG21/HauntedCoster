---
id: TASK-0059
title: "ExhibitRules Corrupt Tier Guard"
type: task
project: GAME-002
status: in_review
priority: low
risk: low
owner: executor
depends_on: []
branch: task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard
related:
  - "[[Task Intake]]"
  - "[[TASK-0058-SetExhibit-Input-Rules]]"
  - "[[AUD-20261018-TASK-0058-01]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# ExhibitRules Corrupt Tier Guard

## Goal
Close the nit from [[AUD-20261018-TASK-0058-01]]: `ExhibitRules.setRefusal` indexes `Economy.HouseTiers[profile.houseTier + 1]` and errors if the tier is out of range. Return a refusal instead. This is also the first task that logs executor context growth (the PR 92 step).

## Scope
- **In:** `shared/Rules/ExhibitRules.luau` (a range and integer check on the tier before the lookup) and its spec.
- **Out (non-goals):** the same lookups in `ProfileRules` (lines 249 and 297) and elsewhere, `ContainmentService`, the sanitizer. They stay as they are; any wider hardening is a separate task for jg.
- **Keep unchanged:** the order and text of the existing refusals; valid tiers behave exactly as before.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], **Light**
- **References:** none relevant in `10 References/`.
- **Reuse:** the TASK-0058 spec file and style.
- **Decisions / assumptions / open questions:** Assumption: `ProfileRules.sanitize` already clamps `houseTier` on load, so this is defence in depth, not a reachable bug. Open for jg: the refusal text; proposed "Something went wrong. Try again after rejoining." (returned as the failure reason).
- **Measurement:** at start and at close, read `get_usage` (`context.tokensUsed`) and record the difference with `orchestrator.py record-usage` (role executor, note "context growth"). Record the weekly plan percent in the Implementation record. Start in a fresh session so the start reading is small.

## Files expected to change
- `games/haunted/src/shared/Rules/ExhibitRules.luau`, `games/haunted/tests/ExhibitRules.spec.luau`

## Acceptance criteria
- [ ] AC1 `setRefusal` returns a refusal when `houseTier` is not a valid index (negative, fractional, NaN, too large); valid tiers unchanged.
- [ ] AC2 Spec covers those cases plus valid tiers; a negative control (guard removed) fails it.
- [ ] AC3 `scripts/check.sh` green; no audit (Light tier); executor context growth logged.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** none (a pure rule with no behaviour change for valid input).

## Risks / notes
Studio is skipped on the same grounds as other pure-rule changes only if the diff stays inside `ExhibitRules.luau`; if it grows, run FullLoop.

---
## Implementation record
- Branch `task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard`, worktree `~/Desktop/Rg1-wt/TASK-0059`, pushed (no PR yet). Guard in `ExhibitRules.setRefusal` returns "Something went wrong. Try again after rejoining." for non-number, fractional, NaN, negative or too-large `houseTier`; checked after the slot-shape check, before the lookup. Spec case added.
- AC2 negative control: with the guard disabled the new spec failed (index nil with 'exhibitSlots'); restored. AC3: `scripts/check.sh` green (173 specs, 0 failed). No Studio run, diff stays inside the rule and its spec.
- Usage: context `tokensUsed` 84,872 at start, 91,660 at close (+6,788); weekly plan 89% at start and at close. Logged with `record-usage`.

## Audits
*(none: Light tier)*

## Outcome
