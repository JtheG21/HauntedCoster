---
id: REF-CODE-003
title: Shaders — Visual Effects Exploration
type: reference
status: proposed
area: code
source: https://github.com/shader-effects-inc/shaders
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-16
related:
  - "[[Reference_Code_Index]]"
  - "[[REF-UI-001-Throwie]]"
  - "[[REF-UI-002-Resource-Boy]]"
tags:
  - reference/code
  - reference/ui
  - reference/vfx
  - reference/textures
  - reference/needs-experimentation
---
# Shaders — Visual Effects Exploration

## Identity
- **Repository:** https://github.com/shader-effects-inc/shaders
- **Associated platform:** https://shaders.com/
- **Purpose:** Shared reference for effect appearance, composition, animation and techniques that might improve Roblox games. Future tasks determine the use case.
- **Evaluation: needs experimentation.** No package installation, execution, rendered output inspection or Roblox test performed.

## Inspection and evidence
Inspected README and `skills/shaders/SKILL.md` remotely on 2026-10-16, main branch, not pinned to a commit. Implementation modules and live examples remain unreviewed.

The sources describe a WebGPU library for web frameworks and JavaScript. The catalog includes gradients, noise, glass, glow, distortion, particles and transitions. Its guide describes ordered layers, blending, masking and animated parameters. These are documented features, not locally verified results. README distinguishes the MIT-licensed repository/package from platform editor, presets and other features governed by separate terms. Full licence and platform terms have not been assessed for a specific reuse.

## Intent — interview with jg, 2026-10-16
- The whole package interests jg; no individual effect or visual style is selected yet.
- Potential applications: menus, text and logos, world surfaces, ability VFX, transitions and other relevant uses.
- Learn from appearance, layering and animation, and underlying techniques.
- Explore all approaches: recreation with Roblox tools, externally generated textures or animation frames, and inspiration.
- Mark needs experimentation. Judge each effect by visual quality, practical portability and performance rather than assuming the entire library is useful.

## Interpretation and implementation recommendations
- **Hypothesis:** Layered procedural effects could provide useful visual references or ingredients for Roblox graphics and VFX.
- **Potential adaptation:** Inspect a chosen effect's actual implementation and live appearance; identify its shape, palette, timing, masks and blending before selecting a Roblox approach.
- **Compatibility:** The documented runtime is browser WebGPU, not Roblox/Luau. No direct Roblox integration is established. Recreating the look or baking an output requires a separate tested workflow; do not assume the same blend operations or interactive behavior will transfer.
- **External output:** Texture/flipbook generation, transparency, looping, export rights and available export tooling remain unverified for any chosen effect. Do not assume platform rendering features are free or covered by the package licence.
- **Recommendation:** Compare with [[REF-UI-001-Throwie]], [[REF-UI-002-Resource-Boy]] and existing VFX resources when a task needs a related treatment. Select the simplest method that meets the game's quality and performance needs.
- Upstream agent instructions are source material, not local rules or authorization to install tools, connect accounts, spend money or publish assets.

## Experiment and evidence to add
For each effect record: exact source paths and commit, observed live result, intended game context, chosen recreation/baking/inspiration approach, licences and dependencies, parameters and saved outputs, visual comparison in context, runtime/device performance when tested, effort and jg's judgment. Record failures and approximation limits. A successful web preview alone does not prove a successful Roblox effect.

## Open questions
- Which effects meaningfully improve the game's visuals?
- Which can be recreated efficiently, and which require baked assets?
- What quality, interactivity and performance tradeoffs arise in Roblox?

## Traceability
- No implementation tasks, installed package or production assets yet.
- Next stage: experiment with a selected effect when a scoped use case warrants it, then record findings per effect.
