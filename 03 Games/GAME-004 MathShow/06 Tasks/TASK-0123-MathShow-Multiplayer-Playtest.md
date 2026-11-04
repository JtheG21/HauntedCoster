---
id: TASK-0123
title: "MathShow Multiplayer Playtest"
type: task
project: GAME-004
status: changes_requested
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0122
branch: task/TASK-0123-private-playtest
related:
  - "[[TASK-0122-MathShow-Hub-Mode-Pads]]"
created: 2026-11-02
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Multiplayer Playtest

## Goal
Prove with two real clients what the single-client Studio rounds could not: per-player delivery of GlyphState and ModePadOpen, and the mid-match pad block.

## Scope
- **In:** a two-client run on a private test place, with both client consoles captured and per-player outcomes recorded.
- **In (added by jg, 2026-11-02, from the TASK-0125 re-scope):** real-device FPS/MicroProfiler capture on phone + desktop for the hub (ShadowMap), including the five east-path lamps. In-Studio perf on this Mac is non-gating and not a substitute.
- **Out (non-goals):** gameplay or code changes beyond test scaffolding, DataStore, merging.
- **Approval:** publishing the private test place needs jg's explicit approval. Do not publish without it.

## Intake
- **Category, depth:** systems test, standard.
- **Why this exists:** jg's option A decision on [[TASK-0122-MathShow-Hub-Mode-Pads]] deferred its two-client check (S4d) as an accepted risk. The Studio multi-client test did not join a second client twice, likely memory pressure on an 8 GB Mac.
- **Assumption:** a private test place can host two clients where one Studio session cannot. Unconfirmed.

## Files expected to change
Evidence only: `docs/workflow/evidence/TASK-0123/`, this note, `tasks/items/TASK-0123.json`.

## Acceptance criteria
- [ ] AC1 Per-player GlyphState: each client's available glyphs and counter are independent.
- [ ] AC2 Per-player ModePadOpen: the player on a pad gets it, the other gets nothing; both consoles captured.
- [ ] AC3 Mid-match block with two clients: the player in the match gets nothing on a pad, the other player does.
- [ ] AC4 Evidence log with measured SHA and applies_to; no errors in either console.
- [ ] AC5 Real-device FPS/MicroProfiler capture on phone + desktop for the hub (ShadowMap), with device, build SHA and applies_to.

## Tests
Two real clients on a private test place.

## Risks / notes
Needs jg's approval to publish a test place.

---
## Implementation record
Private test experience "MathShow Private Test" (universe 10774566206, place 93701543861123), published on jg's approval, kept Private (early tester jg_574). Run 1 on main a3bc341 exposed a menu dead end (F1-F3); jg approved a republish of the TASK-0134 build (81d21fc, PR 196, not merged), and run 2 used that. Per-player Glyph independence passed (P4). Mac client and server consoles were clean; Mac frame times read on a clean client (CPU ~16.7 ms at the 60 FPS cap, GPU 3-4 ms, memory ~1.6 GB); P2 is not conclusive and P3 (iPad) was not done. Detail: `docs/workflow/evidence/TASK-0123/playtest.txt`.

## Audits

## Outcome

Partial. Open: mid-match block (P2, not conclusive), iPad perf and console (P3); see the evidence log. Draft; no audit.

### Close-out decisions (jg, 2026-11-03)
- jg will no longer test on the iPad (2026-11-03).
- P3 iPad performance: deferred, risk accepted by jg. Mitigations: ShadowMap (set by the project file, TASK-0135 merged 2026-11-03), PointLights <= 40 (hub total 25), CastShadow off on props, inventory budgets. Mac P5 numbers are in the evidence log. Re-measure when a mobile device is available.
- P2: accepted as covered by the ModePadRules spec and TASK-0122 Studio S4c; the live attempt is inconclusive.
- P1 leftovers: rare Glyph and HUD hiding covered by TASK-0121 Studio evidence; CLOSE/LEAVE confirmed by jg on the iPad on build 81d21fc (the Codex audit of PR 196 at that SHA is FAIL, tracked on TASK-0134).
- F5 Daily ramp: treated as a real bug, goes to a fix task.
- Test experience 10774566206 stays Private and untouched; no further publishes planned.

