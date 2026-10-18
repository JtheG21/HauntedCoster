# Atelier — shared model viewer

A local, private review stage for models created by Claude or Codex. Inspect real geometry and materials, play imported clips, preview effects, and save repeatable scene setups. This tool does not create models or certify Roblox imports.

Agent-specific review and handoff guidance: [AGENT-GUIDANCE.md](AGENT-GUIDANCE.md).

## Start

Requires Python 3.9+, Node.js 20+ and pnpm (only for dependency setup/checks). Install pinned dependencies once:

```sh
cd tools/model-viewer
pnpm install --frozen-lockfile --ignore-scripts
python3 serve.py
```

Open **http://127.0.0.1:8766**. The server stays in that terminal; Ctrl-C stops it. If the port is busy use `python3 serve.py --port 8767`. No CDN, account or API call is used after installation. Do not run Python's generic static server from the vault root.

On this Mac, Codex's bundled Node and pnpm can be used if they are absent from PATH. Run `mcp__codex_app__load_workspace_dependencies` to find them; an assistant must not assume another machine has this Mac's paths. Node is needed for checks, not for serving an already installed viewer.

## Open and inspect

- **Open model** or drag one GLB onto the page. For glTF, select the `.gltf` plus all `.bin` and image companions together. Relative subdirectory references resolve by unique filename; ambiguous/missing names fail explicitly. Self-contained GLB is the most portable format.
- Drag to orbit, right-drag to pan, scroll to zoom. Use Front / Side / Back / ¾ and **Fit model** (`F`). Front is source +Z; axes are not silently corrected. Space toggles playback when focus is outside a control.
- Inspect neutral lighting and effects off first. Night lighting, wireframe, grid, exposure and turntable are presentation controls.
- Real clip names populate the Clip selector. Map imported clips to Idle / Move / Ability. Playback supports pause, replay, timeline scrub, loop and speed. **Still** returns the model's rest pose. A static GLB stays static; the viewer does not invent a rig or motion.
- Aura, floating sparks and rings are **viewer-only** effects. They do not become Roblox emitters or alter the asset. Effect settings are saved with the scene.
- **Capture PNG** downloads the clean viewport, without the interface. **Export scene** downloads versioned JSON with the camera, presentation, mappings and time. Scenes restore paused.

## Durable packages shared by both assistants

Both Claude and Codex use the same files and commands; neither needs the other assistant's chat history. Add a model without modifying its source:

```sh
python3 scripts/library.py add /absolute/path/model.glb --id ghost-v1 --name 'Ghost v1'
python3 scripts/library.py validate --dry-run
```

A package contains `model.glb`, `scene.json`, and `manifest.json` (source filename, SHA-256, clip names). The index is derived and rebuilt only after all packages pass validation. Existing package IDs are never overwritten: use `ghost-v2` for a new revision. Click **Refresh library** after adding.

To add an exported scene with a new revision:

```sh
python3 scripts/library.py add /absolute/path/model.glb --id ghost-v2 --name 'Ghost v2' --scene /absolute/path/scene.json
```

To update only an existing package's presentation, replace its `scene.json` with the exported JSON for that same package, then validate. Do not change its model or hash in place. `library.py validate` regenerates the index; `--dry-run` does not change it. The manifest's original filename is provenance, not a promise that the original file will remain at a particular absolute path.

**Backup:** `library/` is deliberately ignored because models can be large or private. Export/copy the whole package folder to your established asset storage; keep the same folder ID when restoring into another checkout's `library/`, then run validate. Git backs up the viewer source, instructions, fixture and evidence, **not your local model library**. Browser Remember/Restore is convenience storage for one scene; JSON plus the asset package is the durable source. Loose-file scenes require opening the matching original file before import; those presets cannot identify the file by pathname and do not embed it.

## FBX / OBJ conversion

Requires Blender (tested here with 5.1). Converts into a new GLB; refuses existing output paths:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --factory-startup --python scripts/convert.py -- /absolute/model.fbx /absolute/review.glb
```

OBJ is accepted by the same command. Materials need their source images beside the original. Conversion does not guarantee axis, scale, texture or animation fidelity: inspect the converted model and compare with the original. Compressed Draco, KTX2 and meshopt inputs need an uncompressed review export; automatic decoder downloads are intentionally absent. Maximum single model input: 250 MiB. Draco-compressed glTF is unsupported without conversion. RBXM/RBXL is not a browser input.

## Verification

```sh
scripts/check.sh
# Launch the viewer in another terminal, add the fixture and an existing Wisp package:
python3 scripts/library.py add tests/fixtures/animated.glb --id animation-test --name 'Animation test · fixture'
python3 scripts/library.py add /Users/jg/Roblox-Work/haunted/art/fbx/creature_wisp.glb --id wisp-review --name 'Wisp · existing asset'
node tests/browser.mjs
```

Browser tests use local Chrome; override `CHROME_PATH` for another Chrome/Chromium executable and `VIEWER_URL` for a different port. Test fixture is an original animated triangle for mechanical tests, not production art. Browser results and screenshots are under `docs/`. In an Rg1 integration checkout, run repository-root `scripts/check.sh` for the full vault/game suite. In the standalone viewer repository, the root wrapper runs the viewer checks. Do not run Studio/Rojo to test this browser tool.

## Troubleshooting and limits

- A missing package/model/texture is an error; use Open model, restore the package, or fix the selection. The last successfully loaded model remains available after a failed model load.
- If WebGL/context creation fails, enable graphics acceleration and reload. Context loss is reported and requires reload; there is no silent fallback renderer.
- Start is loopback-only, with no write API, directory listings or exposure of the vault root. Host checks reject unexpected hostnames. File selection stays in the browser. Stop the viewer when finished.
- Desktop Chrome on this Mac is verified. Safari, Firefox, phones, very large assets and low-end GPUs are unverified. Statistics are inspection aids, not game performance certification.
- Skinning and morph animation use Three.js's glTF animation support. The included automated motion fixture tests object transforms; complex deformation needs a real rig-specific review.
- Emission/PBR appearance in a web renderer differs from Roblox. Preserve source scale/pivot, editable master and game export; hand off the reviewed package, scene JSON, PNGs, known material/rig limits and target game context. No upload or game publishing is performed here.

License: original tool follows repository terms. Three.js MIT license is installed at `node_modules/three/LICENSE`; lockfile pins it. Playwright and Prettier are development-only dependencies. No reference dragon or third-party artwork is distributed.
