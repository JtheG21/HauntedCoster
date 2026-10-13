---
id: AGENT-WF-Game-Production
title: Game Production Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[Workflow]]"
  - "[[Obsidian Conventions]]"
---
# Complete game production

A high-level idea is not a build order. Each stage ends at a gate. Stages marked **human** need jg's approval before the next one starts. Once a stage is approved, its tasks run autonomously under [[Workflow]].

| Stage | Output | Exit gate |
|---|---|---|
| 0. Concept | An `01 Inbox/` note, plus `RSH-` research if the market or feasibility is uncertain | **Human:** pursue or drop |
| 1. Requirements and scope | `01 Game Design` with the core loop, the vertical slice, non-goals and the high-risk unknowns | **Human:** the design is approved |
| 2. Architecture | `02 Technical Architecture` (services, remotes and trust boundary, data model, performance budget), plus an ADR per major choice | **Human:** ADRs accepted |
| 3. Reusable systems | A [[Resource Catalog]] and [[Reference_Code_Index]] check, with reuse, adapt or build recorded per system | Recorded in the Technical Architecture |
| 4. World and assets plan | Area list, landmarks, an asset list with the build method per item ([[Map Workflow]], [[Asset Workflow]]), audio and UI needs | Part of the roadmap |
| 5. Sequencing | `03 Roadmap` milestones, and TASKs (risky unknowns first, then the vertical slice) | **Human:** plans approved |
| 6. Integration and testing | Merged tasks, TEST notes, a full-loop scenario, multi-player playtests | Milestone `RETRO-` |
| 7. Performance | Profiling against the budget at the target player count, then on devices | Numbers recorded |
| 8. Release readiness | A `REL-` note: checklist, known issues, approval | **Human:** release approval |

Kill the riskiest unknown first with the smallest prototype that answers it, and record the answer before building on it.

## Starting a new game
1. **Create the folder** `03 Games/GAME-00N Name/` with the per-game layout in [[Obsidian Conventions]]. The ID never changes.
2. **Set up the code.** The code root is `games/<slug>/` (`src/server|shared|client`, `tests/`), with its own `<slug>.project.json` and its own place file. Use one Rojo server per place ([[AGENTS]]).
3. **Fill the project profile** in `00 Overview` (below). This is the only place project-specific configuration lives. Shared notes link to it.
4. **Wire the game into the tooling:**
   - `scripts/check.sh` (StyLua, Selene and the Rojo build paths, and the Lune spec runner).
   - The `AGENTS.md` project map, and the [[Studio Index]] game table.

   Adding the game to these tools is a `chore/` change.
5. **Choose the shared resources to start from** ([[Resource Catalog]]). Copy patterns, not another game's balance or assets.

## Project profile (a section in each game's `00 Overview`)
- **Code root, Rojo project, place file**
- **Status and phase**
- **Player cap:** the target, and what Studio tests use
- **Art direction:** a pointer to the approved notes or references, and its status
- **Performance targets**
- **Validation:** the commands, and what needs Studio
- **Tools in use:** skills, MCPs, Blender or not
- **Game-specific conventions** that differ from the shared ones
