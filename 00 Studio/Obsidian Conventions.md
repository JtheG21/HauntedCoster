---
id: STUDIO-CONVENTIONS
title: Obsidian Conventions
type: index
status: approved
created: 2026-10-10
updated: 2026-10-13
tags:
  - studio/conventions
---
# Obsidian conventions

This is the canonical spec for how project knowledge is stored. `scripts/validate_vault.py` enforces it, and both Claude and Codex follow it through [[AGENTS]].

## 1. Vault layout
The vault is the `Rg1` repo folder (approved, see [[ADR-0001-Repo-Is-Vault]]). GAME-002 code stays in `games/haunted/`; paused GAME-001 code stays in `src/`. Machine files stay in `tasks/`, `project-state.json` and `scripts/`.

| Folder | Holds |
|---|---|
| `00 Studio/` | Studio-wide config ([[Studio Index]], this file, `budget.json`, `Notes.base`) |
| `01 Inbox/` | Raw ideas, links, screenshots, requests. Kept until you approve what happens to them |
| `02 Research/` | `RSH-` notes: evidence and hypotheses |
| `03 Games/GAME-### Name/` | One folder per game (layout below) |
| `04 Agents/` | Role specs and the [[Workflow]]. **The only copy.** The repo's `AGENTS.md` links here |
| `05 Engineering/` | Reusable architecture patterns, Luau standards |
| `06 QA/` | `AUD-` audits, `BUG-` bugs. Only appended, never rewritten |
| `07 Metrics/` | Playtest metrics, retention, monetization experiments (`EXP-`) |
| `08 Reviews/` | `REV-` weekly reviews, `HLT-` generated health reports |
| `09 Knowledge/` | `LES-` lessons, only when backed by evidence |
| `99 Templates/` | `T - *.md` note templates |

Leave these alone: `Agents/` and `Chats/` (Smart Second Brain plugin), `.obsidian/`.

Per-game layout:
```
03 Games/GAME-001 Rg1/
  00 Overview.md  01 Game Design.md  02 Technical Architecture.md  03 Roadmap.md
  04 Decisions/ (ADR-)  05 Systems/ (SYS-)  06 Tasks/ (TASK-)  07 Playtests/ (TEST-)
  08 Releases/ (REL-)  09 Retrospectives/ (RETRO-)
```
`GAME-001` never changes, even if the game is renamed.

## 2. Filenames
| Type | Pattern | Example |
|---|---|---|
| Research | `RSH-YYYYMMDD-Short-Topic.md` | `RSH-20261010-Simulator-Progression.md` |
| Task | `TASK-####-Short-Title.md` | `TASK-0001-Collectible-Pickup.md` |
| Bug | `BUG-####-Short-Title.md` | `BUG-0007-Duplicate-Rewards.md` |
| Audit | `AUD-YYYYMMDD-TASK-####-NN.md` | `AUD-20261010-TASK-0001-01.md` |
| Decision | `ADR-####-Short-Title.md` | `ADR-0001-Repo-Is-Vault.md` |
| System | `SYS-Short-Title.md` | `SYS-Collectible-Service.md` |
| Playtest | `TEST-YYYYMMDD-NN.md` | `TEST-20261010-01.md` |
| Release | `REL-Version.md` | `REL-0.1.0.md` |
| Weekly review | `REV-YYYY-Www.md` | `REV-2026-W41.md` |
| Lesson | `LES-####-Short-Title.md` | `LES-0001-Rojo-Version-Mismatch.md` |
| Retrospective | `RETRO-Short-Title.md` | `RETRO-M0-Workflow-Foundation.md` |
| Experiment | `EXP-####-Short-Title.md` | `EXP-0001-Starter-Pack.md` |
| Health report (generated) | `HLT-YYYYMMDD.md` | `HLT-20261010.md` |
| Reference (in `10 References/<area>/`) | `REF-AREA-NNN-Short-Title.md` | `REF-MAP-001-Graveyard-Gate.md` |

The last four rows (retrospectives, experiments, health reports, references) are local additions to the original spec. Reference notes use `type: reference` and [[T - Reference]]; `10 References/` is outside the validator's frontmatter checks, and the existing `referenceN` notes keep their names ([[ADR-0009-Shared-Production-Foundation]]).

Rules:
- An ID never changes once assigned. Generated names use hyphens, not spaces. Status never goes in a filename.
- Dates are ISO: `YYYY-MM-DD` in content, `YYYYMMDD` in filenames.
- Before creating a note, search for its ID. Update the existing note; never make a second one.
- Link with `[[TASK-0001-Collectible-Pickup]]`, not with file paths. Fixed-name game files (`00 Overview` and so on) are fine while only one game exists. Once there are more, link them with a path: `[[GAME-002 Name/00 Overview]]`.

## 3. Frontmatter
Every note except templates has these fields: `id`, `title`, `type`, `status`, `created`, `updated`. Add `project` for game notes, plus type-specific fields such as `task_id`, `priority`, `owner`, `related` and `tags`.

`type` values: `index, overview, design, architecture, roadmap, task, bug, audit, adr, system, playtest, release, review, health, lesson, retro, research, experiment, inbox, agent`.

### Controlled statuses (no alternative spellings)
`inbox · research · proposed · ready · in_progress · paused · blocked · in_review · changes_requested · approved · done · archived`

For **tasks**, `tasks/queue.json` is authoritative and the note mirrors it (the orchestrator updates both):

| Status | Task meaning |
|---|---|
| `proposed` | Planner wrote it, waiting for human plan approval |
| `ready` | Plan approved, can start once dependencies are `done` |
| `in_progress` | Executor working on its branch |
| `paused` | Work suspended at jg's request; resume rechecks dependencies and budget without consuming a revision |
| `in_review` | Auditor reviewing |
| `changes_requested` | A check or audit failed (counts toward the 2-revision limit) |
| `approved` | Audit passed, **waiting for human merge approval** |
| `done` | Merged |
| `blocked` | Retry limit hit or a human decision needed |
| `archived` | Cancelled or superseded |

Optional task queue fields `owner` and `reviewer` identify `claude` or `codex` and are mirrored to the note when present. They must differ when both are set. The queue remains authoritative for explicit assignments; notes on older tasks may retain role labels such as `owner: executor` when the queue has no assignment. Use `orchestrator.py assign`, `pause` and `resume` as documented in [[Workflow]].

For an **ADR**, `approved` means accepted by a human. For an **audit**, `done` means the report is final, and the verdict goes in the `verdict` field.

## 4. Where each kind of information is authoritative
| Information | Authority |
|---|---|
| Game code | Git (`games/haunted/` for GAME-002; `src/` for GAME-001) |
| Task status | `tasks/queue.json` (mirrored to the task note). If they disagree, the validator flags it; nobody guesses |
| Approved game design | `01 Game Design.md` plus approved ADRs |
| Research, lessons | Obsidian notes |
| Audit evidence | `06 QA/AUD-*` (versioned in Git) |
| Credentials | `.env` / the OS keychain. **Never in notes** |
| Release approval | A `REL-` note recording the human approval |

## 5. Template syntax
`99 Templates/` uses Obsidian's **core Templates** plugin syntax: `{{title}}`, `{{date:YYYY-MM-DD}}`. No Templater or other community template plugin is installed. When Claude generates a note itself, it writes the resolved values directly.

## 6. Checks
`python3 scripts/validate_vault.py` checks filenames, required frontmatter, valid statuses and types, duplicate IDs, broken `[[links]]`, and whether task status matches the queue. It runs as part of `scripts/check.sh`.
