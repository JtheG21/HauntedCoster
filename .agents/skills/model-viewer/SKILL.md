---
name: model-viewer
description: Use when jg wants to preview, inspect or showcase a local 3D model with the shared Atelier viewer, play imported animations, tune presentation effects, capture images or hand a model setup between Claude and Codex.
---
# Shared model viewer

Read `tools/model-viewer/README.md` for setup, package commands, controls and limits. Both assistants use the same files; no Claude Design account is required.

## Start and add
- Work in the checkout containing tools/model-viewer. Respect the vault's worktree rules for code changes.
- Install pinned dependencies there with `pnpm install --frozen-lockfile --ignore-scripts` if missing. Find the available runtime rather than assuming Node is on PATH; Codex can query load_workspace_dependencies.
- Start `python3 tools/model-viewer/serve.py` from the repository root. Open its printed loopback URL in the available browser. An existing instance is reusable only if its served files belong to this checkout.
- From tools/model-viewer, run `python3 scripts/library.py add /absolute/model.glb --id unique-revision --name 'Display name'`. Use `--scene /absolute/scene.json` to include an exported setup. Refresh the library in the page. Originals are unchanged; package IDs cannot be overwritten.
- For FBX/OBJ use the documented Blender conversion command with a fresh output path; verify materials, scale, axes and clips afterward. RBXM/RBXL and compressed glTF are not direct inputs.

## Review and handoff
1. Open the actual asset. Inspect front/side/back/three-quarter with neutral lighting and effects off; compare to that asset's approved references. The fixture and existing Wisp are test inputs, not approved art.
2. Play actual imported clips; map Idle/Move/Ability as appropriate. Missing clips mean static inspection, not permission to invent animation. Scrub important poses and check contacts/deformations.
3. Tune lighting and optional viewer-only effects; capture clean viewport PNGs and export scene JSON. Browser storage alone is not durable.
4. Retain the entire package folder in established backed-up asset storage, with scene JSON and captures. The local library is Git-ignored; pushing viewer source does not back up models. Restore whole package folders into another checkout and validate to rebuild its index.
5. Report actual evidence and remaining model/Roblox checks. Web rendering does not certify Roblox materials, rigging, imports or runtime performance. No upload, publish or paid call is part of this viewer workflow.

## Verify and recover
- Run tools/model-viewer/scripts/check.sh for viewer logic/package/server checks; repository-root scripts/check.sh before independent code review. Browser acceptance instructions are in the README.
- A missing texture/model, invalid scene or failed conversion is a visible failure; keep the source and last good package. Correct the specific input or report the limit. Avoid repeating the same failed operation.
- Stop only this viewer's terminal process when finished; never terminate another assistant's server or Studio session.
