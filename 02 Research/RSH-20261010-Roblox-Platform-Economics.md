---
id: RSH-20261010-Roblox-Platform-Economics
title: Roblox Platform Economics and Discovery
type: research
project: GAME-001
status: research
confidence: high
created: 2026-10-10
updated: 2026-10-10
tags:
  - research/platform
related:
  - "[[RSH-20261010-Candidate-Comparison]]"
  - "[[00 Overview]]"
---
# Roblox platform economics and discovery (shared baseline)

## Question
Which platform rules decide whether a game gets discovered and earns money? Every candidate note uses this one instead of repeating it.

## Sources (accessed 2026-10-10)
| Source | URL |
|---|---|
| Roblox Creator Docs: Discovery | https://create.roblox.com/docs/discovery |
| Roblox Newsroom: Optimizing Discovery (2026-06-15) | https://about.roblox.com/newsroom/2026/06/optimizing-discovery-great-games-reach-millions-players-roblox |
| DevEx documentation | https://www.roblox.com/developer-exchange/help |
| Creator Docs: Creator Rewards | https://github.com/Roblox/creator-docs/blob/main/content/en-us/creator-rewards.md |
| Creator Docs: Engagement-based payouts (deprecated) | https://create.roblox.com/docs/production/monetization/engagement-based-payouts |
| Creator Docs: Acquisition analytics | https://create.roblox.com/docs/production/analytics/acquisition |
| GamePulse developer economics (third-party) | https://gamepulse-zeta.vercel.app/guides/roblox-developer-economics |

## Verified facts
- **Discovery ranks long-term retention.** As of 2026-06-15, Recommended For You uses a 28-day retention view (it used to be 7-day). Named signals: play-through rate (most important), first-play bounce rate (<60 s and 61–180 s, a *negative* signal), play days per user (D1, D2–7, D8–28), playtime per user, qualified play sessions, spend days per user. *(Creator Docs, Newsroom)*
- Only users who arrived **organically from Recommended For You** count in ranking. Players from ads, friends, search or social media don't. *(Creator Docs)*
- **DevEx:** $0.0038 per earned Robux (for Robux earned on or after 2025-09-05). The minimum cash-out is 30,000 earned Robux, about $114. *(DevEx docs)* A higher rate of about $0.0054 applies to eligible spend by **age-verified US players 18+** from 2026-06-08. *(multiple third-party sources; confirm in the DevEx docs before modelling with it)*
- **Marketplace fee:** the creator keeps about 70% of Robux spent on passes and developer products. *(multiple sources, consistent)*
- **Engagement-based Premium Payouts were deprecated on 2025-07-24** and replaced by **Creator Rewards**. Those pay 5 Robux per "Active Spender" who plays ≥10 min, if the game is among the first 3 they play that day, plus a 35% revenue share on the first $100 of purchases by new or reactivated users brought in through Share Links (the game must keep 100+ average DAU). *(Creator Docs)*
- Roblox hosts the game servers; the developer pays no server cost. *(general platform knowledge; there was no cost line in the docs reviewed. Confirm before any formal cost model.)*

## Observations
- **The money is highly concentrated.** Third-party analysis claims about 85% of developers earn under $100 a month. That's unverified, but it fits Roblox's published median-earner figures being far below the top-1,000 averages.
- **Hits come out of nowhere, and fast.** Grow a Garden was made by a 16-year-old in a few days, then scaled by an established studio. 99 Nights in the Forest was made by a 3-person group. Steal An Egg launched 2026-07-25 and reached the #1 spot. *(GamesBeat 2025-09-07; Fandom; earnaldo.com 2026-09)*

## Hypotheses
- **H-P1 (high):** For a small team, **D1/D7 retention and short-session bounce matter more than raw concept popularity**, because they decide organic impressions.
- **H-P2 (medium):** A concept whose **first 60 seconds are instantly fun** is worth more than deep systems that pay off later.
- **H-P3 (medium):** Social and co-op play improves both retention and Share Link acquisition, which feeds Creator Rewards.

## Relevance to our game
We can't buy our way into the algorithm. Ad and friend traffic don't count toward ranking. The prototype has to be judged on bounce rate and return days.

## Recommendations
1. Score candidates mainly on **first-session fun** and **reasons to return**.
2. Make "<60 s bounce" and "D1 return" the core prototype metrics.
3. Don't model revenue with the 18+ rate. Our audience is probably younger.

## Needs human review
- The 18+ DevEx rate, and whether hosting has really zero cost, should be checked against official docs before Phase 7.
