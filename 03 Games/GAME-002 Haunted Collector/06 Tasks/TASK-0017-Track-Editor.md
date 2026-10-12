---
id: TASK-0017
title: Track Editor
type: task
project: GAME-002
status: in_review
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0015
  - TASK-0016
branch: task/TASK-0017-Track-Editor
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# TASK-0017: Track Editor

## Goal
A simple cross-platform control-point editor that lets players make a genuine route choice, validated and saved by the server.

## Scope
- **In:** Editor mode UI (add/select/move/delete, preview, Confirm/Cancel/Exit; touch, mouse, gamepad); 2 special pieces; exhibit-range preview; server validation and persistence.
- **Out:** Branching, physics, free building placement.

## Files expected to change
- `games/haunted/src/client/TrackEditor.client.luau`
- `games/haunted/src/shared/Rules/TrackRules.luau`
- `games/haunted/src/server/Services/TrainService.luau`

## Acceptance criteria
- [ ] AC1: Editor only opens with the tier-1 unlock (server-checked)
- [ ] AC2: Points can be added, moved and removed with mouse and touch; preview updates
- [ ] AC3: Server rejects too few/many points, length out of range, out-of-plot points, self-overlap; reason shown; last valid route kept
- [ ] AC4: Confirmed route rebuilds track, persists and is restored after rejoin
- [ ] AC5: Route quality modifier stays within config range (spec)
- [ ] AC6: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs named in the ACs (run in a fresh Play session, Server data model).
- **Studio playtest procedure:** in the GAME-002 place, start Play from a fresh profile and walk each AC in order. Record the results in the Implementation record, and say plainly which ones were not run.

## Risks / notes
Planned from [[INBOX-20261011-Haunted-Collector-Brief]]. Blocked on approval of [[ADR-0005-Haunted-Collector-Direction]]. Numbers come from the draft design and are tunable.

---
## Implementation record
*Prototype built in one integration commit, `17cb5ae` on `task/TASK-0011-Haunted-Scaffold-And-Player-Data`, which covers TASK-0011 to TASK-0018. The user approved building without per-task gates on 2026-10-11.*
- `scripts/check.sh`: all pass (StyLua, Selene, strict typecheck for both projects, Rojo builds, vault, Python tests).
- Unit specs: 37/37 pass headless ([[TEST-20261011-01]]). Server smoke in Run mode: clean.
- *(Superseded below: FullLoop has since run, see revision 1.)*

### Revision 1 (with TASK-0011, `5878f6d`, merged in PR #2)
- Self-overlap clearance rule added; the editor tap offset (top-bar inset) was fixed; prompts are disabled while editing; gamepad cursor support.
- Evidence: [[TEST-20261011-03]] (real-client editor: add, select, move, delete, piece, out-of-bounds tap, valid and invalid Confirm), [[TEST-20261011-04]] (fix checks).

### Revision 2 (`task/TASK-0017-Track-Editor`, last allowed revision)
- **F1 (touch, AC2):** moved to M2 by jg ([[ADR-0006-M1-Tuning-And-Scope-Decisions]] item 7). The specific risk the audit named is guarded in code: character controls are disabled while the editor is open, so a tap in the thumbstick or jump area can't move the character (checked: W and stick held while editing don't move it).
- **F2:** the clearance spec uses a thin loop with every control point ≥ 6 studs apart, asserts the clearance reason, and has a valid hairpin as a positive case.
- **F3:** ExploitProbe unlocks tier 1 first (test shortcut), spaces out the route calls past the rate limit, and asserts the validation reasons. The spec covers NaN, ±inf and 17 points.
- **F4:** R1 also confirms (Start can be taken by the console menu). The light toggle is on DPadDown (TASK-0012), so it doesn't conflict with the editor's DPadLeft/Right.
- **F5:** clearance now uses segment-to-segment distance instead of sample points.
- **F6:** validation iterates 1..n and rejects non-sequence point or piece tables (holes, extra keys). A quality-limits spec covers both extremes.
- **F7:** the editor refuses to open while carrying a monster.
- Evidence: [[TEST-20261011-06]]: specs 51/0, ExploitProbe 13/13, FullLoop 56/56, editor movement and R1 checks. `scripts/check.sh` passes.
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0017-01]]: fail, revision 1
- [[AUD-20261011-TASK-0017-02]]: fail (1 major: touch never run), revision 2

## Outcome
*(after merge: result, lessons, follow-ups)*
