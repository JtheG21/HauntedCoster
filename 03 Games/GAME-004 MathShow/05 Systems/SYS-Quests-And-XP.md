---
id: SYS-Quests-And-XP
title: "MathShow Quests and XP (v1)"
type: system
project: GAME-004
status: done
side: shared
source: []
related:
  - "[[TASK-0149-MathShow-Quests-XP-Rules]]"
  - "[[TASK-0150-MathShow-Quests-XP-Persistence-And-Services]]"
  - "[[TASK-0151-MathShow-Quests-XP-UI]]"
  - "[[TEST-20261107-01]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - game/system
---

# MathShow Quests and XP (v1)

Design: final after AUD-20261107-QUESTS-XP-DESIGN-01 and -02 (Codex). Implemented in v1 (TASK-0149, TASK-0150, TASK-0151, all
merged); live playtest [[TEST-20261107-01]] passed.

Design review: AUD-20261107-QUESTS-XP-DESIGN-01, DESIGN CHANGES REQUIRED, bullets applied 2026-11-07; no code yet.

Decisions: jg interview and design review 2026-11-07; see "Decisions after the review".

## Player level
- XP raises a level, capped at 50. Levelling cost to go from L to L+1: 100 + 35*(L-1) XP; ~46k XP to 50, ~8 weeks for a daily player.
- Rank stays tied to the Skill Test; level is separate.
- Unlocks (cosmetic only): a title every 5 levels (10 titles, placeholder names); a nameplate colour every 10 levels (5 colours, not rank colours).
  Titles and colours are data in a frozen LevelRewards table. XP is never spent.
- Shown on: the menu main card (level + XP bar) and an overhead nameplate (level + title, tinted by the colour), rendered by each client
  from server-set Player attributes (Level, Title, PlateColor). Post-finish add-ins (not v1): trails, menu/HUD themes.

## XP sources
- Play XP, server-awarded on validated events only: gameshow match finished as a participant 20 (+10 top 3), Blitz run finished 15,
  Skill Test finished 20, Glyph collected 1, Practice 0. Daily play-XP cap 400; quest XP is outside the cap.
- **Play cap:** Every eligible play command carries a day and nominal award, not an authoritative accepted amount. Inside the stored transition award min(nominal, max(0, 400 - storedAmount)) and increment both daily amount and XP by that same result. Quest XP bypasses this cap only through the conditional claim/bonus rules. Progress can continue after play XP hits the cap. Concurrent 390+10+10 must end at 400, not 410. Bound integers, XP totals and operation queue sizes; never derive pending deltas from displayed totals. (Codex design review 2026-11-07)
- **Reward eligibility:** Define finish as a normal terminal run in which the player submitted at least one correct answer; AFK timeout-only, aborted, error, spectator, bot and forfeit outcomes earn no finish XP or finish-quest progress. Apply the top-three bonus only to eligible Round participants with a positive score, (tie rule: see Consistency and balance). These are reward filters only. VS gives no XP and has no quests in v1 (jg, QX-D3). (Codex design review 2026-11-07)
- Glyph XP: see the Glyph XP decision below. Do not describe proximity checks as anti-teleport proof. (Codex design review 2026-11-07)
- Quest XP: easy 100, medium 150, hard 200; finishing all three that day gives a 100 bonus.

## Daily quests
- 3 per player per UTC day (day = floor(os.time()/86400)); reset at 00:00 UTC; picked deterministically from the pool, seeded by userId + day,
  one per category where possible, no duplicates.
- Pool categories: play modes (finish N gameshow matches / Blitz runs, take 1 Skill Test), math skill (accepted correct answers in Round, Blitz or SkillTest), glyphs (collect N, find 1 rare). Daily Challenge quest type dropped (no mode in v1).
- **Claims and bonus:** Identify a reward by player, day and stable slot generation, and identify the all-three bonus by player/day. Claim only a completed, matching, unclaimed stored quest; set claimed and add its reward in that transaction. Manual claim and rollover use this same predicate. Persist bonusGranted; grant the bonus in the transaction that first satisfies the chosen all-three condition. See the Bonus decision below. A second server's independent claim command must observe the persisted flags and award zero. (Codex design review 2026-11-07)
- **Progress:** Freeze event day and board/slot generation when the server accepts an event. Deduplicate handler dispatch per run/question/pickup, then use receipt-protected increments capped at the stored target; never replace the stored board from a local snapshot. Process commands in their recorded order. (Codex design review 2026-11-07)
- **Rollover and delayed saves:** Use one monotonic persisted epoch for the board and play cap. Before advancing, settle completed/unclaimed old-board rewards and its eligible bonus exactly once in that transition, then initialize the new day. Load/display alone never generates an unconditional XP grant. Reject old-day progress/play commands once that epoch is closed; never shift them to today's budget or resurrect a board. This deliberately permits lost late progress when a different server closes the day first; disclose and test that tradeoff. If lossless old-day progress is required, design bounded retained prior-day boards before implementation instead. (Codex design review 2026-11-07)

## Entry points
- Menu: a QUESTS screen (3 cards: description, progress bar, CLAIM), reached from the menu and by the Observatory "Daily" pad,
  which opens QUESTS instead of the locked "daily" secondary. Toasts: quest complete, level up.

## Persistence (deep)
- Profile schema v4 (migrated from v3): xp (integer total), daily epoch, playXpDay {day, amount}, quests {day, catalogVersion, boardRevision, slots[3]{id, generation, progress, claimed}, bonusGranted}.
  Level, title and colour are derived from xp (not stored).
- **Persistence operation:** Keep one ProfileService worker and the TASK-0141 retry/ambiguity rules. Freeze ordered server-generated quest/play commands in the save operation before yielding. In the same pure UpdateAsync transform, check the operation receipt, migrate/validate stored state, apply conditional commands, increment XP by the amount actually permitted, and write quest/cap state plus the receipt atomically. No rewards, notifications, random rolls or external calls inside callbacks. A callback replay recomputes from its supplied stored value; it must not mutate the command or session. Ack writes nothing. Never regenerate an abandoned or possibly committed command as a new sequence; new gameplay facts stay in the next operation. (Codex design review 2026-11-07)
- **Confirmation and failure:** QuestState distinguishes pending local projections from confirmed stored awards; attributes and durable unlocks derive from confirmed XP. On an ambiguous dropped operation, reconcile from stored state without manufacturing a replacement delta. Loading/readonly/newer-schema profiles cannot claim durable rewards; development memory mode is explicitly nonpersistent. A request after a server hop must go through the same stored predicates even if the load showed an unclaimed quest. Plan bounded buffering or explicit loss of pre-load events; do not let the quest subsystem yield the match loop. (Codex design review 2026-11-07)
- **Migration and cutover:** Migrate v3 to v4 idempotently, retaining settings, ranks/test timestamps, blitz best, glyph total, applied receipts and unknown fields. Initialize XP=0 and an empty/uninitialized daily state without awarding historical quests. Include stable slot generation, board/catalog version and bonusGranted in the schema; Verify v3 writers refuse a v4 value both at load and during an already-running UpdateAsync. Add a v4 gate mirroring the v3 freeze/admission-block/drain/verification record for every place and Studio writer; no migration writes until isolation is verified. Rollback after first v4 write must preserve and understand v4 state/receipts or keep writing disabled. (Codex design review 2026-11-07)

## Remotes (server creates all; validate type -> range -> ownership -> rate limit, debounce before any yield)
- **Remotes:** Use server-created RemoteEvents with exact payloads: QuestRequest has no arguments; QuestClaim carries a finite integer day, slot 1–3, expected board revision and slot generation (or an equivalent opaque server-issued slot identity). Ownership comes only from the invoking Player. Reject unknown fields, NaN, infinity, fractions, oversized/malformed payloads and stale identities. Proposed tunables: requests 4/10 seconds, mutations 2/second and 10/30 seconds per player, one bounded pending action per player. Validate type/range/ownership/rate before enqueue; mark pending before yielding. Return explicit pending, stale, rate, loading, unavailable and confirmed states, plus a monotonic state revision so old pushes cannot regress UI. Client supplies no XP, progress, rarity, time or reward ID selection. (Codex design review 2026-11-07)
- QuestState (server -> client): revision, board, progress, claimed, pending vs confirmed, xp, level, next-level XP (0 at level 50). ModePadOpen for the Daily pad carries "quests".

## Out of scope (v1)
Trails, menu/HUD themes, weekly quests, Daily Challenge mode, spending XP, leaderboards by level, publishing.

## v1 scope and delivery
- **v1 scope and delivery:** Rerolls, fast-answer/streak quests and VS rewards/quests are cut from v1 (jg, QX-D3). Start with a fixed versioned pool of qualified mode finishes, correct-answer counts and glyph pickups/one rare, with explicit targets/difficulties and guaranteed eligible alternatives. Keep manual claims plus rollover only if both use the single conditional transition. Derive level/title/colour from XP; no selection remote is needed for automatically equipped rewards. At level 50 define the bar as MAX and next-level requirement as absent/0. The formula totals 46,060 XP to 50. Earning ceiling: 400 play XP + 450 quest XP + 100 bonus = 950 XP/day, so at least 49 days to level 50. The ~8-week figure uses the earning assumption in the Decisions section. (Codex design review 2026-11-07)

## Final design (AUD-20261107-QUESTS-XP-DESIGN-02, applied verbatim; row QX-D4)
- **Eligible events and hooks:** Only Round, Blitz and SkillTest human answers contribute to correct-answer quests; Practice and VS contribute neither quest progress nor XP. Round emits accepted-answer facts after its existing question lock and one eligible completion at Results entry under a unique server-generated run ID. Blitz emits one eligible completion after its ended guard. Skill uses one reward-finalization guard shared by normal completion and departure during the already-finished final reveal; incomplete departure or error-generated termination earns no completion. Glyph emits one accepted pickup fact with server rarity after collection state mutation. Hook calls are non-yielding, bounded, and isolated with warn so quest failures do not change gameplay; duplicate invocations cannot generate new logical events. Freeze each fact's original day and run/question/pickup identity, not the eventual save day. (Codex design re-review 2026-11-07)
- **Blitz secrecy:** Keep correctness-dependent quest facts private to the Blitz run until its existing result boundary. Do not enqueue them into the persistence worker earlier, and do not include them in pending projections, QuestRequest replies, QuestState pushes, claims, toasts or Player attributes before that boundary. On ordinary finish, flush those facts once, retaining their original event days; closed-day facts may be dropped under the accepted rollover rule. For unfinished departure, discard unreleased answer-quest facts rather than publishing early. This is a reward-observation rule, not a change to Blitz's scoring, answer acknowledgement or timers. (Codex design re-review 2026-11-07)
- **Day and identity invariant:** Let dailyEpoch be the only authoritative day. If retaining quests.day and playXpDay.day for convenience, require both equal dailyEpoch in every valid stored v4 value and every candidate write. Advance all three in the same atomic rollover after settling the old board; never reset one independently. Initialize/resolve the deterministic board for an event's day before assigning that event's board identity; never attach tomorrow's event to yesterday's slot. Progress commands match stored day, catalogVersion, slot id and generation; claims additionally validate the expected board revision. A board revision identifies structural board changes; progress/claim state delivery uses a separate monotonic revision and must not silently retarget actions. (Codex design re-review 2026-11-07)
- **Catalog and damaged-state policy:** Define catalogs as immutable mappings from id to target, category, difficulty and XP. Keep every catalog needed by an unclosed stored board, or store immutable target/reward snapshots with its slots. Never reinterpret an existing slot under a changed definition. Unknown catalog or malformed existing v4 daily/award fields disable daily reward mutation with a warning; do not recreate an unclaimed board, clear bonusGranted, lower the cap amount or reset XP. Distinguish this from a genuine v3 migration, which initializes zero XP and uninitialized daily state. The implementation may preserve unaffected existing profile data while the daily feature is disabled. Fail closed rather than inventing a “repair” that grants rewards again. (Codex design re-review 2026-11-07)
- **Clock policy:** Keep jg's no-grace-period UTC decision. Proposed explicit maximum relative server skew: 300 seconds, independently documented for daily logic. A stored day ahead of the local day but no later than floor((nowWall + 300)/86400) is an expected adjacent-day board near midnight: preserve it, reject behind-day progress/play commands, and resume when local event day catches up. A stored epoch beyond that bound or invalid data disables daily mutation and warns. No epoch or budget moves backwards. Test both servers around midnight, a wall-clock jump and resumed operation after the tolerated discrepancy. The bound is an operating assumption, not evidence of a trusted global clock. (Codex design re-review 2026-11-07)
- **Ownership and integration:** Add games/mathshow/src/server/init.server.luau to TASK-0150 for explicit idempotent service startup in dependency order. Assign a concrete service integration scenario, for example games/mathshow/tests/multiclient/QuestsXp.luau, and docs/workflow/evidence/TASK-0150/ to T2; own any Studio hook file only if the plan changes it. Assign games/mathshow/src/shared/LevelRewards.luau to T1; assign games/mathshow/src/client/Hub/ModePadController.luau and a concrete nameplate renderer/startup path to T3. The T2 server pad mapping and T3 receiver must be delivered as one compatible payload change or deferred together until T3. Record sender/handler/receiver changes for new quest remotes in the task handoff. Remove the stale line that the already-added hook/remote/checklist paths are absent. These are proposed ownership changes only; none were made by this review. (Codex design re-review 2026-11-07)
- **Consistency and balance:** Replace “correct answers in any mode” with “accepted correct answers in Round, Blitz or SkillTest.” Proposed top-three tie rule: sort eligible positive-score Round participants by score descending then userId ascending, and award at most three bonuses, matching the existing deterministic ordering. To retain the stated 950/day ceiling, explicitly select one easy, one medium and one hard quest, while preserving category diversity where feasible; otherwise recompute the ceiling from the actual pool constraints. Supply the finite pool, targets and eligibility fallback in T1 before its implementation approval. Rewrite T2 acceptance as v4 ordered conditional commands through the TASK-0141 worker/receipts, with atomic claim/bonus/cap/rollover state, the exact schema names, migration/cross-server/failure/secrecy tests and the required audit. (Codex design re-review 2026-11-07)

## Tasks
T1 rules: XpRules, QuestRules (+ XpConfig, QuestConfig, LevelRewards), pure, with specs ([[TASK-0149-MathShow-Quests-XP-Rules]]).
T2 persistence and services: ProfileRules v4, XpService, QuestService, event hooks in Round/Blitz/SkillTest/Glyph services, remotes
([[TASK-0150-MathShow-Quests-XP-Persistence-And-Services]]). T3 UI: QUESTS screen, level card, toasts, nameplate, Daily pad wiring
([[TASK-0151-MathShow-Quests-XP-UI]]). Order T1 -> T2 -> T3.

## Decisions after the review (jg, 2026-11-07)
- Cut from v1 (post-finish backlog): rerolls; fast-answer (<3 s) and streak quests; VS XP and VS quests. VS stays playable and earns nothing.
- Clock: accept bounded early/late rollover at 00:00 UTC per server under the server-skew assumption; no grace period.
- Glyph XP: 1 XP per accepted pickup stays; teleport/rejoin farming is accepted as a risk bounded by the 400 play cap. No per-spawn limit.
- Bonus: all three completed, independent of claim order, paid once (bonusGranted).
- Earning assumption for ~8 weeks: ~780 XP/day (3 quests avg 150 + 100 bonus + ~230 play XP), so 46,060 XP to level 50 takes ~59 days.
- Unchanged: level cap 50, titles + nameplate colours, 3 daily per player, claim button, Daily pad opens QUESTS.

## Decisions changed by the re-review (need jg's OK)
Accepted by jg (row QX-D5): 300 s skew bound; tie rule score desc then userId asc; one easy, one medium, one hard quest per day.

## Open (Codex)
- Open (Codex): "assign ... a concrete nameplate renderer/startup path to T3". The re-review names no file, so T3 ownership has none yet.
- Open (Codex): "The original report's concurrency/migration verification matrix remains applicable after removing tests for cut features. Add explicit cases for no pre-result Blitz disclosure through QuestRequest/pending state, same-day duplicate claim versus rollover, mismatched day fields failing closed, unknown catalog, tolerated adjacent-day skew versus corrupt future day, startup exactly once and the Daily pad receiver accepting quests." No replacement bullet; goes into the T2 test plan.

## History
- 2026-11-07: brief registered (row QX-D1); waiting for the Codex design review and jg's plan rows.
- 2026-11-07: Codex design review applied (row QX-D2), pending jg's decisions.
- 2026-11-07: jg's post-review decisions applied (row QX-D3).
- 2026-11-07: jg decisions applied (row QX-D3); waiting for Codex re-review.
- 2026-11-07: Codex re-review bullets applied (row QX-D4); design final.
- 2026-11-07: implemented (v1): TASK-0149 rules, TASK-0150 persistence and services, TASK-0151 UI merged (PR #226 last);
  live playtest [[TEST-20261107-01]] passed in the private test place (row QX-PT1); status set to done (row QX-PT2).
