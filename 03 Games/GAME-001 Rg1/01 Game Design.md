---
id: GAME-001-DESIGN
title: Game Design
type: design
project: GAME-001
status: proposed
version: 0.1
created: 2026-10-10
updated: 2026-10-10
tags:
  - game/design
related:
  - "[[ADR-0002-Game-Direction]]"
  - "[[ADR-0003-Original-Factions-IP-Policy]]"
  - "[[EXP-0001-M2-Validation-Experiments]]"
---
# Game design v0.1: **proposed, awaiting approval**

> Direction approved ([[ADR-0002-Game-Direction]]). Everything below is a **proposal** until you approve it. Working title: **"Rival Realms"** (placeholder, no franchise names; see [[ADR-0003-Original-Factions-IP-Policy]]).

## Pitch
Four rival power factions race through a physics obby. You can't finish without a rival's power, and the more you work together, the stronger everyone gets for the final **last-one-standing** brawl. Every match settles "**which power is strongest?**" across **Speed, Teamwork and Combat**, and the results add up into a live global Faction War.

## Target player & motivation
- Ages about 9–16 who like anime and argue about whose hero would win. They play with friends or in public servers.
- Motivations: **identity** (my faction), **mastery** (my power, skilful movement), **social proof** (my faction is winning), **funny chaos** (physics fails with rivals).

## Factions (original archetypes; names are placeholders)
| Faction | Inspired archetype | Signature power (obby use → finale use) | Movement flavour |
|---|---|---|---|
| **Shinobi Clan** | Ninja village | *Echo Clone*: leaves a clone that holds plates and switches for 6 s → decoy that absorbs one hit | Wall-run |
| **Ki Vanguard** | Energy warrior | *Ki Burst*: charged blast that breaks cracked walls and pushes heavy blocks → knockback blast | Short hover-dash |
| **Tide Corsairs** | Pirate adventurer | *Stretch Grab*: elastic grab that pulls you to anchors or pulls an object or player to you → yank a rival | Swing on anchors |
| **Spirit Blades** | Spirit swordsman | *Flash Step / Spirit Cut*: blink through thin spirit barriers, cut ropes → dodge plus short-range cut | Air-dash |

Names, looks, VFX colours and ability names are all original. No franchise names anywhere.

## Loops
- **30-second loop:** run a section with your faction's movement → hit an obstacle that only some powers solve → use yours, or **wait, bargain or ping** for a rival's → light rivalry (shoving at race sections) → checkpoint.
- **5-minute session loop (one match, about 6–8 min, 4–8 players):**
  1. Pick a faction (auto-balanced) → 2. **Race sections** (rivals) alternate with **Convergence Gates** (need 2+ different powers) → 3. Everyone who passes a gate gains an **Echo charge** of the powers that opened it → 4. **Finale arena**: ring-out last-one-standing with your own power plus the Echo charges you earned → 5. **Results**: winners per category (Speed = first to finish the obby, Teamwork = gates opened and assists, Combat = finale) → faction points.
- **Long-term loop:** faction mastery levels (cosmetic only), a weekly **Faction War** board (global totals per category), rotating modular course sections, new gates and arenas each update.

**Why cooperation and rivalry fit together:** helping a rival open a gate makes them stronger in the finale *but also* feeds your own Echoes and your faction's Teamwork score. Every helping decision is a strategic trade-off. That trade-off is the core design bet.

## Rewards & upgrades
- In-match: Echo charges (only last for this match), faction points.
- Persistent (later, needs DataStore and an ADR): faction mastery XP → cosmetic VFX colours, titles, emotes. **No permanent power upgrades**, so matches stay fair.

## Social & multiplayer
Gates that need cooperation with strangers, a ping wheel ("Need Ki Burst here!"), emotes, parties choosing the same or rival factions, and faction chat cosmetics. Fallback for griefing or a missing faction: gates only ask for powers **present in the match**. If nobody helps within 20 s, an **Echo Shrine** opens a slower bypass.

## First-session onboarding (target: first power use within 60 s, because first-play bounce is a negative ranking signal)
1. Spawn into a 30-second faction trial: use your power once, with a prompt.
2. A demo gate with an NPC rival shows "you need *their* power" and Echo pickup.
3. Join the next match. Gate icons show which faction powers are needed.

## Reasons to return (non-manipulative)
Weekly Faction War results ("Shinobi won Teamwork this week"), mastery cosmetics, new course sections. **No** streak-loss punishment, no countdown pressure on purchases, no loot boxes.

## Content & update strategy
A modular course: each section is a 30–60 s module, and a match picks 5–7 randomly (replay value, the weakness found in research). Each update adds 2–4 sections or 1 gate type or 1 arena. A 5th original faction is a later milestone.

## Monetization (player-friendly; all hypotheses for M6)
Cosmetic power VFX colours, trails, finale emotes, faction banners, private servers. **No** paid powers, Echo charges, skips or stat boosts (they would break the "which is strongest" fairness). Details are tested in Phase 7 or M6, with your approval.

## Security, saving & server authority
- All ability activations are **requested** by the client and **validated** by the server (cooldown, range, line of sight, target type). Effects are applied on the server.
- Carried or pushed physics objects: the server owns them or ownership is assigned deliberately (spike TASK). Character speed and teleport sanity checks during races.
- Finale knockback and ring-out decided on the server. Faction points written on the server only.
- Saving (mastery, Faction War) only after an ADR on the DataStore schema and session locking.

## Smallest prototype (M2) to test the riskiest assumptions
| Riskiest assumption | Prototype element |
|---|---|
| R1: Forced cooperation between rivals is **fun, not frustrating** | 1 Convergence Gate needing 2 powers, with the 20 s Echo Shrine fallback |
| R2: Powers **feel good and replicate reliably** with 2–4 players | **2 factions only** (Echo Clone + Ki Burst), server-validated |
| R3: A ring-out finale using obby-learned powers is fun | A tiny arena with knockback and ring-out, Echo charges carried over |
| R4: First power use in under 60 s | 30-second trial area |

Primitive art, no saving, no monetization, no Faction War. One course: race section → gate → race section → finale.

## Essential vs postponed
- **Essential for the first playable (M3):** 4 factions, 6–8 course modules, 2 gate types, the finale, results by category, the onboarding trial.
- **Postponed:** global Faction War (needs MessagingService and DataStore), mastery saving, cosmetics shop, a 5th faction, mobile control polish (but **test mobile in M2**, because it's a large share of Roblox users), anime-style VFX polish.

## Scope re-assessment (honest)
This is **bigger than candidate A** as scored: 4 ability kits plus PvP were explicitly deprioritised earlier as netcode-heavy. Mitigations: a **ring-out** finale instead of hit-point combo combat (it needs much less precise hit registration), powers that serve double duty (obby and fight), and a 2-faction prototype first. Rough effort (unvalidated): M2 prototype about 2–3 weeks part-time; M3 first playable about 6–10 weeks.

## Open questions (need your input)
1. Faction names and visual identity: placeholders are fine for M2.
2. Players per match: 4–8 proposed.
3. Should Echo charges *replace* or *add to* your own power in the finale? (Proposed: add.)

Related: [[00 Overview]] · [[02 Technical Architecture]] · [[03 Roadmap]] · [[RSH-20261010-Anime-IP-And-Demand]]
