---
id: AGENT-WF-Asset
title: Asset Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-13
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[Map Workflow]]"
---
# 3D assets and props

## Visual pilot gate (jg authorized 2026-10-13)
Follow [[Model Approval Workflow]] for finished model requests and revisions. Codex interviews and creates concepts; jg approves the visual target; Claude builds and implements in Studio; Codex independently verifies the actual result. Prove one representative asset before expanding its family. Existing work may finish its current bounded step, then enters the same visual acceptance gate.

## Gather
- The intended use (gameplay-critical, interactive or decor), where it appears, and how close the camera gets.
- References analysed with [[Reference Analysis Workflow]]. Check the silhouette at gameplay distance first.
- The existing assets in the [[Resource Catalog]] and the game's prop modules (GAME-002 builds props in Luau). Reuse or extend before modelling.

## Decide
- **Tool.**
  - **Studio parts or unions** for simple geometry, blockouts and anything code generates or tunes.
  - **Blender** only when a custom silhouette, curved or organic forms, sculpting or a reusable mesh kit clearly beats parts.
  - **Studio MCP generation** (`generate_mesh`, `generate_texture`, `generate_material`) is asset generation and needs jg's approval first.
- **Dimensions:** in studs, taken from the game's config or a known-size reference. If unknown, say so and propose values.
- **Complexity:** the lowest detail that reads at gameplay distance. Plan variants (colour, damage, size) as parameters, not copies.
- **Modularity:** pieces that snap on a grid the game already uses; one source per piece.
- **Pivot and orientation:** set the model pivot at the base centre. The front faces the pivot's LookVector (−Z). Record any exception.
- **Surface:** use Roblox materials or `MaterialVariant` first. `SurfaceAppearance` (PBR, MeshPart only) or textures only when needed. UVs only for textured meshes.
- **Collision:** decor gets `CanCollide = false`. Interactive parts get the simplest `CollisionFidelity` that works (`Box`, then `Hull`, then `Default`); avoid precise decomposition unless needed.

## Build: Studio and Blender
1. Prototype in Studio at the real scale, next to a character.
2. **Blender, if used:** follow [[Blender Pipeline]]. Export with `scripts/blender/export_for_roblox.py`, which audits the model and applies the Roblox export settings.
3. **Importing uploads the mesh to jg's Roblox account**, so the import is jg's step or needs jg's approval.
4. Wire behaviour in code. Assets carry no scripts unless the game's conventions say so.

## Performance and mobile
- Keep triangle counts low for repeated props, and reuse one MeshId across copies.
- Avoid many unique textures.
- Prefer `RenderFidelity = Automatic`.
- Count instances: a prop built from 40 parts costs more than one mesh.

## Acceptance
- The silhouette reads at gameplay distance (a Studio screenshot), and the scale is correct next to a character.
- The pivot, orientation and collision match the decisions above. The player cannot get stuck on it, which a quick walk test checks.
- The performance cost is noted (parts or triangles, instance count).
- It is added to the [[Resource Catalog]] if reusable, with its lifecycle state.
- Visual quality is a manual check by jg, supported by independent reference comparison. Required visual evidence must be demonstrated before a pass; pending criteria are not a completed asset.
- Save the accepted model and verified production method using [[T - Model Recipe]].
