# Map Finish program (GAME-004 MathShow)

**STATUS: Map v1 done (B5 TASK-0147). The program stops here for jg: MF-C Codex audit pending, nothing else queued.**

Goal: "Map v1 done" per `03 Games/GAME-004 MathShow/05 Systems/SYS-Plaza-Map-Brief.md`, mockups A1-A4 and REF-MAP-003. Light tier throughout.
Approved rows (jg, 2026-11-06): MF-P, MF-M, MF-X, MF-C. Resume: read this file, sync main, continue at the first unfinished batch.

## Batches
| Batch | Task | Status | PR | Merge SHA | Lights | Tri inventory |
|---|---|---|---|---|---|---|
| MF-0 inventory | TASK-0142 | merged | #207 | 70b33f8 | 25/40 | 39,232 (TASK-0133) |
| B1 sky | TASK-0143 | merged | #209 | a4768e2 | 25/40 | 39,232 |
| B2 ambient life | TASK-0144 | merged | #211 | 5d8306b | 25/40 | 39,232 |
| B3 path/plaza dressing | TASK-0145 | merged | #213 | 4d2e4e6 | 25/40 | 43,912 |
| B4 boundary sweep | TASK-0146 | merged | #215 | b46b68e | 25/40 | 43,912 |
| B5 final regression | TASK-0147 | in review | - | - | 25/40 | 43,912 |

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

## Final budget (B5)
PointLights 25 of 40 (+0 over the program). Triangle inventory +4,680 over the program (43,912 total, +11.9% over the TASK-0133 base; stop line 49,040). Instances in Hub.rbxmx +392. Detail: B5-final.txt.

## Program results
- B1 sky: Sky (3,000 stars, celestial bodies) and a violet Atmosphere tint; no skybox texture (two free ones did not render in Studio).
- B2 ambient life: client-only shooting stars plus two free low-volume ambient loops; pure rules and spec.
- B3 dressing: 120 plus-sign flower clumps on four flat paths and six benches; north path not lined.
- B4 boundary: fixed a stuck 8-stud moat outside tier 4 (wall 290 -> 283); 24-angle edge walk and 48 pathfinding spots.
- Gallery: ~/Roblox-Work/evidence/MAP-FINISH/gallery_before_after.jpg (outside the repo).

## Deferred / known gaps (not built)
- Walk-on floor puzzles on the plaza rings (new mechanic).
- Flowers on the north ramp path.
- A galaxy skybox texture (free ones loaded but showed nothing in the Studio emulator; needs a different asset or a real-device check).
- Unverified: audibility of the ambient loops, a shooting star in a screenshot, AmbientLife failure injection and stop() cleanup, the rare glyph respawn, two-player and real-device performance (TASK-0123).
- Collision geometry the sweep did not climb out of: every concave corner of every building (sampled by pathfinding only).

## Codex handoff (row MF-C): one audit of the full Map Finish range
- Range: `ea039b1..99fbf45` (code and map; B5 adds docs and evidence only). First Map Finish commit: cf6d5b5 (TASK-0142).
- Tasks and PRs: TASK-0142 #207/#208, TASK-0143 #209/#210, TASK-0144 #211/#212, TASK-0145 #213/#214, TASK-0146 #215/#216, TASK-0147 (this PR).
- Files to read: `scripts/build_hub.py` (add_dressing, WALL_R), `games/mathshow/map/Hub.rbxmx` (generated: check drift, do not read by hand), `games/mathshow/map/Sky.rbxmx`, `mathshow.project.json` (Sky mount, Atmosphere), `games/mathshow/src/client/Hub/AmbientLife.luau`, `games/mathshow/src/shared/AmbientRules.luau`, `games/mathshow/tests/AmbientRules.spec.luau`, `games/mathshow/src/client/init.client.luau` (2 lines).
- Focus points: (1) AmbientLife: pcall isolation, cleanup, frame budget, no remotes, reduced-motion skip, Sound routing through the "Sfx" SoundGroup and fail-inert behaviour; (2) generator determinism and the drift guard (no Random in add_dressing); flowers and benches stay outside the route corridor and off the 34 GlyphSpawns, pads and lamps; (3) WALL_R 283 seals the tier-4 strip without clipping a walkable surface (check the R_Tier glyph at tier 4, R=278); (4) IP rule: flower blooms are plus signs, no mushroom or star motifs; the ambient audio is free Creator Store audio used by id (9112764546, 9112766533), no uploads; (5) budgets: PointLights 25/40, triangle total 43,912 against the 49,040 stop line.
- Gates and evidence (all at the measured SHAs named inside each file): docs/workflow/evidence/MAP-FINISH/B1-sky.txt (dfdd30b), B2-ambient.txt (83b8b05), B3-dressing.txt (fc8e8dd), B4-boundary.txt (649813f), B5-final.txt (be1da32); the inventory and scope in this file. Images: ~/Roblox-Work/evidence/TASK-0143, TASK-0145 and MAP-FINISH (outside the repo).
- Honest caveats for the auditor: B1 to B4 did not re-run collect/respawn/HUD/mid-match live (scope arguments); B5 did, at be1da32. The pathfinding boundary list was not run against the pre-fix map (the physical test was). Skybox textures were dropped, so "galaxy" rests on stars plus tint.
- Verify with: `git diff --stat ea039b1..99fbf45 -- games scripts mathshow.project.json`, `scripts/check.sh`, and (Studio) `HubRoutes.run()` after `scripts/serve.sh` from the checkout under test.
- Stop: after this handoff the program is done and waits for jg.
