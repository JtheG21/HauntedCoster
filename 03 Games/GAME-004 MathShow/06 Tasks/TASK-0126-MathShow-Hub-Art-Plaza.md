---
id: TASK-0126
title: "MathShow Hub Art-1 Batch 1: Plaza"
type: task
project: GAME-004
status: review
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
- [x] AC1 Candidates screenshotted; jg picked RankCrystal A and SpawnHex C (2026-11-02). Evidence: `~/Roblox-Work/evidence/TASK-0126/candidates/`.
- [x] AC2 Plaza built by the generator; drift guard green (`check.sh`).
- [x] AC3 Budgets: 8 new PointLights, 294 new instances, 22,704 new triangles, no textures (art-plaza.txt).
- [x] AC4 Regression: walk times 9.9-11.9 s, 34/34 markers reachable at 12c1b4f, pads, Glyphs and HUD hiding checked (art-plaza.txt, glyph-reachability.csv).
- [x] AC5 Studio evidence at clean BuildStamp 12c1b4f, incl. the forced-error run. Screenshots are ~1210x558, not 844x390.
- [ ] AC6 check.sh green (done); PR open, CI green, not merged (pending).

---
## Implementation record
- Props: `RankCrystal` (candidate A, 396 tris) and `SpawnHex` (candidate C, 178 tris, an octagon as generated) in `map/props/` with manifest entries. Rojo rejected the generated models' tags, so they were rebuilt from the asset ids with `CreateMeshPartAsync` and converted to `.rbxmx` with Lune.
- Generator (`scripts/build_hub.py`): Concrete plaza bands, amber Neon rim strip, basalt plinth with violet trim, crystal with a Neon core, 54 tile pairs (Concrete centre on a cyan/violet/amber Neon base, decorative), chunkier seats, SpawnLocation kept (invisible, top y 0.5) over the SpawnHex plate with 8 violet Neon rim bars, 8 rim LampPosts, 4 bunting lines (112 wedge flags, 24 Neon bulbs, no lights). Neon amber is #FA7D12 (Bloom turns #FFB547 lemon).
- Client: `HubCosmetics.luau` (one RenderStepped connection, distance cull, frame budget, stops itself with one warn on any error), started from `init.client.luau`. Visual constants are in its frozen THEME table.
- Budget fit: the first pass (10 lamps, 64 bulbs) measured 42k triangles because a Neon Ball part costs ~430; cut to 8 lamps and 24 bulbs for 22.7k.
- Evidence: `docs/workflow/evidence/TASK-0126/` (art-plaza.txt, glyph-reachability.csv); screenshots in `~/Roblox-Work/evidence/TASK-0126/`.
- Process notes: stopped the Rojo server on the main checkout (pid 44346) with jg's approval to serve this worktree; a scratch copy of the place was used for generation and closed with Don't Save; MathShow.rbxl was never saved (mtime 2026-10-31 10:04).

## Handoff (Codex review, rev 0, 2026-11-02)
- **Task:** TASK-0126, plaza art batch 1 (props, generator, HubCosmetics). Receiver: Codex, reviewer only, no edits. Claude implemented; check.sh green, Studio checks done at 12c1b4f.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0126`, branch `task/TASK-0126-art-plaza`, commits `b6af3b4..5b0d893` (3 commits, all this task; PR 184).
- **Inputs:** [[SYS-Plaza-Map-Brief]], [[TASK-0125-MathShow-Hub-Art-Pilot]], `docs/workflow/evidence/TASK-0126/` (art-plaza.txt, glyph-reachability.csv), screenshots in `~/Roblox-Work/evidence/TASK-0126/`.
- **Review focus:**
  - `scripts/build_hub.py` (`add_props`, `add_bunting`, `Prop.extra_nodes`): do placements, counts (8 lights, 112 flags, 24 bulbs) and the budgets hold? Do rim lamps or masts block a path, pad or the SpawnLocation?
  - `games/mathshow/src/client/Hub/HubCosmetics.luau`: one connection, pcall-isolated, fails inert, `warn` on error, budget guard; any leak or per-frame allocation?
  - Spawn change (`Spawn` now invisible, top y 0.5, plate CanCollide false): does spawning and walking off still behave? CanCollide false on all decoration except floor, plinth, seats and lamp poles?
  - `props/manifest.json` and `.rbxmx`: asset ids and provenance match jg's pick (crystal A 86836773049913, hex C 111612084578305); no textures uploaded.
  - Evidence claims in art-plaza.txt (22,704 triangles, 294 instances, walk times 9.9-11.9 s): do the numbers follow from the method? Daily is 11.9 s.
- **Constraints:** no uploads, publishing, Studio writes or place saves. Rojo is served from this worktree by Claude; do not start another server.
- **Known non-task:** the `ContentId: rbxassetid://203785492` console warning; no 844x390 screenshots (capture tool has no size option); no real-device perf (TASK-0123).
- **Report back:** verdict, findings with file:line, checks run, what is unverified.

## Outcome
Plaza art batch 1 is built and verified at 12c1b4f. Open items: screenshots are not 844x390; no real-device performance (TASK-0123); jg's visual judgement and the Codex audit are pending. The SpawnHex is an 8-sided plate.
