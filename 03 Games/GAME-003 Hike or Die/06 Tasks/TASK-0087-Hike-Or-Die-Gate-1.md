---
id: TASK-0087
title: Hike or Die Gate 1 Prototype
type: task
project: GAME-003
status: done
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
  - "[[AUD-20261018-TASK-0087-01]]"
  - "[[AUD-20261018-TASK-0087-02]]"
  - "[[AUD-20261019-TASK-0087-03]]"
  - "[[AUD-20261019-TASK-0087-04]]"
created: 2026-10-18
updated: 2026-10-19
tags:
  - workflow/task
---

# Hike or Die Gate 1 Prototype

## Goal
Build and merge an isolated GAME-003 existence prototype. The camera currently fails in live use; jg explicitly approved merging the current prototype with that issue deferred for a higher-model review and later repair. This does not activate the project or authorize release.

## Scope
- **In:** one generated, provable trail blockout; one server-owned cryptid encounter; selfie-camera input; explainable evidence; extraction/restart; local telemetry.
- **Out (non-goals):** production lobby, co-op, persistence, stored images, monetization, paid APIs, publishing, release.
- **Keep unchanged:** GAME-001, GAME-002, current active-game setting, and all published experiences. The user authorized this local Hike or Die place for the matched, non-published Studio test.

## Intake
- **Category → workflow, depth:** Whole game → [[Game Production Workflow]], deep; also map, systems, and UI workflows.
- **References:** [[REF-MAP-001-Dark-Fantasy-World]] (layered woodland depth and warm/cool separation), [[REF-MAP-002-Stylized-Swamp-Encounter]] (readable simplified cryptid silhouette). Viewed originals; both shape the greybox's atmosphere and silhouette only. They are not asset approvals. [[REF-UI-003-Check-UI-Clean-Roblox]] was read before adding camera controls; its demo images are not present to inspect and no package/assets were adopted. Existing HOD HUD colors and buttons remain in use.
- **Reuse:** [[Resource Catalog]] and [[Reference_Code_Index]] inspected. Adapt server-created remotes, separated perception/scoring, bounded target/state cleanup from SODT-RC-1 and Npc_template; do not copy either full system. Existing Haunted UI kit is game-specific and not reused. `roblox-map` builds and proves the simple connected greybox.
- **Decisions / assumptions / open questions:** **Decision (jg, 2026-10-18):** authorized execution of the brief, approved the current visual direction, and approved [[ADR-0014-Hike-Or-Die-Gate-1-World]] and [[ADR-0015-Hike-Or-Die-Evidence-Trust-Boundary]]. **Decision (jg, 2026-10-18):** re-scoped this merge to an existence prototype; the camera is still broken and is explicitly deferred for a higher-model review and follow-up. Other prototype behavior is accepted for this stage; historical playtest evidence remains limited to what it observed. The recovered source brief and this later existence-stage acceptance are distinct; the merge did not satisfy or waive the original Gate 1 hook-study, camera, variation, or telemetry goals. **Assumption:** use a front-right scriptable selfie-camera as the first test candidate. **Open:** physical touch, final camera framing and a repeatable successful full loop remain follow-up work.

## Files expected to change
- `games/hike-or-die/`, `hike-or-die.project.json`, GAME-003 project notes and task state.
- Repo-wide check scripts/project maps are a separate `chore/` change per [[Game Production Workflow]] and are not included in this task branch.

## Acceptance criteria
- [x] AC1 Isolated code root, Rojo project and validation path; GAME-001 and GAME-002 unchanged. Evidence: direct GAME-003 checks and isolated Rojo build pass; repo-wide wiring remains a separate chore.
- [x] AC2 Existence-stage environment and marked extraction are present. Map proof passes; the brighter Studio view separates path, cover, cryptid and beacon. jg approved the visual direction and accepted the prototype for this stage on 2026-10-18; route/cover polish remains follow-up.
- [x] AC3 One cryptid supports observe, investigate, pursue and return states. [[TEST-20261018-03]] observed roaming, Investigating, a reaction-photo transition to Pursuing, and Returning after the investigation timed out. A successful return after an active chase remains unverified.
- [x] AC4 Existence-stage camera code and its known failure are documented. jg reports the camera still does not work and explicitly deferred repair for the next review. Earlier controlled probes are retained in [[TEST-20261018-03]] as historical evidence, not proof that the current experience works. Physical touch and final framing remain follow-up.
- [x] AC5 Server computes evidence from validated visibility, distance, state and risk; feedback explains result. Evidence: [[TEST-20261018-03]] records one banked server-scored photo and a forged-origin rejection with no reward.
- [x] AC6 Extraction/failure summaries match carried metadata; restart resets the round. Evidence: [[TEST-20261018-03]] records 1 photo / 2 points banked, unbanked loss on catch, restart affordance after respawn, and reset to 0 photos.
- [x] AC7 Prototype-level automated and partial Studio scenarios are recorded. Six pure-rule cases and partial Studio smoke scenarios are recorded; jg accepts the successful full-loop scenario as follow-up for this existence stage, not as verified behavior.
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
Implemented isolated GAME-003 code, project and trail blockout. First independent review [[AUD-20261018-TASK-0087-01]] found a stale chase-loop race after yielding path computation, a mismatch between validated and raycast camera origins (including non-finite origin handling), and restart positioning. The first delta review [[AUD-20261018-TASK-0087-02]] found overlapping restarts across `LoadCharacterAsync`; the latest revision adds an in-flight token and post-load owner/round/phase checks. Current HOD formatting, lint, six pure-rule cases, isolated Rojo build, repository `scripts/check.sh` (265 Lune / 163 Python) and vault validation pass. jg reports the camera still does not work and accepts deferring its repair for the existence-stage merge; historical Studio camera probes are not proof of current functionality. Prior Studio evidence includes scoring, forged-origin rejection, extraction/restart, catch/loss and phone layout; no new Studio run was made for the audit fixes. Physical touch and successful full-loop behavior remain unverified. See [[TEST-20261018-03]]. GAME-003 check-script wiring remains a separate tooling chore.

## Audits
[[AUD-20261018-TASK-0087-01]] requested changes for a stale chase-run race, inconsistent/non-finite photo-origin validation and restart positioning. [[AUD-20261018-TASK-0087-02]] confirmed the first fixes but requested an in-flight restart token and post-yield owner/round checks; those changes are now implemented. [[AUD-20261019-TASK-0087-03]] passed the final delta review. The camera remains a user-accepted known failure and is out of this existence-stage acceptance; no claim of camera functionality is made.

## Handoff
**Receiver:** jg in the matched Hike or Die Studio place. Visual direction and both ADRs are approved. Rojo serves this checkout on port 34872 with `hike-or-die.project.json`. jg reports the camera still does not work; treat earlier aim probes as historical only. The existence-stage merge explicitly defers camera repair, physical touch and full-loop validation.

1. If further Studio evaluation is needed, keep the Hike or Die place matched to the `hike-or-die.project.json` server; never connect the Haunted Collector project.
2. Camera repair, physical two-thumb input, route/cover polish and the successful full-loop scenario are deferred follow-ups; this merge does not claim they passed.
3. Record new Studio results in [[TEST-20261018-03]]. The visual direction and both ADRs were approved by jg on 2026-10-18.

Historical handoff note: at the time it was written, CI and merge were pending. **Factual update (2026-10-19):** PR #120 is merged on remote main `c85b279`; the later audit [[AUD-20261019-TASK-0087-04]] still blocks launch. Do not publish or activate the experience.

## Outcome
Existence prototype approved for merge after the required independent audit. User reports the camera still does not work; camera repair, physical touch and the repeatable full loop are explicitly deferred, and earlier playtest observations remain historical evidence only. The audit findings on chase-run races, evidence origin validation and restart concurrency were addressed; repository checks pass. [[AUD-20261019-TASK-0087-03]] records the passing final delta review. The two ADRs were approved by jg on 2026-10-18. A separate tooling `chore/` is required to add GAME-003 to `scripts/check.sh`, `scripts/typecheck.sh`, and the shared project map/Studio Index; GAME-003 remains a candidate and GAME-002 remains active.
