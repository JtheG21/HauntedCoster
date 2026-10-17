---
id: REF-CODE-006
title: Orchestrated Agent Workflows
type: reference
status: approved
area: code
source: User-supplied video; original post URL unknown
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-16
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
- **Local source:** `/tmp/codex-remote-attachments/01a147e8-0f4c-70f3-8203-a85e6ba89679/C63BA418-80E9-4387-88D7-18EFBD225BF0/1-v1c025g50000db876afog65u6j3jm8r0.mp4`. Temporary attachment, not archived in Git.
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
