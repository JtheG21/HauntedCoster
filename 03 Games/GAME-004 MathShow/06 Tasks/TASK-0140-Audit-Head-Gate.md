---
id: TASK-0140
title: "Audit verdicts bound to the PR head; done means merged"
type: task
project: GAME-004
status: changes_requested
priority: high
risk: high
owner: claude-code
depends_on: []
branch: task/TASK-0140-audit-head-gate
related:
  - "[[TASK-0138-MathShow-Lifetime-Glyph-Total]]"
created: 2026-11-05
updated: 2026-11-06
tags:
  - workflow/task
---

# Audit verdicts bound to the PR head; done means merged

## Goal
Close the TASK-0138 failure mode in tooling: it was merged with source that changed after its audit PASS, and marked `done` by a command rather than by a verified GitHub merge. An audit verdict is bound to a head, and `done` follows a verified merge.

## Scope
- **In:** `orchestrator.py` (`record-audit`, `approve-merge`, `mark-merged`, `--post-merge`), `scripts/audit_gate.py`, tests, `.github/workflows/audit-gate.yml`, `AGENTS.md`, `docs/workflow/TASKS.md`.
- **Out:** `games/**`, existing audit reports, TASK-0138/0139 files, branch protection or rulesets, merging, recording any audit.

## Intake
- **Category, depth:** workflow tooling that governs DataStore and security merges, deep.
- **Decisions:** rows GATE-01..GATE-06 approved by jg in chat, 2026-11-05.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0140.json`.

## Acceptance criteria
See the task file.

## Tests
- **Automated:** `scripts/check.sh`, `tests/test_orchestrator_gate.py`, `tests/test_audit_gate.py`.

## Outcome
Failed 2/2 attempts. Root cause: the gate trusts data the PR can write (report status fields, tier at first registration, reviewer labels). Superseded by a redesign task (not yet created). Do not merge PR #205.
