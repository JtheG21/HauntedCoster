---
id: GAME-001
title: Rg1 Overview
type: overview
project: GAME-001
status: in_progress
created: 2026-10-10
updated: 2026-10-30
tags:
  - game/overview
---
# GAME-001: Rival Realms (working title; repo name Rg1)

**Archived (paused 2026-10-11).** GAME-004 MathShow is the active game ([[AGENTS]]). Code: `archive/GAME-001-rg1/`.

**Last phase:** M2 planning: [[GAME-001 Rg1/03 Roadmap|03 Roadmap]] proposed, 8 tasks proposed · **Code:** `archive/GAME-001-rg1/src/` (Rojo 7.7.0) · **Task status:** `tasks/queue.json`

## Documents
[[GAME-001 Rg1/01 Game Design|01 Game Design]] · [[GAME-001 Rg1/02 Technical Architecture|02 Technical Architecture]] · [[GAME-001 Rg1/03 Roadmap|03 Roadmap]]

## Tasks
| Task | Status | Audit |
|---|---|---|
| [[TASK-0001-Collectible-Pickup]] | done | [[AUD-20261010-TASK-0001-01]] (pass) |
| [[TASK-0002-Ability-Framework]] | done | [[AUD-20261010-TASK-0002-01]], [[AUD-20261010-TASK-0002-02]] (pass) |
| [[TASK-0003-Factions-And-Echo-Clone]] | done | [[AUD-20261010-TASK-0003-01]] (fail), [[AUD-20261010-TASK-0003-02]] (pass) |
| [[TASK-0004-Ki-Burst]] | done | [[AUD-20261010-TASK-0004-01]] (pass) |
| [[TASK-0005-Convergence-Gate]] | done | [[AUD-20261010-TASK-0005-01]] (fail), [[AUD-20261010-TASK-0005-02]] (pass) |
| [[TASK-0006-Match-Flow-And-Onboarding]] | done | [[AUD-20261010-TASK-0006-01]] (pass) |
| [[TASK-0007-Ring-Out-Finale]] | done | [[AUD-20261010-TASK-0007-01]] (fail), [[AUD-20261010-TASK-0007-02]] (pass) |
| [[TASK-0008-Prototype-Telemetry]] | archived (executed, audit failed; preserved as [[AUD-20261010-TASK-0008-01]]) | [[AUD-20261010-TASK-0008-01]] (fail) |
| [[TASK-0009-Multi-Client-Test-Harness]] | done | [[AUD-20261010-TASK-0009-01]] (pass) |
| [[TASK-0010-Ability-And-Harness-Hardening]] | archived (not started; GAME-001 paused) | — |

## Research (M1)
- [[RSH-20261010-Candidate-Comparison]]: decided (A)
- [[RSH-20261010-Anime-IP-And-Demand]]

## Decisions
- [[ADR-0002-Game-Direction]]: approved
- [[ADR-0003-Original-Factions-IP-Policy]]: approved

## Design & validation
- [[GAME-001 Rg1/01 Game Design|01 Game Design]] v0.1: approved
- [[EXP-0001-M2-Validation-Experiments]]: **proposed**
- Baseline: [[RSH-20261010-Roblox-Platform-Economics]]

## Engineering
- [[Multi-Client Testing]]: automated 2–8 client tests

## Systems
- [[SYS-Collectible-Service]]

## Playtests
- [[TEST-20261010-01]]: TASK-0001, single player, Studio MCP (pass)
- [[TEST-20261010-02]]: TASK-0001, two players, **pass** (automated through StudioTestService)
- [[TEST-20261010-03]]: TASK-0002 ability framework, single player, pass
- [[TEST-20261010-04]]: TASK-0002 N1 (Dash force cap, seated rejection), pass
- [[TEST-20261010-05]]: TASK-0003 factions and Echo Clone, pass
- [[TEST-20261010-06]]: TASK-0004 Ki Burst, pass
- [[TEST-20261010-07]]: TASK-0003 revision 1 (rebalance, doors), pass after fix
- [[TEST-20261010-08]]: TASK-0005 Convergence Gate (2 clients + real abilities), pass
- [[TEST-20261010-09]]: TASK-0005 revision 1 (exploit regression), pass
- [[TEST-20261010-10]]: TASK-0006 match flow and onboarding (solo loops + join/leave), pass
- [[TEST-20261010-11]]: TASK-0007 ring-out finale (solo + 2 clients, all runs listed), pass

## Retrospectives
- [[RETRO-M0-Workflow-Foundation]]

## Open items
- Hardening follow-ups from the audits (TASK-0003/0004/0005/0006 minors) go into [[TASK-0010-Ability-And-Harness-Hardening]] (proposed).
