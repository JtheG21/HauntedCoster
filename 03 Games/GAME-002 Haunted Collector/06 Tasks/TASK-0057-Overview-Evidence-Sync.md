---
id: TASK-0057
title: "Overview Evidence Sync"
type: task
project: GAME-002
status: done
priority: low
risk: low
owner: executor
depends_on: []
branch: task/TASK-0057-Overview-Evidence-Sync
related:
  - "[[Task Intake]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Overview Evidence Sync

## Goal
Bring the GAME-002 `00 Overview` up to date, and use it as the first measured Light task under the tiering in AGENTS.md (Sonnet low effort or Haiku medium effort, no audit subagent).

## Scope
- **In:** the Overview's "Latest evidence" and "Next" lines, and its task table (add TASK-0053 to TASK-0056 with outcomes and links), taken from `tasks/queue.json`, the task notes and existing TEST notes.
- **Out (non-goals):** game code, other notes, rewriting history, any new test runs or claims not already recorded.
- **Keep unchanged:** approved decisions, historical records, the roadmap.

## Intake
- **Category → workflow, depth:** docs / process, **Light**
- **References:** none relevant in `10 References/` (docs-only change).
- **Reuse:** the existing table format in the Overview; facts only from the task notes and TEST notes.
- **Decisions / assumptions / open questions:** Assumption: the spec count is whatever `lune run scripts/lune/specs` prints at the time of the edit (166 on 2026-10-18).
- **Measurement (decision, jg 2026-10-18):** record executor tokens with `orchestrator.py record-usage` if a real figure exists, the model and effort used, tool-call count and any interruptions. No savings are claimed from one task.

## Files expected to change
- `03 Games/GAME-002 Haunted Collector/00 Overview.md`
- the task note itself, `tasks/queue.json`, `tasks/usage-ledger.jsonl`

## Acceptance criteria
- [x] AC1 Latest evidence and Next lines match the current spec count and the queue. Evidence: `lune run scripts/lune/specs` via `check.sh`, 166 passed (2026-10-18).
- [x] AC2 TASK-0053 to TASK-0056 appear in the task table with outcomes, linked to their notes and passing audits. Evidence: the four rows in the Overview table.
- [x] AC3 `scripts/check.sh` and `validate_vault.py` pass; usage recorded as above; no audit (Light tier).

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** none (docs only).

## Risks / notes
Never invent evidence: any claim must link a task note, TEST note or command output.

---
## Implementation record
- Changed `00 Overview.md` only: spec count 125 to 166 (scenario results kept, labelled 2026-10-12), a Next line that names the monetization baseline and the plugin-asset rights check, four table rows for TASK-0053 to TASK-0056 taken from their notes and passing AUD notes, `updated:` bumped.
- `scripts/check.sh` ALL CHECKS PASSED; `validate_vault.py` 0 errors. Stated states: implemented and tested (docs; checks only). No Studio claims added.
- **Measurement (first Light task under the new tiering), honest limits:** done in the long session that drafted the tiering, on Sonnet 5.5, not in a fresh low-effort session; effort level not recorded. No token figure was available to this session, so none was logged (never estimated). No audit subagent ran (Light tier). One avoided misstep: a first edit script failed on a wrong `updated:` value before writing, so nothing was half-applied; the earlier worktree add also collided on a case-insensitive path. Not enough to claim any saving.

## Audits
[[AUD-20261018-TASK-0057-01]]: pass (Sonnet, requested by jg; 27,723 tokens)

## Outcome
Merged with jg's approval (2026-10-18). Measurement: Light path used a Sonnet audit at jg's request (27,723 tokens, 6 tool calls); executor tokens unavailable. Follow-up: TASK-0058 as the Standard data point.
