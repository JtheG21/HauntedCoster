---
id: ADR-0009
title: Monetization UI Scope
type: adr
project: GAME-002
status: approved
approved_by: jg
approved_on: 2026-10-13
related:
  - "[[RSH-20261013-Haunted-Monetization-Discovery]]"
  - "[[SYS-Haunted-Monetization-UI|Monetization UI Baseline]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/decision
  - game/monetization
---
# Monetization UI Scope

## Context
jg requested moving monetization from discovery to a baseline for the next major UI update. Earlier discovery confirmed compatible account-wide ghost cosmetic ownership and separate equipment slots, but currency/convenience and equipment application remained unresolved. Source history and missing early decisions remain preserved in [[RSH-20261013-Haunted-Monetization-Discovery]].

## Options considered
1. All five cosmetic categories versus ghost skins/mansion themes first.
2. Earned options plus direct Robux versus introducing premium currency or paid convenience now.
3. Per-ghost skin/aura equipment and a per-player capture effect versus one shared cosmetic loadout.

## Decision
Explicitly approved by jg through submitted answers in this chat on 2026-10-13:
- Include all five categories in the next major UI update: ghost skins, auras, capture effects, mansion themes and exterior decorations. Permanent catalog first.
- Cosmetics only: direct Robux purchases plus earned Coins/rewards. Defer premium currency and paid convenience until progression is measured.
- Equip skin and aura per owned ghost; equip capture effect per player. Purchases unlock account-wide use on compatible ghosts, not additional payment per ghost.

These approve product scope and ownership direction. They do not approve prices, exact assets, product IDs, mansion-tier coverage, DataStore schema changes, publishing, spending or an implementation task. Screen arrangements and delivery checks are specified for review in [[SYS-Haunted-Monetization-UI|Monetization UI Baseline]]. No final Claude implementation handoff was requested.

## Consequences
- The UI update must cover discovery/preview, acquisition, owned inventory, equipment and exterior placement rather than adding only a purchase button.
- Cosmetic identity stays separate from natural variants and gameplay strength. Existing Coin progression remains independent.
- Every category needs finished assets meeting [[3D Model Quality Baseline]]; new entitlements, equipment persistence and purchase processing require scoped tasks and verification.
- Seasonal/events, social customization and convenience are future work. Permanent catalog does not require fabricated limited-time urgency.
