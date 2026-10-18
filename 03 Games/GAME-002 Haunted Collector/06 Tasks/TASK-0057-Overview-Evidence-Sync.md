---
id: TASK-0057
title: "Overview Evidence Sync"
type: task
project: GAME-002
status: proposed
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
- [ ] AC1 Latest evidence and Next lines match the current spec count and the queue.
- [ ] AC2 TASK-0053 to TASK-0056 appear in the task table with outcomes, linked to their notes.
- [ ] AC3 `scripts/check.sh` and `validate_vault.py` pass; usage recorded as above; no audit (Light tier).

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** none (docs only).

## Risks / notes
Never invent evidence: any claim must link a task note, TEST note or command output.

---
## Implementation record

## Audits
*(none: Light tier)*

## Outcome
