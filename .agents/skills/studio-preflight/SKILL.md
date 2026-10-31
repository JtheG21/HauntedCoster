---
name: studio-preflight
description: Check the Roblox Studio and Rojo environment before any Haunted Collector or MathShow Play test, scenario run or CrossPlot. Confirms one Rojo server for the game's project file (mathshow.project.json, or the archived haunted.project.json with `--game haunted`) serving the checkout under test, the Studio windows, free memory, and that Studio runs the latest code (build stamp). Use before starting Play or a scenario through Studio MCP, and whenever a Studio run fails for no clear reason, instead of retrying.
---
# Studio preflight

A cheap check so Studio runs don't fail for environment reasons (AGENTS.md "One Rojo server", TEST-20261011-02, LES-0005).

1. Run `scripts/studio-preflight.sh --root <checkout under test>` (default is the active game; add `--game haunted` for archived Haunted Collector). Fix every `FAIL` line before testing; a FAIL is never a reason to retry the test. Note the `STAMP` value.
2. With Studio MCP:
   - `list_roblox_studios`: every window reports its name as "Game", so run `execute_luau` in Edit with `return game.Name` in each to get its place file. The window you'll test in is the place for the game under test (Haunted Collector or MathShow), not the Rg1 place or another tool's place (e.g. AnimPipeline). Before a 2-player run it must be the only window.
   - `get_studio_state`: Edit mode. If a Play session is still stopping, wait; a run started now returns nil.
   - `execute_luau` in Edit: `return game.ReplicatedStorage.Shared.BuildStamp.Value` must equal the `STAMP`. If it doesn't, Rojo isn't syncing this checkout: reconnect the Rojo plugin, or sync by hand and record that in the TEST note.
3. Run specs in a fresh Play session, in the Server data model. Edit mode caches modules (LES-0005).
4. Report one line: the checkout, the Rojo server (project and port), the place, the mode, whether the stamp matches, and any warnings.
