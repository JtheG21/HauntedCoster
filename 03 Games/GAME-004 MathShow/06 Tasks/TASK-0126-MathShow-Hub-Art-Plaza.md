---
id: TASK-0126
title: "MathShow Hub Art-1 Batch 1: Plaza"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0126-art-plaza
related:
  - "[[TASK-0125-MathShow-Hub-Art-Pilot]]"
  - "[[SYS-Plaza-Map-Brief]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 1: Plaza

## Goal
Dress the central plaza in the locked Direction A look (A1 spawn view, A4 palette), all through `scripts/build_hub.py`.

## Scope
- **In:** RankCrystal and SpawnHex props (generate_mesh, jg picks), plaza floor, puzzle-tile rings (decorative), plinth, seating, rim strip, lamp posts (reuse), bunting and string bulbs, spawn plate, `HubCosmetics` client controller.
- **Out:** other zones, signs, skybox, decorative holo symbols, Glyph visuals, puzzle-tile logic, audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** walk times (8-12 s), 34 GlyphSpawn markers reachable, mode pads and Glyphs, HUD counter hiding.

## Intake
- **Category, depth:** map/asset, standard. Decisions: rows B0-B6 (jg, 2026-11-02). Budgets: <=12 PointLights, <=700 new instances, <=25k new triangles, no textures uploaded.
- **Reuse:** LampPost prop and prop pipeline from [[TASK-0125-MathShow-Hub-Art-Pilot]].

## Acceptance criteria
- [ ] AC1 Candidates screenshotted; jg's pick recorded.
- [ ] AC2 Plaza built by the generator; drift guard green.
- [ ] AC3 Budgets reported with actuals.
- [ ] AC4 Regression (walk times, 34 markers, pads, Glyphs, HUD).
- [ ] AC5 Studio evidence at a clean BuildStamp, incl. forced-error survival.
- [ ] AC6 check.sh green; PR open, CI green, not merged.

---
## Implementation record
(pending)

## Outcome
(pending)
