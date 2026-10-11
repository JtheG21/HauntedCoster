---
id: TASK-0011
title: Haunted Scaffold and Player Data
type: task
project: GAME-002
status: in_progress
priority: high
risk: medium
owner: executor
milestone: M1
depends_on: []
branch: task/TASK-0011-Haunted-Scaffold-And-Player-Data
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# TASK-0011: Haunted Scaffold and Player Data

## Goal
Stand up the GAME-002 Rojo project and a safe, server-authoritative player profile and plot system that every later task builds on.

## Scope
- **In:** `haunted.project.json`; `games/haunted/{src,tests}`; check/typecheck/Rojo-build coverage for both projects; PlayerDataService (schema v1, UpdateAsync, session lock, retries, clamp/validate, never-drop migration, memory fallback + banner); PlotService (6 plots, assign/release, bounds, ownership helper); currency HUD.
- **Out:** Gameplay content; monetization; publishing (user creates and saves the new place locally).

## Files expected to change
- `haunted.project.json`
- `games/haunted/src/server/Services/PlayerDataService.luau`
- `games/haunted/src/server/Services/PlotService.luau`
- `games/haunted/src/shared/Config/`
- `games/haunted/src/shared/Rules/ProfileRules.luau`
- `games/haunted/tests/`
- `scripts/check.sh`
- `scripts/typecheck.sh`

## Acceptance criteria
- [ ] AC1: `rojo build haunted.project.json` succeeds and check.sh covers both projects (GAME-001 checks unchanged and still pass)
- [ ] AC2: On join a player gets a validated default or loaded Profile v1 and a free home plot; plot released on leave
- [ ] AC3: Saves use UpdateAsync with a session lock, retry with backoff, and run on leave, on a 60 s autosave and in BindToClose; overlapping saves are serialized
- [ ] AC4: Malformed or out-of-range saved values are clamped or reset per field and logged; unknown fields are preserved (no data loss on migration)
- [ ] AC5: With DataStores unavailable the game runs in memory-only mode with a visible banner; never reported as persisted
- [ ] AC6: ProfileRules (validate/clamp/migrate) have passing specs
- [ ] AC7: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs named in the ACs (run in a fresh Play session, Server data model).
- **Studio playtest procedure:** in the GAME-002 place, start Play from a fresh profile and walk each AC in order. Record the results in the Implementation record, and say plainly which ones were not run.

## Risks / notes
Planned from [[INBOX-20261011-Haunted-Collector-Brief]]. Blocked on approval of [[ADR-0005-Haunted-Collector-Direction]]. Numbers come from the draft design and are tunable.

---
## Implementation record
*Prototype built in one integration commit, `17cb5ae` on `task/TASK-0011-Haunted-Scaffold-And-Player-Data`, which covers TASK-0011 to TASK-0018. The user approved building without per-task gates on 2026-10-11.*
- `scripts/check.sh`: all pass (StyLua, Selene, strict typecheck for both projects, Rojo builds, vault, Python tests).
- Unit specs: 37/37 pass headless ([[TEST-20261011-01]]). Server smoke in Run mode: clean.
- **Not yet verified with a player:** the `FullLoop` play scenario is written but hasn't run (the Studio window didn't load the place). The ACs below stay unchecked until it has run.
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

### Revision 1 (2026-10-11): audit fixes, work in progress
All eight attempt-1 audits failed ([[AUD-20261011-TASK-0011-01]] … [[AUD-20261011-TASK-0018-01]]). The fixes are committed on this branch and **not merged**:
- Saving: BindToClose waits for in-flight and queued saves; a newer-schema profile loads read-only and is never written; a missing or foreign lock aborts the save; the lock is released if the player leaves mid-load; plot assignment retries.
- Purchases carry the expected level, so a double-click buys only once.
- Capture: slack 0.04 s, ping counted once, min gap 0.35 s, retuned zones (spec: mashing is unreliable and gets harder with rarity); variant roll moved to shared code with a spec; the session ends on death; escaped respawns and rares respect caps; server-side carry speed check.
- Train: the owner seat is disabled outside rides and griefers are unseated through the SeatWeld; seating retries; the cooldown is keyed by UserId; track clearance check. Bell Wraith spawns only when someone has the clue and is hidden locally for others. Gamepad controls in the editor and for the light.
- New tests: Variants.spec, extra Capture/Track/Tutorial specs (46/0); scenarios FullLoop **55/55**, Reachability **11/11**, ExploitProbe **11/11**, CrossPlot (2 clients) last finished run 11/12. The seat failure was fixed afterwards, and that run was interrupted before completing, so **CrossPlot still needs a re-run**.

**Next session:** re-run CrossPlot; update the design note for changed numbers, the Ashen rule and tutorial deviations; link the audits from the task notes; record-exec, then a fresh attempt-02 audit. Still needs a human: a hands-on §20 playtest, real-DataStore persistence (needs publishing), Lighting.Technology.

### Revision 1, continued (2026-10-11, second session)
- **Decisions:** jg settled the open questions in [[ADR-0006-M1-Tuning-And-Scope-Decisions]]:
  - Code economy values are official.
  - Ashen is Crypt-only.
  - Memory-only saving is accepted for M1, and the rejoin test moves to M2.
  - Walk-through plus Reachability replaces the prover.
  - The tutorial must follow brief §12.

  [[GAME-002 Haunted Collector/01 Game Design]] is now v0.2.
- **Tutorial:** 12 steps, one to one with §12. Step 1 finishes on reaching the station; step 8 finishes on opening the Mansion or Journal (`mansionOpened` flag via `Ack`). The spec is table-driven over every step.
- **Fixes found by the Studio runs:**
  - CrossPlot failed 11/12 (a griefer stayed in the owner's seat because the SeatWeld was destroyed inside the Occupant signal); the ejection is now deferred.
  - The hands-on run [[TEST-20261011-03]] found the track editor's tap offset (major), the Bell Wraith never spawning in a full Crypt (major), guest-seat touch-sitting, Inspect/Investigate sharing E, and world prompts covering the editor. All were fixed, with a FullLoop check for the Wraith.
- **Evidence on the final code:** [[TEST-20261011-04]].
- **Merged `main`** (reference-first docs) into this branch with no conflicts.
- **Still not covered:** real DataStore persistence (M2 per ADR-0006), touch and gamepad hardware, human feel and pacing, Lighting.Technology.

## Audits
- [[AUD-20261011-TASK-0011-01]]: fail (2 major), revision 1

## Outcome
*(after merge: result, lessons, follow-ups)*
