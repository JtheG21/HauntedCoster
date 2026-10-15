---
id: RSH-20261014-Hitscan-Gun-System-Video
title: "How to Make a Gun System in Roblox Studio (Shooting, Reload & Ammo) (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/B4lr7VtTZN8
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/systems
  - research/combat
  - research/security
---
# How to Make a Gun System in Roblox Studio (Shooting, Reload & Ammo) (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
Systems variant: how does a tool-based gun keep the server authoritative (validation, hitscan, ammo) while the client handles aiming, animation and HUD? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make a Gun System in Roblox Studio (Shooting, Reload & Ammo)", uploader MrWonderHow, 8:44 | https://youtu.be/B4lr7VtTZN8 | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 5 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- The gun is a Tool with a mesh Handle, a "muzzle" attachment, and three sounds (shoot, reload, empty). *(0:18-1:42)*
- Settings are Tool attributes: magazine size, ammo, reserve, damage, fire rate, empty-sound ID, reload time; the attribute values replicate automatically, so the HUD needs no remote event. *(1:54-2:22, 5:16-5:59)* (Roblox-specific; the attribute list is shown in a frame)
- Two remote events only: fire (with the aim position) and reload. *(1:42-1:53)*
- The client sends only a world position; the server checks the tool is equipped, not reloading, the target is a valid Vector3, enough time has passed, and ammo remains, then performs the raycast from the muzzle. *(3:02-4:08)* (security-relevant, speaker claim)
- The raycast ignores the shooter and the weapon; damage applies to humanoid models that are not the shooter; the tracer is a visual neon ball only. *(4:08-4:46)*
- Reload is guarded by a flag and an attribute, moves rounds from reserve to magazine after a delay, and cannot start twice. *(4:46-5:23)*
- Client: input, mouse aim (mouse hit position), animations (idle looped, shoot, reload on action priorities), local feedback and a code-built HUD showing ammo/reserve/mode (shown: "4 / 12  RESERVE 48 AUTO [V]"). *(5:23-6:33)*
- Fire modes: semi-auto fires once per click; auto uses a loop with a token counter so old loops do not overlap new ones. *(6:53-7:19)*
- Test list: muzzle flash, tracer, health drops, auto mode toggles with V, empty-click then auto-reload, no firing while reloading, sky shots give a long tracer and no damage. *(7:43-8:33)* (speaker claim; shown)

## Visual check needed
- 3:23-3:50: the validation list in code, at full size, to see what the server does not check (for example max distance or line of sight).

## Hypotheses
- **H1: Sending only an aim position and recomputing everything server-side is the right trust model for client input** *(confidence: medium; it matches our own rules)*.
- **H2: Attribute-driven HUD removes a class of desync bugs** *(confidence: medium)*. Test: replace one remote-driven counter with an attribute.

## Relevance to our game
- This is the clearest pattern so far for our rule that every client input is validated and rate-limited (AGENTS.md "Safety rules"; [[ADR-0010-Client-Reported-Gaze]] is the closest approved precedent for client-reported data).
- Our capture loop already runs server-side ([[SYS-Haunted-Capture-Loop]]); the same shape (client sends intent, server validates equipped/range/cooldown) applies to any new interaction.
- Attributes as replicated state could simplify some HUD values, but our snapshot-based State remote is already established ([[SYS-Haunted-Player-Data]]).

## Original implementation ideas
- A short "input validation checklist" for any new remote: ownership, state, range, cooldown, type check, server-computed result.
- Evaluate attributes for simple counters only; do not replace the existing snapshot design.

## Recommendations (max 3)
1. Use the validation checklist when designing new remotes.
2. Do not change existing replication design on the strength of this video.

## Needs human review
- Unverified conclusions:
  - What the server does not check (distance, line of sight, ammo exploit paths).
  - Exact script (not legible).
