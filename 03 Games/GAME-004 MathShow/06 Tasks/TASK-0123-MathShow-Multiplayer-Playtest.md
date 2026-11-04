---
id: TASK-0123
title: "MathShow Multiplayer Playtest"
type: task
project: GAME-004
status: approved
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

### Publish approvals (appended after AUD-20261103-TASK-0123-01 F1)
Full ledger (times, target, source SHA, wording): `docs/workflow/evidence/TASK-0123/playtest.txt`, "PUBLISH LEDGER".
- Publish 1 (create, 2026-11-03T20:53Z, a3bc341): jg's prompt of 20:36:07Z, "APPROVED (jg, in chat: "approve test publish"; publishing is limited to exactly this)", row U2.
- Publish 2 (overwrite, 2026-11-03T21:18:34Z, 81d21fc): jg typed at 21:15:21Z, "Republish to MathShow Private Test (universe 10774566206) with the TASK-0134 branch build, then continue the playtest." A typed message, not a button reply.

### Results and dispositions (appended after AUD-20261103-TASK-0123-01 F2; sections above unchanged)
Evidence: `docs/workflow/evidence/TASK-0123/playtest.txt`. Build 81d21fc unless noted. "Accepted" rows are jg's close-out dispositions (2026-11-03), not new runtime passes.

| Item | Result | Final outcome |
|---|---|---|
| P1 pad screens | jg reported every pad opened its screen on the iPad; Mac Blitz pad opened Blitz (22:22:57Z) | Pass (reported, this run) |
| P1 plaza Glyph counter | Stays on screen outside menus (iPad, reported); Mac 7 stayed 7 across Respawn | Pass (this run) |
| P1 Daily toast | Not reported | Not run; no pass claimed |
| P1 rare Glyph, HUD hiding | Not run here | Accepted: TASK-0121 Studio evidence |
| P1 CLOSE/LEAVE | Mac CLOSE worked; jg confirmed on the iPad | Observed; does not overturn the TASK-0134 audit FAIL |
| P4 idle B isolation | B counter 0, no menu opened while A used pads and Glyphs | Pass |
| P4 independent available set | Glyphs A collected still visible to B | Pass |
| P4 B collects independently | B count 0 -> 1 -> 2 (later 5) | Pass |
| P4 reverse isolation | jg confirmed A's count and view unchanged | Pass |
| P2 mid-match pad block | Live attempt: no pad screen opened, but control failed (route not reproducible) | Inconclusive; accepted by jg as covered by ModePadRules spec + TASK-0122 S4c |
| P3 iPad perf | Not read; model and iPadOS not recorded; no iPad console | Deferred; risk accepted by jg |
| P5 Mac CPU | 15.64-17.27 ms over 10 readings (mean 16.533) at the 60 FPS cap | Recorded, ~16.7 ms |
| P5 Mac GPU | 3.06-4.21 ms (mean 3.725) | Recorded, 3-4 ms |
| P5 Mac memory | 1623.7-1627 MB | Recorded, ~1.6 GB |
| P5 limits | Quality 6/10, 60 FPS cap, ping 29-90 ms; FPS inferred from frame ms; no triangle count; Observatory seen from ramp top only | Limits retained |
| Console | Mac client and server 0 errors, 0 warnings (~22:31Z) | Pass for Mac only; iPad console not captured |
| F5 Daily ramp | Unconfirmed in the run (Mac key-driven) | jg: real bug, goes to a fix task; not fixed here |

The 1514-1530 MB reading (22:31Z) came from a memory-starved Mac and is not a P5 number.

