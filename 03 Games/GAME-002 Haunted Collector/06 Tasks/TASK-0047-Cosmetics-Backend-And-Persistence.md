---
id: TASK-0047
title: "Cosmetics Backend and Persistence"
type: task
project: GAME-002
status: ready
priority: high
risk: high
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0047-Cosmetics-Backend-And-Persistence
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Cosmetics Backend and Persistence

## Goal
Implement the approved cosmetic economy backend: catalog, ownership, equipment, placements, rewards and purchases, with safe persistence.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Cosmetics config and rules, profile schema bump and migration, CosmeticsService, Coin purchases, ProcessReceipt grants with Studio-only fixtures, rewards, placement validation, rate limits, specs.
- **Out (non-goals):** UI (TASK-0051), assets (TASK-0050), live product configuration (jg).
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], deep
- **References:** [[SYS-Haunted-Monetization-UI]], [[ADR-0011-Monetization-UI-Scope]], [[RSH-20261013-Haunted-Monetization-Discovery]], [[SYS-Haunted-Player-Data]].
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0041-Interactive-Haunted-Trees` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `src/shared/Config/Cosmetics.luau`, `src/shared/Rules/{CosmeticRules,PlacementRules,ProfileRules}.luau`, `src/server/Services/{CosmeticsService,PlayerDataService}.luau`, `src/server/Remotes.luau`, tests.

## Acceptance criteria
- [ ] AC1 A cosmetic catalog (skins, auras, capture effects, mansion themes, exterior decorations) with compatibility, acquisition routes and no gameplay stats; specs prove cosmetics never change income, rarity, speed, capacity or capture.
- [ ] AC2 Profile schema bump with migration that preserves every existing field; account entitlements, per-ghost skin/aura, per-player capture effect, theme, decoration inventory and placements, and reward claims persist and survive rejoin.
- [ ] AC3 Coin purchases, equip/remove, reward claims and decoration place/move/store are server-validated, rate-limited and idempotent; Robux grants go through ProcessReceipt with duplicate-safe receipt records, and products stay disabled until configured (test fixtures only in Studio).
- [ ] AC4 Placements are validated in plot-local space against tier, footprint, paths and caps; upgrades keep compatible placements and store the rest.
- [ ] AC5 scripts/check.sh passes with new specs; Persistence scenario covers the new fields; schema change awaits jg's approval before merge.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record

## Audits

## Outcome
