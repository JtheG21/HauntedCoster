---
id: TASK-0013
title: Monsters and Capture
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0011
  - TASK-0012
branch: task/TASK-0013-Monsters-And-Capture
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
# TASK-0013: Monsters and Capture

## Goal
Data-driven roster of 4 monsters with variants, roaming in zones, inspectable, and catchable through one server-validated capture meter.

## Scope
- **In:** MonsterDefs/VariantDefs; part-built placeholder models with distinct silhouettes; EncounterService spawn/roam (CFrame stepper, zone-bound, cap 8); inspect card (name, rarity, variant, est. income); CaptureService meter sessions (server-timed, rarity zones, 3 misses -> flee).
- **Out:** Carry/return/containment (TASK-0014); Bell Wraith clue condition wiring beyond a config flag (TASK-0018).

## Files expected to change
- `games/haunted/src/shared/Config/MonsterDefs.luau`
- `games/haunted/src/shared/Config/VariantDefs.luau`
- `games/haunted/src/shared/Rules/CaptureRules.luau`
- `games/haunted/src/server/Services/EncounterService.luau`
- `games/haunted/src/server/Services/CaptureService.luau`
- `games/haunted/src/client/CaptureUI.client.luau`

## Acceptance criteria
- [ ] AC1: Monsters spawn only inside their zone and stay inside it; variant roll uses config chance and is visibly distinct and labelled
- [ ] AC2: Inspect shows name, rarity, variant and estimated income before capture
- [ ] AC3: Capture success/failure decided on the server from its own timing; forged/early/late/spammed release remotes are rejected (exploit probe recorded)
- [ ] AC4: Difficulty (zone width, speed) comes from rarity config
- [ ] AC5: CaptureRules and variant roll have passing specs
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
