---
id: RSH-20261014-Roblox-Viral-Game-Lessons-Video
title: Lessons From Three Viral Roblox Games (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/_JyiKfNNqls
confidence: low
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/onboarding
  - research/progression
  - research/monetization
---
# Lessons From Three Viral Roblox Games (video)

> **Draft.** One developer's post-mortem and opinion, read from German auto-captions plus 6 of 94 frames. Nothing here is approved, and no figure is independently verified.

## Question
Which onboarding, progression-tuning, monetization and playtest practices from a creator's post-mortem of a faded "raise an anomaly" simulator could improve Haunted Collector's first session, tuning process and (later) shop, without copying that game's mechanics, assets, names or numbers?

## Sources
| Source | URL | Accessed |
|---|---|---|
| "I Made 3 Viral Roblox Games in a Row (Here's What I Wish I Knew Sooner)" (uploader: Tizzy RBLX, 24:54) | https://youtu.be/_JyiKfNNqls | 2026-10-14 |

**Evidence limits.**
- **Captions:** auto-generated, tagged German (`de`, provenance unknown). The title and on-screen text are English, so these are probably machine translations of English speech. I read them in German; wording, numbers and names may be garbled.
- **Frames:** the local engine selected 94 frames (scene-change, balanced). I viewed 6 (at 2:08, 8:11, 10:45, 11:50, 17:42, 18:32). The other 88 were not viewed. Frame sampling over 25 minutes is sparse.
- **Audio:** not heard. No speech-to-text fallback was run.
- **Gemini:** the quota was exhausted (20 requests/day), so no whole-video read was obtained.
- **Speaker claims:** every revenue, CCU, retention and sales figure is the speaker's own screenshot or statement, not independently verified.

**Reference compared:** `10 References/01 UI/UI References.md` and `10 References/05 Misc/Misc References.md` (index notes only; no matching onboarding, telemetry or monetization references exist there). `10 References/03 Sounds/Sound References.md` is irrelevant to this video. Nothing in `10 References/` was edited.

## Observed mechanics (verified)
"Verified" here means the transcript says or a viewed frame shows it, not that it is true. Timestamps are *(m:ss)*. The game discussed is a "raise an anomaly" simulator: players steal an egg, hatch it, feed the creature, and buy conveyor speed upgrades.

**Onboarding**
- The speaker tracks each onboarding step as a funnel: join, steal egg, enter safe zone, return to plot, equip egg, place egg, hatch *(2:08-2:24)*. The largest drop was "steal egg". A frame at 2:08 shows a step table with per-step counts and percentages *(frame viewed)*.
- **Opinion:** he believes the title promised something other than egg stealing, so the core loop misled players *(2:24-2:55)*.
- Forcing the player to equip the egg from the hotbar created a drop-off; successful games auto-equip it *(2:55-3:44)*. He wants "a smooth first 90 seconds".
- Food was pre-placed in the starting inventory, and the player is taught where food comes from only when it runs out *(3:44-5:01)*. He names this a contextual tutorial.
- The first feeding makes the creature grow to 5x for a "wow" moment *(5:16-5:31)*.
- Teach the core loop, then let players play; don't switch teaching context too fast; avoid pushing many systems at once *(5:31-7:40)*.
- Contextual tutorials fire from backend triggers, e.g. reaching 1K cash shows where to buy trails, and trying to place a creature on a full plot shows plot upgrades *(6:34-7:24)*.
- Let the player feel one upgrade before showing the next *(7:24-7:40)*.

**Progression and balancing**
- Early retention (D1) was poor at launch (he quotes 6-8%) and improved after a progression overhaul *(7:55-8:26)*. A viewed frame at 8:11 shows a cohort table where later cohorts are visibly higher on D1 and D2; read numbers off the frame yourself.
- **Opinion/own admission:** he tested only on his fully unlocked account, never a fresh second account *(8:42-9:12)*.
- Method: write a minute-by-minute self-play log, e.g. "minute 5, zone 3" *(9:12-9:29)*.
- A progression wall at about minute 10 of the first session: conveyors too expensive, players didn't know how to upgrade the plot *(9:29-10:01)*.
- A progression funnel was added, tracking when each conveyor is bought and when the plot is upgraded *(10:17-11:18)*. He reports about 60% bought the first conveyor and about 26% upgraded the plot. A viewed frame at 10:45 shows a funnel table with per-step completion and churn columns.
- He pays 2-3 testers 1,000-2,000 Robux to grind about three hours and record time, cost and "stuck" notes in a long document *(11:34-12:20)*. A viewed frame at 11:50 shows such a document (first-person timestamps and prices).
- He then feeds the logs, screenshots and a reference game into an AI chat to brainstorm balancing changes *(12:20-12:51)*.
- **Opinion:** "track every milestone, then use testers"; he concedes it may not be the best method *(13:06-13:52)*.

**Monetization**
- **Opinion:** launch with monetization from the start; he introduced limited items about two weeks after launch and regrets it *(14:07-14:52)*.
- A scarce "whale" limited item (about 1,000 Robux, 1,000 in stock) became the second-best seller; an admin/"ultimate" conveyor was added later *(14:36-15:08)*.
- He regrets money-pack sales and giving away strong items too often during an admin-abuse event; he thinks both hurt the economy *(15:23-15:38)*.
- He added a limited item aimed at the female half of the audience (about 50% by his demographic data) *(15:38-16:10)*.
- A scarce, pricier strong food became the best-selling food *(16:10-16:25)*.
- His "strategy": consumables (instant hatch), cheap stackable entry products to cross the "player to payer" threshold, tiered speed multiplier at 5, then 9 Robux and rising, with 61,000 sales on tier 1 *(16:25-17:13)*.
- ARPDAU rose from about 0.9-1.0 to about 2.0 after "whale sinks", dipped as the game died, and recovered after fixing shop UX on mobile *(17:28-17:59)*. A viewed frame at 17:42 shows a Creator dashboard "average Robux spent per daily" chart annotated in red.

**Feedback and testing**
- An in-world mailbox lets players leave feedback, which he reads in the Creator dashboard Feedback tab with an AI summary *(18:14-18:45)*. A viewed frame at 18:32 shows that tab (rating, device, platform, timestamp, comment).
- **Opinion:** he wishes he had a dedicated tester group before launch, because daily patches after entering the algorithm hurt *(18:45-19:00)*.
- A separate published test place lets you test on live Roblox, not only Studio *(19:00-19:15)*.
- A tester found an item exploit that would have broken the economy and topped the leaderboard *(19:30-19:45)*.

**Team management (opinion throughout)**
- Vague briefs ("plush-style, full creative freedom") gave three clashing art styles, and he abandoned those models *(20:15-21:02)*. He recommends a style guide up front and clear references *(21:02-22:48)*.
- Hire fast, replace non-delivering contractors quickly, and don't tolerate mediocrity *(21:32-24:05)*. He says he'd previously wasted USD 800 on models and USD 300 on a discarded map *(20:46, 21:32)*.

## Visual check needed
I viewed 6 frames only. Review these yourself:
- **2:08-2:24, 2:34-2:40:** onboarding funnel table (step counts and conversion).
- **8:04-8:26, 9:34-9:53:** D1 cohort tables before/after the overhaul. I read direction, not exact values.
- **10:34-11:18:** progression funnel (conveyor and plot upgrade completion).
- **11:49-12:17:** the tester document format (what columns a good run log has).
- **14:36-15:08, 16:57-17:16:** product sales lists and the tier-1 volume figure.
- **17:42-18:09:** the Robux-per-daily chart annotations.
- **18:32-18:42:** Feedback tab and AI summary layout.
- **20:53-22:23:** the clashing art-style comparison.

## Hypotheses
- Delivering the core capture action in the first 90 seconds with no inventory step (auto-equip equivalent) reduces early drop-off. *(confidence: medium; compare step-completion in a fresh-account Studio run and a playtest note)*
- Delaying secondary tutorials until a trigger (first full plot, first upgrade affordable) reduces confusion more than a long linear tutorial. *(confidence: low-med; our 12-step tutorial may already cover this, so audit step timing)*
- Our first-session progression has a wall similar to the one described (cost vs time to next zone/tier). *(confidence: low; test with a fresh-account timed run and per-milestone logging)*
- Paid testers with a fixed log format find tuning problems faster than self-testing. *(confidence: low-med; run one structured session and compare issues found)*
- Scarce, high-priced "whale" items drive revenue in simulators. *(confidence: low for us; the video is one game's data, and ADR-0011 defers this)*

## Relevance to our game
Server authority, approved ADRs and AGENTS.md win over anything here.
- **Onboarding and tutorial:** compare against the shipped tutorial in [[TASK-0018-Journal-Tutorial-And-Rare-Clue]] (resumable 12-step state machine) and the capture loop in [[SYS-Haunted-Capture-Loop]]. Useful question: which steps force a menu or inventory action before the first capture?
- **Progress data and funnels:** milestone counters would be player data and need server-owned writes, see [[SYS-Haunted-Player-Data]] and the persistence checks in [[TASK-0019-Persistence-And-Rejoin-Test]]. Any analytics change needs its own scoped task.
- **Tester and playtest practice:** matches the existing playtest notes under `07 Playtests/` (e.g. [[TEST-20261012-10]]). A second fresh account maps to our existing 2-player Studio limit; a fixed log format is new.
- **Monetization:** limited whale items, money packs and consumables conflict with [[ADR-0011-Monetization-UI-Scope]] (cosmetics only, no premium currency or paid convenience, no fabricated limited-time urgency). Only the discovery-level ideas (cheap entry cosmetic, mobile shop UX) stay compatible. See also [[SYS-Haunted-Monetization-UI]] and [[RSH-20261013-Haunted-Monetization-Discovery]].
- **Adjacent research:** the video's game is in the anomaly-raising, egg-stealing space covered by [[RSH-20261010-Coop-Anomaly-Horror]] and [[RSH-20261010-Steal-Collect-Base]]. Platform-level economics: [[RSH-20261010-Roblox-Platform-Economics]].
- **Overlap with the UI note:** [[RSH-20261014-Good-UI-Principles-Video]] covers HUD/shop clarity; this note covers flow and tuning.

## Original implementation ideas
Ours, to validate before any task.
- A **first-session timeline sheet** in the task note: target minute for first capture, first return trip, first journal entry, first upgrade, and the "stuck" signal for each.
- **Contextual hints** keyed to game state, e.g. hint how to raise the house tier only when a capture is blocked by plot capacity, built on the existing tutorial state machine rather than a new system.
- **Fresh-account Studio run** as a checklist item for progression or tuning tasks: reset player data, then run the first 10 minutes without dev unlocks.
- **Tester log template** (time, step, cost, blocker, mood) stored as a playtest note.
- A private **feedback prompt** concept for the Mansion (e.g. a spirit-board object), only after privacy, moderation and DataStore scope are decided.

## Recommendations (max 3)
1. Audit the existing tutorial and first 10 minutes against the "no friction before the first capture" and "contextual, not up-front" questions, using a fresh-account run, before changing anything.
2. Draft a tester log template and use it in the next playtest note.
3. Don't act on the monetization claims; keep them as context until ADR-0011's "progression is measured" condition is met.

## Needs human review
- Unverified conclusions:
  - Every number (D1 6-8%, 60% conveyor, 26% plot upgrade, ARPDAU about 0.9 to 2.0, USD 44K/32K revenue) is from German auto-captions and a few frames, not verified.
  - Whether any retention or monetization effect would transfer to a different genre and audience.
  - Whether the machine-translated captions mis-state names or figures.
  - The 88 frames I did not view.
- Whether to add the fresh-account run and tester template to `04 Agents/Workflows/` (not changed here).
- Whether the speaker's claims about AI art and contractor performance are relevant at all (opinion, not used above).
