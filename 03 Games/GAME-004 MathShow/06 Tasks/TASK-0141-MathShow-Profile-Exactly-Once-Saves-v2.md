---
id: TASK-0141
title: "MathShow Profile Exactly-Once Saves v2"
type: task
project: GAME-004
status: backlog
priority: high
risk: high
owner: claude-code
depends_on: []
branch: task/TASK-0141-profile-exactly-once
related:
  - "[[TASK-0139-MathShow-Profile-Save-Remediation]]"
created: 2026-11-06
updated: 2026-11-06
tags:
  - workflow/task
---

# MathShow Profile Exactly-Once Saves v2

## Goal
Redo the TASK-0139 exactly-once save so over-credit is impossible by construction. TASK-0139 was parked after 2/2 failed revisions: the final Codex audit AUD-20261106-TASK-0139-03 found that receipt expiry and eviction allow a replayed op to double-credit, and that v2 writers can erase v3 receipts.

## Scope
- **In:** the design below, after it passes Codex design review.
- **Out (non-goals):** anything before the design review PASS; publishing, merging, the live experience.
- **Keep unchanged:** to be set in the plan.

## Intake
- **Category → workflow, depth:** DataStore code, deep. Registered by jg 2026-11-06 (row K2), backlog only. Branched from `c54123e` (TASK-0139 rev 2 head).
- **Decisions / open questions:** no plan approval yet. No publish checklist exists in the repo; the plan picks its location.

## Design (pending Codex design review)
- Invariant: never over-credit; under-credit only on an abandoned op (warn).
- RETRY_WINDOW 15 min from op.createdAt (server os.time()); after it the op is abandoned, never retried. Autosave, leave and BindToClose obey it;
  BindToClose gets a bounded retry loop inside the window and the shutdown deadline.
- Receipt TTL 7 days; prune only entries older than TTL.
- Cap 200: may evict only entries older than RETRY_WINDOW; otherwise refuse the write (memory-only + warn).
- v3 cutover: publish checklist step "shut down all servers / migrate to latest update before any v3 writer"; freeze stays until then.
- Specs: window boundary (=, +1 s), past-window never retried, all-young cap refuses, no replay after expiry/eviction; clock skew assumption stated.
- Studio-only hook to shorten the window for an in-engine abandon test; inert in live.

## Acceptance criteria
See `tasks/items/TASK-0141.json`.

## Outcome
