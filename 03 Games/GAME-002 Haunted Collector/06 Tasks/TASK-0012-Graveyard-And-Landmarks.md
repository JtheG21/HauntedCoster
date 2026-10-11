---
id: TASK-0012
title: Graveyard and Landmarks
type: task
project: GAME-002
status: in_review
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
*Prototype built in one integration commit, `17cb5ae` on `task/TASK-0011-Haunted-Scaffold-And-Player-Data`, which covers TASK-0011 to TASK-0018. The user approved building without per-task gates on 2026-10-11.*
- `scripts/check.sh`: all pass (StyLua, Selene, strict typecheck for both projects, Rojo builds, vault, Python tests).
- Unit specs: 37/37 pass headless ([[TEST-20261011-01]]). Server smoke in Run mode: clean.
- *(Superseded below: FullLoop has since run, see revision 1.)*

### Revision 1 (with TASK-0011, `5878f6d`, merged in PR #2)
- [[TEST-20261011-03]] real-client walk-through (replaces the roblox-map prover, [[ADR-0006-M1-Tuning-And-Scope-Decisions]]) and [[TEST-20261011-04]]: FullLoop 56/56, Reachability 11/11. DPadUp light toggle added.

### Revision 2 (`task/TASK-0012-Graveyard-And-Landmarks`, last allowed revision)
- **F2 (AC2):** [[TEST-20261011-05]]: dark Mausoleum Hollow captures with the light on and off, F / HUD button / virtual gamepad toggles. DPadUp turned out to be reserved by Roblox, so the gamepad toggle moved to **DPadDown** (verified). Not run: a physical controller, a touch device, a human readability verdict.
- **F3:** the HUD Light label follows every toggle (`Hud.setLight`).
- **F4:** the crypt check now runs every 0.25 s instead of 1 s. **Accepted M1 risk:** the gate opens on the client for players who meet the requirement, so a modified client can step inside for up to 0.25 s before the server moves it out. Nothing can be captured in that window that the server doesn't also gate (`CaptureService` checks `cryptOpen` for gated-zone monsters).
- **N1:** Reachability adds gate-open positive controls (Crypt `Success` once open; shortcut 6 waypoints once open): **14/14**. Stuck-pocket checking is still covered only by the walk-through.
- **N2:** crypt ejection calls `CaptureService.noteTeleport` first. FullLoop 56/56 after the change.
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0012-01]]: fail, revision 1
- [[AUD-20261011-TASK-0012-02]]: fail (1 major: AC2 evidence), revision 2

## Outcome
*(after merge: result, lessons, follow-ups)*
