---
id: RSH-20261010-Steal-Collect-Base
title: "Candidate D: Steal-and-Collect Base Simulator"
type: research
project: GAME-001
status: research
confidence: medium
created: 2026-10-10
updated: 2026-10-10
tags:
  - research/candidate
related:
  - "[[RSH-20261010-Candidate-Comparison]]"
  - "[[RSH-20261010-Roblox-Platform-Economics]]"
---
# Candidate D: steal-and-collect base simulator ("Steal a X")

## 1. Concept summary
Buy or hatch collectibles that generate passive income in your base. Steal from other players' bases and defend your own. Rebirth for multipliers.

## 2. Target audience hypothesis
The broad core Roblox audience, ages about 8–14. Very large. *(high confidence on demand, see below)*

## 3. Comparable experiences (accessed 2026-10-10)
| Game | Evidence | Source |
|---|---|---|
| Steal An Egg | Launched 2026-07-25. **#1 on Roblox**: about 1.0M–1.8M CCU readings (Sep 2026) | https://www.roblox.com/charts/top-playing-now · https://earnaldo.com/blog/best-roblox-games-2026 |
| Steal a Brainrot (2025) | Peaked at 24M CCU. **Estimated** $64M real-money earnings (RoMonitor via Bloomberg, 2026-03). Lawsuit against clones | https://en.wikipedia.org/wiki/Steal_a_Brainrot · https://www.thestar.com.my/tech/tech-news/2026/03/25/robloxs-hit-game-steal-a-brainrot-battles-its-many-imitators |
| Clones (Steal A Verity, Steal From The Rich…) | About 10–12K CCU each on the charts | https://www.roblox.com/charts/top-playing-now |
| Criticism | Polygon criticised pay-to-win ("best items only available for cash", purchasable admin abilities) | Wikipedia (citing Polygon) |

## 4. Core gameplay loop
Buy or hatch a unit → it earns money → buy a better one → raid others or defend → rebirth → repeat.

## 5. What the references do well
An extremely simple and compelling loop, social conflict, meme-driven virality, strong spending hooks.

## 6. Weaknesses / underserved needs / differentiation
- **Saturated with clones, with active legal disputes** over copying. Hard to stand out, and there's legal and reputational risk.
- Exploits are rife. Public sites distribute auto-steal scripts, so server-authoritative anti-exploit work is mandatory and continuous.
- The economy is driven by pay-to-win, which conflicts with our fair-monetization principle.

## 7. Retention & social mechanics
Offline income, rare drops, events, trading, rivalry.

## 8. Monetization hypotheses
Strong by nature (boosts, gear, rare eggs), but the ethical versions (cosmetic only) give up much of the genre's revenue model.

## 9. Minimum viable prototype
Base plots, a conveyor shop, 5 unit tiers, passive income, a steal-and-carry mechanic with lock and shield, DataStore persistence.

## 10. Development risks & effort
Persistence plus an economy plus PvP theft makes for a large exploit surface. Content (character models) drives the hype. Prototype about 3–4 weeks part-time, and live ops are heavy.

## 11. Evidence gaps & experiments
How long does a clone's player count last (decay curve)? Track 5 clones for 4 weeks.

## Recommendations
1. **Not recommended** as our first game. Highest demand, but lowest differentiation, high exploit and legal risk, and a monetization model that conflicts with our principles.
