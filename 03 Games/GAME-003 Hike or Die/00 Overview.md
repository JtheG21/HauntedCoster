---
id: GAME-003
title: Hike or Die Overview
type: overview
project: GAME-003
status: blocked
created: 2026-10-18
updated: 2026-10-25
tags:
  - game/overview
---

# GAME-003: Hike or Die

**Paused (jg, 2026-10-25):** GAME-004 MathShow is now the studio's active game. Hike or Die stops at the Gate 1 state below; no further work on it unless a task says so.

**Phase:** Gate 1 — prove the photographic risk/reward loop. The project is a candidate and is not the studio's active game. The design source is Hike_or_Die_GAME-003_Gate_1_Brief.md (2026-10-18). Gate 1 is not a production or commercial greenlight.

**Code:** implemented as an isolated source root at games/hike-or-die/ with hike-or-die.project.json and a local Rojo build output, separate from default.project.json (GAME-001) and haunted.project.json (GAME-002). No published place is part of this task.

**Status:** An isolated existence prototype is approved for merge under [[TASK-0087-Hike-Or-Die-Gate-1]]. jg reports the camera still does not work; repair, physical touch evaluation and a successful full-loop test are deferred. This does not activate GAME-003 or authorize release. Task status remains in tasks/queue.json.

## Project profile
- **Status and phase:** Candidate; existence prototype approved for merge. Camera failure and incomplete full-loop validation are known follow-up work.
- **Player cap:** one player for the first prototype. Co-op is deferred to Gate 2.
- **Art direction:** handcrafted readable haunted trail blockout. [[REF-MAP-001-Dark-Fantasy-World]] and [[REF-MAP-002-Stylized-Swamp-Encounter]] guide atmosphere, layered depth, clear silhouettes, and readable route choices only; neither supplies assets or a final style decision.
- **Performance targets:** record a representative desktop baseline and evaluate touch. No numeric guarantee is set before measurement.
- **Validation:** direct game-specific format/lint/spec/map proof/Rojo build; repo-wide wiring is pending a separate chore; local-place Studio scenarios and device checks remain manual evidence.
- **Tools:** Rojo, Lune specs, Studio only against the dedicated GAME-003 place; no third-party asset import or paid API use in Gate 1.
- **Game-specific conventions:** no persistence, monetization, screenshots stored by the game, or client-authoritative rewards in Gate 1.

[[GAME-003 Hike or Die/01 Game Design]] · [[GAME-003 Hike or Die/02 Technical Architecture]] · [[GAME-003 Hike or Die/03 Roadmap]]
