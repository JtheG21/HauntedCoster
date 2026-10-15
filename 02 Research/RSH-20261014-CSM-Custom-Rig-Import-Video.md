---
id: RSH-20261014-CSM-Custom-Rig-Import-Video
title: AI-Generated Character to Roblox Rig Import (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/P7FblStzmTo
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/art
  - reference/3d
---
# AI-Generated Character to Roblox Rig Import (video)

> Draft. One vendor tutorial (a 3D-generation company's own walkthrough). Medium confidence at most. Nothing here is approved, and it changes neither the baseline nor the gallery.

## Question
Which parts of one creator's "generated character → Blender → Mixamo → Studio rig" walkthrough can feed a shared vocabulary and checklist for what a professional, game-ready 3D model is (modeling, topology, texturing/UVs, rigging), so jg and Claude can judge model quality and write precise asset requests for GAME-002? It informs how we apply [[3D Model Quality Baseline]] and the finished-assets requirement in [[ADR-0011-Monetization-UI-Scope]]. Not tied to any task.

**Scope warning.** The video is mostly a rigging and import procedure. It says almost nothing about topology quality, UV layout or texel density. Those rows of the checklist below come from the local Roblox docs, not from the video, and are labelled as such.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "CSM-How to create a custom character and import a rig into Roblox Studio" (uploader: Common Sense Machines, 14:04) | https://youtu.be/P7FblStzmTo | 2026-10-14 |
| Roblox creator-docs: `art/modeling/specifications.md`, `texture-specifications.md`, `rigging.md` (local clone `~/Code/creator-docs`) | local file | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, provenance unknown, rolling duplicate lines. Misheard terms: "idol" = idle, "tries" = tris, "Miximo" = Mixamo, "gaming tag" is unclear. Where captions and on-screen text conflict, on-screen text is used.
- Frames: 22 cue frames at 1024 px viewed individually (0:20, 0:30, 0:59, 1:12, 1:19, 1:32, 2:02, 2:20, 2:50, 3:08, 3:33, 4:10, 5:12, 5:30, 6:08, 7:16, 9:05, 9:12, 9:52, 10:30, 10:58, 11:36). About 108 scene-change frames from 0:00 to 13:46 viewed via 9 contact sheets (small thumbnails, text mostly unreadable). The `--fps 0.1` sweep was not honored by the tool; scene-change selection was used instead, so quiet stretches (about 4:10–5:10, 6:40–8:30) are thinly sampled.
- Not viewed individually: every scene-change frame between the cues; no cue frame exists for 12:00–13:46 (jump animation, final run).
- The presenter's results are one run on one robot character. No mesh files were inspected.

## Observed mechanics (verified)
Tags: *(speaker claim)*, *(shown on screen)*, *(opinion)*. Pipeline order as the video shows it.
- **AI image-to-3D generation with a topology option** *(shown on screen, 0:20)*: the generator's settings panel offers model type (Sculpt / Sculpt with Textures), mesh topology Tris or Quads, polygon count Low/High Poly, symmetry, and bounding box. A retexturing tool fixes texture flaws *(speaker claim, 0:37)*.
- **Triangle budget** *(shown on screen, 0:59 and 1:12; speaker claim, 0:24–1:12)*: raw generated mesh reads 9,351 verts / 18,714 tris; after a Blender Decimate modifier it reads 4,895 verts / 9,802 tris. The speaker says Roblox "only takes 10k" and reduces to "9K". **Conflict:** the local Roblox docs give 20,000 tris per mesh (see Roblox constraints). Treat 10k as the presenter's conservative target, not the engine limit.
- **Prep before rigging** *(shown on screen, 1:19; speaker claim, 1:15–1:24)*: character centred on the grid, origin at the feet, front facing forward.
- **FBX export with embedded textures** *(shown on screen, 1:32; speaker claim, 1:29–1:40)*: Path Mode set to Copy with the embed-textures toggle so textures travel into Mixamo.
- **Auto-rigging by markers** *(shown on screen, 2:02–2:20)*: Mixamo auto-rigger asks for chin, wrists, elbows, knees and groin markers, a finger-detail choice and a skeleton LOD (Standard, 65 bones). Character should be in a T-pose, arms spread, facing forward *(shown on screen, 2:02)*.
- **Animation download choices** *(shown on screen, 2:50, 3:08; speaker claim, 3:03)*: idle and run clips chosen, with "In Place" ticked for run so the root does not travel.
- **Studio import** *(shown on screen, 3:33)*: Import 3D dialog with Rig Type = Custom, "Set Pivot to Scene Origin" ticked, and a child `mixamorig:Hips` hierarchy plus `mesh`. The speaker hits an import error and fixes it by renaming the file and re-importing *(speaker claim, 4:18–4:29; cause unknown, speaker says so)*.
- **Making it a playable character by hand** *(shown on screen, 5:12–5:30, 6:08; speaker claim, 5:05–6:08)*: add an invisible `HumanoidRootPart` sized to the torso, a `Humanoid`, set RigType R15, set HipHeight and WalkSpeed, then copy the engine's `Animate` script into the model and paste published animation IDs into it. Only the 6:08 frame (RigType field) is partly readable.
- **Collision and joints** *(shown on screen, 9:05–9:52; speaker claim, 8:44–9:12)*: a rig-edit plugin's "Create Joints" connects root part to mesh. The mesh's CanCollide/CanQuery/CanTouch are unticked and CollisionFidelity changed (speaker says Precise; the 9:52 frame still shows Default, not resolved).
- **Unresolved defects at the end** *(shown on screen, 9:52, 10:58; speaker claim, 9:44–11:03)*: first test shows the character sunk into the ground and slow; after scaling and a HipHeight guess the speaker says it is "still floating". The speaker calls hip height trial-and-error *(speaker claim, 11:02)*. Jump needs a non-looping animation set to its own action type *(speaker claim, 12:26–13:10)*. A final play test shows a running character *(shown on screen, 13:46 sheet; small thumbnail)*.

## Hypotheses
- **Vendor tutorial skips quality gating.** The video proves the rig imports and animates, not that the mesh is good. Confidence: high. Test: judge each generated model against [[3D Model Quality Baseline]] views and a wireframe/topology screenshot before any rigging.
- **A Mixamo skeleton on a Roblox "Custom" rig plus a hand-made HumanoidRootPart is fragile** (floating, sinking, scale-dependent HipHeight). Confidence: medium. Test: one small throwaway asset through the same path in a fresh place, measuring foot-to-ground gap at two scales.
- **Decimating a generated mesh by modifier alone can damage deformation and texture seams.** Confidence: low (not shown either way). Test: compare elbow/knee bends of decimated vs retopologized versions in the Animation Editor.
- **Tris/quads toggle at generation time reduces later cleanup.** Confidence: low. Test: generate one subject both ways and compare wireframes.

## Relevance to our game
Informs the art side of [[ADR-0011-Monetization-UI-Scope]] ("finished assets") and the review gates of [[3D Model Quality Baseline]]. Existing pipeline notes remain authoritative for scale/orientation: [[LES-0007-Blender-Studio-Scale]], [[Blender Pipeline]]. Related research notes linked: [[RSH-20261013-Haunted-Monetization-Discovery]], [[RSH-20261014-Good-UI-Principles-Video]]. Compared against `10 References/05 Misc/` (`3D Model Quality Baseline.md`, gallery and contact sheets): the baseline rubric is visual-only and explicitly says topology, rigging and budgets were not verified, which is the gap this note's checklist addresses. Nothing there was edited. No matching `01 UI`/`02 Map`/`03 Sounds`/`04 Vfx` references apply.

**Transferability.** Genre-neutral for modeling hygiene. Weak for our audience/platform: the video targets a humanoid-style character with a Mixamo skeleton, while Haunted Collector's creatures, props and cosmetics are mostly non-humanoid or rigid, so the humanoid steps (R15, HumanoidRootPart, Animate script) rarely apply. Server authority, approved ADRs and AGENTS.md win over anything shown.

**Shared vocabulary and checklist** (tag shows whether the point is engine-neutral or Roblox-specific; source in brackets).

| Area | Check | Tag | Source |
|---|---|---|---|
| Modeling | Silhouette, proportions and primary/secondary forms read at gameplay distance and from all views | (general) | Baseline rubric |
| Modeling | Watertight, no zero-thickness faces, no exposed holes/backfaces | (Roblox-specific) | creator-docs |
| Topology | Triangle count stated against a budget; decimated meshes inspected in wireframe, not trusted | (general) | video 0:59, 1:12 |
| Topology | Quads where possible, no n-gons, even density where the mesh will bend | (general / Roblox-specific doc wording) | creator-docs |
| Topology | Flat origin, feet at the ground plane, facing forward, scale applied | (general) | video 1:19; [[LES-0007-Blender-Studio-Scale]] |
| Texturing/UVs | Texture embedded or referenced and loads on import; no stray untextured parts | (general) | video 1:32 |
| Texturing/UVs | Texel density matches object size; texture resolution sized to object (256 / 512 / 1024 px by stud size) | (Roblox-specific) | creator-docs |
| Texturing/UVs | UV islands, seams and overlaps checked on a checker pattern | (general) | **not in video; not verified here** |
| Rigging | Clean hierarchy, bone transforms frozen (scale 1, rotation 0, root at origin) | (Roblox-specific) | creator-docs |
| Rigging | At most 4 bone influences per vertex; no influence on the root bone | (Roblox-specific) | creator-docs |
| Rigging | Marker/joint placement confirmed in a posed test (idle, run, jump), looped only where intended | (general) | video 2:20, 12:26 |
| Rigging | Collision shape set deliberately; character does not sink or float | (Roblox-specific) | video 9:52, 10:58 |

**Roblox constraints.** Individual meshes cannot exceed 20,000 triangles (the video's 10k is a self-imposed margin); geometry must be watertight with volume; vertices take at most 4 bone influences; textures up to 4096×4096; separately uploaded textures as png/jpg/tga/bmp. Source: local creator-docs `art/modeling/specifications.md` and `texture-specifications.md`, read 2026-10-14. Avatar items have separate, stricter budgets.

## Original implementation ideas
Ideas of our own; no copied assets, names, layouts or code.
- **Asset request template.** Each model request lists: subject and style, silhouette notes, tri budget, texture size, whether it deforms (rigid / bendy / skeletal), required poses, and the Baseline gallery IDs to match.
- **Two-gate review.** Gate 1 is the Baseline's visual rubric. Gate 2 is a technical sheet: wireframe screenshot, tri count, bone/influence count if rigged, texture size, and a Studio scale check. Report both separately, as the Baseline already asks.
- **Rigid-first.** For our props and monetization cosmetics, prefer rigid or lightly rigged single meshes; do skeletal rigs only for subjects that must articulate.
- **Reusable rig test place.** One scratch scene with a ground plate, a ruler and the three standard poses so floating/sinking and loop errors are caught the same way each time.

## Recommendations (max 3)
1. Add a technical-acceptance sheet (tri count, wireframe, texture size, bone/influence count) to model requests, next to the Baseline's visual rubric; do not rely on a generator's output looking right in a render.
2. Treat 20,000 triangles per mesh as the hard Roblox ceiling and set a lower per-category budget (to be decided by jg), rather than adopting the video's 10k.
3. Do not adopt the Mixamo/custom-humanoid path for non-humanoid assets; research a separate small-creature or rigid-prop rig path before any rigged model request.

## Needs human review
- Unverified conclusions:
  - Whether 10k vs 20k triangles is the right working target for our assets; the video's reason for 10k is not shown, and the docs figure is from the local clone, not rechecked against the live site.
  - That the presenter's custom-rig procedure actually produces a stable result; the video shows unresolved floating/sinking at 9:52–11:03 and a final run that appears only on a small contact sheet.
  - Whether the CollisionFidelity change (Precise) was actually applied; the 9:52 frame shows Default.
  - UV, topology-flow and texel-density items in the checklist are from general practice and the docs, not from this video.
  - Contents of the 12:00–13:46 stretch (jump, final test) were seen only in scene-change thumbnails.
  - Whether the generator's textures/outputs are licensable for a monetized game; terms were not checked.
- Timestamps jg should view: 0:20 (generator settings), 0:59 and 1:12 (tri counts), 2:20 (marker placement), 3:33 (import dialog), 9:52 and 10:58 (collision/floating), 12:26–13:10 (jump setup and final run).
