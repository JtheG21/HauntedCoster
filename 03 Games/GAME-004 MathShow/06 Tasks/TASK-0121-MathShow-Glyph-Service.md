---
id: TASK-0121
title: "MathShow Glyph Service"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: claude-code
depends_on: []
branch: task/TASK-0121-glyph-service
related:
  - "[[TASK-0119-MathShow-Glyph-Rules]]"
  - "[[TASK-0120-MathShow-Hub-Graybox]]"
created: 2026-11-02
updated: 2026-11-02
tags:
  - workflow/task
---

# MathShow Glyph Service

## Goal
Make the 34 hub glyphs collectable: a server service owns per-player glyph state from TASK-0119's GlyphRules, the client renders available glyphs and asks to collect them, and a HUD counter shows the session count.

## Scope
- **In:** GlyphConfig/GlyphRules extensions (RateWindowSeconds, RawRequestLimit, Symbols, parseSpawns, bad_time) and spec; `GlyphService` (spawn read from `Workspace.Hub` GlyphSpawn tags, per-player state, raw throttle, respawn loop); remotes GlyphCollect and GlyphState; client `GlyphController` (render, local debounce, HUD counter, isolated pickup FX).
- **Out (non-goals):** DataStore/persistence, quests/XP, art meshes, lamps, Lighting.Technology, mode-pad logic, publishing, merging.
- **Keep unchanged:** the map (`Hub.rbxmx`, `scripts/build_hub.py`), `mathshow.project.json`, other services.

## Intake
- **Category → workflow, depth:** Systems (server + client + remotes), standard. Approved rows P1/P2 (jg, 2026-11-02).
- **References:** none relevant in `10 References/06 Code` for glyph collection; follow project conventions (Remotes.luau/Net.luau, RateRules, BlitzService/SkillTestService service shape, Hud Fx isolation).
- **Reuse:** GlyphRules/GlyphConfig (TASK-0119), RateRules for the raw throttle, `server/Remotes.luau` creation pattern.
- **Decisions:** spawn id = the GlyphSpawn attachment's parent part name (`Glyph_C_E1` …), matching the TASK-0120 reachability log. Symbol index = position of the id in the sorted spawn list.

## Remotes (sender / handler / receiver)
| Remote | Direction | Payload | Sender | Handler / receiver |
|---|---|---|---|---|
| GlyphCollect | client → server | `id: string` | `client/Glyphs/GlyphController.luau` | `server/Services/GlyphService.luau` |
| GlyphState | server → one client | `{ available: {string}, count: number }` | `server/Services/GlyphService.luau` | `client/Glyphs/GlyphController.luau` |

## Files expected to change
- `games/mathshow/src/shared/{GlyphConfig,GlyphRules,Net}.luau`, `games/mathshow/tests/GlyphRules.spec.luau`
- `games/mathshow/src/server/{Remotes,init.server}.luau`, `games/mathshow/src/server/Services/GlyphService.luau`
- `games/mathshow/src/client/init.client.luau`, `games/mathshow/src/client/Glyphs/GlyphController.luau`
- `docs/workflow/evidence/TASK-0121/glyph-play.txt`, this note, `tasks/items/TASK-0121.json`

## Acceptance criteria
- [ ] AC1 Spec passes headless (new cases); `scripts/check.sh` green.
- [ ] AC2 Studio steps 1–6 with console excerpts in `docs/workflow/evidence/TASK-0121/glyph-play.txt` (measured SHA, applies_to).
- [ ] AC3 No leaks: state and connections cleared on leave (table size shown).
- [ ] AC4 No yield before the throttle in the handler (file:line).
- [ ] AC5 record-exec done; PR open, CI green, not merged; Play/Rojo stopped, place unsaved.

## Tests
- **Automated:** `scripts/check.sh` (headless GlyphRules spec).
- **Studio playtest procedure:** one round, steps 1–6 of the approved prompt (join, collect common + rare, spoofing and burst, respawn, rejoin, console).

## Risks / notes
- Client-sent ids are untrusted: type → known id → range (server HRP position) → collected → rate, after a raw per-player throttle.

---
## Implementation record

## Audits

## Outcome
