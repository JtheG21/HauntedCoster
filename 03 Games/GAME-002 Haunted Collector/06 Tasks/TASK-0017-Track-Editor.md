---
id: TASK-0017
title: Track Editor
type: task
project: GAME-002
status: proposed
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0015
  - TASK-0016
branch: task/TASK-0017-Track-Editor
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# TASK-0017: Track Editor

## Goal
A simple cross-platform control-point editor that lets players make a genuine route choice, validated and saved by the server.

## Scope
- **In:** Editor mode UI (add/select/move/delete, preview, Confirm/Cancel/Exit; touch, mouse, gamepad); 2 special pieces; exhibit-range preview; server validation and persistence.
- **Out:** Branching, physics, free building placement.

## Files expected to change
- `games/haunted/src/client/TrackEditor.client.luau`
- `games/haunted/src/shared/Rules/TrackRules.luau`
- `games/haunted/src/server/Services/TrainService.luau`

## Acceptance criteria
- [ ] AC1: Editor only opens with the tier-1 unlock (server-checked)
- [ ] AC2: Points can be added, moved and removed with mouse and touch; preview updates
- [ ] AC3: Server rejects too few/many points, length out of range, out-of-plot points, self-overlap; reason shown; last valid route kept
- [ ] AC4: Confirmed route rebuilds track, persists and is restored after rejoin
- [ ] AC5: Route quality modifier stays within config range (spec)
- [ ] AC6: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs named in the ACs (run in a fresh Play session, Server data model).
- **Studio playtest procedure:** in the GAME-002 place, start Play from a fresh profile and walk each AC in order. Record the results in the Implementation record, and say plainly which ones were not run.

## Risks / notes
Planned from [[INBOX-20261011-Haunted-Collector-Brief]]. Blocked on approval of [[ADR-0005-Haunted-Collector-Direction]]. Numbers come from the draft design and are tunable.

---
## Implementation record
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
