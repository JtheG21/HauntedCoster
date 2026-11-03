---
id: TASK-0130
title: MathShow Hub Walk-Length Test
type: task
project: GAME-004
status: approved
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

## Acceptance criteria (A1-A5 supersede W4's stop)
- [x] A1: resume execution and commit/push prototype first (e2c7323).
- [x] A2: default radius-2 blocker clearance and horizontal jump-up costs; movement constants otherwise unchanged.
- [x] A3: tolerance max(10 percent, 10 studs) with documented variance in test docstring.
- [x] A4: calibrated both measured map commits; calibration failed twice, route test is INFORMATIONAL, Studio fresh-Play remains gate. TASK-0131 not merged at calibration (origin/main 725d2a4).
- [x] A5 local: scripts/check.sh, specs and validators pass; no game files touched.
- [ ] A5 delivery: independent audit, push, PR, green CI; no merge.

## Tests
- Fact: `python3 -m unittest discover -s tests -p test_hub_walk.py -v`: 1 test passed in 27.069 s (measured route runtime 27.031 s); all 12 pad routes within 8-12 s, all 34 glyphs reachable on the fa0bdea map. This does not satisfy calibration.
Python tests via check.sh; compare lengths against historical Studio evidence without using Studio/Rojo (owned by Claude).

## Implementation record
Plan: build geometry sampling and A*, calibrate on the exact historical maps, then register the gate only if calibration passes.

## Audits
Independent read-only audit (audit_walk_length, 2026-11-02): PASS, no findings. Independently ran scripts/check.sh: ALL CHECKS PASSED (active). Reviewed diff from fa0bdea including attempt-2 working changes; verified scope, unchanged movement constants, radius inflation, admissible A*, tolerance/evidence pins and informational fallback. Historical calibration was run by primary; reviewer did not duplicate it. Studio physics and final PR/CI outside audit. Audit retained here because user scope permits only the task note, not a separate AUD file.

## Outcome, attempt 1 (historical)
Implemented prototype, calibration failed; stopped under W4. Task status was changes_requested; no PR created at that stage.

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

## Calibration conclusion / handoff, attempt 1 (historical)
- **Fact:** calibration fails W4; stop. No constants tuned. Prototype is uncommitted in /Users/jg/Desktop/Rg1-worktrees/TASK-0130 on task/TASK-0130-walk-length, based on fa0bdea.
- **Fact:** latest TASK-0129 pad values apply to ff44060. Its CSV still claims 7f71497, so it cannot establish per-glyph length calibration at ff44060. Latest text establishes reachability only. TASK-0127 CSV is pinned to 1181b5e.
- **Model limitation:** a point agent can traverse the plaza Seat_09/Seat_08 region toward Glyph_C_SE1 by rising onto the 1.5-stud seat tops (permitted as jump edges). It does not account for the radius-2 clearance or a jump arc. Competitive court walls and arch legs similarly require radius clearance; the grid uses sampled point footprints. These are concrete geometry representations the model mishandles; causal attribution of each Studio detour remains unverified without inspecting its waypoint trace.
- **Model limitation:** collidable mesh props use oriented bounds, not collision hulls. Public Humanoid docs establish WalkSpeed=16 and JumpHeight=7.2, but do not establish the assumed 1-stud automatic step threshold. JumpHeight is not the default active jump mode (UseJumpPower defaults true). These gaps prevent certifying the tool as a physical-walk oracle.
- **Pending:** W5 gate promotion, full check.sh, independent audit, commit/push/PR and CI. W4's explicit stop takes precedence; do not claim this prototype is calibrated. check.sh already discovers the new test without edits. No Studio/Rojo access or game/map writes occurred.
- Notes created: this task note. Updated: own task JSON. No other notes changed.

## Attempt 2, jg rows A1-A5 (2026-11-02)
- A1: normal `start` transition used because `reopen` only targets review, not execution. Prototype + JSON + test + note committed as e2c7323 and pushed before modelling changes.
- A2: AgentRadius=2 source: creator-docs/content/en-us/characters/pathfinding.md:231-234 and reference/engine/classes/PathfindingService.yaml:157-162. Each obstacle span is dilated on the 1-stud lattice by a radius-2 disk; ignore the supporting part itself so tilted ramps do not block their own tops. Step=1 assumption, JumpHeight=7.2, headroom=5, WalkSpeed=16 and resolution unchanged. Jump-up edge cost is horizontal distance only; horizontal A* heuristic keeps it admissible.
- A3: abs(grid - Studio) <= max(0.10 * Studio, 10 studs). Evidence: TASK-0127/art-competitive.txt:70, Practice 184.5 then 173.7 on unchanged west geometry, 10.8 studs; Skill 175.9 then 158.6, 17.3 studs. TASK-0129/art-training.txt:28 describes smaller east variation; :42 changes target height, so that difference cannot be cited as repeatability. Test docstring records these limits.
- A4: **calibration failed twice**. Informational route results; Studio fresh-Play remains the gate. Radius inflation disconnects the north approach/terrace transitions in this model, which cannot traverse airborne gaps over dilated cells. No third model change.
- Reproducible historical comparison: `python3 tests/test_hub_walk.py --calibrate` uses exact map commits and evidence pinned to 725d2a4. Historic centre-route numeric lengths are unavailable. TASK-0129's glyph CSV is still pinned to pre-merge 7f71497, so latest post-merge text supplies pad lengths and 34/34 reachability only.
- No changes to game geometry, props, generator, Studio or Rojo. The branch still holds its fa0bdea source map; historical calibrations load measured maps read-only with git show. PR CI also tests the combined base + branch.

## Attempt 2 calibration table

Lengths are studs; `inf` means unreachable in this model, not in Studio. Passing criterion is absolute error <= max(10 percent of Studio length, 10 studs).


### TASK-0127 rev1: map=1181b5e; evidence=725d2a4
| Route | Studio studs | Grid studs | Delta studs | Delta % | Result |
|---|---:|---:|---:|---:|---|
| spawn->Pad_Daily | 189.9 | inf | +inf | +inf% | FAIL |
| spawn->Pad_VS | 178.3 | 174.60 | -3.70 | -2.07% | PASS |
| spawn->Pad_Blitz | 173.6 | 169.60 | -4.00 | -2.30% | PASS |
| spawn->Pad_Group | 182.5 | 180.37 | -2.13 | -1.17% | PASS |
| spawn->Pad_Practice | 173.7 | 177.03 | +3.33 | +1.92% | PASS |
| spawn->Pad_Skill | 158.6 | 162.15 | +3.55 | +2.24% | PASS |
| spawn->Glyph_C_N1 | 117.0 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_C_N2 | 129.5 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_C_N3 | 143.7 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_C_N4 | 168.2 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_C_E1 | 99.8 | 94.49 | -5.31 | -5.33% | PASS |
| spawn->Glyph_C_E2 | 123.5 | 118.27 | -5.23 | -4.23% | PASS |
| spawn->Glyph_C_E3 | 143.8 | 140.73 | -3.07 | -2.14% | PASS |
| spawn->Glyph_C_E4 | 176.1 | 159.13 | -16.97 | -9.63% | PASS |
| spawn->Glyph_C_E5 | 169.9 | 164.87 | -5.03 | -2.96% | PASS |
| spawn->Glyph_C_E6 | 199.8 | 194.69 | -5.11 | -2.56% | PASS |
| spawn->Glyph_C_W1 | 103.9 | 94.49 | -9.41 | -9.06% | PASS |
| spawn->Glyph_C_W2 | 119.5 | 118.27 | -1.23 | -1.03% | PASS |
| spawn->Glyph_C_W3 | 140.0 | 140.73 | +0.73 | +0.52% | PASS |
| spawn->Glyph_C_W4 | 165.4 | 163.21 | -2.19 | -1.32% | PASS |
| spawn->Glyph_C_W5 | 176.3 | 184.49 | +8.19 | +4.64% | PASS |
| spawn->Glyph_C_SW1 | 60.8 | 58.86 | -1.94 | -3.19% | PASS |
| spawn->Glyph_C_SW2 | 83.3 | 82.18 | -1.12 | -1.35% | PASS |
| spawn->Glyph_C_SW3 | 100.2 | 99.63 | -0.57 | -0.56% | PASS |
| spawn->Glyph_C_SW4 | 153.8 | 153.13 | -0.67 | -0.44% | PASS |
| spawn->Glyph_C_SE1 | 58.7 | 54.85 | -3.85 | -6.56% | PASS |
| spawn->Glyph_C_SE2 | 77.2 | 72.52 | -4.68 | -6.06% | PASS |
| spawn->Glyph_R_Terrace1 | 182.9 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Terrace2 | 182.1 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Terrace3 | 207.6 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Tier1 | 261.6 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Tier2 | 226.6 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Tier3 | 304.6 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Tier4 | 322.1 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Tier5 | 280.5 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Roof1 | 187.1 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Roof2 | 213.3 | inf | +inf | +inf% | FAIL |
| spawn->Glyph_R_Lake1 | 91.2 | 85.60 | -5.60 | -6.14% | PASS |
| spawn->Glyph_R_Lake2 | 93.4 | 89.49 | -3.91 | -4.18% | PASS |
| spawn->Glyph_R_Lake3 | 109.3 | 106.14 | -3.16 | -2.89% | PASS |
Runtime: 79.515s

### TASK-0129 post-merge: map=ff44060; evidence=725d2a4
| Route | Studio studs | Grid studs | Delta studs | Delta % | Result |
|---|---:|---:|---:|---:|---|
| spawn->Pad_Blitz | 169.6 | 169.60 | -0.00 | -0.00% | PASS |
| spawn->Pad_Daily | 185.9 | inf | +inf | +inf% | FAIL |
| spawn->Pad_Group | 174.3 | 174.60 | +0.30 | +0.17% | PASS |
| spawn->Pad_Practice | 173.9 | 177.03 | +3.13 | +1.80% | PASS |
| spawn->Pad_Skill | 154.7 | 172.08 | +17.38 | +11.24% | FAIL |
| spawn->Pad_VS | 178.5 | 180.37 | +1.87 | +1.05% | PASS |
Runtime: 24.065s
CALIBRATION FAIL

### Interpretation
- TASK-0127 rev1: 25/40 measured lengths pass; 15 fail (Daily; common north N1-N4; rare Terrace1-3, Tier1-5, Roof1-2 are unreachable in the model). All finite routes fit A3.
- TASK-0129 post-merge: 4/6 measured pad lengths pass; Daily is unreachable, Skill is +17.38 studs (+11.24 percent), over its 15.47-stud tolerance. This is not a successful walking/reachability gate.
- Radius dilation separates walkable elevations at ramps, tier stair blocks and roof approaches; nearest-neighbour edges cannot bridge the resulting empty cells. Training court walls also lengthen the Skill route too much relative to the post-merge Studio record. No corrective model iteration is authorised or attempted.
- Full comparison command exited 1 as expected. The informational unittest path never asserts route results. Existing synthetic tests still enforce radius, jump cost and tolerance helper behavior.
- Validation: scripts/check.sh ALL CHECKS PASSED (active), including 341 Luau specs and Python suite. validate_queue.py: 122 tasks, 0 errors. validate_vault.py: 0 errors/warnings. git diff --check clean. No new Studio run (no runtime/game source changes; historic evidence only).

## Current validation and handoff
- Implemented and tested: A1-A4, informational route reporting, calibration harness and three synthetic checks. Targeted suite: 4 tests OK in 110.167 s; route test runtime 110.088 s on the fa0bdea map (concurrent processes affected wall time). Historical map runtimes: TASK-0127 79.515 s; TASK-0129 six-pad calibration 24.065 s.
- Two independent full check.sh runs passed (executor + auditor). No new model tuning, no extra constants, no third revision.
- Checkout: /Users/jg/Desktop/Rg1-worktrees/TASK-0130, branch task/TASK-0130-walk-length. W5 is the final two lines of docs/workflow/STUDIO-SYNC.md. Test already participates in check.sh via unittest discovery, so no check.sh edit.
- Status after audit: approved for merge consideration, not merged; jg retains the merge decision. PR/CI delivery is completed below.
- Notes created this task: TASK-0130 note. Notes updated this stage: this note and STUDIO-SYNC.md; own task JSON updated via orchestrator. No game notes or Resource Catalog edits (outside approved file scope). Usage/context start reading unavailable; no tokens estimated or ledger written.
