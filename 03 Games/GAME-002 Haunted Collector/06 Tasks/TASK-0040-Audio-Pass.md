---
id: TASK-0040
title: "Audio Pass"
type: task
project: GAME-002
status: in_progress
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0039
branch: task/TASK-0040-Audio-Pass
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[Sound References]]"
created: 2026-10-12
updated: 2026-10-13
tags:
  - workflow/task
---

# Audio Pass

## Goal
Give the game's existing moments sound with free Creator Store audio sourced by `roblox-sfx` (no uploads, no API key). Resolves Game Design open question 4 (source audio rather than ship silent). Audit plan AUDIT-010 (audio part).

## Scope
- **In:** a sound spec; Studio measurement of candidates in `Place1`; a client-only `SoundBank` + `Sfx` helper; hooks on existing client events (`CaptureEnded`, `RideState`, `Toast`, State changes, habitat changes, UI buttons); a HUD mute toggle; specs; `Sound References` rows.
- **Out:** music, VFX, art, uploads, paid assets, server code and remotes.

## Files expected to change
- `games/haunted/audio/sfx-spec.json` (new), `games/haunted/src/shared/Config/SoundBank.luau` (new), `games/haunted/src/client/Sfx.luau` (new), client hooks in `init.client.luau` and `UI/*`, `games/haunted/tests/SoundBank.spec.luau` (new), `10 References/03 Sounds/Sound References.md`.

## Acceptance criteria
- [ ] AC1 Every spec role is filled by a free Creator Store asset that loaded in Studio with a measured length inside its band; no music, no uploads.
- [ ] AC2 jg chose each sound by ear from a measured shortlist of up to 3 during a Studio sound tour.
- [ ] AC3 Sound is client-only: a `SoundBank` data module and an `Sfx` helper that fails silent, driven by existing client events; no server or remote changes.
- [ ] AC4 A HUD mute toggle silences all game sound; specs cover the bank data and role mapping; `scripts/check.sh` passes.
- [ ] AC5 A 2-player Studio session plays the sounds at the right moments with no script errors; chosen ids and creators are listed in [[Sound References]].

## Tests
- **Automated:** `scripts/check.sh` (new `SoundBank.spec.luau`).
- **Studio playtest procedure:** `rojo serve haunted.project.json` into `Place1`; probe and report from Edit (roblox-sfx); jg listens to the shortlist tour; then a 2-player Test session with normal play.

## Risks / notes
- **Paused 2026-10-13 by jg** in chat ("pause audio") so TASK-0041 Interactive Haunted Trees can go first. That task runs in its own worktree (`/Users/jg/Desktop/Rg1-worktrees/TASK-0041`). This checkout's uncommitted TASK-0040 work (`games/haunted/audio/`, this note, the queue entry) is left as it was. The queue status stays `in_progress`, because the orchestrator has no paused state.
- Plan approved by jg in chat on 2026-10-12 ("accept your recommendations, start the audio task"): ambience only, no music (the art revamp should set the final mood); a HUD mute toggle; Claude shortlists, jg picks by ear; one shared monster sound set.
- References: `10 References/03 Sounds` is empty, so picks follow the Game Design and the current atmosphere.
- Neither Claude nor the skill can hear audio; everything automatic comes from the listing and the measured `TimeLength`. Taste is jg's.
- Creator Store audio used by id stays subject to Roblox's terms and moderation; an asset can be removed later. `Sfx` fails silent if one is.

---
## Implementation record

## Audits

## Outcome
