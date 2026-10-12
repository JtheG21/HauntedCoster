---
id: TASK-0025
title: Clue Hunting Removal
type: task
project: GAME-002
status: ready
priority: high
risk: medium
owner: executor
milestone: M3
depends_on: []
branch: task/TASK-0025-Clue-Hunting-Removal
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
  - milestone/m3
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[RSH-20261012-World-Retrofit-Audit]]"
  - "[[SYS-Haunted-Capture-Loop]]"
  - "[[SYS-Haunted-Player-Data]]"
---
# TASK-0025: Clue Hunting Removal

## Goal
Players no longer investigate landmarks or collect clues for anything. Landmarks stay as scenery, the rare and the crypt follow mansion-tier progression ([[ADR-0007-World-Retrofit-Direction]]), and the journal, capture, containment, income and train keep working.

## Scope
- **In:** every clue dependency in the audit table of [[RSH-20261012-World-Retrofit-Audit]]: `LandmarkService` (scenery-only: anchors and names kept, no prompts, no clue writes, no eject loop), crypt access and Bell Wraith rule, `Monsters.requiresFlag`, the `TrainService` bell hint, shortcut gate, clue markers → "inspected" markers, `JournalUI` Clues card and counter, `TutorialRules` steps 3 and 12 and the completion hint, the Grave Scholar trophy, and the tests that rely on clues.
- **Out:** map layout (TASK-0026), new quests, new species or variants, deleting profile fields.

This is done first (before the layout work) because it removes the crypt gate, eject loop and prompts that every habitat module would otherwise have to carry.

## Files expected to change
`shared/Config/{World,Monsters}.luau`, `shared/Rules/TutorialRules.luau`, `server/Services/{LandmarkService,EncounterService,CaptureService,TrainService,TutorialService,PlotService}.luau`, `server/World/{GraveyardBuilder,PlotBuilder}.luau`, `client/LocalWorld.luau`, `client/UI/JournalUI.luau`, tests (`TutorialRules`, `ProfileRules`, `ChaseRules` and `Variants` specs; FullLoop, Reachability, LandmarkStart).

## Acceptance criteria
- [ ] AC1: No landmark shows an Investigate prompt. Nothing writes `journal.clues` or sets `shortcut`, `bellHint` or `bellClue`. There is no server eject loop.
- [ ] AC2: Crypt entry and Bell Wraith capture follow the rule jg approves in ADR-0007. The Bell Wraith spawns without any clue, is visible to everyone, and keeps `maxAlive = 1`. Ashen still rolls only in the Crypt zone.
- [ ] AC3: The west shortcut is open without a flag, and the first ride gives no bell clue or toast.
- [ ] AC4: Monster highlight and name markers appear for species the player has inspected (`journal.seen`).
- [ ] AC5: The journal still lists species and variants. The Clues card, the landmark counter and the Grave Scholar trophy are gone.
- [ ] AC6: The tutorial keeps 12 steps and none needs an investigation (step 3 explore, step 12 the rare's lair). Saved step numbers keep their meaning, and the skip-forward checks still prevent it from blocking play.
- [ ] AC7: A profile containing `journal.clues` and the three old flags sanitizes without loss (spec).
- [ ] AC8: The specs plus FullLoop, Reachability, ExploitProbe and CrossPlot (2 players) pass in Studio. LandmarkStart is retired.
- [ ] AC9: `scripts/check.sh` passes.

## Tests
- **Automated:** `scripts/check.sh`. The specs run in a fresh Play session (Server). FullLoop and Reachability rewritten without investigations; FullLoop gains "Bell Wraith capturable at tier 1, refused at tier 0" (if that rule is approved).
- **Who settles the evidence:** scenarios (Claude, Studio MCP).

## Risks / notes
- `ProfileRules.KNOWN_FLAGS` drops unknown flags, so the old names stay listed (unused).
- Removing the hidden-model trick for the Bell Wraith changes what tier-0 players see. That is intended: the Wraith becomes a visible goal.

---
## Implementation record

## Audits

## Outcome
