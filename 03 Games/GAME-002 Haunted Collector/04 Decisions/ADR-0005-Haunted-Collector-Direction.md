---
id: ADR-0005
title: Haunted Collector Direction
type: adr
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-11
related:
  - "[[INBOX-20261011-Haunted-Collector-Brief]]"
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0002-Game-Direction]]"
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/decision
---
# ADR-0005: Start GAME-002 Haunted Collector as a second game in this repo

## Context
On 2026-10-11 the user supplied a full MVP brief, [[INBOX-20261011-Haunted-Collector-Brief]]. The game combines a graveyard monster hunt, a risky return trip, mansion tycoon progression and a player-built, rideable ghost train. The user chose to start it as a **new game, GAME-002**, alongside GAME-001 Rival Realms ([[ADR-0002-Game-Direction]] stays approved and unchanged).

The repo currently has **one** Rojo project (`default.project.json`), and it syncs `src/` and `tests/luau` into the Rival Realms place. `scripts/check.sh` and `scripts/typecheck.sh` only cover that tree.

## Options considered
1. **Same repo, separate Rojo project and place (recommended).** Add `haunted.project.json` with code under `games/haunted/{src,tests}`, synced to a **new, separate Studio place**. The vault, orchestrator, checks and skills stay shared, and the checks are extended to cover both projects.
2. **Separate repo and vault.** Cleanest isolation, but it duplicates the workflow, scripts and conventions, and AGENTS.md rule 13 forbids creating another vault without approval.
3. **Same `src/` tree and same place.** Rejected: it mixes two games' services, remotes and Workspace, and it risks breaking GAME-001.

## Decision
**Approved by the user (jg) in chat on 2026-10-11**, including option 1 and the expedition-failure rule. The user also set priority: **GAME-002 is the primary focus. GAME-001 is source material** (its code, patterns and notes can be reused), and its open tasks wait.

- Start GAME-002 under option 1.
- Scope: the MVP in [[GAME-002 Haunted Collector/01 Game Design]]. The Haunted Forest and Mine expansion is out of scope.
- Delivery: the eight proposed tasks TASK-0011 to TASK-0018 ([[GAME-002 Haunted Collector/03 Roadmap]]). Each one goes through the normal plan → execute → audit → merge gates. The brief's "one pass, no approvals" instruction is overridden by [[AGENTS]].
- Expedition failure (the brief's original "Round 19" wording was lost): when the return timer expires or the carrier dies, the **carried capture escapes** back to a graveyard spawn and has to be caught again. The player keeps the journal discovery and loses no coins, and **owned monsters are never touched**.

## Consequences
- TASK-0011 has to add the second Rojo project, extend `check.sh` and `typecheck.sh`, and document how to create the new place. The user creates and saves that place in Studio. **Nothing gets published.**
- GAME-002 is the studio's first game with **DataStore persistence**, so TASK-0011 carries the most technical risk.
- Linking: GAME-002's fixed-name notes (`00 Overview` and so on) make the existing unqualified links in GAME-001 notes ambiguous. The validator warns but doesn't fail. New links use the path form `[[GAME-00N Name/00 Overview]]`. Migrating the old links is a separate cleanup (see the open questions).
- GAME-001 work (TASK-0008 in review, TASK-0010 proposed) is paused behind GAME-002 (user, 2026-10-11).

## Open questions for the user
1. ~~Approve option 1~~: approved 2026-10-11.
2. ~~Expedition-failure rule~~: approved 2026-10-11.
3. ~~Priority~~: GAME-002 first, GAME-001 is source material (2026-10-11).
4. Still open: may a chore task rewrite the old unqualified fixed-name links in GAME-001 notes (including `06 QA` audits) to path form?
