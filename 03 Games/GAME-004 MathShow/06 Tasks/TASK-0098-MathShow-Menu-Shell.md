---
id: TASK-0098
title: "MathShow Menu Shell"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0097
branch: task/TASK-0098-MathShow-Menu-Shell
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Menu Shell

## Goal
Build the MathShow main-menu shell as Shards (design handoff `Game_spec_UI2elements.zip`, menu package) behind an automated text-fit gate (`MENU_TEXT_FIT_AUDIT.md`).

## Scope
- **In:** screens 01 main, 02 mode select (+02b locked), 03a/b/c mode confirm, 17 settings, 18 how-to-play, 20 coming-soon toast, shared components (primary/secondary/action buttons, mode card, player card + rank badge, toast, back button, stepper, toggle). `client/Menu/{MenuTheme,init,View,Preview}`, `shared/{MenuCopy,MenuConfig,ShapeProfiles,RankRules,CooldownRules,NameRules,ModeRules,TextFitRules}` with specs, `tests/studio/TextFit`. Group Battle JOIN SHOW enters the existing match flow.
- **Out (non-goals):** Blitz, VS, Skill Test, rank persistence, matchmaking, new remotes or DataStore fields, SettingsSave, uploads, `badgeSlam`, GAME-001..003.
- **Keep unchanged:** server authority and the match loop; `Net`/`Remotes`.

## Intake
- **Category → workflow, depth:** UI, standard → [[UI Workflow]].
- **References:** `10 References/01 UI` (REF-UI-001..004 + the principles video note): none is a menu/gamepad layout reference; the handoff README and the text-fit audit are the spec. Adapt only HUD precedent (TASK-0097 Shard/Fx/Theme).
- **Reuse:** `client/Hud/{Fx,Shard,Theme}` and the 13 HUD images already uploaded in `Theme.Image`.
- **Decisions (jg, 2026-10-26, "approve everything", defaults accepted):**
  - a) JOIN SHOW is client-only. The match loop in `RoundService` starts for every player (no join step); the menu is a local overlay that hides when JOIN SHOW is pressed, and the HUD shows. Server-side opt-in is a follow-up.
  - b) Audit defaults A1-A12 adopted: panel stack title <= 50 / 20 px leading / gaps 6+8; title shard MATHSHOW 40 px at (30,28) with the tag as a top-edge sticker; "COLOR-BLIND MODE" and 15 px setting labels; check/cross icon images, not glyphs; toast padding 36 (+24 with icon); "WAITING FOR RIVAL" at 16; Blitz clock/score TextScaled; choices never truncate; problem text by measured `fitSize`.
  - c) Glyph policy: generated copy restricted to supported glyphs and ASCII words; a Studio glyph sheet reports fallbacks.
  - d) Layout numbers live in frozen `MenuTheme`; numbers and sizes may change to pass the gate, art may not. Failures needing new art go to the "back to Claude Design" list.
  - e) Never upload: write an upload list (75 files -> `MenuTheme.Image` keys) for jg's approval. `Theme.Image` ids stay `rbxassetid://0`; shards render as flat placeholders.
- **Queue:** the orchestrator has no add command; jg authorised adding this entry to `tasks/queue.json` by hand (2026-10-26).

## Files expected to change
- `games/mathshow/src/client/Menu/*`, `games/mathshow/src/shared/{MenuCopy,MenuConfig,ShapeProfiles,RankRules,CooldownRules,NameRules,ModeRules,TextFitRules}.luau`, `games/mathshow/tests/*.spec.luau`, `games/mathshow/tests/studio/TextFit.luau`, `games/mathshow/art/menu/UPLOAD_LIST.md`, `games/mathshow/src/client/init.client.luau`, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Listed screens and components built as Shards; JOIN SHOW dismisses the menu and shows the HUD; no server change.
- [ ] AC2 TextFitRules (rectFits/fitSize) with the 7 audit fixtures and stress specs; Studio TextFit passes every state and fixture at 844x390, 1920x1080 and phone landscape.
- [ ] AC3 RankRules, CooldownRules, NameRules, ModeRules per RULES_SPEC with boundary specs; MathShow specs above 97.
- [ ] AC4 No remotes/DataStore/rules change; nothing uploaded; upload list and Claude Design list written.

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 97 specs, 362 total).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; run `tests/studio/TextFit`; compare with `screenshots/<id>.png`.

## Risks / notes
- Merriweather glyph coverage (see policy c). Locked items must toast + shake, never navigate. Reduced motion has an identical layout.

---
## Implementation record
Standard tier. Baseline before work: check.sh green, MathShow 97 specs, 362 total.

- **Pure logic (shared/):** `TextFitRules` (`rectFits`, `fitSize`, `profile`), `RankRules`, `CooldownRules`, `NameRules`, `ModeRules`, `MenuConfig` (frozen tunables; only Group Battle open; `practice` added as a locked secondary), `MenuCopy` ("COLOR-BLIND MODE"), generated `ShapeProfiles` (kept as supplied). Specs: all 7 audit regression fixtures pass against the real profiles, plus stress, boundary and invalid-input cases. MathShow specs 97 -> 132.
- **Client (client/Menu):** `MenuTheme` (Title 40, Setting labels 15, ActionWaiting 16, `Panel` stack numbers, `Toast` padding), `Shard` (HUD anatomy, resolves Menu then HUD image keys; unset ids show flat placeholders and warn once), `View` (screens main, modes, confirm blitz/vs/group, settings, how-to-play, toast; components; focus brackets via `SelectionImageObject`; locked items shake + toast and never navigate), `init` (nav stack, B/Esc back, stepper input, local settings: SoundGroups, reduced-motion override), `Preview` (Studio only).
- **Existing code touched, minimally:** `Hud/Fx` gets `setReducedMotion`/`reducedMotion` (central gate = ReducedMotionEnabled OR the setting); `Hud/init` gets `setVisible`; `init.client.luau` hides the HUD until JOIN SHOW; `mathshow.project.json` maps `tests/studio` to `StarterPlayerScripts.StudioTests`.
- **Gate:** `tests/studio/TextFit.luau` (Studio, client side). Measures with `GetTextBoundsAsync` (rendered `TextBounds` for TextScaled / LineHeight ~= 1, since `GetTextBoundsParams` has no LineHeight), places text in the shard's local space, `rectFits(..., 6)`, also clipped/wrapped/truncated text and keep-clear zones (1 px slack for rotated boxes). Viewports are emulated by setting the root scale to `rootScale(w, h)`.
- **Deviations from the README:** no letter-spacing; no dot screen; sparkles are rotated squares; the player card shows UNRANKED (no rank persistence exists); PRACTICE is locked (Skill Test is not built); Blitz and VS cards are locked via `ModeEnabled`.
- **Assets:** the 75 PNGs are filed in `games/mathshow/art/menu/` with `UPLOAD_LIST.md`. Nothing uploaded; `MenuTheme.Image` ids are `rbxassetid://0`.

## Diff table (README -> this task; gate margins fill in after the Studio run)
| number | old | new | why |
|---|---|---|---|
| title text | 46 px at (30,40), tag at (30,16) | 40 px at (30,28), tag a top-edge sticker | A2 |
| 3-line panel title | 58 | 50 (Group stays 44) | A1 |
| panel line leading / gaps | 21 / 8, 10 | 20 / 6, 8 | A1 |
| setting labels | 16 | 15, "COLOR-BLIND MODE" | A4 |
| action waiting label | 19 | 16 | A5 |
| toast padding | 30 per side | 36 (+24 with icon) | A10 |
| tag padding | HUD 12 | README 8 | README spec |

## Back to Claude Design / follow-up tasks
- Claude Design list: none confirmed yet (needs the Studio gate). Candidates from the audit if the gate still fails: 330x104 title shard (A2), 38 px list/review rows (A9).
- Proposed follow-ups (not created): Practice home + Skill Test intro (11, 12, 19a); Skill Test play and result (13-15) with rank persistence; Rank ladder (16); Blitz (06, 07); VS flow (04, 05, 08, 09, 19b) with the 2-player test; Group Battle watching banner (10) and server-side join; SettingsSave; badgeSlam; upload of the 75 PNGs.

## Audits
Standard tier: one Sonnet audit after check.sh and Studio checks.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED (StyLua, Selene, strict types, Rojo build); MathShow 132 specs (baseline 97), 397 total.
- **Not verified (Studio):** the TextFit gate, glyph sheet, screenshot comparisons at 844x390 and 1920x1080, reduced motion, the Fx-fault test, and mouse/touch/gamepad reach. The Rojo server is running for this worktree, but Studio's Rojo plugin was not connected to it and could not be driven (window capture unusable), so nothing from Studio is claimed.
- A 2-player test is pending for VS.
