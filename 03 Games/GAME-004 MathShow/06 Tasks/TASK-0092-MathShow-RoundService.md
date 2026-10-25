---
id: TASK-0092
title: "MathShow RoundService"
type: task
project: GAME-004
status: proposed
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0089
  - TASK-0090
  - TASK-0091
branch: task/TASK-0092-MathShow-RoundService
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow RoundService

## Goal
Server-authoritative match loop: `server/Services/RoundService` owns the remotes (`RoundState`, `SubmitAnswer`, `AnswerResult`), drives the phase machine from RoundRules, generates problems from ProblemRules, and validates/scores submissions via ScoringRules.

## Scope
- **In:** `server/Services/RoundService.luau` with idempotent `start()`; remote creation in `ReplicatedStorage.Remotes`; submission validation (type → range → ownership → rate limit per `AGENTS.md`); one accepted submission per player per question.
- **Out (non-goals):** client HUD, leaderstats/Results UI.
- **Keep unchanged:** `shared/Problem*`, `shared/Scoring*`, `shared/Round*` (consume, don't modify, unless this task finds a genuine bug in them).

## Intake
- **Category → workflow, depth:** Systems → [[Systems Workflow]], deep (shared/server-authoritative state, networking).
- **References:** `games/hike-or-die/src/server/RoundService.luau` for a recent server-authoritative round-loop precedent; adapt the pattern, not the game-specific logic.
- **Reuse:** adapt RoundService's general shape (serialize phase transitions, server-timestamped submissions); MathShow's remotes and payloads are its own, per `games/mathshow/DESIGN.md` "Remotes."
- **Decisions / assumptions / open questions:** Fact (DESIGN.md) — server never sends the answer before Reveal; records submit time on receipt (`os.clock()`), never trusts client time; `endsAt` is `workspace:GetServerTimeNow()`-based.

## Files expected to change
- `games/mathshow/src/server/Services/RoundService.luau`
- `games/mathshow/src/server/Remotes.luau` (or equivalent)
- `games/mathshow/src/shared/Net.luau` (remote names/types)

## Acceptance criteria
- [ ] AC1 The server creates all three remotes; the client never receives the answer before Reveal.
- [ ] AC2 Submissions are validated type → range → ownership → rate limit; only the first valid submission per player per question is accepted.
- [ ] AC3 A 1-player Studio playtest log shows a full cycle: Intermission → Question → Reveal → ... → Results → Intermission.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; join as one player; run a full match and capture the console log showing each phase transition and at least one scored answer.

## Risks / notes
Server-authoritative and networked — deep tier per `04 Agents/Task Intake.md`; needs an Opus first audit (`AGENTS.md` "Session and delegation budget").

---
## Implementation record

## Audits

## Outcome
