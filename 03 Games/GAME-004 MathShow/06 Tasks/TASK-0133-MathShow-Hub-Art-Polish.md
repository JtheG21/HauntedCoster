---
id: TASK-0133
title: "MathShow Hub Art-1 Polish"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0133-art-polish
related: []
created: 2026-11-02
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Hub Art-1 Polish

## Goal
Close the Art-1 polish items left by [[TASK-0132-MathShow-Hub-Art-Lake]]: lake night read, map violet hue, A2 portal frame, A3 L-shaped Training hall, telescope tip.

## Scope
- **In:** `scripts/build_hub.py`, regenerated `Hub.rbxmx`, brief light total, evidence.
- **Out (non-goals):** new meshes (no `generate_mesh`), skybox, audio, Lighting.Technology, gameplay/pad/Glyph logic, saving the place, merging.
- **Keep unchanged:** pads, pad rings, signs, rank ladder, GlyphSpawn markers; MenuTheme/IdentityTheme.

## Intake
- **Category, depth:** map polish, standard. References: A1, A2 (`A2_competitive_entrance.png`), A3 (`A3_aerial_overview.png`), A4 palette.
- **Decisions:** rows Q0-Q8 approved by jg, 2026-11-02.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0133.json`.

## Acceptance criteria
See the task file; checked off in the Outcome once measured.

---
## Implementation record
Generator only (`scripts/build_hub.py`): `LAKE_WATER`/`LAKE_BED` plus `add_waterline`; `MAP_NEON_VIOLET` applied in `make_part` and `PlacedProp` for Neon parts; portal frame in `build_competitive`; L-shaped hall in `build_training` (annexes removed, `Hall_ArmN` added); `OBS_TELESCOPE` scale 1.1. Evidence: `docs/workflow/evidence/TASK-0133/art-polish.txt`. Not recorded as audited or self-audited (row Q8).

## Audits

## Outcome
- [x] Lake reads blue at night, Waterline strip added, before/after captured (Reflectance 0.1).
- [x] Map Neon violet constant (96, 82, 255), captures read hue 258 vs swatch 261.
- [x] A2 portal frame; collider guard passes.
- [x] A3 L-shaped Training hall; pads, rings, signs, ladder and all 34 GlyphSpawns unchanged.
- [x] Telescope inside the dome from 4 views (3.2 studs minimum clearance).
- [x] Budgets: +0 lights (hub 25 of 40), +48 instances, +564 triangles.
- [x] Regression at 30dd62e: walk 9.9-11.8 s, 34/34, 6 pads, mid-match, collect, retry, respawn, HUD, console clean.
