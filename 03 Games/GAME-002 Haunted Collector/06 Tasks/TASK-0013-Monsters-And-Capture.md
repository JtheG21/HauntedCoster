---
id: TASK-0013
title: Monsters and Capture
type: task
project: GAME-002
status: done
priority: high
risk: medium
owner: executor
milestone: M1
depends_on:
  - TASK-0011
  - TASK-0012
branch: task/TASK-0013-Monsters-And-Capture
created: 2026-10-11
updated: 2026-10-11
tags:
  - workflow/task
  - milestone/m1
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# TASK-0013: Monsters and Capture

## Goal
Data-driven roster of 4 monsters with variants, roaming in zones, inspectable, and catchable through one server-validated capture meter.

## Scope
- **In:** MonsterDefs/VariantDefs; part-built placeholder models with distinct silhouettes; EncounterService spawn/roam (CFrame stepper, zone-bound, cap 8); inspect card (name, rarity, variant, est. income); CaptureService meter sessions (server-timed, rarity zones, 3 misses -> flee).
- **Out:** Carry/return/containment (TASK-0014); Bell Wraith clue condition wiring beyond a config flag (TASK-0018).

## Files expected to change
- `games/haunted/src/shared/Config/MonsterDefs.luau`
- `games/haunted/src/shared/Config/VariantDefs.luau`
- `games/haunted/src/shared/Rules/CaptureRules.luau`
- `games/haunted/src/server/Services/EncounterService.luau`
- `games/haunted/src/server/Services/CaptureService.luau`
- `games/haunted/src/client/CaptureUI.client.luau`

## Acceptance criteria
- [ ] AC1: Monsters spawn only inside their zone and stay inside it; variant roll uses config chance and is visibly distinct and labelled
- [ ] AC2: Inspect shows name, rarity, variant and estimated income before capture
- [ ] AC3: Capture success/failure decided on the server from its own timing; forged/early/late/spammed release remotes are rejected (exploit probe recorded)
- [ ] AC4: Difficulty (zone width, speed) comes from rarity config
- [ ] AC5: CaptureRules and variant roll have passing specs
- [ ] AC6: scripts/check.sh passes

## Tests
- **Automated:** `scripts/check.sh` plus the specs named in the ACs (run in a fresh Play session, Server data model).
- **Studio playtest procedure:** in the GAME-002 place, start Play from a fresh profile and walk each AC in order. Record the results in the Implementation record, and say plainly which ones were not run.

## Risks / notes
Planned from [[INBOX-20261011-Haunted-Collector-Brief]]. Blocked on approval of [[ADR-0005-Haunted-Collector-Direction]]. Numbers come from the draft design and are tunable.

---
## Implementation record
*Prototype built in one integration commit, `17cb5ae` on `task/TASK-0011-Haunted-Scaffold-And-Player-Data`, which covers TASK-0011 to TASK-0018. The user approved building without per-task gates on 2026-10-11.*
- `scripts/check.sh`: all pass (StyLua, Selene, strict typecheck for both projects, Rojo builds, vault, Python tests).
- Unit specs: 37/37 pass headless ([[TEST-20261011-01]]). Server smoke in Run mode: clean.
- *(Superseded below: FullLoop has since run, see revision 1.)*

### Revision 1 (with TASK-0011, `5878f6d`, merged in PR #2)
- Judge tightened so blind mashing loses (shared constants in `CaptureRules`), the exploit probe goes through the real remotes from a client (`DevProbe`, ExploitProbe 11/11), the variant roll is a shared function with its own spec. Ashen is Crypt-only (ADR-0006 §2).
- Evidence: [[TEST-20261011-03]] (real-client captures), [[TEST-20261011-04]] (specs 48/0, FullLoop 56/56, ExploitProbe 11/11).
- Systems: [[SYS-Haunted-Player-Data]], [[SYS-Haunted-Capture-Loop]], [[SYS-Haunted-Ghost-Train]].

## Audits
- [[AUD-20261011-TASK-0013-01]]: fail (3 major), revision 1
- [[AUD-20261011-TASK-0013-02]]: **pass** (3 minor, 3 nit): the slack makes the real hit window wider than the drawn zone; ExploitProbe's mash check can't fail; zone caps total 10, not 8. Nits: Ashen really rolls at 27%, ping clamped at 0.3 s.

## Outcome
- **Result:** merge approved by jg on 2026-10-11 after [[AUD-20261011-TASK-0013-02]] passed.
- **Follow-ups (M1 polish / M2):** make the drawn green zone match the judged window (or bound the slack in a spec); give ExploitProbe's mash check a way to fail; reconcile the 8-monster scope with the zone caps (10); Ashen's real roll (27%) vs ADR-0006's 30%; the ping clamp at 0.3 s.
