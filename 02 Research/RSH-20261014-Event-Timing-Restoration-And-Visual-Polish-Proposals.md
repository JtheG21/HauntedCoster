---
id: RSH-20261014-Event-Timing-Restoration-And-Visual-Polish-Proposals
title: Event Timing Restoration and Visual Polish Proposals
type: research
status: proposed
project: GAME-002
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - Batch 03 research assessment and user interview
related:
  - "[[RSH-20261014-Video-Production-Workflow-Audit-Batch-03]]"
tags:
  - research/workflow
---
# Event Timing, Restoration and Visual Polish Proposals

## Question
What small additions to existing workflows can improve synchronization and visual finish without adding new frameworks or pilots?

## Sources
Batch 03 assessment and ten source-note corrections. jg requested equal attention to timing/restoration and visual polish, preparation of documentation only, and no new pilot.

## Observed mechanics (verified)
Existing workflow already calls for states, ownership, cleanup, readable effects and technical verification. These proposals make the handoff artifact more specific; they are not verified efficiency improvements.

## Hypotheses
Explicit cue/ownership records may reduce repeated debugging. Visible-state/motion review may reduce late visual corrections. Validate through the next suitable already-approved task, not an extra pilot.

## Relevance to our game
Use for relevant existing animation/VFX/UI tasks. Preserve Wisp scope and existing gameplay. No mandatory marker migration, camera framework or server architecture change.

## Original implementation ideas
### A. Event/timeline contract — Asset and VFX workflow insertion
For a task with timed presentation, record a short table: cue/marker, source track or authoritative event, visible/sound action, gameplay owner, duplicate policy, interruption fallback and cleanup owner. Marker names/source versions must match. Client cues are not proof of a valid gameplay action. Missing/stale cues must not cause rewards, leave effects stuck or restart an abandoned action. Select the correct completion/fade behavior for the actual animation system.

### B. Temporary-state ownership — Systems and VFX insertion
List each changed camera, lighting, UI, speed, anchor or joint property and who owns it. Record/release only that owner’s changes on completion, cancel, error, death/respawn and replacement. Prevent old callbacks restoring state over a newer effect; saved snapshots alone do not solve overlapping ownership. Movement changes require explicit gameplay scope and authority, even when introduced by a visual tutorial. Validate these paths with actual tests when implemented; do not require a new shared framework preemptively.

### C. Visual polish review — UI/VFX insertion, equal priority to A/B
Show start, peak, fade, cancel and repeated-trigger states in motion, alongside neutral/effects-off model views where relevant. Check gameplay-distance readability, contrast, text, clipping, restrained emphasis and comfort/reduced-effects behavior. Do not imply safety from an arbitrary flash duration or capture frequency; unknowns require review. Avoid effects masking the model or communicating false new/unlocked/purchasable states. Measure relevant visible-effect cost rather than counting source lines or images.

### D. Conditional asset preparation
Preload only selected timing-critical assets with observed first-use problems and a failure-safe path; measure delay. Rig repair starts from actual joint version/attachments and editable source. Skybox prep starts from known source projection, intended face orientation and neighboring-edge checks. No upload or new asset acquisition is authorized here.

## Recommendations (max 3)
1. Review A/B and C together for targeted additions to current task briefs, with equal acceptance weight.
2. Keep D conditional and lightweight; reuse existing helpers and conventions before adding modules.
3. Record result, elapsed time/revisions and actual evidence only when an approved task uses the method; recipes stay provisional until accepted.

## Needs human review
These are proposed insertions, not approved workflow-file replacements. No game code, tool installation, pilot, paid call, upload, publishing, merge or chat dispatch occurred.
