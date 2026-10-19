---
id: TASK-0087
title: Hike or Die Gate 1 Prototype
type: task
project: GAME-003
status: in_progress
priority: high
risk: high
owner: executor
depends_on: []
branch: task/TASK-0087-Hike-Or-Die-Gate-1
related:
  - "[[GAME-003 Hike or Die/00 Overview]]"
  - "[[GAME-003 Hike or Die/01 Game Design]]"
  - "[[GAME-003 Hike or Die/02 Technical Architecture]]"
  - "[[ADR-0014-Hike-Or-Die-Gate-1-World]]"
  - "[[ADR-0015-Hike-Or-Die-Evidence-Trust-Boundary]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Hike or Die Gate 1 Prototype

## Goal
Build the smallest isolated GAME-003 prototype that can test the brief's photo/risk/extraction loop. This does not activate the project or authorize release.

## Scope
- **In:** one generated, provable trail blockout; one server-owned cryptid encounter; selfie-camera input; explainable evidence; extraction/restart; local telemetry.
- **Out (non-goals):** production lobby, co-op, persistence, stored images, monetization, paid APIs, publishing, release.
- **Keep unchanged:** GAME-001, GAME-002, current active-game setting, and all published experiences. The user authorized this local Hike or Die place for the matched, non-published Studio test.

## Intake
- **Category → workflow, depth:** Whole game → [[Game Production Workflow]], deep; also map, systems, and UI workflows.
- **References:** [[REF-MAP-001-Dark-Fantasy-World]] (layered woodland depth and warm/cool separation), [[REF-MAP-002-Stylized-Swamp-Encounter]] (readable simplified cryptid silhouette). Viewed originals; both shape the greybox's atmosphere and silhouette only. They are not asset approvals. [[REF-UI-003-Check-UI-Clean-Roblox]] was read before adding camera controls; its demo images are not present to inspect and no package/assets were adopted. Existing HOD HUD colors and buttons remain in use.
- **Reuse:** [[Resource Catalog]] and [[Reference_Code_Index]] inspected. Adapt server-created remotes, separated perception/scoring, bounded target/state cleanup from SODT-RC-1 and Npc_template; do not copy either full system. Existing Haunted UI kit is game-specific and not reused. `roblox-map` builds and proves the simple connected greybox.
- **Decisions / assumptions / open questions:** **Decision (jg, 2026-10-18):** authorized execution of the brief and this task plan, approved the current visual direction, and approved [[ADR-0014-Hike-Or-Die-Gate-1-World]] and [[ADR-0015-Hike-Or-Die-Evidence-Trust-Boundary]]. **Assumption:** use a front-right scriptable selfie-camera as the first test candidate. **Open:** player-driven aim/framing, real touch interaction, route/cover choice, fair chase counterplay, and repeatable full-loop coverage remain unverified in Studio.

## Files expected to change
- `games/hike-or-die/`, `hike-or-die.project.json`, GAME-003 project notes and task state.
- Repo-wide check scripts/project maps are a separate `chore/` change per [[Game Production Workflow]] and are not included in this task branch.

## Acceptance criteria
- [x] AC1 Isolated code root, Rojo project and validation path; GAME-001 and GAME-002 unchanged. Evidence: direct GAME-003 checks and isolated Rojo build pass; repo-wide wiring remains a separate chore.
- [ ] AC2 Compact readable trail supports route/cover choice and marked extraction. Map proof passes; the brighter Studio view separates path, cover, cryptid and beacon. jg approved the visual direction on 2026-10-18; gameplay route/cover choice still needs a live review.
- [x] AC3 One cryptid supports observe, investigate, pursue and return states. [[TEST-20261018-03]] observed roaming, Investigating, a reaction-photo transition to Pursuing, and Returning after the investigation timed out. A successful return after an active chase remains unverified.
- [ ] AC4 Camera supports clear framing and shutter input, with desktop and touch evaluated before a final camera decision. Shared client/server offsets, keyboard-arrow aim and on-screen aim buttons were exercised; a controlled revised-camera shot passed server validation, but harness direction does not verify player framing. While raised, the camera now remaps camera-relative movement to the hiker's facing and temporarily disables AutoRotate; W moved forward without turning the hiker or camera, including while aim changed. Touch drag is isolated to one right-side finger so the left stick cannot steer aim. iPhone 17 Pro simulator layout fits safe areas; physical two-thumb control and player framing remain unverified ([[TEST-20261018-03]]).
- [x] AC5 Server computes evidence from validated visibility, distance, state and risk; feedback explains result. Evidence: [[TEST-20261018-03]] records one banked server-scored photo and a forged-origin rejection with no reward.
- [x] AC6 Extraction/failure summaries match carried metadata; restart resets the round. Evidence: [[TEST-20261018-03]] records 1 photo / 2 points banked, unbanked loss on catch, restart affordance after respawn, and reset to 0 photos.
- [ ] AC7 Repeatable scenarios cover validation, spoofed inputs, chase reset, extraction and restart. Six pure-rule cases and partial Studio smoke scenarios are recorded; a repeatable successful photo→pursuit→escape→extraction scenario is still pending.
- [x] AC8 `scripts/check.sh` passes; local Studio results and limitations are recorded; no release or persistence claims are made. Evidence: repo-wide check passed when run with permission for its existing sourcemap write and localhost transfer test; Studio results: [[TEST-20261018-03]].

## Tests
- **Automated:** `stylua --check games/hike-or-die/src`; `selene games/hike-or-die/src`; `lune run games/hike-or-die/tests/lune/evidence-rules.spec.luau`; `rojo build hike-or-die.project.json -o /tmp/hike-or-die-gate1.rbxl`; `/Users/jg/.venvs/roblox-skills/bin/python .agents/skills/roblox-map/scripts/prove.py games/hike-or-die/map/hike-trail.json`; repository `scripts/check.sh`.
- **Studio playtest procedure:** Partial single-player smoke completed in the dedicated Hike or Die place with the matching Rojo project; see [[TEST-20261018-03]]. Desktop C camera toggle, Q investigation, valid photo, forged-origin rejection, extraction and restart were observed. Latest continuation verified the safe-area phone layout and a controlled revised-camera server-scored reaction photo, but not player-driven framing or physical touch. The last beacon navigation ended in a catch and loss of unbanked photos. A fair escape, route/cover review and repeatable end-to-end scenario remain open. Never connect GAME-003 source to the Haunted Collector place.

## Risks / notes
- `roblox-map` marks profile character radius/height/eye height and auto-step as assumed. Its pass proves geometric reachability under that profile, not character feel.
- The client reports camera origin/direction only. The server reconstructs the expected origin, bounds aim to a facing cone, raycasts to the current cryptid model, measures distance/state, and computes points. Adversarial runtime verification remains required. The generated map builder carries `--!nocheck` because the generator emits dynamic Instance properties; the authoritative JSON is independently passed through map proof and the Luau code itself is built by Rojo.
- The project `studio-preflight.sh` is hard-coded to Haunted Collector, so this HOD session used the manual equivalent with the matched `hike-or-die.project.json` Rojo server and confirmed HOD place. Keep the server/place pairing explicit; never connect either game's project to the other place.

---
## Implementation record
Implemented separate `games/hike-or-die/` server/shared/client source and `hike-or-die.project.json`; generated and proved the 35-part trail from `map/hike-trail.json`; added pure evidence/camera/round rules, a cryptid state machine with a generation guard against stale restart loops, round/extraction/restart service, per-round cooldown reset and an isolated Lune rules spec. The selfie camera reads shared server/client offsets, offers arrow-key aim and 44-pixel on-screen aim buttons, sinks arrows while raised, applies touch safe-area clipping, and scopes touch drag to one unprocessed finger in a right-side aim zone. While the camera is raised, client movement is converted from camera-relative input to the hiker's forward/right axes and AutoRotate is temporarily disabled; opening/closing the camera no longer makes W send the hiker backward or turn the view. Studio verified W and aim together, then confirmed AutoRotate restores on close. The phone simulator verified the raised-camera layout and prompt, but not physical multitouch. Lighting was raised to dusk so route, cover, creature and beacon separate more clearly. Studio evidence includes banked scoring, forged-origin rejection, extraction/restart, catch/loss, a controlled revised-camera reaction shot scored by the server, and phone layout checks. Player framing, physical two-thumb controls, fair chase escape and route/cover judgment remain open. The final chase attempt reached the beacon area but ended with a catch and lost unbanked photos. See [[TEST-20261018-03]]. Current checks: Stylua, Selene, six pure rules cases, HOD Rojo build, map proof, vault validation and diff check all pass; repo-wide `scripts/check.sh` now passes after the latest movement fix. Luau LSP remains unavailable because configured definitions are missing. GAME-003 check-script wiring remains a separate tooling chore.

## Audits
Pending; do not request AI review until the repository check and Studio checks are green.

## Handoff
**Receiver:** jg in the matched Hike or Die Studio place. Visual direction and both ADRs are approved. Rojo serves this checkout on port 34872 with `hike-or-die.project.json`; the latest Studio test confirmed W-forward movement and steady camera while aiming, and closing the camera restores normal rotation. Studio is returned to Edit mode with the device simulator reset. Physical touch, player-driven framing, route/cover gameplay judgment and a fair escape/full-loop scenario remain.

1. If further Studio evaluation is needed, keep the Hike or Die place matched to the `hike-or-die.project.json` server; never connect the Haunted Collector project.
2. A physical touch device should verify right-side drag aim simultaneously with left-stick movement, aim taps, shutter and call behavior. The simulator check verified layout only.
3. A player-controlled run should test whether the dusk route and cover offer understandable choices and whether breaking sight/reaching safety can beat the pursuing cryptid. The last beacon attempt ended in a catch.
4. Add/execute a deterministic full-loop scenario proving photo → pursuit → escape → extraction and restart before marking AC7 complete.
5. Record any new Studio results in [[TEST-20261018-03]]. The visual direction and both ADRs were approved by jg on 2026-10-18.

Do not publish or merge from this handoff. After the manual checks are recorded, continue the task workflow with `record-exec`, independent audit, and the human merge gate.

## Outcome
In progress. The camera control friction jg reported is fixed in the local branch and verified in Studio: W now moves the hiker forward and aim no longer swings the camera; closing the camera restores normal AutoRotate. Gate 1 is not proven: player-driven revised-camera framing, physical touch evaluation, fair escape/counterplay, route/cover gameplay review and repeatable end-to-end scenarios remain. The two ADRs were approved by jg on 2026-10-18. A separate tooling `chore/` is required to add GAME-003 to `scripts/check.sh`, `scripts/typecheck.sh`, and the shared project map/Studio Index; GAME-003 remains a candidate and GAME-002 remains active.
