---
id: RSH-20261015-Cloud-Hill-Game-Prompt
title: Cloud Hill Game Prompt — Studio-Wide Learning
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
---

# Cloud Hill Game Prompt — Studio-Wide Learning

## Question
What can this game prompt teach us about creative direction, game design, prompting and production across present and future games?

**Scope decision — jg, 2026-10-15:** preserve knowledge beyond immediate usefulness to Haunted Collector. Keep the full source alongside analysis; this is research material, not authorization to build a game, adopt a workflow or change an active task.

## Sources
| Source | URL | Accessed |
|---|---|---|
| Full prompt supplied by jg in this Codex conversation | No external URL supplied; preserved below | 2026-10-15 |

### Original prompt (preserved verbatim)

> Make a first-person 3D exploration game: stand on a grassy, flower-covered hill above a sea of clouds, find ten scattered stars, and wake a guardian robot that has slept for a very long time.
>
> - Setting: a deep blue sky with the sun behind you to the left, and an endless, rolling sea of cumulus clouds all around. Build the clouds as volumetric clouds, with tops that billow up in cauliflower-like clumps, creamy white where the light hits and sky blue in shadow. It should have the warm, airy feel of a hand-drawn animated film.
> - Guardian: at the top of the hill sits an ancient guardian robot, abandoned long ago: chubby, grayish white and overgrown with grass and moss. Its big round eyes are half open as if dozing, and its short, stubby hands rest on the grass. A red ribbon is tied in a bow on its head and flutters in the wind like real cloth.
> - Wind: the whole scene shares one gusting wind. Grass ripples in waves with each gust, every blade on its own rhythm, and grass you walk through gets flattened and springs back a moment later. Add circling seagulls, white butterflies, leaves and petals drifting on the wind, and procedurally generated wind sounds.
> - Stars: little secrets are scattered across the hill; press E to interact, and each one you find gives you a star, ten in all: a biplane nose-down in the grass (the player is its pilot), a hat-shaped stone that is really "a boa constrictor digesting an elephant", a baobab sprout to pull up, a fox that takes three visits to tame, a rose under a glass dome, a little sheep, an empty box with air holes, a Malayan tapir that "eats dreams", a shoebill that has been thinking about something for three days, and touching the guardian's hand for the first time. Once all ten stars are lit, touch its hand again and its eyes light up.
> - Dialogue: ask for the player's name at the start and use it in every line of dialogue after that; keep the tone gentle, restrained and a little philosophical, like a fairy tale.
> - Controls: WASD to walk, mouse to look, Shift to run, Space to jump, E to interact, Esc to pause; gamepad and touch support, plus graphics quality presets.
>
> It should feel like a proper indie game: a consistent visual style with care for lighting, particles and sound; a title screen, pause and settings, with a short controls tutorial on first play; English UI and text; fully playable with keyboard, mouse or gamepad on desktop, and playable in landscape on phones. All art, music and text must be original. Play it through yourself, fix any feel or UI issues, then give me a playable preview.
>
> Use built-in generative AI tools for generating concept design reference images and 3D models.

## Observed mechanics (verified)
Verified here means present in the text, **not implemented or proven in a playable game**.

- One compact exploration space, a central guardian landmark, ten discoveries and a final awakening.
- The guardian's hand is both an initial discovery and the final interaction after collection.
- The fox requires three visits; the sprout suggests removal; other discoveries combine objects, creatures and narrative descriptions.
- One gusting wind connects vegetation, cloth, particles and sound, with additional local vegetation response to the player.
- The brief specifies lighting direction, cloud form and shadow color, material aging, silhouettes, motion, dialogue tone, controls and delivery requirements.
- It requests original content, generative concept images and models, multiple input methods, mobile landscape support, quality presets and a self-playtested preview.

## Hypotheses
These are draft interpretations of the prompt, not tested lessons.

| Hypothesis | Confidence | How to test |
|---|---|---|
| A visible central landmark can support orientation and anticipation in a small exploration space. | Medium | Observe unaided navigation and whether players understand where to return. |
| Connecting collection to awakening a character may make progress more emotionally meaningful. | Low | Ask playtesters what motivated collection and whether the ending felt earned. |
| Reusing an early interaction at the ending may create closure through changed meaning. | Medium | Test whether players remember the hand and return without excessive prompting. |
| Shared environmental signals may make independently animated elements feel like one living world. | Medium | Compare coordinated and uncoordinated wind treatments in motion and sound. |
| Three visits can build attachment if each changes the relationship; repetition alone may feel like padding. | Medium | Prototype changing responses and observe voluntary revisits. |
| Using a name in every line may weaken the intended restrained dialogue tone. | Medium | Compare short dialogue readings with constant and selective name use. |

## Relevance to our game
This heading follows the research template; the scope is **the whole studio and future games**, not just GAME-002.

- **Prompt construction:** emotional premise → setting → player actions → world responses → progression payoff → presentation → verification is a reusable structure to evaluate in future briefs.
- **Exploration and level design:** landmark-centered discovery, secrets in a compact space, visible progress and returning to familiar interactions could suit cozy games, mysteries, horror or hubs.
- **World simulation and atmosphere:** a common environmental driver could coordinate wind, rain, tides, electrical disturbances or supernatural events. Its usefulness depends on each game's direction.
- **Narrative and relationships:** changing responses across visits, gentle dialogue and a character awakening are concepts worth retaining even when irrelevant to current production.
- **Technical research backlog, not a task queue:** volumetric-looking clouds, reactive grass, cloth motion, procedural ambience, wildlife motion, device-specific controls and graphics presets remain possible future study areas. Their feasibility and cost are unverified.
- **Asset direction:** soft robot proportions, weathering through moss and grass, a contrasting ribbon, cloud color relationships and lighting direction are specific creative ingredients, not studio-wide art rules.
- **Completeness:** menus, onboarding, settings, input support, audio and an ending belong in production planning, with explicit checks rather than a general request for polish.

## Original implementation ideas
Unbuilt adaptations of the extracted patterns; no copied assets, names or code.

- A weather station whose instruments gradually reconnect as the player explores, culminating in a change to the sky.
- A harbor where recurring encounters change an animal's behavior and reveal new routes or information.
- A shared environmental signal that controls multiple cosmetic effects, with local variation so the scene stays organic. Architecture and platform suitability would need separate investigation.

## Recommendations (max 3)
1. Keep full prompts with their analysis. Record immediate applications, possible future applications and unresolved questions without deleting material for being irrelevant today.
2. Derive a separate production specification when a concept is selected: distinguish desired sensory outcomes from proposed techniques; define discovery states, revisit conditions, progression feedback and device requirements. Preserve the ambitious source brief.
3. Validate risky assumptions through focused prototypes and observed play: visual quality, interaction variety, ending clarity, device performance, UI and input coverage. Tool availability or generated assets alone do not prove a finished game.

## Needs human review
- All design-effectiveness hypotheses remain untested; no game, concept images or models were produced for this analysis.
- Several motifs appear to reference existing stories. That inference needs an originality and source review before production; this note makes no legal determination.
- Resolve missing rules only if building: what counts as a fox visit, duplicate interaction behavior, save/reset behavior, guidance after ten stars and input equivalents on each device.
- Volumetric clouds, individual grass motion, realistic cloth and cross-device performance need platform-specific feasibility checks. No simplification or implementation choice has been approved.
- Preserve the original-content and generative-tool requests as source requirements; they are not permission for spending, external API calls or publishing.

## Session record
2026-10-15: captured the supplied prompt and draft studio-wide analysis. Active game files, task queue, project state and approved decisions were not changed. No lessons were promoted to approved policy.
