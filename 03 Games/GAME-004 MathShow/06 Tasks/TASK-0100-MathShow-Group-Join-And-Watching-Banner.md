---
id: TASK-0100
title: "MathShow Group Join And Watching Banner"
type: task
project: GAME-004
status: done
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0098
branch: task/TASK-0100-MathShow-Group-Join-And-Watching-Banner
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Group Join And Watching Banner

## Goal
Make JOIN SHOW real on the server: players opt in to the Group Battle match, late joiners watch and join the next one (screen 10).

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Group cap 6 (copy says UP TO 6 PLAYERS), default confirmed. Menu hides without joining only via JOIN SHOW.
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server tracks joined players per match; only joined players can submit, score and appear in standings; a new `JoinShow` remote is validated and rate limited, and the match loop still runs with zero joiners.
- [ ] AC2 A player pressing JOIN SHOW mid-match sees the WATCHING banner (`banner-violet`, HUD question layout without the answer row) until the next Intermission, then plays.
- [ ] AC3 RoundService changes keep every existing spec green; pure join rules live in `shared/` with boundary specs; Studio 1-player run shows full cycle.
- [ ] AC4 Opus audit (networking, remotes).

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record
Deep tier (networking, remotes). Baseline: MathShow 152 specs.

- **Pure (shared/):** `JoinRules` (`participantAt`: only question 1 admits new participants; `isWatching`: joined, not in the match, phase is not Intermission; `validJoin`; `isValidShowState`) with boundary specs. MathShow 152 -> 158. `Net` gains `JoinShow` and `ShowState` and the `ShowStatePayload` type; `MenuConfig.JoinsPer10s = 4`.
- **Server (RoundService):** per-player `joined` and `joinStamps`; `JoinShow` (validated empty payload, 4 per 10 s) sets `joined` and tells that player; `participant` is decided when question 1 opens (`JoinRules.participantAt`), so before this task every player present became a participant, now only joined players do; `ShowState` is sent to one player on join, on join of the match, at match reset and when question 1 opens. The match loop, scoring and standings are unchanged (they already used `participant`).
- **Client:** `Menu` fires `JoinShow` before hiding on JOIN SHOW; `Hud` listens to `ShowState`, computes `watching`, hides the answer row, shows the score as a dash and tells the banner via `Hud.setWatchingListener`; `Menu/Watching` draws the banner (`View.build` with `overlay = true`, DisplayOrder 5, between the HUD and the menu) using the same `watching` screen the Preview and the TextFit gate render.
- **Deviation:** banner text is 15 px, not 17: only y 14..30 of the 44 px banner shard clears 6 px of its cuts. Gate margin 6.5.
- **Persistence of intent:** `joined` stays true across matches until the player leaves; there is no "leave show" yet.

## Studio verification (Rojo via studio-sync, fresh Play, 1 player)
- Not joined: the first match ran with 0 participants (`leaderstats published n=0`) and a `SubmitAnswer` was rejected (`notOpen`); the HUD stayed hidden.
- Joined mid-match (question 2): banner on with `WATCHING . YOU JOIN NEXT MATCH`, answer row hidden, a submit from the watcher rejected. At the next Intermission the banner went off; at question 1 of the next match `ShowState` gave `participant = true`, the submit was accepted and scored (199 points) and the banner stayed off.
- `JoinShow` burst of 12: 4 `ShowState` replies (rate limit); `{x=1}`, `"join"`, `5`, `{1}`: 0 replies.
- Real menu path (PLAY -> Group Battle -> JOIN SHOW with mouse): the menu hides, the HUD shows, `ShowState joined = true` arrives.
- TextFit gate with the new banner state: 1167 rows, 0 failures.
- **Not verified:** two real clients (a second player joining while the first plays); the score dash was set in code but its text was not read in Studio; controller/touch.


## Audits
Deep tier, one Opus audit: **pass** (AUD-20261027-TASK-0100-01). Fixed after it: a warn when the JoinShow remote is missing, the stale client comment, a spec for unknown phases. Kept: `sendState` after `sendShow` (commented). MathShow specs 159. The 2-client run moves to TASK-0104.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED; MathShow 159 specs (baseline 152). Studio 1-player run and the TextFit gate (1167 rows, 0 failures) pass. Opus audit pass.
- **Not verified:** two real clients; the score dash text in Studio; controller/touch.
- Pending for jg: merge decision.
