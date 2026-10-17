---
id: AGENT-Task-Intake
title: Task Intake
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-17
tags:
  - workflow/process
related:
  - "[[ADR-0009-Shared-Production-Foundation]]"
  - "[[Workflow]]"
  - "[[Resource Catalog]]"
---
# Task intake: how any Roblox task starts

The entry point for every task, in any game. [[AGENTS]] holds the rules, [[Workflow]] the task states and gates, and this note the start procedure and routing. Detailed procedures live in the category workflows; open only the ones the task needs.

## Three scopes: put each fact in one place
| Scope | Lives in | Never contains |
|---|---|---|
| **Shared** (every game) | `AGENTS.md`, `04 Agents/` (this note, [[Workflow]], `Workflows/`), [[Resource Catalog]], `05 Engineering/` standards, `99 Templates/`, `09 Knowledge/` | One game's balance, assets, map or art direction |
| **Project** (one game) | `03 Games/GAME-### Name/`: the `00 Overview` (project profile, see [[Game Production Workflow]]), Game Design, Technical Architecture, ADRs, SYS notes; plus the game's code root and Rojo project | Rules that apply to every game (link the shared note instead) |
| **Task** | The TASK note and its `tasks/queue.json` entry, an optional handoff ([[T - Handoff]]), TEST and AUD notes | Copies of shared or project docs (link them) |

## Start procedure
1. **Project and task.** `python3 scripts/orchestrator.py status`, the game's `00 Overview`, `git status` and the branch. Run `scripts/preflight.sh` before any state-changing Git operation.
2. **Instructions.** `AGENTS.md`, then only the project notes the task touches. Don't reread what is already in context.
3. **Decisions already made.** The queue entry, the TASK note, ADRs, the Game Design, and memory. Never ask for something already documented.
4. **Classify** (table below) and open only the matching workflow(s).
5. **Reuse search.** Check the [[Resource Catalog]], the lessons in `09 Knowledge/` and the [[Video Research Index]] for the task's area, then the [[Reference_Code_Index]], then `10 References/<area>/` (`python3 scripts/refs.py brief --task TASK-####` or `--category <name>` prints the matching notes' Intent and open questions; `orchestrator.py start` prints it too), then the existing code (grep). Write reuse, adapt or replace, and why, in the task note.
6. **Inspect the real implementation** before changing it: the files, not their summaries.
7. **Plan** to the depth tier below. For Standard and Deep tasks with matching notes in `10 References/`, the `reference-brief` skill builds the interview, evidence plan and Intake block first.
8. **Execute** in small, reviewable stages on the task branch.
9. **Validate**, cheapest check first ([[Workflow]] "Check order").
10. **Record and report.** Fill the task note's Implementation record and Outcome; add a catalog row if something reusable came out of it; write a LES only with evidence. Report using the states below.

## Classification
A task may combine categories. The primary one governs the plan; the others add checklist items. Analyse references first: their output feeds every other workflow.

| Category | Signals | Workflow | First tools to check |
|---|---|---|---|
| Image or video reference | screenshot, photo, sketch, map, clip | [[Reference Analysis Workflow]] | Read (images); `watch` skill (video) |
| Environment and map | area, layout, terrain, landmarks, paths | [[Map Workflow]] | `roblox-map` skill, Studio MCP |
| 3D asset or prop | model, mesh, modular kit | [[Asset Workflow]] | Studio parts; Blender when it earns its place |
| VFX and animation | particles, beams, tweens, animations | [[VFX Workflow]] | vfx_template ([[vfx_template]]) |
| UI and graphics | HUD, menu, icon, layout | [[UI Workflow]] | The project's UI kit (GAME-002: `Theme.luau`) |
| Audio | SFX, ambience, music | [[Audio Workflow]] | `roblox-sfx` skill |
| Systems, mechanics, pipelines | services, remotes, data, tooling | [[Systems Workflow]] | [[Reference_Code_Index]] |
| Whole game | a new concept or game | [[Game Production Workflow]] | |

## Depth tiers
| Tier | Use when | Produce |
|---|---|---|
| **Light** | Small, clear spec, low risk, easily reversed | A short plan. Game code still needs a TASK ([[AGENTS]]); keep its note brief |
| **Standard** | A normal feature | The TASK note from [[T - Task]], a recorded reuse check, specs or a playtest |
| **Deep** | Shared state, DataStore, security, the core loop, a shared library, a new game, or anything costly to reverse | TASK plus an ADR for each decision, research if uncertain, a multi-player playtest, an Opus first audit |

Pick the lowest tier that covers the risk. Raise it when something surprises you.

## Autonomy: proceed or ask
**Proceed, and record the assumption in the task note,** when the goal is clear, the acceptance criteria are sufficient, the choice is reversible and low-risk, an existing standard or decision resolves it, and it stays inside approved scope.

**Ask** when a consequential design decision is unresolved, different readings would change the result materially, an action is destructive or irreversible, a permission or dependency is missing, or the acceptance criteria can't be met without more information. Batch every question into one message and recommend an option. The always-human gates are in [[Workflow]] ("Human gates") and `AGENTS.md`; this note does not repeat them.

Apply extra scrutiny to foundation architecture, core gameplay, shared libraries, persistence and networking.

## Labels for what you write
Put each claim under one label:
- **Fact:** verified; cite a file and line, a TEST note or a command.
- **Decision:** say who made it and when.
- **Observation:** seen in a reference.
- **Inference**, **Assumption** (reversible, unconfirmed), **Recommendation**, **Open question.**

Never turn an assumption into a decision silently.

## Reporting states
Use one of these for each item:
- **Implemented and tested** (cite the evidence)
- **Implemented, not tested**
- **Planned**
- **Blocked** (say by what)
- **Needs manual Studio or Blender check**

A Rojo build or headless specs are not runtime proof.

## Optimization check (silent)
Before significant work, ask yourself:
- Is it necessary?
- Is it already solved (the catalog)?
- What is the simplest maintainable version?
- Would a cheap probe come first?
- Would research change the decision?
- Is it reusable?
- Is it worth its maintenance?
- How will it be verified?

Write down only the answers that change something.

## Handoffs to another tool or session
When work leaves this session, fill [[T - Handoff]]. Link the sources rather than pasting them. A light task gets a short handoff; a mechanic or game gets states, stages and tests. The receiver reports blockers instead of guessing.

Receiving tools, as checked on 2026-10-12:

| Tool | Status | The handoff must carry |
|---|---|---|
| Claude Code, fresh session | Available; reads the repo | Repo-relative paths, the branch, the task ID |
| Roblox Studio via Studio MCP | Available in Claude Code sessions while Studio is open | The place, Edit or Play, and the Rojo state (one server, matched to its place) |
| Roblox Studio, by hand (jg) | Human | Numbered steps and the expected result for each |
| Blender | 5.1.0; headless FBX export works (`--background --python`); no MCP; import scale being verified (test cube `~/Roblox-Work/blender-scale-test/ScaleTest_1m.fbx`) | Units, dimensions, pivot, export settings |
| Claude Design or claude.ai chat | Not reachable from this repo; can't read local paths | The images attached, plus a written spec that stands alone |
| Figma MCP | Being authorized by jg (2026-10-12); trial for reusable UI designs | Figma file link; check access with `whoami` first |
