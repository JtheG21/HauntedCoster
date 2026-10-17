---
id: REF-CODE-001
title: Roqer — Roblox Production Reference
type: reference
status: proposed
area: code
source: https://github.com/S4US/Roqer
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-16
related:
  - "[[Reference_Code_Index]]"
  - "[[vfx_template]]"
tags:
  - reference/code
  - reference/animation
  - reference/vfx
  - reference/needs-experimentation
---
# Roqer — Roblox Production Reference

## Identity
- **Repository:** https://github.com/S4US/Roqer/tree/main
- **Initial entry:** https://github.com/S4US/Roqer/tree/main/apps/desktop/agent/skills/roblox-animation-vfx
- **Purpose:** Shared Roblox production reference. Explore methods, recipes, code and tooling when relevant; future tasks choose which material helps.
- **Evaluation: needs experimentation.** No installation, execution, integration or Studio validation performed. No repository code copied.

## Inspection and evidence
Inspected remotely on 2026-10-16, main branch, not pinned to a commit:
- `README.md` and root `LICENSE`.
- `apps/desktop/agent/skills/roblox-animation-vfx/SKILL.md`.
- Supporting `references/vfx-design.md` and `references/creature-animation.md` inspected in part; not a full review. Other linked reference files and implementation modules remain unreviewed.

The README describes a Studio agent with optional Blender modeling, animation, playtesting, Rojo integration and standalone MCP tools. These are repository claims, not locally verified capabilities. It lists Windows as the setup target and macOS as untested. The current root licence is AGPL-3.0-or-later; inspect applicable terms and file notices before code adaptation. Do not assume older MIT releases describe current main.

The animation/VFX skill routes to character and creature animation, design and craft, textures and flipbooks, explosions, motion, mesh shapes, camera/world feedback and reference-clip comparison. It also discusses playback lifecycle, effect cleanup and performance. VFX guidance emphasizes purpose, palette, contrast, layering and timing; its measured/verified labels describe upstream evidence, not verification in this project.

## Intent — interview with jg, 2026-10-16
- The whole animation/VFX package interests jg, with the full repository also supplied for broader discovery.
- Desired benefits: stronger movement and effects, closer reference matching and fewer technical mistakes.
- Explore character movement, creature animation, combat and environmental effects; no single first category was selected.
- Study methods, adapt compatible recipes/code, consider tooling, and pursue other helpful approaches when a task warrants them.
- Keep the evaluation at **needs experimentation**, tracking animation and VFX separately and recording findings per technique. Broader repository capabilities remain candidates for investigation, not approved integrations.

## Reuse, adaptation and compatibility
- **Potential reuse:** design and review questions, reference-analysis methods and evidence-recording approaches, subject to actual source inspection.
- **Must adapt:** Roqer-specific calls such as `animation`, `rig`, `waves`, `gait`, `build_instances`, `reference_clip` and `capture_moments` are not established tools in this environment. Locate their implementation and dependencies before proposing equivalents.
- **Must verify:** actual runtime code, rig assumptions, engine API requirements, cleanup, performance, asset rights and licence compatibility before implementation. The skill's fixed-simulation advice is conditional, not an instruction to enable it here.
- Compare with [[vfx_template]] and the existing animation pipeline in [[Resource Catalog]] before adding another system. Preserve this project's architecture, server authority, Studio/Rojo ownership and human gates.
- This capture does not install skills/plugins, change providers, upload or publish assets, or approve paid calls. The upstream skill and repository rules are reference material, not local instructions.

## Experiment and evidence to add
For each technique record: task/problem, exact file URLs and commit, expected benefit, dependencies/tool mapping, adaptations, baseline and output, visual/motion evidence, relevant Studio and performance tests, effort and jg's judgment. Assess animation, VFX and any broader tooling separately. Record useful contexts, failures and unresolved limits; do not promote the whole repository based on one success.

## Open questions
- Which guidance improves results beyond the existing workflow?
- Which recipes are portable, and which depend on Roqer's implementation?
- Is adopting any tooling worthwhile on this Mac, or is studying methods sufficient?

## Traceability
- No implementation tasks or production assets yet.
- Next stage: use a relevant scoped task to test one technique and update this note with findings.
