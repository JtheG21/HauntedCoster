---
id: TASK-0123
title: "MathShow Multiplayer Playtest"
type: task
project: GAME-004
status: backlog
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0122
branch: task/TASK-0123-multiplayer-playtest
related:
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Multiplayer Playtest

## Goal
Prove with two real clients what the single-client Studio rounds could not: per-player delivery of GlyphState and ModePadOpen, and the mid-match pad block.

## Scope
- **In:** a two-client run on a private test place, with both client consoles captured and per-player outcomes recorded.
- **Out (non-goals):** gameplay or code changes beyond test scaffolding, DataStore, merging.
- **Approval:** publishing the private test place needs jg's explicit approval. Do not publish without it.

## Intake
- **Category, depth:** systems test, standard.
- **Why this exists:** jg's option A decision on [[TASK-0122-MathShow-Hub-Mode-Pads]] deferred its two-client check (S4d) as an accepted risk. The Studio multi-client test did not join a second client twice, likely memory pressure on an 8 GB Mac.
- **Assumption:** a private test place can host two clients where one Studio session cannot. Unconfirmed.

## Files expected to change
Evidence only: `docs/workflow/evidence/TASK-0123/`, this note, `tasks/items/TASK-0123.json`.

## Acceptance criteria
- [ ] AC1 Per-player GlyphState: each client's available glyphs and counter are independent.
- [ ] AC2 Per-player ModePadOpen: the player on a pad gets it, the other gets nothing; both consoles captured.
- [ ] AC3 Mid-match block with two clients: the player in the match gets nothing on a pad, the other player does.
- [ ] AC4 Evidence log with measured SHA and applies_to; no errors in either console.

## Tests
Two real clients on a private test place.

## Risks / notes
Needs jg's approval to publish a test place.

---
## Implementation record

## Audits

## Outcome
