---
id: RSH-20261014-Video-Production-Workflow-Audit
title: Video Research Production Workflow Audit
type: research
project: GAME-002
status: research
confidence: medium
created: 2026-10-14
updated: 2026-10-14
sources:
  - Ten video research notes dated 2026-10-14, local checkouts inspected
  - Haunted Collector overhaul task queue and production workflows
  - User interview and Wisp concept approval in Codex, 2026-10-14
tags:
  - research/workflow
  - workflow/review
related:
  - "[[RSH-20261014-Wisp-Approved-Modeling-Handoff]]"
  - "[[3D Model Quality Baseline]]"
  - "[[Workflow]]"
---
# Video Research Production Workflow Audit

## Question
Which lessons from the ten new video notes are sufficiently supported and relevant to improve Haunted Collector production quality and completion speed, and how should they reach implementation?

This is a completed research-readiness assessment with proposed workflow improvements, not a formal task acceptance AUD or a change to approved workflow policy. Full-suite checks are not green. No task status, prior audit, production code or approved ADR is changed.

## Sources
| Source | Location | Accessed |
|---|---|---|
| Eight shared video notes | `/Users/jg/Desktop/Rg1-worktrees/video-3d-models/02 Research/` | 2026-10-14 |
| Blender animation note | Same directory, `RSH-20261014-Blender-To-Roblox-Animation-Import-Export-Video.md` | 2026-10-14 |
| CSM import note | `/Users/jg/Desktop/Rg1/02 Research/RSH-20261014-CSM-Custom-Rig-Import-Video.md` | 2026-10-14 |
| Video Research Index | `/Users/jg/Desktop/Rg1-worktrees/video-index/02 Research/Video Research Index.md` | 2026-10-14 |
| Production, Asset, UI and Reference Analysis workflows | `/Users/jg/Desktop/Rg1-worktrees/overhaul/04 Agents/Workflows/` | 2026-10-14 |
| Art direction, TASK-0043, TASK-0046 and queue | `/Users/jg/Desktop/Rg1-worktrees/overhaul/` | 2026-10-14 |
| Model design skill | `/Users/jg/.codex/skills/model-design/SKILL.md` | 2026-10-14 |

All ten notes were read; duplicate copies across worktrees had matching content hashes. Videos were not independently rewatched for this assessment. Evidence coverage below is what the notes report, not a new verification of their sources. Engine limits and vendor capabilities were not revalidated here.

## Observed mechanics (verified)
### User requirements and ownership
- Priorities: better-looking assets and faster completion; research must become useful to production.
- jg chooses visual direction, reviews key previews and accepts actual results.
- Individual versus representative-family approval is decided at intake, not imposed universally.
- Codex owns research audit, visual briefs and review; Claude owns construction and integration.
- Small experiments within approved scope are authorized. Free methods first; before any paid method explain cost, expected hours saved, uncertainty and alternatives, then obtain explicit approval.
- Wisp is the pilot. The final stitched, perched lantern-creature concept with actively gripping feet is visually approved; actual model construction, performance and acceptance remain unverified. See [[RSH-20261014-Wisp-Approved-Modeling-Handoff]].

### Research disposition: all ten notes
Names below abbreviate the `RSH-20261014-...-Video.md` filenames in the source directories.

| Note | Reported evidence | Production disposition | Named application and verification |
|---|---|---|---|
| AI-Incremental-Game-Pipeline | English captions; 12 of 82 frames viewed; low confidence | Use staged brief/concept/review; handoff practice already covered. Test generated-mesh/bake method only if needed. Defer genre mechanics. | Wisp/TASK-0043: approved concept → representative build → discrepancy review. Record time and revisions; do not assume savings. |
| Good-UI-Principles | Translated captions plus Gemini read, including conflicting modal assessment; medium | Adapt hierarchy, consistent icons, spacing and progressive disclosure. Reject fixed HUD/color counts as universal rules. | TASK-0048/0049/0051: one representative screen, narrow/desktop and state previews, task completion and input checks. Keep explicit acquisition/ownership/error labels. |
| Creature-Capture-AI-Build | English captions only; no frames; low | Use narration as a source of test ideas, not demonstrated visuals or security proof. | TASK-0048/0052: label near/mid/far checks and shared-target multiplayer test. Audio tour: repetition and relative loudness. No zone redesign implied. |
| Roblox-Viral-Game-Lessons | German auto-captions; 6 of 94 frames; low | Test fresh-player timed log and contextual tutorial timing. Defer monetization figures and economy changes. | TASK-0048/0052 or a separately scoped progression task: first capture/return/upgrade timestamps and blockers, no dev unlocks. Test-reset only in isolated authorized memory profiles; never live data. |
| Roblox-Game-95k-Monthly-Revenue | Creator slides/dashboard screenshots; medium | Defer pricing/ads/revenue extrapolation. Use community feedback and cadence as future planning questions. Reject a new ban on AI UI art inferred from opinion. | Post-launch analytics/pricing work only when separately scoped. No prices, ad spend or revenue forecast derived here. |
| Mixamo-Custom-Rig-And-Camera | Captions and contact sheets; medium | Extract scale/texture/animation-fit checks. Reject one-mesh/one-texture as mandatory completion definition. Do not import toolbox camera systems. | Future suitable skeletal asset: reproduce in scratch scene. Wisp uses articulated gripping parts, not proven compatible humanoid assumptions. |
| Mixamo-Skinned-Mesh-Character | Captions and contact sheets; medium | Test animation-fit procedure when rig type requires it. Do not adopt universal Scale-reset/plugin instructions. | Suitable future rig: compare source and imported pose/motion at intended scale; do not install a plugin merely because tutorial uses it. |
| Monster-NPC-Sculpt-And-Rig | Captions and contact sheets; medium | Use stage order and rig-suitability question. Result skips texture finish and is not a visual benchmark. Reject uncertain triangle targets and importing the chase kit. | Creature intake records skeletal/procedural/rigid method and required poses. Model quality floor remains authoritative. |
| Blender-To-Roblox-Animation-Import-Export | Captions; 15 cue frames viewed, sweep unviewed; medium | Test specific export settings on a tiny relevant rig. Defer 24-fps/lag assertion, pivot shortcuts and importer-option claims. | Only if skeletal animation selected: short reproducible import test with foot/hand contacts and measured export/import result. |
| CSM-Custom-Rig-Import | Captions, cue frames and scene contact sheets; medium | Use visual-versus-technical acceptance distinction. Test generator/decimation/deformation claims before reuse. Verify current limits from primary docs when needed. | Wisp: visual form, materials and gripping feet first; measured topology, motion and runtime checks separately. No humanoid conversion assumed. |

### Findings requiring correction before promotion
| Priority | Location | Finding | Required treatment |
|---|---|---|---|
| High | All video notes, Observed mechanics heading | “Verified” can mean only stated in captions, not reproduced or independently viewed. Caveats help but the label overstates readiness. | Distinguish source-reported, frame-observed, locally reproduced and accepted-in-production evidence per claim. |
| High | Mixamo-Custom-Rig-And-Camera:72,78,84 | One mesh/texture is generalized into finished-asset acceptance. Current creature source already has separately movable arms/lantern. | Require appropriate part/material structure and measured cost, not a universal join operation. |
| High | AI-Incremental-Game-Pipeline, H6 | “No exploit surface if server-side only” overstates security. Server timestamps alone do not prove correctness. | Require bounded accrual, validated stored timestamps, idempotency and persistence review if the mechanic is ever scoped. |
| Medium | Blender-To-Roblox-Animation-Import-Export:46,81 | Frame-rate performance effect is a practitioner claim, not measured. | Keep test-first; measure only when this choice affects a selected rig pipeline. |
| Medium | Mixamo-Skinned-Mesh-Character:57,69 | Scale instructions are tied to a particular importer/plugin workflow. | Diagnose intended scale, transforms and rig compatibility with a minimal reproduction; no universal reset rule. |
| Medium | Roblox-Game-95k-Monthly-Revenue:73 | Hand-authored-only UI requirement is attributed to reference-first rules without establishing that requirement. | Judge reference fit, clarity and finish; disclose opinion rather than inventing project policy. |
| Medium | Good-UI-Principles:37,40 and evidence limits | Arbitrary counts and secondary-model interpretation can become design dogma. | Use flexible review questions, retain needed text, validate representative screens. |
| Medium | Video Research Index | Eight rows omit Blender and CSM notes; notes are distributed across branches. | Update index in the appropriate integration change and identify authoritative paths. Do not silently merge branches. |
| Medium | CSM note in current vault | Six broken-link occurrences reference records unavailable in this checkout. | Reconcile through scoped documentation integration; do not invent missing records or change task state. |

### Existing workflow coverage and gaps
Already covered: scoped tasks, reference inspection, server authority, cheap checks before audits, local playtests, human merges, revision limits and context handoffs. Keep these; repeated video agreement does not justify another parallel orchestrator.

Improve application: turn relevant research into a specific deliverable/check at task intake; approve a representative visual target before broad production; record actual-model comparison separately from technical checks; retain accepted recipes and failures so the next task reuses evidence instead of rereading whole tutorials.

No automatic gate is being added here. The pilot tests this proposed operating practice before a formal workflow edit.

### Available capabilities matched to work
| Capability | Appropriate role | Boundary |
|---|---|---|
| model-design + imagegen | Interview, concept refinement, accepted/change/rejected record, visual brief | Image is a target, not mesh/topology/motion proof. Wisp concept is approved. |
| Local Blender/Python/Luau tooling | Repeatable build, export, renders and measured checks | Claude owns implementation; method must achieve the visual floor. |
| Roblox Studio MCP | Scoped inspection, captures, motion/gameplay verification | Coordinate ownership and correct Studio/place/Rojo first. No competing shared-session changes. |
| watch | Inspect only decision-critical timestamps when note evidence is inadequate | No automatic paid fallback; record viewed coverage and unverified claims. |
| Design critique/accessibility skills | UI hierarchy, states and contrast/input review | A screenshot cannot establish controller behavior or screen-reader support. |
| roblox-map / roblox-sfx | Appropriate map proof or verified sound sourcing | No map bootstrap in managed game places; no scope expansion from keywords. |
| Skill creation | Package a repeatable accepted method | Create only after evidence supports reuse; no new skill is necessary for the Wisp interview process. |
| Meshy/Tripo alternatives | Potential candidate if local method cannot reach target efficiently | Availability does not establish free use. Do not invoke billable generation without approval. |

## Hypotheses
1. A defined target plus one representative build reduces expensive family-wide rework. Test with Wisp: time to reviewable model, discrepancy list, revision count and measured usage where available. No reliable savings baseline exists yet.
2. Compact reusable recipes reduce repeated reference reading. Test on the next similar accepted asset; record whether the recipe actually transfers.
3. Research becomes more useful when each selected claim has an owner, task, artifact and verification. Test by tracking Wisp and one UI task, not by measuring number of notes written.

## Relevance to our game
The current vault queue contains older completed tasks; the overhaul worktree contains TASK-0042–0052. These are different checkout snapshots, not permission to reconcile statuses by inference. Wisp work belongs with TASK-0043, not TASK-0046 mansion/train construction. This review provides guidance accessible from the main vault without modifying Claude’s active worktree.

### Proposed task-intake addition
For a task, select only the lessons that affect a real decision. Record:
- Claim/source and evidence level.
- Disposition: use now, test first, already covered, defer, reject.
- Task owner, expected artifact and verification.
- Approval mode: individual or representative-family, with reason.
- Reuse result after acceptance; known failure or limit if rejected.

For unique hero creatures with distinct anatomy, review individually. For repeatable modular pieces with fixed construction/material rules, representative-family review may suffice. Natural variants require a separate decision about their differences; approval of this Wisp does not automatically approve every creature or variant.

## Original implementation ideas
### Wisp pilot execution package
1. Claude reads [[RSH-20261014-Wisp-Approved-Modeling-Handoff]] and opens the actual concept before construction; verifies task ownership/revision allowance from the current queue.
2. Establish real scale and inspect method suitability. If technically uncertain, make the smallest scratch sample that resolves it: head/grin finish or feet/bracket contact, rather than building a whole family.
3. Construct one reviewable Wisp matching the accepted silhouette, expression, stitches, pole, weathered lantern and gripping toes. Expose any fidelity/performance trade-off before reducing quality.
4. Codex compares all views and motion to target; jg reviews key previews and accepts the actual result. Keep visual verdict separate from runtime evidence.
5. Record source/settings, costs, comparisons, accepted changes and failure limits; only then consider family reuse. Two production revisions maximum unless jg explicitly changes scope/allowance.

### Proposed success measures
Track time to first reviewable asset, time to acceptance, revisions, specific visual discrepancies, performance cost and usage when known. Report unknowns. Avoid treating tests passed, triangles produced or notes written as proof of better-looking assets.

## Recommendations (max 3)
1. Run the approved Wisp pilot using the saved target and one representative model; retain its measured outcome as the first recipe candidate.
2. In the next scoped documentation change, repair evidence labels and unsupported generalizations, integrate the missing index rows, and connect task-relevant findings without rewriting historical conclusions as verified passes.
3. After the pilot, propose a small edit to existing intake/asset/UI workflows based on demonstrated benefit. Do not install a competing orchestrator or codify all ten videos as rules.

## Needs human review
- Actual Wisp model acceptance, technical method feasibility and family/variant approval remain pending.
- Workflow changes beyond the authorized pilot remain proposals.
- Original video claims, frame coverage, current engine limits and vendor terms were not independently verified in this review.
- Formal task acceptance is not issued. Prior overhaul check: 153 specs passed, typecheck write blocked by sandbox. Current vault check on 2026-10-14: formatting, lint, types, 125 specs, both Rojo builds, JSON, queue and 41 Python tests passed; full suite failed only on the six existing CSM broken-link occurrences. No Studio playtest was run for this research review.
- This note is saved locally and uncommitted. Other worktrees must use its absolute path until a human-approved integration carries it.

## Recommendation execution (2026-10-14)
- Prepared an isolated documentation package on `chore/video-workflow-adoption` at `/private/tmp/rg1-video-workflow-adoption`, based on overhaul commit `1e9ee4f`; Claude’s active worktree was not edited.
- Consolidated all ten video notes and the index; added per-note production corrections and provenance distinctions while retaining earlier hypotheses and evidence limits. Added the missing Blender/CSM index entries.
- Reused the existing approved Model Approval Workflow and its recipe template. Added the approved Wisp target and pilot instructions to TASK-0043 without changing queue state. No new global workflow policy was silently approved.
- The Wisp handoff has been dispatched with jg’s explicit authorization. Actual modeling, experiments and acceptance remain with the implementation owner and are not claimed complete. No recipes or speedups are claimed verified.
- Documentation-package checks: 153 specs, 44 Python tests, format, lint, types, both builds, JSON and queue checks passed. Vault check reports two inherited status mismatches: TASK-0044 note `in_review` versus queue `changes_requested`; TASK-0046 note `ready` versus queue `in_progress`. Those files were not changed in this package. Queue remains authoritative; implementation owner must reconcile through the existing process. This is not a full-suite pass or formal AI acceptance audit.
- Main-vault notes link to the isolated package for discovery. The full source consolidation and corrections are unmerged; main-vault CSM link errors are not claimed repaired there. No publishing, uploads, spending or merge occurred.

## Dispatch (2026-10-14)
jg explicitly requested sending this package to the existing model-approval implementation chat. Sent to Codex chat `01a13bd8-f14a-79e1-81b2-c2073dad1818` with artifact paths, task/revision gate checks, inherited mismatch warnings and required acceptance evidence. Successful delivery does not establish model completion.
