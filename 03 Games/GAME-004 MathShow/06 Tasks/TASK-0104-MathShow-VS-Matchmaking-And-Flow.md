---
id: TASK-0104
title: "MathShow VS Matchmaking And Flow"
type: task
project: GAME-004
status: done
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0099
  - TASK-0100
branch: task/TASK-0104-MathShow-VS-Matchmaking-And-Flow
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow VS Matchmaking And Flow

## Goal
1v1 VS (screens 03b, 04, 05, 08, 09, 19b): in-server queue, separate 2-player match, head-to-head HUD, results, rematch, sudden death.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Defaults for jg to veto: search timeout 60 s, rematch window 15 s, sudden-death 15 s. This is the largest task; split if the RoundService refactor needs its own task.
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server queue with timeout (60 s default), cancel and keep-waiting remotes, per-match state so VS does not touch the Group Battle loop (RoundService refactor behind the existing specs); forfeit on leave.
- [ ] AC2 Pure `MatchRules` (vsResult, headToHeadPct, searchPhase) with specs; screens render and pass the TextFit gate with 4- and 5-digit scores.
- [ ] AC3 A real 2-client Studio test (max 2 clients) of search, found, play, result and rematch is recorded; ModeEnabled.vs flips on only after it passes; Opus audit.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record
Deep tier (networking, remotes). Baseline: MathShow 195 specs. Branch also records `approve-merge` for TASK-0103.

- **Pure (shared/):** `MatchRules` (`vsResult`, `headToHeadPct`, `searchPhase`), `VsRules` (strict `validQueueJoin` / `validEmpty` / `parseAnswerPayload`, `suddenWinner`, `afterTimeout`), `MenuConfig` VS settings. MathShow 195 -> 204 specs. The spec caught a real bug: an infinite `questionIndex` passed validation (inf == floor(inf)); fixed in `VsRules` and `SkillRules`.
- **Server (`VsService`, separate from `RoundService`, so Group Battle is untouched):** `QueueJoin`, `QueueCancel`, `QueueKeepWaiting`, `VsAnswer`, `RematchRequest` in; `QueueState`, `VsState`, `VsResult` out (the correctness feedback reuses `AnswerResult`). An in-server queue pairs the two oldest searchers; each match runs on its own thread: STARTS IN countdown, six questions (same tiers and time limits as Group Battle), answers scored with `ScoringRules`, totals sent only at Reveal, the opponent's answer never sent, sudden death on a tie (first correct answer wins, up to 5 questions), forfeit if the rival leaves, a rematch window (15 s, both must ask). Searching times out after 60 s (`KEEP WAITING` resets it); a second timeout ends in `failed` (19b). `ModeEnabled.vs` is now true and the server checks it.
- **Studio-only helpers:** `workspace:SetAttribute("MathShowVsBot", true)` pairs a lone searcher with a practice bot after 2 s; `VsService._test` and `StudioTestHook` (copied from GAME-001) run `tests/multiclient/VsTwoClients`.
- **Client:** `View` screens in one `vs` screen by stage: 04a/04b search and timeout, 05 found (YOU and RIVAL, VS, STARTS IN), 08 question and reveal (head-to-head shard replaces the score; widened to 344 px per audit A3), 09a-d result (WIN / LOSS / DEAD EVEN with the sudden-death count / WIN BY FORFEIT, REMATCH or FIND NEW RIVAL, MENU, WAITING FOR RIVAL), 19b no match. `Menu/init` drives it from the queue and match events; Back is CANCEL while searching and disabled while a match starts or runs.
- **Deviations (gate-driven):** the head-to-head points are 16 px (README 20), the sudden-death count is 80 px (README 100): the score shard and the count shard only clear 6 px up to those sizes.

## Studio verification (Rojo via studio-sync)
- **Two real clients** (`ExecuteMultiplayerTestAsync(2, VsTwoClients)`): `ok = true`, every check passed: both players ready; a searcher who cancels is never paired; two searchers are paired into the same match with two seats; all six questions came up; a second valid answer from the same player and an answer for the wrong question index did not count (both wrong answers left the match 0-0); the tie went to sudden death; the sudden-death question ended the match; a rematch started a new match with scores reset; a player who left mid-match ended it by forfeit.
- **One client against the practice bot, through the real UI:** invalid `QueueJoin` payloads (`mode = "blitz"`, an extra key, a string) did nothing; PLAY -> VS -> FIND OPPONENT showed SEARCHING with the clock, FOUND with both names and STARTS IN 3-2-1, then Q1 with the head-to-head shard; typing then LOCK IN showed CORRECT . +109; the totals changed only at each Reveal; `VsState` Question payloads had no answer key (only the Reveal had `answer`); the match ended on YOU WIN (WIN, YOU 1,076, RIVAL 479) with REMATCH and MENU; REMATCH started a fresh match.
- **No opponent:** after 60 s STILL LOOKING / WAITED 1:00 with KEEP WAITING and CANCEL; KEEP WAITING restarted the clock; the second timeout showed COULDN'T FIND A MATCH (RETRY, CHOOSE SHOW, BACK); RETRY searched again and CANCEL returned to the VS panel.
- **TextFit gate** with 04a/b, 05a/b (a 20 x "W" name, "SirCountsALot_Official", DEMON III), 08a-d (4-digit and 5-digit scores "1,200" and "10,000", "123456 + 98765", sudden death), 09a-e, 19b: 2859 rows, 0 failures.
- **Not verified:** the Group Battle two-client join check carried over from TASK-0100 (this scenario covers VS only; `RoundService` has no test surface); a draw's sudden-death screen live (covered by the two-client server run and the gate, not seen on a client); the result screen's motion; controller/touch; real DataStore (VS does not write the profile).


## Audits
Deep tier, one Opus audit: **pass** (AUD-20261027-TASK-0104-01); no secrecy leak or exploit found. Fixed after it: a declined rematch window returns the result screen, a match error tells both players, `RematchRequest` is rate limited, `newSeat` helper, a comment on the draw result. Left: a sudden-death win shows equal totals (cosmetic). The two-client scenario was re-run after the fixes.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED; MathShow 204 specs (baseline 195). Studio: 2-client scenario, single-client UI runs, gate 2859 rows 0 failures. Opus audit pass.
- **Not verified:** the Group Battle 2-client join check (TASK-0100), a draw's sudden-death screen live, motion, controller/touch.
- Pending for jg: merge decision. Claude Design list: 38 px review/ladder rows, taller toast and banner bands, a deeper score shard and count shard.
