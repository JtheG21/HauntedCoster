---
id: TASK-0021
title: Anti-Cheat Hardening
type: task
project: GAME-002
status: in_progress
priority: high
risk: high
owner: executor
milestone: M2
depends_on:
  - TASK-0019
branch: task/TASK-0021-Anti-Cheat-Hardening
created: 2026-10-11
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[RETRO-M1-Playable-MVP-Loop]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# TASK-0021: Anti-Cheat Hardening

## Goal
Close the cheat paths the M1 audits accepted for an unpublished prototype, before any public play.

## Scope
- **In:** Carry speed check that catches sustained or alternating speeding; plausibility of the trip home on secure; enforce the secure deadline; server-side crypt capture gating by house tier (no clue gate since ADR-0007); an escaped Ashen monster respawns only in the Crypt (ADR-0006 §2); noteTeleport on the cart re-park and on server moves such as the habitat evacuation (TASK-0029); a test of a server move during a carry.
- **Out:** Generic anti-exploit frameworks; changes to economy values.

## Files expected to change
- `games/haunted/src/server/Services/CaptureService.luau`
- `games/haunted/src/server/Services/EncounterService.luau`
- `games/haunted/src/server/Services/TrainService.luau`
- `games/haunted/tests/scenarios/ExploitProbe.luau`

## Acceptance criteria
- [ ] AC1: An exploit scenario running at full speed while carrying, and one teleporting to the pen, both fail to secure
- [ ] AC2: A secure after the deadline fails
- [ ] AC3: A tier-0 player can't capture a crypt monster (the Bell Wraith) through crafted `CaptureStart` calls, from inside or outside the crypt (2-player scenario). *Reworded with jg's approval on 2026-10-12. It used to require clue-based inspect and seen gating, which ADR-0007 removed.*
- [ ] AC4: An escaped Ashen monster respawns only in the Sealed Crypt (spec or scenario)
- [ ] AC5: A server-initiated move during a carry (the habitat evacuation, or a test teleport) gives no carry strike (scenario). *Reworded with jg's approval on 2026-10-12. It used to name the crypt ejection, which [[TASK-0025-Clue-Hunting-Removal]] removed ([[AUD-20261012-TASK-0025-01]] finding 4).*
- [ ] AC6: scripts/check.sh passes; ExploitProbe and CrossPlot pass

## Tests
- **Automated:** `scripts/check.sh` plus the specs and scenarios named in the ACs.
- **Who settles the evidence:** All by scenario through the Studio MCP (Claude). No human judgement needed.

## Risks / notes
Proposed in [[RETRO-M1-Playable-MVP-Loop]]; created as `ready` with jg's approval on 2026-10-11. First audit on Opus (security). Tuning thresholds that are too strict will punish lag; record the values chosen.

---
## Implementation record
- **Approval:** created `ready` with jg's approval on 2026-10-11; jg started it in chat on 2026-10-12 ("start TASK-0021").
- **Built:**
  - Carry speed: one budget over the whole carry (`CaptureRules.carryTooFast`), replacing per-tick strikes that alternating bursts and single teleports slipped past. **Values:** tolerance 1.35x the slowed walk speed, plus 12 studs of slack. Standing still banks budget on purpose: it only lets a carrier arrive as soon as a legal walker would. Train-seat movement and noted server moves are excluded.
  - `secure` enforces the deadline and counts the last stretch before accepting, so a teleport between two 0.25 s ticks can't secure (AC1, AC2).
  - Crypt gating by species and variant as well as zone (`HabitatRules.needsCrypt`), for capture and Inspect (AC3).
  - An escaped Ashen monster respawns only in the Sealed Crypt (`HabitatRules.escapedRespawnZones`); before, it went to the first zone spawning its species, outside the crypt (AC4).
  - `TrainService` notes riders on the cart re-park (AC5).
  - Tests: 6 new specs; new `CarryGuard` scenario; AC3 step in `CrossPlot`.
- **Checks:** [[TEST-20261012-11]]: `scripts/check.sh` 114/0; CarryGuard 21/21 (its negative control failed 6 checks as intended); FullLoop 85/85; ExploitProbe 13/13; CrossPlot AC3 7/7 (twice).
- **Open:** CrossPlot's seat-touch control failed in 2 of 3 runs, also with `TrainService` reverted. The all-main comparison couldn't run because the 2-player harness stopped launching its 2nd client. Not counted as a revision (environment).

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
