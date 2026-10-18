# Verification, 2026-10-18

## Proven

- Phase 1: real existing Wisp GLB rendered; see phase1-feasibility.md and phase1-wisp.png.
- Full viewer: real Wisp rendered with textures and camera controls; see viewer-wisp.png and clean wisp-viewport.png. Screenshot reviewed visually. No model changes or new art approval.
- Browser acceptance: browser-results.json records actual passes. Animation fixture tests actual transformed geometry during scrub and replay, including replay after a one-shot clip reaches its end. Errors preserve the last successfully loaded asset.
- Local package/state/server unit checks run by scripts/check.sh inside the viewer. The same Python tests run in the root suite through tests/test_model_viewer.py. Pinned dependency lockfile and formatter checks included.
- ci-browser.mjs runs against its own short-lived loopback server: fixture load, actual animation, rest pose, bad file recovery and access isolation. A CI job installs dependencies and Chromium and runs those checks; a remote CI result must be checked after push before claiming it passed.
- Blender 5.1 FBX conversion successfully produced `/private/tmp/viewer-conversion-wisp.glb` from the existing Wisp FBX. The initial sandboxed Blender process crashed; execution outside the sandbox succeeded. Export warned about vertex colors unused by materials. The command now uses factory-startup to avoid personal add-ons. Conversion file existence is not material-fidelity proof.

## Limits

The Wisp GLB has no imported animation clips. The original animated triangle is test geometry, not production art. Complex skin/morph deformation, arbitrary third-party assets, Safari/Firefox/mobile and low-end-device performance are unverified. Viewer appearance is not evidence of Roblox rendering, collision or runtime behavior. No Studio was used.

## Source references

- https://threejs.org/docs/pages/GLTFLoader
- https://threejs.org/manual/pages/animation-system.html
- Pinned Three.js MIT license: ../node_modules/three/LICENSE (installed dependency, not copied artwork).
- Vault spec: RSH-20261018-Shared-Model-Viewer; task TASK-0069.

## Final review

Same independent auditor passed final revision with no remaining findings and independently reran the full Rg1 suite: ALL CHECKS PASSED. Viewer checks: five JS tests and six Python tests. Both delayed-scene regressions passed in the real-Wisp browser run. Requested Opus was unavailable; review used the inherited session model. Two cleanup revisions, no further changes attempted. OBJ conversion was also executed successfully in Blender factory-startup mode using the original triangle fixture; this proves the command, not material fidelity.

## Private backup and CI

Private repository JtheG21/studio-model-viewer, implementation commit 1ec564f. GitHub Actions run https://github.com/JtheG21/studio-model-viewer/actions/runs/39162907696 passed, including the Linux browser acceptance check. Permanent local checkout /Users/jg/Code/studio-model-viewer passed the full 18-case Wisp browser acceptance; current viewer serves on port 8767. Documentation-only closure follows without changing the tested implementation.
