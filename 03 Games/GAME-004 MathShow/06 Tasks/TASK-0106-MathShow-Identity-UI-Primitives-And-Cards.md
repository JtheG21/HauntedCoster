---
id: TASK-0106
title: "MathShow Identity UI Primitives And Cards"
type: task
project: GAME-004
status: proposed
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0105
branch: task/TASK-0106-identity-ui
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0105-MathShow-Rules-Foundation]]"
created: 2026-10-27
updated: 2026-10-27
tags:
  - workflow/task
---

# MathShow Identity UI Primitives And Cards

## Goal
Build steps 1, 3 and 4 of the identity v3 package (`Game-spec-UI-elementsv3.zip`, prompt `CLAUDE_CODE_PROMPT_C2_identity.md`): the three data modules, the pure primitives and the four player cards. Nothing is mounted in the HUD or menu.

## Scope
- **In:** `IdentityTheme`, `IdentityCopy`, `AssetIds`; primitives RankBadge, ModeIcon, FormatIcon, TrackChip, TagChip, StatusChip, StatusSlot, DeltaPill, RankChangePill, ProgressBar; cards GameplayCard, RevealCard, IntroCard, ResultsRow with six variants; pure rules and specs; a Studio board harness for the S-boards and stress fixtures.
- **Out (later tasks, proposed not created):** step 2 (player/match payloads, demon `standing`, server tag validation), step 5 (Group Battle Placement A and 3v3 Placement B in the HUD; the Question layout shift needs its own review), step 6 (Fx table). Menu v3 and the rank ladder. Uploads.
- **Keep unchanged:** existing assets, HUD Question layout, menu screens, rank ladder, `RankRules`, remotes, DataStore.

## Intake
Source: package unpacked read-only (untrusted data) from `~/Downloads/Game-spec-UI-elementsv3.zip`: README, ENGINEERING_NEEDS, three Luau drafts, 48 PNGs, S1-S7 screenshots.
- **Category -> workflow, depth:** UI / client primitives, standard.
- **References:** none looked up yet; Intake must read `10 References/01 UI` before Phase 2 (open question below).
- **Reuse:** follow `client/Menu/Shard.luau` (root Frame > CanvasGroup > glow/shard/flash/content, ShapeKey/ShapeW/ShapeH for the text-fit gate) and `Hud/Theme.make`; reuse `TextFitRules`/`ShapeProfiles`; tier ids come from `TierConfig` (TASK-0105), so this task is stacked on that branch.
- **Decisions / assumptions:** jg 2026-10-27: build steps 1, 3-4 only. Defaults assumed: package files are first drafts and numbers stay as given; new code lives in `client/Identity/` with the pure rules in `shared/IdentityRules.luau`.

## Plan (Phase 1: awaiting jg approval)
Files:
1. `client/Identity/IdentityTheme.luau`, `IdentityCopy.luau`, `AssetIds.luau` from the package (strict fixes only, numbers unchanged).
2. `shared/IdentityRules.luau` + `tests/IdentityRules.spec.luau` (headless): status priority DISCONNECTED > WATCHING > FIRST_CORRECT > SUBMITTED > YOU > BOT; tag validation shape (2-5 chars); progress fill width (value% of track, min 16, hidden at 0); chip width formulas (tag = text + 20, min 48; status = text + 42); delta/pill text with U+2212; tier ids equal `TierConfig.Ids`; copy has no banned glyph and no TextTransform use.
3. `client/Identity/Primitives.luau` and `Cards.luau`: pure props -> Instances, no state, built on the Menu shard anatomy.
4. `tests/studio/IdentityBoards.luau`: builds S1-S7 and the README rule-10 stress fixtures at 844x390 and runs the text-fit gate; reports positions that differ from the README by more than 2 px.

Flags (what I would change or cannot guarantee):
1. **Package not yet audited.** The split plan sends every Design package through the text-fit, glyph and keep-clear audit and a regenerated `ShapeProfiles.luau`. The text-fit gate for the 17 new `shard-id-*` shards needs those profiles, and PR 151 (open, no task ID) also rewrites `ShapeProfiles.luau`, so the two will conflict. Phase 2 can build and run headless specs, but the Studio gate cannot pass for the new shards until the audited profiles exist.
2. **No textured match yet.** All asset ids stay empty (flat placeholders), so the "compare to the screenshot" check is limited to layout numbers until jg approves the upload. Upload list will be written, nothing uploaded.
3. **Margins below the 8 px aim:** the package reports 6.0-7.0 px on track, tag, status, pill, gameplay card and results row bands (all pass the 6 px rule). The results row is the weakest (6.0).
4. **`AssetIds` drift:** the package lists `icon-menu-check` and `icon-menu-star` as `""`, but `MenuTheme.Image` already has a real id for `icon-menu-check`. Those two keys will resolve through `MenuTheme` first and not be overwritten.
5. **Asset id convention:** the package uses `""` for unset; the menu uses `rbxassetid://0`. I follow the package (`""` -> warn once, render nothing) inside Identity only.
6. **Tier duplication:** `IdentityTheme.TierOrder` repeats `TierConfig.Ids`; a spec asserts they match so they cannot drift.
7. **Headshots:** `GetUserThumbnailAsync` runs in a task with a 3 s timeout and never blocks the card. It is the only async call; Studio will show the fallback offline.
8. **Old ranks:** the existing menu and `RankRules` still use numeric ranks and `rank-demon-1..4`. Mapping them to the nine tiers and a `standing` field is step 2 and is not done here; the primitives take string tier ids.
9. Gameplay card names mostly truncate (56 px); marked AllowTruncate as designed. Scores never truncate.

Open questions for jg: (a) stacked on TASK-0105's branch (PR base becomes that branch until PR 152 merges), OK? (b) does Intake need a `10 References/01 UI` pass first? (c) should the audit of the package happen before Phase 2 starts?

## Files expected to change
- New: `client/Identity/*`, `shared/IdentityRules.luau`, `tests/IdentityRules.spec.luau`, `tests/studio/IdentityBoards.luau`, `games/mathshow/art/identity/UPLOAD_LIST.md`.
- Bookkeeping: `tasks/queue.json`, this note.

## Acceptance criteria
- [ ] AC1 Modules added with numbers unchanged; unset id warns once and renders nothing.
- [ ] AC2 Primitives pure; rules specs cover priority, tag, progress, widths, copy.
- [ ] AC3 Four cards, six variants, 3 s headshot fallback.
- [ ] AC4 Board harness and text-fit gate run; differences over 2 px reported.
- [ ] AC5 Nothing wired or uploaded; `check.sh` passes; MathShow specs above 258.

## Tests
- **Automated:** `scripts/check.sh 2>&1 | tail -30`.
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`, then a fresh Play session running `tests/studio/IdentityBoards` at 844x390, 1920x1080 and phone landscape.

## Risks / notes
- Stacked on TASK-0105; if PR 152 changes before merge this branch must be rebased.
- Task ID allocated by hand-editing `tasks/queue.json`.

---
## Implementation record

## Audits

## Outcome
