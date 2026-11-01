---
id: TASK-0117
title: "Codex Hook Adapter"
type: task
project: GAME-004
status: backlog
priority: medium
risk: medium
owner: codex
depends_on: []
branch: task/TASK-0117-codex-hook-adapter
related: []
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---

# Codex Hook Adapter

## Goal
Bridge Codex hook payloads to the existing Claude hook scripts without copying their implementation.

## Scope
- **In:** `.codex/hooks/adapter.sh`, portable hook configuration, Codex payload fixtures in `tests/test_claude_hooks.py`, and removal of the temporary hook ignores when supported wiring is ready.
- **Out:** implementing the adapter during registration, game code, publishing, user-level config and automatic trust approval.
- **Keep unchanged:** `.claude/` hook sources, AGENTS.md and check.sh.

## Intake
- **Category / depth:** tooling, standard (requested by jg).
- **References:** no external code imported. Official payload contract: https://learn.chatgpt.com/docs/hooks#pretooluse
- **Reuse:** Resource Catalog's Claude Code guard and format hooks; reuse `.claude/hooks/guard.sh`, `luau-format.sh` and `ref-lint.sh` as the single source.
- **Fact:** installed CLI 0.164.0-alpha.11.1; Bash and apply_patch use `tool_input.command`. Edit/Write are matcher aliases, not a guarantee of `tool_input.file_path`. The existing guard's ask response is unsupported by Codex.
- **Decision (jg, 2026-11-01, D6):** register backlog only; no adapter implementation or standing automation approval.

## Files expected to change
- `.codex/hooks/adapter.sh`
- `.codex/hooks.json`
- `.gitignore`
- `tests/test_claude_hooks.py`

## Acceptance criteria
- [ ] Bash payloads pass through unchanged to the single-source .claude/hooks scripts.
- [ ] apply_patch command payloads are parsed for every touched file path (including additions, deletions and moves); invoke the relevant .claude/hooks scripts once per file with Claude-style tool_name and tool_input.file_path fields.
- [ ] Translate permissionDecision ask into block (exit 2) and preserve the reason; never silently allow an unsupported approval decision.
- [ ] Hook commands resolve the repository root portably; no machine-specific absolute paths and no duplicated .claude hook implementations.
- [ ] Add Codex Bash and apply_patch payload fixtures to tests/test_claude_hooks.py, covering multiple files and ask-to-block translation.
- [ ] After the user trusts the new hook definitions, a live git push --force --dry-run origin HEAD:refs/heads/__probe__ invocation is blocked by the guard before execution.
- [ ] scripts/check.sh, validate_queue and validate_vault pass; no adapter implementation is part of the registration chore.

## Tests
- Automated: Codex payload fixtures plus scripts/check.sh, validate_queue and validate_vault.
- Live: user reviews/trusts the new definitions; run the harmless dry-run push named above and prove the guard blocks it before execution. Do not add preflight text to the probe because it would change the condition being tested.

## Risks / notes
Parse each patch path safely and do not execute patch content. Guard failures and unsupported approval requests must not become silent allows. The user controls hook trust.

## Implementation record
Planned only. Registered by Codex in chore/codex-config at jg's request; no adapter code or live probe run.

## Audits
Pending implementation and checks.

## Outcome
Backlog; awaiting plan approval and implementation.
