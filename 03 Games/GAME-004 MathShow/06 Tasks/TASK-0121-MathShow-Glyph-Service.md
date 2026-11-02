---
id: TASK-0121
title: "MathShow Glyph Service"
type: task
project: GAME-004
status: approved
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
- [x] AC1 Spec passes headless (new cases); `scripts/check.sh` green. Evidence: 326 specs pass (9 new GlyphRules cases); check.sh ALL CHECKS PASSED.
- [x] AC2 Studio steps 1–6 with console excerpts. Evidence: `docs/workflow/evidence/TASK-0121/glyph-play.txt`, measured at 3cee8c4.
- [x] AC3 No leaks. Evidence: after a kick, the service's player count went 1 → 0 (glyph-play.txt "No leaks").
- [x] AC4 No yield before the throttle: `GlyphService.luau:122-135`, throttle at lines 128-129.
- [x] AC5 record-exec done (status review); PR #179 open as a draft, not merged; Play and Rojo stopped, place unsaved. CI: run 41526984535 passed on b60eda0.

## Tests
- **Automated:** `scripts/check.sh` (headless GlyphRules spec).
- **Studio playtest procedure:** one round, steps 1–6 of the approved prompt (join, collect common + rare, spoofing and burst, respawn, rejoin, console).

## Risks / notes
- Client-sent ids are untrusted: type → known id → range (server HRP position) → collected → rate, after a raw per-player throttle.
- **Accepted finding (a), jg 2026-11-02:** glyphs that stream out stay rendered from their cached positions. By design (positions are learnt once and kept); revisit past about 150 spawns.
- **Accepted finding (b), jg 2026-11-02:** the server's stats counters increment outside Studio too, but only Studio publishes them as attributes.

---
## Implementation record
- **Shared:** GlyphConfig gains RateWindowSeconds, RawRequestLimit, Symbols. GlyphRules gains `parseSpawns` (unknown rarity against `GlyphConfig.Rarity`, duplicate id with the first kept, non-finite coordinates, empty id: dropped, one warning each) and `bad_time` for a non-finite `now` (checked first). The window uses RateWindowSeconds. Spec: 9 new cases.
- **Server:** `GlyphService` reads the tags under `Workspace.Hub`, sorted by id, and passes them through `parseSpawns`. Per-player state lives in memory and is cleared on PlayerRemoving. Handler order: raw throttle (RateRules) → HumanoidRootPart → validateCollect (`os.clock()`) → applyCollect → GlyphState. Rejections are silent; the server warns once per reason per player per 5 s. One respawn loop sends GlyphState only on change. **Addition:** in Studio only, it publishes counters as attributes on its ModuleScript (Players, Spawns, RawAccepted, RawThrottled, Collected), so Play-mode checks can read them.
- **Client:** `GlyphController`. The place has StreamingEnabled, so spawns are learnt from the GlyphSpawn added signal and kept, not read once (fix in 3cee8c4, found before the first Play run). The symbol index is the id's position in the first GlyphState. One RenderStepped connection runs spin, bob and the reach check. HUD counter "Glyphs N". Pickup burst plus the built-in `rbxasset://sounds/electronicpingshort.wav`, pcall-isolated. Layout constants are in a frozen local `GlyphTheme` table.
- **Studio round (one):** steps 1–6 pass, see the evidence file. Burst of 20: 10 accepted, 10 throttled. Common respawn measured at 90.26 s.

- **Revision 1 (rows H1-H5, jg 2026-11-02):** the counter hides while the menu is open. `GlyphController` watches the `MathShowMenu` ScreenGui's `Enabled` (the menu's existing state, no menu change, no remote) and sets the counter ScreenGui `DisplayOrder = 4` (below the menu's 10). Studio at 4362e83: open → hidden, closed → visible, collect → "Glyphs 1" (evidence file, "Revision 1"). Deviations recorded there: viewport 1336x669 not 844x390, and the script was synced through `execute_luau` (verified length and checksum), not Rojo.
- **Revision 2 (rows R1-R4, jg 2026-11-02; audit AUD-20261102-TASK-0121-01 P2, GlyphController:232):** a rejected request no longer ends the glyph's chances. `GlyphConfig.RetryAfterSeconds = 1.0`, pure `GlyphRules.shouldRequest(lastRequestAt, now, inRange, available)` (true only if available and in range and never asked or at least RetryAfterSeconds ago; non-finite `now` is false), and the controller keeps `lastRequestAt` per rendered glyph (os.clock, local cadence only), which resets when the id leaves and returns. Spec: 3 new cases (329 pass). Studio at b7d61be: first request throttled, retry 1.01 s later collected; a rejected in-range glyph sent 1 request per about 1.0 s. Same deviation as revision 1: script sync through `execute_luau`, verified by length and checksum (accepted by jg).

## Audits

## Outcome
Implemented and verified in one Studio round at 3cee8c4, then revised once (counter hidden under the menu, rechecked at 4362e83). The task goes back to review for the Codex audit. PR #179 is a draft and not merged. No persistence: glyph state resets on rejoin, as scoped.
