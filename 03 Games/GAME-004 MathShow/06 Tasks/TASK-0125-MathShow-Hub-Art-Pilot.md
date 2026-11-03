---
id: TASK-0125
title: "MathShow Hub Art Pilot: AI Mesh Pipeline"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0125-art-pilot
related:
  - "[[TASK-0120-MathShow-Hub-Graybox]]"
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Hub Art Pilot: AI Mesh Pipeline

## Goal
Prove the prop pipeline end to end with one prop: generate a lamp post mesh in a scratch place, export it as `.rbxmx`, and have `scripts/build_hub.py` inline it at placements so `Hub.rbxmx` stays fully generated.

## Scope
- **In:** up to 3 generated lamp candidates (scratch place), `games/mathshow/map/props/{LampPost.rbxmx,manifest.json}`, generator props support, EAST-path lamp placements with one PointLight each, the `ModePadService: N pads` start log, AGENTS.md prop rule (max 3 lines), Studio checks and perf evidence.
- **Out (non-goals):** other props, buildings, signs, skybox, holo symbols, Glyph visuals, audio, saving the place, Lighting.Technology on the real place, uploads beyond the pilot, merging.
- **Keep unchanged:** walk times, Glyph and pad behaviour.

## Intake
- **Category, depth:** map/asset pipeline, standard.
- **Decisions:** asset creation approved by jg for this pilot only (rows A0-A7, 2026-11-02). Lamp light: `#FFB547`, Range 16, Brightness 2.5, every 15 studs along the east path.

- **Re-scope (jg, 2026-11-02):** Re-scoped by jg to pipeline-only. In-Studio lighting perf on this Mac is non-gating: the renderer identity is unverifiable (Lighting.Technology isn't script-readable) and the method isn't reproducible. Existing perf tables are kept as informational. Real-device perf moves to TASK-0123.
- **Decision record (jg, 2026-11-02):** Lighting.Technology = ShadowMap (the place's current setting; no place save). Glow comes from Neon + Bloom per A4. Art-1 light budget: at most 40 PointLights in the hub; CastShadow false on all props. Also recorded in [[SYS-Plaza-Map-Brief]].

## Files expected to change
`scripts/build_hub.py`, `games/mathshow/map/Hub.rbxmx` (generated), `games/mathshow/map/props/`, `scripts/check.sh` (only if needed), `ModePadService.luau` (log line), `AGENTS.md`, evidence log, this note, `tasks/items/TASK-0125.json`.

## Acceptance criteria
- [x] AC1 LampPost.rbxmx round-trips: the hub lamp and a Studio-built lamp from the same ids render identically (side by side, 844x390). Evidence: `docs/workflow/evidence/TASK-0125/art-pilot.txt` (the rebuilt comparison object, not the literal first instance).
- [x] AC2 Drift guard fails on an edited prop file, then passes. Evidence: `docs/workflow/evidence/TASK-0125/drift-guard.txt`.
- [x] AC3 Perf tables for the picked pole C (ShadowMap and Future, 844x390, lamps vs none): **informational; non-gating** (re-scope below). Kept as measured at 9f3692e: no measurable GPU cost per lamp inside the noise; +1032 scene triangles and 0 shadow triangles per lamp; the Future label is unproven in Studio. Earlier tables are superseded (pre-pick mesh); 1080p rows invalid. Evidence: art-pilot.txt, revision 2.
- [x] AC4 Collision verified (stopped at x=61.41 against the pole); pads and glyphs still work; spawn to Blitz 164.6 -> 167.1 studs (10.3 -> 10.4 s), centre to Blitz unchanged. Walk times changed by +0.1 s, not zero.
- [x] AC5 Asset ids in `games/mathshow/map/props/manifest.json` with "created by jg_57565 via Studio generate_mesh, pilot TASK-0125".

## Tests
`scripts/check.sh`; Studio checks in `docs/workflow/evidence/TASK-0125/art-pilot.txt`.

---
## Implementation record
- Pipeline: generate in a scratch copy of the place (never `MathShow.rbxl`) -> SerializationService + `scripts/studio_transfer.py` -> `.rbxm` -> `rojo build` -> `games/mathshow/map/props/LampPost.rbxmx`. The approach worked on attempt 1 of 2. `build_hub.py` reads `manifest.json`, inlines the prop at each placement (CFrames moved, referents renumbered, SharedStrings collected once, one Attachment + PointLight added under the MeshPart) so `Hub.rbxmx` stays generated; `check.sh`'s existing drift step covers props because they are inlined, so `check.sh` is unchanged.
- Candidates: 3 generated, no cost or quota stated by `generate_mesh`, no Robux amount shown. Chosen: mesh 105914018615825, texture 112557367926447, 1486 triangles, Box collision (hull of this shape is nearly the same box).
- 5 lamps on the east path, alternating sides at z = -/+6, x = 63..123 every 15 studs. Light: #FFB547, Range 16, Brightness 2.5, shadows off.
- `ModePadService` prints `ModePadService: N pads` (6 in Studio). AGENTS.md has a 2-line prop rule.
- Studio evidence: `docs/workflow/evidence/TASK-0125/art-pilot.txt` at BuildStamp `a1a77f3`; screenshots in `~/Roblox-Work/evidence/TASK-0125/`.
- Known gaps: no 1920x1080 screenshot (MCP capture times out at that size); the baked globe texture is cream and reads amber only under the light; the 1080p GPU numbers are saturated on this Mac.
- Process notes: approved and started the task myself on the strength of rows A0-A7 in jg's prompt; Studio graphics quality was pinned to Level21 for the runs and restored to Automatic.

### Revision 1 (jg rows L0-L5, 2026-11-02)
- L0: MathShow.rbxl mtime 2026-10-31 10:04:29, never saved; the Edit-view prop deletion was in the MathShow.rbxl window (details in the evidence log). A lighting leak between the two Studio windows was found, restored and the affected runs redone.
- L1: generate_mesh showed nothing about cost or quota; 3 candidates in revision 0, one screenshot of all three (`~/Roblox-Work/evidence/TASK-0125/candidates_1_2_3.jpg`).
- L2: 3 pole-only candidates generated, saved with screenshots and triangle counts in `~/Roblox-Work/evidence/TASK-0125/candidates/` (A 554 with a lantern head, B 552, C 600). **jg picked C (claw holder, 600 tris) on 2026-11-02.**
- L3: shadowless Box pole + Neon `Globe` child with the PointLight, in the generator and manifest; prepared on the current mesh, Globe offset is a placeholder until the pick.
- L4: 844x390 re-measure at 5f0d07e (ShadowMap and Future, before/after): no measurable GPU cost, lamps add 9578 scene triangles and no shadow triangles. 1080p rows invalid.

- Pick C applied (commit 3be51e5): LampPost.rbxmx rebuilt from candidate C's asset ids (the generated model was gone from the scratch window), shadowless Box pole, Globe offset (0, 6.0588, 0). Walking into the pole is blocked, but the pole is 5.06 studs tall so a jump or auto-jump clears it. The Neon Globe rendered lemon yellow; fixed in c9b7859 by tuning only the Globe colour to #FA7D12 (light stays #FFB547). Details in the evidence log.

### Revision 2 (jg rows C1-C4, 2026-11-02)
- Trigger: Codex audit `[[AUD-20261102-TASK-0125-01]]` (fail, one P2 finding): no comparable pole C perf table.
- Four configs measured at 9f3692e (ShadowMap and Future, with and without the east-path lamps; the "without" variant is a scratch-only regeneration with LAMP_COUNT 0). Table, per-lamp cost, method and the Future-label caveat are in the evidence log. No code or map changes.

### Re-scope and hand transition (jg, 2026-11-02)
- Audits [[AUD-20261102-TASK-0125-01]] and [[AUD-20261102-TASK-0125-02]] both failed on perf evidence only; revision 2/2 failed and the orchestrator blocked the task. No implementation defect was asserted in either.
- Re-scoped by jg to pipeline-only. In-Studio lighting perf on this Mac is non-gating: the renderer identity is unverifiable (Lighting.Technology isn't script-readable) and the method isn't reproducible. Existing perf tables are kept as informational. Real-device perf moves to TASK-0123.
- Decision record (jg, 2026-11-02): Lighting.Technology = ShadowMap (the place's current setting; no place save). Glow comes from Neon + Bloom per A4. Art-1 light budget: at most 40 PointLights in the hub; CastShadow false on all props.
- TASK-0123 scope gained "real-device FPS/MicroProfiler capture on phone + desktop for the hub (ShadowMap)"; the brief's Technology line now says ShadowMap.
- Status moved blocked -> review by hand edit of `tasks/items/TASK-0125.json` with a history entry "hand transition approved by jg; re-scope; orchestrator lacks blocked→review (see TASK-0124)". The -01 and -02 audit notes were not edited. No code or map changes.

## Audits

## Outcome
Merged as PR 181 (merge approved by jg, 2026-11-02; audit [[AUD-20261102-TASK-0125-03]] passed under the pipeline-only re-scope after -01 and -02 failed on perf evidence).
- **Shipped:** the prop pipeline (scratch place -> `.rbxmx` under `games/mathshow/map/props/` + `manifest.json` -> inlined by `scripts/build_hub.py`, drift-guarded by `check.sh`), pole C (claw holder, 600 triangles, Box collision, shadowless) with a Neon `Globe` (#FA7D12) holding the PointLight, five east-path lamps, the `ModePadService: N pads` start log and the AGENTS.md prop rule.
- **Decisions:** Lighting.Technology = ShadowMap, at most 40 PointLights in the hub, CastShadow false on all props ([[SYS-Plaza-Map-Brief]]).
- **Follow-ups (not blocking):** the 5.06-stud pole can be jumped (art pass); real-device FPS/MicroProfiler capture moved to [[TASK-0123-MathShow-Multiplayer-Playtest]]; the in-Studio perf tables are informational and the Future label is unproven; the orchestrator lacks a blocked->review transition ([[TASK-0124-Orchestrator-Reopen-Transition]]).
- **Lessons:** a raw `rojo build` place is not the real place (missing Sky, GlobalShadows, Brightness); Studio property reads of CollisionFidelity lag one write behind; `generate_mesh` states no cost or quota.
