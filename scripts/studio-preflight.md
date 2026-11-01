# Read-only Studio preflight

`studio-preflight.sh --root <checkout>` retains the GAME-002 default. It now
fails closed without place/source evidence; it never writes a stamp. Select
`--game GAME-001|GAME-002|GAME-003` and optionally its exact `--project` filename.

| Game | Project | Local place filename |
|---|---|---|
| GAME-001 | default.project.json | Rg1.rbxl(x) |
| GAME-002 | haunted.project.json | HauntedCollector.rbxl(x) |
| GAME-003 | hike-or-die.project.json | HikeOrDieGate1.rbxl(x) |

The names are explicit local safety conventions, not published place IDs. A
renamed/unknown/cloud place requires independent manual identification and a
reviewed mapping update; it cannot earn READY by supplying an arbitrary name.

1. Identify the dedicated local Studio instance with Studio MCP list/state and
   read `game.Name` in Edit. Coordinate ownership first. No Play/start/stop/sync
   is part of this tool. Require one Studio window and one Rojo server.
2. Print a fresh query from the intended checkout:
   `scripts/studio-preflight.sh --root <checkout> --game GAME-003 --print-probe`.
   This only prints read-only Luau and does **not** indicate readiness.
3. Execute that query in the identified Studio instance in Edit. Save only the
   returned JSON object to a temporary file, e.g. `/tmp/hod-source-snapshot.json`.
   Do not fabricate the snapshot from disk. Recollect it after any source/sync
   change, and rerun preflight immediately before testing. Keep it out of Git.
4. Run `scripts/studio-preflight.sh --root <checkout> --game GAME-003
   --project hike-or-die.project.json --place /absolute/path/HikeOrDieGate1.rbxl
   --snapshot /tmp/hod-source-snapshot.json` as one command.
5. Resolve every FAIL before testing. Check memory before multi-client/capture
   work (under 20% free is a warning). Record checkout, project, exact place,
   mode, source comparison and warnings in the test note.

The script checks the checkout top level, exact Rojo cwd and project path, one
identifiable local Studio launch path, Edit state/DataModel name, and every
Rojo-resolved Script/LocalScript/ModuleScript's Source (including new and generated
modules). Full text is compared, normalizing disk CRLF to Studio LF; length and
stamp alone cannot conceal partial sync (LES-0009). No modules are required and
no instances are created by the query. A saved snapshot is human/MCP evidence,
not an authenticated ongoing connection: offline fixtures prove rejection logic
only. Unknown process/cwd/launch metadata fails closed even if sources match.
Manual identification remains necessary because launch arguments can be stale
after opening another place within the same Studio process. Never infer identity
from the generic MCP window label alone. READY is a fresh-snapshot environment
check, not runtime/gameplay or physical-device proof.

HOD checks: install `scripts/requirements-hod.txt` into a Python 3.12+ environment,
then run `HOD_PYTHON=/absolute/venv/bin/python scripts/check.sh`. The override is
optional when `python3` already has the pinned dependencies. CI installs those
pins and runs the same suite with mandatory type definitions. Missing map tools
fail. HOD generated Luau is regenerated in a temporary file, formatted with the
pinned StyLua, and byte-compared; its `--!nocheck` is not strict coverage.
