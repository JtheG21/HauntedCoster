---
id: LES-0008
title: Model Fidelity And Performance
type: lesson
status: proposed
category: asset-production
evidence:
  - "[[RSH-20261014-Wisp-Approved-Modeling-Handoff]]"
  - "Wisp progress inspection in Codex, 2026-10-14; revision 0c3108e"
applies_to:
  - 3D asset production and visual acceptance
created: 2026-10-14
updated: 2026-10-14
tags:
  - knowledge/lesson
  - art/optimization
related:
  - "[[3D Model Quality Baseline]]"
  - "[[RSH-20261014-Wisp-Approved-Modeling-Handoff]]"
---
# Model Fidelity And Performance

## Problem
A recognizable model can still miss approved art through facial proportions, flattened seams, simplified materials or weak secondary forms. A successful export and passing code checks do not prove visual fidelity or runtime performance.

## Root cause
The Wisp inspection found visible differences between the approved concept and the rendered model: protruding eyes, heavier mouth lacing and weaker panel relief/weathering. Detail representation and engine material translation need separate verification. Two concept views do not fully specify hidden surfaces or guarantee a literal pixel-for-pixel match from every angle.

## Solution
**Draft production guidance; the complete process below has not yet been validated on an accepted Wisp.**

1. Preserve the approved art and an editable full-detail master. Correct silhouette, proportions, face, pose, grips and lantern construction before optimizing.
2. Match camera angle, perspective and framing to the concept; overlay renders and compare silhouette and landmarks. Inspect front, side, rear and three-quarter views, neutral/game lighting and effects off. Document inferred hidden surfaces.
3. Keep geometry for visible silhouette and depth: head curl, facial profile, fingers, gripping toes and lantern outline. Test baking shallow stitches, weave, creases, rivets and wear into color/normal/roughness maps. Keep prominent stitches as geometry when baking visibly flattens them.
4. Build distance-specific LODs. Compare each at its actual transition distance; reject silhouette changes, visible detail loss and popping. Do not assume a fixed reduction ratio is safe.
5. Verify the actual Roblox material path early through the approved import process. Compare game captures with external renders; do not assume a vertex-color fallback preserves PBR appearance. Existing upload/spending gates still apply.
6. Measure the intended encounter load, including eight wild creatures and populated pens/exhibits, on the intended lower-end device. Record frame time, memory, loading and draw calls alongside triangles. Neither triangle count alone nor an attractive render establishes acceptable performance.
7. For a perched creature, test a rigid body/pole/perch assembly to preserve hand/toe contact. Check head and lantern movement for clipping in actual motion and in carried/display contexts.

Every optimization must pass a visual comparison at its intended viewing distance. If measured constraints require a visible compromise, report the specific conflict and options before changing accepted detail. This note approves no new budget, upload, design change or model.

## Validation
**Verified evidence, 2026-10-14:** inspected Wisp worktree revision `0c3108e`, builder, animation code, concept comparison and four-view effects-off render. Opened gallery originals MODEL-MIN-042, MODEL-MIN-022 and MODEL-BAD-015 to assess articulated form, surface finish and lantern construction.

- Concept/brief: [[RSH-20261014-Wisp-Approved-Modeling-Handoff]].
- Actual comparison: `/Users/jg/Roblox-Work/haunted/art/previews/creature_wisp_compare_grit.png`.
- Effects-off views: `/Users/jg/Roblox-Work/haunted/art/previews/creature_wisp_noglow.png`.
- GLB index counts and ArtData metadata agreed on 21,555 triangles; ArtData reported LOD1 at 8,274. These establish asset size, not a performance verdict. Evidence paths are local snapshots and may be overwritten by later builds.
- Project checks: 153 gameplay specs and 44 Python tests passed; full suite failed on a sourcemap write-permission error and two task-note/queue mismatches. No formal acceptance pass was established.

**Pending validation:** matched-camera overlays, accepted fidelity after optimization, actual imported PBR appearance, motion/contact checks and representative device/load measurements. No measured speedup or performance benefit is claimed. Human review is needed before treating the proposed process as a proven production recipe.

**Follow-up clarification:** [[RSH-20261014-Wisp-Revision-Readiness]] verifies that the 8.5k creature target is proposed, not approved; distinguishes export totals from Normal-only visible geometry; and identifies the overhaul queue as the existing revision-state authority. Do not infer a budget violation against an approved ceiling or a missing revision transition from stale implementation-worktree metadata.

## Where this applies
Finished creatures and props built from approved concept art, especially assets whose identity depends on close-up surface detail. Complements [[3D Model Quality Baseline]]; task scope and approved design remain authoritative.
