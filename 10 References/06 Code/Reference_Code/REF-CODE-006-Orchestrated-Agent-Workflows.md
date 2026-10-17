---
id: REF-CODE-006
title: Orchestrated Agent Workflows
type: reference
status: approved
area: code
source: User-supplied video; original post URL unknown
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Reference_Code_Index]]"
  - "[[REF-MISC-002-Reference-Library-Approach]]"
tags:
  - reference/code
  - reference/automation
  - reference/needs-experimentation
---
# Orchestrated Agent Workflows

## Identity
- **Original filename:** `v1c025g50000db876afog65u6j3jm8r0.mp4`; attachment filename `1-v1c025g50000db876afog65u6j3jm8r0.mp4`.
- **Local source:** `10 References/06 Code/Reference_Code/Media/REF-CODE-006-Orchestrated-Agent-Workflows/1-v1c025g50000db876afog65u6j3jm8r0.mp4`. Original video archived with this note; see the source-video embed below.
- **Source / rights:** User-supplied video with watermark @snackoverflowgeorge; original post, authorship and rights not independently verified.
- **Purpose:** Shared research direction for more reliable, less repetitive Roblox production workflows.
- **Status distinction:** jg supports investigating the organizational direction (2026-10-16); methods and tools remain **needs experimentation**. This is not approval to change existing workflow policy.

## Inspection and evidence limits
Local watch analysis: 161.5 seconds, 576×1024. Eight sampled frames viewed at 00:00, 00:21, 00:41, 01:08, 01:38, 01:59, 02:19 and 02:37; full-track automatic WhisperX small transcript read. Exact boundaries are approximate; some tool names are uncertain in transcription. No named repository or tool implementation inspected.

| Approximate time | Evidence |
|---|---|
| 00:00–00:24 | Speaker claims high PR throughput and quality; productivity and credential claims unverified |
| 00:24–00:57 | Discusses progressing from one agent/task to multiple sessions |
| 00:57–01:27 | Describes root and folder instructions, templates and scoped agent access; 01:08 slide shows AGENTS.md and folder structure |
| 01:27–01:57 | Discusses memory, recurring jobs, task queues and decision gates; 01:38 slide distinguishes automation and human review |
| 01:57–02:35 | Describes orchestrator/worker communication; 01:59 slide visibly names FirstMate and depicts isolated worker worktrees |

Do not treat a PR count as proof of correctness or a productivity target. The speaker's personal preference against worktrees does not supersede this project's worktree requirement.

## Intent — interview with jg, 2026-10-16
- The whole approach interests jg.
- Desired improvements: fewer repeated explanations, better handoffs, fewer mistakes and faster completion.
- Investigate when parallel agents are worth using.
- Study relevant named tools and transferable principles that can be applied with existing tools.
- Record both support for the organizational direction and the need for experimentation.

## Interpretation and application
- **Hypothesis:** Focused instructions, explicit ownership, reliable handoffs and event-based coordination may reduce supervision and context loss. Parallelism may help independent work but also adds coordination and resource costs.
- **Recommendation:** Compare with existing Task Intake, task gates, handoff templates and session/delegation budget before proposing new layers. Test a concrete bottleneck rather than adopting the entire depicted organization.
- **Potential adaptation:** Inspect one relevant tool's actual source/documentation and verify uncertain names before adding repository links or making capability claims. FirstMate is a visible research lead, not an inspected or approved dependency.
- Preserve one implementation owner, isolated worktrees, human merge/release gates, server authority and single-assistant Studio/Rojo ownership. This reference does not authorize additional agents, recurring jobs, installations or changes to approved policy.
- Any proposal to revise delegation limits must be explicit and separately approved; capturing interest in investigation does not change the current rules.

## Experiment and evidence to add
Define a scoped bottleneck and baseline; inspect selected source/version and dependencies; compare a simpler single-agent improvement with parallel work if separately authorized. Record output quality, defects, handoff completeness, repeated explanations, elapsed time, token/resource use when known and jg's judgment. Evaluate coordination overhead as well as speed. Retain failed and inconclusive findings.

## Open questions
- Which bottlenecks are instruction/handoff problems versus genuinely independent parallel work?
- Can existing tools solve them without an additional orchestration system?
- Which named tools are accurate, available and compatible with this Mac and project?

## Traceability
- No agents spawned, tools installed, scheduled jobs created or policy changes made.
- Next stage: investigate a concrete workflow gap and test a scoped improvement under existing rules.

## Review decision (2026-10-17)
- **Outcome:** keep as reference
- **Decided by:** jg
- **Summary:** Review 2026-10-17 of an approved research direction. The archived video (161.5 s, a creator's ladder from one agent to an orchestrated crew in about twelve slides: one agent one task, more tabs, tooling, persistent instructions (AGENTS.md), instructions by folder, templates with access limits, memory and cron and workflows, a task queue, a decision gate between automation and human review, orchestrator and workers, event-driven agent messages, project direction, and a personal FirstMate fork) was viewed as 48 frames over three contact sheets; the speaker's credentials and PR counts are on-screen assertions, unverified. The article its slide cites is real: 'How we built a software factory with Kiro Crew to merge 1,000 PRs in a week', published 2026-09-18 on kiro.dev, with five stages (one session by hand, many sessions by hand, memory plus dashboard plus cron and workflows, an agent pipeline of triage, implementation, review and merge stages, and Crew Mode with a coordinating agent). Its authors say every one of the 1,000 PRs went through CI and review, the figure came from the pipeline plus an early Crew Mode, a single coordinating agent can become a bottleneck, coordination has a cost, and humans still set the goals. FirstMate is verified: kunchenguid/firstmate, MIT, Shell, created 2026-06-12, about 8,000 stars, an agent distro of AGENTS.md, skills and scripts that runs a crew with one worktree and one visible tmux window per crewmate and event-driven supervision; it needs macOS or Linux, a supported harness, gh and tmux, offers a +yolo merge-autonomy flag and an optional relay that answers public mentions on X and Discord, which conflict with our human-merge and no-outward-posting rules. Herdr (Rust terminal multiplexer for agents, about 44,000 stars) has licence reports that disagree (Apache-2.0 per GitHub, AGPL per some third parties). Against our setup: sessions by hand, persistent instructions, memory and a gated queue exist; scheduled jobs, message-passing pipelines and autonomous orchestrator-and-worker crews are not authorized and would need separate delegation-policy approval. Current data: 40 tasks (37 done, 3 archived), nothing ready, mean revisions 0.45, so there is no backlog for parallel agents; the queue's start-to-review times mark orchestrator calls and are a weak baseline. Kept as a reference. Revisit when orchestrator.py next --parallel-safe repeatedly shows two or more independent ready tasks. FirstMate, Herdr and the Kiro article are named leads only: nothing installed, no policy change, no recurring jobs.
- **Evidence inspected:** Review packet; the archived video as 48 frames over three contact sheets plus scene-change beats; web search results for FirstMate, Herdr and the Kiro article; gh api metadata for kunchenguid/firstmate and the Herdr repositories; the FirstMate README (first 70 lines); the Kiro article through the fetch tool (a summarizer, so secondary); orchestrator.py status, next --parallel-safe and cycles on the current queue
- **Still unverified:** The speaker's claims, credentials and PR counts; the narration (no transcription tool is installed, so only on-screen text was read); FirstMate and Herdr behaviour when run (nothing installed); the Herdr licence; the full Kiro article text beyond the summarizer and whether its stages transfer to a solo Roblox studio; whether parallel agents would reduce completion time here
- **Next action:** none selected

## Archived source video
![[1-v1c025g50000db876afog65u6j3jm8r0.mp4]]
