---
id: RSH-20261012-World-Retrofit-Audit
title: World Retrofit Audit
type: research
status: research
project: GAME-002
sources:
  - games/haunted (repo at 76fc332)
  - 10 References/02 Map (7 user screenshots)
  - JtheG21/Npc_template@28218e5
  - JtheG21/SODT-RC-1@86fc61d
confidence: high
created: 2026-10-12
updated: 2026-10-12
tags:
  - research
related:
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
---
# World retrofit audit (Stage 1)

## Question
What does the code actually assume about the world, plots, habitats and clues, so that the world retrofit (jg's brief of 2026-10-12: radial plots, rotating central habitats, new atmosphere, clue hunting removed) can be planned without breaking the M1 loop?

## Sources
| Source | URL / path | Accessed |
|---|---|---|
| GAME-002 code and tests | `games/haunted/` at `76fc332` (origin/main) | 2026-10-12 |
| Live build, Play session in `HauntedCollector.rbxl` via Studio MCP (3 captures, no edits) | local | 2026-10-12 |
| Map references 1-7 (user screenshots, untracked, context notes empty) | `10 References/02 Map/Reference1.md` … `reference7.md` | 2026-10-12 |
| Npc_template `TargetService.luau`, `Zombie.luau` | https://github.com/JtheG21/Npc_template (28218e5) | 2026-10-12 |
| SODT-RC-1 `RoundService.luau`, `RoundState.luau` | https://github.com/JtheG21/SODT-RC-1 (86fc61d) | 2026-10-12 |
| `roblox-map` skill instructions | `.claude/skills/roblox-map/SKILL.md` | 2026-10-12 |

## Observed (verified in code)
**Layout and coordinates**
- `World.PlotCenters`: six plots in a row at z = 85, x = -250…250, each 100 × 90 studs. The graveyard is a 260 × 210 rect at z -160…-370, joined by a straight lantern road. Hub-to-plot walks run about 240 to 500 studs.
- Plot-local means **world-aligned translation only** (`origin + localPos`; the comment in `World.luau` says plots are not rotated, and local -Z faces the graveyard). 30 call sites use it, in `PlotBuilder`, `PlotService` (`toWorld`, `isInOwnPlot`, spawn facing -Z), `ContainmentService` (resident positions, models face -Z), `CaptureService.secure`, `TrainService.toWorld` (cart heading uses local vectors as world vectors), `TrackEditor` (`hit - origin`, outline, camera offset), `Hud` (home arrow), and the FullLoop, CrossPlot, Reachability and ChaseRules tests.
- Saved routes (`profile.route.points`) and `TrackRules` (validation, payout, exhibit range) are purely plot-local. **A rigid per-plot transform keeps every saved route valid.**
- `AvenueSpawn` (0, 0.5, 40) and `ChaseRules.OpenGround` are row-layout specific.

**Habitat and spawns**
- `GraveyardBuilder.build` runs once at server start: ground, roads, fence, the main gate, the west shortcut gate, 5 landmarks, the walled Sealed Crypt, mausoleums, seeded tombstones and trees, and **all Lighting**. `World.Zones` (Gate, OldRows, Hollow, Crypt) are rects with spawn weights. `EncounterService` fills zones every 4 s, roams by tweened CFrame, and finds an escaped capture's "habitat" by scanning `World.Zones`.
- **A carried capture is not tied to the habitat.** On success the encounter is destroyed and the carry is `{species, variant}` on the player (`CaptureService`). Only three things touch habitat geometry: an open meter session (claimed encounter), the escape chase (a fleeing encounter in a flee region), and `respawnEscaped` (returns a lost escape to a zone).

**Clue hunting: every dependency**
| Dependency | Where | Effect today |
|---|---|---|
| Investigate prompts, clue recording, trophies callback | `LandmarkService` | Writes `journal.clues[id]`, sets flags |
| Clue texts and flags | `World.Landmarks` (`clue`, `requiresFlag`, `setsFlag`) | Old Well sets `shortcut`; Bell Tower needs `bellHint` and sets `bellClue` |
| Crypt access (3 landmarks + tier 1), 0.25 s eject loop, client gate | `LandmarkService.cryptOpen`, `LocalWorld.setGate`, `Economy.unlocksCrypt` | Gates the Crypt zone, Ashen and the Bell Wraith |
| Bell Wraith special encounter | `Monsters.BellWraith.requiresFlag = "bellClue"`, `EncounterService.fillZones` and `inspectPayload`, `CaptureService.requestStart`, `LocalWorld` (hidden model) | Spawns only if someone has the clue; invisible and uncapturable without it |
| Bell hint from the first ride | `TrainService.ride` (`bellHint`, `journal.clues.TrainBell`, toast) | Starts the rare chain |
| West shortcut | `World.Graveyard.shortcut`, `OvergrownGate`, `LocalWorld` | Opens only after the Old Well |
| Clue-based monster markers | `LocalWorld.updateMonsterMarkers` (`clueLandmark`) | Highlight and name label only after the species' clue |
| Journal clue card and landmark counter | `JournalUI` (Clues card, unknown-creature hint, `Landmarks n/5`) | — |
| Tutorial | `TutorialRules` steps 3 (`landmark`) and 12 (`bell`), `completeHint`; `TutorialService` ctx (`clueCount`, `angelClue`, `bell*`, `landmarks`) | Two of 12 steps and the post-tutorial hint need clues |
| Trophy "Grave Scholar" (5 clues) | `PlotService.rebuildTrophies`, `PlotBuilder.buildTrophies` | Cosmetic |
| Profile | `journal.clues`, flags `shortcut/bellHint/bellClue` in `ProfileRules.KNOWN_FLAGS` | Unknown flags are **dropped** by `sanitize`, so these names must stay known |
| Tests | FullLoop (landmark block, bell chain), LandmarkStart, Reachability (crypt and shortcut gates), TutorialRules.spec, ChaseRules.spec (crypt avoid), Variants.spec (Crypt) | — |

**Live look (Play session, no flashlight on the capture camera):** the sky is black with stars, lanterns read as flat yellow cubes with little light spill, and the road and graveyard are nearly invisible from 150 studs. From above, only the six neon beacons show. Today the map depends on the flashlight.

## References reviewed
- **Map references 1-7** (screenshots in the repo root, embedded by the untracked `ReferenceN.md` stubs; no source or licence recorded, and they look like stills from commercial games plus one illustration). Use them for qualities only, never as assets. 3 and 7: purple sky, green-lit ground, warm pumpkin glow, a path framed by dense foliage. 6 and 5: chunky oversized tombstones, spiked iron fence, faced trees glowing orange. 7: a winding dirt path with a picket fence and a crypt. 1, 2 and 4: woodland with tall trunks in rows, faces in bark, thorn stubs, fog banding at trunk height. **No reference shows a top-down layout.** `Map References.md` still says "empty" (not edited: `10 References/` is read-only for feature work).
- **SODT `RoundService` / `RoundState`:** reuse the leaf state module (breaks require cycles) and `GetServerTimeNow()` deadlines for HUD countdowns. Don't reuse the `task.wait` phase chain: it drifts and differs per server, and rotation must follow a shared clock.
- **Npc_template `TargetService` / `Zombie`:** reuse the Idle → Hunting → WindingDown state shape with frozen-record cleanup for pursuers. Don't reuse unlimited detection, Humanoid NPCs or damage: our monsters are anchored CFrame models (architecture budget: no Humanoid pathfinding), and retaliation must stay local and non-lethal. Theta* isn't needed for a short pursuit on open habitat ground.
- **`roblox-map`:** a JSON-spec prover for greybox layouts (P8 ring symmetry, reachability). It can't read our code-built world without an exporter. Optional offline use for the radial layout plan, but never its Studio bootstrap (ADR-0004).

## Hypotheses
- Radial plots shorten the worst return walk from about 500 to about 320 studs (33 s of a 75 s Common timer while carrying, vs 52 s today), so return pressure drops. *(med; measure with Reachability walk times, retune `returnSeconds` after a playtest)*
- Prebuilding the four modules at start and swapping their parents is cheaper and safer than building at the swap. *(med; measure part count and swap time in Studio)*

## Relevance to our game
Keep, improve, replace or defer:
| Item | Verdict |
|---|---|
| Plot contents (house tiers, pen, exhibits, beacon, trophies, track, editor) | **Keep** gameplay; **transform** to rotated plot frames |
| Weeping Angel, Bell Tower | **Improve** first (cemetery vignette) |
| Broken Hearse, Old Well, mausoleums, Sealed Crypt walls | **Keep** as cemetery scenery (no prompts); crypt access moves to house tier |
| Straight lantern road, plot avenue, west shortcut | **Replace** with the ring road and three hub gates |
| `GraveyardBuilder` lighting | **Replace** (purple sky, green haze, warm path lights) |
| Tombstone, tree, lantern, fence helpers | **Reuse** as the start of the shared asset kit |
| Clue chain, crypt landmark count, shortcut unlock, clue markers | **Remove/decouple** (data fields kept) |
| Spider and zombie creatures, habitat mechanics, detailed secondary habitats | **Defer** |

## Original implementation ideas
- One `PlotFrame` per plot (`CFrame.lookAt(centre, hub)`), and every plot-local point goes through `World.plotToWorld` / `worldToPlot`. Plot geometry is built in local space and then transformed as a whole.
- `HabitatModule` contract: id, footprint (disc r ≤ 112 inside the persistent hub wall), three gate connection points (fixed by the outer world), gate approach corridors that must stay clear, spawn zones (rects inside the disc), two landmark slots, `build()` into an unparented model, and validation at startup (vfx `Validator` idea).
- Rotation is a pure function of UTC time: `slot = floor(now / 900)`, `habitat = order[slot % 4 + 1]`, with warning and closing windows. It is unit-tested with an injected clock. The server only acts on phase changes.

## Recommendations (max 3)
1. Do the clue removal first: it deletes the crypt gate, the eject loop and investigate prompts that the module system would otherwise have to port into four habitats.
2. Change plot orientation through one transform helper and prove it with pure specs (no overlap, inward facing, local → world round trip) before any geometry polish.
3. Prove rotation safety with injected-clock specs plus a Studio scenario that swaps while a player carries, is mid-meter and is mid-chase.

## Needs human review
- The verdicts and sequencing above are a draft; [[ADR-0007-World-Retrofit-Direction]] holds the decisions that need jg.
- The map references have no recorded source or licence; their context notes are empty.
- Hypotheses are unmeasured.
