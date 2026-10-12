---
id: TASK-0029
title: Habitat Rotation
type: task
project: GAME-002
status: in_progress
priority: high
risk: high
owner: executor
milestone: M3
depends_on:
  - TASK-0027
branch: task/TASK-0029-Habitat-Rotation
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[SYS-Haunted-Capture-Loop]]"
---
# TASK-0029: Habitat Rotation

## Goal
The active habitat follows a shared 15-minute, four-habitat schedule that every server computes from UTC time. A one-minute warning precedes each swap, new captures close near the end, and the swap never loses or duplicates a capture.

## Scope
- **In:**
  - Pure `RotationRules`: phase, current, next, warning, closing and swap times from an injected clock and config.
  - A `HabitatService` phase machine and a `HabitatState` leaf module (SODT `RoundState` pattern).
  - A HUD countdown using `GetServerTimeNow` deadlines.
  - New capture starts refused while closing.
  - The swap policy approved in ADR-0007 (players inside, open meters, fleeing escapes).
  - A short fog transition. The incoming module activates only after cleanup and validation.
- From [[AUD-20261012-TASK-0027-01]]: `EncounterService.clearWild` removes a claimed encounter but leaves its capture session open until the next release; the swap must end those sessions (AC3). A kept fleeing monster carries an old-module zone id (nil-safe); the swap-with-chase case needs a scenario (AC4).
- **Out:** cinematic transitions, cross-server messaging, per-habitat mechanics.

## Acceptance criteria
- [ ] AC1: Specs show the schedule is deterministic across servers (same clock → same habitat), with correct boundaries (warning at T-60, closing at T-15, swap at T-0), wrap-around, and config changes that apply without touching test settings.
- [ ] AC2: A swap while a player carries keeps the carry (same species, variant and deadline). Securing after the swap adds exactly one monster.
- [ ] AC3: A swap during an open meter session cancels it cleanly. No monster is created, and no claim or prompt is left behind.
- [ ] AC4: A swap during an escape chase follows the approved policy. The fleeing capture is neither duplicated nor silently deleted, and the chase or loss is reported to the player.
- [ ] AC5: Players still inside are handled per policy, and nobody ends up inside new geometry (scenario check).
- [ ] AC6: Capture starts are refused while closing, and normal play resumes after the swap.
- [ ] AC7: FullLoop, CrossPlot and ExploitProbe pass. `scripts/check.sh` passes.

## Tests
- **Automated:** `RotationRules.spec`, and a `HabitatRotation` scenario with a fast config passed through the StudioTestHook args (for example 40 s slots).
- **Not verifiable in Studio:** clock skew across real servers. Documented as residual risk.

---
## Implementation record
- **References used:** SODT-RC-1's leaf `RoundState` module and `GetServerTimeNow` deadlines ([[SODT-RC-1]] guide, as found in [[RSH-20261012-World-Retrofit-Audit]]); adapted as `HabitatState` (Workspace attributes rather than SODT's own replication). Not re-opened in this task.
- **Built:**
  - `Config/Rotation` (900 s slots, warning 60 s, closing 15 s, UTC epoch) and pure `RotationRules` (`at`, `capturesOpen`, `withOverrides`, `clock`), with a spec.
  - `HabitatState`: the Workspace attributes the server writes and the client reads.
  - `RotationService`: a 0.25 s tick on `Workspace:GetServerTimeNow()`. It publishes the phase and closes captures in the closing window, then swaps: fog in, cancel meter sessions, evacuate players inside the hub to just outside their nearest gate, activate the next module (wild monsters cleared), let fleeing escapes follow their players out, fog out.
  - `CaptureService`: `setClosing`, `cancelAllSessions`, `followSwap`, and test views.
  - `EncounterService`: the flee region is re-read every step (a relocated chase continues on the ring road), plus `relocateFleeing`.
  - Client: a HUD rotation line (gold in the warning minute, red while closed) and a local fog fade.
  - Tutorial steps 2, 3 and 12 and the Bell Wraith blurb no longer assume the cemetery is active.
- **Test runs:** a `scenario` argument pins the Cemetery (or the `habitat` argument) unless a `rotation` schedule is passed. Live servers never see test arguments (`StudioTestHook.arg` is Studio-only).
- **From [[AUD-20261012-TASK-0027-01]]:** findings 2 and 3 (open sessions and kept chases across a swap) are covered by swaps 2 and 3 of the scenario.
- **Evidence:** [[TEST-20261012-05]].

## Audits

## Outcome
