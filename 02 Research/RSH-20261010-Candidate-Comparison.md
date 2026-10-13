---
id: RSH-20261010-Candidate-Comparison
title: M1 Candidate Comparison
type: research
project: GAME-001
status: done
confidence: low
created: 2026-10-10
updated: 2026-10-12
tags:
  - research/comparison
related:
  - "[[RSH-20261010-Coop-Physics-Obby]]"
  - "[[RSH-20261010-Coop-Anomaly-Horror]]"
  - "[[RSH-20261010-Round-Party-Minigames]]"
  - "[[RSH-20261010-Steal-Collect-Base]]"
  - "[[RSH-20261010-Roblox-Platform-Economics]]"
  - "[[GAME-001 Rg1/00 Overview|00 Overview]]"
---
# M1 candidate comparison: **decided**

> These scores are structured judgment based on public snapshots, **not a market forecast**. CCU and visits are third-party readings that change daily, and none of them measure profit. The status stays `proposed` until you pick a direction.

## Candidates
- **A:** [[RSH-20261010-Coop-Physics-Obby]]
- **B:** [[RSH-20261010-Coop-Anomaly-Horror]]
- **C:** [[RSH-20261010-Round-Party-Minigames]]
- **D:** [[RSH-20261010-Steal-Collect-Base]]

Considered and dropped early (no note): a cozy grow/farm sim (Grow a Garden needed two studios to keep up with live-ops and economy), and a competitive shooter/PvP (netcode and anti-cheat cost too much for a solo developer).

## Weighting (why)
| Criterion | Weight | Reason |
|---|---|---|
| Feasibility | **25%** | Solo, part-time, AI-assisted, no art budget, 8 GB Mac. Not finishing is the biggest risk |
| Gameplay potential | **20%** | Discovery rewards play-through and low bounce ([[RSH-20261010-Roblox-Platform-Economics]]) |
| Demand evidence | **20%** | Proof that players want this *now* |
| Retention potential | 10% | The algorithm uses 28-day retention, but we can't measure it before a prototype |
| Monetization potential | 10% | A goal, but fair monetization only |
| Differentiation | 10% | Needed to stand out among clones |
| Prototype speed | 5% | Cheap tests let us fail fast |

## Scores (1–5)
| Criterion (weight) | A Co-op obby | B Anomaly horror | C Party minigames | D Steal/collect |
|---|---|---|---|---|
| Demand (20) | 4: two fresh hits Jun–Sep 2026 (5K–23K CCU), one by a first-time solo dev | 4: Animal Hospital 2.3B visits in 5 months, media calls it a trend | 3: NDS evergreen (8K–69K), most minigame games <9K | 5: #1 on the platform (1–1.8M CCU) |
| Gameplay (20) | 4: funny co-op failure, instantly readable | 4: tension plus observation for any skill level | 3: fun but generic | 3: compelling loop, shallow skill |
| Feasibility (25) | 4: primitive art. **Network physics is the risk** | 3: atmosphere/art and anomaly content are expensive | 4: small modules, simple systems | 2: economy, persistence, PvP theft, exploits |
| Differentiation (10) | 3: procedural co-op and several verbs are open | 3: new setting, role asymmetry | 2: hard to stand out | 1: clone war, lawsuits |
| Retention (10) | 2: linear obbies run out (ToH average 4.2 min, CtG 10.7 min) | 3: shifts, classes, weekly anomalies | 3: rotating rounds | 4: passive income, rebirths |
| Monetization (10) | 3: cosmetics, skips, private servers | 3: cosmetics, revives | 3: cosmetics, VIP | 5: proven, but pay-to-win |
| Prototype speed (5) | 5: about 1–2 weeks | 3: about 2–3 weeks | 4: about 1–2 weeks | 3: about 3–4 weeks |
| **Weighted total** | **3.65** | **3.40** | 3.20 | 3.25 |

## Sensitivity: what changes the ranking
- **Monetization-heavy weights** (Monetization 25, Feasibility 15, Prototype 0): D 3.65 > A 3.45 > B 3.40. D wins only if we accept pay-to-win economics and clone and legal risk.
- **Retention-heavy weights** (Retention 25, Feasibility 20, Differentiation 5, Prototype 0): D 3.55 > B 3.40 > A 3.35. A's weak point is replayability.
- **If the co-op obby trend fades** (A's demand drops to 2): A falls to 3.25, below B.
- **If anomaly atmosphere can't be achieved cheaply** (B's feasibility drops to 2): B falls to 3.15.
- So **A's lead depends on two assumptions**: the co-op trend lasts, and we can fix replayability with procedural or varied co-op sections.

## Recommendation: top two
1. **A: co-op physics obby.** The most feasible and the fastest to test, and the demand is fresh (including a first-time solo developer's success). *Trade-off:* weak retention unless we design for replay. One make-or-break technical question: shared physics across clients.
2. **B: co-op anomaly horror.** Stronger retention structure and a proven breakout. *Trade-off:* the fun depends on atmosphere and art, which is our weakest capability, and the content treadmill is ongoing.

**Not recommended:** D (despite the highest demand and earnings) because of exploits, clones and legal risk, and an unfair monetization model. C works as a fallback, or as modes inside A/B later.

## Cheapest next evidence (before Phase 3)
- A: a 1-day **network-physics spike** (two clients carrying one object in Studio). Does it feel good and resist exploits?
- B: a 1-day **atmosphere spike** (one room, lighting and audio, 5 anomalies). Is it tense with primitive art?
- Both: track the reference games' CCU weekly for 4 weeks to tell a lasting trend from a spike.

## Decision required
Pick A, B, or "spike both, then decide". This note stays `proposed` until then.

## Decision (2026-10-10)
The user chose **A**, as an anime-inspired variant with rivals who must cooperate and a last-one-standing finale. See [[ADR-0002-Game-Direction]]. B, C and D are archived. This note isn't edited further.
