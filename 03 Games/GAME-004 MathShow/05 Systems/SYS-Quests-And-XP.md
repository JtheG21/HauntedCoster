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
