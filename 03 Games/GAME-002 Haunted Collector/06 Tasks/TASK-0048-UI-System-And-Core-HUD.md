---
id: TASK-0048
title: "UI System and Core HUD"
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0048-UI-System-And-Core-HUD
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# UI System and Core HUD

## Goal
Replace the prototype UI with one art-directed design system and redesign the HUD and core gameplay feedback.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Tokens, components, icons, HUD, navigation, objectives, onboarding, flashlight, rotation, notifications, inspect, capture, carry/escape/retaliation, loading and error states.
- **Out (non-goals):** Management screens (TASK-0049), shop (TASK-0051).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** UI → [[UI Workflow]], deep
- **References:** `10 References/01 UI` (empty: [[UI References]]); monetization UI baseline screen rules; existing Theme conventions.
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0046-Mansion-Plot-And-Train-Art` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `src/client/UI/**`, `src/client/init.client.luau`, `src/client/LocalWorld.luau`.

## Acceptance criteria
- [ ] AC1 A design system (tokens, typography, icons, components, motion) replaces Theme; every component has hover/press/focus/disabled states and controller focus.
- [ ] AC2 HUD, navigation, objectives and onboarding, flashlight, rotation info, notifications, inspect card, capture meter, carry/escape/retaliation feedback, loading and error states are redesigned.
- [ ] AC3 Captured at desktop and narrow/mobile sizes; touch targets and controller navigation verified in Studio emulation (no physical-device claim).
- [ ] AC4 scripts/check.sh passes; FullLoop passes with the new UI.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
