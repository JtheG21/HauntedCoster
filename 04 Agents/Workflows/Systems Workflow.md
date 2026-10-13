---
id: AGENT-WF-Systems
title: Systems Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[Reference_Code_Index]]"
  - "[[Luau Standards]]"
---
# Technical systems, mechanics and pipelines

## Gather
- **Where it plugs in:** the game's Technical Architecture, the relevant `SYS-` notes, and the existing services and remotes (grep the code, not the notes alone).
- **Reusable code:** the [[Resource Catalog]] and the [[Reference_Code_Index]] lookup table. Open the actual files.
- **Engine APIs you aren't sure of:** grep the local creator-docs clone ([[AGENTS]] project map) before using them.

## Decide (write these in the TASK note)
- **State and data flow:** who owns each piece of state, where it is stored, how it replicates (attributes, values, remotes), and when it is cleaned up.
- **Server and client:** the server decides outcomes. The client sends intent and renders.
- **Trust boundary:** for every remote, check:
  - argument types
  - value ranges, including NaN and infinity
  - distance and ownership
  - a per-player rate limit

  Follow the existing remote wrapper (GAME-002: `Net.luau`; reference: vfx_template `CombatServer`).
- **Structure:** pure rules (no instances, testable headlessly) are separate from the services that mutate state ([[ADR-0008-Headless-Specs-With-Lune]]). Tuning lives in config tables.
- **Errors and edge cases:**
  - Wrap DataStore and HTTP calls in `pcall` with bounded retries.
  - Cosmetic client code fails silent.
  - List the edge cases and handle each:
    - join or leave mid-action
    - respawn
    - duplicate or out-of-order requests
    - 0, 1 or the maximum number of players
    - a server shutdown
- **Rollback and compatibility:**
  - DataStore schema changes are a human gate. Version the saved data, and give old data a migration path.
  - Prefer additive changes, so the change can be turned off or reverted.

## Build and test
1. Write the pure rules and their Lune specs first (`games/<game>/tests/*.spec.luau`, run by `scripts/check.sh`). Assert properties, not exact seeded values.
2. Add the service wiring, then a Studio Play scenario (`tests/scenarios/`) for the behaviour that needs a running server.
3. When shared state is touched, run a multi-player session before asking for merge approval. The current cap is 2 players in Studio ([[Multi-Client Testing]]).
4. For tooling and pipelines (Python or shell), add a unit test under `tests/`, which `check.sh` already runs.

## Performance and maintainability
- Avoid per-frame work on the server unless needed. Measure heartbeat and remote bandwidth with `Stats` when a system runs often.
- Prefer one obvious module per concern, and follow [[Luau Standards]].

## Acceptance
- `scripts/check.sh` passes.
- Specs cover the rules, and a scenario or playtest covers the runtime behaviour. Each acceptance criterion links its evidence.
- The trust boundary is reviewed. The first audit of security, networking or DataStore code uses Opus ([[AGENTS]]).
- The SYS note and the Technical Architecture are updated after the merge.
