---
id: AGENT-WF-Audio
title: Audio Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[Sound References]]"
  - "[[External Skills]]"
---
# Audio and sound design

**Claude cannot hear audio.** It can find, measure and wire sounds; a human chooses by ear.

## Gather
- **Purpose of each sound:** emotional (mood, tension) or functional (confirm, warn, locate).
- **Character:** a few words per role, plus any references in `10 References/03 Sounds/` ([[Sound References]]).
- **Trigger table:** for each role, the game event, who hears it (the local player, nearby players, everyone), whether it loops, and what it must not mask.

## Decide
- **Spatial or 2D:**
  - A `Sound` parented to a part is 3D: set `RollOffMode` and `RollOffMaxDistance`.
  - A sound in `SoundService` or the player's GUI is 2D. Use 2D for UI and personal feedback.
- **Layering and variation:** repeated sounds get slight `PlaybackSpeed` or volume jitter, or 2 or 3 variants, so they don't fatigue.
- **Mixing:** volume tiers by role (ambience lowest, then UI, then feedback, then warnings), `SoundGroup`s per category, and ducking only if needed.
- **Player control:** a mute toggle or volume setting where the game calls for one.
- **Licensing:** use free Creator Store assets by ID. No uploads without approval. Credit the creators in the area index.

## Build
1. **Source with the `roblox-sfx` skill** (no uploads, no API key):
   1. A spec with a length band per role.
   2. Candidates.
   3. Probe in Studio: `IsLoaded` and the measured `TimeLength`. The listing duration is untrustworthy.
   4. A shortlist of up to 3 per role.
2. **A human picks by ear** from the shortlist (in Studio, a labelled tour).
3. **Organise:**
   - One data module (a SoundBank: role to ID, length, volume, looped, credit). No asset ID appears anywhere else in the code.
   - A client helper that fails silent (a missing sound never breaks gameplay).
4. **Drive sounds from existing events.** Audio must not add server logic or remotes unless the task says so.

## Performance
- Limit concurrent sounds, and don't create a `Sound` per event; reuse or pool them.
- Loop only ambience.
- Preload the important short sounds (`ContentProvider:PreloadAsync`) when first-play latency matters.

## Acceptance
- Every role is filled by a loaded asset within its length band, or explicitly left empty.
- A spec checks that the bank is well formed: every role has an ID, a positive length and a volume within range.
- In a Studio session, each trigger fires its sound once, the mute toggle works, and nothing errors when a sound fails to load.
- The mix and fit are jg's manual check. The credits are listed in [[Sound References]].
