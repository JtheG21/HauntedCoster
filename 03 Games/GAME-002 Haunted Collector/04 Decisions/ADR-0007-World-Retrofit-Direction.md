---
id: ADR-0007
title: World Retrofit Direction
type: adr
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-12
related:
  - "[[RSH-20261012-World-Retrofit-Audit]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/decision
---
# ADR-0007: World retrofit direction (radial plots, rotating habitats, no clue hunting)

## Context
On 2026-10-12 jg supplied a world, map and environment retrofit brief, the result of a design discovery round. It keeps the core loop (hunt → capture → carry home → secure → income → mansion and train) and changes the world around it:
- six plots in a ring around a shared hunting area,
- one of four habitats active in the centre, rotating every 15 minutes on a shared clock,
- a purple-sky, green-fog, warm-orange-light atmosphere,
- a detailed ghost cemetery first, with blockouts for the other three,
- clue hunting removed from the MVP,
- optionally, a local retaliation chase after a failed capture.

The audit [[RSH-20261012-World-Retrofit-Audit]] found:
1. Every plot-local position assumes unrotated plots.
2. A carried capture isn't tied to the habitat, so a swap can't delete it.
3. Clue progression gates the crypt, the Bell Wraith, the shortcut, monster markers, two tutorial steps and a trophy.

This ADR changes approved decisions: [[ADR-0006-M1-Tuning-And-Scope-Decisions]] §2 (Ashen tied to the crypt zone stays, but crypt access changes) and §3 (tutorial steps 3 and 12), plus the clue rows of the GDD v0.3.

## Options considered
1. **Staged retrofit in seven scoped tasks (recommended).** Each task is its own branch, with checks, Studio scenarios and one audit. Merges are stacked and approved by jg.
2. One umbrella task: rejected, because AGENTS.md requires one scoped task at a time and the diff would be too large to audit.
3. A full redesign: out of scope (brief §14).

## Decision
**Approved by jg in chat on 2026-10-12** (Claude Code session, answers to the four batched questions): the plan and all seven tasks ("Approve all, run in order"), plus the choices recorded under *(jg)* below. The defaults were approved with the plan.

**Layout (defaults)**
- The hub centre is at the world origin. Six plots sit 60° apart with centres at r = 185, inner edge at r = 140, and keep their current 100 × 90 size and contents.
- Each plot frame is `CFrame.lookAt(centre, hub)`, so local -Z faces the hub and every plot-local point goes through one transform. Saved routes stay valid unchanged.
- A persistent ring road (r 120–132) and hub wall (r 115) have three gates at 30°, 150° and 270°, one between each pair of plots, so every plot is the same distance from a gate. There is no separate shortcut.

**Habitat modules (defaults)**
- The modules are Ghost Cemetery, Cursed Woodland, Spider Woodland and Zombie Settlement. They share one footprint: a disc of r ≤ 112 inside the wall, with the same three gate connection points and clear approach corridors.
- Each module defines its own spawn zones and two landmark slots, and all four are prebuilt at server start and swapped in and out.
- Roster: Cemetery has Wisp, Hound, Gentleman and Bell Wraith (crypt only). Woodland weights Hound. Spider Woodland weights Gentleman. Zombie Settlement mixes all three commons. There are no new species or variants in this pass.

**Rotation (defaults)**
- The order is fixed and repeats: Cemetery → Woodland → Spider Woodland → Zombie Settlement, 900 s each (a 60 min cycle), aligned to UTC epoch time so every server agrees without messaging.
- A warning shows 60 s before the swap, and new captures close in the last 15 s.
- All values live in config. Tests inject a clock and the live interval never reads a test setting.

**Swap policy for players and captures** *(jg: "Evacuate to the gates")*
- Carried captures are never touched (they aren't tied to a habitat).
- New captures close in the last 15 s.
- At the swap: open meter sessions are cancelled (nothing was caught, so nothing is lost) and wild monsters are cleared. Players still inside are moved just outside their nearest gate behind a short fog fade.
- An escaped capture being chased moves with its player, and the chase continues on the ring road.

**Clue removal** *(jg: "Restored Manor")*
- The Bell Wraith and the Sealed Crypt need house tier 1 (the existing `unlocksCrypt` flag).
- The Wraith lives only in the cemetery crypt and is visible to everyone. Its capture prompt tells tier-0 players to restore their house. Ashen stays crypt-only.
- Landmarks become scenery and navigation only: no prompts, no clues. The Old Well shortcut is retired.
- The journal keeps species and variants. The Clues card and landmark counter are removed. `journal.clues` and the flags `shortcut`, `bellHint` and `bellClue` stay in the profile schema, unused, so old profiles load unchanged.
- The tutorial keeps its 12 slots so saved step numbers still mean the same step: step 3 becomes a hunting-ground and rotation intro, and step 12 becomes a habitat or Bell Wraith step.
- The "Grave Scholar" trophy is retired.

**Failed-capture retaliation** *(jg: "Final miss only")*
- When a capture's misses run out, the target and up to 2 wild monsters within 30 studs chase the player for at most 8 s at 13.5 studs/s (players run 16).
- A catch is a 1.5 s ragdoll with no damage, then that monster gives up.
- Single misses keep the Round 20 startle hop. Built last (TASK-0031). All numbers are config.

**Assets (default)**
- Built-in parts and materials only. No uploaded, generated or Creator Store models, skyboxes or textures.
- The map references are inspiration only (their source and licence aren't recorded).

## Consequences
- GDD v0.3 → v0.4 for the map, core loop, Bell Wraith and tutorial rows, after approval. The GDD status stays `proposed`.
- Return walks get shorter (worst case about 500 → 320 studs). `returnSeconds` stays 75 / 90 / 120 s (ADR-0006 §8) and is retuned only after a playtest.
- New tasks: [[TASK-0025-Clue-Hunting-Removal]], [[TASK-0026-Radial-Plot-Layout]], [[TASK-0027-Habitat-Modules-And-Blockouts]], [[TASK-0028-Cemetery-Vignette-And-Atmosphere]], [[TASK-0029-Habitat-Rotation]], [[TASK-0030-House-And-Train-Presentation]], [[TASK-0031-Failed-Capture-Retaliation]].
- Persistence is still memory-only ([[TASK-0019-Persistence-And-Rejoin-Test]]), so no live profiles exist yet. The schema stays at version 1 because no field is removed or renamed.
