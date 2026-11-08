---
id: TASK-0151
title: "MathShow Quests XP UI"
type: task
project: GAME-004
status: review
priority: medium
risk: low
owner: executor
depends_on: ["TASK-0150"]
branch: task/TASK-0151-quests-xp-ui
related:
  - "[[SYS-Quests-And-XP]]"
created: 2026-11-07
updated: 2026-11-07
tags:
  - workflow/task
---

# MathShow Quests XP UI

## Goal
Menu panel, level badge, XP bar and Reveal toast. Design: [[SYS-Quests-And-XP]].

## Scope
- **In:** as in the brief's Tasks table.
- **Out (non-goals):** anything under "Out of scope" in the brief.

## Intake
- **Decisions:** Backlog; waiting for the Codex design review of SYS-Quests-And-XP and jg's plan rows. No plan approval yet. Registered by row QX-D1 (jg, 2026-11-07).

## Acceptance criteria
- [ ] AC1 See `tasks/items/TASK-0151.json`.

## Implementation record
- **Plan:** approved by jg, row QX-T3 (2026-11-07); merge after a Codex PASS on the exact head, row QX-T3M.
- **Files:** `client/Menu/Quests.luau` (new: QuestState receiver, models, claim/request, toasts), `client/Menu/View.luau`
  (QUESTS screen, level card on the player card, `notify` toast), `client/Menu/init.luau` (quests screen, re-render on
  push), `client/Menu/MenuTheme.luau`, `client/Menu/Preview.luau` (level fixtures, 21a-21h), `shared/MenuCopy.luau`,
  `client/Hud/Nameplates.luau` (new), `client/init.client.luau`, `shared/ModePadConfig.luau` (Daily -> `quests`),
  `client/Hub/ModePadController.luau`, `tests/ModePadRules.spec.luau`; `LedgerRules` + spec after the Studio TextFit run.
- **Ownership note:** the two specs (`ModePadRules.spec`, `LedgerRules.spec`) were added to files_owned: they assert the
  values QX-T3 changes (Daily pad screen, ledger counts). `ModePadService` and `ModeRules` needed no change.
- **Remotes (no payload change):** QuestRequest / QuestClaim sender = `Menu/Quests.luau`; handler = `QuestService`
  (unchanged); QuestState receiver = `Menu/Quests.luau`. ModePadOpen: sender `ModePadService` (unchanged, reads
  ModePadConfig), receiver `ModePadController` now accepts `quests`.
- **Behaviour:** toasts (quest complete, claimed, bonus, level up / new title) wait while the player answers a gameshow
  question and show at its Reveal; first state is a baseline (no toasts); older revisions ignored. Reduced motion: no new
  tweens; entrances, pop and glow go through Fx / glowLoop, which already honour it.

- **Studio run (2026-11-08, Claude):** Rojo from this worktree (`scripts/serve.sh`, 34872), MathShow.rbxl, BuildStamp
  `2d6baaa` in Edit = HEAD; fresh Play, client. First TextFit: 50 rows failed, all `Content/Xp` at 5.5 px margin (under 6)
  plus the 5 ledger mismatches -> XP label moved 6 px left (`LevelCard.TextX` 236 -> 230). Rerun: every row passes,
  measured 781 / unmeasured 320 on all five viewports -> LedgerRules and its spec updated; fresh Play after that:
  **TEXTFIT_RESULT rows=11670 failures=0**, canary 20 rows / 0 failures.
- **Live checks (same session):** a server `ModePadOpen { screen = "quests" }` opened the live QUESTS screen with the
  real server board (one easy, medium, hard); the local nameplate showed `LV 1` from the server attributes. Synthetic
  QuestState pushes (Studio only, fired from the server; nothing saved): level 1 -> 4 toast; a progress push re-rendered
  the card to CLAIM with glow; queued toasts played in order ~2.7 s apart (`+200 XP`, `+150 XP`, `+100 XP`,
  `ALL THREE DONE · +100 XP`, `LEVEL 10 · QUICK COUNTER`); an older revision was ignored; a new day's first push gave
  no toast; then `QUEST COMPLETE · CLAIM +100 XP`.
- **Visual:** iPhone 13 emulation (QUESTS 21a, main with LV 49 and `1779 / 1780 XP`) and a 1410x669 desktop viewport
  (QUESTS 21c, main with LV 50 / MAX LEVEL): no clipping or overlap seen.
- **Not verified:** a real CLAIM round trip and a real quest completion through gameplay (needs a saved profile and
  play; QuestService's claim path is TASK-0150's, unchanged); the Reveal hold of toasts during a live gameshow
  question (code path only: ShowState.participant + RoundState phase). No 2-client run (UI-only change).

## Audits

## Outcome
