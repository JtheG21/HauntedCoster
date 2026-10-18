---
id: TASK-0053
title: "Sequence Runner"
type: task
project: GAME-002
status: proposed
priority: low
risk: medium
owner: executor
depends_on: []
branch: task/TASK-0053-Sequence-Runner
related:
  - "[[ADR-0012-Sequence-Runner]]"
  - "[[RSH-20261017-Sequence-Runner-Proposal]]"
  - "[[REF-VFX-001-Cinematic-Energy-Sequence]]"
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/task
---

# Sequence Runner

## Goal
Pure sequence core, client player and one demo sequence per [[ADR-0012-Sequence-Runner]]. No gameplay change.

## Scope
- **In:** `shared/Sequence.luau` (validate, order, cleanup plan), `client/SequencePlayer.luau`, `tests/Sequence.spec.luau`, one demo sequence, a Play scenario in `tests/scenarios/`.
- **Out (non-goals):** real ability sequences, sound sourcing, art, server logic, live changes.
- **Keep unchanged:** server files, `Net.luau` contracts, existing scenarios.

## Intake
- **Category → workflow, depth:** VFX / systems → [[VFX Workflow]], standard
- **References:** REF-VFX-001 (quality floor; flash gate and one-prompt ledger), REF-CODE-001 (methods only, AGPL: no code copied), `vfx_template` as baseline
- **Reuse:** [[Resource Catalog]] checked for sequence or cutscene tooling: none implemented; adapt `vfx_template` cleanup ideas
- **Decisions:** ADR direction approved by jg 2026-10-17; GAME-002 chosen 2026-10-17; owner, ID and Studio window delegated to Claude by jg 2026-10-17 (Studio place1 window open)

## Files expected to change
- `games/haunted/src/shared/Sequence.luau`, `games/haunted/src/client/SequencePlayer.luau`, `games/haunted/tests/Sequence.spec.luau`, `games/haunted/tests/scenarios/SequenceRunner.luau`, a demo sequence data file

## Acceptance criteria
- [ ] AC1 Lune spec: cues sort by time; invalid tables rejected with a named reason; cancel at any time yields a complete cleanup plan; same input gives same plan.
- [ ] AC2 Play scenario (fresh Play session): after the demo finishes or is cancelled, instance and connection counts equal the pre-run baseline and peak particles stay within the stated budget.
- [ ] AC3 `evidence.py series --max-transitions 6` passes on a screen take of the demo.
- [ ] AC4 `scripts/check.sh` green; one audit; no server file changed.

## Tests
- **Automated:** `scripts/check.sh` plus the Lune spec.
- **Studio playtest procedure:** `studio-preflight`, fresh Play session (Server data model), run the scenario, capture the demo with a screen take.

## Risks / notes
New client module only. Needs a free Studio session (one assistant at a time).

---
## Implementation record

## Audits

## Outcome
