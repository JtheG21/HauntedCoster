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

- **Revision 1 (audit F1, F2):** the QuestState re-render keeps gamepad/keyboard focus on the same control (path under
  the root; default only if it is gone) instead of `focusDefault` on every push; the toast hold is recomputed on
  ShowState too (last RoundState phase kept), so a mid-question join holds at once. Studio (fresh Play, synced): a push
  re-rendered the main menu to `LV 3` and selection stayed on the DAILY QUESTS hit. check.sh green.

- **Revision 2 (Codex [[AUD-20261107-TASK-0151-02]] F1, F2; last revision allowed):** `Quests.parse` now checks
  ranges, catalog and board identity before a push can replace the state or advance the revision: revision >= 1;
  level 1..50; `nextLevelXp` = `XpRules.costOf(level)` (0 at the cap) with `xpIntoLevel` below it; day, boardRevision
  non-negative integers; `pendingClaim` 1..3; zero or exactly 3 slots, each a known catalog id with integer generation,
  progress 0..target and claimed only when complete; a board needs a day and board revision. A rejected push is warned
  with its reason. Toasts compare only two usable (saved/memory) states, so the first usable state after loading or
  unavailable is the baseline. Studio (fresh Play, Rojo synced from this worktree): 11 malformed pushes at revisions
  1000000+ (Codex's probe, level 51, wrong need, into = need, unknown id, progress over target, claimed early, two
  slots, no day, pendingClaim 4, fractional XP) were each rejected with a reason; a valid revision 500000 then applied
  (LV 7); loading -> saved level 10 gave no toast; saved 10 -> 11 gave `LEVEL UP · LV 11`. check.sh green.

- **Revision 3 (Codex [[AUD-20261107-TASK-0151-03]] F1; approved by jg in chat 2026-11-07, "Approve revision 3", over
  the two-revision limit):** `Quests.parse` also requires `catalogVersion` = `QuestConfig.CatalogVersion` whenever a
  board is present or a version is sent, board revision and slot generation >= 1 (QuestRules starts both at 1), and
  unique slot ids. Studio (fresh Play, Rojo synced): the real server push was accepted (LV 1); six pushes at revisions
  1000001+ (catalog 99, board without catalogVersion, board revision 0, generation 0, duplicate id, loading with
  catalog 99) were rejected with reasons; a valid revision 500000 then applied (LV 9). check.sh green.

- **Revision 4 (Codex [[AUD-20261107-TASK-0151-04]] F1; approved by jg in chat 2026-11-07, "Approve revision 4"):**
  a pushed board is now checked with the server's own invariants, `QuestRules.validate` (as a daily state with
  `dailyEpoch` = the board day), instead of hand-written slot checks: this catalog version, one quest per category in
  slot order, one easy / medium / hard, board revision and generations >= 1, progress within target, claimed only when
  complete, bonus only when all three are. `bonusGranted` without a board is rejected. Side effect: a damaged stored board
  that the server still sends is ignored, so that player's level card stops updating (fail closed). Studio (fresh Play,
  Rojo synced): the real server push was accepted (LV 1); 11 pushes at revisions 1000001+ (repeated category, two easy,
  bonus on incomplete, bonus without board, catalog 99, board revision 0, generation 0, level -8, unknown id, progress
  over target, claimed early) were rejected with reasons; a valid all-claimed board with the bonus at revision 500000
  then applied (LV 9). check.sh green.

## Handoff (Codex review, rev 4, 2026-11-07)
- **Task:** TASK-0151 revision 4, fix for [[AUD-20261107-TASK-0151-04]] F1 (jg approved revision 4). Receiver: Codex, delta re-review only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0151`, branch `task/TASK-0151-quests-xp-ui` (PR #226). Range `d683ea9..HEAD`;
  code: `git diff d683ea9..HEAD -- games/mathshow` (only `client/Menu/Quests.luau` `parse`). The head is this handoff commit.
- **Inputs:** [[AUD-20261107-TASK-0151-04]], "Revision 4" above, `shared/QuestRules.luau` `validate` / `boardValid`, `QuestService.buildState`.
- **Focus:**
  - `Quests.parse`: does wrapping the pushed board as `{ dailyEpoch = day, playXpDay = { day, 0 }, quests = board }` make `QuestRules.validate` accept exactly the boards the server can send (fresh, progressed, claimed, bonus, rolled over) and nothing else?
  - The no-board branch (loading / unavailable): catalogVersion and bonusGranted handling; any other field a malformed push could still use to advance the revision?
- **Constraints:** no uploads, publishing, DataStore or Studio writes. Rojo is stopped; Studio idle in Edit.
- **Known:** no non-task failures. Unverified: a real claim round trip through gameplay.
- **Report back:** verdict, findings with file:line, checks run, what remains unverified.

## Handoff (Codex review, rev 3, 2026-11-07)
- **Task:** TASK-0151 revision 3, fix for [[AUD-20261107-TASK-0151-03]] F1 (jg approved revision 3). Receiver: Codex, delta re-review only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0151`, branch `task/TASK-0151-quests-xp-ui` (PR #226). Range `908d464..HEAD`;
  code: `git diff 908d464..HEAD -- games/mathshow` (only `client/Menu/Quests.luau` `parse`). The head is this handoff commit.
- **Inputs:** [[AUD-20261107-TASK-0151-03]], "Revision 3" above, `shared/QuestRules.luau` `boardFor` / rollover, `QuestService.buildState`.
- **Focus:**
  - `Quests.parse`: catalogVersion, board revision >= 1, generation >= 1 and unique ids: does anything the server can send still get rejected (loading reply with no board, a rolled-over board), and does any malformed board still get in?
  - Is there any other field a rejected-but-plausible push could use to advance the revision?
- **Constraints:** no uploads, publishing, DataStore or Studio writes. Rojo is stopped; Studio idle in Edit.
- **Known:** no non-task failures. Unverified: a real claim round trip through gameplay.
- **Report back:** verdict, findings with file:line, checks run, what remains unverified.

## Handoff (Codex review, rev 2, 2026-11-07)
- **Task:** TASK-0151 revision 2, fixes for [[AUD-20261107-TASK-0151-02]] F1-F2 (standard; rows QX-T3, QX-T3M). Receiver: Codex, delta re-review only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0151`, branch `task/TASK-0151-quests-xp-ui` (PR #226). Range `351f4d8..HEAD`;
  code diff only: `git diff 351f4d8..HEAD -- games/mathshow` (one file, `client/Menu/Quests.luau`). The head is this handoff commit.
- **Inputs:** [[AUD-20261107-TASK-0151-02]], "Revision 2" above, `shared/XpRules.luau`, `shared/QuestConfig.luau`, `QuestService.buildState` (what the server really sends).
- **Focus:**
  - `Quests.parse`: does every field check match what `QuestService.buildState` can send (level 1..50, `nextLevelXp` = cost or 0 at the cap, `xpIntoLevel` below it, empty board while loading), so no valid push is rejected and no malformed one is accepted?
  - `Quests.onState` + `usable`: is the first usable state after loading or unavailable always a baseline, and are claim / rate / stale replies still handled?
  - Anything a rejected push could still change (revision, toasts, listeners)?
- **Constraints:** no uploads, publishing, DataStore or Studio writes. Rojo is stopped and Studio is idle in Edit; nobody holds them.
- **Known:** no non-task failures. Unverified, as before: a real claim round trip through gameplay. Revision 2 is the last under the two-attempt rule.
- **Report back:** verdict, findings with file:line, checks run, what remains unverified.

## Handoff (Codex review, rev 1, 2026-11-07)
- **Task:** TASK-0151 Quests XP UI (standard; rows QX-T3, QX-T3M). Receiver: Codex, independent review only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0151`, branch `task/TASK-0151-quests-xp-ui` (PR #226). Range
  `d1314ad..HEAD` (code `2d6baaa`, `fbc45b3`, rev 1 `db12e2b`; the head is this handoff commit). Code: `git diff d1314ad..HEAD -- games/mathshow`.
- **Inputs:** [[SYS-Quests-And-XP]], [[AUD-20261107-TASK-0151-01]], "Implementation record" above, `QuestService.luau` and `Net.luau` (TASK-0150, unchanged).
- **Focus:**
  - `client/Menu/Quests.luau` `claim` / `request` / `parse` / `onState`: only the server's own identity is echoed, never XP or progress; stale and malformed pushes ignored?
  - `Quests.luau` `announce` / `pump` and the ShowState + RoundState hold: correct toasts only within one day and board; can the queue or hold get stuck?
  - `client/Menu/init.luau` subscriber + `View.luau` `buildQuests` / `playerCard`: re-render keeps focus and does not disturb pad-opened screens (`Menu.open` / `closePadScreen`) or other screens?
  - `client/Hud/Nameplates.luau`: fails inert, no leaks across respawn and leave; `ModePadConfig` Daily -> `quests` with `ModePadController`.
- **Constraints:** no uploads, publishing, DataStore or Studio writes. Rojo is stopped; Studio (MathShow.rbxl) is idle in Edit and nobody holds it.
- **Known:** no non-task failures (check.sh, validate_vault green). Unverified: a real claim round trip through gameplay, and the toast hold during a live question (code path only).
- **Report back:** verdict, findings with file:line, checks run, what remains unverified.

## Audits
- [[AUD-20261107-TASK-0151-01]]: PASS with findings (2 minor, 1 nit), Sonnet auditor at `fbc45b3`. F1 and F2 fixed in
  revision 1; F3 (noop handler list) kept, same pattern as ModePadController and Watching.
- [[AUD-20261107-TASK-0151-02]]: Codex FAIL at `351f4d8`: F1 moderate (malformed state accepted, advances the
  revision), F2 minor (level toast after a loading reply). Both fixed in revision 2.
- [[AUD-20261107-TASK-0151-03]]: Codex FAIL at `b4c808f`: F2 closed; F1 partly open (no `catalogVersion` check; zero
  board revision / generation and duplicate slots accepted). Revision limit reached; waiting for jg's decision.
- [[AUD-20261107-TASK-0151-04]]: Codex FAIL at `4425a4e`: the -03 cases are closed; board invariants still incomplete
  (repeated category or difficulty, bonus on incomplete quests). Waiting for jg's decision on a further revision.

## Outcome
