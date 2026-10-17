---
id: STUDIO-Resource-Catalog
title: Resource Catalog
type: index
status: approved
created: 2026-10-12
updated: 2026-10-16
tags:
  - studio/catalog
related:
  - "[[Task Intake]]"
  - "[[Reference_Code_Index]]"
  - "[[ADR-0009-Shared-Production-Foundation]]"
---
# Resource catalog

The one place to look before building something that might already exist. Each row points to the authoritative copy and says how far it has been proven. Detailed guides stay where they are: code references in the [[Reference_Code_Index]], visual and audio references in the `10 References/` area indexes, tool details in [[External Skills]]. This note links to them rather than copying them.

Identity is the resource's path or existing ID. This catalog adds no new ID scheme.

## Lifecycle
These are catalog states, not note statuses. A resource may skip states, and "verified" does not mean "works everywhere": the Limits column says where it was proven.

| State | Meaning | Evidence needed |
|---|---|---|
| **captured** | A reference or idea, not built | Where it lives |
| **proposed** | A design or plan exists | A TASK or ADR |
| **implemented** | Built and in the repo; untested or only partly tested | The path |
| **verified** | Tested in at least one real context | A spec, a TEST note or an AUD note |
| **approved** | jg accepted it for reuse across projects | Who and when |
| **deprecated** | Superseded or unsafe; kept for history | What replaces it |

## Reuse-first procedure
1. Search this table and the indexes it links (Ctrl/Cmd-F, or `grep -ri <term> "00 Studio/Resource Catalog.md"`).
2. Open plausible matches. Read the actual files, not the row.
3. Check compatibility: dependencies, hierarchy, client and server boundary, the game's conventions, and the licence.
4. Decide to **reuse**, **adapt**, **extend** or **replace**, and write the decision in the task note's Intake. Explain it when the choice costs something or affects architecture.
5. After the task:
   - Add or update the row: state, evidence, limits.
   - If a shared resource changed, list its consumers in the task note so they can be checked.

Don't reuse something only because its name fits. Don't rebuild something without a concrete reason: incompatible requirements, unacceptable quality, a technical limit, or excessive adaptation cost.

## Catalog
Checked on 2026-10-12 against the repo; the evidence is linked.

### Workflow and tooling
| Resource | Location | State | Evidence | Limits / notes |
|---|---|---|---|---|
| Cheap check suite | `scripts/check.sh` (CI: `.github/workflows/check.yml`) | verified | CI on every PR | Paths are per game; a new game must be added |
| Task gates | `scripts/orchestrator.py` | verified | `tests/test_orchestrator.py` | `tasks/queue.json` format |
| Vault validator | `scripts/validate_vault.py` | verified | `tests/test_validate_vault.py` | Doesn't check frontmatter under `10 References/` |
| Git checkout guard | `scripts/preflight.sh` | verified | `tests/test_preflight.py`, [[LES-0006-Guard-Git-Checkout]] | Read-only guard |
| Headless Luau specs | `scripts/lune/specs.luau`, `games/haunted/tests/TestRunner.luau` | verified | [[ADR-0008-Headless-Specs-With-Lune]]; 125 specs pass | Pure modules only; instance requires are shimmed |
| Studio play scenarios | `games/haunted/tests/scenarios/` | verified | [[TEST-20261012-17]] and earlier TEST notes | GAME-002 specific; Studio, at most 2 players ([[Multi-Client Testing]]) |
| Note templates | `99 Templates/` | approved | [[Obsidian Conventions]] | Core Templates syntax only |
| Claude Code guard and format hooks | `.claude/settings.json`, `.claude/hooks/` | verified | `tests/test_claude_hooks.py` | Claude Code only; Codex relies on the git pre-commit hook. Matches the common command forms, not every spelling |
| Studio environment check | `scripts/studio-preflight.sh`, skill `studio-preflight` | implemented | Run on 2026-10-14 against live state: it caught Rojo serving another worktree | macOS process checks; the Studio-side checks go through Studio MCP |
| Task close-out | skill `task-close` (`.claude/skills/`, copy in `.agents/skills/`) | implemented | Not yet used on a task | Packages AGENTS.md protocol #9 and #17 and [[Task Intake]] step 10; those notes win |
| Audit subagent | `.claude/agents/auditor.md` | implemented | Not yet used on a task | Wraps [[Auditor]]; read-only; once per task |

### Production skills
| Resource | Location | State | Evidence | Limits / notes |
|---|---|---|---|---|
| Sound sourcing (`roblox-sfx`) | `.claude/skills/roblox-sfx/` | verified (sourcing and probing) | TASK-0040 shortlist: 90 candidates probed in Studio | Can't hear; human picks. Wiring output not yet merged |
| Map plan and prover (`roblox-map`) | `.claude/skills/roblox-map/` | verified | [[TASK-0012-Graveyard-And-Landmarks]], [[AUD-20261011-TASK-0012-01]] | Never run its Studio bootstrap on the Rg1 or Haunted places |
| Video watching (`watch`) | user skill | implemented | Dependencies installed 2026-10-12 | Not yet run on a real video |
| Blender pipeline | [[Blender Pipeline]], `scripts/blender/export_for_roblox.py`, Blender 5.1.0 | verified | Headless export tests; Studio import exact in FBX and glb ([[LES-0007-Blender-Studio-Scale]]) | Static meshes only; rigs and animation are untested (animation plugin not installed yet) |
| Mixamo → Roblox animations (`mixamo-roblox`) | Separate repo `~/Code/mixamo-roblox-pipeline` (private, JtheG21); vault `~/Documents/RobloxAnimVault`; skill `skills/mixamo-roblox/SKILL.md` there | verified | 25 animations published 2026-10-16 (15 R15, 10 R6: idle, walk, run, jump, fall, combat idle, punch, dance, wave, pose and more); retarget-check clean on R15, R6 and a scaled R15; Lune and Python tests in that repo | IDs: `python3 scripts/pipeline.py lookup "<term>" --rig R15` there, or its `manifest.json`. Owned by jg's personal account, so they play only in jg-owned games, not group games. Run it from a session in that repo (Rg1's guard blocks its key file). Personal use; never commit Mixamo FBX to Rg1 |

### Code patterns
| Resource | Location | State | Evidence | Limits / notes |
|---|---|---|---|---|
| External reference repos (SODT, NPC, VFX) | [[Reference_Code_Index]] | captured | Access confirmed 2026-10-11 | Reference only; adapt, don't copy balance or assets |
| Pure rules plus Lune specs | `games/haunted/src/shared/Rules/` pattern | verified | 125 specs pass | Keep rules free of instances |
| Server-validated remotes | `games/haunted/src/shared/Net.luau` and services | verified | `ExploitProbe` scenario 13/13 in [[TEST-20261011-07]] | GAME-002's remote list; reuse the shape |
| UI kit | `games/haunted/src/client/UI/Theme.luau` | implemented | Used by 6 GAME-002 UI modules | Haunted palette is project-specific; the constructors are reusable |
| Prop kit (lanterns, fences, graves, trees, mausoleums) | `games/haunted/src/server/World/Props.luau` | implemented | Used by the hub and habitat builders | Built from parts in Luau; GAME-002 art, which may be revamped |
| Haunted-tree prop (3 archetypes, optional animated face) | `games/haunted/src/server/World/HauntedTree.luau` | implemented | [[TEST-20261013-01]] (scale and readability checked in Studio) | Parts only, 13–38 parts per tree; look awaits jg's review; GAME-002 art |
| Client-reported cosmetic gaze (report edges plus keepalive; server plausibility, observer aggregation, one replicated attribute) | `games/haunted/src/shared/Rules/GazeRules.luau`, `Services/HauntedTreeService.luau`, `client/HauntedTrees.luau`, `shared/TreeSight.luau` | verified | 15 specs; [[TEST-20261013-01]] (2-player 20/20) | GAME-002; [[ADR-0010-Client-Reported-Gaze]] proposed; 6 players not verified; cosmetic only, so don't reuse it for anything that grants progress |
| GAME-002 Figma UI kit (Haunted Theme variables, text styles, Panel / Button / Toast / Coin Counter components) | Figma file `mzc2U3QPxTfY9dwtQE7xIE`, page "GAME-002 Haunted Kit" | implemented | Built 2026-10-12 from `Theme.luau` values | Gotham isn't available in Figma, so Montserrat stands in; Figma-to-Studio direction untested; the other pages are jg's structure samples, not to be edited |
| GAME-001 code | `src/`, `tests/luau` | implemented | GAME-001 TEST notes | Paused; source material only |

### Art, audio and references
| Resource | Location | State | Limits / notes |
|---|---|---|---|
| GAME-002 art direction | GAME-002 world code | implemented | Accepted for now; a full revamp is expected (jg, 2026-10-12). Not a reusable standard |
| Map screenshots (7) | `10 References/02 Map/` ([[Map References]]) | captured | On hold; context not written |
| GAME-002 sound bank | TASK-0040 (in progress) | proposed | Add here once merged |

| Throwie image-effects exploration | [[REF-UI-001-Throwie]] | captured | Needs experimentation; jg likes distressed, eerie, hand-drawn possibilities. Exports, rights and Roblox use unverified |
| Resource Boy Exclusives | [[REF-UI-002-Resource-Boy]] | captured | Needs experimentation per pack; VFX, textures, text effects and gradients are initial interests; rights, formats and Roblox suitability unverified |
| Anatomy structural modeling exploration | [[REF-MISC-001-Anatomy]] | captured | Needs experimentation on one confusing object; SVG/WebGL skill, not a verified Roblox model pipeline |
| Roqer production reference | [[REF-CODE-001-Roqer]] | captured | Needs experimentation per technique; animation/VFX first inspected; full repo available for exploration; Roqer tool dependencies and macOS compatibility unverified |
| RoPilot workflow automation reference | [[REF-CODE-002-RoPilot]] | captured | Needs experimentation; study automation and consider a trial when relevant; homepage claims only, no product testing |
| Shaders visual effects exploration | [[REF-CODE-003-Shaders]] | captured | Needs experimentation per effect; web WebGPU library; Roblox recreation, baking, output rights and performance unverified |
| Apify research and reference gathering | [[REF-CODE-004-Apify]] | captured | Needs experimentation on a bounded collection job; compare alternatives when needed; individual tools and linked comparison article unreviewed |
| Expo Skills agent knowledge and workflows | [[REF-CODE-005-Expo-Skills]] | captured | Needs experimentation per method; Expo/React Native assumptions require adaptation; PRs are research leads, not approved changes |
| Reference library organizational direction | [[REF-MISC-002-Reference-Library-Approach]] | approved | jg, 2026-10-16: evidence-backed summaries and links, possible uses and contradiction flags; direction only, no automated service implemented |
| Cinematic energy sequence quality reference | [[REF-VFX-001-Cinematic-Energy-Sequence]] | approved | jg, 2026-10-16: inspiration and minimum animation/cutscene/VFX quality; implementation needs experimentation; original video remains a temporary attachment |
| Dark fantasy world quality reference | [[REF-MAP-001-Dark-Fantasy-World]] | approved | jg, 2026-10-16: inspiration and minimum world look/feel quality; implementation needs experimentation; six reference frames preserved |
