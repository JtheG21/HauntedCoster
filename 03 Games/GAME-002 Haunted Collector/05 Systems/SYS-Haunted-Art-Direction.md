---
id: SYS-Haunted-Art-Direction
title: Art Direction and Asset Pipeline
type: system
project: GAME-002
status: proposed
created: 2026-10-13
updated: 2026-10-16
tags:
  - game/art
  - engineering/pipeline
related:
  - "[[3D Model Quality Baseline]]"
  - "[[3D Model Quality Gallery]]"
  - "[[Blender Pipeline]]"
  - "[[Asset Workflow]]"
  - "[[TASK-0042-Art-Pipeline-And-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
---
# Art direction and asset pipeline (Haunted Collector)

**Status: proposed (draft).** Written by Claude during the 2026-10-13 overhaul. The direction, budgets and per-asset verdicts are an interpretation of [[3D Model Quality Baseline]] and need jg's visual acceptance; nothing here is user-approved yet.

## Purpose
One coherent look for every player-visible 3D asset, and one production path that reaches the quality floor without uploads, paid tools or AI generation (jg, 2026-10-13: "Blender only").

## Direction: "storybook haunted attraction"
A haunted carnival-graveyard you collect and show off. Chunky, hand-made stylized forms with real anatomy and construction, a slight crooked lean, bevelled edges and painted light. Not voxel/cube style and not photoreal.

| Quality | Direction | Carried from |
|---|---|---|
| Silhouette | Exaggerated, readable at 40–80 studs; taper everywhere (trunks, limbs, posts); asymmetry and lean on organic and old things | MIN-010, MIN-054–056 (taper, roots), MIN-069 (layered architecture) |
| Forms | Coherent anatomy or construction; smooth transitions (blended joints, collars, sockets) instead of touching boxes | MIN-013–015 (dragon), MIN-037–044 (antlered creature, skeleton), MIN-048–053 (rat, zombie) |
| Identity | Every creature has a focal face/feature in the geometry, not only glowing eyes | MIN-011/012, MIN-045–047 (layered monster); against BAD-006–012 |
| Surface | Vertex-painted colour (AO, cavity, edge wear, height gradient, mottling) multiplied with Roblox material grain via box UVs (Wood, Slate, Metal, Fabric) | MIN-060–070 pack finish; Studio spike 2026-10-13 proved vertex colour × material on EditableMesh |
| Light | Lantern amber is the one strong warm light; ghost teal/cyan for the supernatural; no glow used to hide geometry (every asset is checked with glow off) | against BAD-013/014/015 |

Rejected patterns we design against: BAD-001–005 (cylinder trunks, pasted rectangular faces), BAD-006–012 (box hounds), BAD-013/014 (flat cart, glow hiding the form), BAD-015/016 (plain post, box lantern), BAD-017 (box shack).

### Palette (sRGB, `games/haunted/art/hcart/palette.py` is the source)
Night indigo world; iron `#2a2c36` with blue-grey edges; lantern amber `#ffb352`/flame `#ffd27a`; stone `#8c8a94`, bone `#e3d8bd`, moss `#4f6b3a`; wood `#5b3d2a`, bark `#4a3a30`; roof violet `#3d3550`; pumpkin `#e2711d`; ghost `#cfeff2`/ecto `#8ff0dc`. Natural variants own their accents: **Spectral** cyan `#7fe9ff` (translucent body, cold rim), **Ashen** charcoal `#5f5a57` with ember `#ff7a2e` cracks. Cosmetic skins must not use those two treatments.

## Production pipeline
1. **Author** each asset family as a Python generator in `games/haunted/art/assets/` using `hcart` (lathes, swept tubes, metaball blobs, skinned graphs, bevels, noise). The script is the source of truth; `.blend` files are disposable.
2. **Paint** vertex colour with `hcart.paint` (ray-cast AO over the whole asset, cavity/edge, gradients, mottling).
3. **Preview** with `hcart.render`: front, three-quarter, side and rear in neutral light, plus night and glow-off passes (`~/Roblox-Work/haunted/art/previews/`).
4. **Export** `--export` → `assets/ArtData/<asset>.model.json` (mapped to `ServerStorage.ArtData`; raw data never replicates): one StringValue per part with HCM1 data (`hcart/codec.py` ↔ `shared/Art/MeshCodec.luau`, both spec-tested), attributes for material, transparency, centre, joint pivot and LOD. Parts over 400 triangles also get an LOD1 (~30%).
5. **Bake** on the server: `server/Services/ArtBakeService` turns each HCM1 part into an EditableMesh (servers have no editable memory budget), stores it as DataModel-scoped content (`AssetService:CreateDataModelContentAsync`) and keeps a template MeshPart in `ReplicatedStorage.ArtTemplates/<asset>/<part>`. That content replicates like a normal mesh. Studio test 2026-10-13: the first client-side design hit the per-device EditableMesh budget after a few meshes ("Failed to create empty EditableMesh ... memory budget limits"); with server baking, all lamps and creatures cost 2.0 MB `GraphicsMeshParts` on the client.
6. **Run** on the client: `client/Art/ArtLoader` clones the baked template (falling back to a local EditableMesh build). Server builders keep their invisible colliders, lights and prompts and tag an anchor `ArtSlot` with `ArtKey`; `client/Art/Dressing` attaches the visual, `client/Art/Lod` swaps LOD0/LOD1 and drops `Detail` parts with distance, `client/Art/Creatures` animates creatures. A failed bake or build leaves the collider and logs once; gameplay never depends on art.
7. **Verify** in Studio at gameplay distance and in game lighting; record triangles and memory.

Command: `/Applications/Blender.app/Contents/MacOS/Blender -b --factory-startup -P games/haunted/art/build.py -- --asset <name> --render --night --noglow --export`.

### Going live (needs jg)
EditableMesh fails by default in published games. Either:
- **A. Import** (recommended for release): `--fbx` writes import files; jg runs one batch 3D import (an upload to the account) and the MeshIds go into an asset map so the loader prefers them. Vertex-colour support on imported meshes must be confirmed at that import; if unsupported, colours are baked to a texture first.
- **B. Keep the server bake**: jg completes 13+ age and ID verification and turns on **Enable Mesh / Image APIs** in the Creator Dashboard (creator-docs `EditableMesh.yaml`, read 2026-10-13). The bake creates *ephemeral* DataModel-scoped content each server session (Roblox stores it for the session; it is not an inventory asset and is subject to a server storage budget, `Enum.CreateContentResult.StorageLimitExceeded`). Whether `CreateDataModelContentAsync` needs anything beyond the toggle in live servers is **unverified** until a published test.

## Budgets (proposed; measured in TASK-0042 and TASK-0052)
| Asset class | LOD0 triangles | LOD1 | Notes |
|---|---|---|---|
| Creature | ≤ 8,500 | ≤ 6,000 incl. detail parts dropped at distance | 8 wild + pen/exhibit displays (measured: Wisp 8.4k / LOD1 3.2k (Meshy rev, 2026-10-16), Gentleman 5.6k, Bell Wraith 5.3k, Hound 8.3k) |
| Repeated prop (lamp, grave, fence, tree) | ≤ 3,200 | ≤ 1,100 | LOD1 beyond 70 studs |
| Landmark | ≤ 12,000 | ≤ 4,000 | one or two per habitat |
| Mansion tier | ≤ 16,000 | ≤ 5,000 | six plots |
| Cart / station | ≤ 6,000 | ≤ 2,000 | |
| Scene | ≤ 450k rendered at a typical view (desktop) | | measured, not assumed |

## Asset inventory and decisions (2026-10-13)
Every current asset was built from primitive parts (ADR-0007 "simple parts") and four of its families are in the rejected gallery, so retention needs a visual reason.

| Category | Current builder | Decision | Why | Task |
|---|---|---|---|---|
| Lamps (path, gate, plot) | `Props.lantern` | **Replace** | BAD-015/016 | 0042 |
| Wisp, Stitched Hound, Hollow Gentleman, Bell Wraith + Spectral/Ashen | `MonsterModels` | **Replace** | BAD-006–012; part assemblies | 0043 |
| Haunted trees (TASK-0041) | `World/HauntedTree` | **Replace visuals, keep behaviour** | BAD-001–005 | 0044 |
| Dead trees, pines, boulders, logs, roots | `Props.deadTree`, `Woodland` | **Replace** | cylinder trunks, no taper | 0044 |
| Tombstones, graves, candles, pumpkins, curb stones, moss, fences, cemetery gate, ruined walls | `Props.*` | **Replace** | primitive kit below MIN-063/068/069 | 0044 |
| Mist | `Kit.mist` | **Refine** | keep the fog role; soften into layered cards | 0044 |
| Ground, plazas, paths | `Props.disc`, `Kit.layPaths` | **Replace presentation** | flat discs; keep walk height and colliders | 0044 |
| Hub wall, gates, ring road, spokes | `HubBuilder` | **Replace** | plain arcs | 0044 |
| Weeping Angel, Bell Tower, Sealed Crypt, mausoleums, hearse, well | `Props.*` | **Replace** | part assemblies | 0045 |
| Standing stones, hollow oak, dens, brood tree, cocoons, webs, ruined chapel, barn, cottages | habitat builders | **Replace** | part assemblies | 0045 |
| Mansion tiers 0–2 | `PlotBuilder.buildHouse` | **Replace** | BAD-017 | 0046 |
| Pen, exhibit plinths, beacon, entrance gate, border wall, owner sign, trophies | `PlotBuilder` | **Replace** | part assemblies | 0046 |
| Station canopy, cart, rails, Scare Arch, Fog Tunnel | `PlotBuilder`, `TrainService` | **Replace** | BAD-013/014 | 0046 |
| Floating world labels ("SHABBY SHACK", habitat names) | `Build.billboard` | **Replace** with signage + UI-system labels | oversized text dominates the scene | 0046 / 0048 |
| Lighting, sky, atmosphere | `Atmosphere` | **Refine** | twilight direction was reviewed in TASK-0028; tune for new materials | 0044 |
| Flashlight | client SpotLight | **Retain** | a light, no geometry to judge | — |
| Skins, auras, capture effects, mansion themes, exterior decorations | none | **New** | approved scope ([[ADR-0011-Monetization-UI-Scope]]) | 0050 |

## Third-party sources and credits
- **Lantern Wisp base mesh (2026-10-15, TASK-0043 rev 1):** body and head generated with Meshy 6 Lite image-to-3D from the approved concept, on Meshy's free plan. Free-plan output is licensed **CC BY 4.0**: commercial use is allowed, and the game must credit Meshy (for example "Wisp base model generated with Meshy" in the experience description or credits). Approved by jg in chat on 2026-10-15; no money was spent. The source GLB stays outside the repo (`~/Roblox-Work/haunted/art/meshy/wisp_meshy_v1.glb`); `art/assets/wisp_hybrid.py` builds on it, and `creature_wisp_procedural` is the fully procedural fallback.

- **Lantern Wisp imported textures (2026-10-16, approved by jg in chat):** the baked game parts (1024 maps) were imported through Studio's 3D Importer, uploading to jg's account, and filed under `ServerStorage.ImportedArt/creature_wisp` in the local test place `~/Roblox-Work/haunted/WispRev3.rbxl`, where `MeshBuild.imported` prefers them over the vertex-coloured build. Asset IDs (to rebuild without re-uploading): Body mesh 132058751370899, Head mesh 139559420312900, Eyes mesh 138061365221442, LampIron mesh 138538525494294, Perch mesh 75068377089870; Creature colour 136853848737865, Creature normal 72429941937717; Metal colour 90669118569125, Metal normal 114393961588486. `ImportedArt` lives in the place file, not in Rojo source: any place rebuilt from the repo needs these parts re-inserted (an `ImportedArt` model file in the repo is the open follow-up). LampGlow stays the in-game neon build.

## Trust boundary
Art is client-side presentation. The server never reads it; colliders, prompts and lights stay server-built. Cosmetic appearance comes from replicated attributes the server sets after validation ([[TASK-0047-Cosmetics-Backend-And-Persistence]]).

## Needs human review
- The direction, palette and every "meets the floor" verdict are Claude's; jg owns visual acceptance.
- Choose live path A or B before publishing.
- **Lantern Wisp performance pass (2026-10-16, superseded the 18k import above):** re-baked at 8,415 tris (LOD0) / 3,165 (LOD1), down from 17,990, inside the ≤ 8,500 creature budget. Normal maps are baked from the full-detail source onto the cut mesh; the face (eyes, grin) is protected during decimation (`keep_face` weight in `wisp_meshy.py`, `decimate_to(keep=...)` in `hcart/core.py`); close-ups compared against the source show the same shapes. Re-imported (same approved flow) and saved in the repo as `games/haunted/assets/ImportedArt.rbxm`, mapped to `ServerStorage.ImportedArt` in `haunted.project.json`, so any `rojo build` place carries the textured Wisp (round-trip checked: mesh, maps, sizes identical). Parts use RenderFidelity Automatic and box collision. Current asset IDs: Body 75612386658950, Head 99243944145033, Eyes 132509968012500, LampIron 137713377547378, Perch 80079725003486; Creature colour 74516942057421, normal 97386526582948; Metal colour 121499623802643, normal 135044514471578. Live `rojo serve` sync of MeshParts from an .rbxm is not verified.
