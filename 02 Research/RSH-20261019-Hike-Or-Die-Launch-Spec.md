---
id: RSH-20261019-Hike-Or-Die-Launch-Spec
title: Hike or Die launch specification
project: GAME-003
type: research
status: proposed
confidence: medium
created: 2026-10-19
updated: 2026-10-19
tags:
  - research/launch
related:
  - "[[AUD-20261019-TASK-0087-04]]"
  - "[[RSH-20261019-Hike-Or-Die-Delivery-Plan]]"
  - "[[RSH-20261019-Hike-Or-Die-Commercial-Plan]]"
---
# Hike or Die launch specification

## Question
What must GAME-003 deliver to launch credibly and build repeatable income, with next week as the requested launch window and $50 maximum remaining cash?

**Decision (jg, this chat, 2026-10-19):** aim to earn as much as possible; aim for most development today, launch next week, then frequent updates the following week. Remaining project cash cap is $50, reserved for necessary tools with substantial demonstrated efficiency gains. This sets priorities and constraints; it does not approve particular purchases or waive release gates. No monthly bill amount was supplied.

**Assumption:** next week means October 26–November 1, 2026, America/Los_Angeles. Frequent follow-up updates means November 2–8. Schedule is conditional, not a delivery guarantee. This spec is planning work; its packages are not automatically executed or approved by being listed.

## Sources
| Source | Location | Accessed |
|---|---|---|
| Current build and evidence | [[AUD-20261019-TASK-0087-04]] at `c85b279` | 2026-10-19 |
| Scope and decisions | [[GAME-003 Hike or Die/01 Game Design]], ADR-0014/0015 and TASK-0087 | 2026-10-19 |
| Visual direction | [[REF-MAP-001-Dark-Fantasy-World]], [[REF-MAP-002-Stylized-Swamp-Encounter]]; opened original preserved frames Dark-Fantasy-00-03.jpg and Swamp-00-08.jpg | 2026-10-19 |
| Platform release requirements | [Roblox publishing](https://create.roblox.com/docs/production/publishing/publish-games-and-places) | 2026-10-19 |
| Business and model sources | Linked commercial and delivery plans | 2026-10-19 |

## Observed mechanics (verified)
One solo trail, one blockout cryptid, server-scored metadata, extraction/failure/restart and limited spawn variation exist. Headless tests pass. Camera usability, fair escape and current full-loop behavior are not proven. No production persistence, co-op, monetization or live analytics are implemented in inspected source. Detailed findings and limits are in the audit; do not translate TASK-0087's done status into Gate 1 success.

## Hypotheses
- **Medium confidence:** a reliable, readable camera → risky photo → escape → collection loop may earn voluntary replay. Test this before expensive content work.
- **Low confidence:** co-op rescue and collectible discoveries will sustain returning players. Need real groups and D1/D7 cohorts.
- **Low confidence:** camera/gear cosmetics and supporter identity can earn revenue without selling survival advantages. Need actual purchases and repeat usage, not survey enthusiasm alone.

## Relevance to our game
The product promise is photographing dangerous cryptids with friends and bringing the proof home. A minimal commercial release must deliver that promise, remain usable solo, and make a second expedition feel worthwhile. Revenue is an outcome of a valuable repeatable experience, audience acquisition and reliable payments; launch alone proves none of these.

## Original implementation ideas
**Recommended constrained launch scope, pending jg approval:** one polished forest trail with two readable approaches and extraction; 1–4 player expeditions; two behaviorally distinct cryptids with at least three photo-worthy states each; three controlled encounter variants; six reusable contracts; a persistent metadata journal with at least twelve discovery/quality milestones; a small free cosmetic unlock track plus two optional paid cosmetic/supporter offers. Prototype the second creature's behavior before commissioning final art. Counts are starting scope proposals, not validated content requirements. H06/H25 must show enough novelty for three consecutive runs before content is accepted.

If this cannot be proven within the week, release an explicitly limited test only after technical/safety gates, or postpone. A solo preview must be described as solo and needs jg's scope decision. Never advertise friends, saved photos or purchases that are absent. Optional image sharing remains deferred; journal cards can represent verified evidence metadata without promising permanent photographs.

### Product requirements and acceptance
All rows are **Planned** unless the audit marks a partial prototype implementation. `P0` is mandatory for the stated release; `P1` must exist before scaling or is explicitly conditional; `Later` is deferred.

| ID / priority | Requirement | Done means / evidence | Delivery packages |
|---|---|---|---|
| R01 P0 | Stable camera and controls | Agreed yaw/pitch/movement mapping, sensitivity/inversion, collision/occlusion behavior, reliable raise/lower/shutter, no reset on score updates. Keyboard/mouse and actual touch users complete consecutive shots while moving; focus loss, menus, respawn and reconnect restore controls. | H02,H03,H05 |
| R02 P0 | Fair encounter and extraction | Detectable anticipation, readable pursue/lose/return, usable cover and alternate route, no catch through obstruction or path-failure wall crossing. Empty exit, dead player, failure/extract race and replay have deterministic outcomes. | H03,H04,H10 |
| R03 P0 | Evidence worth collecting | Server grades subject, state, range and framing; clearly explains rejection and quality; rewards unique discoveries/skill, not shutter spam. Bounded evidence, run duration and grants; carried/banked/lost values agree. | H10,H11,H20 |
| R04 P0 for advertised co-op | Friends and solo | 1/2/4-player rounds, ready/leave flow, clear party membership, invitations/fallback joining, late-join rule, disconnect handling and safe return to camp. No requirement to speak or use voice. Solo remains completable. | H08,H09,H24 |
| R05 P0 for advertised rescue | Downed/rescue/end states | Server validates alive rescuer, range, duration, obstruction and cancel; multiple rescuers do not duplicate grants. Party wipe, one survivor, abandoned player and extraction resolve. Spectating cannot affect rewards; griefing cannot trap players indefinitely. | H09,H20,H24 |
| R06 P0 | Onboarding and readable UI | First-session objective → raise → frame → feedback → risk → extract → journal → replay. Contextual hints, skippable tutorial/replay, every button works, safe areas and readable text; clear loading/empty/error/save-failed states. Shop appears after value is demonstrated. | H14,H17,H25 |
| R07 P0 | Replay and progression | Discovery journal, banked quality improvements, finite free goals and explicit next goal. Three runs reveal different decisions; six contracts tested for solvability and payouts. No compulsory daily streak or paid advantage. | H11,H15,H25 |
| R08 P0 | Durable player data | Versioned schema, separate test/live namespaces, concurrent-session control, atomic/idempotent reward writes, bounded retry/backoff, autosave/leave/shutdown, no default overwrite on failed load, migration/rollback and recovery rehearsed. Purchases survive reconnect; failures communicate honestly. | H12,H20,H24 |
| R09 P0 before sales | Reliable optional purchases | Small approved SKU catalog; accurate dynamic price/ownership display, clear benefit/previews, cancel/error handling, durable ownership and grant recovery. Developer products require idempotent server receipt handling. Remove unsafe sales entirely until fixed. | H13,H18,H19,H20 |
| R10 P0 | Production presentation | Approved creature silhouette/model/rig, state animations, original forest/landmarks, camera prop, extraction/camp props, coherent UI. Compare against model baseline and selected original references in actual gameplay light; no blockout accepted as finished art. | H07,H16,H17 |
| R11 P0 | Sound/VFX/accessibility | Rights-cleared ambience, footsteps, directional threat cues, shutter, grade, pursuit, rescue and extraction sounds; state animation and restrained feedback. Volume controls, captions/visual equivalents for key sound cues, reduced motion/flashes, adequate darkness/contrast and non-color-only states. | H16,H17,H22 |
| R12 P0 | Device and performance quality | Minimum supported devices recorded; desktop plus physical iOS/Android for advertised mobile. Profile full four-player session, networking, pathfinding, memory and effects. Loading failure and missing assets recover. Controller/console/VR excluded unless explicitly selected and tested. | H05,H23,H24 |
| R13 P0 | Security | Validate every remote's shape, finite values, rate, phase, ownership, alive status, position plausibility and permissions; server owns reward/extract/rescue/purchase state. Fuzz missing/oversized/bad inputs and impossible movement. Reject cheaply; bound payloads/collections/work. | H10,H12,H13,H20 |
| R14 P0 | Useful analytics | Server funnel and trusted outcomes, stable event/version IDs, run duration, abort/loss reasons, client input diagnostics separately labeled. Dashboard receipt checked in authorized test environment; retention, device performance and revenue denominators defined. | H06,H21 |
| R15 P0 | Release, rights and support | Owner/universe/place IDs confirmed; account security/roles, asset permissions/licences, age/content disclosure, audience settings, platform eligibility and moderation complete. No unfiltered custom user text. Support/bug channel, update notes, known issues and crash triage owner ready. | H00,H07,H26,H28 |
| R16 P0 | Deployment and rollback | Pinned build, passing CI, clean matched-place smoke, feature flags for sales/new content, previous build retained, forward/backward data compatibility. Rehearse rollback and emergency sale disable before release. Human REL approval names build and limitations. | H01,H24,H27 |
| R17 P0 to acquire players | Honest discovery package | Original legible icon, at least two truthful thumbnails, short gameplay clip, concise description/controls, device/party limits and onboarding promise. jg approves publishing/outreach; track visits→play→first evidence→return. | H26,H29 |
| R18 P1 before scaling | Sustainable business | Cash received and eligible Earned Robux reconciled; purchase/retention cohorts measured; acquisition experiment has spend cap and stop rule. Next content update ready and support load sustainable. | H25,H29,H30 |
| R19 Later | Expansion | More maps/creatures, procedural generation, trading, public photo uploads, battle passes, subscriptions, paid revives, competitive leaderboards and complex cross-server lobby. Require evidence of need and separate scope. | Post-launch only |

### Gate evidence
These are proposed local acceptance thresholds, not Roblox benchmarks or revenue forecasts. Declare them before recruiting testers and record raw counts, devices, build, cohort and exclusions.

| Gate | Required evidence / decision |
|---|---|
| G0 — honest baseline, today | H00/H01: current scope/queue claims reconciled, original brief recovered or missing acknowledged, HOD included in CI, dedicated place known. |
| G1 — hook works | H02–H06: ten consecutive human-controlled round cycles without camera/round blocker; successful risky evidence→escape→bank→restart plus failure/loss. Five fresh target users initially: at least four take valid evidence and explain bank/loss without coaching within five minutes; at least three voluntarily replay and name a reason. At least two real touch users if mobile targeted. Directional sample only; if failed, revise the hook before content. |
| G2 — production alpha | 1/2/4 players validated; progression/persistence fault matrix passes; two distinct creatures and three variants; all configured content completable. Separate approval of world/data/network decisions and scope. |
| G3 — limited release ready | Zero known reproducible loss/duplicate purchase/progress bugs or core softlocks; independent high-risk review complete; physical device/performance gates met; rights/audience approval; actual purchase recovery validated with approved test method; rollback drill and REL approval. |
| G4 — launch next week, conditional | G3 plus fresh-user test and verified analytics ingestion. Begin limited exposure, stage expansion after 48 hours of stable errors/save/purchase outcomes. Publish only after jg approval. Missing cohort maturity cannot be declared a pass. |
| G5 — scale / income evidence | See commercial plan: mature D1/D7 and eventually D30 cohorts, observed net contribution and no dependence on one spender. Larger acquisition spending is separately approved; $50 reserve is not an ads budget. |

### Proposed measured performance gates
At approved minimum hardware: mobile p95 frame time ≤33.3 ms and desktop target ≤16.7 ms during a representative four-player expedition; server p95 heartbeat frame ≤33.3 ms. No sustained frame spikes that prevent aiming, no crashes in a 30-minute soak, no monotonically growing retained resources across 20 rounds after warmup. Initial target p90 join-to-control ≤15 seconds on a documented network. These are proposed targets to measure and ratify, not claimed results. Set absolute memory, instance, triangle, texture and bandwidth budgets from H23's baseline before final art integration. Re-test under ~150 ms and ~300 ms round-trip latency; measure reward acknowledgement and avoid false failure feedback.

### Required scenario matrix
- Input: desktop/touch, three viewport sizes, two-thumb move/aim/shutter, menu/chat focus, touch cancellation, background/resume, low FPS, avatar scaling, camera near walls, extreme aim.
- Loop: quiet/reaction/pursuit photo, blocked/invalid shot, repeated state, cover escape, no-path fallback, catches, empty/valuable extraction, death/extract overlap, rapid restarts, disconnect at every phase.
- Co-op: 1/2/4 players, mixed devices, leader leaves, late join, conflicting rescues, disconnected downed player, partial extraction/wipe, unequal latency.
- Data/purchases: failed/throttled load/save, stale schema, concurrent session, shutdown mid-save/grant, duplicate/out-of-order receipt, unavailable product, owned item, cancel, refund/support procedure and reconnect.
- Content: every contract/variant, asset permission failure, sound-off readability, reduced motion, long soak and all item equip/unequip paths.

## Recommendations (max 3)
1. Spend today's best reasoning and testing on camera, fair escape and reliable state; defer production expansion until G1 evidence.
2. Attempt next week's limited launch only with G3 satisfied; shrink content breadth before reducing safety, visual quality or core-loop reliability.
3. Instrument repeat use and net income, then ship small measured updates. Do not spend the $50 reserve to hide weak retention.

## Needs human review
Approve minimum content count, target ages/devices, co-op/rescue scope, final art direction and SKU concepts; supply original brief and choose the minimum monthly bill target when useful. Decide production activation independently of this planning document. Release/purchases/uploads remain explicitly gated. No external analytics, current player population, income, device results or platform eligibility was verified in this audit.
