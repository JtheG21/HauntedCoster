---
id: TASK-0042
title: "Free AI Prop Pipeline Trial"
type: task
project: GAME-002
status: proposed
priority: medium
risk: low
owner: executor
depends_on: []
branch: task/TASK-0042-Free-AI-Prop-Pipeline-Trial
related:
  - "[[RSH-20261013-Universal-Modder-Evaluation]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Free AI Prop Pipeline Trial

## Goal
Make one ghost-lantern collectible prop with **three free sources** and pick a default pipeline by measured time, triangle count and visual fit. **$0 spend.**

## Scope
- **In:** one prop, three free sources (A Studio Assistant mesh generation with its triangle cap; B a Blender Python script written by an AI chat; C the Meshy free plan through the web app, if its download is allowed). Triangle and texture checks, side-by-side screenshots, an asset manifest entry for each.
- **Out (non-goals):** any paid plan, API key or credit purchase; uploading to Roblox; adding the prop to HauntedCollector.rbxl or `games/haunted/src`; gameplay code.
- **Keep unchanged:** the live game, the Rojo-served tree, GAME-001.

## Intake
- **Category → workflow, depth:** Art/assets, light.
- **References:** check `10 References/04 Vfx` and `05 Misc` for the lantern/ghost look before generating. Prop art style from existing in-game props.
- **Reuse:** asset manifest and style-suffix ideas from [[RSH-20261013-Universal-Modder-Evaluation]]. No Universal Modder code.
- **Decisions:** no spend (jg, 2026-10-13). Triangle check on every mesh (jg, 2026-10-13, AGENTS.md). Work only in an **unpublished scratch place**.

## Files expected to change
- `assets/gen/manifest.jsonl` (new): source, prompt, seed if any, licence, triangle count, texture size, SHA-256.
- `assets/gen/lantern_{a,b,c}.*` (exported FBX + screenshots) only if the user approves storing binaries in Git; otherwise they stay local and only the manifest is committed.
- This note.

## Acceptance criteria
- [ ] AC1 Each candidate is **≤ 2,000 triangles** (small-prop budget), measured in Blender Statistics or headless, and recorded.
- [ ] AC2 Textures are ≤ 512 px (a ~5–10 stud prop) and only one material per mesh.
- [ ] AC3 Each candidate has a manifest line with source, licence (Meshy free = CC BY 4.0 with attribution) and the exact prompt or script.
- [ ] AC4 Gameplay-distance screenshot of each next to an existing prop, with the user's visual score 1–5.
- [ ] AC5 No money spent, no key created or stored, nothing published (user confirms).
- [ ] AC6 Outcome names a default pipeline and a fallback.

## Tests
- **Automated:** `scripts/check.sh` (no code change expected; must stay green).
- **Studio procedure:**
  1. Open a new, unpublished Baseplate place (not HauntedCollector.rbxl, no Rojo connected).
  2. A: Assistant `/generate_mesh` with a ~3×3×4 stud Part selected as bounding box and the max triangle count set to 2,000.
  3. B/C: import the FBX with the 3D Importer.
  4. Check triangles, screenshot, score.

## Risks / notes
- Meshy free: 100 credits/month, about 20 per model, so about 5 models. Its help centre says Meshy 6/7 downloads are **paywalled on the free plan**. If so, source C is dropped (don't pay).
- Assistant can hit usage limits. That's why sources B/C exist.
- Free-tier CC BY 4.0 assets need a credit line in the game description if shipped.

---
## Implementation record

## Audits

## Outcome
