---
id: TASK-0095
title: "MathShow 2-Player Test"
type: task
project: GAME-004
status: changes_requested
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0093
  - TASK-0094
branch: task/TASK-0095-MathShow-TwoPlayer-Test
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow 2-Player Test

## Goal
Run the full vertical slice in Studio with a 2-player local server and file a fix list. Per `games/mathshow/DESIGN.md` "Tasks" item 8: no fixes in this task, only the finding.

## Scope
- **In:** a 2-client local-server Studio playtest of a full match; a written list of bugs/gaps found, each filed as a follow-up task or note.
- **Out (non-goals):** fixing anything found here — that's separate follow-up work.
- **Keep unchanged:** all `games/mathshow/` code.

## Intake
- **Category → workflow, depth:** Systems (verification) → [[Systems Workflow]], standard.
- **References:** `05 Engineering/Multi-Client Testing.md` for the 2-client Studio recipe; `09 Knowledge/` for the Studio test player cap lesson (max 2 Studio clients, build for more).
- **Reuse:** reuse the existing multi-client testing recipe rather than inventing a new one.
- **Decisions / assumptions / open questions:** none; this is a pure verification task.

## Files expected to change
- None in `games/mathshow/` (test-only task). A new TEST note under `07 Playtests/` and, if bugs are found, new follow-up TASK entries in `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 A full match completes with 2 players joined, each submitting at least one answer.
- [x] AC2 A TEST note records what worked, what didn't, and console evidence.
- [ ] AC3 Every finding is filed as a follow-up task (or explicitly deferred with a reason) — no silent gaps.

## Tests
- **Automated:** `scripts/check.sh` (sanity only; this task's evidence is the Studio run).
- **Studio playtest procedure:**
  1. Follow `05 Engineering/Multi-Client Testing.md` with 2 clients against `mathshow.project.json`.
  2. Run one full match end to end; capture console output and screenshots per phase.

## Risks / notes
This is the slice's acceptance gate — don't start Design/implementation on anything past the slice until this is reviewed by jg.

---
## Implementation record
Test-only task, no `games/mathshow/` change. Two attempts at `ExecuteMultiplayerTestAsync(2, ...)` (the original and the one allowed retry) both ended with a single client; see [[TEST-20261025-04]]. AC1 not met (blocked, needs a manual check or a new harness task); AC2 met (TEST note with console evidence); AC3: findings listed in the TEST note, each deferred with a reason because new task IDs come from jg. Reporting state: blocked.

## Audits

## Outcome
