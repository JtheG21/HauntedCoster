---
id: TASK-0038
title: "Encounter Review Capture Guards"
type: task
project: GAME-002
status: approved
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0037
branch: task/TASK-0038-Encounter-Review-Capture-Guards
related:
  - "[[TASK-0031-Failed-Capture-Retaliation]]"
  - "[[TEST-20261012-16]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/task
---

# Encounter Review Capture Guards

## Goal
Close two gaps from the 2026-10-12 audit (T5). EncounterService (554 lines) had never been reviewed line by line, and capture start, a trust boundary, was only tested through Studio scenarios (AUDIT-009).

## Scope
- **In:** a line-by-line review of `EncounterService.luau`; a pure `CaptureRules.startRefusal`; `CaptureService.onCaptureStart` uses it; specs.
- **Out:** behaviour changes. Any defect the review finds becomes a follow-up for jg to approve.

## Files expected to change
- `games/haunted/src/shared/Rules/CaptureRules.luau`, `games/haunted/src/server/Services/CaptureService.luau`, `games/haunted/tests/CaptureRules.spec.luau`

## Acceptance criteria
- [x] AC1 EncounterService is reviewed line by line; findings are recorded below with file:line, and any defect becomes a follow-up rather than an unapproved change.
- [x] AC2 Capture-start guards move into a pure `CaptureRules.startRefusal` with the same checks, order and player-facing reasons; the claim and rate limit stay in `CaptureService`.
- [x] AC3 Specs cover the all-clear case, every refusal and the order; a negative control (one guard removed) fails them.
- [x] AC4 FullLoop, ExploitProbe, CarryGuard and Retaliation pass in Studio; `scripts/check.sh` passes.

- Evidence: AC1 in the implementation record below; AC2–AC4 in [[TEST-20261012-16]] and the diff.

## Tests
- **Automated:** `scripts/check.sh` (3 new `CaptureRules` specs).
- **Studio playtest procedure:** the four scenarios from Edit in the unsaved `Place1` via Rojo.

## Risks / notes
- Approved in chat on 2026-10-12 as T5 of the audit plan ("clean up the branch, then start T5").

---
## Implementation record
### EncounterService review (AC1)
No defects found. Checked:
- **Leave cleanup.** `start()` (`EncounterService.luau:544-551`) clears `claimedBy` and `progress` for a leaving player. A monster *fleeing* from that player is removed and respawned by `CaptureService`'s PlayerRemoving (`CaptureService.luau:824-842`); a *pursuing* one is released by `RetaliationService`'s `finish(player, "left")` (`RetaliationService.luau:267-273`).
- **Claims.** `claim` (`:270`) refuses a monster claimed by someone else; `startle` (`:313-331`) releases its claim only if no newer claim happened (`claimEpoch`), so a late timer can't drop another player's capture.
- **Inspect** (`:167-180`): the server re-checks distance (22 studs) and that the monster is alive; it only marks the journal and sends a card, so no rate limit is needed beyond the prompt.
- **Tweens.** `roam` (`:101-137`) only cancels its own tween; `tweenTo` (`:296`) cancels the previous one; `remove` cancels before destroying.
- **Spawn caps.** `fillZones` (`:244-261`) and `respawnEscaped` (`:473-487`) respect `maxAlive` (counting monsters being carried) and zone caps, and a capped rare skips the zone cap by design.
- **Swaps.** `clearWild` (`:491-500`) removes entries while iterating; assigning nil to an existing key during traversal is allowed in Luau.

Observations (not defects, no change):
- `spawnFleeing` (`:352-358`) picks the first active zone whose spawn list has the species, without checking its variant. An escaped Ashen capture may flee as if from a non-crypt zone. The zone only labels the encounter while it flees; `respawnEscaped` sends it home by variant (`HabitatRules.escapedRespawnZones`).
- `randomPoint` (`:96-99`) assumes zones wider than 8 studs; every configured zone is.

### Capture guards (AC2, AC3)
- Specs first: 3 new specs failed (no function). Negative control: `startRefusal` without the pursuing check failed exactly the "pursuing" case. Real rule: 124 passed.
- `onCaptureStart` now gathers the facts and calls `CaptureRules.startRefusal`. The order and reasons match the old `if` chain; the rate limit (first) and the claim (last) stay in the service.

## Audits
- [[AUD-20261012-TASK-0038-01]]: pass (Opus). Two minor findings fixed after the audit: a monster-guard order spec added (125 specs), and the cleanup line range corrected.

## Outcome
