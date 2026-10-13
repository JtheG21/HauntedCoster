---
id: RSH-20261013-Universal-Modder-Evaluation
title: Universal Modder Evaluation
type: research
status: research
project: GAME-002
sources:
  - rehan-remade/universal-modder@5ba8150 (cloned to a session scratch dir, never opened as a Claude project)
  - .claude/skills/PROVENANCE.md
  - 10 References/06 Code/Reference_Code/Reference_Code_Index.md
confidence: medium
created: 2026-10-13
updated: 2026-10-13
tags:
  - research
  - tooling
  - assets
---

# Universal Modder Evaluation

## Question
Does `universal-modder` (UM) give GAME-002 measurable gains in asset generation, rigging, textures, SFX, testing or knowledge reuse over what we already have, and can any part be adopted without breaking our workflow or safety rules?

**Short answer:** don't install it as a plugin or dependency. Borrow three ideas (generation manifest, style-suffix prompting, preview-before-ship), and maybe vendor one script later behind its own ADR. Its 3D and texture outputs need Roblox-specific steps that UM doesn't have.

## Sources
| Source | URL | Accessed |
|---|---|---|
| UM repo, commit `5ba8150` (2026-10-12), MIT | https://github.com/rehan-remade/universal-modder | 2026-10-13 |
| Files read: `skills/fal-assets`, `skills/asset-pipeline`, `hooks/*`, `.claude/settings.json`, `.mcp.json`, `mcp.json`, `pyproject.toml`, `bin/um`, `SECURITY.md`, `.github/workflows/test.yml`, `examples/aoe2-de-civ/assets/gen.sh`, grep of `um/*.py` for subprocess, network and secrets | (in repo) | 2026-10-13 |

Not opened: the other 10 skills (modding, RE, video and Windows automation, which don't apply to Roblox), `um/sprite.py` and `um/blender/render_sprites.py` beyond grep, and the `knowledge/` contents. The KB has **no Roblox entries** (`grep -ri roblox` finds nothing in the repo).

## Observed (verified)
### Install surface and security audit
| Item | Finding | Risk for us |
|---|---|---|
| `.claude/settings.json` + `hooks/hooks.json` | A `SessionStart` hook runs `hooks/add-to-path.sh`, which appends `bin/` to `PATH` through `CLAUDE_ENV_FILE`. The script is benign, but **it runs automatically if Claude Code is opened inside the clone** or the plugin is installed. | Medium: auto-executes code and shadows `PATH` |
| `.mcp.json`, `mcp.json`, `.cursor/`, `.vscode/`, `.codex/`, `gemini-extension.json` | Preconfigured **remote fal MCP** (`https://mcp.fal.ai/mcp`, `Bearer ${FAL_KEY}`). Claude Code prompts to enable it when the folder is opened. | High: a paid remote API driven by the agent |
| `um/fal.py:76-84` | Reads `FAL_KEY` from env, `FAL_KEY_FILE`, **or a `.env` in the CWD or the repo root**. | Conflicts with our rule never to read `.env` |
| `um/fal.py` | Plain `urllib` REST to `queue.fal.run`, `rest.fal.ai`, `v3.fal.media`, `api.fal.ai`. Uploads local inputs to the fal CDN. | Paid; sends data off-machine |
| `um/kb.py:30,66-78,387-415` | `kb` syncs from GitHub raw; `kb share` runs `gh repo fork` and `git push` to upstream. | Outward-facing; never run `share` |
| `um/win.py` | Downloads `ffmpeg` "latest" builds (checksummed), drives Windows input, and `taskkill`s by PID. | N/A on macOS; unused |
| `subprocess` calls | All list-form, no `shell=True` (`common.py`, `render3d.py` → `blender -b --python`, `video.py` → ffmpeg). | Low |
| Dependencies | Python ≥3.10, Pillow, numpy, PyYAML. `bin/um` uses `uv run` (creates a `.venv`, resolves from PyPI without a lockfile). Optional: Blender, ffmpeg, ComfyUI. | Low–medium (unpinned resolution) |
| Secret scanning | `um publish check` has regexes for fal, Anthropic, OpenAI, GitHub, AWS and private keys, plus decompiler residue. | Useful idea |
| CI | pytest + `um kb check` + `um publish check`. | Fine |

### Capability comparison
| # | Capability | UM offers | We already have | Verdict |
|---|---|---|---|---|
| 1 | **fal assets / image-to-3D** | `um fal model3d` (Trellis 2, Hunyuan, Tripo, Meshy) → textured GLB; remesh endpoints. | Nothing generative. Studio importer (FBX/OBJ/glTF), Blender (planned local install), Creator Store. | **Adapt, paid, gated.** Only real gain area. Needs a Roblox post-step (see 4). |
| 2 | **Textures / materials** | `fal texture` (tiling), `fal pbr` (base, normal, rough, metal, height), `sprite seamless`/`tile-preview`. | Studio MaterialVariant / SurfaceAppearance by hand, built-in materials. | **Adapt.** Map to SurfaceAppearance's separate maps (no ORM packing). The tile-preview idea is free to reuse. |
| 3 | **Rigging / animation** | `fal rig` (Meshy auto-rig, humanoid only) and `hunyuan-motion`. | Studio Rig Builder, Animation Editor, Npc_template patterns. | **Reject for now.** Meshy skeletons are not R15. Ghosts don't need humanoid rigs (tween/bob), which fits the vfx_template approach. |
| 4 | **Roblox import / optimisation** | None. Engine conversions cover Unity, Unreal, Bethesda, Minecraft, AoE2. | Studio importer, Rojo `.rbxmx` rule for MeshId/TextureID. | **Gap: we'd write it.** A Blender decimate + scale + export checklist. |
| 5 | **Provenance / reproducibility** | `fal_manifest.jsonl` per call: endpoint, inputs, seed, request id, files. `gen.sh` recipes regenerate assets. | `PROVENANCE.md` for skills; roblox-sfx records asset ids. No generated-asset ledger. | **Reuse the idea** (no code). Add the file SHA-256 and model licence that UM omits. |
| 6 | **Testing / quality gates** | `publish check` (secret + residue scan), `sprite preview`, "look before shipping". | `check.sh` (StyLua, Selene, strict types, Lune specs, rojo build), roblox-map prover, roblox-sfx IsLoaded/TimeLength proof. | **Ours is stronger.** Reuse only the secret-regex idea in `check.sh`, if wanted. |
| 7 | **Knowledge reuse** | `knowledge/` field notes per game, `INDEX.md`/`index.json`, `kb search`, `kb share` upstream. | Obsidian vault: `LES-`, `RSH-`, `10 References/` guides, `validate_vault.py`. | **Reject (duplicate).** Ours is richer and Roblox-specific. |
| — | SFX / music / voice | `fal sfx`/`music`/`voice` (ElevenLabs via fal) → MP3. | `roblox-sfx` (free Creator Store, verified in Studio, no upload). | **Reject by default.** Generated audio must be uploaded (Roblox moderation + audio upload quota) and that counts as publishing. Use it only for a sound the store lacks. |

## Hypotheses
- Image→3D props (crates, lanterns, collectibles) could cut prop modelling from about 1–2 h to under 20 min each, including cleanup. *(medium; test in the PoC: time it and count manual fixes)*
- Raw Trellis/Hunyuan GLBs will exceed Roblox's per-mesh triangle limit or render poorly at Roblox texture resolution unless remeshed and decimated. *(high; verify current import limits in `creator-docs` before the PoC; I did not check them in this session)*
- Generated textures at 2048 px gain nothing over 1024 in Roblox. *(medium; confirm the max texture size in creator-docs)*
- The commercial-use licence differs per fal model. *(high; check each model's licence page before shipping anything)*

## Relevance to our game
Haunted Collector needs many small themed props and collectibles plus ghost VFX. Greybox and audio are already covered (roblox-map, roblox-sfx). Prop art is the uncovered gap, so UM's fal recipes are the only part that adds capability. Everything else duplicates or doesn't apply (Windows/PC modding).

## Adoption proposal
**Reuse (ideas only, no dependency)**
- Asset ledger `assets/gen/manifest.jsonl`: endpoint/model, prompt, seed, request id, output SHA-256, licence URL, Roblox asset id after upload, approver.
- A reusable **style suffix** per game in a config note (e.g. "stylised low-poly haunted Victorian, muted teal/purple, soft rim light, isolated on white, no text").
- Preview before import: a turntable or checker preview reviewed by a human before anything goes to Studio.

**Adapt (only after a separate approved task + ADR)**
- Generation: call fal's REST queue with our own ~100-line script, or vendor `um/fal.py` at `5ba8150` under `tools/` with these changes: `.env` lookup removed, key only from `FAL_KEY` set by the user in their shell, `--dry-run`/`--max-cost` guard, manifest additions above. **Not** the MCP server: CLI calls are auditable and cheaper in tokens.
- Roblox post-step (new, Blender headless): remesh/decimate to a triangle budget, apply scale (studs), +Y up, ≤1024 px textures, export FBX → Studio 3D Importer → save as `.rbxmx` in Rojo source.
- PBR → SurfaceAppearance: ColorMap/NormalMap/RoughnessMap/MetalnessMap (drop height).

**Reject**
- Installing the plugin, its SessionStart hook, its `.mcp.json` fal server, `um kb share`, `um win`, `showcase-video`, all modding/RE skills, and Meshy auto-rig.

## Dependency and cost considerations
| Item | Cost | Notes |
|---|---|---|
| fal account + `FAL_KEY` | Paid per call; 3D and video are the expensive tiers | Prices change weekly; query `get_pricing`/`um fal price` before any batch. I did not fetch current prices. |
| Blender (local, free) | Disk ~1 GB; 8 GB RAM is fine for single props | Headless `blender -b` |
| Roblox upload | Free for meshes/images; audio has a monthly upload quota | Uploading = publishing → explicit approval |
| Claude tokens | Lowest with CLI + manifest, highest with MCP discovery loops | Prefer a fixed recipe over model search |
| Python deps | Pillow, numpy (only if vendoring) | Pin with a lockfile; not in `check.sh` |

## Safe proof-of-concept plan (requires approval; nothing done yet)
1. **Approve** a `chore/fal-asset-poc` task, a spend cap (e.g. ≤ $5, ≤ 6 generations) and one target prop (e.g. a ghost lantern collectible).
2. **Isolate:** work in a git worktree outside the Rojo-served tree. No plugin, no MCP, no hook. The user exports `FAL_KEY` in their own shell; the agent never reads or echoes it.
3. **Price first:** dry-run that prints endpoint + expected cost; the human confirms.
4. **Generate:** 1 concept image → 1 image-to-3D call (+1 remesh), written to `assets/gen/` with a manifest line.
5. **Optimise:** Blender headless decimate/scale/export, then record triangles, texture size and file size.
6. **Import locally:** Studio 3D Importer into an **unpublished scratch place**, not HauntedCollector.rbxl. Screenshot next to existing props.
7. **Measure** against hand-modelling: wall-clock, $ spent, manual fixes, triangles, visual fit (human 1–5 score).
8. **Decide** with an ADR: adopt / adapt / drop. Uploading to Roblox and adding to the game are separate approved tasks.

Success bar: ≤ 20 min agent + human time per prop, ≤ $1 per accepted prop, within the triangle budget, visual score ≥ 4.

## Recommendations (max 3)
1. Don't install UM or enable its fal MCP. Adopt the **asset manifest + style suffix + preview gate** as conventions now (zero dependencies).
2. Run the gated PoC above for **props only** before deciding on any fal integration.
3. Keep audio on `roblox-sfx` and rigging in Studio. Revisit generated SFX only for a sound the Creator Store lacks.

## Needs human review
- Unverified: Roblox's current mesh triangle and texture-size limits, fal pricing, and per-model commercial licences (none fetched this session).
- Decision: PoC spend cap and target prop.
- Whether a secret-regex scan should be added to `scripts/check.sh` (separate chore).
