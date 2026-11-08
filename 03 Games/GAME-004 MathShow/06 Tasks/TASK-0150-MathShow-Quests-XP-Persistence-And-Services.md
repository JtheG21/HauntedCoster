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
  only), Skill (one shared finalisation guard; rev 1), Glyph (pickup + rarity). ModePad files untouched (T3).
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

### Revision 1 (AUD-20261107-TASK-0150-01, Codex FAIL, 5 findings)
Range 81f2f8b..HEAD. Owned files only: `ProfileRules.luau`, `ProfileService.luau`, `QuestService.luau`, `BlitzService.luau`,
`SkillTestService.luau`, `ProfileRules.spec.luau`, this note, the task file, evidence.
- F1: Skill finalises a completed run when its last answer closes it, through one guard (`ProfileRules.finalizeRun`, session
  `terminal`), so the completion is queued while profile and quest state exist, whatever order PlayerRemoving listeners run in.
  The missing-problem path finalises as "error" and earns no completion.
- F2: Blitz records each accepted answer's day privately (`answerDays`); at the result boundary QuestService flushes correct
  answers grouped by that day (`ProfileRules.factsByDay`) and the finish uses the day the run ended. Unfinished leave discards.
- F3: `queuedEpoch` removed. Readiness is `ProfileRules.needsRollover(confirmed epoch, ledger, day)`: rollovers in the
  unresolved op or queued ahead only. On every terminal "settled" event, days of queued commands left without a rollover
  (`strandedDays`) get a fresh one. The queue keeps day order around rollovers (a rollover goes before queued commands of its day
  or later; a dated command goes before a queued rollover to a later day). Abandoned/expired commands are never replayed.
- F4: initialised v4 daily state without a valid integer xp is "disabled" (warned, nothing mutated, xp not written); new and
  migrated profiles (uninitialised) still start at 0.
- F5: the pending claim keeps its full identity; `ProfileRules.claimOutcome` confirms only the claim's own applied result or a
  matching already-claimed slot on the adopted board, else "stale". `ProfileService` settled-event `eventIds` are now
  index-aligned with `results`.
- No remote payload changed (QuestState still sends `pendingClaim` as the slot number).
- Regression specs (`ProfileRules.spec.luau`), run against 81f2f8b source (extracted with `git archive`) and at 84c9891:
  | Spec | 81f2f8b | 84c9891 |
  |---|---|---|
  | AUD-01 F1: one finalisation guard: one completion across finish and final-reveal leave; error earns none | FAIL (`finalizeRun` absent) | PASS |
  | AUD-01 F2: a Blitz run across midnight keeps each answer's day, in both board-advancement orders | FAIL (`factsByDay` absent) | PASS |
  | AUD-01 F3: an unconfirmed rollover never counts; the next fact or the settlement reopens the day | FAIL (`needsRollover` absent) | PASS |
  | AUD-01 F4: missing xp in initialised v4 daily state fails closed; xp is never read or written as 0 | FAIL (`expected disabled, got ok`) | PASS |
  | AUD-01 F5: a claim is confirmed only for its own identity; stale identities report stale | FAIL (`claimOutcome` absent) | PASS |
  F4 fails on behaviour. F1/F2/F3/F5 fail because the pure decisions lived untestably inside the services at 81f2f8b; their old
  behaviour is the audit's source probes, and the Studio runs below drive the fixed paths. Full suite: 463 passed at 84c9891.
- Studio (private test place, measured 84c9891): interrupted rollover + rejoin settled once (xp 280 -> 630, no regeneration);
  Blitz across a clock-offset midnight kept 8 post-midnight answers on the new board and the finish on the end day; claim /
  repeat claim confirmed (+100 once), yesterday's identity and a wrong generation "stale"; Skill leave during the finished final
  reveal +20 once (limitation: this run's listener order also let the cooldown save, so it cannot show the order-dependent loss);
  bonus not re-paid by rollover. Profile restored to day 20765, xp 630 (recorded). Evidence:
  `docs/workflow/evidence/TASK-0150/rev1/studio-pass.txt`.
- Not changed (report "additional observations", no correction required): denied-request pushes, `QuestService: any`, loaded
  result semantics. Seen, out of scope: Skill's cooldown save on a final-reveal leave still depends on listener order
  (pre-existing, not part of F1's correction).

## Audits
- [[AUD-20261107-QUESTS-XP-DESIGN-01]]: design review, DESIGN CHANGES REQUIRED.
- [[AUD-20261107-QUESTS-XP-DESIGN-02]]: design re-review, DESIGN CHANGES REQUIRED; replacement bullets applied (QX-D4).
- [[AUD-20261107-TASK-0150-01]]: Codex code review of 81f2f8b, FAIL (F1-F5); revision 1 above.

## Outcome
