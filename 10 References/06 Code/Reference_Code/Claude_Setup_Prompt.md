# Claude Code Task: Set Up Reference-First Development

## Objective

Set up this existing Roblox/Obsidian development workspace so future systems reuse relevant prior work from these three public GitHub repositories instead of being reinvented:

- `https://github.com/JtheG21/SODT-RC-1.git`
- `https://github.com/JtheG21/Npc_template.git`
- `https://github.com/JtheG21/vfx_template.git`

This task is **documentation and workflow setup only**. Do not implement game features, alter gameplay code, change the reference repositories, or make design decisions for the current game.

## First: Inspect the existing workspace

1. Inspect the current working directory, the Obsidian vault's actual folder conventions, the existing `reference/` area (including `reference/ui` and any maps/sounds/VFX/misc folders), root and project-level `CLAUDE.md` files, any agent instruction files, `.gitignore`, and the established vault validator.
2. Read the existing workspace instructions before changing anything. Reuse the existing lowercase/capitalization and naming conventions. Do not create a parallel `References/` hierarchy if the vault already uses `reference/`.
3. Identify how project documentation, notes, branches, and validation are normally handled. Follow those conventions.
4. Test whether the current Claude Code environment can actually access the repositories. These are public repositories, but do not assume that GitHub access in another app means this shell has network or GitHub access. Use a non-mutating check such as `git ls-remote` or the available GitHub integration. Never request credentials or print secrets.

## Create/update the reference knowledge files

Use the vault's existing reference directory. If it is named `reference/`, prefer this structure unless current conventions clearly require something else:

- `reference/code/INDEX.md` — master system lookup index and mandatory reference workflow.
- `reference/code/SODT-RC-1.md` — repository guide and relevant source paths.
- `reference/code/Npc_template.md` — repository guide and relevant source paths.
- `reference/code/vfx_template.md` — repository guide and relevant source paths.

Do not duplicate these documents if equivalent notes already exist; update the established files instead. Keep all links and paths usable from the vault.

## Repository roles and starting source map

### 1. SODT-RC-1 — broad Roblox systems and engineering patterns

Repository: `https://github.com/JtheG21/SODT-RC-1`

It is the Scare or Die Roblox project and contains server/client/shared Luau systems, UI, player data configuration, testing/tooling configuration, design notes, and explicit Claude workflow guidance. Use it as a broad engineering reference, not as a template to copy wholesale.

Good starting points:
- `CLAUDE.md` — architecture invariants, conventions, project-specific pitfalls, test expectations, and scope discipline.
- `docs/work-routing-protocol.md` — how to distinguish machine-verifiable work, instrument-assisted tuning, and work that needs human judgment; includes a stop rule for repeated visual guesswork.
- `src/server/Services/PerceptionService.luau` — shared sensor layer and server-side perception state.
- `src/server/Services/SetupService.luau` — calculation-oriented system design and separation between deriving a result and mutating game state.
- `src/shared/Remotes.luau` — centralized remote declaration and client/server access pattern.
- `src/shared/Balance.luau` — centralized gameplay tuning configuration.
- `src/server/Services/RoundService.luau` and `src/server/Services/RoundState.luau` — round orchestration and a small leaf-state module used to avoid require cycles.
- `src/shared/PlayerData/Template.luau`, `src/shared/PlayerData/Types.luau`, and `src/server/InventoryService.luau` — player data and inventory-related examples; inspect current code and its storage dependency before adapting.
- `src/menu/` — reusable menu/page controllers, page configurations, UI helper modules, and UI effects.
- `src/shared/stories/` — UI story examples.
- `src/client/BeastHandsCalibrationPanel.client.luau` — an example of instrumentation for visual calibration.

Caution: its game rules, sprint status, balance values, asset IDs, map assumptions, and existing architectural choices are specific to Scare or Die. Reuse patterns only after checking compatibility with the current project.

### 2. Npc_template — NPC behavior, crowd systems, and navigation

Repository: `https://github.com/JtheG21/Npc_template`


Good starting points:
- `reference/Src/server/CrowdController.luau` — crowd/wave orchestration, steering cadence, NPC collection and route caching.
- `reference/Src/server/Zombie.luau` — NPC state, spawn/cleanup lifecycle, target tracking, attacks and appearance state.
- `reference/Src/server/TargetService.luau` — target selection helpers.
- `reference/Src/server/Theta/GridScanner.luau` — environment scanning and navigation-grid generation.
- `reference/Src/server/Theta/ThetaSolver.luau` — Theta*/A*-style route solving, line-of-sight shortcuts, continuous-floor checks, and corner-cutting safeguards.
- `reference/Src/server/Theta/PathTypes.luau` — grid/node types.
- `reference/Src/server/Theta/GridVisulizer.luau` — debug visualization (preserve the repository's spelling when linking).

Caution: inspect expected models, folders, map geometry, raycast exclusions, NPC rig structure, and runtime location before reuse. Do not assume the reference code can be dropped into the current game's hierarchy unchanged.

### 3. vfx_template — combat validation and reusable VFX patterns

Repository: `https://github.com/JtheG21/vfx_template`

Its README describes client-side combat input/animations/VFX, server-side combat handling/hit validation/delivery, and shared configuration/types/utilities. It is reference material, not a ready-to-publish experience.

Good starting points:
- `src/server/Combat/CombatServer.luau` — server-side request orchestration and dynamically registered delivery modules.
- `src/server/Combat/Validator.luau` — startup/structure validation; inspect specific checks before borrowing them.
- `src/server/Combat/HitService.luau` — hit handling patterns.
- `src/server/Combat/Deliveries/` — server-side melee, projectile, beam, and AOE delivery examples.
- `src/shared/Combat/Attacks.luau`, `src/shared/Combat/Settings.luau`, `src/shared/Combat/Types.luau`, and `src/shared/Combat/Remotes.luau` — shared attack configuration, types, settings, and remotes.
- `src/client/combat/CombatInput.luau`, `src/client/combat/AttackAnimations.luau`, and `src/client/combat/CombatVfx.luau` — client input, animation and visual response.
- `src/client/vfx/VfxUtil.luau` and `src/client/vfx/TemplatePrep.luau` — common VFX/audio utility and template preparation patterns.
- `src/client/vfx/assetPool.luau` and `src/shared/Combat/Shared/ObjectPool.luau` — pooling examples.
- `src/shared/Combat/Shared/CameraShake.luau`, `Anchors.luau`, `Raycasting.luau`, and `Trajectory.luau` — shared effects/math helpers.

Caution: do not treat client-reported hit claims as trusted. Understand which calculations are performed server-side, what the client sends, and which assumptions about models/assets/remotes must be adapted.

## Reference-first rule to add to the appropriate agent instructions

Add a concise rule to the existing root/project `CLAUDE.md` or equivalent instruction file (do not create a competing instruction file if one already governs the current project):

> **Reference-first development:** Before implementing a substantial new system, search `reference/code/INDEX.md`, then search the most relevant reference repositories and inspect the actual matching source files. Identify which patterns are reusable, which need adaptation, and which are unsuitable. Briefly report the most relevant repository/file paths and compatibility notes before implementation. Do not blindly copy entire systems, assume a reference is correct just because it exists, or import game-specific balance/assets/hierarchy. Preserve the current project's architecture and security boundaries. If repository access is unavailable, say so and use only verified local material. After successful work, record genuinely reusable lessons in the reference notes. Never modify or push changes to the reference repositories unless explicitly authorized.

## Access / local checkout decision

- If Claude Code can reliably inspect GitHub source on demand, start with the index and source links; avoid duplicating code unnecessarily.
- If local searching is needed, first inspect the workspace's repository and Obsidian conventions. Only create shallow local checkouts if they fit the workspace safely. Avoid accidentally committing nested Git repositories or large vendor copies into the vault. If appropriate, put checkouts in a dedicated ignored folder and document how to refresh them with `git pull`.
- Do not expose tokens, create credentials, or change GitHub repository settings.

## Validation and completion report

1. Run the project's existing vault/document validator and any relevant link/path checks.
2. Do not start feature implementation.
3. Report the files created/updated, how Claude can access the reference source, the validation result, and any blocker. Be explicit if this environment cannot reach GitHub.
