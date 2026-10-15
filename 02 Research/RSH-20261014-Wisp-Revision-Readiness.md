---
id: RSH-20261014-Wisp-Revision-Readiness
title: Wisp Revision Readiness
type: research
status: research
project: GAME-002
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - /Users/jg/Desktop/Rg1-worktrees/overhaul/tasks/queue.json
  - /Users/jg/Desktop/Rg1-worktrees/wisp/games/haunted/assets/ArtData/creature_wisp.model.json
related:
  - "[[RSH-20261014-Wisp-Approved-Modeling-Handoff]]"
  - "[[LES-0008-Model-Fidelity-And-Performance]]"
tags:
  - research/art
  - workflow/production
---
# Wisp Revision Readiness

## Question
What must be reconciled before the next Wisp modeling pass? jg authorized task tracking, explicit visual corrections and geometry-budget investigation on 2026-10-14. This is a production addendum, not model acceptance or authorization to upload, spend or merge.

## Sources
| Source | Location | Accessed |
|---|---|---|
| Authoritative task state and mirror | `Rg1-worktrees/overhaul/tasks/queue.json` and its TASK-0043 note | 2026-10-14 |
| Implementation snapshot | `Rg1-worktrees/wisp`, revision `0c3108e`; ArtData, exporter, ArtLoader and Creatures | 2026-10-14 |
| Proposed budgets | Wisp worktree `SYS-Haunted-Art-Direction`, Budgets section | 2026-10-14 |
| Visual evidence | Concept and `~/Roblox-Work/haunted/art/previews/creature_wisp_compare_grit.png`, `creature_wisp_noglow.png`, inspected during the preceding progress assessment | 2026-10-14 |

## Observed mechanics (verified)
### 1. Task tracking reconciled
The authoritative **overhaul** checkout already records TASK-0043 as `in_progress`, revision **1/2**, with request-changes and start events at 2026-10-14T18:22:41. Its task note agrees. Orchestrator validation returned **51 tasks, 0 errors** on this inspection. Preserve those events; do not increment the revision again merely to correct documentation.

The **wisp** implementation worktree contains a stale inherited queue/note (`approved`, revision 0). It is the implementation source, not the authority for this revision's task status. The earlier progress assessment mistakenly treated that stale copy as current. No queue was copied, replaced or reset in this reconciliation. The authoritative queue's branch field still names the original TASK-0043 branch; the current Wisp revision code is separately on `task/TASK-0043-Wisp-Revision` at `/Users/jg/Desktop/Rg1-worktrees/wisp`.

Claude remains construction/integration owner per the approved handoff; Codex owns brief/review. This note records the relationship without modifying another operator's active checkout. The older TASK-0043 audit applies to the earlier implementation, not acceptance of this revision.

### 2. Concrete visual correction checklist
Keep the approved concept fixed. Use its front three-quarter and rear three-quarter views as the primary comparisons; MODEL-MIN-042/022 and BAD-015 remain supporting finish references, not alternate character designs.

| Priority | Observed discrepancy | Correction and evidence required |
|---|---|---|
| 1 | Eyes protrude as smooth round discs | Recess them into shaped sockets and integrate eyelid/lacing transitions. Match eye depth and spacing in a close-up at the concept camera; verify profile too. |
| 1 | Mouth lacing is bulky and visually dominant | Match loop thickness, spacing, curvature and the exposed dark grin to the concept. Preserve readable uninterrupted loops; do not decimate them into broken fragments. |
| 1 | Head/curl reads as a smoother regular cap | Recover irregular broad head volume, swept curl and stitched panel boundaries. Compare outer silhouette and chin/neck placement before adding surface noise. |
| 2 | Body panels and seams look flatter and less integrated | Shape panel transitions, puckering and limb joins; restore deliberate seam hierarchy and worn material separation. Check rear/side finish, not only the face. |
| 2 | Lantern finish is simpler and panes read as uniform bright stripes | Match roof/frame proportions and characteristic construction; strengthen aged iron/bronze separation and uneven glass/wear. Supply effects-off and night comparisons without concealing geometry in glow. |
| Preserve | Hands/pole and both feet/bracket define the approved pose | Keep slim curled toes and clear grips while correcting the above. Verify contact in close-up and actual motion; no standing-pose redesign. |

Review package: matched camera/framing overlays; front/side/rear/three-quarter neutral renders; game-light/effects-off comparisons; close-ups of face, grips and lantern. Match perspective before diagnosing proportion. These are correction targets, not claims they have been implemented or accepted. Retain the full-detail editable source before destructive optimization.

### 3. Budget investigation
The system note explicitly labels its budgets **proposed** and says the direction needs jg's acceptance. Its creature targets are LOD0 <=8,500 and LOD1 <=6,000, not an approved hard ceiling. The current asset exceeds both proposed targets; no budget increase or simplification is approved here.

| Part | LOD0 triangles | LOD1 triangles |
|---|---:|---:|
| Body | 5,000 | 1,500 |
| Head | 4,999 | 1,498 |
| Face | 1,600 | 1,600 |
| Face twine | 3,372 | 1,010 |
| Lantern iron | 3,690 | 1,106 |
| Pole/perch | 1,904 | 570 |
| Lantern panes | 516 | 516 |
| Ember overlay (Ashen; outside current Normal-only production scope) | 474 | 474 in metadata |
| Export metadata total | **21,555** | **8,274** |

The Normal path removes Ember. Its static visible geometry is therefore approximately **21,081 near / 7,800 far**, assuming complete templates and the inspected LOD selection. This is calculated from export attributes and code, not a captured renderer measurement. The Ember detail is also omitted at distance, so the metadata total should not be treated as a universal draw count.

Eight all-Normal Wisps would contribute **168,648 near / 62,400 far** triangles before pens/exhibits, other scene geometry or effects. Those figures alone cannot establish frame time, draw calls or memory. The source/baked export has eight LOD0 mesh objects including Ember; object count is not a measured draw-call count. Spectral uses additional near shells in existing code: include its compatibility cost in eventual load testing, without expanding variant art production now.

**Working disposition:** retain the current detailed version as a fidelity candidate; do not mark it performance-ready, raise the budget, or force it under 8.5k before evidence. Correct the art first, then optimize by visual contribution. Head/body account for 9,999 triangles and twine/lantern/perch another 8,966: inspect waste in these groups, preserve defining profiles and contacts, and bake shallow relief only when a matched comparison proves it survives. The face and panes remain full resolution at distance; inspect their actual far-view contribution before choosing custom LODs. Automatic 30% reduction is an implementation setting, not proof of acceptable LOD appearance.

## Hypotheses
Manual topology and distance-specific treatment may lower cost while preserving the approved appearance. Actual savings and acceptable triangle limits remain unverified. Do not promise that the proposed 8.5k target can retain the required finish or that 21.6k is safe.

## Relevance to our game
Continue the existing Normal Wisp revision within its recorded revision limit. Preserve gameplay scale, server rules, interaction/collision behavior and current variants' compatibility. No new production attempt or state transition was recorded by this documentation work.

## Original implementation ideas
Runtime measurement protocol for the implementation owner, once the correct local place/material path is verified: compare the same scene/camera/settings before and after the Wisp change, with 1 and 8 visible wild Wisps plus populated pens/exhibits. Record actual visible counts and LODs, target device/specs, frame-time distribution, graphics mesh/texture memory, loading time and draw-call statistics where available. Include a close-up and an LOD-boundary camera pass. Use the project's established device/performance target; no FPS target is invented here. Make a budget recommendation only after these measurements and visual comparisons agree. Studio setup/verification is still pending, so no runtime result is claimed.

## Recommendations (max 3)
1. Use the overhaul queue for TASK-0043 status and the Wisp revision checkout for implementation; preserve existing revision/audit history.
2. Execute the explicit discrepancy checklist against matched views before further detail reduction.
3. Preserve the fidelity candidate and treat budget acceptance as pending measured load and in-game appearance, then propose the smallest justified change.

## Needs human review
- Actual model acceptance and any visible fidelity trade-off remain with jg.
- Final runtime budget is unresolved until representative device/load measurements exist. Static cost accounting is complete; performance acceptance is not.
- Correct local Studio place/material path and motion captures remain pending. No Studio session was taken over and no upload occurred.
