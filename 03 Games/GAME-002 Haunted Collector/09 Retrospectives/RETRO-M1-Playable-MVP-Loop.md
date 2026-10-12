---
id: RETRO-M1-Playable-MVP-Loop
title: "M1: Playable MVP loop"
type: retro
project: GAME-002
status: done
milestone: M1
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/retro
related:
  - "[[GAME-002 Haunted Collector/03 Roadmap]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
  - "[[TEST-20261011-03]]"
  - "[[TEST-20261011-04]]"
  - "[[TEST-20261011-05]]"
  - "[[TEST-20261011-06]]"
---

# Retrospective: M1, the playable MVP loop

*Written by Claude; approved by jg on 2026-10-11 (chat), including the open items below.*

## Goal of the milestone
A playable first session following brief §12 and §20: walk the graveyard, capture a monster, bring it home for income, upgrade, ride and edit the ghost train, and follow the Bell Tower clue to the Bell Wraith.

## Outcome
| Planned | Result |
|---|---|
| TASK-0011 to TASK-0018 | **All 8 done**, merge approved by jg on 2026-10-11 (PRs #2 and #4 to #10) |
| Exit gate: §20 journey in a TEST note | Met: [[TEST-20261011-03]] (fresh profile, real client), fixes checked in [[TEST-20261011-04]] |
| Exit gate: persistence check in a published or API-enabled place | **Not met.** Moved to M2 by [[ADR-0006-M1-Tuning-And-Scope-Decisions]] §4. Saving is memory-only and says so in game |
| Audits | 8 tasks, 19 audits. Attempt 2 passed for 6 tasks. TASK-0017 passed at attempt 3; TASK-0012 hit the revision limit and passed at attempt 4 after jg's unblock (ADR-0006 items 6–7) |
| Automated evidence (latest) | Specs 51/0, FullLoop 56/56, Reachability 15/15, ExploitProbe 13/13, CrossPlot 12/12 (2 players) |

## What went well
- **Play scenarios driven from Edit through the Studio MCP** (`StudioTestService`) gave repeatable evidence for every task. CrossPlot caught the front-seat griefing regression before a human did.
- **Running the real client by hand found what the scenarios missed:** the editor taps landing 8.6 studs off, prompts swallowing taps, E-key prompt conflicts, the guest seat seating players on touch, and the Bell Wraith never spawning ([[TEST-20261011-03]] F1–F5).
- **Asking jg all the decisions in one batch up front** (economy, deviations, tutorial, queue order, who playtests) let long stretches run without interruption.
- **Delta re-audits on Sonnet** were cheap (75k to 103k tokens) and still found real problems, for example a spec passing for the wrong reason.

## What went badly
- **The build ran ahead of the gates:** one integration commit covered TASK-0011 to TASK-0018. That turned M1 into a long tail of bookkeeping PRs and one approval per task after the fact.
- **Evidence ACs that need human judgement were found at audit time:** readability, a physical controller, touch. They cost TASK-0012 two extra attempts and a block. Decide them when the task is approved.
- **Specs that pass for the wrong reason:** the clearance case was rejected by point spacing, and the exploit probe stopped at the tier gate. Specs now assert the exact rejection reason.
- **Roblox reserves inputs:** DPadUp can't be used by the game. Found only with virtual input in Studio.
- **Operational:** approve-merge is a human-only command, and it was easy to re-run the previous task's command by mistake (harmless, the orchestrator refused it).

## Usage & cost
- API spend: $0 (subscription only).
- Audit subagents in this session, from `tasks/usage-ledger.jsonl`: 4 attempt-2 audits on Opus (about 563k tokens across 8 tasks) and 3 delta audits on Sonnet (about 261k). The main session's tokens weren't measured.

## Open items for jg (settled 2026-10-11)
- ✅ **Confirmed by jg** (ADR-0006 item 8): the code values ADR-0006 adopted but didn't name one by one: return timer 75/90/120 s, ride base 40, ride cooldown 20 s, Spectral at 10% × 1.5. Also note the first upgrade comes about 51 s after the first secure, against a target of about 2 min ([[AUD-20261011-TASK-0015-02]]).
- ✅ **Accepted by jg** (ADR-0006 item 9): the crypt-entry window: the gate opens on the client and the server checks every 0.25 s (TASK-0012 Outcome).
- ⏳ **Still open:** a short human feel run of the first session (pacing, readability in the dark).
- ✅ Retro approved; the M2 tasks below were created as `ready` (TASK-0019 to TASK-0022).

## Changes to adopt
- When approving a task, name who settles each evidence AC and how (human judgement, a device, or a scenario). Don't leave it to the audit.
- Specs assert the rejection reason, not just `ok == false`.
- One task per build commit. No integration commits across tasks.
- Candidate lesson (not promoted, it needs a second occurrence): "Check input bindings against Roblox-reserved keys with virtual input before shipping" ([[TEST-20261011-05]]).

## M2 tasks (approved by jg on 2026-10-11)
1. [[TASK-0019-Persistence-And-Rejoin-Test]]: **persistence and rejoin test** in a private API-enabled place (ADR-0006 §4). Required before any public play.
2. [[TASK-0020-Physical-Device-Checks]]: **physical devices:** a controller and a touch device (or emulator) for the flashlight, the track editor and capture (ADR-0006 item 7). Include the full gamepad editor path.
3. [[TASK-0021-Anti-Cheat-Hardening]]: **anti-cheat hardening before public play:** carry speed and secure plausibility, server-side Bell Wraith visibility or inspect gating, Ashen escape respawn only in the Crypt (ADR-0006 §2).
4. [[TASK-0022-M1-Polish]]: **M1 polish:** exhibit in-range feedback (TEST-03 F6), a tailored completion hint (F7), a drawn capture zone matching the judged window, the stale-purchase reply, quality-clamp specs, a test that forces a crypt ejection, rebuilding the track when a plot changes owner mid-ride, and a post-fix light-off capture.
5. Then the roadmap's M2: tuning from playtest data and sound (`roblox-sfx`).
