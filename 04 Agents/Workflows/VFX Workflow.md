---
id: AGENT-WF-VFX
title: VFX Workflow
type: agent
status: approved
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/production
related:
  - "[[Task Intake]]"
  - "[[vfx_template]]"
---
# VFX and animation

## Gather
- **Purpose and trigger:** which game event fires it, who sees it (one player, nearby players, everyone), and what it must communicate.
- **References:** `10 References/04 Vfx/`, plus video analysed beat by beat ([[Reference Analysis Workflow]]).
- **Reusable code:** [[vfx_template]] (`VfxUtil`, `TemplatePrep`, `assetPool`, `CameraShake`) and the game's existing effects.

## Decide
- **Visual hierarchy:** the gameplay-critical signal (danger, success, a target) reads first and is never hidden by decoration.
- **Timing:** wind-up, peak and fade, in seconds. Note what it overlaps with (UI, sound, other effects).
- **States and variants:** start, loop, end and cancel. Plan every state the trigger can produce, including interrupted ones.
- **Camera and context:** first or third person, distance, dark or bright scenes, and many players at once.
- **Ownership:** the server decides that something happened; clients render the effect. Never let a client effect decide an outcome.
- **Method:**
  - `ParticleEmitter`, `Beam` and `Trail` for particles.
  - `TweenService` for property motion.
  - `Animator` with animation assets for characters. Uploading animations is jg's step.
  - Lights only where they read.

## Performance and mobile
- Cap emitter rates and lifetimes.
- Pool reused effects instead of creating and destroying them per event (vfx_template `assetPool`).
- Limit shadow-casting lights and large transparent quads; overdraw is the mobile killer.
- Disconnect and clean up on every exit path, including when a player leaves mid-effect.

## Acceptance
- A Studio check at gameplay distance, in the darkest and brightest relevant scenes, by screenshot or capture.
- Every state is triggered once: start, loop, end, cancel, and interruption.
- With 2 players, the effect shows for the intended audience only.
- No leftover instances after the effect: check instance counts before and after.
- Feel and readability are jg's manual check.
