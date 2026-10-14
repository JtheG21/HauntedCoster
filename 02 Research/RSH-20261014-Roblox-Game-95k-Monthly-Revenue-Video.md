---
id: RSH-20261014-Roblox-Game-95k-Monthly-Revenue-Video
title: "How My Roblox Game Makes $95,110/mo (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/0ENzqNB_EUo
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/monetization
  - research/live-ops
---
# How My Roblox Game Makes $95,110/mo (video)

> **Draft.** Creator self-report about a different genre (motorbike/roleplay game). Speaker claims are unaudited, even where a dashboard screenshot is shown. Nothing here is approved.

## Question
Which live-ops, pricing and retention lessons from a creator's "how my game earns ~$95k/mo" video are relevant to Haunted Collector's already-approved cosmetic monetization scope ([[ADR-0011-Monetization-UI-Scope]]), and which are not (genre, audience, ad spend)?

Context: this is background research for monetization and live-ops planning. It is **not** tied to TASK-0040 (Audio Pass).

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How My Roblox Game Makes $95,110/mo", uploader VuukStudios, 16:40 | https://youtu.be/0ENzqNB_EUo | 2026-10-14 |

**Evidence limits.**
- Captions are YouTube auto-generated English (original-language provenance unknown). The speaker's English is evidently translated or non-native; the on-screen slide text is cleaner than the captions and was preferred where they differ.
- Frames, all viewed by us on 2026-10-14 (local engine, two passes): 62 scene-change frames over 0:00-5:33; 9 cue frames at 1024 px (0:21, 0:25, 0:48, 1:03, 1:10, 1:28, 4:29, 4:38, 5:28), of which I opened 0:21, 1:03 and 4:29; and 70 keyframes from 5:33-16:38 (about every 8 s), reviewed as five 4x4 contact sheets, not individually.
- The video contains **only slides (grey background, text) and screenshots of dashboards**. There is no gameplay footage and no talking head, so nothing about the game's actual moment-to-moment play was shown.
- The Gemini engine was not used (quota); no cloud service was used for this note.
- Dashboard numbers are the creator's own screenshots; we have not verified them against Roblox.

## Observed mechanics (verified)
Only what the transcript says or the viewed frames show. Everything about revenue is **speaker claim**, not measured by us.
- **Claimed result** *(0:00-0:55)*: the title says $95,110/mo; the speaker says about 2.5M Robux in 3 days, "almost 100k per month", and 10k CCU. Screenshots show: Hourly Robux spent total 2,504,293 over the selected period (0:21); live concurrent users 10,747 in 977 servers, peak concurrent players 10,327 (half-hourly average, +17.4%); the game card "Ride Storm" with 90% likes and 10.7K; a DevEx calculator with Robux submitted 2504293 in USD; and Sale DevEx Rates of 7,990,801 (standard) and 2,026,080 (US 18+). *(0:21, 1:03 frames viewed)*
- **Audience age skew toward DevEx** *(0:37-0:50)*: speaker says over 30% of Robux comes from users 18+, which affects DevEx rate. Opinion/claim.
- **Ads with every update** *(2:07-4:18)*: the speaker runs Roblox ads on each major update with a fresh set of creatives (visuals, thumbnails, descriptions), tests which gets the most clicks, and favours weekends for larger games (5-10k CCU+). Claims one idle game gained about 4,000 players after an ad. Opinion: advertising is "an investment with a payback", comparable to Meta/Google ads.
- **Price cut by demographic** *(4:18-5:30)*: the country chart (4:29) shows Mexico 12.4%, Philippines 9.0%, Indonesia 7.8%, India 5.7%, United States 4.8%, Colombia 4.7%, Vietnam 3.9%, Brazil 3.9%, Thailand 3.1%, Malaysia 2.4%. Mexico is the largest single country but not a majority; the speaker's "4%" for the US is closer to 4.8% on screen. The team halved prices of developer products and passes; speaker claims revenue rose about 5x. A slide at 5:28 says "higher prices does not mean better revenue". *(4:29 and 5:28 frames viewed.)* Single anecdote, no controls, no timeframe given.
- **Community feedback loop** *(5:34-7:15)*: 50,000-person Discord; many updates come from player requests; claimed to improve playtime. Opinion: "some requests are stupid" but listen anyway.
- **Short-form video marketing** *(7:15-7:40)*: TikTok clips from the Spanish-speaking community reach millions of views / 200k likes (speaker claim). The slide gives the reason as the game being "easily clippable" (captions misheard this as "hackable"), a social game where you "make up your own story".
- **Fresh experience per session** *(7:40-10:45)*: the speaker argues a game should give a "new experience every time", roleplay/social and event/admin-abuse style content, and not only a farm-and-leave grind; A screenshot shows Average playtime 23.1 min (daily average over the selected period, +1.6%); the speaker mentions 40+ minutes for other games and "almost all indicators green". Opinion/claim. Cites an egg-stealing game as the contrasting case that still has events.
- **AI use** *(10:46-14:20)*: slides state AI is "a tool to fasten your process of development", not a replacement for building, UI or scripting; "people are turned off by AI games and leave fast" if it is used as a whole builder (opinion, no data); players can tell AI-looking UI; design the interface and map yourself. Suggests an AI assistant connected to Studio via MCP to "scan my game and tell me what to improve" and give ideas. Opinion.
- **Longevity over a quick payout** *(14:10-14:45)*: speaker's earlier game peaked at about $10-15k/mo and died within one or two months. Claim.

## Visual check needed
Mostly resolved by the second pass. What is still worth a human look:
- **0:25-0:30**: the Sale DevEx Rates panel (7,990,801 vs 2,026,080, +125.6% and +95.1%): what period and whether "US 18+ Rate" is a subset or a separate figure is not stated on screen.
- **1:28-2:04**: any extra dashboard panels not covered by the cue frames (paying users, conversion rate, daily Robux spend per the speaker at 1:20-1:26).
- **9:00-9:20**: the Average playtime panel at full resolution; I read 23.1 min but did not open the full-size frame.
- **5:33-16:38**: I viewed contact sheets only, not each of the 70 keyframes; scan if any slide had an image I missed (all sheets showed text slides only).

## Hypotheses
- **H1: Regional price calibration can lift revenue more than raising prices** *(confidence: low, one anecdote)*. Test: post-launch, A/B or time-sliced prices on a developer product, using analytics by country. Do not pre-commit; prices are not approved ([[ADR-0011-Monetization-UI-Scope]]).
- **H2: Ads aligned with content updates pay back better than a one-off launch ad** *(confidence: low)*. Test: only after launch and with an approved budget; compare cost per retained player for update vs non-update windows.
- **H3: Repeated "something new each session" content (events, rotating rewards) raises playtime for a collector game** *(confidence: low-med)*. Test: Playtests with the existing Journal/haunt loop; measure session-to-session return, not just single-session length.
- **H4: Players penalise obviously AI-made UI** *(confidence: low)*. Test: blind A/B of hand-designed vs generated UI in playtest feedback.

## Relevance to our game
- Approved scope is cosmetics only, direct Robux plus earned Coins, no premium currency or paid convenience yet ([[ADR-0011-Monetization-UI-Scope]], [[SYS-Haunted-Monetization-UI]]). The video's pricing and ads lessons are inputs for a later, separate pricing task; they do not change scope.
- Prior discovery: [[RSH-20261013-Haunted-Monetization-Discovery]]. Platform economics context: [[RSH-20261010-Roblox-Platform-Economics]]. Related video notes: [[RSH-20261014-Good-UI-Principles-Video]].
- Server authority and approved ADRs win. Prices, product IDs and spending still need explicit human approval (AGENTS.md safety rules); ad spend is "spend money" and also needs approval.
- Reference check: `10 References/05 Misc/` has no matching reference beyond the notes above (no live-ops or pricing reference); `01 UI` was not relevant to this video's content. Nothing under `10 References/` was edited.
- Genre mismatch: the video's game is a social/roleplay/vehicle title with a mostly Latin American and Southeast Asian audience. Our collector-horror audience is unmeasured; do not assume the same price sensitivity.

## Original implementation ideas
- Build a country-aware analytics view in our own dashboard notes after launch (country share of purchases, per-product conversion) before touching any price.
- Plan a "what's new" cadence for the Journal that gives each login a different small goal (ghost of the night, rotating collection target), without fabricated urgency (consistent with ADR-0011's permanent-catalog consequence).
- Keep a short update checklist (new thumbnail, store description, announcement) as a live-ops template; no ad purchases without approval.
- Gate UI quality: hand-authored icons and layouts only, as already required by the reference-first rules.

## Recommendations (max 3)
1. File the pricing/regional idea (H1) as a deferred item for the pricing step that ADR-0011 explicitly left open; collect country analytics first.
2. Treat paid ads as a post-launch, human-approved budget item, with the update checklist above prepared in advance.
3. Do not act on the revenue figures themselves; use only the structural lessons (live-ops cadence, community feedback, demographics) as planning prompts.

## Needs human review
- Unverified conclusions:
  - All revenue, CCU, "5x" and ad-result numbers are self-reported by the speaker; screenshots are the creator's own and unverified. The monthly figure is an extrapolation (about 10x a 3-day total) and may not include seasonality.
  - "Hourly cost of about $9,500" in the captions is garbled; the dashboard shows 2,504,293 Robux for the selected period, but the period length is only the speaker's "3 days".
  - The "5x revenue" result has no baseline, period or control.
  - Contact sheets rather than individual frames were reviewed for 5:33-16:38.
  - Genre transferability to a collector-horror game.
  - Timestamps are caption timestamps (rolling auto-captions, about 1 s granularity).
