---
id: RSH-20261014-Animated-Shine-Button-Video
title: "How to Make an Animated Shine Button in Roblox Studio (video)"
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/AOyax0QFuyE
confidence: medium
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ui
  - research/vfx
---
# How to Make an Animated Shine Button in Roblox Studio (video)

> **Draft.** A hobbyist tutorial; speaker claims are unaudited and nothing here is approved.

## Question
UI variant: how is an animated highlight sweep built from one transparent image and a tween loop, and what does that suggest for shop or reward buttons? General knowledge-building for GAME-002, tied to no task. Tags: (general) = applies to game work anywhere, (Roblox-specific) = Roblox Studio or its engine, (Blender) = Blender.

## Sources
| Source | URL | Accessed |
|---|---|---|
| "How to Make an Animated Shine Button in Roblox Studio", uploader MrWonderHow, 5:44 | https://youtu.be/AOyax0QFuyE | 2026-10-14 |

**Evidence limits.**
- Captions: English, auto-generated, readable but with mistranslations; the speaker's English appears machine-translated in places. Scripts are described as "shown on the screen", so exact code and numeric property values are mostly not in the captions.
- Frames: 4 cue frames at 1024 px viewed on a contact sheet (640 px tiles), plus 12 sweep frames across the whole video (480 px contact sheet; not opened for every video). Fine text and numbers on screen were mostly not legible at these sizes.
- No audio was heard by us.
- **References compared:** the project's existing research notes and `10 References/` index notes were checked for overlap; nothing in `10 References/` was edited. No code from the video was copied.

## Observed mechanics (verified)
Verified means said in captions or seen in a viewed frame. Timestamps *(m:ss)*.
- The effect is a single soft diagonal white stripe on a transparent PNG, imported through the Asset Manager and set as an ImageLabel named "shine" child of the button. *(0:39-1:46)* (shown: the black/white diagonal stripe image)
- The shine is wider than the button; ClipsDescendants on the button masks it to the button shape (rectangular clip only), and the image has ZIndex above other elements. *(2:11-3:23)* (Roblox-specific)
- A LocalScript tweens the shine from X -0.6 to 1.6 in 0.6 s with Quad Out easing, then waits 2 s and repeats, snapping back to the start each cycle. *(3:32-5:03)* (speaker claim; the two numbers and easing are stated)
- Frames show a gold "GIFT" button with the stripe at the left edge and an Explorer hierarchy with UICorner, Outline, Shine, Label, Shadow children. *(shown at 0:10-2:20)*
- Intended use: store buttons, rewards, giveaways. *(5:03-5:16)*

## Visual check needed
- 4:07-5:03: the motion at runtime (stills only show the start).

## Hypotheses
- **H1: A short sweep with a long pause draws attention without becoming noise** *(confidence: low-medium)*. Test: play-test sweep/pause values on a shop button.

## Relevance to our game
- Directly relevant to the shop and monetization UI ([[ADR-0011-Monetization-UI-Scope]], [[SYS-Haunted-Monetization-UI]]): an attention cue for new or purchasable items. Per the ADR we avoid fabricated urgency; a subtle highlight on "new" items is not urgency, but it should not blink constantly.
- It is client-only cosmetic and costs one image and one tween per button.

## Original implementation ideas
- A small reusable "highlight sweep" helper in our own UI theme with a configurable interval, used only on new/unlocked items.

## Recommendations (max 3)
1. If adopted, apply it only to newly unlocked or featured items and keep a long pause.

## Needs human review
- Unverified conclusions:
  - Rectangular clipping on rounded buttons (known limitation, mentioned in the video).
  - Accessibility: constant motion may bother some players.
