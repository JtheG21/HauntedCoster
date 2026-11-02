---
id: TASK-0119
title: MathShow Glyph Rules
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: codex
depends_on: []
branch: task/TASK-0119-glyph-rules
related: []
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---
# MathShow Glyph Rules

## Goal and approved scope
jg approved rows R1/R2: standard task, isolated branch from main, frozen GlyphConfig, pure typed GlyphRules and typed TestRunner specs. No Instances, remotes, services, client code, persistence, map, project file or merge. jg separately approved only this task note and its audit record as exceptions to the no-vault constraint.

## Intake
- Systems Workflow, standard (explicit user tier). Resource Catalog and Code Reference Index checked; no matching glyph source. Reuse MathShow ScoringRules configuration/require shape and RoundRules.spec typed TestRunner pattern. No external material or dependencies imported.
- Assumptions: trusted unique spawn array `{id, position={x,y,z}, rarity}`; caller supplies finite positions and monotonic finite time. Player state owns glyph status, sessionCount (weighted rarity total), and collectTimes. Rolling window is `(now-1, now]`; applyCollect follows successful validation synchronously. tickRespawns explicitly releases expired glyphs at `now >= respawnAt`.
- Plan: implement pure rules/specs; run headless and check.sh; independent standard audit; open PR and verify CI. Runtime wiring is a later task; no Studio test needed for plain-value functions.

## Files expected to change
- games/mathshow/src/shared/GlyphConfig.luau
- games/mathshow/src/shared/GlyphRules.luau
- games/mathshow/tests/GlyphRules.spec.luau
- tasks/items/TASK-0119.json
- This task note and its independent audit record.

## Acceptance criteria
- [x] Headless specs pass: 317 total, 13 glyph tests, 0 failures.
- [ ] scripts/check.sh exits 0.
- [ ] Independent audit passes.
- [ ] PR open with green CI; not merged.

## Implementation record
Frozen nested tunables; exported Position, Rarity, Spawn, GlyphState, PlayerState types. First failure reasons: invalid_type, unknown_id, out_of_range, already_collected, rate_limited; success is ok. applyCollect and tickRespawns clone all state containers and glyph records. applyCollect prunes expired rate timestamps. Tests cover both rarities, each distance axis, translated 3D positions, validation precedence, exact respawn/window boundaries, independent state, frozen inputs, and no spawns.

## Audits
Pending independent audit after check.sh passes.

## Outcome
Implemented; headless tests passed. Full gate, audit and PR pending. No merge authorization requested.
