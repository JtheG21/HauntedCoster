---
id: RSH-20261019-Hike-Or-Die-Commercial-Plan
title: Hike or Die income, launch measurement and cash plan
type: research
project: GAME-003
status: proposed
confidence: low
created: 2026-10-19
updated: 2026-10-19
tags:
  - research/monetization
related:
  - "[[RSH-20261019-Hike-Or-Die-Launch-Spec]]"
  - "[[RSH-20261019-Hike-Or-Die-Delivery-Plan]]"
---
# Hike or Die income and launch measurement

## Question
How can the game pursue maximum sustainable earnings under a $50 remaining project cash cap, and what evidence would justify relying on it for bills?

**Decision (jg, 2026-10-19):** maximize earnings; launch next week if ready; update frequently afterward; reserve the remaining $50 for necessary, unusually productive tools. No specific monthly bill target or purchase approved. Default spend in this plan is $0. The audit has no live revenue or player data.

## Sources
All sources accessed 2026-10-19; recheck at release and before any cash decision.

| Source | URL | What it establishes |
|---|---|---|
| Roblox DevEx rates | [Help and information](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page) | Current standard and conditional rates |
| DevEx eligibility | [Roblox DevEx program](https://create.roblox.com/docs/production/monetization/developer-exchange) | Eligibility and cash-out process; verify on official page before use |
| Growth measurement | [Analytics](https://create.roblox.com/docs/production/analytics) | Retention/engagement before acquisition; relevant metrics |
| Cohort definitions | [Retention](https://create.roblox.com/docs/production/analytics/retention) | D1/D7/D30 cohort timing |
| Revenue measures | [Monetization analytics](https://create.roblox.com/docs/production/analytics/monetization) | Conversion, ARPPU, ARPDAU |
| Fulfillment | [Developer products](https://create.roblox.com/docs/production/monetization/developer-products) | Server ProcessReceipt and purchase record responsibility |
| Publishing/audience | [Release requirements](https://create.roblox.com/docs/production/publishing/publish-games-and-places) | Audience-dependent requirements |
| Event delivery | [Economy events](https://create.roblox.com/docs/production/analytics/economy-events) | Server/published-environment event limitation |

## Observed mechanics (verified)
Roblox's current standard DevEx rate is $0.0038 per eligible Earned Robux; a conditional US age-verified adult spending category can receive $0.0054. Use the standard rate for planning; eligibility/mix is unverified and the higher category is not the whole audience. Purchased Robux and sticker-price sales are not equivalent to cash-out-eligible earnings. DevEx also requires eligibility, review and cash arrival; a dashboard balance is not money already in the bank. Never store personal tax/payment details in this repo. [DevEx rate source](https://en.help.roblox.com/hc/en-us/articles/13061189551124-Developer-Exchange-Help-and-Information-Page), [eligibility and payout process](https://create.roblox.com/docs/production/monetization/developer-exchange).

Roblox recommends improving retention, engagement and monetization before large acquisition efforts. D1/D7/D30 are measured from first-play cohorts and need time to mature. Monetization metrics distinguish payer conversion, spend per payer and revenue per daily user. Economy events are sent by servers in published games, not Studio, so local logs alone cannot prove dashboard ingestion. [Analytics guidance](https://create.roblox.com/docs/production/analytics), [retention cohorts](https://create.roblox.com/docs/production/analytics/retention), [economy event limits](https://create.roblox.com/docs/production/analytics/economy-events).

Current publishing requirements vary by audience. The official page lists account good standing/age checks and maturity disclosure; wider Kids/Select reach adds identity, 2FA, subscription-history-or-fee and evaluation/rating requirements. H00/H26 must verify the actual account and desired audience today, because those requirements may prevent next week's intended reach. This audit did not inspect eligibility, recommend paying a fee, or authorize publishing. [Current release requirements](https://create.roblox.com/docs/production/publishing/publish-games-and-places).

## Hypotheses
**Low confidence:** recognizable camera cosmetics, hiker identity and collectible proof will monetize an enjoyable replay loop. **Low confidence:** organic clips showing a risky capture/escape will acquire suitable players. Test both cheaply; neither a polished icon nor a large shop compensates for a broken camera.

## Relevance to our game
The product currently has no demonstrated payer or returning-user base. “Pay my bills” requires retained players, dependable net receipts and affordable ongoing work. The useful first objective is a measurable positive contribution, followed by increasing it without damaging retention. No earnings guarantee or statistically supported forecast is possible yet.

## Original implementation ideas
### Offers and economy proposal
- Launch candidate A: a permanent supporter/camera-style pack with visible preview and exact listed contents. Candidate B: a distinct hiker/camera cosmetic set. Start with direct purchases and a small catalog; select the actual platform product type in H18/H13. Durable items should use suitable ownership/entitlement handling; consumable developer products require receipt idempotency. Do not force developer products into a permanent-offer design merely to use a receipt system.
- Preserve useful free cosmetic unlocks and all core photography/chase/rescue capability. Display the shop after the player has experienced a successful loop, not as a spawn obstruction. No gameplay-critical paid film, paid escape, paid revive, fake urgency, random paid boxes or subscription obligations in the first release.
- Prices are hypotheses, not yet approved values. Prepare a low/mid price comparison from current comparable offers in H18, then obtain jg's SKU/price approval. Fetch player-visible prices rather than hardcoding a Robux label; account for regional or experimental pricing if enabled.
- Keep the initial reward system simple: discovery/contract progress and cosmetic unlocks. Add a currency only when an actual use requires it. If introduced, document every source/sink, expected first unlock time, inflation, duplicate behavior, maximum balances and exploit caps. No trading economy at launch.
- Track offer exposure, prompt, purchase confirmation, durable grant and equip separately. A closed purchase prompt is not a confirmed sale. Test cancel, already-owned, unavailable item, disconnection, replayed receipt and delayed grant before exposing sales. Show a recoverable pending state rather than claiming an undelivered purchase succeeded.

### Income sensitivity, not a forecast
Define:
- `B`: desired monthly spendable income after a chosen planning reserve.
- `C`: actual monthly cash operating costs, including approved tools/ads and fees. Current project spend cap remains $50 total; future operating costs are not pre-approved.
- `t`: fraction of pre-reserve profit held back. This is a user-selected planning buffer, not an estimate of personal tax liability.
- `e`: net eligible Earned Robux per active-user-day, after platform deductions and any partner split. Determine from reconciled data, not gross shop sales.
- `d`: applicable cash-out rate; use $0.0038 until evidence supports another mix.

Approximate monthly cash generation: `30 × DAU × e × d`.
Approximate spendable amount: `(30 × DAU × e × d − C) × (1 − t)`.
Required DAU: `(B / (1 − t) + C) / (30 × e × d)`.
Do not apply a second platform fee to earnings already reported net. Incentive/reward income is excluded from baseline until actually eligible and observed. Cash timing/holds can make a profitable month insufficient to pay a bill that is due earlier.

**Illustrative sensitivity only:** 30 days, C=$0, t=25% planning reserve, d=$0.0038. These income levels are examples because jg has not selected a minimum. All DAU counts round up. Values of e=1/3/5 are assumptions, not HOD measurements or platform benchmarks.

| Monthly spendable goal B | Cash generated before reserve | Eligible Earned Robux/month | DAU at e=1 | DAU at e=3 | DAU at e=5 |
|---|---:|---:|---:|---:|---:|
| $1,000 | $1,333.33 | 350,878 | 11,696 | 3,899 | 2,340 |
| $3,000 | $4,000.00 | 1,052,632 | 35,088 | 11,696 | 7,018 |
| $5,000 | $6,666.67 | 1,754,386 | 58,480 | 19,494 | 11,696 |

For example, daily payer conversion of 1% with 100 net eligible Robux per payer gives e≈1; 3% at the same net amount gives e≈3. That is an algebraic illustration, not a reason to assume either conversion rate. DAU differs from concurrent players and from monthly unique users. A 4-player server cap does not mean only four users can play the game overall.

**Recommendation:** before treating revenue as bill coverage, observe at least three consecutive months of actual cash receipts meeting the chosen minimum after operating costs and reserve, check concentration in large spenders, and maintain a buffer for payout delays and lower months. This is a cautious project planning criterion, not a promise of stability.

### Measurement contract
| Measure | Definition / slice | Decision supported |
|---|---|---|
| Discovery conversion | Plays divided by attributable impressions, same surface/time window | Which truthful icon/thumbnail brings suitable players? |
| Activation | New players with first valid evidence and first extraction divided by eligible new starts | Do users reach the hook? Separate device/party size/source |
| Time to fun / abandonment | Median/p90 join→first evidence, exits by funnel step, exit reason where known | Where to simplify or fix performance |
| Voluntary replay | Players choosing another expedition after a result divided by players seeing a result | Is another run desirable? Track success/failure separately |
| D1/D7/D30 | Platform first-play cohorts at matching elapsed days | Are users returning? Never count today's cohort as D7 |
| Photo/chase balance | Rejection reason, grade, state, catch/escape rates, loss and run duration | Is risk legible and skill rewarded? |
| Conversion / e / ARPPU | Daily payers/DAU; reconciled eligible earnings per active-user-day; net per payer | Offer fit and income sensitivity |
| Purchase integrity | Confirmed purchases, durable grants, duplicates, pending duration and support cases | Disable unsafe sales immediately |
| Data/service health | Load/save errors, timeouts, session conflicts, crashes and frame p95 | Stop rollout or roll back before more users are exposed |
| Maintenance cost | Creator hours, tool cash, model usage and support cases per release | Can the update cadence be sustained? |

Event schema minimum: build version, event name/version, session/round correlation, device class, party size, encounter/contract ID, phase/outcome/rejection reason, duration and amount where applicable. Bound fields/cardinality and retention; no raw screenshots/chat/PII collection. Platform cohort data should do the identity work where possible. Client camera-open events are diagnostic, not evidence that a trusted game outcome occurred. Document abandoned/disconnected sessions so the funnel doesn't count only survivors. Verify a controlled published-test event end to end with approval.

### Launch and scaling experiments
1. **Hook study:** G1's five fresh users provides a directional go/revise signal, not retention or market proof. Record actual observations; no leading “would you buy?” questions as substitute for behavior.
2. **Alpha cohort:** target at least 30 fresh target players across supported devices and solo/groups; inspect failures and voluntary replay. Human recruits/testers; no outreach sent by agents without authorization.
3. **Limited public exposure:** do not buy ads initially. Seek at least 300 eligible new-player starts over a documented period; lower traffic means “insufficient data,” not failure or success. Wait for D1/D7 maturity and report n, rates and uncertainty. Suggested provisional evaluation floors: activation ≥70%, D1 ≥20%, D7 ≥5%. These are internal starting hypotheses, not Roblox benchmarks or evidence of profitability; calibrate against similar-game dashboard benchmarks when available. If missed, diagnose device/source/onboarding differences and revise before expanding acquisition.
4. **Offer experiment:** start with one clearly described offer placement/price test; retain stable versions and sufficient observation time. Revenue and D1/D7 are joint guardrails. If sample is too small for inference, report descriptively and do not claim an uplift. An offer that lifts immediate spending but worsens repeat play is not an automatic win.
5. **Scaling decision:** no paid acquisition under the reserved $50 plan. If separately funded later, compare measured incremental acquisition cost with conservative realized cohort net contribution after operating/support costs; do not spend against an assumed lifetime value. Stop when the preapproved cap is reached or integrity/retention guardrails regress.

### $50 tool reserve
| Allocation | Planned spend now | Release condition |
|---|---:|---|
| Existing CLI/Studio/Blender/reference workflow | $0 incremental | Use already available tools |
| Ads, assets, extra model credits, convenience subscriptions | $0 | Not assumed necessary or approved |
| Emergency efficiency tool reserve | Up to $50 total, untouched | A specific demonstrated bottleneck, free alternatives comparison and explicit jg approval |

Before proposing a paid tool: define the exact blocked deliverable; run a free/local sample if possible; measure manual baseline versus trial including cleanup/revisions; confirm Roblox output compatibility, licence, total cost/credits and cancellation; show the reusable result. Recommended hurdle: about 3× end-to-end throughput on comparable output with no quality loss, or a uniquely necessary capability that removes a launch blocker. “Exponential improvement” is not accepted as a marketing claim. No purchase, renewal or paid generation without the concrete cost and result being approved. Record actual spend against the single $50 cap and the studio's existing API policy.

### Following-week operations
During November 2–8: inspect save/purchase/error health and support daily, prioritize camera/softlock/data defects immediately, and ship small verified changes. Aim for two meaningful content/quality updates if health is stable, with a prepared contract/encounter variation and cosmetic preview rather than a new map pipeline. Announce only approved releases. Reconcile income weekly and cash arrivals monthly. Keep a release changelog, exact build/cohort tags and rollback instructions. Prefer one measured hypothesis per release; do not reset cohorts by changing everything daily.

## Recommendations (max 3)
1. Earn the right to monetize through a reliable first session and a compelling second expedition.
2. Use observed net earnings, mature cohorts and cash receipts to decide scaling; the current prototype cannot support a bill-paying forecast.
3. Keep the $50 reserve intact until a small tool trial demonstrates value and jg authorizes the specific spend.

## Needs human review
Select target audience and account eligibility path, initial offers/prices, recruit/test access, minimum bill threshold and reserve assumption. Cash, account, legal/tax details stay with jg outside the repo. Publishing, ads, outreach, fees, tool subscriptions and account changes are not authorized by this plan. Rates and release rules must be rechecked before use.
