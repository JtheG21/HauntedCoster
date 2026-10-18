---
id: TASK-0054
title: "Rare Capture Finisher"
type: task
project: GAME-002
status: done
priority: low
risk: low
owner: executor
depends_on:
  - TASK-0053
branch: task/TASK-0054-Rare-Capture-Finisher
related:
  - "[[ADR-0012-Sequence-Runner]]"
  - "[[TASK-0053-Sequence-Runner]]"
  - "[[REF-VFX-001-Cinematic-Energy-Sequence]]"
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/task
---

# Rare Capture Finisher

## Goal
The first consumer of the sequence runner: a 12.5 s cosmetic finisher for a rare monster capture, the REF-VFX-001 experiment. One interview, one implementation prompt, one-prompt ledger. Not wired into the live capture flow in this task.

## Scope
- **In:** `shared/Config/RareCaptureFinisher.luau` (sequence data), `client/RareCaptureFinisher.luau` (handlers and `play`), a Lune spec for the data, a Play scenario for cleanup, a Studio-only trigger for judging.
- **Out (non-goals):** hooking into capture success, server changes, sound, Resource Boy textures (upload question open), copying the clip's characters, layout or assets.
- **Keep unchanged:** server files, `Net.luau`, capture rules, the runner core.

## Intake (reference brief)
- **Category → workflow, depth:** VFX → [[VFX Workflow]], standard
- **References:** REF-VFX-001 (approved quality floor; rights: methods only, reference-only class), REF-CODE-001 (methods only, AGPL, no code). Roqer methods used in our own words: purpose, palette, contrast, layering, timing, cleanup.
- **Qualities taken (from the Intent / Dense review):** layered timing across three colour phases joined by two inversion bursts; constantly changing camera; pillar and lightning stack at the peak; brightness and spectacle. **Not taken:** the clip's characters, layout, assets, audio.
- **Evidence plan:** Lune spec (data valid, flash-rate bound computed from the cue table); Studio scenario (cleanup to baseline, emitter budget); camera and look judged by jg on a client run; flash check by data (large luminance transitions per second from the cue table, at most 3 flashes) because screen-take gating was waived on TASK-0053.
- **Interview answers (jg, 2026-10-17):** subject rare capture finisher; three phases with a haunted palette (cold blue-green charge, white pillar peak, purple release), two inversion bursts under the flash limit; short cinematic cuts with player input locked about 12 s and restored by cleanup; no sound this round; reduce-effects option included. Textures: built-in particles and parts only (Resource Boy upload question open).
- **Ambition proposals:** none added.
- Brief review: 0 additions proposed, 0 accepted by jg, interview 4 questions

## Acceptance criteria
- [x] AC1 Lune spec: the finisher validates; length is 10-15 s; large-flash cues are at most 2 and at least 2 s apart; reduced mode drops flash and shake strength.
- [x] AC2 Play scenario: after finish and after cancel, descendants of the effect folder and Lighting return to baseline; no emitters left; peak emitters within budget.
- [x] AC3 jg judges one client run of the finisher against REF-VFX-001's beats (phases, bursts, camera variety) and gives a verdict on the floor; ledger recorded. Evidence: jg, 2026-10-17, after running it in Place1 several times and directing the orb, texture and release changes: "this is good". That is an approval of the look, not a formal floor comparison; the asset rights stay open.
- [x] AC4 `scripts/check.sh` green; one audit; no server file changed.

## Tests
- **Automated:** `scripts/check.sh`; Lune spec.
- **Studio:** `studio-preflight`; fresh Play session; scenario, then a client run for jg.

## Risks / notes
Client-only. Input lock must always be released, including on cancel and errors (runner cleanup guarantees it).

---
## Implementation record
- Built 2026-10-17: sequence data, `SequencePlayer` handlers, pure orbit rules (exponential spin and tightening, tumbling on all three axes, tested in Lune), reduce-effects mode, Play scenario (35 checks, real Heartbeat clock included, cancel at three points).
- Orb: orbits the monster, speeding up and tightening exponentially (spin 1.2 to 18 rad/s), then breaks off at the player. jg judged the normal version good (2026-10-17).
- Plugin assets (jg, 2026-10-17: use the VFX Studio plugin's meshes and textures): ids read from the plugin in Place1 into `shared/Config/FinisherAssets.luau` (5 meshes, 7 textures: rune circle, flare, lightning, swirl). **Rights unverified**: third-party uploads reached through a plugin, no licence checked. Anything that fails to load is skipped. Visual check in Place1 by Claude (screenshots at charge, peak, release) shows the rune disc, pillar, shockwave rings, lightning, orb glow and wind ring working.
- Practice parts `PracticeAura` remain in the scratch place Place1 only.

## Audits
- Audit 1 (2026-10-17, auditor, Opus, commit 905e7df): **changes requested**, 2 major, 11 minor, 5 nit. Revision 1 fixed: second `play()` while one runs (one active run, per-run lock name, `PlayerModule` controls disabled and re-enabled); reduce-effects now reaches the rune, shockwave, pillar light and bolts; camera cuts no longer reset the camera for a frame; parent-last for Lighting effects; `Meshes.preload` waits instead of returning early; orb smaller than its tightest orbit, core capped, NaN-safe exit velocity, impact no longer cut short (orb cue 4.4 s, sequence 12.8 s); camera follows the anchor; dead code, unused params and the unused `snap` rule removed; shared `Ctx` type and named constants. Revision 2 (after the delta audit): tint colour is now validated before Lighting is touched (revision 1's claim of that fix had silently not applied; found by the delta audit), and `Meshes.preload` can no longer leave waiting callers stuck. Not fixed: effects run on `os.clock`, so `step()`-driven scenario runs do not exercise the orb motion (documented; the real-clock run does).
- Client check on a real client (Place1, 2026-10-17): overlapping runs leave one lock; cancel and a natural reduced run both restore camera type, field of view and the lock; 35/35 cleanup scenario.
- Delta re-audit (2026-10-17, auditor, Sonnet, 905e7df..28ef5aa): **pass with notes**; every first-audit finding fixed except the tint ordering and a preload hang risk, both fixed after in revision 2.
- Visual defect found and fixed in review: the core glow used a texture with an opaque dark background, which showed as a black box on a billboard; now an alpha-correct texture (`glow` is for additive particles only).

## Outcome
Merged with jg's approval (2026-10-17). Open: rights of the VFX Studio plugin assets (`FinisherAssets.luau`) before anything ships; not wired into the capture flow; effects run on `os.clock` so stepped scenario runs do not exercise orb motion.
