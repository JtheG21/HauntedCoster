---
id: RSH-20261014-AI-Incremental-Game-Pipeline-Video
title: AI-Built Incremental Game Pipeline (video)
type: research
project: GAME-002
status: research
sources:
  - https://youtu.be/RNnUqomUaII
confidence: low
created: 2026-10-14
updated: 2026-10-14
tags:
  - research/ai-workflow
  - research/idle-incremental
  - research/ui
  - reference/misc
---
# AI-Built Incremental Game Pipeline (video)

> **Draft.** Full English auto-captions read; 12 of 82 sampled frames viewed (the rest not). Gemini was unavailable (quota), so the local engine was used. Nothing here is approved.

## Question
General knowledge-building for GAME-002 Haunted Collector, tied to no task: what can a creator's "AI builds a whole Roblox incremental game with one skill per discipline" run teach us about workflow (staged skills, handoffs, mockup-then-code UI, mesh pipeline) and about the incremental genre it produced, without copying that game?

## Sources
| Source | URL | Accessed |
|---|---|---|
| "Can AI Make an Entire Roblox Incremental Game? (Art, 3D Models, Code)", uploader SyphoDev, 19:13 | https://youtu.be/RNnUqomUaII | 2026-10-14 |

**Evidence limits.**
- Native English captions (`en`, automatic, original language). Readable; some mishearings (e.g. "Glowshroom" is clear, but "claw code", "block code" and "shirt patches" are garbled; "shirt patches" is almost certainly "ServerScriptService" or similar and is not trusted).
- **Frames:** 82 scene-change frames were extracted at 512px; I viewed 12 (about 0:18, 6:10, 10:50, 11:49, 13:20, 14:00–14:05, 14:44, 15:23, 17:54 and two intro scenes). The rest were not viewed. UI text in frames is small and partly illegible.
- No audio was heard by us. Everything audible (music, SFX) is unverified.
- **Confidence lowered to `low` on 2026-10-14** under the updated video-research recipe (medium needs frames reviewed across the whole video; only 12 of 82 were viewed).
- Speaker's numbers (player counts, visits, "60 to 1" mesh reduction, "857 instances") are his claims or read off his Claude output, not independently measured.
- **References compared against:** `10 References/01 UI/UI References.md` (one text reference, no mockups), `10 References/02 Map/Map References.md` and `10 References/05 Misc/Misc References.md`. Nothing in `10 References/` was edited. Same uploader as [[RSH-20261014-Creature-Capture-AI-Build-Video]]; UI principles also covered in [[RSH-20261014-Good-UI-Principles-Video]].

## Observed mechanics (verified)
"Verified" means said in captions and/or seen in a frame we viewed. Opinions are marked.

**Workflow claims (what the creator says he built)**
- Opinion: most "AI makes a Roblox game" videos paste code into Studio and look like "AI slop"; his diagnosis is that everything is made through code, even map, UI, models and VFX. *(0:36–1:25)*
- Setup: one Claude Code **skill per discipline** (map, UI, 3D modeling, animation, VFX, programming), each a folder with an instruction file, a references folder and tested Python scripts, so a fresh session "still knows everything". *(1:41–2:16, 4:00–4:42)*
- **MCP** gives Claude live Roblox Studio access (create objects, set properties, run code, screenshots, play test). *(2:16–2:56)* Compare: our own Roblox_Studio MCP is already in use.
- **APIs** each do one job and return a file: Cloudflare for image generation, a free Kaggle GPU for an open-source image-to-3D model, and a Roblox key that uploads finished assets. *(3:33–3:50)*
- Studio setup shown: new experience, saved to Roblox, then File > Experience Settings > Security > allow HTTP requests so the tool can talk to Studio. *(5:01–5:37)*
- One command starts the whole run ("create Roblox game … incremental … do the research on the genre"). *(5:42–6:08)*
- The tool researched the genre, produced a one-page plan, and **paused for human approval** before building; the speaker approved it in the chat. *(6:11–8:41)*
- After approval it wrote a **handoff file** and told him to clear the chat and paste a resume prompt, so each session reads one file instead of replaying history. *(8:41–10:15)* Opinion (his): long contexts re-read every message and waste tokens. *(8:59–9:39)*
- Second session produced "all the scripts" plus placeholder map and mushrooms and **play-tested the loop itself**; he then tested it by hand and noted UI, models and map were placeholders. *(10:18–12:12)* Frame at ~10:50 shows plot labels, a spore counter and a Colony/Upgrades panel in Studio play. *(frame 10:50)*
- **3D model pipeline claim:** concept image first, Claude checks it, image goes to an open-source image-to-3D model on a free GPU, the mesh comes back at "around 600k faces", Claude cuts it ~60:1 in Blender and **bakes the lost detail back as a texture**. *(12:48–13:29)*
- **UI pipeline claim:** no design tool; the skill makes a **mock-up image**, Claude compares it with other Roblox UIs, then builds the UI in code. His rationale: "a mock-up is a picture and pictures drift." *(13:40–14:02)*
- UI result frames show several `<unbound>` placeholders (unfilled bindings) in the first mock-up build, then a later frame with a coloured spore counter, rate and Colony/Upgrades/Bloom buttons. *(14:44; frame 15:23)* Opinion: "the UI looks quite good". *(14:54)*
- **Map pipeline claim:** plans the map, generates meshes (Blender or the mesh skill), takes screenshots and fixes until "playable". *(15:01–15:22)* Output reported "857 instances, 480 meshes, nine generated meshes". *(15:23–15:36)*
- **Defects he found himself:** map "very dark", plot labels reading "unclaimed", UI elements misplaced, an empty plot area where something should spawn. *(15:37–16:03, 17:19–18:20)* The model's fix lightened the sky/ambient and moved the UI; he judged the map "much better" but the plot content still missing. *(16:46–17:35)*
- He did not demonstrate the VFX or animation skills in this video. *(18:35–18:46)*

**The game concept the tool generated (the "incremental" itself)**
- Pitch: grow a glowing mushroom colony on your plot; when large enough it "blooms" and **resets**, keeping seeds that make the next run stronger; long-term goal is waking a "heart root" at bloom 10. *(6:17–6:38)*
- Research claims the tool made: the genre is hot, the leader copies the same template, and "none of them make other players in your server matter"; some titles died fast without updates. *(6:42–7:15)* These are the model's read of live pages, unverified.
- **Twist:** each other player in the server boosts your colony 10% up to 50%, and when anyone blooms the whole server gets a 60-second production-doubling event. *(7:21–7:37)* Opinion (speaker): "that's smart", the genre does not encourage playing with friends. *(7:43–7:50)*
- Core loop: tap glowing mushrooms for spore bursts; buy five mushroom types and 16 upgrades; owning 25/50/100 of a type doubles it; blooms keep 10% of each type as a permanent ×2; bloom 10 unlocks faster ripening and auto-buy. *(7:52–8:16)*
- **Offline gain** exists: leaving and returning gives more spores. *(11:04–11:12)*
- Scope: it left features out "because it's quite high scope". *(8:20–8:24)*

## Visual check needed
Transcript alone is insufficient (I viewed only the frames noted above):
- 14:14–14:50: the mock-up images themselves (colony, upgrades, bloom, "heart root" screens). The speaker says the mock-up was "hard to see"; I saw one frame with `<unbound>` labels but not the mock-ups.
- 15:23–15:48: the "very dark" map and the Rojo-sync fix (before/after lighting).
- 12:48–13:31: any shown mesh, Blender decimation, or texture bake. Not viewed.
- 17:02–17:35: the improved map (bushes, mushrooms, stumps, rocks), the empty-plot defect.
- 6:17–8:20: the Claude plan screen in full (frame 6:10 is too small to read the full text).
- 11:04–11:30: the offline-gain counter and what "280 spores" represented.

## Hypotheses
- **H1: A mock-up-image step before building UI (compare, revise, then code) would reduce our "plausible but ugly" HUD iterations.** *(confidence: low, test: for one small panel, make a mockup, review it against [[RSH-20261014-Good-UI-Principles-Video]] before coding; compare edit rounds with the usual path.)*
- **H2: One-file handoff plus `/clear` is a cheap context-hygiene habit, and we already do it.** *(confidence: high that it matches our rule; test: none needed; AGENTS.md already says "≤20-line handoff … when context passes ~150k".)*
- **H3: His "research → one-page plan → human approves → build" is the same gate as our task intake, so nothing new to adopt.** *(confidence: medium, test: compare with `04 Agents/Task Intake.md`.)*
- **H4: Mesh generation at ~600k faces with ~60:1 Blender decimation and baked textures may be a viable asset route for props, but our quality floor and Roblox limits decide.** *(confidence: low, test: one throwaway prop through the same steps (outside the vault) compared with `3D Model Quality Baseline.md` and [[LES-0007-Blender-Studio-Scale]].)*
- **H5: A server-wide shared bonus ("each player boosts you; one bloom buffs everyone") keeps players cooperating without a trade system.** *(confidence: low-medium, test: paper-model against our up-to-6 player target in a scenario, with server-authoritative effect only.)*
- **H6: Offline accrual is expected by idle players and is cheap to model if the server computes it from a timestamp.** *(confidence: medium, test: compare with the DataStore shape in [[SYS-Haunted-Player-Data]]; no exploit surface if server-side only.)*

## Relevance to our game
- **Not our genre.** Haunted Collector is a capture/collection loop ([[ADR-0005-Haunted-Collector-Direction]], [[SYS-Haunted-Capture-Loop]]); the video's loop (tap, buy, reset, prestige) would be a different game. The only transferable parts are the workflow ideas and the generic multiplayer-boost pattern.
- **Server authority wins.** His generated economy is not shown to be server-validated; we require every client input to be validated and rate-limited. Nothing in the video overrides AGENTS.md.
- **Workflow:** our rules already cover staged skills, one-task-at-a-time and handoffs ([[ADR-0009-Shared-Production-Foundation]]; AGENTS.md "Session and delegation budget"). The new point is the **mock-up-first UI** and **concept-image-first 3D**, which fit our reference-first rule in AGENTS.md.
- **Retention angle:** the shared bonus and "keep a permanent fraction on reset" idea are generic retention patterns that could inform [[ADR-0011-Monetization-UI-Scope]] discussions, but they are not proposals.
- **Failure modes he hit** (dark map, misplaced UI, empty plot, unbound labels) are the same "functional but unreviewed" gaps our reference-first rule is meant to catch: a result needs visual verification, which he did by hand.

## Original implementation ideas
Our own, not from the video's game:
- A "visual verification" step in every UI/map task: screenshot at fixed camera positions and compare against the chosen reference IDs, instead of trusting a self-reported "built and proved".
- A scenario assertion that no `TextLabel` in a screen has an unresolved binding string (e.g. contains `<`/`unbound`-style markers), catching the placeholder-leak failure he showed.
- For a future event, a server-computed "lantern-lit" shared bonus for a whole server window; purely cosmetic first, numbers tuned by playtest.
- A small "lighting check" scenario: sample average screen luminance at spawn and fail if too dark, since "far too dark" was his first defect.

## Recommendations (max 3)
1. File one low-priority research follow-up: try a mock-up-first pass on a single non-critical UI panel and record edit rounds (H1). No code.
2. Add "unbound/placeholder label" and "spawn-area luminance" as candidate checks to the next UI/map task's test list, linking [[RSH-20261014-Good-UI-Principles-Video]].
3. Do not adopt the incremental design or its economy; keep only the shared-bonus pattern as a note for a future events discussion.

## Needs human review
- Unverified conclusions:
  - Every number from the creator (player counts, visit numbers, mesh counts, 600k → ~10k reduction ratio, "857 instances") is his claim.
  - Whether his pipeline actually produced shippable-quality assets (only a handful of frames were viewed; the VFX/animation skills were not shown).
  - Whether the generated economy is server-authoritative. The video does not show it.
  - Garbled caption names (e.g. "shirt patches") were not interpreted.
  - Whether the genre-research claims about other games are accurate.
- Timestamps jg should view himself: **12:48–13:31** (3D pipeline), **13:40–14:55** (UI mock-ups), **15:23–17:35** (map before/after and the empty plot), **6:11–8:20** (plan screen), **11:04–11:30** (offline gain).
- Not part of our existing approved notes; no ADR or LES changes proposed.
