---
id: RSH-20261014-Good-UI-Principles-Video
title: Good vs Bad Roblox UI Principles (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/haf0V--67Ac
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ui
  - reference/ui
---
# Good vs Bad Roblox UI Principles (video)

> **Draft.** Speaker opinion. Evidence is captions plus Gemini's video read (picture and audio), not our own viewing of frames. Nothing here is approved.

## Question
Which practical UI principles from a Roblox creator's "psychology of good UI" lesson can shape Haunted Collector's HUD, Journal, Mansion and the approved Shop/monetization UI, without copying any game's assets or layout?

## Sources
| Source | URL | Accessed |
|---|---|---|
| "the psychology behind good ui within roblox games" (uploader: Twine, 27:38). Free sample module from the creator's paid course. | https://youtu.be/haf0V--67Ac | 2026-10-14 |

**Evidence and method.** Two passes on 2026-10-14:
1. Auto-generated Arabic captions (apparently machine-translated), via the local engine. No frames viewed.
2. Gemini (`gemini-3.7-flash`, agentic video) over the whole video in 2–5 minute segments. It reports slide text, on-screen examples and timestamps, and was cross-checked against the captions.

Gemini output is secondary evidence, not our own observation. It was **internally inconsistent in one place**: segment 20:00–25:00 calls the Rewards/Daily modal bad, while 25:00–27:37 lists a "Rewards / Daily Streak" modal as good. Game names it gives (e.g. "TiresomeNewbie") are avatar or UI text it read, not verified titles. Timestamps show where to re-check.

## Observed mechanics (verified)
Observed in the transcript only (speaker claims, not measured facts). Timestamps in *(m:ss)*.
- **Icons carry meaning without text** *(0:30–5:00)*: shoe+bolt for speed, egg+number for egg count, moon+countdown for night. Text under an obvious icon is clutter.
- **Small HUD** *(5:00–11:00)*: about seven always-visible elements, each readable at a glance.
- **One icon per concept** *(8:30–9:20)*: reuse the same icon across surfaces so players link them without reading.
- **Rewards as icon + number**, not sentences *(8:05–8:36)*.
- **Small palette, clean font** *(9:30–10:30, 14:12–14:42, 19:48–20:18)*: about three main colors; no random gradients or chunky fonts.
- **Collapse secondary content behind one button** *(13:40–13:50, 16:13–17:10)*; show detail only after a click.
- **Place by attention** *(15:12–16:00)*: critical info near the eyes (upper middle), not bottom corners.
- **Uniform sizes, spacing, alignment** *(19:48)*.
- **Not a guarantee** *(24:20–26:00)*: the speaker concedes weak-UI games can succeed.

### Added by the Gemini pass (slides and on-screen detail)
- **The speaker's own checklists** *(slides at 0:58, 5:36, 9:25)*: Good UI = *Show, not tell · Conveys the purpose · Simple · Clean font*. Bad UI = *Bad color palette · Chunky, blocky font · Cluttered · Too complex · Can't be discerned from first glance*.
- **Progressive disclosure is the main fix** *(13:40–14:06, 16:32–17:07)*: five separate crate buttons should be one button that opens a sub-screen. Reference game: Pet Simulator 99's basket/shop and inventory.
- **Tier scale shown visually** *(7:16–7:49)*: speed packs use one shoe, a pair, a pile, a bag, a chest, so value reads without numbers.
- **Remove heavy frames and borders** *(18:18–18:36)*: thick black backings around every button add noise.
- **Merge near-duplicate surfaces** *(18:37–18:50)*: separate "Shop" (in-game currency) and "Store" (Robux) could be tabs in one window.
- **Avoid duplicate controls** *(21:24–21:30)*: e.g. Rebirth in the sidebar and again in the bottom bar.
- **Avoid AI-generated UI art** *(22:24–23:44)*: the speaker says players notice and are put off; a tinted frame, UI stroke, subtle texture, clear text and simple vector icons are enough.
- **Fredoka-style fonts read as dated** *(20:13–20:23)* — his opinion, not a measured fact.
- **Hierarchy of attention** *(15:37–16:00, 19:30–19:41)*: stats crammed in the bottom-left are called poor; Server/Invite belong upper-right.

**Still worth checking visually** (not independently verified): 0:30–5:00 icon examples, 5:00–11:00 HUD counts, 16:13–17:10 collapsed menu, 19:48–20:18 palette and font comparisons.

## Hypotheses
- Following these reduces first-session confusion for the young audience. *(confidence: medium; test with a playtest note and a "what is this button?" check)*
- Icon-first labeling suits a haunted theme but may fail for abstract items (cosmetic categories) that need a label. *(confidence: low; test in a Shop mockup)*

## Relevance to our game
- **Shop / monetization UI**: [[SYS-Haunted-Monetization-UI]] has five categories, filters and acquisition labels. Best overlap: *collapse to one entry, detail on demand* and *no text that repeats an icon*. Acquisition and ownership states stay explicit, even as labels. That rule wins ([[ADR-0009-Monetization-UI-Scope]]).
- **HUD**: small, icon-led always-visible set. Journal and Mansion open from single, consistently iconed buttons.
- **Theme**: palette and font stay in `games/haunted/src/client/UI/Theme.luau` as one source, not per screen.
- Related: [[UI References]], [[RSH-20261013-Haunted-Monetization-Discovery]].

## Original implementation ideas
Ours, to validate in a mockup first.
- One "Collection" hub button opening Journal, Mansion and Shop tabs, instead of three parallel buttons.
- A shared icon set for currencies, ownership and acquisition states, defined once in the theme layer.
- A 3-color base HUD with one accent reserved for actionable items.

### Review checklist (draft, optional for UI tasks)
1. **Glance**: can a new player name each always-visible element without reading?
2. **Count**: how many elements at rest, and is each needed during play?
3. **Icon reuse**: same concept, same icon, everywhere?
4. **Text** only where an icon cannot do the job (state, price, ownership, errors).
5. **Palette and font** come from `Theme.luau`.
6. **Placement**: critical info near the play area; secondary behind one entry.
7. **Consistency**: sizes, spacing, alignment match siblings.
8. **Disclosure**: are parallel buttons that serve one purpose grouped behind one entry?
9. **Chrome**: do heavy frames or borders add noise, and are two surfaces doing one job (Shop vs Store)?

## Recommendations (max 3)
1. Use the checklist as an optional review step in UI task notes. Don't make it a gate until a playtest supports it.
2. For the next UI task, cite this note and name the two principles that will shape the work (reference-first development).
3. Before promoting anything to a `LES-` lesson, view the frames at the "Still worth checking visually" timestamps.

## Needs human review
- Unverified conclusions: every principle is the speaker's opinion, read through captions and Gemini rather than our own viewing. Gemini was inconsistent on the Rewards modal.
- Whether the checklist becomes part of the UI review workflow, and where.
- Whether any principle conflicts with the approved Shop/monetization scope.
