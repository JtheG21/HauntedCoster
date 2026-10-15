---
id: RSH-20261014-Fighter-Juggle-And-Air-Combo-Video
title: "How to Make an Anime Fighter in Roblox: Full Combat System, EP6 Juggles and Air Combos (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/LjfSuv1UVeA
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/combat
---
# How to Make an Anime Fighter in Roblox: Full Combat System, EP6 Juggles and Air Combos (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how is a data-driven fighting system (frame data, cancel chains, juggle physics on the server) structured, and what is transferable to server-authoritative design? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make an Anime Fighter in Roblox: Full Combat System, EP6 Juggles and Air Combos", uploader MrWonderHow, 10:06 | https://youtu.be/LjfSuv1UVeA | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- Frame data (startup, active, recovery) per move is stored in a data table; target-combo animations are longer than the frame data, so the fix is to compute move completion from the animation length when it is longer. *(0:16-1:28)* (shown: a move list with fields anim, strength, damage, startup, active, recovery, hitstun, blockstun, knockback, cancelInto)
- Juggle config: launch speed (reach about jump height), a reduced gravity scale (about 10%), per-hit toss speed with decay, flip rotation, max hits, and a max juggle time to prevent infinite combos. *(2:01-3:08)* (speaker claim)
- Six air normals (light/medium/heavy arm and kick) share the same buttons when airborne; overhead height blocks only standing; an aerial finisher uses "spike" and "knockdown" flags. *(3:36-4:37)*
- Chain table: light cancels into medium or heavy, medium into heavy, heavy into the finisher; jump cancel lets a ground hit cancel into a jump. *(4:46-5:27)*
- Client: the fighter reads input and confirms hits; air hover gravity briefly holds the player on each hit. *(5:19-6:11)*
- Server: owns the dummy's state (in air, juggle hits, start time, vertical velocity), updates vertical velocity with reduced gravity each Heartbeat, rotates it, and only allows landing when falling. *(6:21-7:10)*
- Hit response priority: finisher first, then combo-target knockdown, then toss/juggle, then normal knockdown/repulse; order matters. *(7:10-8:16)* (speaker claim)
- Reaction animation name is sent with each hit. *(8:16-8:39)*

## Visual check needed
- 7:10-8:39: the response-priority order, which depends on code order and is easy to misread from captions.

## Hypotheses
- **H1: Moves as data tables with a cancel graph make combat easy to tune and review** *(confidence: medium)*. Test: express two moves in a data table and change them without code edits.
- **H2: A juggle needs hard caps (max hits, time) for fairness** *(confidence: medium)*.

## Relevance to our game
- Not scoped. The data-table approach mirrors how we keep config and pure rules in `shared/` ([[SYS-Haunted-Capture-Loop]] uses rule modules). A reusable idea is "state machine on the server with data-defined transitions".
- The server-owns-the-dummy design aligns with our authority rule.

## Original implementation ideas
- A server state-machine template where transitions are data (used only if a new interaction needs states).

## Recommendations (max 3)
1. Keep as background on data-driven state machines.

## Needs human review
- Unverified conclusions:
  - Full scripts are not legible.
  - Netcode behaviour for PvP (the video uses a dummy).
