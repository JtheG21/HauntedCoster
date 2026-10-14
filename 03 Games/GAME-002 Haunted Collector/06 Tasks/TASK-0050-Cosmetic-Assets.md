---
id: TASK-0050
title: "Cosmetic Assets"
type: task
project: GAME-002
status: in_progress
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0050-Cosmetic-Assets
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Cosmetic Assets

## Goal
Model the launch cosmetic assortment for all five categories to the quality baseline.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Ghost skins, auras, capture effects, mansion themes per supported tier, exterior decorations.
- **Out (non-goals):** Prices and live products.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Asset/VFX → [[Asset Workflow]] + [[VFX Workflow]], deep
- **References:** MODEL-MIN-060–070 (decoration packs), creature references from TASK-0043.
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0049-Management-Track-And-Journal-UI` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/cosmetics*.py`, `src/shared/ArtData/*`, `src/client/Art/*`.

## Acceptance criteria
- [ ] AC1 Launch assortment for all five categories is modelled to the quality baseline: ghost skins, auras, capture effects, mansion themes per supported tier, and exterior decorations.
- [ ] AC2 Skins and auras keep Spectral/Ashen natural identities readable; effects stay within performance budgets.
- [ ] AC3 Four-view captures of every item, with and without effects.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
- **Approach (no uploads, no paid generation):** skins are per-part tint/material palettes over the finished creature art (part names verified against the exported assets: Body, Arms, Lamp, Head, Head2, Tail, Hat, Clapper); auras and capture effects are client particle effects using built-in particle textures only (`client/Art/Effects.luau`); mansion themes tint the house art's theme slots (Walls, Trim, Roof, Glass) on every tier; decorations reuse finished kit and landmark meshes (lit pumpkin, lamp post, headstone, Celtic cross, hay bale, coffin, a 0.4-scale Weeping Angel, candles).
- **Natural variants stay dominant:** `Creatures` applies the skin first and lets Spectral/Ashen keep their identity (Spectral 35% skin hue over the pale translucent body and shell, Ashen 20% over the charcoal ash); aura intensity is capped (rate <= 8) and every emitter is local to the client.
- **Honest limits:** palette skins are a lighter-weight product than modelled skins; jg judges whether they meet the quality floor for sale. Effects use stock textures (sparkles, smoke, fire). Evidence captures were blocked by the Studio stall in this session.

## Audits

## Outcome
