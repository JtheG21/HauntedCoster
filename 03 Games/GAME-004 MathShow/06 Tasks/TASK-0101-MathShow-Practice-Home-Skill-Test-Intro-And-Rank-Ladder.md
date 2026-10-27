---
id: TASK-0101
title: "MathShow Practice Home, Skill Test Intro And Rank Ladder"
type: task
project: GAME-004
status: done
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0099
branch: task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Practice Home, Skill Test Intro And Rank Ladder

## Goal
Screens 11 (Practice home, cooldown, 19a rank unavailable), 12 (Skill Test intro, first time), 16 (rank ladder) and the `badgeSlam` Fx, driven by the profile.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, standard tier. Standard: one Sonnet audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** Skill Test start leads to TASK-0102 (button disabled until it ships).
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 PRACTICE opens Practice home; TAKE TEST shows the retake countdown from `CooldownRules`; TOPIC DRILLS locked; RETRY re-requests the profile; ladder shows current/cleared/locked via `RankRules.ladderMark`.
- [ ] AC2 `Fx.badgeSlam` added (pcall-isolated, no yield, reduced-motion snap); Preview states and TextFit gate cover every new state with 0 failures.
- [ ] AC3 Specs for any new pure logic; check.sh green; screenshots compared.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record
Standard tier. Baseline: MathShow 159 specs. Branch also carries the orchestrator state for TASK-0099/0100 (`approve-merge` by jg, recorded after their PRs were merged).

- **Pure (shared/):** `PracticeRules` (`remaining`, `state`: unavailable / cooldown / ready, `isFirstTest`), `RankRules.ladderLayout`, `MenuConfig.SecondaryEnabled` (`practice` now open, new `skilltest` locked until TASK-0102) with specs. MathShow 159 -> 165.
- **Fx:** `Fx.badgeSlam` (scale 2.4 and a 12 degree tilt settle with the slam ease, 0.5 s; reduced motion snaps; fault warns, never throws).
- **Client:** `View` gets `practice` (11a ready, 11b retake clock, 19a unavailable with RETRY), `skillintro` (12a, 12b first test; START toasts COMING SOON until the Skill Test exists) and `ladder` (16: two columns, staircase offsets, current/cleared/locked marks, rank badges). `Menu/init` carries the profile's `lastTestRank` and `retryAt`, ticks the retake label each second without re-rendering and re-renders at zero so TAKE TEST returns, and wires RETRY to `Menu.retryProfile`. Studio-only hook: `workspace:SetAttribute("MathShowFakeRetakeSeconds", n)` fakes a cooldown.
- **Additions not in the README:** a RANK LADDER button beside BACK on the Practice home (the ladder had no entry; the README only reaches it from the Skill Test result), a Studio-only fake-cooldown hook.
- **Deviations from the README (gate-driven):** ladder rank names are 10 px, not 15, and the YOU tag 10 px: the stretched HUD row art (34 px) has a deep bottom-left cut and a top-right notch, leaving a 12 px clear window left of x 125. 15 px needs a 38 px row (Claude Design, audit A9).

## Studio verification (Rojo via studio-sync, fresh Play)
- TextFit gate with the new states (11a, 11b, 11c, 12a, 12b, 16a-c, 19a) x 3 viewports: **1590 rows, 0 failures**; ladder subjects are the tightest at 6.0.
- Behaviour with the mouse: PRACTICE opens the Practice home; with a faked 45 s cooldown the action reads RETAKE IN 00:25, counts down (00:23) with no re-render and no button, and after zero re-renders as TAKE TEST with a button; TAKE TEST opens 12a (BEST . SILVER); START toasts COMING SOON and stays; BACK returns; RANK LADDER opens the ladder with all 10 rungs.
- `Fx.badgeSlam`: mid-flight scale 0.84, ends at rest (scale 1, rotation 0, opaque); reduced motion snaps; deleting the UIScale warns and does not throw.
- Textured capture of 16a: staircase, GOLD current (green, YOU, check), cleared checks, locked rungs dimmed with locks, rank badges.
- **Not verified:** the 19a RETRY path live (the simulated load failure was not re-run here); 11/12 textured captures; controller/touch; a real cooldown (needs TASK-0102).

## Back to Claude Design
- **Rank ladder rows:** a 38 px row (or a 34 px row with a shallower bottom-left cut) so rank names can be 15 px. Measured: 15 px names reach 3.0 px margin; 11 px reaches 5.5.
- Carried from earlier tasks: toast shard clear band 28 px (text 15 px, 6.0) and banner shard clear band 16 px (text 15 px, 6.5); both would fit README sizes with taller bands.


## Audits
Standard tier, one Sonnet audit: **pass** (AUD-20261027-TASK-0101-01). Minor findings fixed after it: the ticker stops when the menu hides, a loading state for the Practice home, no last-test fallback in the BEST tag; nits fixed too. Studio re-run after the fixes: gate 1590 rows 0 failures; live PRACTICE shows an enabled TAKE TEST and opens 12b.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED; MathShow 165 specs (baseline 159). Studio gate 1590 rows, 0 failures. Sonnet audit pass.
- **Not verified:** the 19a RETRY button live, textured captures of 11/12, controller/touch, a real cooldown (TASK-0102).
- Pending for jg: merge decision. Claude Design list: 38 px ladder rows (names 15 px), taller toast and banner bands.
