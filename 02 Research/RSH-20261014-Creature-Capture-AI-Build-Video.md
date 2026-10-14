---
id: RSH-20261014-Creature-Capture-AI-Build-Video
title: AI-Built Creature Capture Game (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/jJtZmZ3Hz9k
confidence: low
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/capture-loop
  - research/ui
  - research/audio
  - reference/misc
---
# AI-Built Creature Capture Game (video)

> **Draft.** Captions only: no frames were viewed and Gemini was unavailable (quota). Speaker opinions are marked. Nothing here is approved.

## Question
The "Context for relevance" line in the request was left as a template placeholder, so this note assumes the closest open work: the capture loop, name-label and HUD readability, and the audio pass (TASK-0040 (Audio Pass, not yet on main)). What practical lessons does a creator's end-to-end "AI builds a creature-capture Roblox game" run offer for Haunted Collector's capture timing, world labels, zone progression, sound levels and playtest process, without copying its game?

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Can AI Make an Entire Roblox Creature Capture Game? (3D Models, Map, Code)", uploader SyphoDev, 34:49, published 2026-10-13 | https://youtu.be/jJtZmZ3Hz9k | 2026-10-14 |

**Evidence limits.**
- Native English captions (`en-orig`, auto-generated): readable, with some mishearings (creature and move names are unreliable; the speaker says "season-lins"/"seasonlings" and the captions vary). Speaker names are not trusted here.
- **No frames were viewed.** The local frame download stalled and was stopped; the Gemini engine returned HTTP 429 (daily free-tier quota). Everything below is "what the speaker says," plus what his narration implies is on screen.
- No audio was heard by us. Loudness and animation quality claims are his words only.
- Reference compared against: `10 References/03 Sounds/Sound References.md` (empty: no sound references yet) and `10 References/01 UI/UI References.md`. Nothing in `10 References/` was edited. See also [[RSH-20261014-Good-UI-Principles-Video]] for a UI-principles video already summarised.

## Observed mechanics (verified)
Verified means the speaker said or narrated it in captions. None is verified by our own viewing.
- The run is a Claude Code workflow ("my AI pipeline") that does research, plan, grey-box, map, 3D models, UI, animations and sound, with every step done by AI. *(0:00–0:24)*
- Setup step: HTTP requests and related Experience Settings turned on so the tool can reach the Roblox API for asset upload. *(0:45–1:09)* (Our rules: no uploads without approval; not relevant to adopt.)
- The prompt demanded that every creature name, type and design be an original invention to avoid IP problems; the result reportedly included a name-clash search. *(1:16–2:36)*
- Generated concept: four elemental "season" types, wild creatures caught by throwing a seed, a catch-chance reticle shown before the throw, 1v1 turn-based battles with three moves each, and a timing ring per attack for a "perfect hit". *(1:48–2:07)*
- The speaker says the timing ring is **graded by the server "so it can't be faked."** *(2:05–2:09)* This is the generator's claim, not shown.
- Four "wardens" (boss versions of a zone's rare creature) gate progression; beating one unlocks the next section. *(2:18–2:23, 4:39–4:50)*
- The model reported simulation data for balance ("all data has been measured") and said fun is not yet proven. *(2:50–3:10)* Opinion-ish: the speaker accepts this and says fun is his input.
- Process: after each stage Claude emitted a resume prompt; the speaker clears chat and pastes it to avoid "context rot". *(3:27–3:59, 11:26–11:33, 21:16–21:27)*
- First layout was four groves in a circle around a hub; the speaker **opinion**: a straight line of zones 1–6 is better because it is easy to extend with the same zone code and "most popular Roblox games" do it. *(7:15–7:48, 8:57–9:23, 10:50–11:09)* He then fed a sketch back and Claude regenerated the layout. *(7:56–8:20)*
- Map claims: 780 meshes from his own asset kit; each zone has a different seasonal theme. *(11:43–12:50)* **Opinion:** "spawn looks nice"; overlapping parts called out as a defect. *(12:02–12:21)*
- UI defects he found in his own test: labels above creatures too big and unreadable when zooming out (they got bigger on zoom-out and covered the creature), panels crowded against each other, large black backgrounds. *(13:56–14:26, 15:00–15:18)*
- The feedback prompt he sent asked that name tags sit **above the head, never over the body, scale with distance like a real object, and stay readable from far enough to throw at the creature**; every element needs clear space; shrink the zone bar; fix part-flicker where geometry meets zone walls on every instance; and replace grey-box placeholders. *(15:22–16:02)*
- After that fix he still found the label too big and asked for it to be mostly transparent and smaller; he confirmed it was see-through. *(17:12–17:36, 20:15–20:53)* His own take: he could fix it by hand "but that's not the point of the series." *(19:46–20:12)*
- Later pass added animations, effects and sound; the speaker said it was play-tested in Studio. *(21:29–21:41)*
- Multiplayer test with other players: starter picker (four starters), challenge other players' creatures, VFX, music, shiny variants (asterisk by name), seed pickup bushes, rest point that heals, tree lights when final warden is beaten. *(22:15–25:00, 32:36–32:46)*
- Playtest observations (his): seed throw is "slightly buggy when they move", better when the creature is stationary. *(25:18–25:39)* Wild creatures push you into battle when you did not intend to (annoying; "a staple of the genre"). *(6:22–6:26, 27:04–27:16)*
- **Sound level:** he reports the music as "very loud" and says he will cut it in the video. *(26:35–26:48)* One mention of "some nice music, some animations, some VFX." *(24:09–24:14)*
- Two players fighting the same warden spawned two bosses; the speaker's opinion was to make it client-side. *(29:20–29:48)* This is a design hazard for shared encounters.
- Self-rating after the playtest: he says ~6/10 overall, ~5 for a regular game, ~7 for an AI game; other testers said 4–6. *(33:16–34:10)* **Opinion**, not measurement.

## Visual check needed
Frames were **not** viewed, so none of the visuals are confirmed. Transcript alone is insufficient at:
- 5:25–6:08: capture reticle, catch chance, timing ring and the result feedback.
- 14:00–14:30: the oversize overhead label problem, and 17:20–17:36 / 20:35–20:53 the "see-through" fix (what exactly is shown, size at distance).
- 16:00–18:20: before/after of the party UI spacing.
- 19:00–19:30: warden arenas and zone theming.
- 22:15–24:20: multiplayer view with VFX and sounds (the only place audio/VFX are shown in play).
- 28:00–29:50: two bosses on one warden (shared-encounter behaviour).

## Hypotheses
- **H1: Our overhead labels and capture prompts have the same "too big / wrong scale" risk when zoomed out.** *(confidence: medium, test: in a Studio play session, view every `BillboardGui`/name label at near, mid and far camera distances and with the zoomed-out camera, check size on screen and whether it hides the creature.)*
- **H2: A server-graded timing window, as the video claims, is the same authority model our capture loop already uses** ([[SYS-Haunted-Capture-Loop]]), so there is nothing new to adopt there. *(confidence: medium, test: compare the video's claim at 2:05 with `CaptureRules`; we need the frames/code to confirm what is actually graded.)*
- **H3: Loud default music (26:35) is a common playtest complaint that our audio pass should guard against with a volume ceiling and a mute toggle.** *(confidence: medium, test: during the TASK-0040 sound tour, play each shortlisted sound at the planned volume next to others and have jg flag anything too loud.)*
- **H4: A linear zone chain is easy to extend with shared code, which matches our habitat/zone model more than a hub.** *(confidence: low, test: compare with [[ADR-0007-World-Retrofit-Direction]] and `HabitatRules`; no change implied unless jg wants one.)*
- **H5: Shared encounters need an explicit rule for what two players see (one monster or two).** *(confidence: medium, test: run our 2-player Studio scenario with both players on the same target; check `EncounterService` behaviour.)*

## Relevance to our game
- Capture timing and judging stay server-authoritative per [[SYS-Haunted-Capture-Loop]]; the video's claim agrees but proves nothing about our implementation.
- Audio: TASK-0040 (Audio Pass, not yet on main) is client-only SFX with a mute toggle and a jg-chosen shortlist. Add the loudness lesson to the tour; music is out of scope for that task. [[Sound References]] has no rows yet.
- UI/world labels: pairs with [[RSH-20261014-Good-UI-Principles-Video]] on spacing and readability; the label-scale failure here is a concrete case.
- World: [[ADR-0007-World-Retrofit-Direction]] and [[ADR-0010-Client-Reported-Gaze]] (still proposed) win; nothing here changes them.
- The "AI does everything with no human fix" framing is a content-series rule of this creator, not ours. Our human gates, AGENTS.md and approved ADRs win.

## Original implementation ideas
Our own, not taken from the video's content:
- A label-scale check in our Studio scenarios: spawn a monster, place the camera at three distances, and assert on-screen label size stays inside a band (property check, not a pixel snapshot).
- A single audio "ceiling" setting in the future `SoundBank` that all roles are multiplied by, so the tour can retune loudness in one place.
- A checklist item in the audio tour: "any sound that is jarring when heard 10 times in a row?" because repetition is where loudness complaints show up.
- A two-player scenario that attacks the same target in the same tick and asserts one encounter, one result.

## Recommendations (max 3)
1. Add a loudness/ceiling check to the TASK-0040 (Audio Pass, not yet on main) sound tour (no music); record chosen ids in [[Sound References]].
2. Add a label-scale scenario (near/mid/far, zoomed-out camera) before the next UI pass, linked to [[RSH-20261014-Good-UI-Principles-Video]].
3. View the timestamps in "Visual check needed" before any of this is used in a design decision; confidence stays low until then.

## Needs human review
- Unverified conclusions:
  - Every visual or audio claim (label size, "perfect hit" ring, animation and VFX quality, music loudness) is the speaker's words only; no frames or audio were checked by us.
  - "Graded by the server" (2:05) is the generator's claim, not shown; we have not seen code.
  - Creature, move and zone names in the captions are unreliable and were deliberately not used.
  - Whether the label fix at ~17:30–20:50 actually solved the problem.
  - H1–H5 are untested hypotheses.
  - The assumed context (capture loop, labels, audio pass) is mine; the "Context for relevance" line was not filled in.
