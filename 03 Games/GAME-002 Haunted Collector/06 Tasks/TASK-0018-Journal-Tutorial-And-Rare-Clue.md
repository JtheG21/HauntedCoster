---
id: TASK-0018
title: Journal, Tutorial and Rare Clue
type: task
project: GAME-002
status: proposed
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
*(Executor: files changed, decisions, check output)*

## Audits
*(links to AUD- notes)*

## Outcome
*(after merge: result, lessons, follow-ups)*
