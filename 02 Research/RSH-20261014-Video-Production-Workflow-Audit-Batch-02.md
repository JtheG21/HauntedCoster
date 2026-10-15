---
id: RSH-20261014-Video-Production-Workflow-Audit-Batch-02
title: Video Production Workflow Audit Batch 02
type: research
project: GAME-002
status: research
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - /Users/jg/Desktop/Rg1-worktrees/mrwonder-batch/02 Research
  - https://create.roblox.com/docs/scripting/security/network-ownership
  - https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter
related:
  - "[[RSH-20261014-Video-Production-Workflow-Audit]]"
tags:
  - research/workflow
  - workflow/review
---
# Video Production Workflow Audit Batch 02

## Question
What do the ten new video notes add to Haunted Collector production quality and speed, and what must be corrected before using them?

jg confirmed the same priorities and ownership: better-looking assets and faster completion; Codex audits/briefs/reviews, Claude constructs/integrates, jg chooses targets and accepts results. Scope is whole-workflow assessment WITHOUT starting another pilot. Interview refinements remain pending. This is a research-readiness assessment, not a formal task pass or a production code audit.

## Sources
All ten new notes were read in `/Users/jg/Desktop/Rg1-worktrees/mrwonder-batch/02 Research/`; filenames below have prefix `RSH-20261014-` and suffix `-Video.md`. No original video was independently rewatched. The batch shares one uploader, MrWonderHow: ten notes are not ten independent corroborating sources.

Compared against existing Asset, UI, VFX, Audio and Reference Analysis workflows in the overhaul checkout. Inspected current task status for 0043/0048/0050/0052 for applicability only; did not move any status. Existing approved model process and the Wisp pilot remain separate.

Primary-source checks accessed 2026-10-14:
- Roblox network ownership/security documentation: https://create.roblox.com/docs/scripting/security/network-ownership
- ParticleEmitter API: https://create.roblox.com/docs/reference/engine/classes/ParticleEmitter and local creator-docs YAML.
- Motor6D description: local `~/Code/creator-docs/content/en-us/reference/engine/classes/Motor6D.yaml`.
- Blender Actions manual URL could not be retrieved. Action-delete/reset advice remains unverified, not corrected from memory.

## Observed mechanics (verified)
### Batch disposition
| New note | Useful candidate | Disposition and application | Evidence still needed |
|---|---|---|---|
| Hand-Built-ASYM-Monster | Joint/pivot planning, held attack poses, prop contact | Adapt rig-planning questions to creature tasks; keep the part-built output out of the visual quality baseline. No Wisp rig change proposed. | Actual rig/source review, motion and contact test; relevant original quality references, not index summaries. |
| Blender-R6-Animation-To-Roblox | Keep editable source; rig preparation and single-clip smoke test | Conditional reference for an actual R6 task; do not install its add-on/plugin or impose R6 prep on custom creatures. | Tool versions, maintained source/licence, non-upload local test; do not leave a runtime rig anchored due to import-only instructions. |
| Blender-Remove-Animation-Actions | Explicit action selection and clean export | Adapt as a preservation/diagnosis checklist, not automatic deletion. | Backup source, identify NLA/action users/fake users and desired clips; verify installed Blender version, export before/after. |
| Glowing-Sword-Aura-No-Script | Layered hierarchy, attachment planning, geometry-with-effects-off view | Best visual-workflow candidate: future TASK-0050 aura/effect spec records purpose per layer, orientation, lifecycle and measured cost. No build now. | Compare minimal layers at gameplay distance/multiple angles; particle/beam/overdraw cost and cleanup with many visible entities. |
| Anime-Flight-System | Reusable attachment-point effect templates and state-based visibility | Adapt template/lifecycle questions to VFX; defer flight, speed-line UI and server-cloned architecture. | Validate server-approved state, intended observers, client rendering choice, cancellation/late joins and replication. |
| Material-Footsteps | Small surface palette, material test strip, loading and fallback checks | Optional audio research backlog; footsteps are not automatically added to TASK-0040. | Inspect actual world surface signals and existing audio, load/length/licence checks, respawn/mute/default-sound conflicts, human listening. |
| Emote-Wheel | Data-driven action list, clear selection and cancellation | Existing data-driven UI practice; park radial pattern until a real screen needs it. No emotes or navigation replacement proposed. | Touch/controller/keyboard paths, cancel/focus-loss/death behavior, comparison with simpler menu. |
| Advanced-Movement-System | Shared action arbitration, central tuning, named input actions | Reuse structure as review questions, not movement feature scope. Reject security H2. | Actual state transitions, cleanup and server gameplay checks; input mapping alone does not prove parity. |
| Parkour-Vault-System | Opt-in tags and measure-before-act design | Existing interaction pattern; defer vault mechanic and reject security inference from tags/raycasts. | Server context/position checks, permitted geometry/landing space, interruption and latency tests if ever scoped. |
| Wall-Climbing-System | Explicit transition/cancel model and surface-detection tests | Background only. No climbing or mansion traversal change. | Actual motion around corners, server gameplay constraints, respawn/interruption cleanup and input behavior. |

### Readiness findings
| Priority | Source location | Finding | Required treatment |
|---|---|---|---|
| High | Advanced-Movement-System:54 (H2) | Says server validation is needed only for cosmetics/rate limiting while positions are not validated. | Reject as production guidance. Protect gameplay outcomes, permissions, distances and relevant movement context on server; effect validation does not establish movement integrity. |
| High | Parkour-Vault-System:49–50; Wall-Climbing controller claim | Tags/raycasts, non-competitive framing and automatic position replication are treated as safety signals. | Selection/detection/replication do not establish trust. Identify exactly what gameplay depends on before choosing validation. |
| Medium | All ten, evidence limits / observed headings | All are marked medium despite sparse contact sheets, incomplete sweep review, unreadable code/values and no listened audio. | Evaluate confidence per claim. Treat mechanics as source-reported unless frame-observed; code safety, motion quality and audio fit remain unverified. Do not raise confidence by note count. |
| Medium | Hand-Built-ASYM-Monster:59 | Generalizes the tutorial’s R15 setup into a constraint of Motor6D rigs. | Separate tutorial-specific Humanoid naming from joint capability. Local API describes an animatable connection between two BaseParts; do not impose humanoid layout on all custom rigs. |
| Medium | Glowing-Sword-Aura:43,52,57 | “Particles always face camera” and “client-visible only” are overly broad. | Particle orientation has selectable modes; facing and attachment motion are different decisions. Declare authority, replication and rendering ownership from inspected implementation, not appearance. |
| Medium | Blender-Remove-Animation-Actions:36 | “Cannot be deleted from Action Editor” is universal wording for version-sensitive behavior. Cleanup is destructive. | Keep as reported tutorial procedure, verify exact version and users, preserve source before deletion. Avoid deleting actions just to export one chosen clip. |
| Medium | Material-Footsteps, evidence limits | Sound quality is discussed without listening; script/IDs/default character sound assumptions unverified. | Load/measure/source safely, test lifecycle and mix, let jg choose by ear. Do not adopt the tutorial’s volume value. |
| Medium | All ten reference comparison sections | Index/research overlap checked, actual corresponding assets/code not demonstrated as inspected. | This is insufficient for finished-model comparison or safe code reuse. Open actual references/source only when a scoped task needs them. |

Official documentation confirms that client physics ownership has security implications, and movement validation must fit the game. It also documents multiple particle orientation modes. These checks correct the two generalizations above; they do not verify any video implementation.

### What this adds beyond batch 01
- Batch 01 established the research-to-task bridge and concept-first/representative-model process. Retain it.
- This batch adds concrete VFX layer/orientation/lifecycle questions, rig/action-source preservation and surface-audio lifecycle questions.
- Central tuning, input abstraction, action states, tags, cleanup and server validation are already workflow principles. Cite/reuse them instead of creating parallel frameworks.
- Traversal tutorials do not justify adding traversal to a capture collector. Their implementation complexity could slow the approved work without improving asset appearance.

## Hypotheses
1. Assigning each VFX layer a distinct communication role avoids expensive decoration that hides the model. Test only in a future approved effect task with a minimal-layer comparison; no pilot is started here.
2. A versioned animation-source/export manifest reduces repeated import troubleshooting. Test in a relevant animation task before creating a reusable recipe.
3. A compact research-disposition record is more useful than another general framework. Measure whether a later task can identify exactly which claim affected its artifact and verification.

## Relevance to our game
Highest near-term fit: VFX acceptance for TASK-0050 and animation/rig source hygiene for creature work. Surface footsteps are optional scope, radial UI is conditional, movement systems stay deferred. No new task, dependency, queue transition, Studio operation, plugin installation or paid call is authorized by this assessment.

Existing capabilities are sufficient: local Blender/Python tooling for version/source/export inspection; Studio MCP for later scoped motion/replication/profiling; watch for decision-critical frames; roblox-sfx for later audio sourcing/proof; existing UI and VFX patterns for implementation. No new skill or generator is warranted by this batch alone.

## Original implementation ideas
### Proposed checklist additions, not adopted global policy
**VFX:** event/purpose → intended viewers → attachment/orientation choice → minimum meaningful layers → start/loop/end/cancel → effects-off appearance → multi-entity cost and cleanup.

**Animation:** rig type and source/version → source preserved → explicit clip/action selection → transforms/pivots → representative contact/motion checks → export/import provenance → runtime unanchored/anchored state verified for actual use.

**Audio:** actual surface signal → small palette → default-sound coexistence → load/preload/fallback → repeated playback/mute/respawn → human listening and cost.

**Systems:** named actions and explicit state transitions → interruptions/cleanup → server gameplay validation independent of cosmetic relay → keyboard/touch/controller verification, not just input bindings.

Use a named existing task only when the lesson fits its approved scope. Disposition/owner/artifact/verification stays the traceability record. Do not install a competing movement framework, copy tutorial scripts or broaden the Wisp pilot.

## Recommendations (max 3)
1. Prioritize the VFX acceptance and animation-source preservation proposals; ask which should become concrete documentation proposals next, without building a new pilot.
2. Add source-readiness corrections in a scoped documentation package after the interview, preserving original hypotheses/history. Prioritize movement trust claims and particle orientation, then confidence labels and version-sensitive cleanup claims.
3. Keep traversal, footsteps and radial interaction patterns in a conditional backlog. Promote only when they answer a named approved production need.

## Needs human review
- Choose VFX/readability versus animation workflow as the first documentation emphasis, or retain both.
- Choose whether source-note corrections and index integration should be prepared after this interview; assessment alone does not claim those changes implemented.
- Actual motion, audio fit, code safety, plugin rights/maintenance and Blender cleanup behavior remain unverified. No original video or mesh was re-reviewed.
- Current vault check on 2026-10-14: types/format/lint/builds/JSON/queue, 125 specs and 41 Python tests pass; full suite fails on the same six pre-existing CSM broken-link occurrences. No formal AI task pass is issued. No Studio tests run.
- Current source notes remain in the mrwonder-batch worktree. This new assessment is in the main Obsidian vault, uncommitted. No chat was messaged and no pilot started.

## Interview outcome and documentation preparation (2026-10-14)
jg chose both areas with animation/rigging efficiency first, and authorized preparing source corrections and workflow proposals. Ten corrected note copies and ten index rows were prepared in `/private/tmp/rg1-video-workflow-adoption`; original mrwonder-batch worktree remains untouched. Historical hypotheses/confidence are preserved with explicit correction addenda. Proposals: [[RSH-20261014-Animation-Rigging-And-VFX-Workflow-Proposals]]. No pilot, code change, task transition or chat dispatch occurred. Package is unmerged; approved workflow files were not rewritten.
