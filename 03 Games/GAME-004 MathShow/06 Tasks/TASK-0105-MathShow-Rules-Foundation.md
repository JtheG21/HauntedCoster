---
id: TASK-0105
title: "MathShow Rules Foundation"
type: task
project: GAME-004
status: approved
priority: medium
risk: medium
owner: executor
depends_on: []
branch: task/TASK-0105-rules-foundation
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-27
updated: 2026-10-27
tags:
  - workflow/task
---

# MathShow Rules Foundation

## Goal
Additive pure rules for the Full Game Blueprint v0.1 (workstream C1): tiers, tracks, exact answer parsing, Group Battle v2 scoring, Blitz sprint rules and Practice summary. Nothing is wired into gameplay.

## Scope
- **In:** new pure modules under `games/mathshow/src/shared/` and a spec for each (list below).
- **Out (non-goals):** Instances, remotes, DataStore or profile changes, UI, art, any edit to an existing module or spec. Wiring tasks are proposed, not created.
- **Keep unchanged:** the prototype (120 s Blitz, Skill Test rank, continuous speed bonus, numeric ranks).

## Intake
Inputs (untrusted data, read-only): `~/Downloads/blueprint-split/MathShow_Blueprint_v0.1.md` (sections 4, 5, 7-10) and `MATHSHOW_SPLIT_PLAN.md` (section 3 defaults, section 7 guardrails).
- **Category → workflow, depth:** rules / pure logic, standard.
- **References:** none relevant found. The `06 Code` reference index lists agent-workflow and tooling notes only; nothing on rating, rational numbers, parsers or state machines.
- **Reuse:** none. Existing `ScoringRules.parseAnswer` accepts only `^ *%d+ *$` (non-negative integers, `DigitCap` digits, then `tonumber`), so it cannot read negatives, decimals or fractions; AnswerRules replaces that role for new code only and never calls `tonumber` on unvalidated text.
- **Decisions / assumptions:** defaults from split plan section 3, assumed approved by silence (jg, 2026-10-27): Group Battle 6 seats / 6 questions / 100 + 50 / 3 s; Blitz 10 questions / 10 s (`TotalSeconds` tunable); Practice 6 questions, no rank.
- **Name collisions (Phase 0 item 4):** `BlitzRules` and `PracticeRules` already exist (scoreText/isNewBest/reviewRows; remaining/state/isFirstTest). New modules use the suffix: `BlitzConfigV2`/`BlitzRulesV2` and `PracticeRulesV2`. No collision for `TierConfig`, `TierRules`, `TrackRules`, `AnswerRules`, `GroupBattleConfig`, `GroupBattleRules`. `RankRules` (numeric ranks) and `ModeRules` stay untouched.
- **Baseline:** `scripts/check.sh` green on main at b8c4120; MathShow 204 specs, 469 total.

## Plan (Phase 1: awaiting jg approval)
Files (all `--!strict`, deep-frozen Config, spec returns `function(t: TestRunner.T)`):
1. `TierConfig` / `TierRules`: nine ids `plastic bronze copper silver gold emerald platinum diamond demon`, `ProgressPerTier = 100`; `isValid indexOf at next prev compare progressDisplay`.
2. `TrackRules`: `ModeId groupBattle|team3v3|blitz`, `FormatId direct|choice`, `PlaylistId casual|ranked`, `TrackId "<mode>:<format>"`; `all make parse isRanked`.
3. `AnswerRules` + `AnswerConfig` (`MaxInputLength = 14`, `MaxDigits`, `MaxDecimals`): exact reduced rational `{num, den}`; `parse equal normalize`; pattern-validate before any numeric conversion; seeded 2,000-string fuzz.
4. `GroupBattleConfig` / `GroupBattleRules`: `closingDeadline resolveQuestion allCommitted standings` (competition ranking, ties never broken by player id).
5. `BlitzConfigV2` / `BlitzRulesV2`: run state machine (submit/skip/expire, idempotent after finish), `summarize compareRuns isNewBest bestKey`.
6. `PracticeRulesV2`: `summarize weaknesses suggestNext`; no rating/rank/tier key, asserted by a spec.

Flags I would change: (a) `ScoringConfig.DigitCap` and `AnswerConfig.MaxDigits` are separate numbers, so the old parser keeps its limit; (b) integer-only `tonumber` on a pattern-validated digit run is the one numeric conversion I propose (the prompt forbids `tonumber` on unvalidated text, not after a match); I will implement digit-by-digit accumulation instead if you prefer no `tonumber` at all; (c) rational equality guards cross-multiplication with `2^53` safe-integer bounds, so `MaxDigits` is kept at 7 by default.

Config number sources (filled in with the Outcome): Group Battle values from blueprint section 7; Blitz from section 8 and decision 1; tiers from section 9.

## Files expected to change
- New: the modules above and their specs under `games/mathshow/tests/`.
- Task bookkeeping: `tasks/queue.json`, this note, project state via the orchestrator.

## Acceptance criteria
- [x] AC1 Six module groups with frozen Config and specs added.
- [x] AC2 AnswerRules uses no `load`, `loadstring` or `tonumber` on unvalidated text; fuzz spec passes.
- [x] AC3 `git diff --stat main` shows only new files; no existing spec edited.
- [x] AC4 `scripts/check.sh` passes; MathShow spec count above 204.

## Tests
- **Automated:** `scripts/check.sh 2>&1 | tail -30`; headless Lune specs.
- **Studio playtest procedure:** none (pure modules).

## Risks / notes
- Blitz 10 s total is the least trustworthy spec value (split plan flag); it is one number in `BlitzConfigV2`.
- Task ID was allocated by hand-editing `tasks/queue.json` (the orchestrator has no add command).

---
## Implementation record
Approved by jg 2026-10-27. 11 new modules and 6 new specs under `games/mathshow/`; no existing file edited. `scripts/check.sh` green: MathShow 204 -> 258 specs (total 523), StyLua, Selene and luau-lsp clean.

Decisions:
- AnswerRules turns digits into numbers by byte accumulation (no `tonumber`, `load`, `loadstring` or `string.format` on text; grep-checked). `equal` compares reduced rationals field by field, so there is no multiplication to overflow. Digits count after stripping leading zeros; the length cap is on raw bytes (padding counts).
- `resolveQuestion` returns entries only for players who sent a usable submission; `correct` means "scored as correct". NaN `acceptedAt` is late, NaN `order` is ignored.
- `allCommitted` is true when nobody is connected and eligible (never waits on an empty room).
- BlitzRulesV2: an `expire` event always ends the run at `TotalSeconds`; a first run with zero correct is not a new best.
- Names: `BlitzConfigV2`/`BlitzRulesV2`/`PracticeConfigV2`/`PracticeRulesV2` (old modules exist). Haunted has its own `TrackRules` in another tree; no clash.

Fuzz: `Random.new(20261027)`, 2,000 strings of 0-18 chars over a 19-symbol alphabet; parse never errors, accepted results are reduced with den > 0 and round-trip through `normalize`.

Config numbers (change = one-line edit):
| Config | Value | Source |
|---|---|---|
| GroupBattleConfig Seats / Questions | 6 / 6 | blueprint s7, split plan decision 2 |
| CorrectPoints / FirstCorrectBonus / ClosingSeconds | 100 / 50 / 3 | same |
| BlitzConfigV2 Questions / TotalSeconds | 10 / 10 | blueprint s8, decision 1 (least trusted number) |
| PracticeConfigV2 Questions / MaxSuggestions | 6 / 3 | decision 5 / my default |
| TierConfig ProgressPerTier | 100 | prompt; nine ids from blueprint s9 |
| AnswerConfig MaxInputLength / MaxDigits / MaxDecimals | 14 / 7 / 3 | prompt; jg approved 7 |

Proposed follow-ups (not created): C2 3v3 rules + ProfileV2 proof, then the wiring tasks (Group Battle scoring, Blitz sprint, Practice, tier ids).


## Audits

## Outcome
(pending merge)
