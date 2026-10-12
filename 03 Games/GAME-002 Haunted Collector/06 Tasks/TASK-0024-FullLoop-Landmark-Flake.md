---
id: TASK-0024
title: FullLoop Landmark Flake
type: task
project: GAME-002
status: in_review
priority: low
risk: low
owner: executor
milestone: M2
depends_on: []
branch: task/TASK-0024-FullLoop-Landmark-Flake
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m2
related:
  - "[[TASK-0023-Round-20-Design-Changes]]"
  - "[[TEST-20261011-08]]"
  - "[[AUD-20261011-TASK-0023-02]]"
  - "[[SYS-Haunted-Capture-Loop]]"
---
# TASK-0024: FullLoop Landmark Flake

## Goal
Make FullLoop's first landmark check deterministic, so a red FullLoop always means a real regression.

## Scope
- **In:** find out why "landmark records clue" (the Weeping Angel investigate straight after the first teleport) failed in 1 of 3 runs on the TASK-0023 build ([[TEST-20261011-08]], revision 1). Then fix the scenario, or fix `LandmarkService` if the game is at fault.
- **Out:** other landmark behaviour, and changing `MAX_DISTANCE` (18 studs) without evidence.

## Files expected to change
- `games/haunted/tests/scenarios/FullLoop.luau` (landmark block)
- Possibly `games/haunted/src/server/Services/LandmarkService.luau`

## Acceptance criteria
- [x] AC1: A failing landmark check reports its cause (distance and root, a missing anchor, root or profile, or a replaced character or profile), and the hypotheses tested are recorded with evidence. *Reworded by jg in chat on 2026-10-11 ("Ship the diagnostics"): the original AC1, "the cause is named with evidence", could not be met because the flake did not reproduce in 17 runs ([[TEST-20261011-09]]).*
- [x] AC2: FullLoop passes 5 runs in a row in Studio, with the landmark check passing each time
- [x] AC3 (n/a, no game fault found): If the game is at fault (a real player could hit it), the fix is in `LandmarkService` and covered by a check that fails without it
- [x] AC4: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh`; FullLoop run 5 times from Edit (`StudioTestService:ExecutePlayModeAsync({ scenario = "FullLoop" })`).
- **Who settles the evidence:** scenarios (Claude).

## Risks / notes
- **Observation:** the check failed with no detail in run 1 and passed in runs 2 and 3. `LandmarkService.investigate` returns silently when the landmark, the anchor, the root or the profile is missing, or when the root is more than 18 studs from the anchor (`LandmarkService.luau:57-67`).
- **Hypothesis (unverified):** the scenario's first `tp` (PivotTo + 0.3 s wait) runs before the character has settled or replicated after spawn, so the distance check rejects the investigate. Alternative: the anchor isn't built yet when the scenario starts.
- **Recommendation:** first add the distance and anchor state to the check's `detail`, then fix the cause. Don't just add a longer wait.
- Created as `proposed` at jg's request (chat, 2026-10-11: "open the landmark follow-up"). Needs approval before work starts.

---
## Implementation record
| Change | Why |
|---|---|
| `LandmarkService.blocker(player, id)` returns the reason an investigate would be ignored (unknown landmark, no anchor, no root, no profile, or "too far: N studs (root at …)"); `investigate` uses it | Same behaviour, but the silent early returns now explain themselves (AC1 evidence) |
| FullLoop's landmark check reports the blocker, or whether the character or profile table was replaced | The next failure names its cause |
| New `tests/scenarios/LandmarkStart.luau`: FullLoop's opening plus the first investigate | Repeats the start-of-session check in many fresh sessions cheaply |

**Evidence ([[TEST-20261011-09]]):** the teleport-revert hypothesis is not supported (20/20 clean). The plot-spawn correction, missing anchors, monster collision and random props are ruled out by reading the code. LandmarkStart 12/12, FullLoop 5/5 (81/81). **The cause is not reproduced, so AC1 is open; AC2 is met.**
**Checks:** `scripts/check.sh`: ALL CHECKS PASSED (2026-10-11).

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
