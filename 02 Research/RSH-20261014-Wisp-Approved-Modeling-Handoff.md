---
id: RSH-20261014-Wisp-Approved-Modeling-Handoff
title: Wisp Approved Modeling Handoff
type: research
project: GAME-002
status: research
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - User-provided visual references and design approval in Codex, 2026-10-14
tags:
  - research/art
  - reference/3d
related:
  - "[[3D Model Quality Baseline]]"
---
# Wisp Approved Modeling Handoff

Reusable fidelity/performance guidance and the limits of current verification: [[LES-0008-Model-Fidelity-And-Performance]] (proposed; runtime validation pending).

Current task authority, explicit correction checklist and per-part budget investigation: [[RSH-20261014-Wisp-Revision-Readiness]]. The overhaul queue already records revision 1/2 in progress; the Wisp implementation checkout's queue is stale.

## Question
How should Claude construct the Wisp pilot to match jg’s approved visual target while improving production quality and efficiency?

## Sources
| Source | Location | Accessed |
|---|---|---|
| Approved concept | assets/wisp-pilot/wisp-approved-concept.png | 2026-10-14 |
| User references | assets/wisp-pilot/user-reference-01.png and user-reference-02.png | 2026-10-14 |
| Approval | jg: “yes this is a solid design now” in Codex | 2026-10-14 |

## Observed mechanics (verified)
The visual target was approved after the feet were corrected to actively grip the lantern bracket. This is appearance approval only; construction and technical acceptance remain pending.

![[wisp-approved-concept.png]]

## Hypotheses
The existing local Blender pipeline may reach the approved target. Verify with one representative Wisp before creating variants; no quality or speed improvement has yet been measured.

## Relevance to our game
Applies to the Wisp within TASK-0043 (Creature Models and Animation), currently recorded in the overhaul worktree. Follow [[3D Model Quality Baseline]]. Claude should read this note and open the approved image before construction or revision.

## Original implementation ideas
### Ownership and scope
Codex: research audit, visual brief and review. Claude: construction and integration. Pilot for Haunted Collector production quality and speed, associated with TASK-0043. Do not change queue status or overwrite prior audit history. Do not edit another agent’s active checkout or shared Studio session without coordinating. No paid methods, uploads, publishing or merges are authorized by this concept approval. Ask before a paid option, explaining expected hours saved and cost.

### Approved appearance
Use wisp-approved-concept.png as the primary target; preserve both user-reference images as supporting appearance material. References have unknown provenance/licensing; no source meshes or textures have been inspected or approved for import.

Preserve the broad irregular head, unsettling mischievous grin, pale grey-green stitched body, dark swept curled scalp, hunched small torso, slender articulated limbs, diagonal metal pole and large weathered Gothic lantern with cyan panes. Both feet have long slender toes visibly curled around the iron bracket: gripping, not resting flat or standing on bulbous feet. Preserve the accepted material separation, aged iron/bronze and restrained cyan glow. Do not return to the earlier cute cyan teardrop ghost. Do not silently simplify defining forms to meet a budget.

The image supplies two views, not a complete orthographic specification. Infer hidden surfaces cautiously and expose discrepancies in review. Dimensions, unseen anatomy, exact pivot and performance budget remain technical choices to establish from the current game and measure; do not infer verified mesh properties from concept art.

### Production method and research disposition
Start by testing whether the existing free local Blender pipeline can produce the defining head/mouth, stitched form transitions and gripping feet at the required gameplay scale. Preserve editable source and separate movable components. Prove this representative Wisp before making variants or expanding a family. An alternative free method is justified only if it resolves a demonstrated limitation.

Apply now: concept before production; visual and technical acceptance separately; all-view comparison under neutral/game lighting with effects disabled; representative asset before family; reproducible previews and concise accepted/change/rejected records.

Test first: material-detail translation at gameplay distance, usable animation method, LOD silhouette and measured performance. Humanoid Mixamo setup is not established as appropriate for this perched spectral creature. Do not adopt one-mesh/one-texture, universal scale-reset rules, or 24-fps performance claims as blanket requirements. Revenue/ads/onboarding lessons are outside this asset pilot.

### Acceptance evidence
- Front, side, rear and three-quarter renders at comparable scale, neutral lighting and intended game lighting; also without glow/particles.
- Compare directly against the approved concept and relevant minimum gallery originals; document specific discrepancies, not just a numeric score.
- Face and stitches read at gameplay distance; joins are deliberate; both feet visibly grip the bracket; lantern and hands do not intersect during required motion.
- Inspect idle/roam/startle/carried/chase/retaliation/display motion where required by TASK-0043. A still image cannot prove motion quality.
- Verify scale/pivot, collision and interaction preservation, loading, appearance replication and measured triangle/instance/memory/frame costs using the task’s approved procedures. Preserve server authority and gameplay rules.
- Run required project checks before formal AI audit. Prior overhaul check attempt passed 153 specs but full suite was not green because sandbox permissions prevented writing a sourcemap; rerun in an authorized checkout before claiming pass.
- jg accepts the actual model separately. Variant/family approval is a separate gate; concept approval does not approve all variants.

### Efficiency experiment
Record time to first reviewable model, production revision count, acceptance discrepancies and usage when known. Compare against the existing Wisp process where reliable baseline data exists; do not invent a speedup. Save a reusable family recipe only after actual visual acceptance and technical evidence.


## Recommendations (max 3)
1. Use the approved concept as the visual target and preserve the gripping feet.
2. Prove one Wisp with all-view, motion and technical evidence before expanding variants.
3. Save an accepted, verified method as a reusable recipe; keep untested claims provisional.

## Needs human review
- Accept the actual constructed model separately from this approved concept.
- Decide individual or family approval for natural variants before expanding production.
- Dimensions, hidden geometry, performance budgets and method feasibility require verification.
- The full ten-video workflow audit remains pending; this note contains only the Wisp-specific production disposition.

## Handoff availability
Saved in the main Obsidian vault at `/Users/jg/Desktop/Rg1/02 Research/RSH-20261014-Wisp-Approved-Modeling-Handoff.md`. Claude working in another checkout should read this absolute path; uncommitted notes do not automatically appear in other worktrees. No task statuses, prior audits, or approved workflow policies were changed. The implementation handoff was sent with jg’s explicit authorization on 2026-10-14; see Dispatch below.

## Implementation package
The isolated documentation package is `/private/tmp/rg1-video-workflow-adoption` on `chore/video-workflow-adoption`. It consolidates the ten research notes, evidence addenda and index, and adds the pilot handoff to TASK-0043 without changing its status. Read [[RSH-20261014-Video-Production-Workflow-Audit]] for the full disposition. Integration is unmerged; Claude must not assume another worktree contains these updates.

## Dispatch (2026-10-14)
jg explicitly requested sending this package to the existing model-approval implementation chat. Sent to Codex chat `01a13bd8-f14a-79e1-81b2-c2073dad1818` with artifact paths, task/revision gate checks, inherited mismatch warnings and required acceptance evidence. Successful delivery does not establish model completion.

## First-pass production readiness (2026-10-14)
jg requested Claude construct the approved design with a strong first-pass match, handle routine decisions and verification, and present the completed result for final review. Do not guarantee a one-shot match or bypass visual/technical checks. The user decisions below resolve normal/variant scope, motion and fidelity preferences.

**Verified integration concern:** inspected overhaul `games/haunted/src/client/Art/Creatures.luau:370–380` currently animates Wisp arms and Lamp separately. The approved model grips a shared pole and lantern bracket. Reusing independent motions without adjustment may break contact. Preserve fingers/pole and toes/bracket contact throughout actual required poses/motion; choose a constrained joint/assembly method appropriate to the approved behavior. No mandatory humanoid or external auto-rigging pipeline is implied.

**Recommended scope:** retain species ID, income/rarity, roam/capture logic, interaction/hitbox and established placement constraints. Inspected config has `hover=4`, `roamSpeed=5`; these are current gameplay parameters, not permission to change them or proof the taller silhouette fits. Check full lantern/pole clearance in wild, carried, pen and exhibit contexts at actual scale. Report an incompatible footprint before changing gameplay or silently distorting proportions.

**Review package:** editable source and reproducible export, front/side/rear/three-quarter neutral renders, intended-night/effects-off comparison, short actual motion capture demonstrating grips, in-game captures of relevant display contexts, measured costs and required task checks. Clearly label external renders versus in-game evidence. No new interim user appearance approval is needed unless the accepted design cannot be reached within scope/budget; final actual-model acceptance remains with jg.

**Current task gate:** inspected TASK-0043 remains `approved`, revision count 0. User now requests this Wisp revision; implementation owner must use the existing orchestrator request-changes/start path in the verified authoritative checkout, count the revision, preserve unrelated work and coordinate Studio ownership. Do not copy stale queue state between worktrees.

## Final build decisions (jg, 2026-10-14)
- Build the **Normal Wisp only**. Spectral/Ashen variants follow actual-model acceptance; do not expand them now. Preserve existing game compatibility and report any necessary handling of current variants rather than silently breaking them.
- Creature, pole, bracket and lantern float together with subtle motion. Hands grip the pole and toes actively grip the bracket throughout motion. Pole is visual only, no combat function. Preserve the approved crouched/perched pose and silhouette.
- **Preserve close-up surface detail.** Stitches, grin/teeth, face construction, surface separation, wear and Gothic lantern finish matter. If measured performance or the present pipeline conflicts with fidelity, report the concrete conflict and options before reducing detail; do not silently use the earlier recommended microdetail-first simplification.
- No further routine visual-direction interview is needed. Present a verified representative actual model to jg when ready. Escalate only a genuine unresolved design/performance/scope constraint or existing paid/upload/publish/merge gate.
- User requested Claude build. Existing model-approval implementation chat is the authorized coordination destination; delivery to that Codex chat is not proof Claude Code has started. Record actual executor and completion evidence honestly.

## Four-note pre-build review (2026-10-14)
Reviewed the newly added Pet RPG full tutorial, Pet Shop prototype, Procedural Building and Procedural Spider notes before proceeding. Accepted appearance, Normal-only scope, subtle floating assembly, close-up fidelity and spending constraints are unchanged.

**Required readiness refinements:**
1. Preserve an editable construction/rest pose distinct from the approved presentation pose. Plan hands/pole and toes/bracket contact and any deforming joints before mesh fusion or weighting. If a neutral pose is required to rig cleanly, restore the approved crouched grip pose for all acceptance captures; never redesign it as a standing creature to suit a tool. Test actual shoulder/hip/toe/hand deformations where they move. Do not force skeletal weighting if a rigid articulated assembly achieves the required motion and finish.
2. Before claiming Blender/Studio edits or tests, verify the actual tool connection with a read-only query and identify the intended file/place/session. A successful chat response or generated script is not execution evidence. Record actual executor/tool and resulting files/captures. Respect existing operator ownership and matched Rojo/place rules; no restart of someone else’s session.
3. Record source-to-game scale/orientation and verify once at target gameplay size. Do not copy tutorial FBX scale 0.01, later 5x scaling, generator reduction targets or scripted height fixes as universal settings. Check that mesh preparation/remesh preserves accepted stitches, teeth, material finish and grip silhouette. If fidelity cannot be retained within measured constraints, report before reducing it.

No image-to-3D service, new plugin, spider ground-IK/locomotion, pet combat/shop feature or paid call is introduced. Reference tutorials show iterative prototypes, not evidence the Wisp can be guaranteed in one pass. Review completion lifts the earlier hold for this four-note review only; implementation must still satisfy existing task/revision/ownership gates.

## Production dispatch instruction (2026-10-14)
jg explicitly requested giving Claude the construction work now. A finalized start instruction was delivered to the existing authorized implementation chat `01a13bd8-f14a-79e1-81b2-c2073dad1818`, with full brief/evidence paths and no further routine design questions. The receiver was asked to confirm actual Claude execution or report inability to coordinate it, preserve fidelity and complete required verification. Delivery succeeded; execution/start status could not be retrieved because the chat status tool reports `thread/items/list is not supported yet`. No model completion is claimed.
