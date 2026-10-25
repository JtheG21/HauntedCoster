---
id: TASK-0092
title: "MathShow RoundService"
type: task
project: GAME-004
status: done
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
Claude (Opus), 2026-10-25, worktree `~/Desktop/Rg1-worktrees/task-0092`. jg approved the plan in chat on 2026-10-25,
including SubmissionRules and its spec.

**Files** (all `games/mathshow/`)
- `src/shared/Net.luau`: frozen remote names, `RoundStatePayload`, `ScoreEntry` (array), `AnswerResultPayload`.
- `src/shared/SubmissionConfig.luau`: `MinSubmitIntervalSeconds = 0.3`, `LateGraceSeconds = 0.25`,
  `RejectReplyIntervalSeconds = 0.3`.
- `src/shared/SubmissionRules.luau`: pure `evaluate(raw, ctx) -> (Verdict, number?)`, type → range → ownership →
  rate limit → duplicate; `advancesRateLimit` (ok, duplicate), `sendsReply` (not badType/rateLimited) and
  `rejectThrottled` (rejections inside RejectReplyIntervalSeconds get no reply or log).
- `tests/SubmissionRules.spec.luau`: 13 tests (each verdict, precedence pairs, length/digit/interval/deadline/index
  boundaries, only-ok-returns-a-number).
- `src/server/Remotes.luau`: create-or-reuse `ReplicatedStorage.Remotes` and the three RemoteEvents; errors on a
  wrong-class name clash.
- `src/server/Services/RoundService.luau`: match loop, SubmitAnswer handler, idempotent `start()`.
- `src/server/init.server.luau`: starts RoundService.

**Deviations from "Files expected to change"**
- Added SubmissionConfig, SubmissionRules and its spec (jg-approved), so validation is pure and tested headlessly.
- `init.server.luau` changed to start the service.
- `LateGraceSeconds = 0.25` (Question stays open 0.25 s past the shown deadline; Reveal starts that much later, jg
  chose this in revision 1), abort to Intermission when all players leave, and a 1 s loop-error backoff.
- Participants: every present player joins the match when a question opens, so a mid-question joiner plays from the
  next question.
- No change to `shared/Problem*|Scoring*|Round*`.

**Remote payload ownership**
- `RoundState`: sender RoundService, receiver client Hud (TASK-0093).
- `SubmitAnswer`: sender client Hud (TASK-0093), handler RoundService.
- `AnswerResult`: sender RoundService, receiver client Hud (TASK-0093).

**Checks**
- `scripts/check.sh`: every step PASS (StyLua, Selene, typecheck, Lune `MathShow: 39 passed, 0 failed` /
  `304 passed, 0 failed`, Rojo builds, JSON, orchestrator, vault, refs, skills, Python tests).
- `TYPECHECK_REQUIRED=1 scripts/typecheck.sh`: `no type errors`.
- Studio playtest: [[TEST-20261025-01]] pass.

**Revision 1** (jg, 2026-10-25, from [[AUD-20261025-TASK-0092-01]] findings 1–2; commit `d5d042d`)
- Rejected submissions are replied to and logged at most once per `RejectReplyIntervalSeconds` per player.
- RoundService waits `deadline + LateGraceSeconds` before Reveal; `endsAt` still shows the deadline.
- Nits 3–4 left as is (no behaviour change). Re-run in [[TEST-20261025-01]] "Revision 1 re-run": pass.

**Acceptance criteria**
- AC1 met (verified): `Remotes.luau` creates all three; `grep -n answer RoundService.luau` puts `answer` in a payload
  only at the Reveal branch (line 71); playtest client log shows `answer=nil` in every Question payload.
- AC2 met (verified): SubmissionRules spec for order and boundaries; playtest shows badRange, badType (no reply),
  ok `points=195`, rateLimited (no reply), duplicate, and wrong-first locking the question.
- AC3 met (verified): [[TEST-20261025-01]] logs Intermission → Q1..Q6 Question/Reveal → Results → Intermission for two
  full matches.

**Known gaps**
- Not exercised in Studio: 2 players, everyone leaving mid-match, loop-error backoff (2-player test task).
- `scripts/studio-preflight.sh` and `scripts/stamp.sh` are GAME-002 only (false FAIL on a MathShow server, no
  MathShow build stamp). Sync was verified by checking the new instances in Studio instead.

## Audits
- [[AUD-20261025-TASK-0092-01]] (Opus, attempt 1): pass with 2 minor findings (unthrottled replies/logs for badRange
  and notOpen; `LateGraceSeconds` only covers loop jitter) and 2 nits. jg asked for revision 1.
- [[AUD-20261025-TASK-0092-02]] (Opus delta, attempt 2): pass; both findings resolved; 2 nits, no change needed.

## Outcome
- RoundService runs the full MathShow match loop server-side: remotes in `ReplicatedStorage.Remotes`, answer only in
  Reveal, submissions validated by pure SubmissionRules (13 spec tests), first valid answer locks the question.
- `scripts/check.sh` exits 0 (MathShow specs 26 -> 39 passed, 0 failed); strict typecheck clean.
- Studio: [[TEST-20261025-01]] (two full cycles, every verdict, revision re-run with grace and throttle) pass.
- Audits: [[AUD-20261025-TASK-0092-01]] pass with 2 minor; revision 1 (jg) fixed both;
  [[AUD-20261025-TASK-0092-02]] delta pass. 1 of 2 revisions used.
- Not run: 2 players, everyone leaving mid-match, loop-error backoff (2-player test task).
- For TASK-0093 (Hud): listen to `RoundState` (`Net.RoundStatePayload`), send `SubmitAnswer(raw: string)`, show
  `AnswerResult`. `endsAt` is server time; the server accepts answers for `LateGraceSeconds` (0.25 s) after it, so the
  Hud may keep input open briefly at 0. Rejections can come back throttled (no reply), so do not wait on a reply.
- Tooling follow-up: `scripts/studio-preflight.sh` and `scripts/stamp.sh` only support GAME-002.
