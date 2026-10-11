---
id: REF-Npc_template
title: Npc_template reference guide
type: index
status: proposed
created: 2026-10-11
updated: 2026-10-11
tags:
  - reference/code
related:
  - "[[Reference_Code_Index]]"
---
# Npc_template: reference guide

Back to [[Reference_Code_Index]]. Draft for human review.

- **Repo:** https://github.com/JtheG21/Npc_template (public, default branch `main`)
- **Verified at:** commit `28218e5`, 2026-10-11. Nine Luau files, all `--!strict`, all under `reference/Src/server/`.
- **Role:** NPC lifecycle, crowd/wave orchestration, grid scanning and Theta* (any-angle) pathfinding. The README says it is reference code, **not wired into a runtime**.

## Source map
| Need | File | What it shows | Reuse notes |
|---|---|---|---|
| Crowd/wave orchestration | [`CrowdController.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/CrowdController.luau) | Singleton controller. Waves grow by `GrowthFactor` up to `MaxZombies`. Steering tick 0.15 s. Spawn-node search. **Route cache** re-solves only when an endpoint moves to a different grid node. Every NPC lives in one `CROWD_NPCS` folder so raycasts can exclude the crowd | Route-cache and folder-exclusion ideas transfer directly. Grid constants (60×60, spacing 4, centre `Vector3.zero`) are map-specific |
| NPC object | [`Zombie.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Zombie.luau) | `new / Update / Attack / EnterAttackMode / Die`, eye-colour state, sound | Clones `ServerStorage.Guy` and expects parts named `Left eye ball` / `Right eye ball` with `iris`. Replace with your own rig contract |
| Targeting | [`TargetService.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/TargetService.luau) | Nearest living player | Detection range is `math.huge`, with no line of sight. Add both for anything stealth- or ghost-like |
| Grid generation | [`Theta/GridScanner.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/GridScanner.luau) | Downward raycasts per node (from +20 studs, length 40) mark walkable cells | Its `RaycastParams` has an **empty** exclude list, so players or NPCs standing there at scan time can become "floor". Scan before spawning, or add exclusions |
| Path solving | [`Theta/ThetaSolver.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/ThetaSolver.luau) | Theta* with A* fallback. Line-of-sight shortcuts at +2 studs of clearance. `hasContinuousFloor` sampling (`MAX_FLOOR_STEP` 3.5) stops shortcuts over gaps. Tie-break heuristic prevents route flipping. Redundant-bend trimming | **Most reusable file.** Excludes player characters and `THETA_GRID_DEBUG` automatically. Tune the step and clearance values to your character's movement |
| Types | [`Theta/PathTypes.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/PathTypes.luau) | `Node` and `Grid` types | Copy with the solver |
| Debug view | [`Theta/GridVisulizer.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/GridVisulizer.luau) | Draws the grid and path in `THETA_GRID_DEBUG` | Dev only. Note the filename spelling |
| Misc | [`Behavior.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Behavior.luau), [`Button.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Button.luau) | A small behaviour stub, and a world button that starts or stops the crowd | Low value |

## Known pitfalls (found 2026-10-11)
- **Hierarchy mismatch:** `CrowdController` requires `ServerScriptService:WaitForChild("Theta")` and then `WaitForChild("GridVisualizer")`, but the file is named `GridVisulizer.luau`. Synced as-is through Rojo, that `WaitForChild` would never finish. Fix the name or the require when adapting.
- `CrowdController` and `Zombie` use `WaitForChild` on siblings, and `Theta/` is expected at the root of `ServerScriptService`, not next to the controller.
- Pathing is a 2D grid over one floor level. Multi-floor maps (e.g. stairs in haunted houses) need a separate grid per floor or a different approach.

## Lessons from use
*(None yet.)*

## Needs review
- Notes come from reading the source. Nothing was run in Studio.
