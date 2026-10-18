---
id: RSH-20261018-Shared-Model-Viewer
title: Shared Model Viewer
type: research
status: done
created: 2026-10-18
updated: 2026-10-18
related:
  - "[[Resource Catalog]]"
  - "[[LES-0008-Model-Fidelity-And-Performance]]"
tags:
  - tooling/model-viewer
---
# Shared Model Viewer

## Goal and authorization
jg requested a reusable visual model showcase that Claude and Codex can both use, then requested an interview, spec and execution. Ten multiple-choice questions were presented. No selections were returned; jg said continue. The recommended defaults below are implementation assumptions, not individual human endorsements.

## Intake
- Category: tooling, Systems Workflow; Standard depth, independent audit after checks.
- References: user Photo 1.jpg / Photo 2.jpg (chat attachments): orbitable model stage, Idle / Move / Ability / Still, visible effects. Borrow interaction ideas only, no dragon assets or code.
- Reuse: Three.js GLTFLoader, OrbitControls, AnimationMixer (MIT); original viewer code. Code reference index has no browser asset viewer. REF-MISC-001 Anatomy is an explanatory SVG tool, unsuitable as a mesh viewer; no code or assets copied.
- Quality: LES-0008 informs all-view inspection, neutral lighting and effects-off controls. Existing Wisp is a test input, not a new or accepted model.
- Brief review: ten interview questions; zero scope additions; proceed with declared defaults after user requested continuation.
- Expert lens: asset lifetime/disposal, stale async loads, embedded/external texture failures, timeline determinism, missing clips, state validation, portability, local-only file access.
- Evidence: real Wisp load and screenshot; animated GLB fixture for motion; browser interaction checks; unit tests for validation and file serving; full check.sh; independent audit. No Studio/game rendering claims.

## Spec
1. **Location and launch:** tools/model-viewer, chore/shared-model-viewer in isolated worktree. Python 3 launch command, loopback-only static server; pinned local Three.js dependency, no runtime CDN/API/credentials. Source backs up to the separate private JtheG21/studio-model-viewer repository; Rg1 integration remains local for review, per jg's explicit choice. Merge remains jg's gate.
2. **Assets:** load GLB and glTF (with selected local companion files), drag/drop or file picker; CLI add copies GLB into ignored library and creates a portable relative-path package. FBX/OBJ conversion via Blender command; never rewrite originals. Explicit errors for unsupported/compressed dependencies. No arbitrary URL loader.
3. **Inspection:** orbit/pan/zoom, front/side/back/three-quarter, fit; studio/bright/night lighting; grid, wireframe, exposure, turntable; mesh/triangle/material/animation statistics. Frame geometry without altering source transforms. Floor aligned to the model.
4. **Animation:** list actual clips; map Idle/Move/Ability to imported clip names, Still returns bind/rest pose. Play/pause/replay, scrub, loop and speed. Missing clips disabled with explanation; animation creation is out of scope.
5. **Effects:** deterministic optional aura/sparks/rings preview anchored around the model, adjustable color and intensity; clearly labelled viewer-only, no claim of Roblox compatibility. Effects-off always available.
6. **Scenes:** versioned validated JSON saves camera/target, presentation settings, clip mappings and playback time. Download/import portable presets; browser local storage is convenience only. Package includes model path plus scene.json; original asset must accompany it. No silent dependency on chat history.
7. **Capture:** clean viewport PNG; explicit snapshot action. No automatic approval claim. Errors visible, keyboard-labelled controls and responsive desktop layout.
8. **Shared workflow:** README and matching Claude/Codex project skill explain launch/add/review/export, failure handling and Roblox handoff. CLI validate fails clearly on broken packages. No global app settings or agent hooks changed; checks enforce package contracts instead.
9. **Bounds:** no hosting, paid APIs, uploads, game changes, new model creation, animation authoring, comparison mode, phone certification or automated Roblox imports. Dedicated Studio place is not needed for this web-only scope.

## Phases and acceptance
- [x] Phase 1: real Wisp GLB loads in a locally served Three.js feasibility viewer; evidence saved before larger UI.
- [x] Phase 2: validated portable package, conversion command and state schema; negative cases tested.
- [x] Phase 3: full viewer controls, actual animation fixture, state round trip, missing assets/errors and screenshots verified in browser.
- [x] Phase 4: shared instructions, full checks, audit, commit/push and reviewable handoff.

## Implementation record
See [[TASK-0069-Shared-Model-Viewer]] and tools/model-viewer/docs/verification.md for actual evidence and limitations. Five JS tests, six viewer Python tests, real-Wisp browser acceptance and isolated CI browser test passed; root scripts/check.sh passed. Final independent review passed: [[AUD-20261018-TASK-0069-03]]; same inherited-model auditor because requested Opus was unavailable.

## Outcome
Implemented and tested, private branch pushed (1ec564f). Rg1 integration remains local. Visual acceptance remains jg's; web previews do not certify Roblox material translation or device performance.

## Repository disposition
On 2026-10-18, the existing HauntedCoster remote was verified public. jg selected a separate private viewer repository and requested the Rg1 integration remain local. Canonical reusable source: https://github.com/JtheG21/studio-model-viewer ; permanent local checkout: /Users/jg/Code/studio-model-viewer. Local Rg1 integration worktree: /private/tmp/rg1-shared-model-viewer. No public push or game change authorized.

## Final evidence
Implementation 1ec564f backed up privately; CI run 39162907696 passed, including Linux browser acceptance. Permanent-checkout browser acceptance passed all 18 cases. [[TASK-0069-Shared-Model-Viewer]] carries the handoff and all three audit records.
