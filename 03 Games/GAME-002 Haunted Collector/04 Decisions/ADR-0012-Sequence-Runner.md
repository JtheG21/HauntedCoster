---
id: ADR-0012
title: Sequence Runner
type: adr
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-17
related:
  - "[[RSH-20261017-Sequence-Runner-Proposal]]"
  - "[[REF-VFX-001-Cinematic-Energy-Sequence]]"
  - "[[ADR-0008-Headless-Specs-With-Lune]]"
  - "[[ADR-0009-Shared-Production-Foundation]]"
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/decision
  - game/vfx
---
# Sequence Runner

## Context
jg chose "build it first" for a data-driven sequence runner in the REF-VFX-001 review. The two 2026-10-14 video notes show per-ability scripts with no shared cleanup, silent marker-name mismatches and no shown server validation.

## Options considered
1. Per-ability ad hoc scripts: no shared cleanup; rejected.
2. Third-party animation or cutscene package: rights and the ADR-0009 shared-foundation rule; rejected.
3. Animation event markers as the only timing source: silent name mismatches; allowed only as an optional cue source validated against the data table.
4. A data table of timed cues, a pure validating core and a thin client player (chosen).

## Decision
A sequence is a plain data table of ordered cues (`at` seconds, `kind` camera | effect | sound | callback, parameters, cleanup flag). A pure module in `games/haunted/src/shared/` validates and orders cues and plans cleanup, tested in Lune. A client player in `games/haunted/src/client/` runs cues from one clock and always runs cleanup, including on cancel. The runner is cosmetic only: gameplay stays on the server, and a server broadcast to start a sequence goes through `Net.luau` with the usual validation and rate limit.

Approved by jg in chat, 2026-10-17 ("if thats what you think is best then yes").

## Consequences
- One shared cleanup and flash-risk story for every future ability, boss or capture moment.
- New client module and spec; no server or data changes in the first task.
- Experiments on GAME-002 (jg, 2026-10-17); the first ability sequence is chosen in the follow-on experiment.
