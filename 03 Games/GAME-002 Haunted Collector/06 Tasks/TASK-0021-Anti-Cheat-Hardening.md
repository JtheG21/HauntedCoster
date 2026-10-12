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
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
