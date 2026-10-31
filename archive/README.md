# Archived games

Paused games, kept buildable as source material. Don't change them unless a task says so. They are outside the required
gate (`scripts/check.sh`); check them on demand with `scripts/check.sh --archive`. Their vault notes stay in `03 Games/`.

| ID | Name | Paused | Last state | Build (from the repo root) |
|---|---|---|---|---|
| GAME-001 | Rg1 / Rival Realms | 2026-10-11 | M2 planning. Specs run in Studio only. | `rojo build archive/GAME-001-rg1/default.project.json -o Rg1.rbxl` |
| GAME-002 | Haunted Collector | 2026-10-25 (GAME-004 became active; no earlier pause is recorded) | M1 and M3 complete, M2 except device checks. 265 headless specs pass. TASK-0070 to 0086 archived unstarted. | `rojo build archive/GAME-002-haunted-collector/haunted.project.json -o HauntedCollector.rbxl` |
| GAME-003 | Hike or Die | 2026-10-25 | Gate 1 prototype; the camera was reported not working. Pure-rule specs pass. | `rojo build archive/GAME-003-hike-or-die/hike-or-die.project.json -o HikeOrDie.rbxl` |

## Known `--archive` failures
GAME-003 fails StyLua, Selene and strict types. It was never in `check.sh`, so these predate the archive and were left
as they are: archiving changed only paths.

## Path map for older notes
Vault notes, audits and code comments written before 2026-10-30 cite the old paths.

| Old path | Now |
|---|---|
| `src/`, `tests/luau/`, `default.project.json`, `maps/finale_arena.json` | `archive/GAME-001-rg1/` (same names inside) |
| `games/haunted/`, `haunted.project.json` | `archive/GAME-002-haunted-collector/` |
| `tests/test_hcm_codec.py` | `archive/GAME-002-haunted-collector/art/test_hcm_codec.py` |
| `games/hike-or-die/`, `hike-or-die.project.json` | `archive/GAME-003-hike-or-die/` |

A project file's `rojo serve` still needs the place it belongs to: never connect one to another game's place.
