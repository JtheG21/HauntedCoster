---
id: SYS-Quests-And-XP
title: "MathShow Quests and XP (v1)"
type: system
project: GAME-004
status: proposed
side: shared
source: []
related:
  - "[[TASK-0149-MathShow-Quests-XP-Rules]]"
  - "[[TASK-0150-MathShow-Quests-XP-Persistence-And-Services]]"
  - "[[TASK-0151-MathShow-Quests-XP-UI]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - game/system
---

# MathShow Quests and XP (v1)

Decisions: jg interview 2026-11-07. Defaults marked (D) are Claude's picks, open to change in the design review.

## Player level
- XP raises a level, capped at 50. Levelling cost to go from L to L+1: 100 + 35*(L-1) XP (D); ~46k XP to 50, ~8 weeks for a daily player.
- Rank stays tied to the Skill Test; level is separate.
- Unlocks (cosmetic only): a title every 5 levels (10 titles, placeholder names) (D); a nameplate colour every 10 levels (5 colours, not rank colours) (D).
  Titles and colours are data in a frozen LevelRewards table. XP is never spent.
- Shown on: the menu main card (level + XP bar) and an overhead nameplate (level + title, tinted by the colour), rendered by each client
  from server-set Player attributes (Level, Title, PlateColor). Post-finish add-ins (not v1): trails, menu/HUD themes.

## XP sources
- Play XP, server-awarded on validated events only: gameshow match finished as a participant 20 (+10 top 3), Blitz run finished 15,
  VS match finished 15 (+10 win), Skill Test finished 20, Glyph collected 1, Practice 0 (D). Daily play-XP cap 400 (D); quest XP is outside the cap.
- Quest XP: easy 100, medium 150, hard 200; finishing all three that day gives a 100 bonus (D).

## Daily quests
- 3 per player per UTC day (day = floor(os.time()/86400)); reset at 00:00 UTC; picked deterministically from the pool, seeded by userId + day,
  one per category where possible, no duplicates.
- Pool categories: play modes (finish N gameshow matches / Blitz runs / VS matches, take 1 Skill Test), math skill (N correct answers in any
  mode, a 5-answer streak, N answers under 3 s), glyphs (collect N, find 1 rare). Daily Challenge quest type dropped (no mode in v1).
- Progress counts only server-validated events (same sources as play XP). Progress caps at the target.
- Claim: a finished quest shows CLAIM; the server grants its XP once. Finished-but-unclaimed quests are granted at rollover or next load (D).
- Reroll: 1 free per day, unfinished quests only, the replacement comes from the pool and isn't already on the board.
- Clock: a stored quest day never goes backwards; if a server's day is behind the stored day (skew), the stored board stands.

## Entry points
- Menu: a QUESTS screen (3 cards: description, progress bar, CLAIM / REROLL), reached from the menu and by the Observatory "Daily" pad,
  which opens QUESTS instead of the locked "daily" secondary. Toasts: quest complete, level up.

## Persistence (deep)
- Profile schema v4 (migrated from v3): xp (integer total), playXpDay {day, amount}, quests {day, slots[3]{id, progress, claimed}, rerolled}.
  Level, title and colour are derived from xp (not stored).
- XP and quest changes go through the TASK-0141 exactly-once save path as deltas. Ambiguity rule unchanged: no covering receipt = drop the delta
  (under-credit, warn). Older (v3) writers refuse v4 profiles; add a "profile schema v4 cutover" gate to PUBLISH-CHECKLIST.md.

## Remotes (server creates all; validate type -> range -> ownership -> rate limit, debounce before any yield)
- QuestRequest() -> server sends QuestState to that player. QuestClaim(slot: 1..3). QuestReroll(slot: 1..3). QuestState (server -> client):
  board, progress, claimed, rerollUsed, xp, level, next-level XP. ModePadOpen for the Daily pad carries "quests".

## Out of scope (v1)
Trails, menu/HUD themes, weekly quests, Daily Challenge mode, spending XP, leaderboards by level, publishing.

## Tasks
T1 rules: XpRules, QuestRules (+ XpConfig, QuestConfig, LevelRewards), pure, with specs ([[TASK-0149-MathShow-Quests-XP-Rules]]).
T2 persistence and services: ProfileRules v4, XpService, QuestService, event hooks in Round/Blitz/Vs/SkillTest/Glyph services, remotes
([[TASK-0150-MathShow-Quests-XP-Persistence-And-Services]]). T3 UI: QUESTS screen, level card, toasts, nameplate, Daily pad wiring
([[TASK-0151-MathShow-Quests-XP-UI]]). Order T1 -> T2 -> T3.

## History
- 2026-11-07: brief registered (row QX-D1); waiting for the Codex design review and jg's plan rows.

## Design review replacements ([[AUD-20261107-QUESTS-XP-DESIGN-01]])
Proposed by the Codex review, applied verbatim as row QX-D2; pending jg's decisions.

- **Persistence operation:** Keep one ProfileService worker and the TASK-0141 retry/ambiguity rules. Freeze ordered server-generated quest/play commands in the save operation before yielding. In the same pure UpdateAsync transform, check the operation receipt, migrate/validate stored state, apply conditional commands, increment XP by the amount actually permitted, and write quest/cap state plus the receipt atomically. No rewards, notifications, random rolls or external calls inside callbacks. A callback replay recomputes from its supplied stored value; it must not mutate the command or session. Ack writes nothing. Never regenerate an abandoned or possibly committed command as a new sequence; new gameplay facts stay in the next operation.
- **Claims and bonus:** Identify a reward by player, day and stable slot generation, and identify the all-three bonus by player/day. Claim only a completed, matching, unclaimed stored quest; set claimed and add its reward in that transaction. Manual claim and rollover use this same predicate. Persist bonusGranted; grant the bonus in the transaction that first satisfies the chosen all-three condition. Recommendation: all three completed, independent of button order. A second server's independent claim command must observe the persisted flags and award zero.
- **Progress and reroll:** Freeze event day and board/slot generation when the server accepts an event. Deduplicate handler dispatch per run/question/pickup, then use receipt-protected increments capped at the stored target; never replace the stored board from a local snapshot. Process commands in their recorded order. If retained, reroll atomically requires matching day/revision/slot, unfinished status and unused daily allowance; choose its replacement deterministically from a frozen versioned pool, reset its progress, consume the allowance and increment the slot generation. Reject a stale action; never retarget it. Define that old-generation progress is discarded after a committed reroll rather than applied to the replacement.
- **Rollover and delayed saves:** Use one monotonic persisted epoch for the board and play cap. Before advancing, settle completed/unclaimed old-board rewards and its eligible bonus exactly once in that transition, then initialize the new day. Load/display alone never generates an unconditional XP grant. Reject old-day progress/play commands once that epoch is closed; never shift them to today's budget or resurrect a board. This deliberately permits lost late progress when a different server closes the day first; disclose and test that tradeoff. If lossless old-day progress is required, design bounded retained prior-day boards before implementation instead.
- **Clock:** Server wall time selects the event's UTC day; client time is ignored. The 300-second receipt skew allowance is not a trusted UTC oracle. Choose explicitly between accepting bounded early/late rollover under a documented server-skew assumption, or delaying rollover by a configured grace period (which changes the advertised midnight reset). Behind-day servers cannot earn against an ahead board until their event day catches up. Unexpected future/corrupt stored epochs disable daily mutation with a warning rather than silently advancing further or resetting backwards. Monotonic local time remains the answer/retry clock.
- **Play cap:** Every eligible play command carries a day and nominal award, not an authoritative accepted amount. Inside the stored transition award min(nominal, max(0, 400 - storedAmount)) and increment both daily amount and XP by that same result. Quest XP bypasses this cap only through the conditional claim/bonus rules. Progress can continue after play XP hits the cap. Concurrent 390+10+10 must end at 400, not 410. Bound integers, XP totals and operation queue sizes; never derive pending deltas from displayed totals.
- **Reward eligibility:** Define finish as a normal terminal run in which the player submitted at least one correct answer; AFK timeout-only, aborted, error, spectator, bot and forfeit outcomes earn no finish XP or finish-quest progress. Apply the top-three bonus only to eligible Round participants with a positive score, and state the tie policy. These are reward filters only. For v1, recommend no VS XP/quests; if retained, exclude forfeit rewards and specify persisted daily per-opponent diminishing/capped rewards, including rematches and server hops. Account age or a second account is not proof of an independent opponent.
- **Answer/glyph rules:** Count only accepted correct human answers, once per run/question; Practice is excluded from both XP and quest progress unless explicitly enabled. Fast means correct and server-received elapsed <3 seconds from that question opening, never a client duration. A streak is within one run/mode and resets on wrong answer, timeout, run end or leave; interleaved modes do not combine. If glyph XP remains, accept that teleport-assisted/rejoin collection can reach the cap, or add a persisted per-day per-spawn award limit. Do not describe proximity checks as anti-teleport proof. Rare quests use accepted server rarity, not the glyph value or client report.
- **Remotes:** Use server-created RemoteEvents with exact payloads: QuestRequest has no arguments; QuestClaim/QuestReroll carry finite integer day, slot 1–3, expected board revision and slot generation (or an equivalent opaque server-issued slot identity). Ownership comes only from the invoking Player. Reject unknown fields, NaN, infinity, fractions, oversized/malformed payloads and stale identities. Proposed tunables: requests 4/10 seconds, mutations 2/second and 10/30 seconds per player, one bounded pending action per player. Validate type/range/ownership/rate before enqueue; mark pending before yielding. Return explicit pending, stale, rate, loading, unavailable and confirmed states, plus a monotonic state revision so old pushes cannot regress UI. Client supplies no XP, progress, rarity, time or reward ID selection.
- **Confirmation and failure:** QuestState distinguishes pending local projections from confirmed stored awards; attributes and durable unlocks derive from confirmed XP. Publish confirmed level/quest-complete notifications after the relevant answer secrecy boundary. On an ambiguous dropped operation, reconcile from stored state without manufacturing a replacement delta. Loading/readonly/newer-schema profiles cannot claim durable rewards; development memory mode is explicitly nonpersistent. A request after a server hop must go through the same stored predicates even if the load showed an unclaimed quest. Plan bounded buffering or explicit loss of pre-load events; do not let the quest subsystem yield the match loop.
- **Migration and cutover:** Migrate v3 to v4 idempotently, retaining settings, ranks/test timestamps, blitz best, glyph total, applied receipts and unknown fields. Initialize XP=0 and an empty/uninitialized daily state without awarding historical quests. Include stable slot generation, board/catalog version and bonusGranted in the schema; define partial/malformed v4 recovery without converting corruption into a fresh reward opportunity. Verify v3 writers refuse a v4 value both at load and during an already-running UpdateAsync. Add a v4 gate mirroring the v3 freeze/admission-block/drain/verification record for every place and Studio writer; no migration writes until isolation is verified. Rollback after first v4 write must preserve and understand v4 state/receipts or keep writing disabled.
- **v1 scope and delivery:** Recommend deferring rerolls, fast-answer/streak quests and VS rewards/quests. Start with a fixed versioned pool of qualified mode finishes, correct-answer counts and glyph pickups/one rare, with explicit targets/difficulties and guaranteed eligible alternatives. Keep manual claims plus rollover only if both use the single conditional transition. Derive level/title/colour from XP; no selection remote is needed for automatically equipped rewards. At level 50 define the bar as MAX and next-level requirement as absent/0. The formula totals 46,060 XP to 50; the eight-week estimate needs stated daily earning assumptions. Before planning, update TASK-0150 ownership to include the actual hook services, remotes, release checklist and XpService if retained; its current queue ownership omits them. Do not implement those files under the existing incomplete ownership list.
