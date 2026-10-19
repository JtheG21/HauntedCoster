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
- **References:** [[REF-MAP-001-Dark-Fantasy-World]] (layered woodland depth and warm/cool separation), [[REF-MAP-002-Stylized-Swamp-Encounter]] (readable simplified cryptid silhouette). Viewed originals; both shape the greybox's atmosphere and silhouette only. They are not asset approvals.
- **Reuse:** [[Resource Catalog]] and [[Reference_Code_Index]] inspected. Adapt server-created remotes, separated perception/scoring, bounded target/state cleanup from SODT-RC-1 and Npc_template; do not copy either full system. Existing Haunted UI kit is game-specific and not reused. `roblox-map` builds and proves the simple connected greybox.
- **Decisions / assumptions / open questions:** **Decision (jg, 2026-10-18):** authorized execution of the brief and this task plan. The two ADR notes remain proposed; no individual ADR approval is recorded. **Assumption:** use a front-right scriptable selfie-camera as the first test candidate; desktop/touch fit and camera choice remain unverified pending a matched Studio session. **Open:** confirm camera framing, touch dragging, creature readability, chase counterplay, and restart behavior in Studio before Gate 1 can pass.

## Files expected to change
- `games/hike-or-die/`, `hike-or-die.project.json`, GAME-003 project notes and task state.
- Repo-wide check scripts/project maps are a separate `chore/` change per [[Game Production Workflow]] and are not included in this task branch.

## Acceptance criteria
- [x] AC1 Isolated code root, Rojo project and validation path; GAME-001 and GAME-002 unchanged. Evidence: direct GAME-003 checks and isolated Rojo build pass; repo-wide wiring remains a separate chore.
- [ ] AC2 Compact readable trail supports route/cover choice and marked extraction. Evidence: map proof passes; visual/gameplay readability still needs Studio.
- [ ] AC3 One cryptid supports observe, investigate, pursue and return states. Runtime showed Investigating and Returning/Roaming; a confirmed Pursuing transition is still needed ([[TEST-20261018-03]]).
- [ ] AC4 Camera supports clear framing and shutter input, with desktop and touch evaluated before a final camera decision. C/shutter and one photo worked; manual aim and touch remain unverified because the Studio MCP mouse bridge sent zero deltas ([[TEST-20261018-03]]).
- [x] AC5 Server computes evidence from validated visibility, distance, state and risk; feedback explains result. Evidence: [[TEST-20261018-03]] records one banked server-scored photo and a forged-origin rejection with no reward.
- [x] AC6 Extraction summary matches carried metadata; restart resets camera, UI, creature and round. Evidence: [[TEST-20261018-03]] records 1 photo / 2 points banked and a restart to 0 photos.
- [ ] AC7 Repeatable scenarios cover validation, spoofed inputs, chase reset, extraction and restart. Only six pure rule cases exist; end-to-end scenarios pending.
- [x] AC8 `scripts/check.sh` passes; local Studio results and limitations are recorded; no release or persistence claims are made. Evidence: repo-wide check passed when run with permission for its existing sourcemap write and localhost transfer test; Studio results: [[TEST-20261018-03]].

## Tests
- **Automated:** `stylua --check games/hike-or-die/src`; `selene games/hike-or-die/src`; `lune run games/hike-or-die/tests/lune/evidence-rules.spec.luau`; `rojo build hike-or-die.project.json -o /tmp/hike-or-die-gate1.rbxl`; `/Users/jg/.venvs/roblox-skills/bin/python .agents/skills/roblox-map/scripts/prove.py games/hike-or-die/map/hike-trail.json`; repository `scripts/check.sh`.
- **Studio playtest procedure:** Partial single-player smoke completed in the dedicated Hike or Die place with the matching Rojo project; see [[TEST-20261018-03]]. Desktop C camera toggle, Q investigation, one valid photo, forged-origin rejection, extraction and restart were observed. Studio MCP right-drag produced zero mouse delta; manual desktop/touch framing and the investigation→pursuit→return path still need verification. Never connect GAME-003 source to the Haunted Collector place.

## Risks / notes
- `roblox-map` marks profile character radius/height/eye height and auto-step as assumed. Its pass proves geometric reachability under that profile, not character feel.
- The client reports camera origin/direction only. The server reconstructs the expected origin, bounds aim to a facing cone, raycasts to the current cryptid model, measures distance/state, and computes points. Adversarial runtime verification remains required. The generated map builder carries `--!nocheck` because the generator emits dynamic Instance properties; the authoritative JSON is independently passed through map proof and the Luau code itself is built by Rojo.
- The project `studio-preflight.sh` is hard-coded to Haunted Collector, so this HOD session used the manual equivalent with the matched `hike-or-die.project.json` Rojo server and confirmed HOD place. Keep the server/place pairing explicit; never connect either game's project to the other place.

---
## Implementation record
Implemented separate `games/hike-or-die/` server/shared/client source and `hike-or-die.project.json`; generated and proved the 35-part trail from `map/hike-trail.json`; added pure evidence/camera/round rules, one cryptid state machine with a generation guard against stale restart loops, round/extraction/restart service, per-round cooldown reset, client HUD with mouse/touch hints and scriptable camera controls, and an isolated Lune rules spec. Studio showed the camera's initial yaw pointed opposite the server's expected selfie direction; corrected the base-yaw calculation in `CameraClient.client.luau`. Runtime smoke evidence, including one valid banked photo, a forged-origin rejection, extraction, restart, and the manual drag limitation, is in [[TEST-20261018-03]]. The map prover reports `RESULT: PASS`; direct rules spec reports `6 passed, 0 failed`; Rojo build succeeds; Stylua and Selene are clean. The first repository check was blocked by sandbox denial of its typecheck sourcemap write and Python localhost bind, then passed when rerun with those permissions; its discovered missing `created` metadata was fixed. Isolated `luau-lsp analyze` on GAME-003 source reports no type errors. GAME-003 check-script wiring remains a separate tooling chore.

## Audits
Pending; do not request AI review until the repository check and Studio checks are green.

## Outcome
In progress. Gate 1 is not proven: manual camera framing, touch evaluation, confirmed pursuit/counterplay, route readability review, and repeatable end-to-end scenarios remain. The smoke test did prove a scored photo, server rejection of a forged origin, extraction and restart. A separate tooling `chore/` is required to add GAME-003 to `scripts/check.sh`, `scripts/typecheck.sh`, and the shared project map/Studio Index; GAME-003 remains a candidate and GAME-002 remains active.
