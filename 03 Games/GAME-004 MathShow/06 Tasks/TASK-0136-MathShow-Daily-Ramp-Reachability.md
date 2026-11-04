---
id: TASK-0136
title: "MathShow Daily Ramp Reachability"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0136-daily-ramp
related: []
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Daily Ramp Reachability

## Goal
In the TASK-0123 private playtest the Mac avatar could not walk from spawn to the Daily pad without jumping and stopped at a dark wall. Make every plaza-to-pad route walkable (no rise above 1.0 stud, at least 12 studs wide) and guard it with a deterministic test.

## Scope
- **In:** `scripts/build_hub.py` route geometry, generated `Hub.rbxmx`, `tests/test_hub_routes.py`, `scripts/check.sh`, evidence log.
- **Out (non-goals):** art beyond ramp/path geometry, pad logic, Glyph logic, menu, publishing, iPad, merging.
- **Keep unchanged:** Daily ModePad tag, attributes and size; Observatory on the highest terrace.

## Intake
- **Category, depth:** map geometry, standard. References: none beyond project conventions.
- **Decisions:** rows R0-R5 approved by jg, 2026-11-03.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0136.json`.

## Acceptance criteria
See the task file; checked off in the Outcome once measured.

---
## Implementation record

## Diagnosis (R1)
Rises along the spawn -> Daily pad route (north path, world -z; a = studs from the origin), measured on main 4a9fe32 by `tests/test_hub_routes.py`:
- **Plaza edge -> ramp 1 (a 56-72):** smooth slope, one 0.2 curb. Ramp 1 stops 2 studs inside Terrace_1's rim, so at the rim (a 72) the surface is 7.1 under the 8.0 terrace top: a **1.1-stud lip** (Path_N_Ramp1 / Terrace_1).
- **Terrace_1 (a 72-98) -> ramp 2:** flush. Ramp 2 ends at a 98, but Terrace_2's circular rim is at a 98 only on the centre line; at the path edges (b = +-6) it is at a 98.8, so a **0.8-stud slot, 10 studs deep**, sits at both sides (Path_N_Ramp2 / Terrace_2).
- **Terrace_2 (a 98-118) -> ramp 3:** ramp 3 runs a 104-122 but Terrace_3's rim is at a 118 (b = 0) to 119 (b = +-6); at the rim the ramp is at 28.9 against a 32.0 top: a **3.1-stud vertical face across the whole path**. This is the dark wall below the gallery lip that the Mac avatar stopped at (F5 in playtest.txt); the avatar's jump (7.2) could not clear it from the slope's moving surface in three attempts.
- **Terrace_3 (a 118-130) -> Daily pad:** flat; pad top 32.5 (0.5 step). The Observatory tower (a 150) and gallery (front a 139) do not touch the path.
- Not in the Daily route but found by the same guard: E-path lamp posts at b = +-6 (LAMP_SIDE) stood inside a 12-wide corridor (63, 78, 108, 123); the W and E courts, arches and walls clear a 12-wide corridor.

## Fix (R2, build_hub.py only)
Ramps now end exactly at each terrace's near rim (centre a - radius) at terrace top + 0.05, with a 2-stud landing block (ground to top) so the corners the circular rim leaves open are covered; ramp 3 starts at the end of landing 2 (a 100). Ramp slopes: 26, 29 and 38 degrees (ramp 3 was 38 before). E lamps moved to b = +-8.2, outside the path. Daily ModePad position, size, tag and attributes unchanged; Observatory unchanged on the top terrace.

## Studio run (R4)
Scratch place built from the checkout (BuildStamp 7fd395c, clean), fresh Play, Humanoid driven by MoveTo only with jumping disabled. All six pads arrive from spawn along the corridor waypoints in 10.9-12.7 s and each fires its screen (locked:daily, confirm_vs, confirm_blitz, confirm_group, practice, skillintro). A first attempt with a straight MoveTo from spawn failed for Group only (walked off the path into the court wall): a test-method error, fixed by using the corridor waypoints (second attempt; the two-attempt limit is used for this method). Regression: 34 glyph spawns, 6 pads, mid-match block (0 events on five pads), console clean. Details and what was not exercised: `docs/workflow/evidence/TASK-0136/daily-ramp.txt`.

## Outcome (2026-11-03)
- R1: the dark wall is a 3.1-stud face where ramp 3 meets Terrace_3's rim; plus a 1.1-stud lip (ramp 1) and 0.8-stud slots (ramp 2). See Diagnosis.
- R2: ramps end at the terrace rims with landing blocks; E lamps moved off the path; Daily pad and Observatory unchanged; collider guard and drift check pass.
- R3: `tests/test_hub_routes.py` fails on main (13 lane failures, `before-fix.txt`) and passes now; picked up by check.sh's Python test discovery.
- R4: see above. `hub_nav.py` (informational) still reports Daily unreachable; the Studio run is the gate.
- R5: `check.sh` green; PR open, not merged; no audit recorded.
