---
id: ADR-0006
title: M1 Tuning and Scope Decisions
type: adr
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-11
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[INBOX-20261011-Haunted-Collector-Brief]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[AUD-20261011-TASK-0012-01]]"
  - "[[AUD-20261011-TASK-0014-01]]"
  - "[[AUD-20261011-TASK-0015-01]]"
  - "[[AUD-20261011-TASK-0018-01]]"
  - "[[AUD-20261011-TASK-0012-03]]"
  - "[[TEST-20261011-05]]"
  - "[[RETRO-M1-Playable-MVP-Loop]]"
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/decision
---
# ADR-0006: M1 tuning and scope decisions

## Context
The attempt-1 audits found that the prototype's config disagreed with the design doc (v0.1). They also found four acceptance criteria that needed a human decision: the economy numbers, the tutorial steps, the Ashen variant, and persistence and reachability evidence. The 2026-10-11 readiness audit asked for these to be settled before M1 closes. jg answered each point in chat on 2026-10-11.

## Options considered
1. Keep the code values and update the design to match.
2. Revert the code to the design values and re-run the tests.
3. Leave the numbers unresolved until playtests. M1 can't close in that case.

## Decision
Approved by jg on 2026-10-11 (Claude Code session, chat answers).

1. **Economy: the code values are official for M1** (option 1). The design is updated to match `games/haunted/src/shared/Config/`:

   | Setting | Design v0.1 | Official (code) |
   |---|---|---|
   | House tier 1 / tier 2 cost | 300 / 2,000 | 250 / 1,500 |
   | Speed upgrade costs (3 levels, +2 WalkSpeed each) | 100 per level | 75 / 200 / 450 |
   | Acclimation | 60 s | 30 s |
   | Base income per second | common 2, uncommon 4, rare 10 | Wisp 1, Stitched Hound 1.5, Hollow Gentleman 3, Bell Wraith 8 |

   The same config also differs from v0.1 on these values: return timer 75 / 90 / 120 s (design: 90 to 120 s), ride base payout 40 (design: 50), ride cooldown 20 s, natural variant "Spectral" at a 10% roll and ×1.5 (design: about 8%). **They are adopted under the same "code values" decision but weren't named one by one. Flagged for jg to confirm at the M1 retro.** All of these stay tunable after playtests.
2. **Ashen variant: environmental, Sealed Crypt only.** It has a 30% roll for monsters spawning in the Crypt and ×1.75 income. That replaces "tied to the Bell Tower clue, ×1.5" in v0.1. This settles [[AUD-20261011-TASK-0018-01]] F6 and the matching TASK-0013 point.
3. **Tutorial: NOT approved as built.** The code must follow brief §12 one to one: 12 steps. Step 1 finishes on proximity to the player's station, not a timer. Step 8 finishes when the player opens the Mansion or the Journal. The exhibit and "catch the rare" steps are dropped from the tutorial, and the rare stays as the post-tutorial hook. This was implemented on the TASK-0011 branch in revision 2.
4. **Persistence: memory-only is acceptable for M1.** M1 can close without a real DataStore rejoin test. The game must keep reporting memory-only mode honestly. A rejoin and persistence test in a private, API-enabled test place moves to M2 and is required before any public release. Nothing is published for this.
5. **TASK-0012 AC1: walk-through instead of the prover.** The `Reachability` play scenario plus a recorded walk-through (plots → every zone → back, including the shortcut; the Crypt is blocked while gated) replace the `roblox-map` prover report.

### Addendum (approved by jg on 2026-10-11, chat answer after [[AUD-20261011-TASK-0012-03]])
6. **TASK-0012 AC2: dark-section readability accepted.** jg reviewed the [[TEST-20261011-05]] captures of Mausoleum Hollow and accepts them as readable for M1. The flashlight toggle evidence is F, the HUD button (mouse) and a virtual gamepad on DPadDown.
7. **Physical-device checks move to M2.** A physical controller and a real or emulated touch device are required in M2 before public play, covering the flashlight (TASK-0012 AC2) and **the touch track editor (TASK-0017 AC2)**, including taps near the mobile thumbstick and jump areas. For M1, TASK-0017 AC2 is judged on mouse and gamepad-cursor evidence.

Bell Wraith spawning only for clue holders follows the approved design and needed no new decision. Revision 1 implemented it.

### Addendum 2 (approved by jg on 2026-10-11, chat answer at the [[RETRO-M1-Playable-MVP-Loop]])
8. **The unnamed code values are confirmed as-is:** return timer 75 / 90 / 120 s, ride base payout 40, ride cooldown 20 s, Spectral at 10% × 1.5. The first upgrade arriving about 51 s after the first secure (target about 2 min) stays for now and is retuned with M2 playtest data.
9. **The crypt-entry window is an accepted M1 risk:** the gate opens on the client for qualifying players, and the server checks every 0.25 s. Capture in the Crypt is gated separately on the server. Hardening before public play is [[TASK-0021-Anti-Cheat-Hardening]].

## Consequences
- [[GAME-002 Haunted Collector/01 Game Design]] goes to v0.2 with these values. Its status stays `proposed`, because the roadmap and design as a whole still need jg's approval.
- TASK-0012 AC1, TASK-0018 AC2 and the persistence parts of TASK-0011 and TASK-0017 AC4 are judged against this ADR in the attempt-2 audits.
- M2 must add a persistence (rejoin) test task before any public play.
- M2 must add a physical-device task (controller and touch, flashlight and track editor) before any public play.
