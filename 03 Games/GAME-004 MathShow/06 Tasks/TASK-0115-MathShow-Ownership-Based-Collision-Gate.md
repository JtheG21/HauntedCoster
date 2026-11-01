---
id: TASK-0115
title: "MathShow Ownership-Based Collision Gate"
type: task
project: GAME-004
status: review
priority: medium
risk: low
owner: claude-code
depends_on:
  - TASK-0114
branch: task/TASK-0115-ownership-collision
created: 2026-11-01
updated: 2026-11-01
tags:
  - workflow/task
---

## Goal
Rebuild the menu collision check around ownership instead of name heuristics, so cross-control overlaps are all compared and every exemption is explicit and counted.

## Scope
- Owner = nearest `<Control>/Group/Content` ancestor; skip pairs inside one owner.
- Compare all cross-owner pairs, including shard images, labels, stickers, Spark frames and visible Flash/Glow.
- Exemptions only through `CollisionManifest.luau`, exact path pairs plus a reason; log the hit count.
- Planted-fault canary fixture the gate must flag.

## Not in scope
Layout fixes for real collisions (new task per fix). Hit-rect sizing (TASK-0116).

## Origin
Registered 2026-11-01 when TASK-0114 dropped its collision gate after two failed audits (see [[TASK-0114-MathShow-Tap-Target-Unmeasured-Rows-Audit]]). Backlog only: no implementation, not approved.

## Progress (2026-11-01, code build 28c7561)

- **Built:** pure `tests/studio/CollisionRules.luau` (rotated-rect overlap area, owner resolution, manifest matching, pair comparison) with `tests/CollisionRules.spec.luau` (13 tests, headless specs 297 passed); empty `CollisionManifest.luau`; `CollisionCanary.luau` (plain-Instance fixtures in tests/studio, not in the menu path); `TextFit.luau` integration and `TextFit.runCanary()`.
- **Owner rule:** the nearest ancestor X whose path continues `X/Group/...` (the `Menu/Shard` anatomy: Group holds Shard, Glow, Flash and Content), otherwise the element's own path. The task text said `X/Group/Content`; I widened it to `X/Group/<anything>` because a control's own Shard would otherwise count as a foreign element to its own label.
- **Red run:** both planted faults flagged and the composition control passed at 5/5 viewports (committed `0e48bfc`, before the real menu).
- **Real-menu run:** 81 cross-owner overlaps per viewport (23 unique pairs), manifest empty, no layout changed. Stop report with screenshots in `docs/workflow/STUDIO-SYNC.md`. **Waiting on jg:** approve manifest entries row by row; layout fixes become a new task.
- **Not recorded:** `record-exec`, because the gate is not green. A fail record would use a revision.

## Final (2026-11-01, code build 5b5a4ab)

- **Manifest:** 17 entries with `fixtures` lists for approved rows R1 to R4 (60 pair-fixtures). `matchManifest` treats a listed fixture with no pair as an unused entry; the spec covers a fixtures-list hit, a missing fixture and owner `X/Group/Shard` -> `X` (specs 300 passed).
- **Layout (jg-approved scope extension):** R5 `RankStrip` y 8 -> 0; R6 new `VsProblem` box (y 66, h 166) plus VS problem text y 60 -> 55. R6 attempt 1 broke the TextFit margin (1.5 px) and attempt 2 fixed it. Before/after screenshots for 14a and 08a in the scratchpad.
- **Gate:** 0 collision fails, 60 manifest hits and 0 unused per viewport, canaries FLAGGED/FLAGGED/PASS, ledger 669/284, IdentityBoards 109 / 0 / 0 GuiButtons at 5/5. TextFit 9,880 rows, 0 failures. Details in `docs/workflow/STUDIO-SYNC.md`.
- **For Codex:** audit `CollisionRules.luau`, the manifest semantics, the canary design and the two layout constants. The VS shard art is stretched (166 against 186 tall).


## Handoff (Codex review, TASK-0115 first review, 2026-11-01)
- **Task:** TASK-0115, ownership-based menu collision gate with canaries, a manifest and two jg-approved layout fixes. Receiver: Codex, reviewer only, no edits.
- **Workspace:** `/Users/jg/Desktop/Rg1-worktrees/task-0115`, branch `task/TASK-0115-ownership-collision`, PR #169. Range `28c7561..d2e59ae` (code `28c7561`, `c4c0b44`, `5b5a4ab`; the rest are docs).
- **Inputs:** [[TASK-0114-MathShow-Tap-Target-Unmeasured-Rows-Audit]], `docs/workflow/STUDIO-SYNC.md` (sections "TASK-0115 red run", "real-menu run: stop report" and "final gate").
- **Focus:**
  - `tests/studio/CollisionRules.luau:97` (`rotatedRectOverlapArea`): is the clip correct for every rotation, a shared edge, containment and zero size? Does the 0.5 px² threshold in `compare` (`:132`) hide real overlaps?
  - `CollisionRules.luau:114` (`resolveOwner`): the owner is the nearest `X/Group/<anything>`, wider than the task text's `X/Group/Content`. Does it mis-assign any element, and does it hide an overlap between a control's own parts?
  - `CollisionRules.luau:166` (`matchManifest`) and `tests/studio/CollisionManifest.luau`: an entry is unused when any listed fixture lacks the pair. Can a stale or over-broad entry pass? Do the 17 entries cover exactly the 60 approved pair-fixtures?
  - `TextFit.luau:340-451` (`glyphRect`, `collectElements`, `collisionChecks`, `runCanaries`): what visible elements are skipped (zero-alpha images, empty text, plain Frames)? Do the canaries fail for the right reason, not by accident?
  - `client/Menu/MenuTheme.luau` and `View.luau`: `RankStrip` y 0 and new `VsProblem` box plus VS text y 55. Do they change any other screen or break the 6 px margin?
- **Constraints:** no uploads, publishing or Studio writes. Rojo is stopped; ask jg before starting it.
- **Known non-task failures:** none. `check.sh`, `validate_queue`, `validate_vault` pass; CI green; specs 300 passed.
- **Unverified:** the gate ran once in Studio (Play, Client); same-owner overlaps are never compared, so a text move inside its own shard (VS text, 5 px up) is only checked by the TextFit margin and a screenshot.
- **Report back:** verdict, findings with file:line, checks run, what is unverified.

## Audit fixes, revision 1/2 (2026-11-01, code build 0e21eee)

- **Done:** F1 collection by drawable property with per-class counts; F2 `CollisionRole = "Halo"` attribute in `Menu/Shard.luau` and on `TierGlow`, R2 manifest entries removed (14 entries, 52 hits, 0 unused); F3 Blitz text back at y 60 (my earlier replace had changed both builders); F4 `canary-name-is-not-role` FLAGGED with the other three canaries unchanged.
- **Gate not green:** 27 cross-owner overlaps per viewport in 7 unique pairs: five are a Frame against its own child (timer tracks and `Fill`, miss slots and `Cross`), two are the toast over `Spark3`. Table with screenshots in `docs/workflow/STUDIO-SYNC.md`. Stopped as instructed; no manifest or layout change made.
- **Not recorded:** `record-exec`. A fail record would be revision 2/2.

## Final after audit fixes (2026-11-01, code build 34f046b)

- **jg decision:** an element and its own descendant are one owner (composition); manifest rows for the toast over `Spark3` (12 pair-fixtures).
- **Gate:** 0 collision fails, 64 manifest hits and 0 unused per viewport (16 entries), four canaries as expected, ledger 669/284, IdentityBoards 109 / 0 / 0 GuiButtons at 5/5. TextFit 10,525 rows, 0 failures. Specs 302 passed.

