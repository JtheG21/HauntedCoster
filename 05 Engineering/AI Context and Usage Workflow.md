---
id: ENG-AI-Context-And-Usage
title: AI Context and Usage Workflow
type: index
status: approved
created: 2026-10-18
updated: 2026-10-18
tags:
  - engineering/workflow
  - engineering/usage
related:
  - "[[AGENTS]]"
  - "[[Task Intake]]"
  - "[[Workflow]]"
  - "[[ADR-0009-Shared-Production-Foundation]]"
---
# AI context and usage workflow

How an agent session gets its instructions, how a task's prompt is built, what is measured, and when to start fresh. Shared by every Roblox project in this repo; project paths and IDs stay in the game's own notes.

Status: approved for the workflow changes listed under "What changed" (jg's request, 2026-10-18). Measurements are local and deterministic; token figures are estimates, not API-reported usage.

## Baseline (measured 2026-10-18)

Measured with `python3 scripts/context_budget.py` on the `main` checkout at commit `494be30`. Bytes are exact. Tokens are bytes / 4 (estimate).

| Context | Bytes | Est. tokens | When loaded |
|---|---|---|---|
| `CLAUDE.md` + `AGENTS.md` (imported) | 17,630 | ~4,400 | Every session |
| Skill descriptions (8 project skills) | 4,507 | ~1,100 | Every session (listed, not read) |
| `.claude/agents/auditor.md` | 2,337 | ~580 | When an auditor subagent starts |
| `Task Intake.md` + `Workflow.md` + `Executor.md` | 13,905 | ~3,480 | Task start, on instruction |
| Skill bodies (8 skills) | 79,470 | ~19,900 | Only when invoked; `roblox-map` alone is 50,932 |
| Dispatch prompt (executor, last task with a note), before this change | 472 | ~120 | Per dispatch |
| Dispatch prompt (same task), after this change | 1,605 | ~400 | Per dispatch |

Findings:

1. **Verbatim duplication is not measured.** No sentence of 60+ characters repeats across `CLAUDE.md`, `AGENTS.md` and the start docs. The suspected duplication was not confirmed, so no root rule was cut. Removing durable safety, governance or validation rules to save tokens would trade correctness for little gain.
2. **The biggest always-on cost is `AGENTS.md`** (about 3,200 estimated tokens). It holds rules every session needs, so it stays. The largest optional cost is a skill body, which loads only when that skill is invoked.
3. **The dispatch prompt was not the bottleneck** (about 120 estimated tokens). It did not state acceptance criteria or the expected file list, so the agent had to re-derive scope from the note. That is now included (see below), at a cost of about 1.1 KB more per dispatch. Whether this saves exploratory reads is not measured yet.
4. **Usage records are incomplete.** `tasks/usage-ledger.jsonl` has 44 rows, all `kind: subscription`. 15 have `tokens: null` and 17 have an empty `model`. Entries are written by hand through `record-usage`; the workflow has no automatic capture of session usage. Missing values are recorded as unavailable, not backfilled.
5. **A Codex skill copy had drifted.** `.agents/skills/roblox-sfx/SKILL.md` pointed at `.Codex/skills/...` instead of `.claude/skills/...`, and the copy test did not cover it. Fixed; the test now covers `roblox-map` and `roblox-sfx`.

## What changed

- `scripts/orchestrator.py` `build_prompt`: the dispatch prompt now lists the task's `acceptance_criteria` from `tasks/queue.json` and its "Files expected to change" from the task note. It adds no stored field, so the queue and note stay the only sources of truth. Tasks without a note get no file list.
- `scripts/context_budget.py` (new, read-only): reports the context table above. Run it after changing any instruction file to see the effect.
- `.agents/skills/roblox-sfx/SKILL.md`: copy restored to match `.claude/skills/`.
- `tests/test_orchestrator.py`, `tests/test_claude_hooks.py`, `tests/test_context_budget.py`: cover the prompt scope, the copy check and the measurement.

## Daily workflow

1. **Start:** `python3 scripts/orchestrator.py status` and `next`, then the task note. Read `AGENTS.md` (already loaded), then only the project notes the task touches.
2. **Dispatch:** `python3 scripts/orchestrator.py dispatch TASK-#### --role executor` writes the prompt to `tasks/prompts/`. It makes no AI call (dry-run is the only mode).
3. **Implement and check:** `scripts/check.sh` before any review. Use focused checks while iterating (`lune run`, `selene <file>`, `stylua --check <file>`).
4. **Record:** `record-exec`, then `record-audit`, then `record-usage` with the tokens if they are visible in the session, otherwise omit `--tokens`. Never estimate a token count into the ledger.
5. **Measure:** `python3 scripts/orchestrator.py cycles` shows revisions, audits and start-to-review hours per task. It reports `n/a` where tokens were not logged.

## Context management

- **Continue in the same session** while the task is open and the context is still relevant.
- **Start fresh** when the objective changes, when the session passes about 150k tokens (AGENTS.md), or after an interrupted task. Write a short handoff in the task note first.
- **Recover from persisted state, not from the conversation.** A fresh session reads, in order: the queue entry (status, acceptance criteria, files expected), the task note (Implementation record, Outcome, Handoff), `git -C <worktree> status` and log on the task branch, then the latest audit under `06 QA/`. A prior assistant summary is never more authoritative than the working tree.
- **`/compact` and `/clear`** are interactive Claude Code commands. Run them yourself in a terminal session; this workflow cannot run them and does not pretend to.

## Retrieval rules

- Start narrow: the task note, its expected files, and the matching `10 References/` folder from the reference brief.
- Widen only with a reason written in the task note: a cross-system change (capture and habitat rotation, for example), an unexpected dependency, or a failing test that points elsewhere.
- Large skill bodies (`roblox-map`, `roblox-sfx`) are read only when that skill is the task's tool.

## Validation tiers

Run the cheapest tier that covers the change, and escalate only on failure:

- **A, deterministic:** `stylua --check`, `selene`, `scripts/typecheck.sh`, JSON parse, `orchestrator.py validate`, `validate_vault.py`, `refs.py lint`, `skill_lint.py`.
- **B, focused tests:** the Lune spec for the touched module, or the matching `tests/test_*.py`.
- **C, integration:** `rojo build` for both project files, then `scripts/check.sh` in full.
- **D, Studio:** only with `studio-preflight` green, one assistant at a time, on the synced code. Never claim a Studio pass from static checks.

## Troubleshooting

| Symptom | Check |
|---|---|
| Prompt much larger than expected | `python3 scripts/context_budget.py --sample TASK-####`; the prompt section shows its size |
| Agent reads many files | Compare the prompt's "Files expected" list with what it opened; if the list is missing, the note's `## Files expected to change` heading is absent |
| Skill copies differ | `python3 -m unittest tests.test_claude_hooks`; the copy test names the skill |
| Duplicated instructions | `context_budget.py` `duplication` section lists repeated sentences |
| Missing usage | `orchestrator.py cycles` shows `tokens=n/a`; that is correct when the session did not expose tokens |
| Failed handoff | `orchestrator.py validate` and `validate_vault.py` flag queue or note mismatches |
| Broken dispatch | `python3 -m unittest tests.test_orchestrator` |

## Maintenance: inheriting in a new project

Nothing project-specific lives here. A new Roblox project gets the workflow by sharing the orchestrator, `context_budget.py`, `AGENTS.md`'s rules and this note. It keeps its own `CLAUDE.md` for project paths and commands, and its own `queue.json`. Do not copy large configuration blocks; link this note.

## Deferred

- Per-task automatic token capture: not available from the workflow today. Revisit only if Claude Code exposes usage to hooks or a local file.
- Context manifests as a separate file: the queue and note already hold the scope, so a second manifest would become another source of truth.
- Live dispatch: still disabled by design (`dispatch_mode` must stay `dry-run`).
- Scenario D (interrupted-task recovery) was inspected by reading the recovery order above, not executed in a live session.
