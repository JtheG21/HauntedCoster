---
id: ENG-External-Skills
title: External Skills
type: index
status: in_progress
created: 2026-10-10
updated: 2026-10-10
tags:
  - engineering/tooling
related:
  - "[[ADR-0004-External-Skills-As-Toolbox]]"
---
# External skills (SyphoDev Roblox AI Skills)

**Source:** https://github.com/SyphoDev-yt/roblox-ai-skills, commit `f530452` (audited 2026-10-10 from a read-only clone at `~/Desktop/roblox-ai-skills-review`; nothing executed).
**Licence:** free for own and commercial games, no reselling, free redistribution must link back (`.claude/skills/SyphoDev-LICENSE.txt`).

## Installed (project-local, `.claude/skills/`, user-approved 2026-10-10)
| Skill | Why | Dependencies | Status |
|---|---|---|---|
| `roblox-map` | Map and course layout from a JSON spec, plus a **playability prover** (jump reach, falls, sightlines, ring-out windows). Fits obby sections and the ring-out finale | Python + numpy, scipy, Pillow | Copied. **Python dependencies not installed** (awaiting approval) |
| `roblox-sfx` | Sound sourcing from the Creator Store by asset id, verified in Studio, no API key | Python standard library | Copied. Ready |

## Deliberately not installed
| Item | Reason |
|---|---|
| `create-roblox-game`, `roblox-build-orchestrator` | A second orchestrator with its own state (`HANDOFF.md`, separate game folders), a publish stage, and an approval that counts as given if you just continue. Conflicts with `orchestrator.py` and our human gates |
| `roblox-code` | Knit-based scaffold (we don't use Knit). **Idea worth borrowing:** headless Luau specs through Lune (would fix [[LES-0005-Edit-Mode-Require-Cache]]) |
| 7 agents | 6 of 7 run on Opus (cost). The "never touch Studio" guard blocks `mcp__robloxstudio-mcp`, but our server is `Roblox_Studio`, so the guard wouldn't apply |
| `roblox-ui` | Later (M3). Its icon generation needs torch and diffusers (heavy for 8 GB) |
| `roblox-3d-model`, `roblox-animation`, `roblox-texture-gen`, `roblox-vfx` | Later (M5). External GPU accounts (Kaggle/HF), Blender CLI, tokens, model licences |
| `roblox-skills-setup` | Assumes a user-level install path. LOCAL.md files written by hand instead |

## Security sweep (2026-10-10)
No `eval`/`exec` and nothing obfuscated (the `b64decode` hits decode API image responses). Deletes only touch temp or stale outputs. Network calls go to apis.roblox.com (toolbox search, asset upload), Kaggle, Hugging Face, Cloudflare, Pollinations and PyTorch downloads. Remote GPU steps `pip install` large packages there. Keys are read from env vars only. Installers only copy files, but agents are overwritten without a backup.

## Local changes
`roblox-sfx/SKILL.md` line 131: `cd` path changed to the project-local folder. See `.claude/skills/PROVENANCE.md`.

## Rollback
Delete `.claude/skills/roblox-map`, `.claude/skills/roblox-sfx`, `PROVENANCE.md` and the licence copy. Revert the `AGENTS.md` section. Remove `~/.venvs/roblox-skills` if created.
