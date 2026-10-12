---
id: TASK-0025
title: Clue Hunting Removal
type: task
project: GAME-002
status: approved
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
**References used:** none applicable (removal work). Patterns kept from this codebase: pure rules in `shared/Rules`, snapshot providers in services.

**Removed** (restore from git history before this task's commit if clue hunting returns):
- `LandmarkService` (investigate prompts, clue writes, flag setting, landmark count, the 0.25 s crypt eject loop) and the `LandmarkStart` scenario.
- From `World.Landmarks`: the `clue`, `requiresFlag` and `setsFlag` fields; `cryptLandmarksNeeded`.
- `Monsters.clueLandmark` and `requiresFlag`; the hidden-Wraith client trick; the `OvergrownGate`.
- The first-ride bell hint and toast; the journal Clues card and landmark counter; the Grave Scholar trophy.

**Retained:**
- Landmarks as named scenery (anchors and billboards).
- The crypt walls and gate. The gate opens locally when `snap.cryptOpen` is true.
- `journal.clues` and the flags `shortcut`, `bellHint` and `bellClue` in the profile schema. Nothing writes them, but `KNOWN_FLAGS` keeps them so old profiles survive.
- The Round 20 startle, chase and grab behaviour, untouched.

**Replaced:**
- The crypt rule is `EconomyRules.cryptOpen(houseTier)`, using the existing `unlocksCrypt` on the Restored Manor and Grand Mansion.
- A capped rare (`maxAlive`) ignores the zone cap, so the Bell Wraith always gets a slot. The old clue condition did that job before.
- Monster markers now mark species you have inspected (`journal.seen`).
- Tutorial steps 3 (`explore`: walk up to a monster) and 12 (`lair`: enter the crypt) replace the two clue steps in place. The completion hint names the house tier.
- The unknown-creature journal hint lists the zones where the species lives.

**Crypt enforcement decision:**
- The eject loop was not kept. Access only matters for capture, and capture in a gated zone is refused on the server (`CaptureService.requestStart`) below tier 1.
- Entering the crypt without access therefore grants nothing.
- The capture check is stronger than the old 0.25 s eject window that ADR-0006 §9 accepted as a risk.

**Attempt 1 checks** ([[TEST-20261012-01]], 2026-10-12):
- `scripts/check.sh` ALL CHECKS PASSED (StyLua, Selene, strict types, both Rojo builds, JSON, queue, vault, Python tests).
- Studio: specs 63/0, FullLoop 81/81, Reachability 15/15, ExploitProbe 13/13.
- CrossPlot (2 players) scored 12/13 twice ("B's parked front seat refuses A"), and the harness gave no result twice.
- A minimal repro proved the cause: a server `Seat:Sit()` seats through `Disabled` (engine behaviour, not in our code).

**Revision 1** (after [[AUD-20261012-TASK-0025-01]]):
- **F1 (major):** the CrossPlot parked-seat check now asserts what the game guarantees. A forced into B's parked seat doesn't keep it, because the owner guard ejects A. The enabled-seat check now runs first, while A has never sat in that seat, so it can't pass on an earlier sighting. A player can't call `Seat:Sit()`, and touch-sitting a disabled seat still fails.
- **F2:** linked the TEST note and listed every result.
- **F3:** the architecture row for LandmarkService now records its removal.
- **F4:** added dated "superseded" notes to ADR-0006 (the clue-holder line and §9), keeping the original text. TASK-0021's AC3, AC5 and its Wraith-gating scope are flagged for jg; the ACs themselves are unchanged.
- **F6:** `NEAR_MONSTER_STUDS` is now 16 (the Inspect reach), so the step 3 hint shows until the player is close enough to inspect.
- **F7:** renamed the FullLoop prompt check to what it proves; the tutorial spec asserts the concrete string; added an `EconomyRules.cryptOpen` spec.
- **F8:** fixed the stale R-key comment, removed the unused "clue" toast kind, and commented the builder's unused return fields (TASK-0026 replaces that builder).
- **F9:** `respawnEscaped` applies the same capped-rare zone-cap exemption as `fillZones`.
- **F5 (pre-existing):** left to TASK-0021 AC4.
- **CrossPlot test robustness** (found while correcting F1, all test-only):
  - The enabled-seat check now runs first, because the engine refuses to re-seat a humanoid right after an ejection.
  - Captures try up to 3 monsters, since a timed release can miss under 3-process load.
  - A missing B monster now reports and ends the scenario instead of erroring.
- **Revision 1 evidence** ([[TEST-20261012-01]]):
  - `scripts/check.sh` all pass.
  - Specs 64/0, FullLoop 81/81, Reachability 15/15, ExploitProbe 13/13, CrossPlot (2 players) 13/13.

## Audits
- [[AUD-20261012-TASK-0025-01]]: fail (1 major: CrossPlot not green)
- [[AUD-20261012-TASK-0025-02]]: pass (delta). N1, a CrossPlot touch-sit check, is deferred as a follow-up; N2 and N3 doc nits are fixed.

## Outcome
