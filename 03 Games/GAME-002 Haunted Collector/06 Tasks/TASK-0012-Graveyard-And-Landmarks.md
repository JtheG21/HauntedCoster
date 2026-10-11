---
id: TASK-0012
title: Graveyard and Landmarks
type: task
project: GAME-002
status: proposed
priority: high
risk: low
owner: executor
milestone: M1
depends_on:
  - TASK-0011
branch: task/TASK-0012-Graveyard-And-Landmarks
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
# TASK-0012: Graveyard and Landmarks

## Goal
A compact, readable, dark graveyard next to the plots, with a flashlight and landmarks that record clues.

## Scope
- **In:** Map spec via `roblox-map` (plan, prove, Luau builder; never its Studio bootstrap); zones Gate path, Old Rows, Mausoleum Hollow, Sealed Crypt (gated); lighting/atmosphere; flashlight tool; home beacon; 4-5 landmarks with investigate prompts -> journal clues + markers; one shortcut unlock.
- **Out:** Monsters; journal UI beyond a minimal clue toast (TASK-0018).

## Files expected to change
- `maps/haunted_graveyard.json`
- `games/haunted/src/server/Services/LandmarkService.luau`
- `games/haunted/src/shared/Config/Zones.luau`
- `games/haunted/src/client/Flashlight.client.luau`

## Acceptance criteria
- [ ] AC1: roblox-map prover report: every zone reachable from the plots, no stuck pockets, Sealed Crypt unreachable while gated
- [ ] AC2: Flashlight works on PC/mobile/gamepad without battery; paths and obstacles readable in the dark section (screenshot evidence)
- [ ] AC3: Investigating a landmark (server distance check, once per player) adds its clue to the profile and a marker; repeat gives no duplicate
- [ ] AC4: Sealed Crypt gate shows its requirement text and opens only when the server says the requirement is met
- [ ] AC5: Shortcut unlocks from its landmark and persists
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
