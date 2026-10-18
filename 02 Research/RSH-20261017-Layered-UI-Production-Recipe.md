---
id: RSH-20261017-Layered-UI-Production-Recipe
title: Layered UI Production Recipe
type: research
status: research
sources:
  - "[[RSH-20261017-Reference-Feedback-Experiment]]"
  - "[[REF-UI-004-Illustrated-Halloween-Shop]]"
confidence: high
created: 2026-10-17
updated: 2026-10-17
tags:
  - research/ui
  - engineering/recipe
related:
  - "[[Resource Catalog]]"
  - "[[UI References]]"
---
# Layered UI Production Recipe

## Question
How can an assistant build a coherent illustrated Roblox UI, preserve the chosen reference details and prove its visual/input behavior?

## Sources
| Source | Evidence / scope | Accessed |
|---|---|---|
| [[RSH-20261017-Reference-Feedback-Experiment]] | Implementation, rejections, corrections and final approval | 2026-10-17 |
| [[REF-UI-004-Illustrated-Halloween-Shop]] | Visual reference only; source assets/code not imported | 2026-10-17 |
| `experiments/reference-feedback/` | Original source, generated art originals, exact prompts, payload provenance and inspector | 2026-10-17 |

## Observed mechanics (verified)
- jg accepted the final Reserve Lab UI after the second rightward branch increment, then authorized saving this recipe. Acceptance is specific to this isolated demo; it is not a universal art direction or a game integration approval.
- Native controls retain hit targets, state, selection and callbacks; illustrated artwork provides the surrounding silhouette. A single state model drives meter, lamp, hints and disabled/recovery behavior.
- Structural frame stays still. Independent ghost/branch/spider/leaf layers move gently; reduced motion stops ambient movement. Restored original corner vines are currently stationary artwork.
- Header labels share the painted ribbon's coordinate system. Thread origins use the same branch transform, including offsets/rotation, and verified opaque attachment pixels.

## Original implementation ideas
1. **Establish the target.** Open the actual reference and identify protected features, silhouette, palette, typography, interactions and rights. Record what the user means by a named feature; an original curled vine is not interchangeable with a new stalk.
2. **Separate structure and decoration.** Keep controls and frame stable. Request full transparent sprite silhouettes with padding, and clean plates without duplicated baked decorations. Preserve originals and exact prompts. Give each changed asset its own payload when neighboring sprites must stay unchanged.
3. **Adapt the existing UI kit.** Keep demo/game-specific tokens in the appropriate skin. Use one state description for every label, color, hint and action. Do not adopt demo balance or client-only authority in a real shared game resource.
4. **Place against the art.** Center text within the visible ribbon, not an asymmetrically padded card. Attach silk to actual opaque bark. Check transformed origins after movement and offsets. Check how roots/ornaments join the frame: do not introduce false end caps or pedestals.
5. **Animate selectively.** Small independent sway, a recycled leaf pool, soft illumination fades and button feedback should preserve readability and hit targets. Honor Roblox reduced motion and offer a local reduction toggle. Disconnect bindings/connections and release EditableImages on teardown.
6. **Prove details before completion.** Inspect all eyes, nose, mouth, leaf tips and sprite edges close up in both desktop/portrait artwork. Use `inspect-faces.luau` for actual base/emission content at dim/lit extrema. Verify atlas boundaries end in transparency. A whole-screen screenshot and successful build missed defects in this experiment.
7. **Prove behavior separately.** Run state boundaries/recovery, disabled navigation, keyboard/gamepad paths, target sizes, short-screen scrolling, input stacking and cleanup checks. Preserve rejected evidence and distinguish technical pass from human visual acceptance.

## Hypotheses
- These production and review steps should transfer to other illustrated UIs. Visual quality, performance and layout still require new reference comparison and validation for each game.
- The pixel-color carving mask is asset-specific, not a generic segmentation tool. New art requires new feature/edge verification; previous thresholds and seeds demonstrably missed pixels and noses.

## Relevance to our game
Reusable as a reference/intake and verification recipe. No Haunted Collector or Rg1 game code/place changed. A game adoption task must choose its own scope, art direction, authority model and deployment path.

## Recommendations (max 3)
1. Reuse the layering, coordinate/attachment checks and closeup review process; adapt artwork and state rules per game.
2. Preserve generated originals, rights boundaries, prompts, hashes and rejected comparisons with the implementation.
3. Verify EditableImage permissions/memory and actual device performance before production adoption; this local encoding path is not a certified publishing solution.

## Needs human review
- Physical touch/controller hardware and device performance are not certified. Keyboard/controller virtual inputs, mouse on desktop and emulated phone layout/focus were checked.
- Phone mouse injection in this MCP session did not generate GUI input events; do not count it as touch activation proof. The standalone menu now sits above avatar touch controls; hit order was inspected, but actual touch remains pending.
- Source rights remain reference-only. Final visual approval does not establish ownership of the reference post or permission to reuse its original assets.

## Independent review lesson
[[RSH-20261017-Reference-Feedback-Review-01]] found that GuiObject rotation pivots about its center regardless of AnchorPoint. Match rendered geometry, not an assumed anchor transform: rotate attachment pixels about the sprite center and center each thread between its endpoints. The bounded runtime endpoint regression covers both artwork variants and sway extrema; physical device checks remain separate.

Independent delta review: [[RSH-20261017-Reference-Feedback-Review-02]] passes the correction; initial finding retained in review 01.
