---
id: ENG-Creature-Art-Pipeline
title: Creature Art Pipeline
type: index
status: proposed
created: 2026-10-16
updated: 2026-10-16
tags:
  - engineering/pipeline
  - art
related:
  - "[[Blender Pipeline]]"
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[TASK-0043-Creature-Models-And-Animation]]"
---

# Creature art pipeline (sourced base mesh → game)

The repeatable path the Lantern Wisp proved (TASK-0043 rev 1). Use it for every creature, and for any hero prop
built from a generated or bought base mesh. Draft until jg approves it; `status: proposed`.

## The steps
| # | Step | Tool | Who |
|---|---|---|---|
| 1 | Concept approved, saved under `02 Research/assets/<asset>/` | — | jg |
| 2 | Base mesh generated (Meshy free plan, CC BY 4.0) or sourced; GLB kept **outside the repo** at `~/Roblox-Work/haunted/art/<source>/` | Meshy in Chrome | Claude; spending needs jg |
| 3 | Asset module from `games/haunted/art/templates/sourced_creature.py` → `art/assets/<name>.py` | `hcart.sourced`, `hcart.surface` | Claude |
| 4 | Review cameras added to `art/tools/review_views.json` | — | Claude |
| 5 | `art/tools/review.sh <asset> --glb`: bake, comparison sheets, budget | Blender, `test_art_budgets.py` | Claude shows jg the sheets |
| 6 | Iterate paint and details until jg accepts the look (at most 2 revisions per task) | — | jg judges |
| 7 | `art-import <asset>` skill: 3D Importer upload, `ImportedArt.rbxm` into the repo, round-trip check | Studio, computer use | Claude; **upload needs jg's approval** |
| 8 | Play check: LOD swap, close-up, animation; audit; `codex-handoff`; `/task-close` | Studio MCP, auditor | jg accepts |

## The building blocks (`games/haunted/art/hcart/`)
- **`sourced.py`**: working from a base mesh.
  - `load_glb`: import, join, clear materials.
  - `separate_loose`: loose pieces, largest first.
  - `split_faces(obj, keep_face, name, material)`: move faces into a new part.
  - `fit_axis` / `axis_distance`: refit a pole or chain.
  - `hits_from_front`: place eyes or a mouth from front-view coordinates.
  - `Relief(obj, scale)`: stitch and seam relief to paint from.
  - `split_head(body, is_candidate, is_band)`: the animatable head, with a seam-hiding neck band.
  - `fit_to_height(height, lowest)`: game size and lift, with pivots.
  - `keep_near`: decimation weights that keep the face detailed.
  - `bounds`, `seg_dist`, `tri_report`.
- **`surface.py`**: painting.
  - `vertex_paint(objs, fn)`: painter → vertex colours, with ambient occlusion.
  - `fbm`, `ridged`, `SeamIndex`.
  - `burlap(..., pal=SACKING)`: cloth.
  - `relief_stitches`: thread on stitch ridges.
  - `weathered_iron(base, ...)`: rust, patina, worn copper.
- **`bake.py`**: the `BAKE` spec per asset: texture sets (size ≤ 1024, Roblox's image limit), parts with `tris` targets and an optional `keep` weight. Normals are baked from the full-detail source onto the cut mesh.
- **`export.py`**: HCM1 ArtData with LOD1 at 0.3 of the triangles; `--glb` for the import file.

## Rules that came out of the Wisp
- **Keep the source geometry.** Re-sculpting or combining it with procedural parts lost the look (jg, 2026-10-15). Add detail on top; don't replace.
- **Paint from relief, not curvature.** Generated meshes carry stitches and seams as relief (`Relief`). Look it up with a KDTree, not rounded positions.
- **Split the head after painting** so the colours carry over, and take only the island connected to the top of the head.
- **Budget first.** Creatures are 8,500 / 6,000 (LOD0 / LOD1); `check.sh` enforces it. Protect the face with `keep_near` when cutting, and give eyes enough triangles to stay round.
- **Texture maps ≤ 1024 px.** At 2048 the import fails.
- **Third-party credit.** Record it in the asset's `Credit` attribute and in [[SYS-Haunted-Art-Direction]]. The player-facing credit must be added before publish.

## Checks
- `tests/test_art_budgets.py`: triangle budgets. `tests/test_art_templates.py`: the template and asset modules only call functions that exist in `sourced` and `surface`.
- Refactoring the shared modules: dump every part's vertices and colours from the old and new code, then compare. Geometry must match exactly. A few painted parts (the lantern iron, the older Wisp variants' face and perch) vary a little between runs of the same code, so compare those against an old-vs-old run, not against zero.
- **GLBs from other tools are often unwelded** (every face has its own vertices). `load_glb` welds by default; without it `separate_loose` shatters the mesh into single faces.

## Not covered yet
- Animation is still the client's procedural rig (`client/Art/Creatures`); there's no skinned-mesh path.
- Imported meshes have no download-status check yet (Codex review, TASK-0043). Add it with the next import.
