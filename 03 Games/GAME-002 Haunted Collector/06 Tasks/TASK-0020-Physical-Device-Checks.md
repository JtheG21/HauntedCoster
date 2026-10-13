---
id: TASK-0020
title: Physical Device Checks
type: task
project: GAME-002
status: archived
priority: high
risk: medium
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0020-Physical-Device-Checks
created: 2026-10-11
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[RETRO-M1-Playable-MVP-Loop]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# TASK-0020: Physical Device Checks

## Goal
Verify the game on a real controller and a touch device (or Studio's device emulator): flashlight, capture, prompts, Mansion and Journal, and the full track editor path.

## Scope
- **In:** Gamepad: flashlight (DPadDown), capture (A/R2), prompts (X/Y), the editor's cursor, A/Y/X, D-pad cycling and R1/Start confirm. Touch: HUD buttons, capture, prompts, editor taps including the thumbstick and jump areas. A post-fix light-off capture. **A 2-player CrossPlot run** on the current build (deferred from [[TASK-0022-M1-Polish]] by jg; the Studio multiplayer harness wasn't joining clients on 2026-10-11).
- **Out:** New input features beyond fixing what the checks find.

## Files expected to change
- `games/haunted/src/client/UI/TrackEditor.luau` (only if a defect is found)
- `games/haunted/src/client/init.client.luau` (only if a defect is found)

## Acceptance criteria
- [ ] AC1: Every listed gamepad action works on a physical controller (TEST note, per action)
- [ ] AC2: Every listed touch action works on a touch device or the device emulator, and taps in the thumbstick or jump area neither move the character nor misplace points while editing
- [ ] AC3: The HUD Light label matches the light in a new capture after the fix
- [ ] AC4: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs and scenarios named in the ACs.
- **Who settles the evidence:** **jg** runs the physical controller and touch checks (or the device emulator) and reports per action; Claude records the TEST note and fixes defects.

## Risks / notes
Proposed in [[RETRO-M1-Playable-MVP-Loop]]; created as `ready` with jg's approval on 2026-10-11. Roblox-reserved inputs (DPadUp found in M1). Settled in ADR-0006 item 7.

---
## Implementation record
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*

- **Parked** 2026-10-12 by jg: archived until after the upcoming audit and the changes that follow; to be revived then.
