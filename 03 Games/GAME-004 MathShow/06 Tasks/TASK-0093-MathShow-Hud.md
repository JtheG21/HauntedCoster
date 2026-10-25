---
id: TASK-0093
title: "MathShow Hud"
type: task
project: GAME-004
status: done
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0092
branch: task/TASK-0093-MathShow-Hud
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-25
tags:
  - workflow/task
---

# MathShow Hud

## Goal
Client HUD: question text, countdown timer, number input box, and correct/incorrect feedback, driven entirely by `RoundState` and `AnswerResult` events. Built in code, no assets.

## Scope
- **In:** `client/Hud` module(s), timer display synced to the server-provided `endsAt`, a text/number input that calls `SubmitAnswer`.
- **Out (non-goals):** leaderstats, Results/podium screen (TASK-0094).
- **Keep unchanged:** `server/` and every existing `shared/` file. Widened at planning (jg handed the plan over): new `shared/HudConfig`, `shared/HudRules` and `tests/HudRules.spec` hold the testable pure logic (digit filter, countdown maths, feedback mapping), since Lune only runs `shared/` and `tests/`.

## Intake
- **Category → workflow, depth:** UI and graphics → [[UI Workflow]], standard.
- **References:** check `10 References/01 UI/` for any relevant timer/quiz HUD notes; GAME-002's `Theme.luau` for this repo's UI conventions if applicable.
- **Reuse:** none existing for a timed-input HUD; build fresh per DESIGN.md.
- **Decisions / assumptions / open questions:** Assumption — HUD trusts only server-sent `phase`/`endsAt`/`problemText` for its countdown, never a local clock guess, consistent with RoundService being server-authoritative.

## Files expected to change
- `games/mathshow/src/client/Hud/` (new: init, Theme, View, Fx), `client/init.client.luau` (wiring)
- `games/mathshow/src/shared/HudConfig.luau`, `HudRules.luau` and `games/mathshow/tests/HudRules.spec.luau` (new)

## Acceptance criteria
- [x] AC1 Timer counts down to the server's `endsAt`, not a client-local timer.
- [x] AC2 Submitting an answer sends exactly one `SubmitAnswer` call per question; the input is disabled after submission.
- [x] AC3 Feedback (correct/incorrect, points) renders on `AnswerResult` and clears for the next question.

## Tests
- **Automated:** `scripts/check.sh` (no new pure logic expected; confirm it still passes).
- **Studio playtest procedure:**
  1. `rojo serve mathshow.project.json`; join as one player; verify the HUD shows the problem, counts down, accepts one answer, and shows feedback each round.

## Risks / notes
None beyond needing TASK-0092's remotes finished first.

---
## Implementation record
- **References:** `10 References/01 UI/UI References.md` has no timer or quiz HUD entry; followed [[UI Workflow]], the Good UI Principles note (small HUD, show don't tell) and GAME-002's Theme/Hud pattern (adapted, not copied). Colours and layout come from the untracked `HudSpec.json` (visual reference only, not loaded at runtime).
- **API checks (creator-docs):** present and not deprecated: `ScreenGui.ScreenInsets` (`Enum.ScreenInsets.DeviceSafeInsets`), `TextBox.TextEditable`, `TextBox.ClearTextOnFocus`, `TextBox.FocusLost`, `Workspace:GetServerTimeNow`, `UITextSizeConstraint`, `RunService.Heartbeat`, `TweenService:Create`.
- **Design:** one Heartbeat connection only while a countdown shows, computed from `GetServerTimeNow()` against the server `endsAt`; submit locks synchronously before `FireServer`; a rejected reply does not re-arm input; Hud never waits on `AnswerResult`; Fx calls are pcall-isolated.
- **Added beyond HudSpec:** a Submit button for touch and gamepad.
- **Static checks:** `scripts/check.sh` ALL CHECKS PASSED (MathShow specs 57 passed, incl. 18 new HudRules); `TYPECHECK_REQUIRED=1 scripts/typecheck.sh` no type errors.
- **Studio playtest:** [[TEST-20261025-02]], one full match, AC1-AC3 pass. First RoundState reached the Hud 0.03-0.05 s after start (no PlayerAdded race seen, so no server change needed). One revision: dark text outline on question, seconds and feedback labels for legibility.
- **Needs a manual check (jg):** Submit button click, phone-landscape emulator, touch targets and keyboard, gamepad.

## Audits
- [[AUD-20261025-TASK-0093-01]] pass (Sonnet, attempt 1): 1 minor, 1 nit, none blocking.

## Outcome
