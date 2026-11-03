---
id: TASK-0131
title: "MathShow Hub Art-1 Batch 4: Observatory + Ranks"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0131-art-observatory
related: []
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 4: Observatory + Ranks

## Goal
Build the Observatory hero landmark (north, highest terrace, houses the Daily pad) and the Ranks hall (south-west) to match A1/A3 and the A4 palette. Two new props: ObservatoryDome and Telescope.

## Scope
- **In:** ObservatoryDome and Telescope props (at most 3 `generate_mesh` calls each), Observatory and Ranks hall in `scripts/build_hub.py`, regenerated `Hub.rbxmx`, evidence.
- **Out (non-goals):** lake/terraces art, holo symbols, Glyph visuals, polish items, skybox, pad logic, audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** the Daily pad's ModePad part, tag, Mode attribute and size.

## Intake
- **Category, depth:** map + props, standard. Reuse: TASK-0127/0129 patterns (masses, trim, windows, `sign_plate`), `RANK_RGB` from `IdentityTheme.luau` `Tier.*.Rgb`.
- **Decisions:** rows O0-O6 approved by jg, 2026-11-02.

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, `props/{ObservatoryDome,Telescope}.rbxmx`, `props/manifest.json`, evidence, this note, `tasks/items/TASK-0131.json`.

## Acceptance criteria
- [x] AC1 Props generated within the call cap (3 + 3) and picked by jg (Dome C2, Telescope C1). Evidence: `docs/workflow/evidence/TASK-0131/art-observatory.txt` (O1).
- [x] AC2 Observatory built (tower, dome with one PointLight, telescope, DAILY sign; Daily pad unchanged).
- [x] AC3 Ranks hall dressed (Basalt Blue, amber trim, RANKS sign, nine tier podiums).
- [x] AC4 Budgets met: +3 lights (hub 23), +213 instances, +6574 triangles.
- [x] AC5 Regression at 246b967: walk times 10.4-11.6 s, 34/34 glyphs, pads, Daily COMING SOON toast, mid-match block, HUD, console clean.
- [x] AC6 Evidence written with measured SHA and applies_to; A1-framing screenshot beside A1_spawn_view.png.

---
## Implementation record
Generator plus two props: `build_observatory`, `build_ranks`, `ObservatoryDome` and `Telescope` (manifest `dome_light`). Dome material is ForceField (Neon bloomed solid). The Ranks hall shell is kept because its roof carries two rare glyphs. ID: `next-id` gave TASK-0130, already used by Codex's walk-length worktree, so TASK-0131. Not recorded as audited or self-audited (row O6).

### Revision 1 (rows P0-P6)
Props re-exported from a Studio scratch place (real mesh/size/Box collision data, ModeArch-derived copies removed), brief light total 23 of 40, AGENTS.md ID rule. Rendering identical to rev0, regression repeated at 6ce3ca8. Evidence: `art-observatory.txt` REVISION 1. Not recorded as audited or self-audited.

## Audits

## Outcome
