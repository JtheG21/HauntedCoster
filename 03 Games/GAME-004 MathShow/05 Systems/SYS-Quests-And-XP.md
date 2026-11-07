---
id: SYS-Quests-And-XP
title: "MathShow Quests and XP Design Brief"
type: system
project: GAME-004
status: proposed
side: shared
source: []
related:
  - "[[TASK-0149-MathShow-Quests-XP-Rules]]"
  - "[[TASK-0150-MathShow-Quests-XP-Service]]"
  - "[[TASK-0151-MathShow-Quests-XP-UI]]"
  - "[[SYS-Plaza-Map-Brief]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - game/system
---

# MathShow Quests and XP Design Brief

Design only. No code ships with this note. Approved as row QX-D1 (jg, 2026-11-07); the numbers below are **proposals** until jg approves task T1 (plan approval) and T2 (DataStore schema change).

## Purpose
Give players a reason to come back and a sense of progress between matches, without touching how a match is scored or ranked. XP is a long-term meter; quests are short goals that pay XP. Rank stays the skill signal (Skill Test); XP is the effort signal.

## Principles
- **Server-authoritative.** The server decides what happened (a correct answer, a finished match) and awards XP. The client only displays.
- **Derived from existing events.** Quests listen to events the server already knows (accepted answer, round reveal, results, Skill Test result, glyph pickup). No new client-to-server remote for earning.
- **Pure rules.** Quest progress and level maths live in `shared/QuestRules` and `shared/XpRules` (no Instances), tunables in frozen `shared/QuestConfig` and `shared/XpConfig`.
- **No pay-to-progress, no Robux.** XP is earned only by play. Rank stays visual flair only (Plaza brief "Access").
- **Quiet failure.** If a save fails, progress stays in memory for the session and retries; the UI never blocks a match.

## XP
| Topic | Proposal |
|---|---|
| Sources | Correct answer, finishing a match, quest completion, Skill Test pass, first win of the day. |
| Correct answer | 5 XP (flat; no speed bonus, so XP does not reward typing speed over accuracy). |
| Finish a match | 20 XP for completing it, +10 for a podium place. |
| Quest reward | Quest-defined, 25 to 100 XP. |
| Cap | At most 600 XP from answers and matches per UTC day; quest rewards sit outside the cap. Stops grinding bots and AFK farms. |
| Levels | Level 1 to 50. XP to next level = `100 + 25 * (level - 1)`, so level 50 needs about 36 k XP in total. |
| Level reward | Cosmetic only (title strings, name-plate colour, plaza emote). Nothing that changes scoring. |
| Display | Level badge by the name plate, XP bar on the menu, a small "+XP" toast at Reveal (respects `reducedMotion`). |

## Quests
| Topic | Proposal |
|---|---|
| Slots | 3 daily quests (reset 00:00 UTC) and 3 weekly quests (reset Monday 00:00 UTC). One re-roll per day. |
| Selection | Server picks from a pool by player level band, no duplicates, deterministic from `userId` + date so a rejoin shows the same set. |
| Kinds | `answers` (get N correct), `matches` (finish N), `streak` (N correct in a row in one match), `mode` (play a given mode), `podium` (place in the top 3), `skilltest` (pass a rank). |
| Progress | Monotonic counters; completing is idempotent. A quest is claimed once. |
| Claim | Automatic on completion; XP is added at the next save and shown at Reveal or in the menu. |
| Difficulty | Targets scale with the player's `bestRank` band so a Plastic player and a Demon player both get reachable goals. |

## Data and state
Profile schema moves from v3 to **v4** (a DataStore schema change, so it needs fresh explicit approval from jg before T2 starts).

| Field | Type | Rule |
|---|---|---|
| `xp` | number | Lifetime XP; never decreases; added as a delta like `glyphsDelta`, so the exactly-once receipt log covers it. |
| `quests` | table | Active quests: id, kind, target, progress, day key, claimed flag. Replaced at reset. |
| `xpDay` | table | `{ day, earned }` for the daily cap. |

Reuse the TASK-0141 save-operation and receipt design: XP and quest progress travel as deltas inside the same `SaveOp`, never as absolute totals, so two servers cannot over-credit. Stored data is lenient (bad fields fall back); any client-supplied value is rejected whole.

## Interfaces
| API / Remote | Direction | Args (validated) | Notes |
|---|---|---|---|
| `QuestState` (RemoteEvent) | server to owner | `{ level, xp, xpToNext, quests = {...} }` | Sent on join and after a change. Server creates it. |
| `XpGain` (RemoteEvent) | server to owner | `{ amount, reason }` | Display only. |
| `QuestReroll` (RemoteFunction or event) | client to server | none; rate-limited, once per day, ownership by `Player` | Only client request in the system. Server ignores it if the re-roll is spent. |

A changed payload updates sender, handler and receiver together (AGENTS.md remote change rule).

## Trust boundary
Clients cannot award, claim or set anything. The one client request (re-roll) carries no data to trust. XP and quest counters change only inside server code paths triggered by server-observed events.

## Out of scope
Leaderboards of XP, seasons, a quest shop, monetisation, group quests, anything touching Blitz, VS or Group Battle scoring, and any change to Skill Test rank rules.

## Open questions for jg
1. Are the XP numbers and the daily cap right, or should answers pay more?
2. Level reward list: titles and name-plate colours only, or also a plaza emote?
3. Is 3 + 3 quest slots right?
4. T2 touches the DataStore schema: approve at plan time, per the Approval Protocol.

## Tasks
| Task | Title | Tier | Depends on |
|---|---|---|---|
| [[TASK-0149-MathShow-Quests-XP-Rules]] (T1) | Pure rules, config and specs | standard | none |
| [[TASK-0150-MathShow-Quests-XP-Service]] (T2) | Service, profile v4, remotes | deep | T1 |
| [[TASK-0151-MathShow-Quests-XP-UI]] (T3) | Menu panel, XP bar, toasts | standard | T2 |

## Tests
- Automated: lune specs for `QuestRules` and `XpRules` (T1); profile v4 migration and save-delta specs (T2); text-fit ledger rows for the new UI (T3).
- Playtest: two Studio clients, one full match, daily reset by faking the day key, rejoin shows the same quests.

## History
- 2026-11-07: brief written (row QX-D1). No code.
