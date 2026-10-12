---
id: TASK-0014
title: Return Trip and Containment
type: task
project: GAME-002
status: approved
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0013
branch: task/TASK-0014-Return-Trip-And-Containment
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
# TASK-0014: Return Trip and Containment

## Goal
Close the core loop: carry the capture home under a timer, secure it, and earn passive income after acclimation.

## Scope
- **In:** Carry state (WalkSpeed x0.7, re-applied on respawn-safe path), return timer HUD, home arrow/beacon; escape on timeout/death (capture returns to graveyard, ADR-0005); secure at own containment pad; owned roster with uid; acclimation 60 s; passive income tick; onboarding reward.
- **Out:** Upgrades; train.

## Files expected to change
- `games/haunted/src/server/Services/CaptureService.luau`
- `games/haunted/src/server/Services/ContainmentService.luau`
- `games/haunted/src/shared/Rules/IncomeRules.luau`
- `games/haunted/src/client/HUD.client.luau`

## Acceptance criteria
- [ ] AC1: Successful capture starts the visible timer and slows the carrier; speed restored on secure/escape/leave
- [ ] AC2: Timeout or death while carrying releases only the carried capture; owned roster and coins untouched (test)
- [ ] AC3: Securing works only at the player's own pad within range and adds exactly one owned monster
- [ ] AC4: Income starts after acclimation, at config rate x variant multiplier, credited by the server only
- [ ] AC5: First secure grants the onboarding reward once
- [ ] AC6: IncomeRules have passing specs; a 2-client run shows no cross-plot securing
- [ ] AC7: scripts/check.sh passes

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
- CrossPlot uses 2 real players: A's secure at B's pen is rejected and B's roster is unchanged (12/12). The timeout path is tested and checks coins. A server-side carry speed check was added. Economy values per ADR-0006.
- Evidence: [[TEST-20261011-03]] (real-client return and secure), [[TEST-20261011-04]] (FullLoop 56/56, CrossPlot 12/12).
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0014-01]]: fail (1 major: no 2-client run), revision 1
- [[AUD-20261011-TASK-0014-02]]: **pass** (2 minor, 4 nit): the carry speed check (~23 studs/s) is too lenient for public play; an escaped Ashen Gentleman can respawn outside the Crypt (ADR-0006 §2). Nits: missing noteTeleport on the cart re-park, the death test doesn't check coins, secure ignores the deadline by up to 0.25 s.

## Outcome
*(after merge: result, lessons, follow-ups)*
