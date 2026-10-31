---
id: TASK-0096
title: "MathShow Loose Ends"
type: task
project: GAME-004
status: done
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0093
  - TASK-0094
branch: task/TASK-0096-MathShow-Loose-Ends
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow Loose Ends

## Goal
Close the three items left open by TASK-0092 to TASK-0094: Reveal shows who got each question, a failed answer send is visible and retryable, and the Studio tooling works for MathShow.

## Scope
- **In:** (1) `RoundStatePayload.solvers` (Reveal only): `{ userId, name, points }` for participants who answered the question correctly, best first; the Hud shows them under the answer. (2) Hud: when `FireServer` throws, unlock the input and show a send-failed message. (3) `scripts/stamp.sh` and `scripts/studio-preflight.sh` take `--game haunted|mathshow` (default haunted); MathShow gets a gitignored `BuildStamp.txt` synced into `ReplicatedStorage.Shared`.
- **Out:** the 2-player check (waived by jg, [[TASK-0095-MathShow-TwoPlayer-Test]]), scoring changes, persistence, art.
- **Keep unchanged:** scoring and submission rules, the Haunted Collector defaults of both scripts.

## Intake
- **Category → workflow, depth:** Systems and UI, standard → [[Systems Workflow]], [[UI Workflow]].
- **References:** none specific.
- **Decisions / assumptions:** `solvers` is sent only in Reveal, like `answer`; it names only players whose accepted submission for that question was correct, so it reveals nothing before Reveal. The remote payload changes, so sender (`RoundService`), `Net.luau` and receiver (`Hud`) change together. The send-failed path unlocks the question so the player can retry; the server still accepts only one valid submission.

## Acceptance criteria
- [x] AC1 Reveal shows who got the question right (names and points) from a Reveal-only `solvers` field, sender, handler and receiver updated together, no answer leak before Reveal.
- [x] AC2 If `SubmitAnswer:FireServer` throws, the Hud shows a send-failed message and lets the player retry.
- [x] AC3 `stamp.sh` and `studio-preflight.sh` support MathShow (`--game mathshow`) and still default to Haunted Collector.

## Tests
- **Automated:** `scripts/check.sh`, `TYPECHECK_REQUIRED=1 scripts/typecheck.sh`, `python3 -m unittest` hook tests.
- **Studio:** one-player match: Reveal shows the player as a solver on correct questions and "nobody" otherwise; build stamp matches. The FireServer failure path cannot be forced in Studio; covered by pure-rule specs and a code read.

---
## Implementation record
Tier standard. One Sonnet audit: [[AUD-20261025-TASK-0096-01]] pass, 3 nits (the pcall nit and the slot comment were fixed after the audit; the duplicated game-name check was left). Approval came from jg's chat instruction, recorded with `approve --by jg`.

- **Reveal solvers (AC1):** `Net.RoundStatePayload.solvers` (Reveal only, `ScoreEntry` shape); `RoundService` tracks `solvedIndex`/`solvedPoints` per player and sends `solvers()` with the Reveal; `HudRules.solversLabel`, `HudConfig` strings and `MaxSolverNames`, `View.setSolvers`, `Hud.applyState`. Sender, receiver and the type changed together; no other remote changed. 3 new specs (MathShow 75 -> 78).
- **Send failed (AC2):** `Hud.trySubmit` unlocks the question and shows `Strings.SendFailed` when `FireServer` throws.
- **Tooling (AC3):** `scripts/stamp.sh` and `scripts/studio-preflight.sh` take `--game haunted|mathshow`; `.gitignore`, `CLAUDE.md` and both `studio-preflight` skill copies updated.
- **Checks:** `scripts/check.sh` ALL CHECKS PASSED; `TYPECHECK_REQUIRED=1 scripts/typecheck.sh` no type errors. Studio: [[TEST-20261025-05]].
- Not verified: the FireServer failure path in Studio, several solvers on screen, phone landscape.

## Audits

## Outcome
- All three loose ends from TASK-0092 to TASK-0094 are closed (Reveal solvers, send-failed retry, MathShow stamp and preflight). Evidence in the Implementation record and [[TEST-20261025-05]]. 2-player behaviour stays untested (waived).
