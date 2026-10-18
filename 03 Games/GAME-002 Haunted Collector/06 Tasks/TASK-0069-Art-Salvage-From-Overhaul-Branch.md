---
id: TASK-0069
title: "Art Salvage From Overhaul Branch"
type: task
project: GAME-002
status: proposed
priority: high
risk: high
owner: executor
depends_on: []
branch: task/TASK-0069-Art-Salvage-From-Overhaul-Branch
related:
  - "[[Task Intake]]"
  - "[[SYS-Haunted-Monetization-UI]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - workflow/task
---

# Art Salvage From Overhaul Branch

## Goal
The finished models (creatures, habitats, mansion, ghost train) that live only on `task/TASK-0046-Mansion-Plot-And-Train-Art` (last commit 2026-10-13, never merged) reach `main`, without that branch's cosmetics backend or UI. **Draft: not approved.**

## Scope
- **In:** the art commits for TASK-0042 to 0046 (art pipeline, creature models and animation, environment kit, habitat landmarks, mansion tiers, plot dressing, ghost train) and their art data, specs and scenarios.
- **Out (non-goals):** TASK-0047 cosmetics backend, 0050 cosmetic assets, 0048/0049/0051 UI overhaul on that branch. Main's TASK-0060 and TASK-0061 versions stay.
- **Keep unchanged:** gameplay, economy and persistence rules on main.

## Intake
- **Category → workflow, depth:** Art plus Systems, **Deep** (first audit: Opus).
- **Findings:** a trial merge of the art history (to 3457e64) onto main conflicts in only five files: the Roadmap, ADR-0011, `init.server.luau`, `project-state.json`, `tasks/queue.json`. `a5f0aaa` adds PlotBuilder plus a Cosmetics config that main does not have; decide at start whether PlotBuilder needs a small art-only config instead.
- **Branch queue state:** 0042, 0043, 0045 approved; 0044 changes_requested; 0046 in_progress. Their notes carry uncommitted edits in `~/Desktop/Rg1-worktrees/overhaul`: read them before porting; do not discard them.
- **References:** `10 References/05 Misc/3D Model Quality Baseline.md` and the gallery (AGENTS.md reference-first rules).
- **Measurement:** note `get_usage` context tokens at start and close; log with `record-usage`.

## Acceptance criteria
- [ ] AC1 The art for TASK-0042..0046 is on main, ported from the branch; 0047, 0048-0051 are not.
- [ ] AC2 Main's cosmetics (TASK-0060), Shop UI (TASK-0061), ProfileRules, Net and queue are unchanged except minimal wiring; conflicts resolved in favour of main.
- [ ] AC3 The branch's Cosmetics.luau and CosmeticRules are not imported.
- [ ] AC4 `scripts/check.sh` and all specs green, including MeshCodec and the triangle budgets; a fresh Play session shows creatures, habitats, mansion tiers and train, with desktop and phone screenshots.
- [ ] AC5 Quality Baseline compared, reference IDs recorded; jg reviews the visuals before merge.
- [ ] AC6 One Opus audit.

## Tests
- **Automated:** `scripts/check.sh`, `lune run scripts/lune/specs`, `tests/test_hcm_codec.py`, art budget tests.
- **Studio playtest procedure:** `studio-preflight` first; run the ArtShowcase and HabitatTour scenarios.

## Risks / notes
Large diff (hundreds of files, mostly art data); server-baked templates affect load time. The old branch and worktrees stay untouched until jg says otherwise. Tasks 0062, 0063 and 0064 wait on this one.

---
## Implementation record

## Audits

## Outcome
