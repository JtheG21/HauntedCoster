---
id: TASK-0055
title: "Rare Capture Hookup"
type: task
project: GAME-002
status: in_progress
priority: low
risk: medium
owner: executor
depends_on:
  - TASK-0054
branch: task/TASK-0055-Rare-Capture-Hookup
related:
  - "[[TASK-0054-Rare-Capture-Finisher]]"
  - "[[ADR-0012-Sequence-Runner]]"
  - "[[REF-VFX-001-Cinematic-Energy-Sequence]]"
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/task
---

# Rare Capture Hookup

## Goal
Play the rare capture finisher ([[TASK-0054-Rare-Capture-Finisher]]) to the capturing player when they catch a Rare monster, and give them the finisher's time back on the carry timer. Cosmetic on the client; the one server change is the timer bonus and the notifying event.

## Scope
- **In:** a `CaptureFinisher` server-to-client event (`Net.luau`), `CaptureService` firing it on a Rare success and extending that carry's deadline by the finisher's length, a pure `CaptureRules.finisherSeconds`, a client module that validates the event and plays the finisher, an `essence` cue so the finisher supplies its own subject (the monster is removed the instant the capture succeeds), Lune specs.
- **Out (non-goals):** other players seeing it, a skip key, a Settings toggle for reduced effects, sound, any change to capture difficulty, rarity or income.
- **Keep unchanged:** capture meter judging, encounter spawning, retaliation, persistence, the economy.

## Intake
- **Category → workflow, depth:** VFX and systems → [[VFX Workflow]] / [[Systems Workflow]], standard (touches a server service and the Net contract)
- **References:** REF-VFX-001 (methods only, rights unverified); the finisher's plugin assets are third-party with **unverified rights** and block shipping, not this hookup.
- **Reuse:** the finisher from TASK-0054; existing `Remotes`/`State.remote` pattern; `CaptureRules` for the pure rule.
- **Confirmed decisions (jg, 2026-10-17):** the carry deadline gets the finisher's time added (recommended option); only the capturing player sees it; not skippable in this task; reduce-effects read from a `ReduceEffects` player attribute, no UI yet. Rare only (the Bell Wraith today).
- **Open for jg:** rights of the plugin assets; whether the finisher should also pause the Retaliation or Chase systems (neither is touched here).

## Files expected to change
- `games/haunted/src/shared/Net.luau`, `shared/Rules/CaptureRules.luau`, `shared/Rules/FinisherRules.luau`, `shared/Config/RareCaptureFinisher.luau`, `server/Services/CaptureService.luau`, `client/CaptureFinisher.luau`, `client/init.client.luau`, `client/Finisher/Effects.luau`, `client/Finisher/Orb.luau`, specs.

## Acceptance criteria
- [x] AC1 Lune: `finisherSeconds` is the finisher's duration for Rare and 0 otherwise; the payload check rejects bad species, non-Vector3, far-away and non-Rare events; the essence cue is valid and ends before the sequence.
- [x] AC2 A Rare success fires `CaptureFinisher` to that player only and extends that carry's `deadline`, `deadlineServer` and `returnSeconds` by the finisher's seconds; Common and Uncommon captures are unchanged. Evidence: Studio scenario or recorded test on the real place.
- [x] AC3 The finisher plays on the client from that event, restores the camera, field of view and movement lock afterwards, and the HUD carry bar still reads correctly. Evidence: Studio on the Haunted place.
- [ ] AC4 `scripts/check.sh` green; one audit (the Net contract and server timing are touched).

## Tests
- **Automated:** `scripts/check.sh`, Lune specs.
- **Studio:** the Haunted Collector place with `haunted.project.json` served from this checkout (`studio-preflight`), a fresh Play session, a Rare capture through the real meter or `CaptureService.requestRelease`.

## Risks / notes
Server timing change (carry deadline) and a new remote: both small, both audited. The finisher takes over the camera and movement for about 12.6 s, so the carry bonus matters. Needs the Haunted Collector place open in Studio; one assistant at a time.

---
## Implementation record
- Server: `CaptureService.onCaptureRelease` reads the monster's position and rarity before removing it, adds `CaptureRules.finisherSeconds(rarity)` to the carry via `startCarry`'s new `bonusSeconds` (so `deadline`, `deadlineServer` and `returnSeconds` all grow), and fires `CaptureFinisher` to that player. Client: `CaptureFinisher.mount()` (wired in `init.client.luau`) checks the payload with `FinisherRules.parsePayload` and plays the finisher from a hidden marker on the ground under the monster; the finisher brings its own captured-spirit sphere because the monster is gone.
- Studio evidence (2026-10-17), the real Haunted Collector place built from this branch (build 87a9b7f, unpublished so DataStores are in memory mode): a server script in the game's own context raised the test player's house tier (crypt gate) and drove the real capture meter through `CaptureService` on a Bell Wraith to success. The client received `CaptureFinisher` (species BellWraith), the camera went Scriptable and the movement lock was bound, then both were released; `FinisherFx` and the marker were gone; the server reported `isCarrying = true`; the HUD read "Carrying Bell Wraith: 126s" about 7 s after the capture and 107 s later with the bar at about 80%, consistent with 120 s plus the finisher's 12.8 s. A screen capture of the finisher in the real game was taken.
- Not exercised: a second player (only the capturing client receives the event by construction, `FireClient`), Common and Uncommon captures in Studio (covered by the Lune spec: `finisherSeconds` is 0), the finisher interrupted by death or a habitat swap.
- Testing notes: `require` in `execute_luau` creates separate copies of each service with empty state; to use the game's real services, run a Script placed in `ServerScriptService`. An unpublished place file runs DataStores in memory mode; the profile loads normally in that case.

## Audits

## Outcome
