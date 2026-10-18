---
id: REF-UI-004
title: Illustrated Halloween Shop
type: reference
status: proposed
area: ui
source: https://x.com/Vywroteczka/status/2109342989591945458
accessed: 2026-10-17
created: 2026-10-17
updated: 2026-10-17
related:
  - "[[UI References]]"
  - "[[Reference Review 2026-10-17]]"
  - "[[RSH-20261017-Reference-Feedback-Experiment]]"
tags:
  - reference/ui
  - reference/illustration
---
# Illustrated Halloween Shop

## Identity
- Source: Kizzo (@Vywroteczka) X post, accessed 2026-10-17 in the browser. Post credits UI to @aerodevx and inspiration to @DevionUI. Those are source credits, not independently established ownership.
- Purpose: concrete visual target supplied by jg after the feedback demo's generic UI treatments were rejected.
- Rights: reference-only; no original artwork, code or image assets were extracted for production reuse. Post claims about model authorship or functionality are not verified.

## Observations (visible facts only)
The eleven-second browser video shows a purple Halloween Shop header, warm brown content panel, thick outlined cartoon lettering, layered orange wood-like edges, a witch-hat pumpkin, a ghost, a branch with spiders and bottom pumpkins. Decorations overlap the panel silhouette. A compact pumpkin/hat state transitions to the larger shop frame. The viewed panel was empty; no product purchase workflow was demonstrated.

## Interpretation
The distinctive quality is a coherent illustrated object, with themed artwork shaping the silhouette, texture, depth and typography together. This is an inference from the visible material, not a universal UI rule. Precise animation curves/timings, implementation, original assets, licensing and mobile behavior were not established.

## Intent
jg described this as a good UI example and explicitly asked to apply it to the existing feedback demo. Preserve the demo functionality and control spacing that jg already accepted. Adapt the illustrated Halloween direction into original artwork; do not record this as approval of a finished recreation or every future game's art direction.

## Visual requirements
- Themed illustrated frame and decorative characters, with warm orange/brown/purple relationships.
- Confident outlined lettering and layered surfaces; readable live labels and controls.
- Maintain functional input and keep character artwork proportional on small screens.

## Implementation recommendations
Use original desktop and narrow artwork variants around native Roblox controls. Verify the actual result in Studio rather than accepting a generated art preview as runtime proof. Check disabled states, recovery, screen bounds and input after adding artwork.

## Traceability
[[RSH-20261017-Reference-Feedback-Experiment]] records the generated-original frame adaptation and runtime checks. Source under `experiments/reference-feedback/`; original generated PNGs and generation prompts are preserved there. The source video's exact reveal/choreography is not reproduced or verified.

## Open questions
Does jg accept the resulting illustrated demo? No visual approval is inferred from asking to apply the reference.

## Adaptation acceptance — 2026-10-17
jg visually accepted the final generated-original Reserve Lab adaptation after the second branch offset increment (“all good now”), then authorized recording it and saving the recipe. See [[RSH-20261017-Layered-UI-Production-Recipe]]. This does not change this source note's Intent/status, source rights or any game design decision.
