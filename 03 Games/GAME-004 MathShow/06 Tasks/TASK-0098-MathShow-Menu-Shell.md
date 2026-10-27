---
id: TASK-0098
title: "MathShow Menu Shell"
type: task
project: GAME-004
status: approved
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
- **Assets:** the 75 PNGs are filed in `games/mathshow/art/menu/` with `UPLOAD_LIST.md`. **Uploaded 2026-10-26 with jg's approval** (Studio MCP `upload_image`, jg's account, 7 batches of 5-14 from a temporary local http server, stopped afterwards; no duplicates, no retries). All 75 ids are in `MenuTheme.Image`.

## Diff table (README -> this task)
Margins are the tightest measured by the gate at 844x390 (min over all fixtures); required >= 6.
| number | old | new | why | gate margin |
|---|---|---|---|---|
| title text | 46 px at (30,40), tag at (30,16) | 40 px at (30,28), tag a top-edge sticker | A2 | 7.5 |
| 3-line panel title | 58 | 50 (Group stays 44) | A1 | >= 7 (tags) |
| panel stack | leading 21, gaps 8/10 | leading 20, gaps 6/8 | A1 | >= 7 |
| panel tag position | (50,28) | (50,32) | tag crossed the top-left cut (3.5 at 28) | >= 8 |
| setting labels | 16 px "COLOR-BLIND MARKS" at x 20 | 15 px "COLOR-BLIND MODE" at x 26 | A4 | 6.5 |
| stepper glyphs | 22 px | 18 px | glyph box 3.5 from the square's corner | >= 8 |
| action waiting label | 19 px | 16 px | A5 | 7.0 |
| action button | x 572 | x 566 | rotated box ran 2 px into the 44 px right inset | n/a (target) |
| side secondary | x 580 | x 576 | same, ahead of the follow-up screens | not built |
| toast | h 40, 18 px, padding 30 | h 46, 15 px, padding 36 (+24 icon), text y 15 | the 320x46 toast shard has a 28 px clear band; 18 px text cannot keep 6 px | 6.0 |
| tag padding | HUD 12 | README 8 | README spec | >= 7 |

## Studio verification (TASK-0098, Rojo from this worktree, fresh Play sessions, client)
- **TextFit gate:** 11 states (main x 6 player fixtures, modes, modes locked, confirm x4 incl. "WAITING FOR RIVAL", settings x2, how-to, coming-soon) x 3 viewports (844x390, 1920x1080, phone 812x375) = **1164 rows, 0 failures**. Viewports are emulated by setting the root scale to `rootScale(w, h)` (a real window resize was not done). The gate caught real defects first (toast margin, panel tags, settings labels, stepper glyphs, Action inside the right inset); two of its own bugs were fixed (a `{ nil }` fixtures table that skipped every non-main state; rotation drift of up to 2 px on tilted shards, now removed by un-rotating centre offsets).
- **Stress fixtures covered:** 20 x "W" name, "SirCountsALot_Official" (truncates to "SirCountsALot_Offic..."), DEMON II/III with "Calculus 1, second half" / "Calculus 2", RANK UNAVAILABLE, UNRANKED, 0/10 steppers, longest COMING SOON and WAITING FOR RIVAL. **Not applicable to this scope** (screens not built): answers, scores, clocks, calc-style problems.
- **Tightest margins (px):** toast 6.0, settings labels 6.5, MATHSHOW title 7.5, DAILY CHALLENGE 7.5, WAITING FOR RIVAL 7.0, primary labels 9.0. A tagged `FitSticker` (COMING SOON, THE MATH GAMESHOW) is excepted by design.
- **Glyph sheet (Merriweather Bold and Italic both load):** render: ² ³ × ÷ − · ... — ± ½ ° √ π ∫ ∞ <= >= != and the check mark. **Box (missing):** the cross mark U+2715. The calculus symbols draw serif shapes in both faces; whether they are Merriweather's own or a system fallback cannot be told from a capture. Policy stands: check/cross use icon images, never the glyphs.
- **Screenshots vs `screenshots/<id>.png`:** captured 01 main, 03a Blitz and 17a settings at the Studio viewport (1336x669, about 2:1; not exactly 844x390 or 1920x1080). Layout, copy, rotation and order match; shard art is flat placeholder (textures blocked on the upload), except the settings rows which use the uploaded HUD art. 02, 03b/c, 18 and 20 were verified by the gate and by behaviour, not by side-by-side screenshots.
- **Acceptance:** locked LEADERBOARD and the locked Blitz card toast, shake and never navigate (checked with real mouse clicks); PLAY -> modes -> Group Battle -> confirm; B = Back; JOIN SHOW hides the menu and enables the HUD; an Fx fault (deleted UIScale) warned `[MathShow] Hud Fx.slam failed ... has no UIScale` and navigation still worked; reduced motion leaves every shard, label and button at the same position and size (only the drift and twinkle loops differ); every state's focus graph reaches all its buttons, all targets are >= 44x44 and carry focus brackets (outline until `icon-menu-focus` has an id). Gamepad input itself was simulated (B key, static reachability), not tried on a controller; touch uses the same `Activated` path as the mouse.
- **Textured checks (after the upload):** all 75 ids report `AssetFetchStatus.Success` from `ContentProvider` in a Play client (no moderation block seen; formal moderation status was not queried). The gate re-ran with art: 1164 rows, 0 failures. Textured captures of 01 main (with the DEMON II fixture), 02b modes (hatched locked cards, GROUP BATTLE glow), 20 coming-soon (toast with lock) and 17a settings match the handoff layout, copy, rotation and hatching, including title, PLAY glow, locked Practice with lock, rank badges and focus-free state. A first capture right after `show` caught the locked shards before their textures loaded; a recapture was correct. `Preview` now holds the toast in the 20 state (it otherwise auto-dismisses after 1.6 s).
- **Not verified:** exact 844x390 / 1920x1080 / phone window sizes (captures were at about 2:1); real controller and touch device; 03a/b/c, 17b and 18 textured captures (covered by the gate and the earlier flat captures); formal moderation status; 2-player VS (pending).

## Back to Claude Design
- None required for the built scope: every element passed with the number changes above (no new art needed). Closest to the edge: toast text (6.0 at 15 px) and the settings labels (6.5). If a larger toast label or 16 px settings labels are wanted, the toast shard needs a taller clear band (about 36 px) and the row shard more left inset.
- Carry forward from the audit for the unbuilt screens: title shard at 330x104 only if the tag must stay inside it (A2 chosen: sticker), 38 px list/review rows if A9 still fails when built.

## Follow-up tasks (proposed, not created)
Practice home + Skill Test intro (11, 12, 19a); Skill Test play and result (13-15) with rank persistence; Rank ladder (16); Blitz (06, 07); VS flow (04, 05, 08, 09, 19b) with the 2-player test; Group Battle watching banner (10) and server-side join; SettingsSave; `badgeSlam`; upload of the 75 PNGs; make the gate's viewport run a true window resize.

## Audits
Standard tier, one Sonnet audit (2026-10-26, `main..HEAD`): **pass**, no blocker or major finding; AC1-AC4 met (textures need the upload). It did not re-run the Studio gate.
- Minor, fixed: `TextFitRules.rectFits` returned true for NaN rect, margin or target size (now false, with a NaN spec); `Menu.hide()` left the stepper `InputBegan` handler connected (now disconnected and `SelectedObject` cleared). Added a half-open band-boundary spec. MathShow specs 134.
- Nits, left: `Menu.model()` hard-codes `rank = nil` (no rank persistence yet); `Preview`/`TextFit` ship to live clients but are `IsStudio()`-gated; `Preview.show` leaves reduced motion on (Studio only).
- Note gap, fixed: `mathshow.project.json` also changed (maps `tests/studio` to `StarterPlayerScripts.StudioTests`).

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED (StyLua, Selene, strict types, Rojo build); MathShow 134 specs after the audit fixes (baseline 97), 399 total.
- Studio TextFit gate: 1164 rows, 0 failures (see Studio verification). Glyph sheet, behaviour, reduced-motion and textured checks done; exact window sizes and real controller/touch are not.
- Uploaded and textured-checked (see above). Pending for jg: the merge decision. A 2-player test is pending for VS.
