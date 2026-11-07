---
id: TASK-0150
title: "MathShow Quests XP Persistence And Services"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: high
owner: executor
depends_on: ["TASK-0149"]
branch: task/TASK-0150-quests-xp-persistence
related:
  - "[[SYS-Quests-And-XP]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - workflow/task
---

# MathShow Quests XP Persistence And Services

## Goal
ProfileRules v4, XpService, QuestService, event hooks and remotes (DataStore schema change). Design: [[SYS-Quests-And-XP]].

## Scope
- **In:** as in the brief's Tasks table.
- **Out (non-goals):** anything under "Out of scope" in the brief.

## Intake
- **Decisions:** Backlog; waiting for the Codex design review of SYS-Quests-And-XP and jg's plan rows. No plan approval yet. Registered by row QX-D1 (jg, 2026-11-07).

## Acceptance criteria
- [ ] AC1 See `tasks/items/TASK-0150.json`.

## Implementation record
- Branch `task/TASK-0150-quests-xp-persistence`. Schema v4 in `ProfileRules` (xp, dailyEpoch, playXpDay, quests); ordered commands
  (play / progress / claim / rollover) frozen into the TASK-0141 save op and applied in `planSave` against the stored value.
  `QuestService` is new; no `XpService` (not needed). Hooks: Round (answer, Results completion + top 3), Blitz (result boundary
  only), Skill (shared `rewarded` guard), Glyph (pickup + rarity). ModePad files untouched (T3).
- **Remote sender / handler / receiver** (no client receiver in T2; T3 adds it):
  | Remote | Sender | Server handler | Receiver |
  |---|---|---|---|
  | QuestRequest (no args) | client (T3) | `QuestService.onRequest` | none |
  | QuestClaim {day, slot, boardRevision, generation} | client (T3) | `QuestService.onClaim` via `ProfileRules.parseClaimPayload` | none |
  | QuestState (`Net.QuestStatePayload`) | `QuestService.push` | none | client (T3) |
- Choices not in the brief (please review): command discriminator is `type` (progress already has `kind`); board seed uses
  `abs(userId)` (Studio players can be negative); a rare pickup counts for glyph and rare quests; consecutive same-quest
  increments are folded into one queued command; `XP_MAX` 100,000,000, queue cap 64, 256 remembered event ids; memory mode
  applies commands to the in-memory profile only; `MathShowClockOffsetS` Studio clock offset (inert outside Studio); a second
  claim of a claimed slot reports "confirmed" with 0 awarded; `QuestService._test` Studio-only seam.
- Accepted losses, disclosed: facts before the profile loads wait in a 64-entry buffer, beyond it dropped with a warning;
  commands of a closed day are dropped (warn once per op); an abandoned or expired op's commands are never regenerated.
- Evidence: `docs/workflow/evidence/TASK-0150/studio-pass.txt`.

## Audits
- [[AUD-20261107-QUESTS-XP-DESIGN-01]]: design review, DESIGN CHANGES REQUIRED.
- [[AUD-20261107-QUESTS-XP-DESIGN-02]]: design re-review, DESIGN CHANGES REQUIRED; replacement bullets applied (QX-D4).

## Outcome
