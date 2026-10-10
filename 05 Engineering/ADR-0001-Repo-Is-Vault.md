---
id: ADR-0001
title: Repo Is Vault
type: adr
status: approved
approved_by: jg
approved_on: 2026-10-10
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/decision
related:
  - "[[Obsidian Conventions]]"
---
# ADR-0001: The Rg1 repository is the Obsidian vault

## Context
Obsidian was already opened on `~/Desktop/Rg1`, the Rojo repo. We needed one place where both Claude Code and the human read and write project knowledge.

## Options considered
1. Same vault, in the repo: notes versioned with Git, one location.
2. A separate notes vault: cleaner separation, but two places to keep in sync.

## Decision
Option 1. Approved by the user in chat on 2026-10-10 (setup question "Vault: same vault, in repo"). Rojo only syncs `src/` and `tests/luau`, so notes never reach the game. Studio-level notes use the numbered folders from [[Obsidian Conventions]]. The game lives in `03 Games/GAME-001 Rg1/`.

## Consequences
- Plugin folders (`Agents/`, `Chats/`, `.obsidian/`) sit next to the code. They're git-ignored where they're per-machine.
- A future second game would get its own `03 Games/GAME-002 …` folder. Its code would need its own repo, or a `src/` per game (to decide then).
