---
id: TASK-0097
title: "MathShow HUD Shards"
type: task
project: GAME-004
status: done
priority: medium
risk: low
owner: executor
depends_on:
  - TASK-0093
  - TASK-0096
branch: task/TASK-0097-MathShow-HUD-Shards
related:
  - "[[GAME-004 MathShow/00 Overview]]"
created: 2026-10-25
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow HUD Shards

## Goal
Restyle the working MathShow HUD as angled, textured "shards" with glow, gameshow copy and choreographed motion, from the design handoff (Game-spec-UI-elements.zip, README draft id "TASK-0097").

## Scope
- **In:** `client/Hud/{Theme,Fx,View,init}`, new `shared/HudCopy`, pure logic in `HudRules`/`StandingsRules` with specs, the 32 PNGs filed in the repo, an upload list for jg.
- **Out (non-goals):** game rules, remotes and payloads, uploading or publishing assets, the 2-player run (waived), GAME-001..003.
- **Keep unchanged:** server authority; leaderstats change only at Reveal.

## Intake
- **Category → workflow, depth:** UI, light tier → [[UI Workflow]].
- **References:** `10 References/01 UI` REF-UI-001..004 (adapt, not copy); design handoff README is the spec.
- **Decisions (jg, 2026-10-25, approved defaults):**
  - a) No payload change: `solvers`/`scores` already carry `{userId, name, points}`.
  - b) Roblox text has no letter-spacing property (creator-docs checked): ship without tracking, widen tag boxes, never wrap. Visual deviation from the spec.
  - c) CanvasGroup = shard + 36 px pad each side; shard image inset by the pad; outer Frame keeps Theme.Layout position/rotation.
  - d) `GuiService.ReducedMotionEnabled` exists; one central gate in Fx.
  - e) Merriweather: `rbxasset://fonts/families/Merriweather.json` is listed in Font docs; load in Studio unconfirmed, fallback in `Theme.Font`.
  - f) Standings: 8 rows + pinned own row + "+N MORE".
  - g) Keep original PNGs (ten exceed 1024 px, Roblox will downscale); no pre-downscale.

## Acceptance criteria
- [ ] AC1 All 16 states rebuilt as Shards with HudCopy strings.
- [ ] AC2 Fx isolated (pcall + warn), secondTick never yields, reduced-motion gate.
- [ ] AC3 Pure logic in Rules modules with boundary specs; MathShow specs above 78.
- [ ] AC4 No rules/remote changes; assets filed, upload list written, nothing uploaded.

## Tests
- **Automated:** `scripts/check.sh`.
- **Studio:** fresh Play session, 16 states vs screenshots at 844x390 and 1920x1080 (image checks blocked until asset IDs exist).

---
## Implementation record
Light tier (no audit subagent). Baseline before work: check.sh green, MathShow 78 specs, 343 total.

- **Rules and copy:** new `shared/HudCopy` (all player-facing strings); `HudConfig` keeps numbers only. `HudRules` gains `problemSize`/`problemChars`/`problemModel`, `questionTag`/`difficultyOf`, `topModel`/`pipStates`, `secondsTag`/`scoreTag`, `intermissionMode`, `toastFor`, `feedbackFor` (now a toast kind + points), `solversModel`, `rootScale`. `StandingsRules` gains `formatNumber`, `pointsLabel`, `moreLabel`, `topTag`, `emptyMessage`, `scoreFor`. `questionLabel`, `solversLabel` and `HudConfig.Strings` are gone. MathShow specs 78 -> 97.
- **Client:** `Hud/Theme` (fonts, colours, frozen layout, image guard: an unset id shows a flat gem-coloured panel and warns once), new `Hud/Shard` (root / CanvasGroup / glow / image / flash / content), `Hud/Fx` (rest-state based, channels, no `Completed:Wait`, central `ReducedMotionEnabled` gate, typed parts per phase), `Hud/View` (all 16 states, Instances only), `Hud/init` (entrances on phase/question/mode change, `Fx.feedback` on toast change, `Fx.secondTick` per whole second, score pop at Reveal only). No remote, server or rules change.
- **Assets:** the 32 PNGs are in `games/mathshow/art/hud/` with `UPLOAD_LIST.md` (filename -> `Theme.Image` key). Nothing uploaded. The art-import skill covers 3D imports, not UI PNGs, so it was not used.
- **Deviations from the spec:** no letter-spacing (tags get wider padding); ambient diamonds, pips and burst sparks are rotated squares (Roblox has no clip-path); the dot screen is left out; a full-screen ground Frame sits behind the 844x390 root; Seconds column nudged to x 646 so its right edge is on the 44 px inset; list rows that reach the jump zone (rank 8 and the pinned row) end at x 664 and borrow room on the left; the answer "flip" is a Back-eased scale (no scaleY); a toast's width is measured from a hidden sizer label.

## Audits
Light tier relies on green check.sh.

## Outcome
- `scripts/check.sh` ALL CHECKS PASSED: StyLua, Selene, strict types, MathShow 97 specs (baseline 78), Haunted 265, Rojo builds.
- Studio (MathShow place, Rojo from this worktree, fresh Play sessions): live match ran Intermission, Question, Reveal and back with no Fx warnings; a UIScale deleted from the Seconds number made `Fx.pulse` warn every second while the countdown, bar and the red last-3-s state kept running. States checked on screen at the Studio viewport with fallback panels: lobby, get ready, question (also the red last 3 s and the 3-digit problem size), reveal with three chips and "+2 MORE", results with a tie and a pinned own row, scores unavailable, and the sendfail toast.
- **Not verified:** all textured looks (no asset ids yet); the 1920x1080 and 844x390 comparisons against `screenshots/01-16` (checked at the Studio window size only); empty-scores and nobody-solved screens on screen (the live run did show TIME'S UP); wrong, rejected and correct toasts and the burst/shake motion (a live answer could not be typed in); reduced motion (the setting cannot be toggled from Studio, code read only); phone landscape on a device; touch and gamepad submit (the button uses `Activated`). The 2-player run stays waived and pending.
- Pending for jg: upload approval for the 32 PNGs and their ids (`games/mathshow/art/hud/UPLOAD_LIST.md`); Merriweather loads in Studio.
- **Upload (jg approved 2026-10-26):** the 32 PNGs were uploaded through Studio MCP `upload_image` (served from a temporary local http server) and the ids are in `Theme.Image` and `UPLOAD_LIST.md`. Three sampled ids report AssetTypeId 1 (Image). One 31-file call timed out, so about 16 files were uploaded twice; the extra copies are unreferenced duplicates on jg's account. Moderation not yet confirmed. Textured screenshots vs `screenshots/01-16` are NOT done: the Studio window stopped rendering (screen locked or asleep) before the id build could be synced and captured.
- **Textured check (2026-10-26, Rojo from this worktree, fresh Play, real View code fed fixed states):** question (blue), reveal with chips and correct toast, reveal nobody-solved with TIME'S UP (red problem and toast), results with a tie and pinned own row, get-ready with countdown shard all render with the uploaded art, no moderation block, and match `screenshots/04, 11, 12, 14, 02` in layout, copy and colour. Only rank 8 and the pinned row differ on purpose (stop at x 664 for the jump zone). Done at the Studio window's aspect (about 2:1), not exactly 844x390 or 1920x1080; the root scales to the safe area, so those sizes differ only in letterboxing. Still unchecked: lobby/empty/unavailable/wrong/rejected/sent with art, motion visuals, reduced motion, device landscape, touch/gamepad submit.

