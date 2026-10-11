---
id: REF-vfx_template
title: vfx_template reference guide
type: index
status: proposed
created: 2026-10-11
updated: 2026-10-11
tags:
  - reference/code
related:
  - "[[Reference_Code_Index]]"
---
# vfx_template: reference guide

Back to [[Reference_Code_Index]]. Draft for human review.

- **Repo:** https://github.com/JtheG21/vfx_template (public, default branch `main`)
- **Verified at:** commit `5c44380`, 2026-10-11. Almost everything is `--!strict` (`src/server/Modules/RaycastHitbox.luau` is the exception).
- **Role:** combat request flow with server-side validation, modular attack deliveries, and client VFX, audio and animation utilities. The README says it is reference material, **not a publishable experience**. There is no Rojo project file, so the instance hierarchy is implied by the `require` calls.

## Trust boundary (read before borrowing combat code)
The client sends only `action, attackId, origin, aim, side?` on `Remotes.AttackRequest`. `CombatServer` handles those values as follows:
- types every argument as `unknown` and `typeof`-checks it
- rate-limits to `Settings.MaxRequestsPerSecond` in a fixed 1-second window
- rejects an `origin` farther than `MaxOriginDistance` from the server-side `HumanoidRootPart`, with **NaN-safe** comparisons written as `not (x <= max)`
- bounds the aim length
- times the charge with the server clock
- keeps the hand chosen at charge start, ignoring the side claimed on release
- leaves hit detection to the server **Delivery** modules (`HitService.canReach` raycasts)

**The client never reports hits.** Keep that property in any adaptation.

## Source map
| Need | File | What it shows | Reuse notes |
|---|---|---|---|
| Server request pipeline | [`src/server/Combat/CombatServer.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/CombatServer.luau) | The validation above, per-player state, and Delivery modules registered dynamically by name | **High value.** Pattern for any client ability remote |
| Config/asset validation at startup | [`src/server/Combat/Validator.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/Validator.luau) | Checks attack and style tables for unknown fields and missing VFX templates under `ReplicatedStorage.VFXTemplates`. Reports errors and warnings | Idea transfers to any config module. Checks are specific to the combat schema |
| Hit application | [`src/server/Combat/HitService.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/HitService.luau) | `canReach` line of sight, `hitCharacter`, `hitSurface`, `explode`, impact replication | Damage model is template-specific |
| Delivery shapes | [`src/server/Combat/Deliveries/`](https://github.com/JtheG21/vfx_template/tree/main/src/server/Combat/Deliveries) (`Melee`, `Projectile`, `Beam`, `AOE`) | One module per hit shape | Small, readable examples |
| Shared config/types/remotes | [`Attacks.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Attacks.luau), [`Settings.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Settings.luau), [`Types.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Types.luau), [`Remotes.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Remotes.luau) | Typed attack configs. Remotes are one-directional (`AttackRequest` and `AttackReplicate`, found in a `RemoteEvents` folder) | Values and asset IDs are template-specific |
| Client input and animation | [`CombatInput.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/CombatInput.luau), [`AttackAnimations.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/AttackAnimations.luau), [`CombatVfx.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/combat/CombatVfx.luau) | Charge and instant input, camera-ray aim, local prediction of VFX | Animation IDs need replacing |
| VFX/audio utilities | [`src/client/vfx/VfxUtil.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/VfxUtil.luau), [`TemplatePrep.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/TemplatePrep.luau) | `burst / sustain / stop / playBurst / attachKit`, emitter lifetimes, sound fades, light fades | **Most broadly reusable** (pickups, ghost captures, UI juice) |
| Pooling | [`src/client/vfx/assetPool.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/client/vfx/assetPool.luau), [`src/shared/Combat/Shared/ObjectPool.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/ObjectPool.luau) | Instance pools for effects | Generic |
| Effects math | [`CameraShake.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/CameraShake.luau), [`Anchors.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Anchors.luau), [`Raycasting.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Raycasting.luau), [`Trajectory.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/shared/Combat/Shared/Trajectory.luau) | Shake, hand anchors, ray helpers, arcs | Generic |
| Dev tools | [`src/server/DevTools/`](https://github.com/JtheG21/vfx_template/tree/main/src/server/DevTools), [`DebugDraw.luau`](https://github.com/JtheG21/vfx_template/blob/main/src/server/Combat/DebugDraw.luau) | Dev panel, target dummy, hitbox drawing | Dev only. Gate on Studio |

## Known pitfalls (found 2026-10-11)
- **Name and case mismatches:** `CombatInput` requires `script.Parent.VFX.VFXUtil`, and `VfxUtil` requires `script.Parent.AssetPool`. The files are `src/client/vfx/VfxUtil.luau` and `assetPool.luau`. Rojo names instances after files, so rename the files or fix the requires when adapting.
- `src/shared/Modules/` contains older copies (`ObjectPool`, `CameraShake`, `AbilityData`) that nothing in `src/` requires. Use the `Combat/Shared/` versions.
- `CombatServer` indexes `ReplicatedStorage.Combat` directly, not through `WaitForChild`, so it assumes the shared folder already exists when the server starts.

## Lessons from use
*(None yet.)*

## Needs review
- Notes come from reading the source. Nothing was run in Studio.
