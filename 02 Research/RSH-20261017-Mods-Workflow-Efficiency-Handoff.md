---
id: RSH-20261017-Mods-Workflow-Efficiency-Handoff
title: Mods Workflow Efficiency Handoff
type: research
status: proposed
sources:
  - https://code.claude.com/docs/en/plugins/mods/overview
confidence: medium
created: 2026-10-17
updated: 2026-10-17
tags:
  - research
  - workflow/process
related:
  - "[[Task Intake]]"
  - "[[Workflow]]"
  - "[[Resource Catalog]]"
---
# Mods Workflow Efficiency Handoff

## Question
After installing Claude Code mods, how can we reduce process overhead and AI usage while retaining the controls that prevent meaningful mistakes?

## Sources
| Source | URL | Accessed |
|---|---|---|
| Anthropic mods documentation | https://code.claude.com/docs/en/plugins/mods/overview | 2026-10-17 |
| jg direction and discussion | This repository-review chat; recorded below | 2026-10-17 |

## Observed mechanics (verified)
- Fact: official docs describe mods that draw panels, route model requests and message sessions. Mods run with user permissions and are not sandboxed.
- Fact: jg said the goal is to be extremely efficient and ship projects, using only the process needed, without wasting tokens on small actions that receive routine approval.
- Decision: jg requested this note for Claude to read after mod installation. This is a handoff of intent and proposed changes, not approval of every policy edit below.
- Evidence limit: this session did not install or test a mod, establish installed versions, or measure net savings.

## Hypotheses
- Repeated permission requests for already authorized reversible work, duplicated records, broad rereads and redundant checks consume effort without necessarily preventing errors.
- A deterministic read-only panel may improve visibility without additional model calls. A router may save usage only if routing overhead and retries do not erase the savings.
- Neither hypothesis has measured results yet. Time and tool-call counts are proxies, not token or monetary savings.

## Relevance to our game
Shipping useful, tested work is the goal. Task ownership should prevent conflicting edits, not require extra conversations. Human approval should cover consequential decisions once, when a concrete result is reviewable. Preserve the authoritative queue and avoid creating a competing orchestrator.

## Original implementation ideas
### Proposed minimum process
| Retain | Automate within an authorized scope |
|---|---|
| Explicit approval for spending, publishing, merging, destructive actions and consequential unresolved design changes | Reads, research, reversible edits, relevant checks, notes, commits and pushes to the established project remote |
| One accountable implementation owner and isolated worktrees | Routine handoffs, status recording and silent checkout guards |
| Independent review for security, networking, persistence and substantial behavior changes | Small documentation and low-risk tooling changes with appropriate deterministic verification |

These are proposals wherever they differ from current AGENTS.md or Workflow requirements. Do not silently rewrite or bypass existing policy. Scope and dependencies matter: a small-looking tooling edit can still affect security or production.

### Reduce repeated work first
- Record evidence once in its authoritative location and link it from other records. Avoid restating the same results across TASK, SYS, overview and architecture notes when no fact there changed.
- Load only the instructions and files needed for the current task. Reuse evidence already established in the session.
- Run checks appropriate to the change, plus checks currently required by policy. After success, repeat only for new changes, failures or unresolved concerns. Propose any required-check policy change explicitly.
- Batch genuine questions. Do not ask again for authorization already supplied. Interrupt only for missing consequential decisions, blockers or materially changed scope.
- Avoid recurring model-generated status summaries and automatic session chatter. Event-driven deterministic updates should be preferred when sufficient.

### Suggested order after mods are installed
1. Inspect the installed mods, their source, event handlers, dependencies and permissions without reading credentials. Identify duplication with existing hooks and tooling. Do not enable automatic tool approval or cross-session messaging from this note.
2. Locate the smallest actual overhead source in a recent task and propose a compact policy diff. Resolve only real conflicts with existing rules; do not restart a general workflow interview.
3. If visibility is still needed, trial a read-only panel showing active task, branch/worktree, latest check evidence and available usage figures from authoritative sources. Mark unavailable or stale data honestly. No model call is needed merely to refresh local state.
4. Consider model routing later, initially for clearly simple documentation or formatting tasks. Keep security, networking, persistence and required independent reviews under their existing rules. A deterministic edit may need no model at all.
5. Measure one bounded task before and after: completion time, interruptions, repeated reads/checks, actual model usage where available, correctness and rework. Keep only improvements with a clear benefit; remove experiments that add maintenance without benefit.

Acceptance: less repeated work and fewer unnecessary interruptions, with required checks passing, no conflicting ownership, no missed material approvals and no unsupported savings claims. No numeric savings target has been established.

## Recommendations (max 3)
1. Simplify unnecessary process before automating it; do not build a dashboard or router merely because mods make it possible.
2. Present jg with one small, concrete policy change where approval is genuinely required. Continue already authorized independent work in the meantime.
3. Keep platform approval review separate from project policy. Mods must not bypass platform controls. If a platform rejection blocks completion, explain the specific action and reason rather than inventing another approval layer.

## Needs human review
- Proposed policy differences above are not yet adopted. Read current rules and identify the exact changes needed before implementation.
- Installed mod identity, source safety, compatibility and runtime behavior remain unverified here.
- No installation, spending, live-game modification, merge or automated message to another chat is authorized by this note alone.

## Session handoff
Claude: read this after mod installation. jg wants the minimum effective process and projects shipped, not more coordination machinery. Start with existing authorization, inspect relevant current rules, and eliminate demonstrably redundant work. Keep approvals concentrated on consequential actions. This handoff is documentation only; no policy, queue status or game code changed.
