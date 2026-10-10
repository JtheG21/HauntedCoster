---
id: RSH-20261010-Coop-Physics-Obby
title: "Candidate A: Co-op Physics Obby"
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
# Candidate A: co-op physics obby ("do it together or fail together")

## 1. Concept summary
Two players (or more) must cooperate physically to clear an obstacle course: carrying a fragile object together, being tethered, or sharing one vehicle or contraption. You can't win alone.

## 2. Target audience hypothesis
Friends and siblings who play together (ages about 9–16), and solo players who want a partner from public matchmaking. *(hypothesis: low–medium confidence)*

## 3. Comparable experiences (accessed 2026-10-10)
| Game | Evidence | Source |
|---|---|---|
| Carry the Glass Together! [2 Player Obby] (Ritronics Studios) | Released 2026-06-29. 15.3M+ visits, 5.8K active on its page, 12.86K all-time CCU peak, **10.7 min average session**. The page says it's an "early beta made by a passionate solo developer… my first Roblox game" | https://www.roblox.com/games/81734857983173 · https://romonitorstats.com/experience/81734857983173 |
| [1 & 2 PLAYER] Grapple Cart Obby (rng dev) | Created 2026-08-26. 7–11M visits within about a month, 15.5K–22.7K CCU readings in late Sep, 92–93% rating, daily updates | https://spawnscope.com/games/1-2-player-grapple-cart-obby · https://www.bloxscout.net/games/10762388019 |
| Tower of Hell (solo competitive obby, the genre anchor) | 29B visits, 11K–58K CCU readings, **4.23 min average playtime**, 74% rating | https://www.rolimons.com/game/1962086868 · https://roguard.org/games/1962086868-tower-of-hell |
| Carry The Glass (Steam, the off-platform original) | $4.99, about 64K units estimated, 75% reviews. The concept predates the Roblox version | https://raijin.gg/app/3263320/Carry_The_Glass |

## 4. Core gameplay loop
Pair up → attempt a section → fail together (comic physics) → retry → reach a checkpoint → unlock the next stage or cosmetic → swap partner or replay for a faster time.

## 5. What the references do well
- An instant, readable premise. The title explains the game (low bounce).
- Failure is funny and social, which suits clips and sharing.
- Very low asset needs (primitives plus physics), so small teams ship fast and update daily.

## 6. Weaknesses / underserved needs / differentiation
- **Content runs out:** a linear obby ends, and replay is weak. Tower of Hell answers this with procedural towers.
- **Solo players** have to rely on finding a random partner. The partner-matching experience is often poor. *(observation from the descriptions; to verify by playing)*
- The trend is getting crowded fast with "[2 PLAYER] X" titles.
- **Differentiation options:** procedurally assembled co-op sections, so every run is new; several cooperative verbs (carry, tether, balance, pull) rather than one gimmick; good stranger-pairing with emotes and pings; time-trial leaderboards per pair.

## 7. Retention & social mechanics
Pair records and "best partner" stats, daily rotating course seeds, collectible cosmetics for the carried object, friend-invite bonuses (fits Creator Rewards Share Links).

## 8. Monetization hypotheses (ethical)
- Cosmetics for the carried object, trails, celebration emotes (no gameplay advantage).
- A **checkpoint skip** developer product. This is common in obbies but needs care so it doesn't undermine the challenge. It's a hypothesis, to test.
- Private servers for friend pairs.

## 9. Minimum viable prototype
One carry-object mechanic, 5–6 hand-built sections, two-player pairing in a lobby, checkpoints, break and reset, and a timer. Primitive art only.

## 10. Development risks & effort
- **Main technical risk: shared physics across two clients.** Who owns the network physics of the carried object, how latency feels, and how to stop exploits (a client teleporting the object). This needs a spike task. *(high importance)*
- Mobile controls for rotating or tilting the object.
- Effort for the prototype: about 1–2 weeks of part-time AI-assisted work (rough estimate, unvalidated).

## 11. Evidence gaps & experiments
- Is the subgenre's demand lasting or a short spike? Track Carry the Glass and Grapple Cart CCU weekly for 4 weeks.
- Does random pairing produce fun for solo players? Playtest with strangers.
- What's retention beyond one session? Unknown. RoMonitor retention data is owner-only.

## Recommendations
1. A **network-physics spike** before anything else. It's the make-or-break risk.
2. Differentiate on **replayability** (procedural sections, several co-op verbs), not just one more gimmick.

## Needs human review
- CCU figures are third-party snapshots on different dates. Treat them as ranges, not facts about monetization.
