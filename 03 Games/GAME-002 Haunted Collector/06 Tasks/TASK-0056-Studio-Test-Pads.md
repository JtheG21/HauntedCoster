---
id: TASK-0056
title: "Studio Test Pads"
type: task
project: GAME-002
status: done
priority: low
risk: low
owner: executor
depends_on: []
branch: task/TASK-0056-Studio-Test-Pads
related:
  - "[[RSH-20261017-Reference-Automation-Spec]]"
  - "[[REF-UI-002-Resource-Boy]]"
  - "[[REF-UI-001-Throwie]]"
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/task
---

# Studio Test Pads

## Goal
Three reusable Studio test pads (spec item X11) so a texture, icon or effect is judged in context, not from a preview image: a **UI pad** (one image at 48, 128 and 512 px on dark and light), a **VFX pad** (an emitter with a given texture at three camera distances, with a lifecycle and particle-count check) and a **surface pad** (a texture on a wall under the game's Lighting). Each prints one metrics line and can be captured for jg's judgement.

## Scope
- **In:** pure layout and metrics rules in `shared/Rules/PadRules.luau` with a Lune spec, one Play scenario `tests/scenarios/TestPads.luau` taking `pad = "ui" | "vfx" | "surface"` and a texture id, a short "how to run" note in `05 Engineering/`, the Resource Catalog row.
- **Out (non-goals):** uploading any texture (every upload is jg's per-action approval), judging quality automatically (numbers are aids; jg decides), changes to the game itself.
- **Keep unchanged:** server and client game code, Net, specs outside the new files.

## Intake
- **Category → workflow, depth:** tooling / QA, light-standard
- **References:** [[REF-UI-001-Throwie]] (readability at real sizes on dark and light), [[REF-UI-002-Resource-Boy]] (texture-in-context; pack files stay outside the repo), the automation spec's X11, `evidence.py matrix`/`series` for off-Studio checks.
- **Reuse:** the existing scenario shape in `tests/scenarios/`, the finisher scenario's baseline counting, `studio-preflight`.
- **Decisions:** the pads are verified on a scratch place, not the game place; texture ids are arguments, never committed packs.

## Files expected to change
- `games/haunted/src/shared/Rules/PadRules.luau`, `games/haunted/tests/PadRules.spec.luau`, `games/haunted/tests/scenarios/TestPads.luau`, `05 Engineering/Studio Test Pads.md`, `00 Studio/Resource Catalog.md`.

## Acceptance criteria
- [x] AC1 Lune: the pure rules produce the three UI sizes on both backgrounds, three VFX camera distances and a wall layout; reject bad texture ids and sizes.
- [x] AC2 Studio: each pad runs in a fresh Play session from the scenario with a built-in texture, prints its metrics line, and leaves the place at its baseline (descendants, emitters, Lighting).
- [x] AC3 A capture of each pad is taken with the Studio tool and viewed; the note records how.
- [x] AC4 `scripts/check.sh` green; audit (light).

## Tests
- **Automated:** `scripts/check.sh`, Lune spec.
- **Studio:** `studio-preflight`, fresh Play session, each pad once.

## Risks / notes
Low: new scenario and rules only. Studio capture tool behaviour is unverified until used.

---
## Implementation record
- `PadRules` (sizes, layouts, texture-id check, metrics line) with 6 Lune tests; the spec caught a real hole (`rbxasset://textures/../x` was accepted), fixed. `TestPads.luau` scenario with `pad`, `texture`, `keep` and `cleanup` arguments. How to run: [[Studio Test Pads]].
- Studio (Place1, 2026-10-17): VFX pad (captured at 6 studs), surface pad (mandala tiled on the wall beside swatches) and UI pad (48, 128 and 512 px on dark and light) all rendered and were captured with the Studio capture tool; `vfx` and `surface` passed their baseline checks in a fresh Play session (server), `ui` in the Client data model.
- Findings: the first capture after moving the camera can be stale or time out (capture twice); Edit mode caches `require`; `PreloadAsync` hangs on a server, so the UI pad is client-only and `all` skips it there.

## Audits
- Light audit (2026-10-17, Sonnet): pass with notes; fixes applied in the same commit (see [[AUD-20261017-TASK-0056-01]]).

## Outcome
