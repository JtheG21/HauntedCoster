---
id: TASK-0127
title: "MathShow Hub Art-1 Batch 2: Competitive"
type: task
project: GAME-004
status: review
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0127-art-competitive
related:
  - "[[TASK-0125-MathShow-Hub-Art-Pilot]]"
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art-1 Batch 2: Competitive

## Goal
Build the Competitive zone (VS / Blitz / Group pads) to match `A2_competitive_entrance.png` and the A4 palette, using one generated prop, ModeArch, plus generator-built masses, signs and wall.

## Scope
- **In:** ModeArch (up to 3 candidates, scratch place), Competitive zone in `scripts/build_hub.py`, regenerated `Hub.rbxmx`, evidence.
- **Out (non-goals):** other zones, skybox, holo symbols, Glyph visuals, pad logic, audio, Lighting.Technology, saving the place, merging.
- **Keep unchanged:** pad trigger volumes and ModePad tags, walk times, Glyph behaviour.

## Intake
- **Category, depth:** map/asset, standard. Reuse: the TASK-0125 prop pipeline and LampPost.
- **Decisions:** rows C0-C6 approved by jg, 2026-11-02 (budgets: <=8 new PointLights, hub total <=40, <=600 instances, <=20k triangles).

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx`, `games/mathshow/map/props/{ModeArch.rbxmx,manifest.json}`, evidence logs, this note, `tasks/items/TASK-0127.json`.

## Acceptance criteria
- [x] AC1 ModeArch candidates generated (3, <=300 tris); jg picked A (2026-11-02). Evidence: `docs/workflow/evidence/TASK-0127/art-competitive.txt` (C1).
- [x] AC2 Zone built by the generator only; pad volumes, tags and pad() calls unchanged. Evidence: same file (C2), `scripts/check.sh` drift step.
- [x] AC3 Budgets: +5 PointLights (hub total 18), +106 instances, +3924 triangles (inventory metric). Evidence: same file (C3).
- [x] AC4 Regression at d21894f: walk times 9.9-11.9 s, 34/34 GlyphSpawn reachable, pad screens, blocked mid-match, HUD behind menu. Evidence: same file (C4), `glyph-reachability.csv`.
- [x] AC5 Evidence at a clean BuildStamp d21894f: A2-framing screenshot beside the mockup, inventory, light total, console clean. Deviations from A2 are listed (VS/Group sides, magenta-looking violet).

---
## Implementation record
- Branch from `main`, then merged `main` (TASK-0126 plaza art, budget metric) before building; `Hub.rbxmx` regenerated after the merge.
- Candidates generated in a scratch place (never saved); jg picked A. `ModeArch.rbxmx` + manifest entry (`arch_light` key, colour per placement); `build_hub.py` gained per-placement colour/material and `build_competitive`.
- Decisions: mesh CanCollide false plus two transparent leg colliders per arch (a hull would fill the opening); pads left where they are, so VS is on the viewer's right (A2 has it left); wall gap 10 studs either side; `Font.GothamBlack`, SurfaceGui PixelsPerStud 12 (SizingMode 1).
- Cost found: VS walk +1.1 s because the front wall closes the court-corner diagonal.
- Checks: `scripts/check.sh` all pass; Studio checks in the evidence file. Not recorded or self-audited (row C6).

### Revision 1 (audit AUD-20261102-TASK-0127-01, rows G0-G7, jg 2026-11-02)
- F1 (P2): arches scaled x2.14 so the legs and their colliders sit outside the pad trigger footprint (1.12 studs clear); new guard `tests/test_build_hub.py` (failed on the pre-fix geometry, passes now); zone dimensions followed (walls, masses, signs, light range).
- F2 (P2): all 7 generate_mesh calls recorded in `props/manifest.json` (`generation_history`) with picked / discarded / failed; cap of 3 exceeded and acknowledged by jg (G1); AGENTS.md prop rule has the cap line. Mesh ids of the first two discarded attempts were not captured; stated, not invented.
- F3 (P3): absolute totals 34,334 -> 38,258 (+3,924) at d21894f, method in the evidence; revision state 38,666 (+4,332).
- Flaky Python test: name not retained by the auditor; three full `check.sh` runs all passed, no chore registered.
- Studio at 1181b5e: 9/9 pad entries (front and both side edges), walk times 9.9-11.9 s, 34/34 reachable. Evidence appended to `docs/workflow/evidence/TASK-0127/art-competitive.txt`.
- Not recorded or self-audited. PR 187 (TASK-0128) is stacked on the old geometry and needs this revision merged into its branch.

## Audits
- [[AUD-20261102-TASK-0127-01]]: fail, changes requested (F1 P2, F2 P2, F3 P3); addressed in revision 1.
- [[AUD-20261102-TASK-0127-02]]: fail, changes requested after revision 2/2; remaining findings are unrecoverable evidence, see the re-scope below.

### Re-scope (jg, 2026-11-02)
Re-scoped by jg: (a) the discarded generate_mesh ids from the first two attempts are unrecoverable (models deleted before capture); texture ids are recorded instead. Accepted as a permanent gap. (b) The flaky Python test seen in the auditor's run is unnamed (its output was not retained); 3 consecutive full-gate passes since. Accepted. (c) jg accepts the x2.14 arch scale and the adjusted walls/masses.

Task moved to review by hand (approved by jg; re-scope after 2/2; orchestrator lacks the transition, TASK-0124).

## Outcome
