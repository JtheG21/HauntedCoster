---
id: RSH-20261014-Animation-Rigging-And-VFX-Workflow-Proposals
title: Animation Rigging and VFX Workflow Proposals
type: research
status: proposed
project: GAME-002
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - Batch 02 video research readiness assessment and existing production workflows
related:
  - "[[RSH-20261014-Video-Production-Workflow-Audit-Batch-02]]"
tags:
  - research/workflow
  - workflow/production
---
# Animation, Rigging and VFX Workflow Proposals

## Question
How can existing production workflows gain useful checks without adding redundant gates or unneeded tools?

jg requested both areas, animation/rigging efficiency first, VFX second. Preparing these proposals and correcting research is authorized; no new pilot, traversal feature, plugin installation, paid generation or implementation starts here. Approval of documentation preparation is not evidence that these methods improve production.

## Sources
Batch 02 assessment, all ten source notes and the existing Asset, VFX, UI, Audio and Model Approval workflows. The isolated package at `/private/tmp/rg1-video-workflow-adoption` contains the source-note corrections and consolidated index. The main-vault assessment records provenance and verification limits.

## Observed mechanics (verified)
Existing workflows already cover references, scope, technical/visual separation, cleanup, server authority, performance and user acceptance. The gap is task-specific rig/export provenance and repeatable motion/contact evidence. No reliable before/after completion-time baseline exists yet.

## Hypotheses
A concise asset manifest and representative clip check may reduce repeated import debugging. Distinct VFX layer roles may improve readability at lower cost. Verify only during an already-approved relevant task; do not start a new pilot merely to validate these proposals.

## Relevance to our game
Animation/source hygiene can support existing creature work where it fits the selected method. VFX checks can support approved aura/capture-effect work. Existing Wisp target, ownership and task gates remain. R6 tutorial resources are not an appropriate default for every custom creature.

## Original implementation ideas
### Proposal 1 — Asset intake: choose and document the animation method
Proposed insertion in Asset Workflow, after rig/moving-part decisions:
- Record intended states and contact constraints; choose rigid pieces, procedural joints or skeletal deformation to match them.
- Record source file, rig/version, axis/scale/pivot, expected movable parts, source action names and target export clips. Reuse existing pipeline defaults rather than copy tutorial settings wholesale.
- Keep an editable original. Perform destructive action/pose cleanup only on a duplicate after inspecting constraints and users; export one selected clip when deletion is unnecessary.

### Proposal 2 — Animation verification: representative failure case first
Proposed insertion in VFX/animation Workflow before accepting an imported animation:
- Test the smallest representative clip that exposes the real uncertainty, such as gripping contact, looping continuity or scale mismatch.
- Compare source and imported playback at actual game scale, including interruption/return-to-idle where relevant. Verify runtime anchoring/root state separately from import preparation.
- Capture motion, contact errors, loop/priority behavior and required lifecycle. Still renders do not prove motion quality.
- Record export settings and versions only after reproduction; no universal R6, Scale-reset, fps or third-party-plugin rule.

### Proposal 3 — VFX specification: purpose and cost per layer
Proposed insertion in VFX Workflow’s Decide/Acceptance sections:
- Each layer names what it communicates, its attachment/orientation, intended viewers, trigger and lifetime.
- Choose rendering ownership separately from the server’s decision that a gameplay event occurred. A cosmetic request relay does not validate gameplay movement.
- Review geometry with effects disabled, then effect readability at near/far and bright/dark views. Validate start/loop/end/cancel, respawn and interrupted-state cleanup.
- Measure beams, active particles, transparent coverage, lights and multi-entity frame cost as relevant. Compare minimal meaningful layers before adding more. No five/eight-layer default.

### Efficiency record
Add a short task record only when applicable: source/export manifest location; uncertainty tested; result; time to reviewable output; revisions and repeated failure avoided; technical cost and actual acceptance evidence. Unknown metrics stay unknown. Reuse a verified family recipe only after accepted production output.

## Recommendations (max 3)
1. Review proposals 1 and 2 first for a small targeted addition to existing Asset/VFX workflows.
2. Review proposal 3 for existing cosmetic-effect work without widening its approved scope.
3. Retain footsteps/radials/traversal as conditional research; do not add frameworks or new capabilities without a named need.

## Needs human review
- These are proposed insertions, not silently edited approved policy.
- Installed-version Blender behavior, third-party rights and actual runtime results remain unverified.
- No new pilot or code work was started. Existing task revisions, approvals and ownership remain authoritative.
