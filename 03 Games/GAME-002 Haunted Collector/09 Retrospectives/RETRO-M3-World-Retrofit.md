---
id: RETRO-M3-World-Retrofit
title: "M3: World retrofit"
type: retro
project: GAME-002
status: proposed
milestone: M3
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/retro
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[RSH-20261012-World-Retrofit-Audit]]"
---

# Retrospective: M3, the world retrofit

*Draft written by Claude on 2026-10-12; waiting for jg's review.*

## Goal of the milestone
Retrofit the world without redesigning the game ([[ADR-0007-World-Retrofit-Direction]]): remove clue hunting, put six plots in a ring around a central hunting ground, build four swappable habitats on a 15-minute rotation with capture-safe swaps, give the world its purple-sky, green-haze, warm-light look, upgrade the houses and train station, and add retaliation on a failed capture.

## Outcome
| Planned | Result |
|---|---|
| [[TASK-0025-Clue-Hunting-Removal]] | Done. PR #17. The crypt and Bell Wraith need the Restored Manor |
| [[TASK-0026-Radial-Plot-Layout]] | Done. PR #20. Six rotated plots, one shared plot transform |
| [[TASK-0027-Habitat-Modules-And-Blockouts]] | Done. PR #21. Four modules behind one contract and validator |
| [[TASK-0028-Cemetery-Vignette-And-Atmosphere]] | Done. PR #22. The look still needs jg's sign-off (the sky renders blue-indigo; the green comes from ground mist) |
| [[TASK-0029-Habitat-Rotation]] | Done. PR #23. One failed audit (a stuck swap), fixed in revision 1 |
| [[TASK-0030-House-And-Train-Presentation]] | Done. PR #24 |
| [[TASK-0031-Failed-Capture-Retaliation]] | Merged through PR #25 once its audit passes; see the task note |
| [[TASK-0032-Retaliation-Hardening]] | Done. PR #26. The TASK-0031 audit follow-ups |

## What went well
- Specs moved to Lune (ADR-0008), so `scripts/check.sh` proves the rules on every commit without Studio. It grew from 63 to 96 specs.
- Specs on shared layout config caught mistakes before Studio: PlotDecor flagged a lamp on the pen, and the habitat validator was green for all four modules on the first build.
- Timing-heavy behaviour (the rotation swap) was cheap to test once the schedule became a test argument: three swaps in about 100 s.
- The independent audits paid off. TASK-0029's audit found a real bug (an error during a swap would leave the server foggy and refusing captures) that no scenario hit.
- A scenario found a design gap: a second pursuer could stun-lock a player right after they got up (TASK-0031 run 1). That led to the grace rule.

## What went badly
- Studio on the 8 GB Mac drops the MCP connection under memory pressure, mostly during screen captures in Play. Several captures had to be retried or added later.
- The CrossPlot harness often starts only one client. Almost every task needed a rerun.
- Process slips, caught and fixed:
  - A forward link to a not-yet-written audit note broke the vault check.
  - One merge went through before CI reported. CI passed afterwards.
  - I wrote a made-up commit hash in a TEST note build line, then corrected it.
- Visual direction is the weak spot of headless work. The purple-sky and green-haze brief can't be met literally with one Roblox Atmosphere colour, and only jg can judge the look.

## Usage & cost
- No paid APIs, no Robux, nothing published. API spend $0 (orchestrator ledger).
- One audit subagent per attempt: Opus for the first audits of TASK-0026, 0029 and 0031; Sonnet for 0027, 0028, 0030 and the 0029 delta re-audit.

## Changes to adopt (link any LES- or ADR- notes)
- Gate commands on `scripts/check.sh`'s exit code, not on its last line of output.
- Before merging, wait until CI has reported on the head commit.
- Candidate lesson, if jg agrees: in Studio MCP, the plugin has its own module cache, so a Play session's services can't be driven from `execute_luau`. Use scenario arguments. Evidence: [[TEST-20261012-03]].
- jg's open review items: the M3 look ([[TEST-20261012-04]]), the habitat blockouts ([[TEST-20261012-03]]), the house tiers ([[TEST-20261012-06]]), one real 15-minute swap, and the feel of retaliation ([[TEST-20261012-07]]).
