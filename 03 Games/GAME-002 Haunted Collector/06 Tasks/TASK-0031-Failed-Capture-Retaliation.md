---
id: TASK-0031
title: Failed-Capture Retaliation
type: task
project: GAME-002
status: in_progress
priority: medium
risk: medium
owner: executor
milestone: M3
depends_on:
  - TASK-0027
branch: task/TASK-0031-Failed-Capture-Retaliation
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[SYS-Haunted-Capture-Loop]]"
  - "[[TASK-0023-Round-20-Design-Changes]]"
---
# TASK-0031: Failed-Capture Retaliation

## Goal
A failed capture turns into a short, local chase: the target and a few nearby monsters pursue the player. A creature that reaches the player knocks them down briefly (ragdoll, no damage), and the player can recover and escape. Scope and trigger follow jg's answer in ADR-0007.

## Scope
- **In:**
  - Pure `RetaliationRules`: who joins (radius, cap), pursuit speed and duration, catch distance, knockdown time, cooldown.
  - Server pursuit stepping on anchored models (EncounterService tween pattern; Npc_template Idle → Hunting → WindingDown states, not its unlimited targeting or Humanoids).
  - A server-triggered brief ragdoll and recovery. Cleanup on death, leaving, habitat swap and timeout.
- **Out:** damage or death, spider or zombie abilities, per-habitat AI, pathfinding solvers.

## Acceptance criteria
- [ ] AC1: Only the failing player is targeted. At most N pursuers (config), all within the join radius and the active habitat. Pursuers never leave the habitat footprint.
- [ ] AC2: A catch knocks the player down for the configured time with no health loss. The player can move again afterwards, and the same pursuer can't chain-knockdown (cooldown).
- [ ] AC3: Pursuit ends on timeout, distance, death, leaving or a swap. Pursuers return to roaming, and no state leaks (scenario).
- [ ] AC4: Round 20 behaviour outside the approved trigger (startle hop, misses carried over) is unchanged. The ChaseRules and CaptureRules specs pass.
- [ ] AC5: FullLoop, ExploitProbe and CrossPlot pass. `scripts/check.sh` passes.

---
## Implementation record
- **References used:** Npc_template's Idle → Hunting → WindingDown state shape ([[Npc_template]] guide, via [[RSH-20261012-World-Retrofit-Audit]]): adapted as roaming → pursuing → giving up. Not used: its unlimited targeting and Humanoid NPCs. Monsters stay anchored and server-stepped, like the escape chase. Not re-opened in this task.
- **Built:**
  - `Monsters.Retaliation` config (ADR-0007 numbers, plus catch distance 3.5, cooldown 20 s, give-up distance 60, grace 3 s).
  - Pure `RetaliationRules`: `pickPursuers`, `pursueStep` (never leaves the habitat region, never enters the crypt from outside), `caught`, `endReason`, `canKnock`.
  - `RetaliationService`: `begin(player, target)` on the last miss; a 0.25 s tick steps the pursuers and handles catches. A catch sets the character attribute `KnockedDownUntil`, then that pursuer gives up. Pursuits end on timeout, escape, death, leaving, or a swap (`stopAll` from `HabitatService.onDeactivating`).
  - `EncounterService`: a `pursuing` state, pursuers skipped by the roam loop, `setPursuing` / `stepTo` / `candidatesForPursuit` / `byId`.
  - `CaptureService`: the final miss goes to `onFled` handlers (RetaliationService) and falls back to "slipped away"; pursuers can't be captured; `failForTest`.
  - Client `LocalWorld`: the knockdown goes into the Physics state with a small knock-back, then GettingUp. No damage anywhere.
- **Decision during testing:** a per-player grace period (3 s after getting up). The per-pursuer cooldown alone let a second pursuer knock a player down again straight away ([[TEST-20261012-07]] run 1).
- **AC4:** single misses still startle (unchanged code path); the ChaseRules and CaptureRules specs pass.
- **Evidence:** [[TEST-20261012-07]].

## Audits

## Outcome
