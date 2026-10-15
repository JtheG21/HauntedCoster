---
id: RSH-20261014-Video-Production-Workflow-Audit-Batch-03
title: Video Production Workflow Audit Batch 03
type: research
status: research
project: GAME-002
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - /Users/jg/Desktop/Rg1-worktrees/mrwonder-batch/02 Research
  - https://create.roblox.com/docs/environment/skybox
  - https://create.roblox.com/docs/scripting/security/client-server-boundary
related:
  - "[[RSH-20261014-Video-Production-Workflow-Audit-Batch-02]]"
  - "[[RSH-20261014-Video-Production-Workflow-Audit]]"
tags:
  - research/workflow
  - workflow/review
---
# Video Production Workflow Audit Batch 03

## Question
Which lessons from the next ten video notes help Haunted Collector quality and efficiency without introducing unapproved features?

Interview decision (jg, 2026-10-14): audit animation-event timing/restoration and visual polish equally; prepare corrected copies, index rows and proposed workflow additions; no new pilot. Existing priorities, ownership and human gates remain. This is a research-readiness review, not formal task/code acceptance.

## Sources
All ten new notes were read in `/Users/jg/Desktop/Rg1-worktrees/mrwonder-batch/02 Research/`; list below. They share the MrWonderHow uploader and sparse contact-sheet/caption method; note count is not independent corroboration. Original videos, scripts, audio and meshes were not independently inspected this round. Existing Asset/UI/VFX/Audio workflows and prior audit/proposals provide the comparison baseline.

Primary checks accessed 2026-10-14: Roblox skybox documentation (six neighboring aligned faces) and client/server boundary documentation (context, value and rate validation); local creator-docs AnimationTrack marker/Stopped/Ended entries, GuiObject clipping and Highlight FillTransparency entries. Local descriptions distinguish playback stop from complete fade-out and define zero fill transparency as opaque. No original video frame was rechecked against the Highlight claim.

URLs: https://create.roblox.com/docs/environment/skybox and https://create.roblox.com/docs/scripting/security/client-server-boundary . These verify bounded API/security points, not tutorial correctness.

## Observed mechanics (verified)
### All ten dispositions and required corrections

#### Animation-Event-Ability-System
**Disposition:** adapt marker/timeline contract.

Client animation markers may synchronize presentation, but a release message does not prove valid gameplay timing. Require server-owned action state/timing, range/context, duplicate protection and rate limits. Specify missing-marker, interrupted-playback and stale-callback handling. Distinguish playback stop from fade completion; no hard-coded assumption that every marker fires.

#### Impact-Frames
**Disposition:** conditional visual reference; reject cosmetic-only classification.

Anchoring the root, changing movement and clearing velocity are gameplay/movement changes, not merely cosmetic. Do not adopt freeze in a visual-effects helper. Restore only owned changes using saved state/ownership rules, not fixed defaults or a stale whole-state snapshot. Specify overlapping effects, interruption, death/respawn and reduced-effects behavior before any implementation.

#### Grab-And-Throw-Skill
**Disposition:** existing request-validation and reversible-state pattern; defer combat.

The client selects a target and drives a dash, so “client makes no decisions” is misleading. Server acceptance and effects must be separated from client intent. A Motor6D grip does not by itself prove physics independence or complete validation. Record owned temporary changes and release them on every exit; never restore over a newer owner.

#### Hitscan-Gun-System
**Disposition:** reuse validation questions; defer gun and replication redesign.

A Vector3 type check is insufficient: validate finite components, bounds, context, ownership, rate and game-specific aim/obstruction rules. The note does not verify the implementation. Attributes do not inherently eliminate races/desync and do not justify replacing the established state snapshot design.

#### Fighter-Juggle-And-Air-Combo
**Disposition:** existing state/transition concept; defer combat.

Server-owned dummy simulation does not prove authoritative client hit confirmation. Animation length must not silently redefine gameplay recovery/cooldown. Any such coupling is a scoped design decision requiring validated state and transition rules. Keep duration/hit caps and interruption cleanup as review questions only.

#### Back-Sword-Equip-System
**Disposition:** conditional preload/lifecycle checks; no weapon feature.

Preloading is a latency mitigation to measure, not a guarantee of hitch-free first use. Avoid blocking startup on unneeded assets; handle failed/unavailable loads and cancellation. Server script location alone does not prove permissions, replication audience or security. Do not insert toolbox audio as a permission workaround without verification.

#### Dynamic-Head-Neck-Joint-Fix
**Disposition:** conditional rig diagnosis only.

The observed modern R15 AnimationConstraint setup is not a universal neck fix or proof of facial deformation. Identify actual rig/joint system, attachment references and ownership before repair; do not stack welds/constraints blindly. Verify accessory contact and animation on the intended rig, preserving editable source.

#### Animated-Shine-Button
**Disposition:** conditional restrained visual accent.

Treat one-image/one-tween cost as structure, not measured performance. Require visible-only lifecycle, cancel/destroy handling, motion preferences, text/readability and rounded/moving/rotated clipping checks. The effect must not imply false acquisition status or urgency. Do not add sweeps to every purchase control.

#### Custom-Skybox-GIMP
**Disposition:** conditional environment workflow; no uploads.

An arbitrary panorama/HDRI sliced on a grid is not established as a valid seamless cubemap conversion. Confirm source projection and face layout/orientation, and inspect every neighboring edge/corner. Roblox documents six aligned cube faces. “Mood mostly sky, not geometry” is opinion; composition, geometry and readability remain relevant. Upload approval is its own existing gate.

#### Claude-MCP-Skill-Cutscene
**Disposition:** existing written handoff process; optional beat-sheet reference.

One edited creator demo does not confirm general speed or handoff reliability. Report hidden setup, missing production checks and accepted scope. Local Highlight docs define FillTransparency=0 as opaque, so “outline with zero fill” needs frame reinspection. Use a written timeline and state/cleanup contract, not a new orchestrator or licensed character reproduction.

### Cross-batch findings
- Repeated “Observed mechanics (verified)” headings still conflate captions, frames and reproduction. All ten carry medium note-level confidence despite incomplete sweeps, unreadable code and no listened audio. Preserve provenance per claim; motion, safety and cost stay unverified.
- Captions and small stills cannot establish marker reliability, cancellation behavior, first-use delay, freeze comfort, PvP safety or remote audience.
- Reference index summaries are insufficient for finished-model comparison or code reuse. Open originals/source only when needed by a scoped production decision.
- Existing workflows already cover authority, cleanup, state, input, performance and acceptance. New value is an explicit event/temporary-state contract and visual-effect review states, not ten new systems.

### Production fit
| Area | Best use | Boundary |
|---|---|---|
| Existing creature/animation work | Rig diagnosis, marker/attachment/contact contract if the chosen implementation uses it | No imposed R15 conversion, neck repair or marker architecture for procedural assets |
| Approved cosmetic/capture effects | Clear beats, owned lighting/camera/UI changes, cancellation and visual hierarchy | No movement freeze, combat or new cinematic scope implied |
| UI polish | One meaningful accent, readability, lifecycle and reduced motion | No purchase-pressure pattern, new navigation or unmeasured cost claim |
| Environment | Projection/edge/readability checklist | No custom skybox production/upload without scope and approval |
| Systems | Context/finite-value/duplicate/state validation questions | No gun, sword, combo, grab/throw or snapshot redesign |

## Hypotheses
1. A compact event timeline with cancellation ownership may reduce mismatched VFX/audio and stuck temporary state. Test only in an existing approved relevant task; no experiment starts here.
2. Review of visible states and actual motion may catch polish failures earlier than favorable still images. Compare only when reliable task evidence exists.
3. Scoped preloading may reduce first-use delay; measure actual latency and failure paths rather than adopting blanket preload-at-join.

## Relevance to our game
Use existing briefs/tasks and approved process. Wisp construction remains the previously assigned pilot; these notes neither start another nor change its accepted design. Codex audits/briefs/reviews, implementation owner builds/integrates, jg accepts actual outputs. No dispatch to other chats occurs in this batch.

## Original implementation ideas
See [[RSH-20261014-Event-Timing-Restoration-And-Visual-Polish-Proposals]] for proposed insertions into existing workflows. Preserve source, effect ownership and before/after evidence. Only promote a method after accepted output and technical verification; do not create another general framework from tutorial count.

## Recommendations (max 3)
1. Give timing/restoration and visual polish equal review weight through the proposed compact contracts.
2. Prepare ten corrected note copies plus index entries in the isolated documentation package; preserve source history and avoid editing the research author’s active checkout.
3. Defer combat/skybox/features and API migrations unless a named approved task requires them. No new pilot.

## Needs human review
- Workflow additions remain proposed, not edits to approved policy.
- Actual timing, motion, audio quality, licenses, permissions and measured performance remain unverified.
- Current main-vault check: format/lint/types, both builds, JSON/queue, 125 specs and 41 Python tests pass; full suite still fails on six existing CSM broken-link occurrences. No Studio tests or formal audit pass issued.
- Package `/private/tmp/rg1-video-workflow-adoption` is unmerged; it has two inherited TASK-0044/0046 note/queue mismatches, not corrected by inference. New source-note corrections and proposals add no validation errors.
