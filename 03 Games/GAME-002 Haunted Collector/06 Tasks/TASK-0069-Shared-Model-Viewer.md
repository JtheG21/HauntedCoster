---
id: TASK-0069
title: Shared Model Viewer
type: task
project: GAME-002
status: approved
priority: medium
risk: medium
owner: executor
depends_on: []
branch: chore/shared-model-viewer
related:
  - "[[RSH-20261018-Shared-Model-Viewer]]"
  - "[[Resource Catalog]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Shared Model Viewer

## Goal
Reusable local visual model showcase for models created with either Claude or Codex.

## Scope
- **In:** browser model viewer, actual clip playback, preview effects, presets, PNG capture, portable packages, Blender conversion and shared instructions.
- **Out (non-goals):** model creation, animation authoring, Roblox importing, uploads, hosting and paid APIs.
- **Keep unchanged:** game code, existing model sources, Studio, Rojo and user configuration.

## Intake
- Systems/tooling, Standard; loopback HTTP serving warrants security-focused independent review.
- Spec, reference brief and interview: [[RSH-20261018-Shared-Model-Viewer]]. Ten optional multiple-choice questions, user requested continuation without selections; declared recommended assumptions.
- Reuse Three.js MIT GLTFLoader, OrbitControls and AnimationMixer. No suitable browser viewer in the code reference index. Existing Wisp is verification input, not newly approved art. No reference source code/assets copied.
- Authorization: jg requested interview/spec/execute, then continue. No merge approval inferred.

## Files expected to change
- tools/model-viewer; matching model-viewer skills; Resource Catalog; viewer CI/check integration; this task, spec, audit and machine state.

## Acceptance criteria
- [x] AC1 Real existing model renders with orbit, camera views, neutral lighting, effects-off inspection and statistics.
- [x] AC2 Imported clips play, pause, scrub, replay and stop correctly; missing animations and corrupt/missing assets have clear behavior.
- [x] AC3 Validated portable packages and scene JSON preserve model identity and review settings; screenshots export; originals remain unchanged.
- [x] AC4 Shared Claude/Codex instructions, conversion guidance, automated tests, full repository checks and independent audit are delivered.

## Tests
- **Automated:** viewer scripts/check.sh; browser.mjs with real Wisp and original motion fixture; ci-browser.mjs; repository scripts/check.sh.
- **Studio playtest procedure:** not applicable to this browser-only tool; no game runtime claims.

## Risks / notes
Local library is ignored by Git; preserve packages in existing asset storage. The original Wisp remains outside this worktree. FBX conversion warns about unused vertex colors; compare materials separately. Desktop Chrome verified; mobile and complex rig deformation unverified.

## Implementation record
Implementation and initial checks performed in this isolated chore worktree; task registration records the authorized scope, without claiming individual interview selections. Evidence: tools/model-viewer/docs/phase1-feasibility.md, browser-results.json, viewer-wisp.png and wisp-viewport.png. Real Wisp has no animation clips; actual geometry motion tested using original fixture. FBX conversion produced a new GLB with unused-vertex-color warnings; material fidelity remains a separate check.
- Root scripts/check.sh: ALL CHECKS PASSED (2026-10-18); viewer scripts/check.sh: formatter, five JS tests and six Python tests passed. Isolated CI browser smoke passed with actual animated transforms and server access restrictions. Remote CI run 39162907696 started after private push; result follows below.
- No Studio or game changes. Source edits in tools/model-viewer, shared skill copies, tests/test_model_viewer.py, CI, catalog/spec/task and machine state.
- Subscription token growth unavailable: no start measurement tool was provided; no estimate recorded.
- Audit model exception: project requests Opus for network code; spawn_agent rejected opus as unavailable. Independent auditor uses the inherited session model; no Opus review claimed.

## Audits
[[AUD-20261018-TASK-0069-01]] and [[AUD-20261018-TASK-0069-02]] preserved; final [[AUD-20261018-TASK-0069-03]] passes with no findings. Two optional cleanup revisions used; no further revision attempted.

## Outcome
Implemented and tested locally; independently reviewed with no remaining findings (inherited model because Opus unavailable). Five JS tests, six Python tests, browser acceptance and independent full repository check green. Private source branch pushed at 1ec564f; repository verified private. Canonical checkout browser acceptance also passed all 18 cases. Final appearance preference and Rg1 merge remain jg's decisions; no public push or game changes.

## Handoff
- Objective: use the shared model studio from either Claude or Codex; no model-creation/Roblox-import claims.
- Canonical private repository: https://github.com/JtheG21/studio-model-viewer ; checkout /Users/jg/Code/studio-model-viewer, branch chore/shared-model-viewer.
- Local Rg1 integration: /private/tmp/rg1-shared-model-viewer, chore/shared-model-viewer; intentionally not pushed to the public game repo (jg's explicit choice).
- Start: read tools/model-viewer/README.md and the model-viewer skill; launch python3 tools/model-viewer/serve.py from the private checkout. Current permanent viewer uses --port 8767.
- Inputs: GLB or glTF companions, optional imported clips; original Wisp is a static test model. Preserve originals and ignored library packages in established asset storage.
- Acceptance/evidence: tools/model-viewer/docs/browser-results.json and screenshots; private repo CI, local viewer checks and final audit.
- Constraints: no publishing, spending, game imports or merges; browser visual review is not Roblox/runtime certification.
- Remaining: private source backup complete; check CI run 39162907696 below; Rg1 integration awaits jg's review. Opus-specific review remains unavailable, disclosed in audits.
- Report actual file paths, test results and rendering/deformation limits when reviewing the next real model.

## Session notes
Created task/spec and three preserved audit records; updated Resource Catalog, orchestrator state and health report. No game overview/SYS/architecture facts changed. Rg1 integration intentionally unpushed pending jg review. Project skill lint passed; system quick_validate.py could not run because its Python environments lack PyYAML. No missing start-token reading was estimated.

## Final evidence
Private implementation commit 1ec564f pushed successfully. CI https://github.com/JtheG21/studio-model-viewer/actions/runs/39162907696 passed (Linux browser included). Permanent checkout browser run: 18/18 checks. Current viewer http://127.0.0.1:8767; temporary 8766 server stopped after verifying its PID and checkout. Main Rg1 checkout unchanged by this task; integration branch is committed locally and deliberately unpushed. No merge approved or performed.
