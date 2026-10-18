---
id: RSH-20261017-Sequence-Runner-Proposal
title: "Sequence runner: proposed TASK and ADR (draft for jg)"
type: research
project: GAME-002
status: research
sources:
  - "[[REF-VFX-001-Cinematic-Energy-Sequence]]"
  - "[[RSH-20261014-Claude-MCP-Skill-Cutscene-Video]]"
  - "[[RSH-20261014-Animation-Event-Ability-System-Video]]"
  - "[[RSH-20261017-Reference-Automation-Spec]]"
confidence: low-medium
created: 2026-10-17
updated: 2026-10-17
tags:
  - research/vfx
  - research/systems
---
# Sequence runner: proposed TASK and ADR

> **Update 2026-10-17:** jg approved the ADR direction, chose GAME-002 and delegated the task ID, owner and Studio window. Recorded as [[ADR-0012-Sequence-Runner]] (approved) and [[TASK-0053-Sequence-Runner]] (proposed; plan approval still pending). The text below is the original proposal.

## Why
jg chose "build it first" for VF-5 in the REF-VFX-001 review: a data-driven runner for timed sequences (camera keys, effect cues, cleanup), so the experiment on a 10-15 s ability sequence has something to run on. The two 2026-10-14 video notes (read 2026-10-17) show the pattern is common but give no code, no server validation and no cleanup story: markers drive cosmetics, the server hitbox check is not shown, and marker-name mismatches fail silently. Those three gaps are what the runner must cover.

## Proposed ADR (approval needed): sequence data and ownership
- **Decision proposed:** a sequence is a plain data table (ordered cues: `at` seconds, `kind` camera | effect | sound | callback, parameters, `cleanup` flag). A pure module in `games/haunted/src/shared/` orders cues, validates them (unknown kind, negative or non-monotonic time, missing cleanup, duplicate ids, unknown marker name) and plans cleanup. A thin client player in `games/haunted/src/client/` executes cues with `task.delay` from a single clock and always runs cleanup, including when cancelled.
- **Authority:** the runner is cosmetic only. Gameplay effects stay server-side; a client cue never grants or validates anything (AGENTS "server is authoritative"). The server may broadcast "start sequence X" through `Net.luau` with the usual validation and rate limit.
- **Options rejected:** per-ability ad hoc scripts (what the videos show; no shared cleanup); a third-party animation or cutscene package (rights and the ADR-0009 shared-foundation rule); animation event markers as the only timing source (silent name mismatches; kept as an optional cue source, validated against the data table).
- **Why it is shared:** needs ADR-0009 treatment (reused by any future ability, boss or capture moment). jg approves; status stays `proposed` until then.

## Proposed TASK
- **Goal:** pure sequence core plus client player plus one demo sequence, no gameplay change.
- **Category / depth:** VFX and systems, Standard. References: REF-VFX-001 (floor, ledger X7), REF-CODE-001 (methods only, AGPL, no code copied), `vfx_template` as baseline.
- **In:** `shared/Sequence.luau` (validate, order, cleanup plan), `client/SequencePlayer.luau`, `tests/Sequence.spec.luau` (Lune), one demo sequence data file, a Play scenario in `tests/scenarios/` that asserts descendant and connection counts return to baseline and peak particles stay under budget.
- **Out:** real ability sequences, sound sourcing, art, anything that changes server logic or live experience.
- **Acceptance criteria:**
  1. Lune spec: cues sort by time; invalid tables are rejected with a named reason; cancelling at any time still yields a complete cleanup plan; same input gives same plan.
  2. Play scenario (fresh Play session, LES-0005): after the demo finishes or is cancelled, instance and connection counts equal the pre-run baseline; peak particle count within the stated budget.
  3. `evidence.py series --max-transitions 6` passes on a screen take of the demo (flash-risk gate from the VFX-001 review).
  4. `scripts/check.sh` green; one audit; no server file changed.
- **Studio:** needs a free Studio session for AC2 and the screen take (recording is jg's action).
- **Risk:** low to medium (new client module, no server or data changes). Owner: jg assigns; Claude by default for design, Codex for the Lune spec if preferred.
- **Not decided here:** the 10-15 s ability the experiment will use and which clip beats must carry over (open decisions in the VFX-001 review).

## Needs jg
1. Approve the ADR direction (data table, pure core, cosmetic-only client player) or change it.
2. Assign the TASK ID, owner, and a free Studio window.
3. Pick the game for the follow-on experiment (still open).
