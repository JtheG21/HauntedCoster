---
id: TASK-0131
title: "MathShow Hub Art-1 Batch 4: Observatory + Ranks"
type: task
project: GAME-004
status: in_progress
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
- [ ] AC1 Props generated within the call cap and picked by jg.
- [ ] AC2 Observatory built.
- [ ] AC3 Ranks hall built.
- [ ] AC4 Budgets met.
- [ ] AC5 Regression at a clean BuildStamp.
- [ ] AC6 Evidence written.

---
## Implementation record

## Audits

## Outcome
