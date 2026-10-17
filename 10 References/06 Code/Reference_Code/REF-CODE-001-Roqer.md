---
id: REF-CODE-001
title: Roqer — Roblox Production Reference
type: reference
status: proposed
area: code
source: https://github.com/S4US/Roqer
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
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

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Source inspected 2026-10-17 at commit 4e29b9b90a. Roqer is a desktop agent for Roblox Studio (Electron app, a fork of a Studio MCP server, Blender modeling, R15 animation, Rojo, Creator Store tools); it requires Windows (macOS untested, on its roadmap), Node 20+ and npm install; the repo was created 2026-09-25, has 155 stars and was last pushed 2026-10-16. Licence AGPL-3.0-or-later (LICENSE, README, package.json, NOTICE.md) with a LibMP additional permission; releases 0.1.6 and earlier were MIT. The animation and VFX skill is a 6 KB SKILL.md plus 12 reference docs (about 190 KB) and an emit.lua template. Our VFX Workflow and vfx_template cover process, performance, acceptance and combat code but not VFX craft; Roqer's docs cover layering, an intensity curve where brightness only falls while an explosion's mass can keep growing, colour and value, flipbook textures, shapes, camera and world feedback, and scaling by where the player sees the effect. Its reference-clip matching document (layers in order with times, peak brightness, size ratio, colour by phase, compare at most twice, state approximations) fits REF-VFX-001 and works as a method without Roqer's tools. It independently confirms our LES-0005 (edit-mode require cache) and the creator-docs emitter limit (400 particles per second, 100 on mobile). Its measured numbers come from upstream's studied files and are unverified here; its tool calls are not tools in this environment. Rights ledger basis updated; class stays copyleft.
- **Evidence inspected:** Review packet; repo metadata, pinned tree (869 files) and licence files (LICENSE, NOTICE.md, README, package.json); SKILL.md in full; vfx-reference.md in full; vfx-design sections 1 and 6; vfx-craft sections 5 and 6; headings of the other reference docs; our vfx_template guide and VFX Workflow for comparison; creator-docs particle-emitters for the emitter limit
- **Still unverified:** The bodies of the character-animation, creature-animation, textures, explosions, mesh-shapes, motion and camera-world references and emit.lua; upstream's measured numbers; whether the method improves our VFX beyond the existing workflow; any behaviour of the Roqer app (not installed or run); macOS support
- **Next action:** Write our own technique card, in our own words, for two methods: the VFX intensity curve with layer skeleton (intensity only goes down, staggered layers, body layers outliving the flash) and the reference-clip matching steps (layers in order with times, peak brightness, size as a ratio, colour per phase, compare at most twice, state approximations). Apply it to the first REF-VFX-001 ability-sequence experiment against the vfx_template baseline. Methods only: no install, no copied code or documentation text. The animation references stay unreviewed until an animation task needs them.
