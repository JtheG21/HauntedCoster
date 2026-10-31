---
id: AGENT-Handoff-ClaudeCode-20261025
title: "Handoff to Claude Code: activate GAME-004 MathShow, pause Hike or Die"
type: agent
status: done
receiver: claude-code
created: 2026-10-25
updated: 2026-10-25
---

# Handoff to Claude Code 2026-10-25

From: Claude (chat, claude.ai) · To: Claude Code · Approved scope: jg · Status: PR #121 merged (jg, 2026-10-25); intake complete

## State
- **GAME-004 MathShow** is the new active game (timed math gameshow). **GAME-003 Hike or Die is paused** (jg, 2026-10-25).
- Branch `chore/mathshow-setup` (worktree `~/Desktop/Rg1-worktrees/chore-mathshow-setup`), draft PR to `main`, waiting on jg.
  It adds `mathshow.project.json`, `scripts/new-service.sh`, `games/mathshow/DESIGN.md`, and an updated `AGENTS.md` project map.
- Claims to verify (not approvals): check.sh was green at the first commit (265 lune specs). The GAME-004 commit hasn't been checked yet.

## Your job (Light tier, Sonnet, no audit subagent)
Wait until jg confirms the PR is merged. Then, in a **new worktree** off updated `main`, run `04 Agents/Task Intake.md` for:
1. **Record the pause:** GAME-003 Hike or Die `00 Overview.md` → paused (jg decision 2026-10-25). Update `project-state.json` via `orchestrator.py`, not by hand.
2. **Create `03 Games/GAME-004 MathShow/`** from `99 Templates/` (Overview at minimum). Link `games/mathshow/DESIGN.md`; don't copy it.
3. **Queue the 8 slice tasks** from DESIGN.md "Tasks" in `tasks/queue.json`, with real IDs from the queue.
4. Stop after intake. Don't start Design task 1 (Scaffold) in this session.

## Known risk: check before Scaffold
- `scripts/new-service.sh` generates specs as `tests/<Name>Rules.spec.luau`, using `require(script.Parent.TestRunner)` and `TestRunner.T`.
  check.sh actually runs **lune specs** (for example `games/hike-or-die/tests/lune/*.spec.luau`). Compare against how check.sh
  finds specs; if they don't match, fix the template in the Scaffold task (flag it at intake, don't fix it now).
- `mathshow.project.json` maps `tests` → TestService. Drop that mapping if lune specs live outside the place.

## Don't
Touch `games/haunted`, `games/hike-or-die`, or `src/` (reading Hike or Die's RoundRules/RoundService as references later is fine).
Read `10 References/` this session. Publish, merge, or force-push.
