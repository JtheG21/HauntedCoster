---
id: TASK-0069
title: "Art Salvage From Overhaul Branch"
type: task
project: GAME-002
status: done
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
Executor: Claude (Sonnet 5.5, at jg's choice; the plan called for Opus). Branch `task/TASK-0069-Art-Salvage-From-Overhaul-Branch`.

**What was done:** `git merge 3457e64` from `task/TASK-0046-Mansion-Plot-And-Train-Art` (commit `c10773a`). This brings the art history for TASK-0042 (art pipeline), 0043 (creatures), 0044/0045 (environment, landmarks) and the 0046 mansion tiers, plot dressing and ghost-train art (PlotBuilder, TrainService, art data). Conflicts in the Roadmap, ADR-0011, `project-state.json` and `tasks/queue.json` were resolved to main; `init.server.luau` keeps both `ShopService` and `ArtBakeService`. Queue entries for 0042-0046 were copied from the branch with their branch statuses (0042, 0043, 0045 approved; 0044 changes_requested; 0046 in_progress), and two note statuses were aligned to the queue.

**Deliberately not ported:** notes for TASK-0047 to 0052; `a5f0aaa` (Config/Cosmetics, PlotBuilder theme tint and `buildDecorations`), which belong to TASK-0064/0065; `199a82b`, `197c153`, `1e9ee4f` (cosmetics backend, cosmetic assets, UI overhaul). The old branch and its worktrees are untouched, including their uncommitted note edits.

**Checks:** `scripts/check.sh` ALL CHECKS PASSED; Lune specs 206 passed, 0 failed; `validate_vault.py` 0 errors.

**Not done (jg chose to skip, 2026-10-18):** Studio playtest and desktop/phone screenshots (AC4 visuals), the 3D Model Quality Baseline comparison and jg's visual review (AC5). Nothing here proves the art renders or loads in a Play session; the old branch notes record the earlier Studio evidence. `a5f0aaa` removal means the plot has no `buildDecorations` yet.

| AC | State |
|---|---|
| AC1 art for 0042-0046 on main | implemented, not tested in Studio |
| AC2 main's cosmetics/Shop/queue unchanged | implemented and tested (specs, check.sh) |
| AC3 branch Cosmetics/CosmeticRules not imported | implemented and tested |
| AC4 checks green, Studio shows art | checks green; Studio needs manual check |
| AC5 baseline and jg review | needs manual Studio check / jg |
| AC6 Opus audit | see Audits |

## Audits
[[AUD-20261018-TASK-0069-01]]: pass (Opus). Minor findings kept in the audit note; Studio and visual review still owed by jg.

## Outcome
Art for TASK-0042 to 0046 landed on main through this task (merge approved by jg, 2026-10-18). Opus audit passed. Not verified: Studio rendering, art bake time (~11 MB), baseline comparison and jg's visual review. TASK-0044 (`changes_requested`) and TASK-0046 (`in_progress`) keep those statuses in the queue and still need closing or follow-up. Cosmetic decorations and theme tint (`a5f0aaa`) are left for TASK-0064/0065.
