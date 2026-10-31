---
id: RSH-20261015-Claude-Restart
title: Claude Restart
type: research
status: research
project: GAME-002
sources:
  - /Users/jg/Desktop/Rg1-worktrees/overhaul/tasks/queue.json
  - /Users/jg/Desktop/Rg1-worktrees/wisp
confidence: high
created: 2026-10-15
updated: 2026-10-15
tags:
  - workflow/production
---
# Claude Restart

## Question
Where should Claude resume, and what startup housekeeping is needed?

## Sources
| Source | Location | Accessed |
|---|---|---|
| Task authority | `/Users/jg/Desktop/Rg1-worktrees/overhaul/tasks/queue.json`, task notes and project-state | 2026-10-15 |
| Revision source | `/Users/jg/Desktop/Rg1-worktrees/wisp`, clean at `0c3108e` | 2026-10-15 |
| Approved brief | [[RSH-20261014-Wisp-Approved-Modeling-Handoff]], [[RSH-20261014-Wisp-Revision-Readiness]], [[Wisp Pilot Start Here]] | 2026-10-15 |
| Startup checks | `/private/tmp/rg1-restart-check-full.log` | 2026-10-15 |

## Observed mechanics (verified)
- Main vault checkout is `chore/vault-navigation` at `8d6955d`; its queue stops at TASK-0039. Preserve existing user edits and untracked research.
- Overhaul is on `task/TASK-0046-Mansion-Plot-And-Train-Art` at `1e9ee4f`, with existing uncommitted task/queue/state changes. Its queue has 51 tasks: 37 done, 3 archived, 2 approved, 7 in progress, 1 changes requested, 1 ready.
- TASK-0042/0045 are approved, not merged. TASK-0043 is in progress, revision 1/2. TASK-0044 has changes requested, revision 1. TASK-0046–0051 remain in progress. TASK-0052 is ready; check dependencies and acceptance evidence before starting it.
- Wisp revision source is on `task/TASK-0043-Wisp-Revision`; its inherited queue incorrectly reflects the older approved revision 0. Do not use it to reset authoritative status.
- Rojo PID 33608 serves `haunted.project.json --port 34872` from overhaul. Observed process arguments and parent command establish the serving checkout; Studio connection and place were not inspected.
- Full overhaul `scripts/check.sh` passed: 153 Luau specs, 44 Python tests, formatting, lint, types, both builds, queue (51 tasks/0 errors), vault (0 errors/0 warnings). First sandbox run could not write a typecheck sourcemap; permitted rerun passed. No fresh Studio gameplay or visual validation was performed.
- Refreshed generated project-state and `08 Reviews/HLT-20261015.md` through the overhaul orchestrator. No task transitions, revision increments, source edits, commits or merges.
- Prior evidence: TASK-0044 two-player HauntedTrees was 23/28 and remains unpassed; TASK-0047 Cosmetics scenario was written but not run. Schema 2 needs human approval before merge. These are task-record observations, not newly repeated tests.

## Hypotheses
Resume the existing Normal Wisp revision first, one scoped task at a time. This recommendation follows the latest explicit production handoff; it does not establish actual model acceptance.

## Relevance to our game
M1/M3 gameplay baseline exists. Current work is the art/UI/cosmetics overhaul, with visual and integration acceptance still outstanding. Physical device checks and six-player profiling remain deferred.

## Original implementation ideas
The prompt below pins task authority separately from implementation source and requires checking the running Studio/Rojo path before integration.

## Recommendations (max 3)
1. Resume TASK-0043 within revision 1/2 using the approved Normal Wisp brief.
2. Preserve checkout histories and edits; keep task state in overhaul rather than copying queues among worktrees.
3. Complete visual/motion and local integration evidence before broad overhaul verification or acceptance claims.

## Needs human review
Actual model acceptance, fidelity trade-offs, final runtime budget, schema changes, publishing, uploads, paid calls and merges remain gated. No new approvals are implied by this restart note.

## Claude restart prompt
```text
Resume GAME-002 Haunted Collector. Read /Users/jg/Desktop/Rg1/AGENTS.md and the applicable workflow/asset instructions first. This is a continuation of the existing approved local work, not authorization to publish, upload, spend, configure live products or merge.

Read /Users/jg/Desktop/Rg1/02 Research/RSH-20261015-Claude-Restart.md for the verified startup snapshot. Task authority is /Users/jg/Desktop/Rg1-worktrees/overhaul/tasks/queue.json and its mirrored task notes. The main vault queue is behind; the Wisp revision checkout also carries stale task state. Do not replace queues or erase existing edits.

Startup housekeeping has been performed: overhaul check.sh passed on 2026-10-15 (153 Luau specs, 44 Python tests, types/lint/builds/queue/vault); the orchestrator health report and generated state were refreshed. Recheck Git status and the authoritative queue for changes since that inspection. Avoid repeating the full check suite until changes justify it. Keep historical failures and approval gates visible.

Continue only TASK-0043, Normal Wisp pilot, within its already recorded revision 1/2. Implementation source: /Users/jg/Desktop/Rg1-worktrees/wisp on task/TASK-0043-Wisp-Revision, inspected clean at 0c3108e. Authority: overhaul records in_progress, revision 1; the older approved audit is not acceptance of this revision. Do not increment the revision just to fix stale documentation. Verify these paths/branches before edits and run preflight chained to every state-changing Git operation. Do not switch branches under the running Rojo server.

Read /private/tmp/rg1-video-workflow-adoption/02 Research/Wisp Pilot Start Here.md and its approved modeling handoff, plus /Users/jg/Desktop/Rg1/02 Research/RSH-20261014-Wisp-Revision-Readiness.md and RSH-20261014-Wisp-Four-Note-Prebuild-Review.md. Check which documentation is already integrated; do not reapply commits blindly. Read 10 References/05 Misc/3D Model Quality Baseline.md and open the relevant original gallery assets. Keep the approved perched concept and pose fixed. Prioritize recessed eyes/sockets, thinner integrated mouth lacing, irregular head/curl silhouette, shaped body seams and convincing aged lantern construction. Preserve grips and slim toes. Normal only; defer variants until acceptance.

Retain full-detail editable source; plan rig/rest pose separately from presentation and record transforms. Show matched front/side/rear/three-quarter neutral views, effects-off/night comparisons, face/grip/lantern close-ups and actual motion/contact evidence. Do not claim completion from still renders or old audit results. Proposed triangle targets are not an approved simplification mandate; measure visual contribution and representative load before recommending a budget.

Rojo was serving haunted.project.json from overhaul on port 34872 (PID 33608). Recheck the process, actual Studio place and source before connecting. Wisp edits do not automatically reach that server. Do not connect default.project.json to Haunted Collector, run a map bootstrap or take over another active session. Establish a deliberate local preview/integration route before touching Studio; keep source edits and authoritative task bookkeeping in their identified checkouts.

After substantive changes run the relevant checks and required local scenarios before any independent audit. Respect the two-revision limit. Report concrete evidence, remaining failures and anything requiring jg's decision; never convert pending visual acceptance into done. Update the task Outcome/system/overview/architecture notes and state only as warranted by actual work and the orchestrator. Stop at the scoped review package or a real approval boundary, without rolling into other overhaul tasks.
```
