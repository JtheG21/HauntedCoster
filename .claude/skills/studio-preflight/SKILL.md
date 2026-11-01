---
name: studio-preflight
description: Check game-specific Roblox Studio, Rojo checkout and synced sources before any Play test or scenario. Supports GAME-001, GAME-002 (default), and GAME-003. Read-only and fail-closed; a build stamp is insufficient.
---
# Studio preflight

Follow `scripts/studio-preflight.md` in the checkout under test. It documents
explicit game/project/place selection, the read-only source query and the fresh
MCP snapshot comparison required before READY. Keep the manual identity/state
checks: launch metadata alone is insufficient after Studio opens another file.

1. Identify the intended local Studio instance with MCP list/state and `game.Name`
   in Edit; confirm ownership. Never operate another assistant's place.
2. Generate the query with `scripts/studio-preflight.sh --root <checkout> --game
   <GAME-ID> --print-probe`. Execute it read-only in that instance and save the
   returned JSON to a temporary snapshot. No Play/start/stop/sync in this step.
3. Run the documented command with `--place` and `--snapshot`. Fix every FAIL.
   Record the exact checkout/project/place, Edit state, full Source comparison
   and warnings. Never treat a matching stamp or offline fixture as sync proof.
4. Only when authorized, run scenarios in a fresh Play session (LES-0005).

GAME-002 remains the default; an invocation with only `--root` reports missing
evidence and fails. The script no longer writes the build stamp (LES-0009).
