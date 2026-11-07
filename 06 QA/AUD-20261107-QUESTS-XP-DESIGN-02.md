---
id: AUD-20261107-QUESTS-XP-DESIGN-02
title: MathShow Quests and XP design re-review
type: audit
project: GAME-004
status: done
task_id: TASK-0150
attempt: 2
verdict: fail
reviewer: codex
reviewed_commit: bf6294e5065a0d3403059151af693be6d2023cf5
created: 2026-11-07
updated: 2026-11-07
tags:
  - workflow/audit
---

# Audit: MathShow Quests and XP design re-review

## Scope

Read-only design follow-up to [[AUD-20261107-QUESTS-XP-DESIGN-01]], reviewing PR #222 (JtheG21/HauntedCoster), exact head bf6294e5065a0d3403059151af693be6d2023cf5, branch chore/quests-xp-design-review, checkout /Users/jg/Desktop/Rg1-worktrees/quests-xp-design-review. Reviewed the full brief, TASK-0150 JSON, prior report on this branch and PR file list/diffs. Inspected the existing server entry point and pad client allow-list, and TASK-0149/0151 ownership to verify delivery boundaries. No quest implementation exists here. Only this report is added, uncommitted; no design, source, queue, Git state or Studio changes.

## Requirements

Resolve or explicitly remove original F1–F7; remove contradictions; ensure v4 represents every atomic predicate; ensure task ownership covers delivery; identify blockers before implementation. Human cuts in the brief are treated as decisions: no rerolls, fast/streak quests or VS rewards/quests; bounded midnight skew accepted; glyph farming risk accepted within the play cap; bonus on all three completed.

## Evidence

- GitHub PR head and local HEAD both resolve to bf6294e5065a0d3403059151af693be6d2023cf5. PR contains the revised brief, prior audit, TASK-0150 note/JSON and the audit-name validator adjustment. No gameplay implementation is being approved.
- Prior audit on branch was read in full, SHA-256 c3cee3485b02b74602c6d8022ce35c72c432bf2330580ffc4f626387f6c0ad16. This re-review does not alter its verdict or history.
- Brief lines 36,46–48,58 now put cap consumption, conditional claims, bonus flags, rollover and receipt-protected commands inside the same stored transition. Independent sessions cannot each authorize an unconditional reward from their loaded snapshots under this design.
- Brief lines 56–60 add catalogVersion, boardRevision, slot generation and bonusGranted and retain the existing receipt/ambiguity contract. The fields can represent the required predicates, provided epoch equality, identity/version interpretation and fail-closed recovery are specified (R2).
- TASK-0150 now owns all four retained gameplay hook services, XpService/QuestService, Remotes, Net, ProfileService/Rules/Config, the release checklist and server pad/config files. It still omits startup wiring and service-level test/evidence files (R3). Separate T1/T3 ownership also has gaps.
- scripts/check.sh exited 0 at this head: all 13 active checks passed (format, lint, strict types, specs, Rojo build, map drift, JSON, task schema/queue, vault, references, skills and Python tests). Log: /tmp/quests-xp-design-02-check.log. No Studio, DataStore, fault injection or future quest implementation tests were performed. A green repository gate is not proof of this design's concurrency or secrecy behavior.

## Acceptance criteria

| Original finding | Re-review status | Evidence / remaining issue |
|---|---|---|
| F1: cross-server claims, rollover and play cap | Resolved at design level | Lines 36,46,48,58 require atomic predicates, XP and state plus operation receipt. No snapshot-authorized unconditional quest XP. |
| F2: bonus, progress merge, slot identity and reroll | Resolved in principle; contract detail remains | bonusGranted, capped additive commands and identities added. Reroll race is moot under jg's cut. R2 must define which fields form authoritative identity and how duplicate day fields agree. |
| F3: day attribution and skew | Partially resolved | Closed-day rejection and bounded skew accepted, but numeric skew/future-state rules remain undefined; R2. |
| F4: farming eligibility | Substantively resolved | Correct-answer finish filter, atomic cap, VS cut and explicit accepted glyph risk. Top-three tie policy is still an instruction to choose one; R4. |
| F5: migration and cutover | Partially resolved | Preservation and complete freeze/drain/compatible rollback are required. Actual checklist editing can occur in T2. Malformed v4 and unknown catalogs still lack a concrete safe policy; R2. |
| F6: remote identity and validation | Resolved at design level | Typed finite identifiers, stale checks, Player ownership, bounded rates/pending actions, outcomes and state revision specified. Freeze exact wire shapes in Net during planning; no reroll remote. |
| F7: hooks and secrecy | Partially resolved | Fast/streak timing and VS hooks are moot. Retained finish/answer hook placement and Blitz disclosure protection remain underspecified; R1. |

| Additional check | Result |
|---|---|
| No contradictions | Not met: stale ownership assertion, “any mode” versus VS cut, undefined difficulty ceiling; R4. |
| Schema sufficient | Required categories of fields exist; their invariants/recovery and catalog lifetime must be defined before implementing predicates; R2. |
| TASK-0150 owns every required file | Not met; R3. UI/pure-rule files belong in their respective tasks, not indiscriminately in T2. |
| Ready to implement | No. Resolve R1–R4 and obtain the separately required plan/schema approval; TASK-0150 remains backlog with no plan approval. |

## Findings

All line references refer to this exact reviewed head.

| # | Severity | Location | Evidence | Required correction |
|---|---|---|---|---|
| R1 | Major | SYS-Quests-And-XP.md:47,59,74–75 | “Publish ... notifications after the relevant answer secrecy boundary” does not prevent QuestState's progress/pending projections, a QuestRequest response, confirmed XP or a next-day rollover from exposing a correct Blitz answer before BlitzResult. Existing Blitz intentionally reveals correctness only at run end. The brief also does not carry forward the prior report's terminal-hook guards, including Skill final-reveal leave. | Buffer correctness-dependent Blitz quest commands until the run's existing result boundary; do not expose them through pending state, requests, attributes, claims or rollover first. Specify guarded answer/finish hooks and departure behavior. |
| R2 | Moderate | SYS-Quests-And-XP.md:42–49,56–60 | One authoritative epoch is required but schema stores a separate daily epoch, playXpDay.day and quests.day without an equality invariant or recovery policy. “Unexpected future/corrupt” and “define partial/malformed ... recovery” leave the actual decision unresolved. Accepted skew has no numeric bound. Slot id alone cannot recover target/reward if a catalog version disappears or changes. | Define a single day invariant, stored identity/catalog semantics and concrete fail-closed corruption/unknown-catalog policy; specify numeric skew tolerance and handling of a legitimate adjacent-day board. Clarify new-day board initialization before attaching progress identities. |
| R3 | Moderate | tasks/items/TASK-0150.json:8–25; SYS-Quests-And-XP.md:70,73–76 | The new services need explicit startup/remote-handler initialization, but server/init.server.luau is not owned. Only ProfileRules.spec is owned for testing; no service scenario/evidence location is assigned. T3 does not own client/Hub/ModePadController.luau, whose OPENABLE table currently rejects quests. T1 does not own the promised LevelRewards file; T3 has no explicit nameplate renderer file. | Assign startup and service-test/evidence paths to T2, and the pad receiver/nameplate/LevelRewards paths to the appropriate T1/T3 owners. Define the dependency boundary for changing the pad payload. Do not claim T2 must own all UI/rule files. |
| R4 | Minor, specification consistency | SYS-Quests-And-XP.md:37,44–45,70; tasks/items/TASK-0150.json:32 | The brief still says the queue omits hook/remote/checklist ownership, although the JSON now includes it. Correct answers “in any mode” includes VS despite the explicit cut. Top-three text says “state the tie policy” instead of supplying one. A 450 quest-XP ceiling is asserted without requiring one easy/medium/hard quest; distinct categories do not impose distinct difficulties. Queue acceptance still describes v4 as “saved as deltas” and names xpDay rather than the brief's playXpDay. | Replace stale assertions with the actual allocation, name the eligible modes, pick a tie rule, define the difficulty distribution or correct the earning ceiling, and describe ordered conditional commands in acceptance. |

## Verdict

- [ ] Pass
- [x] Changes requested
- [ ] Blocked

DESIGN CHANGES REQUIRED. The core over-credit architecture is corrected and jg's cuts remove substantial complexity. Remaining corrections are targeted contract and delivery decisions; no new session-lock system, extra reward source or reversal of the cuts is requested.

## Follow-up

### Replacement bullets

- **Eligible events and hooks:** Only Round, Blitz and SkillTest human answers contribute to correct-answer quests; Practice and VS contribute neither quest progress nor XP. Round emits accepted-answer facts after its existing question lock and one eligible completion at Results entry under a unique server-generated run ID. Blitz emits one eligible completion after its ended guard. Skill uses one reward-finalization guard shared by normal completion and departure during the already-finished final reveal; incomplete departure or error-generated termination earns no completion. Glyph emits one accepted pickup fact with server rarity after collection state mutation. Hook calls are non-yielding, bounded, and isolated with warn so quest failures do not change gameplay; duplicate invocations cannot generate new logical events. Freeze each fact's original day and run/question/pickup identity, not the eventual save day.
- **Blitz secrecy:** Keep correctness-dependent quest facts private to the Blitz run until its existing result boundary. Do not enqueue them into the persistence worker earlier, and do not include them in pending projections, QuestRequest replies, QuestState pushes, claims, toasts or Player attributes before that boundary. On ordinary finish, flush those facts once, retaining their original event days; closed-day facts may be dropped under the accepted rollover rule. For unfinished departure, discard unreleased answer-quest facts rather than publishing early. This is a reward-observation rule, not a change to Blitz's scoring, answer acknowledgement or timers.
- **Day and identity invariant:** Let dailyEpoch be the only authoritative day. If retaining quests.day and playXpDay.day for convenience, require both equal dailyEpoch in every valid stored v4 value and every candidate write. Advance all three in the same atomic rollover after settling the old board; never reset one independently. Initialize/resolve the deterministic board for an event's day before assigning that event's board identity; never attach tomorrow's event to yesterday's slot. Progress commands match stored day, catalogVersion, slot id and generation; claims additionally validate the expected board revision. A board revision identifies structural board changes; progress/claim state delivery uses a separate monotonic revision and must not silently retarget actions.
- **Catalog and damaged-state policy:** Define catalogs as immutable mappings from id to target, category, difficulty and XP. Keep every catalog needed by an unclosed stored board, or store immutable target/reward snapshots with its slots. Never reinterpret an existing slot under a changed definition. Unknown catalog or malformed existing v4 daily/award fields disable daily reward mutation with a warning; do not recreate an unclaimed board, clear bonusGranted, lower the cap amount or reset XP. Distinguish this from a genuine v3 migration, which initializes zero XP and uninitialized daily state. The implementation may preserve unaffected existing profile data while the daily feature is disabled. Fail closed rather than inventing a “repair” that grants rewards again.
- **Clock policy:** Keep jg's no-grace-period UTC decision. Proposed explicit maximum relative server skew: 300 seconds, independently documented for daily logic. A stored day ahead of the local day but no later than floor((nowWall + 300)/86400) is an expected adjacent-day board near midnight: preserve it, reject behind-day progress/play commands, and resume when local event day catches up. A stored epoch beyond that bound or invalid data disables daily mutation and warns. No epoch or budget moves backwards. Test both servers around midnight, a wall-clock jump and resumed operation after the tolerated discrepancy. The bound is an operating assumption, not evidence of a trusted global clock.
- **Ownership and integration:** Add games/mathshow/src/server/init.server.luau to TASK-0150 for explicit idempotent service startup in dependency order. Assign a concrete service integration scenario, for example games/mathshow/tests/multiclient/QuestsXp.luau, and docs/workflow/evidence/TASK-0150/ to T2; own any Studio hook file only if the plan changes it. Assign games/mathshow/src/shared/LevelRewards.luau to T1; assign games/mathshow/src/client/Hub/ModePadController.luau and a concrete nameplate renderer/startup path to T3. The T2 server pad mapping and T3 receiver must be delivered as one compatible payload change or deferred together until T3. Record sender/handler/receiver changes for new quest remotes in the task handoff. Remove the stale line that the already-added hook/remote/checklist paths are absent. These are proposed ownership changes only; none were made by this review.
- **Consistency and balance:** Replace “correct answers in any mode” with “accepted correct answers in Round, Blitz or SkillTest.” Proposed top-three tie rule: sort eligible positive-score Round participants by score descending then userId ascending, and award at most three bonuses, matching the existing deterministic ordering. To retain the stated 950/day ceiling, explicitly select one easy, one medium and one hard quest, while preserving category diversity where feasible; otherwise recompute the ceiling from the actual pool constraints. Supply the finite pool, targets and eligibility fallback in T1 before its implementation approval. Rewrite T2 acceptance as v4 ordered conditional commands through the TASK-0141 worker/receipts, with atomic claim/bonus/cap/rollover state, the exact schema names, migration/cross-server/failure/secrecy tests and the required audit.

The original report's concurrency/migration verification matrix remains applicable after removing tests for cut features. Add explicit cases for no pre-result Blitz disclosure through QuestRequest/pending state, same-day duplicate claim versus rollover, mismatched day fields failing closed, unknown catalog, tolerated adjacent-day skew versus corrupt future day, startup exactly once and the Daily pad receiver accepting quests. No re-audit approval substitutes for jg's pending implementation and schema approvals.

Only this note is created and left uncommitted. Brief/queue revisions and implementation remain pending with their owners.
