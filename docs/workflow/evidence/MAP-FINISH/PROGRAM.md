# Map Finish program (GAME-004 MathShow)

Goal: "Map v1 done" per `03 Games/GAME-004 MathShow/05 Systems/SYS-Plaza-Map-Brief.md`, mockups A1-A4 and REF-MAP-003. Light tier throughout.
Approved rows (jg, 2026-11-06): MF-P, MF-M, MF-X, MF-C. Resume: read this file, sync main, continue at the first unfinished batch.

## Batches
| Batch | Task | Status | PR | Merge SHA | Lights | Tri inventory |
|---|---|---|---|---|---|---|
| MF-0 inventory | TASK-0142 | merged | #207 | 70b33f8 | 25/40 | 39,232 (TASK-0133) |
| B1 sky | TASK-0143 | merged | #209 | a4768e2 | 25/40 | 39,232 |
| B2 ambient life | TASK-0144 | merged | #211 | 5d8306b | 25/40 | 39,232 |
| B3 path/plaza dressing | TASK-0145 | merged | #213 | 4d2e4e6 | 25/40 | 43,912 |
| B4 boundary sweep | - | pending | | | | |
| B5 final regression | - | pending | | | | |

## Budgets
- PointLights: 25 of 40 at TASK-0133 (25 counted in `Hub.rbxmx` at MF-0).
- Triangle inventory baseline 39,232 (TASK-0133); program stop at +25% = 49,040.

## MF-0 method and limits
Read of `scripts/build_hub.py`, `Hub.rbxmx`, `mathshow.project.json`, `HubCosmetics.luau`, the brief, the mockup README and REF-MAP-003. No Studio captures were taken in MF-0 (no map change; Studio was already open on another place and no rojo server was running). Image-level gaps (colour, density) are confirmed with before captures at the start of each batch, from the A1/A2/A3 viewpoints.

## Brief item vs main
| Brief item | State on main | Batch |
|---|---|---|
| Starry galaxy sky, violet+cyan | **Gap.** No `Sky` anywhere (0 in `Hub.rbxmx`, none in project file); Lighting has Bloom, Atmosphere, ColorCorrection, ClockTime 0 only | B1 |
| Shooting stars (cosmetic, pcall-isolated) | **Gap.** `HubCosmetics.luau` only turns the rank crystal and bobs the holo symbols | B2 |
| Ambient sound (night air, festival) | **Gap.** No ambient Sounds (client sounds exist only for Glyph pickup and menu) | B2 (MF-X, free assets only) |
| Flower-lined paths | **Gap.** None in the generator | B3 |
| Rank showcase at centre | **Done.** `RankCrystal` over the plinth, animated by HubCosmetics. B3 only checks it against A1 | B3 (check) |
| Seating/hangout spots | **Partial.** 48-slot plaza Seat ring (minus path gaps). Nothing at the lake promenade, path sides or terraces | B3 |
| Bunting, lamps, lake, observatory, trees, holo symbols | **Done** (TASK-0125..0133) | - |
| Walk-on floor puzzles on the rings | **Not in scope** (new gameplay-adjacent feature) | Deferred |
| Terraced boundary | **Built:** 4 tiers x 48 at radius 254-278, invisible wall ring R=290, height 80, 48 segments | B4 verify |

## Scope
- **B1 Sky:** add `Sky` (StarCount, SunAngularSize/MoonAngularSize, celestial tint violet/cyan per A4), in `mathshow.project.json` or `.rbxmx`. With MF-X: a free Creator Store galaxy skybox (texture IDs in `.rbxmx`). Retune Atmosphere/ColorCorrection only if captures need it. Verify every Sky property name against `~/Code/creator-docs` before use.
- **B2 Ambient life:** client module `Hub/AmbientLife.luau`: shooting stars (pooled Parts or Beams, a few per minute), pcall-isolated, warns, cleans up, per-frame budget. With MF-X: 2 low-volume ambient Sounds (night air, distant festival) in Rojo source, fail inert. No remotes.
- **B3 Dressing:** flower strips along the 4 radial paths (CanCollide false, CanQuery false, CastShadow false, few triangles, no lights), benches at the lake promenade and two path sides, RankCrystal check against A1. No GlyphSpawn, pad or route moves.
- **B4 Boundary sweep:** walk every edge, terrace and roof; list of spots checked; add colliders only where a gap is found.
- **B5 Regression:** full gate on main's head, final budget table, before/after gallery, "Map v1 done"; MF-C Codex handoff.

## Deferred (not built)
- Walk-on floor puzzles on the plaza rings (new mechanic).
- Any custom-uploaded skybox or audio, paid assets, new generated meshes beyond the approved candidate cap.
- Real-device performance: lives in TASK-0123.

## Open items
- Studio gates for each batch need one Studio window and one `scripts/serve.sh`; Studio is currently open on place 93701543861123 and must be checked with `scripts/studio-preflight.sh` before B1.
- Other worktrees exist (TASK-0138, 0139, glyph-lifetime etc.) and PRs #203/#204/#205 stay untouched.
