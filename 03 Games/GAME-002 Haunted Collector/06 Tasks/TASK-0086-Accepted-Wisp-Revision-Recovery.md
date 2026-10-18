---
id: TASK-0086
title: "Accepted Wisp Revision Recovery"
type: task
project: GAME-002
status: proposed
priority: high
risk: high
owner: executor
depends_on: [TASK-0069]
branch: task/TASK-0086-Accepted-Wisp-Revision-Recovery
related:
  - "[[RSH-20261018-Delivered-Update-Reconciliation]]"
  - "[[TASK-0043-Creature-Models-And-Animation]]"
  - "[[TASK-0069-Art-Salvage-From-Overhaul-Branch]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---
# Accepted Wisp Revision Recovery

## Goal
Restore the final accepted Wisp revision omitted by the earlier art salvage. Proposed integration scope; not started or approved.

## Scope
- **In:** accepted Wisp asset, imported PBR source, orientation, scale and animation dependencies.
- **Out (non-goals):** old cosmetics/backend/UI overhaul, new creature designs, uploads, publishing, unrelated map fixes.
- **Keep unchanged:** current gameplay, server authority, rare-variant policy, schema and current cosmetics.

## Intake
- **Category → workflow, depth:** Asset + Systems → [[Asset Workflow]], [[Systems Workflow]], deep (shared server art pipeline).
- **References:** [[3D Model Quality Baseline]], [[3D Model Quality Gallery]], accepted concept and comparisons linked from TASK-0043 on branch `task/TASK-0043-Wisp-Revision`; open actual originals before production/visual acceptance.
- **Reuse:** adapt the accepted `5ecb890` branch assets and minimal dependencies; Resource Catalog and source inspected. Run reference-brief at implementation intake; no new design is proposed.
- **Decisions / assumptions / open questions:** branch Outcome records acceptance on 2026-10-16, with delivery deferred to TASK-0052. Current merge approval remains with jg. See reconciliation evidence for exact omissions and compatibility conflicts.

## Files expected to change
- `games/haunted/assets/ArtData/creature_wisp.model.json`
- `games/haunted/assets/ImportedArt.rbxm`, `haunted.project.json`
- `games/haunted/src/shared/Art/MeshBuild.luau`
- `games/haunted/src/server/Services/ArtBakeService.luau`
- `games/haunted/src/client/Art/ArtLoader.luau`, `Creatures.luau`
- Original Wisp production recipe/credits and targeted tests only as required for reproducibility.

## Acceptance criteria
- [ ] AC1 Recover the accepted final Wisp data and existing imported PBR asset plus minimal MeshBuild, ArtBake, ImportYaw and animation/scale dependencies from the preserved revision branch; no uploads or paid generation.
- [ ] AC2 Preserve main cosmetics, SkinId/AuraId, rare-variant restrictions, persistence, UI and CI-pinned type compatibility; do not merge excluded overhaul ancestry.
- [ ] AC3 Verify normal/Spectral/Ashen wild, carried, pen and exhibit appearances in fresh Studio; capture matched views against the accepted Wisp and baseline originals, measure budgets, test two-client visibility and imported fallback; check.sh green.
- [ ] AC4 Record every selected commit/file and any omitted dependency; jg reviews visual equivalence and explicitly approves the integration merge.

## Tests
- **Automated:** scripts/check.sh with CI-pinned definitions; asset triangle budgets and imported fallback/orientation checks.
- **Studio playtest procedure:** preflight, verify source plus asset payload, isolate profile data, fresh sessions; cover all presentation contexts, two clients and matched visual references.

## Risks / notes
Full branch merge would import excluded UI/backend and undo current cosmetic behavior. Imported-content loading/ownership and live Rojo binary-asset sync need verification. Do not assume a nonempty MeshId proves an asset loaded.

---
## Implementation record
Not started. Proposed by Codex following jg's report of old wisps on 2026-10-18.

## Audits
Prior Wisp reviews are source evidence on the preserved branch; adapted integration requires its own checks and independent review under project depth rules.

## Outcome
Planned. No asset/source/Studio change performed by this proposal.
