---
id: TASK-0009
title: Multi-Client Test Harness
type: task
project: GAME-001
status: done
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0009-Multi-Client-Test-Harness
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[01 Game Design]]"
  - "[[03 Roadmap]]"
---
# TASK-0009: Multi-Client Test Harness

## Goal
Find a **repeatable** way to run 2–4 client tests, because the automated attempt in [[TEST-20261010-02]] was blocked. Candidates: Studio's Test → Server & Clients with a documented manual script; the StudioTestService API; open-source runners (investigate only).

## Scope
- **In:** Research, a short written procedure, and if possible a server-side test script that drives characters (PivotTo) and asserts outcomes.
- **Out:** Installing new tools without approval.

## Files expected to change
- `tests/luau/multiclient/README.md` (new). **Replaced by** the vault note [[Multi-Client Testing]]
- `tests/luau/multiclient/CollectibleRace.server.luau` (new, optional)

## Acceptance criteria
- [ ] A documented procedure that a human can run in ≤5 min, or an automated method that Claude can run
- [ ] [[TEST-20261010-02]] executed with it (pass or a filed BUG)
- [ ] Any tool needing install is listed for approval, not installed

## Tests
- **Automated:** `scripts/check.sh` plus the new Luau specs (run in Studio: `require(game.TestService.Tests.TestRunner).run()`)
- **Studio playtest procedure:** Run the procedure on TASK-0001 coins (two players, one coin).

## Risks / notes
Follow [[Luau Standards]]: server-authoritative, validate every remote argument, debounce shared state before yielding.

---
## Implementation record
*Executor (Claude Code, main session), 2026-10-10, branch `task/TASK-0009-Multi-Client-Test-Harness`*

**Finding:** Roblox's `StudioTestService:ExecuteMultiplayerTestAsync(numPlayers, args)` (plugin security, up to 8 clients) is callable from the Studio MCP `execute_luau` in Edit mode. It launches a server plus N clients and returns the value the server passes to `EndTest`. **Fully automated, nothing to install.**

**Files changed**
- `src/server/Services/StudioTestHook.luau` (new): runs `TestService.Tests.multiclient.<scenario>` only when `RunService:IsStudio()` and test args carry a scenario. Otherwise a no-op
- `src/server/init.server.luau`: starts the hook (first, before game services)
- `tests/luau/multiclient/CollectibleRace.luau` (new): race plus legit scenario with readiness wait, drop approach and diagnostics (touch trace, drift)
- **Deviation:** the procedure doc is the vault note [[Multi-Client Testing]] (in `05 Engineering/`) instead of `tests/luau/multiclient/README.md`, because Markdown in a Rojo-synced folder isn't useful in Studio and the knowledge belongs in the vault

**Results:** [[TEST-20261010-02]] **passed** in 2 consecutive automated runs (4/4 race rounds exactly 1 reward, 0 duplicates, legit 1/1). Early round-1 misses were diagnosed as a harness readiness artifact ([[LES-0004-Wait-For-Client-Physics]]).

**Check results:** `scripts/check.sh` ALL CHECKS PASSED on the code. **Correction:** commit `6c9ff2d` and the `record-exec` were made while the vault check was failing (a broken link to TEST-20261010-03, which lives on the TASK-0002 branch). The chained command didn't stop on the failure. Fixed in the next commit, and check.sh is green again. Process fix: gate commits on `scripts/check.sh` exit status, not on filtered output.

**Incidents:** `rojo serve` crashed on a branch switch ([[LES-0003-Rojo-Crash-On-Branch-Switch]]). A double test run in one MCP call timed out, and Studio recovered when the session ended.

## Audits
- [[AUD-20261010-TASK-0009-01]]: attempt 1, **pass** (5 minor, 4 nit). Follow-ups are tracked for a hardening task

## Outcome
Merged to `main` on 2026-10-10 (merge approved by jg). Audit attempt 1 pass. Follow-ups in [[TASK-0010-Ability-And-Harness-Hardening]]. The multi-client blocker from M0 is resolved: [[Multi-Client Testing]].
