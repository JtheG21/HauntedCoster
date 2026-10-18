---
id: REF-UI-003
title: Check-UI Clean Roblox
type: reference
status: proposed
area: ui
source: https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox
accessed: 2026-10-17
created: 2026-10-17
updated: 2026-10-17
related:
  - "[[UI References]]"
  - "[[Reference Review 2026-10-17]]"
tags:
  - reference/ui
  - reference/code
  - reference/needs-experimentation
---
# Check-UI Clean Roblox

## Identity
- **Source:** https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox
- **Purpose:** Shared Roblox UI reference for visual design, components, interactions, icon discovery and agent guidance, selected by each game's needs.
- **Evaluation: needs experimentation.** No installation, Studio execution, asset loading or adaptation performed. No quality baseline adopted from this interview.
- **Source / licence:** README claims MIT. Full licence text and icon ownership/usage rights have not been verified; listed asset IDs do not establish permission or availability.

## Observations and evidence limits
Inspected the repository README and controller source, plus part of the component constructor source remotely on 2026-10-17; main branch, not pinned to a commit. Design manual, skill instructions, visual showcase images, icon registry and examples remain uninspected.

README describes Shop, Codes, Rebirth, Settings and Daily Rewards interfaces and claims a large uploaded icon registry, multi-device scaling and production readiness. These claims are untested here. Read source contains window/button builders, viewport-based clamped scaling, button tweens, modal animation and sunburst rotation.

Inspected URLs:
- https://github.com/TemporaryLooker22/Check-UI-Clean-Roblox
- https://raw.githubusercontent.com/TemporaryLooker22/Check-UI-Clean-Roblox/main/src/CheckUIController.luau
- https://raw.githubusercontent.com/TemporaryLooker22/Check-UI-Clean-Roblox/main/src/CheckUIComponents.luau

## Intent — interview with jg, 2026-10-17
- The whole package interests jg: visual style, reusable components, animation, icons and AI guidance.
- Use visual inspiration, study methods, adapt compatible code or consider the skill wherever useful.
- Desired benefits: polish, consistency, responsiveness, production speed and fewer unsupported guesses.
- Apply cartoon/simulator styling only when it fits the game; other projects retain their own visual direction.
- Mark needs experimentation for later review. The final yes is recorded as agreement to experimentation, not approval of a minimum UI quality standard.

## Interpretation and implementation recommendations
- **Hypothesis:** Concrete component recipes and interaction examples may reduce UI guesswork when a game's style fits.
- Compare with the existing game's UI kit before adding another component framework. Inspect actual showcased images before drawing visual-quality conclusions.
- **Source observations to check during adaptation:** responsive binding sets a newly created UIScale once and returns an existing scale without updating it; the inspected controller does not subscribe to viewport changes. RenderStepped/event connections do not expose a cleanup owner. Test resize/camera changes, lifecycle cleanup and input behavior rather than relying on README claims.
- Verify layout at actual phone/tablet/desktop sizes, safe areas, readability and supported input methods. Review the module hierarchy and dependencies before integration.
- Upstream mandatory-style language is reference material, not project policy. No installation or wholesale replacement of existing UI is authorized by capture.

## Experiment and evidence to add
For a selected UI task, record actual visual sources inspected, exact commit and files, applicable licences, chosen components and adaptations, before/after screenshots, device/input checks, interaction and cleanup tests, effort and jg's judgment. Evaluate techniques and assets individually. Preserve failed and inconclusive results.

## Open questions
- Do visual examples meet jg's taste for a specific game?
- Which components improve on the existing kit, and which need corrections?
- Are icons usable, available and appropriately licensed for the intended experience?

## Traceability
- Capture only: no skill installed, UI built or runtime changes made.
- Next stage: later review, then a scoped experiment only if selected.

## Experiment inspection — 2026-10-17
Opened the actual `assets/all_menus_harmonized.png` and `assets/standard_button_studio.png` images from main and the design manual. Observed slate menu canvases, contrasting headers, outlined typography, inset fields and raised gradient buttons. Files were inspected in scratch, not installed or imported; exact commit was not pinned.

[[RSH-20261017-Reference-Feedback-Experiment]] records a demo-local original adaptation of header hierarchy, inset fields and button depth. jg rejected the result's style. This is evidence about that adaptation, not a verdict on the entire source or permission to reuse its assets. Original interview and status retained.
