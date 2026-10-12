---
id: TASK-0018
title: Journal, Tutorial and Rare Clue
type: task
project: GAME-002
status: approved
priority: high
risk: low
owner: executor
milestone: M1
depends_on:
  - TASK-0012
  - TASK-0013
  - TASK-0014
  - TASK-0015
  - TASK-0016
  - TASK-0017
branch: task/TASK-0018-Journal-Tutorial-And-Rare-Clue
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# TASK-0018: Journal, Tutorial and Rare Clue

## Goal
Tie it into one first session: journal UI, resumable 12-step tutorial, and the Bell Wraith clue that gives a reason to return.

## Scope
- **In:** Journal UI (known/unknown species and variants, clues, trophies); TutorialService state machine with skip-forward checks; Bell Tower clue -> Bell Wraith spawn condition in Sealed Crypt; next-action hint; end-to-end playtest note.
- **Out:** New regions, cosmetics shop.

## Files expected to change
- `games/haunted/src/server/Services/TutorialService.luau`
- `games/haunted/src/shared/Rules/TutorialRules.luau`
- `games/haunted/src/client/JournalUI.client.luau`

## Acceptance criteria
- [ ] AC1: Journal shows known/unknown entries and clues consistent with the profile; completion gives trophies only
- [ ] AC2: Tutorial follows brief §12, resumes after rejoin, and auto-advances if the step is already satisfied (spec covers every step)
- [ ] AC3: After the first paid ride the Bell Tower clue points to the Bell Wraith; it spawns only in the Sealed Crypt once the condition is met
- [ ] AC4: A TEST- note records a fresh-profile run of the full brief §20 journey, with times; persistence result stated honestly
- [ ] AC5: scripts/check.sh passes

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
- *(Superseded below: FullLoop has since run, see revision 1.)*

### Revision 1 (with TASK-0011, `5878f6d`, merged in PR #2)
- The tutorial was rewritten to brief §12 one to one (12 steps; step 1 on station proximity, step 8 on opening the Mansion or Journal; ADR-0006 §3) with a table-driven spec. The Bell Wraith spawns only while a player in the server has the Bell Tower clue, and specials ignore the zone cap.
- Evidence: [[TEST-20261011-03]] (fresh-profile §20 run through the real client), [[TEST-20261011-04]] (FullLoop 56/56, including "Bell Wraith spawns in the Crypt after the clue").
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0018-01]]: fail (2 major: no §20 end-to-end TEST note; rare not conditioned on the clue), revision 1
- [[AUD-20261011-TASK-0018-02]]: **pass** (2 minor, 4 nit): the Wraith is hidden only on the client, so a modified client can inspect it and get it recorded as seen; no test checks the Wraith is absent before the clue. Nits: trophy count includes the TrainBell clue, the journal hard-codes Crypt species, the Wraith can show for up to 1 s, notes were stale.

## Outcome
*(after merge: result, lessons, follow-ups)*
