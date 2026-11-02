---
id: TASK-0125
title: "MathShow Hub Art Pilot: AI Mesh Pipeline"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0125-art-pilot
related:
  - "[[TASK-0120-MathShow-Hub-Graybox]]"
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art Pilot: AI Mesh Pipeline

## Goal
Prove the prop pipeline end to end with one prop: generate a lamp post mesh in a scratch place, export it as `.rbxmx`, and have `scripts/build_hub.py` inline it at placements so `Hub.rbxmx` stays fully generated.

## Scope
- **In:** up to 3 generated lamp candidates (scratch place), `games/mathshow/map/props/{LampPost.rbxmx,manifest.json}`, generator props support, EAST-path lamp placements with one PointLight each, the `ModePadService: N pads` start log, AGENTS.md prop rule (max 3 lines), Studio checks and perf evidence.
- **Out (non-goals):** other props, buildings, signs, skybox, holo symbols, Glyph visuals, audio, saving the place, Lighting.Technology on the real place, uploads beyond the pilot, merging.
- **Keep unchanged:** walk times, Glyph and pad behaviour.

## Intake
- **Category, depth:** map/asset pipeline, standard.
- **Decisions:** asset creation approved by jg for this pilot only (rows A0-A7, 2026-11-02). Lamp light: `#FFB547`, Range 16, Brightness 2.5, every 15 studs along the east path.

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx` (generated), `games/mathshow/map/props/`, `scripts/check.sh` (only if needed), `ModePadService.luau` (log line), `AGENTS.md`, evidence log, this note, `tasks/items/TASK-0125.json`.

## Acceptance criteria
- [ ] AC1 LampPost.rbxmx round-trips (side-by-side screenshot).
- [ ] AC2 Drift guard fails on an edited prop file, then passes.
- [ ] AC3 Perf table before/after, both technologies, both viewports.
- [ ] AC4 Collision verified; walk times unchanged.
- [ ] AC5 Asset ids in manifest.json with provenance.

## Tests
`scripts/check.sh`; Studio checks in `docs/workflow/evidence/TASK-0125/art-pilot.txt`.

---
## Implementation record

## Audits

## Outcome
