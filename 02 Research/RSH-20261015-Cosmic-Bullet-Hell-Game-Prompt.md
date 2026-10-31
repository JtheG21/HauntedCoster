---
id: RSH-20261015-Cosmic-Bullet-Hell-Game-Prompt
title: Cosmic Bullet-Hell Game Prompt — Studio-Wide Learning
type: research
status: research
sources:
  - User-supplied prompt in Codex conversation, 2026-10-15
confidence: low
created: 2026-10-15
updated: 2026-10-15
tags:
  - research
  - design/prompts
related:
  - "[[Resource Catalog]]"
  - "[[RSH-20261015-Cloud-Hill-Game-Prompt]]"
---

# Cosmic Bullet-Hell Game Prompt — Studio-Wide Learning

## Question
What can this prompt teach us about action-game briefs, combat readability, expressive upgrades, replayability and production across present and future games?

**Scope:** retain the complete source and ideas regardless of immediate usefulness to Haunted Collector. Research capture only; no game implementation, active-task changes or new studio policy is authorized by the quoted prompt.

## Sources
| Source | URL | Accessed |
|---|---|---|
| Prompt supplied by jg in this Codex conversation | No external URL supplied; preserved below | 2026-10-15 |
| Earlier exploration prompt and analysis | [[RSH-20261015-Cloud-Hill-Game-Prompt]] | 2026-10-15 |

### Original prompt (preserved verbatim)

> Make a cosmic bullet-hell action game: Pilot a pearl-powered starship through luminous nebula gardens, weaving between dazzling projectile storms, bending time at the perfect instant, and confronting colossal guardians with petal-shaped wings.
>
> - **Core gameplay:** Build momentum through tightly choreographed top-down stages while dodging patterned bullet waves, collecting radiant pearls, and managing a limited slow-time meter. Slow time should make dense attacks readable without removing danger; reward precise movement, grazing near bullets, and surviving escalating phases.
> - **Power-ups and combat:** Let the ship unleash expressive, high-impact power-ups such as pearl lances, orbiting bloom drones, shield blossoms, and a temporary storm-clearing burst. Each power-up should visibly alter the ship and encourage a different tactical choice. Give every guardian distinct telegraphed patterns, weak points, phase changes, and spectacular petal-winged attack formations.
> - **Content and structure:** Create a compact arcade campaign of several cosmic gardens, each with a distinct palette, enemy ecology, hazard language, and end-of-stage guardian. Include a title screen, stage select or progression map, score/combo chase, lives or a readable retry system, and a final results screen that clearly celebrates score, pearls, time, and performance.
> - **Controls and readability:** Support keyboard, mouse, and gamepad desktop play with responsive eight-direction movement, focused/slow-time input, primary fire, power-up activation, and pause. Keep hitboxes clear, offer adjustable difficulty or assist options, and provide strong telegraphs, contrast, and accessibility-friendly projectile readability.
>
> The finished game must have a proper indie-game feel, with a consistent original art style suited to a dreamlike cosmic garden, polished animation, layered particles, satisfying screen shake, and original sound effects and music. Include game-like title, pause, settings, and results UI; provide a short first-play controls tutorial; use English UI and text; support keyboard/mouse/gamepad desktop play and landscape phone play; and use entirely original characters, art, music, and text with no licensed IP. Self-playtest the complete experience, fix broken controls, unfair collisions, progression issues, and presentation bugs, then provide a polished playable preview.

## Observed mechanics (verified)
Verified means specified in the source text, not built or demonstrated in a playable game.

- Top-down patterned projectile avoidance combines shooting, pearl collection, grazing rewards, escalation and a limited slow-time resource.
- Four example power-ups suggest offensive reach, orbiting support, protection and emergency clearing. The prompt requires visible ship changes and different tactical choices; their exact behaviors remain unspecified.
- Guardians require telegraphs, weak points, phases and distinctive formations; gardens require distinct palettes, ecology and hazard language.
- Campaign progression is paired with a score/combo chase, retry or lives system, and results celebrating several performance measures.
- Readability, hitboxes, assists and difficulty are explicit requirements alongside spectacle, particles and screen shake.
- Desktop inputs are described in more detail than phone inputs, although landscape phone play is also required.
- Unlike the earlier prompt, this source does not explicitly request generative tools. Do not silently import that requirement from another example.

## Hypotheses
Draft interpretations, not proven design lessons.

| Hypothesis | Confidence | How to test |
|---|---|---|
| Grazing can turn avoidance into an optional risk/reward decision. | Medium | Observe whether players deliberately approach bullets and understand the reward without unavoidable damage. |
| Limited slow time can create meaningful timing decisions while preserving pressure. | Medium | Compare use timing, deaths and resource starvation across patterns and player skill levels. |
| Visible upgrade changes can communicate tactical state without constant HUD checks. | Medium | Ask players to identify their active ability and likely use from the ship silhouette and effects. |
| Consistent hazard signals can support learning while stage themes change. | Medium | Test whether players recognize dangerous projectiles in unfamiliar stage palettes. |
| Distinct metrics on a results screen can encourage different replay goals. | Low | Observe whether players understand the metrics and choose to replay for a specific goal. |
| Excessive particles, glow and shake can hide the information needed for fair avoidance. | Medium | Compare hit recognition and missed telegraphs at maximum combat intensity, with effects reduced and enabled. |

## Relevance to our game
Template heading; scope is all studio games, including future action, racing, survival and ability-based games.

### Reusable prompt techniques
- Define the intended player decision, not just a feature: slow time must improve readability while retaining danger; upgrades must change tactical choices.
- Connect form and function: ship appearance communicates power-up state; formations express a guardian's identity.
- Specify content variation across several dimensions: palette, enemy behavior, hazards and boss mechanics. This is stronger than merely requesting more levels.
- Include the whole session loop: start, learn, play, fail/retry, progress, finish and inspect results.
- Name concrete failure categories for self-testing: controls, collisions, progression and presentation. These are useful starting points, not evidence that testing happened.

### Creative and technical ideas to retain
- Cosmic gardens, luminous nebulae, pearl-powered machinery and petal-winged guardians are a coherent theme worth keeping as creative material.
- Pattern choreography, near-miss rewards, limited time manipulation, orbiting companions, defensive blooms and emergency clearing remain possible future mechanics.
- Boss phases, weak-point windows, stage identity, combo scoring and results feedback could apply beyond bullet-hell games.
- Assist settings, reduced effects and clear hitbox presentation are possible reusable capabilities; no implementation or cross-project standard is approved here.

### Comparison with the exploration prompt
| Dimension | Cloud hill exploration | Cosmic bullet hell | Transferable insight |
|---|---|---|---|
| Emotional target | Gentle discovery and awakening | Pressure, mastery and spectacle | A brief should identify the intended experience before listing systems. |
| Connecting motif | Shared wind across the scene | Garden imagery across ships, weapons and guardians | A repeated motif can unite visuals, mechanics and sound. |
| Progression | Ten discoveries unlock a final interaction | Stages, escalating phases and performance chase | Define both the completion path and reasons to continue or replay. |
| Main quality tension | Rich simulation versus feasible delivery | Spectacle versus readable danger | Record competing goals and test their balance; do not silently discard either. |
| Missing rules | Visit conditions and discovery state | Time scaling, graze rules and input mapping | Creative briefs need separate production specifications. |
| Shared delivery request | Menus, tutorial, multi-device play and preview | Menus, tutorial, multi-device play and preview | These are recurring production concerns, not yet approved studio requirements. |

## Original implementation ideas
Unbuilt adaptations, not copied assets or code.

- A training encounter that introduces a pattern safely, then recombines it with a previously learned pattern so escalation tests learning rather than surprise alone.
- A configurable visual hierarchy in which harmful projectiles, player hitbox and safe gaps remain legible while background bloom and cosmetic particles can be reduced.
- A post-run explanation of one narrowly avoided attack and one avoidable hit, helping players connect results to decisions rather than only a score total.

## Recommendations (max 3)
1. Preserve the source and derive a separate rules sheet if selected for production: time behavior, resource economy, movement, collisions, upgrades, scoring, retries and progression.
2. Prototype a single complete encounter with one slow-time decision and a retry/results loop before expanding content. Test danger readability at peak effect density and across intended inputs.
3. Keep fairness and spectacle as simultaneous targets. Define measurable checks and adjustable presentation rather than treating visual polish or accessibility as a final pass.

## Needs human review
- All effectiveness claims remain hypotheses; no playable build, performance measurements, collision tests or originality verification were performed.
- What slows: enemy bullets, enemies, player movement, player fire, timers, animation or audio? Are focused movement and time manipulation one action or separate actions?
- How does the meter refill, what does grazing award, and can the same projectile award repeatedly? How do scoring and assists interact?
- Define visible versus damaging hitboxes, diagonal movement speed, analog-stick behavior, collision handling during slow time and protection after a hit. These are validation targets, not known defects.
- Define power-up acquisition, duration, stacking, replacement and the tradeoff for emergency clearing; define boss vulnerability and phase transitions.
- Replace vague content quantities such as “several” with explicit scope only when a project is selected. Resolve stage select versus progression map and lives versus retries then.
- Specify touch movement, firing, slow time, power-up activation and pause without obscuring essential play space. Clarify mouse aiming versus fixed-direction fire and gamepad equivalents.
- Decide whether completion time means real elapsed time or simulated time, especially during slow time and pause; explain results metrics to the player.
- Test reduced motion/shake, contrast, reliance on color, text readability and assist discoverability. Platform feasibility and acceptable performance remain unknown.

## Session record
2026-10-15: captured the full second prompt, draft analysis and a comparison with the first. No active game files, task state, approved policy or previous research were changed. Future-use material remains preserved; no LES was promoted from untested hypotheses.
