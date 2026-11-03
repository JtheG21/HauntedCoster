---
id: TASK-0130
title: MathShow Hub Walk-Length Test
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: codex
depends_on: []
branch: task/TASK-0130-walk-length
related: []
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---
# MathShow Hub Walk-Length Test

## Goal
A deterministic stdlib walk-length and reachability gate, subject to calibration (jg W1-W6).

## Intake
- Category: tooling, [[Systems Workflow]], standard.
- Reuse: check.sh already discovers tests/test_*.py. Adapt XML parsing approach from tests/test_build_hub.py; no reusable navigation tool in Resource Catalog. No applicable code references; the documented Reference_Code_Index path is missing. Visual art references do not apply to this numeric tooling task.
- Fact: TASK-0129 evidence is only in its active worktree; calibration must use each evidence record's measured map commit.
- Decision: jg W4 requires stopping on any >10% discrepancy, without constant tuning.
- Assumption: 1-stud point sampling, eight neighbours, 3D segment lengths; this is a navigation estimate rather than physical walk timing.
- Context usage: unavailable in this client.

## Files expected to change
scripts/hub_nav.py, tests/test_hub_walk.py, docs/workflow/STUDIO-SYNC.md, own JSON and note. check.sh already discovers the test.

## Acceptance criteria
- [ ] XML collision grid and A* routes, documented defaults.
- [ ] Spawn and centre to pads 8-12 s; all glyphs reachable.
- [ ] Calibration within 10% of measured evidence.
- [ ] Checks, independent audit, PR and green CI, unmerged.

## Tests
- Fact: `python3 -m unittest discover -s tests -p test_hub_walk.py -v`: 1 test passed in 27.069 s (measured route runtime 27.031 s); all 12 pad routes within 8-12 s, all 34 glyphs reachable on the fa0bdea map. This does not satisfy calibration.
Python tests via check.sh; compare lengths against historical Studio evidence without using Studio/Rojo (owned by Claude).

## Implementation record
Plan: build geometry sampling and A*, calibrate on the exact historical maps, then register the gate only if calibration passes.

## Audits
Pending calibration and required checks.

## Outcome
Implemented prototype, calibration failed; stopped under W4. Task status changes_requested. No PR created.

## Calibration TASK-0129 at ff44060

| Route | Studio studs | Grid studs | Difference |
|---|---:|---:|---:|
| spawn->Pad_Daily | 185.9 | 188.83 | +1.58% |
| spawn->Pad_VS | 178.5 | 180.34 | +1.03% |
| spawn->Pad_Blitz | 169.6 | 169.60 | +0.00% |
| spawn->Pad_Group | 174.3 | 161.44 | -7.38% |
| spawn->Pad_Practice | 173.9 | 177.03 | +1.80% |
| spawn->Pad_Skill | 154.7 | 164.55 | +6.37% |

Centre routes: Daily 141.47 studs (8.84 s), VS 161.16 studs (10.07 s), Blitz 150.49 studs (9.41 s), Group 161.16 studs (10.07 s), Practice 157.84 studs (9.87 s), Skill 157.84 studs (9.87 s). No measured centre-route lengths exist in the cited evidence.

Runtime: 59.005s. All 34 glyphs reachable.

## Calibration TASK-0127 at 1181b5e

| Route | Studio studs | Grid studs | Difference |
|---|---:|---:|---:|
| spawn->Pad_Daily | 189.9 | 188.83 | -0.56% |
| spawn->Pad_VS | 178.3 | 161.44 | -9.46% |
| spawn->Pad_Blitz | 173.6 | 169.60 | -2.30% |
| spawn->Pad_Group | 182.5 | 180.34 | -1.18% |
| spawn->Pad_Practice | 173.7 | 177.03 | +1.92% |
| spawn->Pad_Skill | 158.6 | 162.15 | +2.24% |
| spawn->Glyph_C_N1 | 117.0 | 114.76 | -1.91% |
| spawn->Glyph_C_N2 | 129.5 | 127.68 | -1.41% |
| spawn->Glyph_C_N3 | 143.7 | 142.11 | -1.11% |
| spawn->Glyph_C_N4 | 168.2 | 166.56 | -0.98% |
| spawn->Glyph_C_E1 | 99.8 | 94.49 | -5.32% |
| spawn->Glyph_C_E2 | 123.5 | 118.27 | -4.23% |
| spawn->Glyph_C_E3 | 143.8 | 140.73 | -2.13% |
| spawn->Glyph_C_E4 | 176.1 | 156.88 | -10.91% |
| spawn->Glyph_C_E5 | 169.9 | 164.87 | -2.96% |
| spawn->Glyph_C_E6 | 199.8 | 194.51 | -2.65% |
| spawn->Glyph_C_W1 | 103.9 | 94.49 | -9.06% |
| spawn->Glyph_C_W2 | 119.5 | 118.27 | -1.03% |
| spawn->Glyph_C_W3 | 140.0 | 140.73 | +0.52% |
| spawn->Glyph_C_W4 | 165.4 | 163.21 | -1.32% |
| spawn->Glyph_C_W5 | 176.3 | 184.49 | +4.65% |
| spawn->Glyph_C_SW1 | 60.8 | 56.14 | -7.66% |
| spawn->Glyph_C_SW2 | 83.3 | 82.18 | -1.34% |
| spawn->Glyph_C_SW3 | 100.2 | 99.63 | -0.57% |
| spawn->Glyph_C_SW4 | 153.8 | 153.13 | -0.44% |
| spawn->Glyph_C_SE1 | 58.7 | 50.72 | -13.59% |
| spawn->Glyph_C_SE2 | 77.2 | 72.52 | -6.06% |
| spawn->Glyph_R_Terrace1 | 182.9 | 184.19 | +0.71% |
| spawn->Glyph_R_Terrace2 | 182.1 | 179.53 | -1.41% |
| spawn->Glyph_R_Terrace3 | 207.6 | 202.18 | -2.61% |
| spawn->Glyph_R_Tier1 | 261.6 | 267.70 | +2.33% |
| spawn->Glyph_R_Tier2 | 226.6 | 233.49 | +3.04% |
| spawn->Glyph_R_Tier3 | 304.6 | 306.28 | +0.55% |
| spawn->Glyph_R_Tier4 | 322.1 | 332.10 | +3.10% |
| spawn->Glyph_R_Tier5 | 280.5 | 286.80 | +2.25% |
| spawn->Glyph_R_Roof1 | 187.1 | 172.94 | -7.57% |
| spawn->Glyph_R_Roof2 | 213.3 | 193.10 | -9.47% |
| spawn->Glyph_R_Lake1 | 91.2 | 85.60 | -6.14% |
| spawn->Glyph_R_Lake2 | 93.4 | 89.49 | -4.19% |
| spawn->Glyph_R_Lake3 | 109.3 | 106.14 | -2.89% |

Centre routes: Daily 141.47 studs (8.84 s), VS 161.16 studs (10.07 s), Blitz 150.49 studs (9.41 s), Group 161.16 studs (10.07 s), Practice 157.84 studs (9.87 s), Skill 157.84 studs (9.87 s). No measured centre-route lengths exist in the cited evidence.

Runtime: 51.839s. All 34 glyphs reachable.

## Calibration conclusion / handoff
- **Fact:** calibration fails W4; stop. No constants tuned. Prototype is uncommitted in /Users/jg/Desktop/Rg1-worktrees/TASK-0130 on task/TASK-0130-walk-length, based on fa0bdea.
- **Fact:** latest TASK-0129 pad values apply to ff44060. Its CSV still claims 7f71497, so it cannot establish per-glyph length calibration at ff44060. Latest text establishes reachability only. TASK-0127 CSV is pinned to 1181b5e.
- **Model limitation:** a point agent can traverse the plaza Seat_09/Seat_08 region toward Glyph_C_SE1 by rising onto the 1.5-stud seat tops (permitted as jump edges). It does not account for the radius-2 clearance or a jump arc. Competitive court walls and arch legs similarly require radius clearance; the grid uses sampled point footprints. These are concrete geometry representations the model mishandles; causal attribution of each Studio detour remains unverified without inspecting its waypoint trace.
- **Model limitation:** collidable mesh props use oriented bounds, not collision hulls. Public Humanoid docs establish WalkSpeed=16 and JumpHeight=7.2, but do not establish the assumed 1-stud automatic step threshold. JumpHeight is not the default active jump mode (UseJumpPower defaults true). These gaps prevent certifying the tool as a physical-walk oracle.
- **Pending:** W5 gate promotion, full check.sh, independent audit, commit/push/PR and CI. W4's explicit stop takes precedence; do not claim this prototype is calibrated. check.sh already discovers the new test without edits. No Studio/Rojo access or game/map writes occurred.
- Notes created: this task note. Updated: own task JSON. No other notes changed.
