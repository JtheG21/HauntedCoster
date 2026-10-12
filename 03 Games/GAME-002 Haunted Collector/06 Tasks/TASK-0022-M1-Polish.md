---
id: TASK-0022
title: M1 Polish
type: task
project: GAME-002
status: approved
priority: medium
risk: low
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0022-M1-Polish
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[RETRO-M1-Playable-MVP-Loop]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# TASK-0022: M1 Polish

## Goal
Fix the UX and test gaps found in M1 that don't affect security or persistence.

## Scope
- **In:** Exhibit in-range feedback per slot (TEST-03 F6); a completion hint tailored to what's missing (F7); the drawn capture zone matching the judged window (or a spec bounding the slack); show the 'Already upgraded' reply; quality specs that reach both clamps; rebuild or cancel the track when a plot changes owner mid-ride; CrossPlot asserts the griefer was seated and the cancel asserts the ride started; trophy count excludes the TrainBell clue; journal Crypt species from config; Ashen roll matches 30%; a robust `setMovement` in the editor.
- **Out:** Economy retuning (needs playtest data, roadmap M2); sound.

## Files expected to change
- `games/haunted/src/client/UI/` (Mansion, Journal, Capture, TrackEditor)
- `games/haunted/src/shared/Rules/` (Track, Capture, Variants)
- `games/haunted/src/server/Services/TrainService.luau`
- `games/haunted/tests/`

## Acceptance criteria
- [ ] AC1: Each listed item is fixed or explicitly deferred with a reason in the Implementation record
- [ ] AC2: New or changed specs fail when the behaviour is removed (no specs that pass for the wrong reason)
- [ ] AC3: FullLoop, CrossPlot and ExploitProbe pass
- [ ] AC4: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs and scenarios named in the ACs.
- **Who settles the evidence:** Scenarios and specs (Claude). **jg** judges the UX items in a short feel run.

## Risks / notes
Proposed in [[RETRO-M1-Playable-MVP-Loop]]; created as `ready` with jg's approval on 2026-10-11. Broad scope. Split if the diff grows past one reviewable PR.

---
## Implementation record
References: the `10 References/01 UI` index is empty, so the existing Theme and Mansion conventions were followed.

| Item | Change |
|---|---|
| Exhibit in-range feedback (TEST-03 F6) | `MansionUI`: per-slot "near the track" / "too far from the track (no bonus)", same rule as the payout; re-renders when the route changes |
| Completion hint (F7) | `TutorialRules.completeHint`: names only what's missing (landmarks still needed, Restore house), "open to you" once both are met, and a post-catch line. `TutorialService` passes `landmarks` |
| Capture zone vs judged window | `CaptureRules.judgedWidth`; the meter draws it. Spec: measured judge window = drawn width, and it stays on the bar |
| Stale "Already upgraded" | Shown as an info toast instead of being hidden |
| Quality clamps | Spec reaches the ceiling (fails without the clamp); the floor equals the formula base |
| Plot changes owner mid-ride | `TrainService`: a rebuild skipped mid-ride sets `rebuildPending` and is redone from the current owner when the ride ends |
| Tests that could pass vacuously | CrossPlot: the parked seat refuses A, and an enabled seat seats A and then ejects them. FullLoop: asserts seated in the FrontSeat before the cancel |
| Trophy count | Counts landmark clues only (TrainBell excluded) |
| Journal Crypt species | Zone-only variants listed for species that spawn in those zones (from `World.Zones`) |
| Ashen roll | Environmental variants roll first, so Ashen is exactly 30% in the Crypt (ADR-0006 §2) |
| Editor `setMovement` | Non-yielding, cached controls; always applies the current editing state (no race) |

Evidence: [[TEST-20261011-07]]: specs 53/0, FullLoop 57/57, ExploitProbe 13/13, Mansion capture. **CrossPlot not run** (Studio multiplayer harness hung; the CrossPlot and handover changes are judged on code). `scripts/check.sh` passes.

### Revision 1 (after [[AUD-20261011-TASK-0022-01]])
- **F1 (AC3):** the mid-ride handover is now run, in FullLoop: a rebuild requested mid-ride waits, then builds the current owner's route at ride end (59/59). The 2-player CrossPlot run is **deferred by jg** (chat answer on 2026-10-11: skip CrossPlot here, run it in the [[TASK-0020-Physical-Device-Checks]] session). The Studio multiplayer harness failed 4 times today (0 or 1 of 2 clients joined).
- **F2:** variants roll once against cumulative chances: Crypt Ashen 30% / Spectral 10% / Normal 60%, Spectral 10% elsewhere (ADR-0006 §2, item 8). Spec added for Spectral in the Crypt.
- **F3:** the server sends per-slot in-range flags (`snap.exhibitInRange`), computed from the validated route it pays on (`routeFor`, starter fallback). The Mansion only displays them.
- **F4:** the capture judge is exact (needle range over the slack window, including peaks and troughs) instead of 5 ms steps. The spec tolerance is now 0.002.
- **F5:** accepted as documented: the floor clamp can't be reached by the formula; the ceiling test does fail without the clamp.
- **F6:** the movement freeze retries every 0.5 s while editing until PlayerModule has loaded.
- Evidence: [[TEST-20261011-07]] revision-1 table. `scripts/check.sh` passes.

## Audits
- [[AUD-20261011-TASK-0022-01]]: fail (1 high: CrossPlot and handover not run; 1 medium: Spectral in the Crypt at 7%), revision 1
- [[AUD-20261011-TASK-0022-02]]: **pass** (2 low: per-snapshot warning for an invalid saved route; no spec for the judge's peak/trough branches; 3 info). AC3: the 2-player CrossPlot run is deferred to TASK-0020 by jg.

## Outcome
*(after merge: result, lessons, follow-ups)*
