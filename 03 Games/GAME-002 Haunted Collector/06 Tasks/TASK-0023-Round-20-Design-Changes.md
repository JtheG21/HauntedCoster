---
id: TASK-0023
title: Round 20 Design Changes
type: task
project: GAME-002
status: in_review
priority: medium
risk: medium
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0023-Round-20-Design-Changes
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
  - "[[TASK-0013-Monsters-And-Capture]]"
  - "[[TASK-0014-Return-Trip-And-Containment]]"
  - "[[TASK-0016-Starter-Ghost-Train]]"
---
# TASK-0023: Round 20 Design Changes

## Goal
Bring the built loop in line with jg's Round 20 discovery answers (2026-10-11): Q1 A, Q2 D, Q3 D, Q4 D, Q5 B. Tuning was chosen by jg in chat on 2026-10-11: a 15 s chase with re-grab, a carry penalty that shrinks per level, and an 8–14 stud startle hop.

## Scope
- **In:**
  - **Q2 D:** a missed press startles the monster. The meter closes, the monster hops 8–14 studs within its zone, and the player walks up and retries. Hits and misses carry over.
  - **Q1 A:** when the timer expires, the capture breaks free and runs for 15 s. Grab it (E, 6 studs) to resume with 20 s, once per capture. Otherwise it returns to its habitat.
  - **Q3 D:** carry multiplier 0.6/0.7/0.8/0.9 by Running Shoes level.
  - **Q4 D:** the starter loop gets one Scare Arch and passes one display (exhibit slot 2).
  - **Q5 B:** the "Build your haunted train" hook goes in the GDD and the Overview.
- **Out:** Round 21 questions (misses-allowed count, duplicates, exhibit assignment model, respawn delay), which are still unanswered. Also out: sprint input, raids and stealing (rejected in Round 20 research), and economy retuning.

## Files expected to change
- `games/haunted/src/server/Services/` (CaptureService, EncounterService, TrainService)
- `games/haunted/src/shared/` (Config Monsters/Economy/World, Rules EconomyRules, new ChaseRules)
- `games/haunted/src/client/UI/` (CaptureUI, Hud, MansionUI, TrackEditor)
- `games/haunted/tests/` (ChaseRules, EconomyRules and TrackRules specs; FullLoop, CrossPlot and ExploitProbe scenarios)
- GDD v0.3, Overview

## Acceptance criteria
- [ ] AC1: A missed capture press startles the monster (8–14 stud hop inside its zone, no instant retry), and hits and misses carry over to the next attempt
- [ ] AC2: Return-timer expiry starts a 15 s chase. Grabbing within 6 studs resumes the carry with 20 s, once per capture. Chase expiry, death, leaving or the speed check send it back to its habitat. Owned monsters and coins are untouched
- [ ] AC3: The carry speed multiplier is 0.6/0.7/0.8/0.9 by Running Shoes level, and the server speed check uses the same rule
- [ ] AC4: The fixed starter ride has one Scare Arch and at least one starter exhibit slot within range
- [ ] AC5: GDD v0.3 and the Overview record the Round 20 decisions and the "Build your haunted train" hook
- [ ] AC6: Specs (ChaseRules, EconomyRules, TrackRules) and the FullLoop, CrossPlot and ExploitProbe scenarios pass in Studio
- [ ] AC7: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh`. In a fresh Play session: `require(game.TestService.Tests.TestRunner).run()`, then the FullLoop, ExploitProbe and CrossPlot scenarios.
- **Who settles the evidence:** specs and scenarios (Claude). **jg** judges the feel: whether the chase is tense rather than frustrating, whether the startle retry is too slow, and whether 0.6× at level 0 is too slow.

## Risks / notes
- The chase grab is a new server-validated remote surface (a ProximityPrompt that only the owner can use, with a distance check and the deadline). The chase is networking-adjacent, so the first audit stays on Opus.
- The flee movement is a tweened CFrame with no pathfinding. It is clamped to the crypt, the graveyard or the open ground so it never crosses a fence, but it can pass through props such as houses and tombstones. Revisit if playtests show unreachable runners.
- Level 0 carry is slower than before (9.6 vs 11.2 studs/s). The farthest crypt-to-pen trip is about 450 studs, about 47 s, within the 120 s rare timer.
- The ExploitProbe mash check changed meaning: a miss now ends the session, so exactly one press of a burst counts.

---
## Implementation record
References: `10 References/06 Code` was not consulted. These are rule changes inside existing services and follow the established CaptureService/EncounterService patterns. No UI or sound references apply.

| Item | Change |
|---|---|
| Q2 startle | `CaptureService`: a miss ends the session as `startled` and keeps `progress[player]` on the encounter. `EncounterService.startle` hops the monster, then releases the claim after 0.8 s (guarded by `claimEpoch`). `CaptureUI` closes the meter and toasts the misses left |
| Q1 chase | `CaptureService.escape(..., canChase)` → `startChase` (Grab prompt, `chases` table, HUD snapshot `chase`), `grab`, `endChase`, and test hooks `expireChaseForTest`/`chaseTarget`/`requestCancel`. `EncounterService.spawnFleeing` runs the flee loop. `Monsters.Chase` holds the tuning. `stats.escapes` now counts only escapes that are finally lost |
| Pure maths | New `Rules/ChaseRules` (`startleTarget`, `fleeRegion`, `fleeStep`) with `ChaseRules.spec` |
| Q3 carry | `Economy.CarrySpeedMultipliers` and `EconomyRules.carryMultiplier`. `walkSpeed` uses it, so `MovementService` and the server speed check follow automatically. The Mansion shows the carry speed |
| Q4 starter | `World.Plot.starterPieces` (a Scare Arch at point 4), used by `TrainService` (starter fallback and unowned plots) and `TrackEditor` (starter load and the "Starter Loop" button). `TrackRules.spec` checks one arch and one in-range starter slot |
| Q5 hook | GDD Pitch and Overview |

**Checks:** `scripts/check.sh`: ALL CHECKS PASSED (2026-10-11). **Studio ([[TEST-20261011-08]]):** specs 60/0, FullLoop 79/79, ExploitProbe 13/13. CrossPlot gave no result (the same harness problem as TEST-07); its change is judged on code only, and the 2-player run sits with TASK-0020. AC6 is partly met.

## Audits
*(none yet)*

## Outcome
*(after merge)*
