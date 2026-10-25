---
id: TASK-0094
title: "MathShow Scores"
type: task
project: GAME-004
status: proposed
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0092
branch: task/TASK-0094-MathShow-Scores
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow Scores

## Goal
leaderstats integration and a Results screen showing the podium at match end, sourced from the `scores` field RoundService already sends on `RoundState`.

## Scope
- **In:** server-side leaderstats (`Score` IntValue per player, in-memory for this slice, no DataStore), client Results screen rendering final standings during the Results phase.
- **Out (non-goals):** persistence across sessions (explicitly "Later, not in the slice" per DESIGN.md), monetization.
- **Keep unchanged:** `server/Services/RoundService.luau`'s scoring logic (consume `scores`, don't recompute it client-side).

## Intake
- **Category → workflow, depth:** UI and graphics / Systems → [[UI Workflow]], light.
- **References:** none specific; standard Roblox leaderstats pattern.
- **Reuse:** leaderstats is a well-known Roblox pattern; no new abstraction needed beyond a `Score` IntValue per player.
- **Decisions / assumptions / open questions:** Assumption — no DataStore in this slice; scores reset each server session, consistent with DESIGN.md's "Later" list.

## Files expected to change
- `games/mathshow/src/server/Services/RoundService.luau` (leaderstats wiring, if not already present) or a small new leaderstats module
- `games/mathshow/src/client/Hud/` (Results screen, extends TASK-0093's HUD)

## Acceptance criteria
- [ ] AC1 Each player has a visible `Score` leaderstat that updates after each Reveal.
- [ ] AC2 The Results screen shows a ranked podium matching the server's `scores` at match end.
- [ ] AC3 No DataStore or persistence call is introduced in this task.

## Tests
- **Automated:** `scripts/check.sh`
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; play a full match as one player (or more, if available); confirm leaderstats update and the Results screen matches.

## Risks / notes
None.

---
## Implementation record

## Audits

## Outcome
