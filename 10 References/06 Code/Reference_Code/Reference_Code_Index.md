---
id: REF-CODE-INDEX
title: Code Reference Index
type: index
status: proposed
created: 2026-10-11
updated: 2026-10-16
tags:
  - reference/code
---
# Code Reference Index

> Purpose: reusable engineering knowledge for future Roblox systems. References are source material to inspect and adapt, not plug-and-play guarantees.

Per-repo guides, with verified paths, compatibility notes and known pitfalls: [[SODT-RC-1]] · [[Npc_template]] · [[vfx_template]]. The rule that makes this mandatory is in `AGENTS.md` ("Reference-first development").

## Additional references awaiting experimentation

- [[REF-CODE-001-Roqer]] — full Roblox Studio agent repository; animation/VFX guidance is the first inspected area. Needs experimentation per technique. Roqer-specific tools, current AGPL licensing and untested macOS support require checking before adoption. The access table below covers the original three repositories only.

- [[REF-CODE-002-RoPilot]] — website/product reference for workflow automation, not inspected implementation code. Needs experimentation; showcase examples are not jg’s visual baseline.

- [[REF-CODE-003-Shaders]] — browser WebGPU effects reference; explore appearance, layering, animation and possible Roblox recreation or baked assets. Needs experimentation per effect; direct compatibility unverified.

- [[REF-CODE-004-Apify]] — research/reference collection and web automation exploration. Organization overview inspected only; compare tools and alternatives for a concrete job. Needs experimentation.

- [[REF-CODE-005-Expo-Skills]] — Expo/React Native agent knowledge and workflow reference; explore Roblox adaptations and supporting tools. PRs are research leads only; individual files/diffs unreviewed. Needs experimentation.

## How to access the source
All three repos are **public**. Reading them needs no credentials and no clone in the vault. Access was confirmed from this shell on 2026-10-11 with `git ls-remote` and `gh api`.

| Repo | Default branch | Commit verified |
|---|---|---|
| SODT-RC-1 | `main` | `86fc61d` |
| Npc_template | `main` | `28218e5` |
| vfx_template | `main` | `5c44380` |

Preferred, read-only methods (pick one):
1. **One file:** `gh api repos/JtheG21/<repo>/contents/<path> -H "Accept: application/vnd.github.raw"`
2. **List files / check that a path still exists:** `gh api "repos/JtheG21/<repo>/git/trees/main?recursive=1" --jq '.tree[].path'`
3. **Search across a repo:** shallow-clone into **Claude's session scratchpad or `~/Roblox-Work/Rg1/reference-src/`, never inside this vault** (that avoids nested Git repos and vendored code in Rg1). Run `git clone --depth 1 https://github.com/JtheG21/<repo>.git`, then refresh with `git -C <dir> pull --ff-only`.

If GitHub can't be reached, say so in the task note and work only from these notes and verified local material. Don't guess file contents.

## System lookup
| Building… | Look first at |
|---|---|
| Any client→server remote / ability | vfx_template `CombatServer.luau` (unknown-typed args, rate limit, NaN-safe distance checks) · SODT `Remotes.luau` |
| Pure rules vs. state mutation, testable scoring | SODT `SetupService.luau` |
| "Who can see / is near whom" sensors | SODT `PerceptionService.luau` · Npc `TargetService.luau` |
| Round / phase loop, breaking require cycles | SODT `RoundService.luau` + `RoundState.luau` |
| Tuning tables | SODT `Balance.luau` (structure only) |
| Player data / inventory | SODT `PlayerData/*`, `InventoryService.luau` (Wally DataService, so shape ideas only) |
| Menus, pages, button juice | SODT `src/menu/` |
| Visual tuning that needs a human eye | SODT `docs/work-routing-protocol.md` (Amber lane) + `BeastHandsCalibrationPanel.client.luau` |
| NPC lifecycle, waves | Npc `CrowdController.luau`, `Zombie.luau` |
| Pathfinding on custom geometry | Npc `Theta/ThetaSolver.luau`, `GridScanner.luau`, `PathTypes.luau` |
| Particles, sounds, lights, pooling | vfx `VfxUtil.luau`, `TemplatePrep.luau`, `assetPool.luau`, `ObjectPool.luau` |
| Startup checks for config tables and assets | vfx `Validator.luau` |
| Camera shake, trajectories, raycast helpers | vfx `Combat/Shared/*` |

## Mandatory workflow

Before building a substantial system:

1. Search this index by system/component (NPC, pathfinding, combat, VFX, remotes, player data, UI, state machines, validation, testing).
2. Open the linked repository files that actually implement the relevant behavior. Do not rely on filenames or summaries alone.
3. Check dependencies, hierarchy, types, server/client boundaries, asset IDs, storage approach, tuning constants, tests and project assumptions.
4. State briefly what pattern will be reused, what must change, and why. If nothing fits, implement the smallest appropriate solution and record that no suitable reference was found.
5. Validate the adapted system in the current project. Afterward, add only reusable, confirmed lessons to the relevant reference note.

Do not blindly copy systems, import project-specific balance values, or assume code is correct merely because it exists. Never modify a reference repository unless explicitly authorized.

## Repository quick map

| Repository | Best starting use cases | Start here |
|---|---|---|
| [SODT-RC-1](https://github.com/JtheG21/SODT-RC-1) | General Roblox architecture; server-authoritative gameplay; shared sensors; calculation/state separation; centralized remotes and tuning; rounds; player-data/config patterns; UI page controllers; dev calibration instruments; workflow lessons | [CLAUDE.md](https://github.com/JtheG21/SODT-RC-1/blob/main/CLAUDE.md), [work-routing protocol](https://github.com/JtheG21/SODT-RC-1/blob/main/docs/work-routing-protocol.md), [PerceptionService](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/PerceptionService.luau), [SetupService](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/SetupService.luau), [Remotes](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/Remotes.luau) |
| [Npc_template](https://github.com/JtheG21/Npc_template) | NPC lifecycle and states; target selection; crowd/wave management; route caching; grid scanning; Theta*/A* navigation; pathfinding debug visualization | [README](https://github.com/JtheG21/Npc_template/blob/main/README.md), [CrowdController](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/CrowdController.luau), [Zombie](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Zombie.luau), [ThetaSolver](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/ThetaSolver.luau) |
| [vfx_template](https://github.com/JtheG21/vfx_template) | Combat request flow; server-side hit validation; modular attack delivery; client input/animation; VFX/audio utilities; pooling; camera shake; projectile/beam/melee/AOE effects | [README](https://github.com/JtheG21/vfx_template/blob/main/README.md), [CombatServer](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/CombatServer.luau), [Validator](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/Validator.luau), [VfxUtil](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/VfxUtil.luau), [assetPool](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/assetPool.luau) |

## SODT-RC-1 — system pointers

- Architecture and scope discipline: [`CLAUDE.md`](https://github.com/JtheG21/SODT-RC-1/blob/main/CLAUDE.md)
- How to route verifiable code vs. instrument-assisted visual calibration vs. human judgment: [`docs/work-routing-protocol.md`](https://github.com/JtheG21/SODT-RC-1/blob/main/docs/work-routing-protocol.md)
- Shared perception state: [`src/server/Services/PerceptionService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/PerceptionService.luau)
- Derived gameplay scoring: [`src/server/Services/SetupService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/SetupService.luau)
- Central remote declarations: [`src/shared/Remotes.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/Remotes.luau)
- Shared tuning: [`src/shared/Balance.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/Balance.luau)
- Round orchestration and leaf state module: [`RoundService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/RoundService.luau), [`RoundState.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/Services/RoundState.luau)
- Player data: [`Template.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/PlayerData/Template.luau), [`Types.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/shared/PlayerData/Types.luau), [`InventoryService.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/server/InventoryService.luau)
- UI patterns: [`src/menu/`](https://github.com/JtheG21/SODT-RC-1/tree/main/src/menu), [`src/shared/stories/`](https://github.com/JtheG21/SODT-RC-1/tree/main/src/shared/stories)
- Visual calibration instrument: [`BeastHandsCalibrationPanel.client.luau`](https://github.com/JtheG21/SODT-RC-1/blob/main/src/client/BeastHandsCalibrationPanel.client.luau)

**Cautions:** game rules, sprint state, balancing, asset IDs, and map assumptions are specific to Scare or Die. Check current code and docs; do not treat roadmap items as implemented features.

## Npc_template — system pointers

- NPC crowd orchestration and route caching: [`CrowdController.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/CrowdController.luau)
- NPC states, health, targeting and cleanup: [`Zombie.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Zombie.luau)
- Target selection: [`TargetService.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/TargetService.luau)
- Grid generation: [`GridScanner.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/GridScanner.luau)
- Theta* / A* path solver: [`ThetaSolver.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/ThetaSolver.luau)
- Grid and path types: [`PathTypes.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/PathTypes.luau)
- Path debug visualization: [`GridVisulizer.luau`](https://github.com/JtheG21/Npc_template/blob/main/reference/Src/server/Theta/GridVisulizer.luau)

**Cautions:** README says this is reference code, not wired into the runtime template. Check the required NPC model, hierarchy, map geometry, raycast filters and performance limits before adaptation.

## vfx_template — system pointers

- Server combat flow and delivery-module registration: [`CombatServer.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/CombatServer.luau)
- Structure/config checks: [`Validator.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/Validator.luau)
- Hit handling: [`HitService.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/HitService.luau)
- Server attack delivery modules: [`Deliveries/`](https://github.com/JtheG21/vfx_template/tree/main/src/server/Combat/Deliveries)
- Shared combat config/types/remotes: [`Attacks.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Attacks.luau), [`Types.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Types.luau), [`Remotes.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Remotes.luau)
- Client combat input and animations: [`CombatInput.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/CombatInput.luau), [`AttackAnimations.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/AttackAnimations.luau), [`CombatVfx.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/CombatVfx.luau)
- VFX/audio utility and template prep: [`VfxUtil.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/VfxUtil.luau), [`TemplatePrep.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/TemplatePrep.luau)
- Pooling: [`assetPool.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/assetPool.luau), [`ObjectPool.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/ObjectPool.luau)
- Common helpers: [`CameraShake.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/CameraShake.luau), [`Anchors.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Anchors.luau), [`Raycasting.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Raycasting.luau), [`Trajectory.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Trajectory.luau)

**Cautions:** This is reference material, not a publish-ready experience. Preserve server authority for consequential combat outcomes; understand the client/server protocol before reuse.

## Notes from future projects

Add a new entry only when a real implementation teaches a reusable lesson. Include:

- **System / problem:**
- **Source project and file paths:**
- **Pattern worth reusing:**
- **What must be adapted:**
- **Known limitations / pitfalls:**
- **Validation evidence:**
- **Related current-project note or ADR:**
