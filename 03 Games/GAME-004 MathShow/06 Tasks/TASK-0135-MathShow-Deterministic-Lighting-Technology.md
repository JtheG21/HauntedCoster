---
id: TASK-0135
title: "MathShow Deterministic Lighting Technology"
type: task
project: GAME-004
status: approved
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0135-lighting-technology
related: []
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Deterministic Lighting Technology

## Goal
Opening the Rojo-built place in Studio showed a "Lighting Technology Migration" dialog (Compatibility to Voxel) during the TASK-0123 private playtest, so the published place differed from the build. Set Lighting.Technology in the project file.

## Scope
- **In:** `mathshow.project.json` Lighting `$properties`, `docs/workflow/STUDIO-SYNC.md`.
- **Out (non-goals):** publishing, saving `MathShow.rbxl`, lighting look changes.
- **Keep unchanged:** all other Lighting properties.

## Intake
- **Category, depth:** tooling, light. References: none relevant.
- **Decisions:** rows D1-D5 approved by jg, 2026-11-03.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0135.json`.

## Acceptance criteria
See the task file; checked off in the Outcome once measured.

---
## Implementation record

## Outcome (2026-11-03)
- Added `"Technology": "ShadowMap"` to Lighting `$properties` in `mathshow.project.json`.
- **Lune read of the built .rbxl:** ShadowMap (the build without the line reads Voxel).
- **Studio 0.745 open of both builds:** the build without the line showed the **Lighting Technology Migration** dialog; the new build opened with **no dialog**.
- **Live sync (D3c):** `scripts/serve.sh` plus the Rojo plugin (Connect, Accept) into the old scratch build completed; BuildStamp `d24b35a` equal to HEAD, ClockTime 0 from the project file, console clean (no Technology error). Done in a scratch copy, not `MathShow.rbxl` (mtime unchanged, 12:42); no fallback build step needed.
- Both scratch windows closed with Don't Save; nothing published.
- [[STUDIO-SYNC]] section "Lighting.Technology" updated.
