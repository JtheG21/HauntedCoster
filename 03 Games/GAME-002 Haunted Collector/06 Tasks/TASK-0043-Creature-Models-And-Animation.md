---
id: TASK-0043
title: "Creature Models and Animation"
type: task
project: GAME-002
status: done
priority: high
risk: medium
owner: executor
depends_on:
  - TASK-0041
branch: task/TASK-0043-Creature-Models-And-Animation
related:
  - "[[SYS-Haunted-Art-Direction]]"
  - "[[SYS-Haunted-Monetization-UI]]"
  - "[[3D Model Quality Baseline]]"
created: 2026-10-13
updated: 2026-10-16
tags:
  - workflow/task
---

# Creature Models and Animation

## Goal
Replace the four part-built creatures and their natural variants with finished, animated meshes.

Part of the overhaul jg requested on 2026-10-13 (3D asset overhaul, full UI overhaul, approved monetization scope). jg authorized the local design and implementation work, creating scoped tasks and testing in local Studio places; publishing, spending, live products, uploads and merges stay gated.

## Scope
- **In:** Wisp, Stitched Hound, Hollow Gentleman, Bell Wraith; Spectral and Ashen looks; client procedural animation; wild, carried, pen and exhibit display.
- **Out (non-goals):** Cosmetic skins and auras (TASK-0050); server movement rules.
- **Keep unchanged:** server authority, gameplay rules and tuning, existing interaction points and collisions, GAME-001.

## Intake
- **Category → workflow, depth:** Asset → [[Asset Workflow]], deep
- **References:** MODEL-MIN-013/014/015, MIN-031, MIN-037–044, MIN-048–053 (anatomy, finish); MODEL-BAD-006–012 (rejected hounds).
- **Reuse:** existing builders keep their gameplay geometry; visuals move to the art pipeline from [[TASK-0042-Art-Pipeline-And-Direction]].
- **Branch stacking:** stacked on `task/TASK-0042-Art-Pipeline-And-Direction` (queue field `stacked_on`); the queue dependency stays TASK-0041 because unmerged stacked work cannot be `done`.

## Files expected to change
- `games/haunted/art/assets/creatures*.py`, `src/client/Art/Creatures.luau`, `src/server/World/MonsterModels.luau`, services that build monster models.

## Acceptance criteria
- [ ] AC1 Wisp, Stitched Hound, Hollow Gentleman and Bell Wraith are rebuilt as finished meshes that meet or exceed MIN-013/031/037-044/048-053 and avoid BAD-006-012, inspected in four views, neutral and night light, without glow.
- [ ] AC2 Normal, Spectral and Ashen read as distinct natural identities on every species without hiding the form.
- [ ] AC3 Client-side procedural animation covers idle, roam, startle, carried, chase, retaliation and display poses; server movement, colliders, prompts and capture behaviour are unchanged.
- [ ] AC4 Wild, carried, contained and exhibited creatures all use the new art; LOD and triangle budgets hold with 8 wild plus full pens.
- [ ] AC5 scripts/check.sh passes; FullLoop, CarryGuard and Retaliation scenarios pass.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio playtest procedure:** local place `~/Roblox-Work/haunted/Overhaul.rbxl` built from this branch; scenarios named in the criteria; captures stored with the evidence.

## Risks / notes
- Runtime meshes use EditableMesh. Live use needs either jg's batch 3D import (an upload) or jg's 13+/ID verification plus the Creator Dashboard Mesh/Image API toggle ([[SYS-Haunted-Art-Direction]]).

---
## Implementation record
**References used:** MODEL-MIN-013–015 (dragon: anatomy, jaw, tapering tail), MIN-031 (layered creature versus a box assembly), MIN-037–044 (antlered creature, skeleton: tapered limbs, ribs, finger bones), MIN-048–053 (rat, zombie: features held on side and rear views), MIN-011/012 (focal face). Rejected: MODEL-BAD-006–012 (box hounds with sparkles).

**Built (commits 46f1225 and later on this branch):**
- `art/assets/creatures.py` + `hcart/anatomy.py`: Stitched Hound (metaball anatomy, digitigrade legs, two heads, teeth, stitched seams, button eye, collar and tag, bandaged tail; 8.3k tris), Lantern Wisp (curling tail, flame curl, hollow eyes, little lantern; 3.4k), Hollow Gentleman (tailored coat loft, waistcoat and buttons, beckoning glove, skull cane, floating top hat over an empty collar; 5.6k), Bell Wraith (patinated bell with glowing crack and eye slits, clapper heart, ragged shroud and ribbons, skeletal arms; 5.3k). Each has an Ashen ember-crack overlay. `props_small.py`: capture_jar.
- Server `World/MonsterModels.luau`: invisible Root + Hitbox + lights, tagged `Creature`; pens/exhibits set `ArtScale`/`Display`; the carried jar is art-dressed and tagged `CarriedCreature` (`CaptureService`).
- Client `Art/Creatures.luau`: builds art per species/variant and animates it every frame from the Root's measured speed (walk cycles, idles, jaw snaps, hat bob, ribbon sway) with `BulkMoveTo`; LOD swap at the asset's distance.
- Natural variants: Spectral = pale translucent body inside a ForceField shell plus motes; Ashen = charcoal Slate surface plus glowing ember cracks.
- `tests/scenarios/ArtShowcase.luau`: stages pens, exhibits and a carried jar for captures.

**Defects found and fixed in Studio:** client EditableMesh budget → server bake (TASK-0042); Fabric darkening → export gain; pen/exhibit art missing because the `Creature` tag replicated before the Root → attach waits for Root; Ashen too weak under warm light → darker tint, Slate, opaque.

**Evidence (`07 Playtests/assets/overhaul/`):** `blender-creature_*.jpg` (front, 3/4, side, rear, neutral), `blender-creature_*_ashen.jpg` (night, embers on), `blender-creature_hound_focus.jpg`, `T43-creatures-variants-studio-neutral.jpg` (all 4 × Normal/Spectral/Ashen in Studio), `T43-pen-residents-variants-game.jpg`, `T43-exhibit-game.jpg`, `T43-capture-jar-game.jpg`.

**Checks:** pre-commit `check.sh` steps pass (143 specs). Studio, stacked head: FullLoop 85/85 (twice, after the bake gating), CarryGuard 21/21, Retaliation 36/36. Client mesh memory with lamps + creatures 2.0–2.5 MB.

**Not verified:** animation was checked for errors and poses in stills only, not judged in motion by a person; triangle budgets were raised to ≤ 8.5k (Hound 8.3k) and recorded in [[SYS-Haunted-Art-Direction]].
- 2026-10-16 rev 1 (Claude): Lantern Wisp rebuilt from a Meshy 6 Lite base (CC BY 4.0), repainted and baked to PBR maps; 8,415 tris LOD0 / 3,165 LOD1; head split for the neck turn; textured parts imported and kept in `games/haunted/assets/ImportedArt.rbxm`. Details and asset IDs: [[SYS-Haunted-Art-Direction]]. Audit pass with minor findings (blank-mesh fallback guard, Meshy credit before publish, note updates), addressed. Awaiting Codex review and jg's acceptance.

## Handoff (Codex review, rev 1, 2026-10-16)
**Task:** TASK-0043 rev 1. Independent code review of the Lantern Wisp revision before jg accepts it.
**Receiver:** Codex (reviewer; Claude owned the implementation). **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/wisp`, branch `task/TASK-0043-Wisp-Revision`, review commits from `aad6906` through `21e9db1`. Run `scripts/preflight.sh` before any Git state change; review only, no edits unless jg asks.
**Inputs:** [[SYS-Haunted-Art-Direction]] (budget table, the "Lantern Wisp performance pass" entry and asset IDs), this note's rev 1 implementation line, the audit hand-back (verdict pass, minor findings addressed in `21e9db1`).
**Review focus:**
- `games/haunted/src/shared/Art/MeshBuild.luau` `imported()`: server-only clone, `@lod1` guard, empty-MeshId fallback. Is the fallback to the HCM1 bake still safe, and is a mesh that is linked but fails to load (moderated or private) worth guarding with `ContentProvider:PreloadAsync`?
- `haunted.project.json` mapping of `games/haunted/assets/ImportedArt.rbxm` into `ServerStorage.ImportedArt`: confirm `rojo build` includes it. Live `rojo serve` sync of MeshParts from an `.rbxm` is unverified.
- `games/haunted/art/hcart/core.py` `decimate_to(keep=...)` and `hcart/bake.py`: the weight group is inverted (weight = keep, capped at 0.8 because 1.0 locks a vertex), and behaviour without `keep` is unchanged.
- `creature_wisp.model.json`: 8,415 tris LOD0 / 3,165 LOD1 against the budget of 8,500 / 6,000.
**Constraints:** no uploads, no publishing, no Studio writes. Studio and Rojo are used by one assistant at a time; the Rojo server on port 34872 belongs to TASK-0046 (`overhaul` worktree).
**Known, not this task:** `validate_vault` fails on the TASK-0044 and TASK-0046 status mismatches.
**Report back with:** verdict, findings with file:line, the checks you ran and their output, and what is unverified.

## Audits
- 2026-10-16 rev 1 Codex review (aad6906..21e9db1): **pass**, one minor non-blocking finding. `MeshBuild.imported` accepts any non-empty MeshId, so a private or moderated mesh would render blank instead of falling back to HCM1. Fix later by checking the PreloadAsync callback status (failed downloads don't throw). Codex verified the missing, wrong-class and empty-ID fallbacks, the `@lod1` guard, that the Rojo build includes the five meshes and their SurfaceAppearances, the budget (8,415 / 3,165, with LOD1 including 919 tris from Eyes and LampGlow kept at distance), and the decimate paths. Unverified: a fresh Blender bake, live Rojo `.rbxm` sync, loading under another owner, animation in motion.
- [[AUD-20261013-TASK-0043-01]]: pass. Fixed on the TASK-0044 branch: finding 1 (Spectral shells were drawn at all distances, near-range cost up to 14.3k on the Hound) — shells are now near-only; 2 (step guarded); 3 (re-check after build); 4 (Root timeout warns); 5 (LOD hysteresis, staggered throttle); 7 (Lamp rides ArmL, Jaw/ears ride Head); 8 (separate start guards); 9 (ArtShowcase refuses non-memory profiles); 10 (Hitbox comment). Open: 6 (gait speed from a tweened Root, judge in motion), 11 (nits).

## Outcome
- **Accepted by jg, 2026-10-16** (chat: "the wisp looks good go ahead and close it out"). The merge was approved through `orchestrator.py approve-merge`.
- Four creatures rebuilt (original pass, AUD-20261013-TASK-0043-01). The Lantern Wisp was then revised to match the approved concept (rev 1): a Meshy base (CC BY 4.0), repainted, PBR-baked, the head split for the neck turn, 8,415 / 3,165 tris, imported textures kept in `games/haunted/assets/ImportedArt.rbxm`. Independent audit and Codex review both passed.
- **Delivery:** the revision lives on `task/TASK-0043-Wisp-Revision`, stacked on the overhaul integration line (TASK-0042…0051). It reaches `main` with that line through [[TASK-0052-Overhaul-Verification]], not on its own, because a direct merge would ship unapproved overhaul work.
- **Follow-ups:** the player-facing Meshy credit before publish; a PreloadAsync status guard for imported meshes (do it together with the other creatures' imports); the known budget overages listed in `tests/test_art_budgets.py`; the other three creatures can follow the Wisp's steps (`review.sh`, `art-import`).
