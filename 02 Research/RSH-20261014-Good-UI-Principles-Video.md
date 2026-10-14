---
id: RSH-20261014-Good-UI-Principles-Video
title: Good vs Bad Roblox UI Principles (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/haf0V--67Ac
confidence: low
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ui
  - reference/ui
---
# Good vs Bad Roblox UI Principles (video)

> **Draft.** Speaker opinion from machine-translated captions, frames not viewed. Nothing here is verified or approved.

## Question
Which practical UI principles from a Roblox creator's "psychology of good UI" lesson can shape Haunted Collector's HUD, Journal, Mansion and the approved Shop/monetization UI, without copying any game's assets or layout?

## Sources
| Source | URL | Accessed |
|---|---|---|
| "the psychology behind good ui within roblox games" (uploader: Twine, 27:38). Free sample module from the creator's paid course. | https://youtu.be/haf0V--67Ac | 2026-10-14 |

**Evidence limits.** Auto-generated Arabic captions (apparently machine-translated), not the audio. Frames were **not** viewed, so the on-screen examples (Pet Simulator 99 and others) are known only as narrated. Timestamps show where to re-check.

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

**Visual check needed** (the transcript alone is insufficient): 0:30–5:00 icon examples, 5:00–11:00 HUD counts, 16:13–17:10 collapsed menu, 19:48–20:18 palette and font comparisons.

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

## Recommendations (max 3)
1. Use the checklist as an optional review step in UI task notes. Don't make it a gate until a playtest supports it.
2. For the next UI task, cite this note and name the two principles that will shape the work (reference-first development).
3. Before promoting anything to a `LES-` lesson, view the frames at the "Visual check needed" timestamps (`/watch`, or Gemini).

## Needs human review
- Unverified conclusions: every principle is the speaker's opinion from machine-translated captions without frames.
- Whether the checklist becomes part of the UI review workflow, and where.
- Whether any principle conflicts with the approved Shop/monetization scope.
