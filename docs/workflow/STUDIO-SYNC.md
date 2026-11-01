# Studio sync: why Studio stopped receiving scripts (TASK-0110)

**Status:** sync works in a clean setup (below). The exact cause is **not proven**: the old failure wasn't reproduced.

## Symptom (2026-10-27 to 10-30)
The plugin connects and `ReplicatedStorage.Shared.BuildStamp` updates, but existing scripts keep their old source. New instances do appear.

## Phase 0 evidence (2026-10-30)

| Check | Result |
|---|---|
| Rojo listeners | None running at the start. No conflict between servers |
| `rojo --version` in the repo | 7.7.0, protocol 5, from `~/.rokit/bin` |
| `rojo` outside a repo | `~/.rokit/bin` first on PATH. From `~` it resolves to 7.6.1 through `~/rokit.toml`; `~/.aftman/bin/rojo` is next on PATH |
| Root `default.project.json` | None, as intended. Only `mathshow.project.json` |
| Server probe (scratch clone, port 34899) | **Saw an on-disk comment change in 0.5 s and sent it out** through `/api/read`, with the message cursor advancing |
| Wire format | **MessagePack, not JSON.** This explains the handoff's "Can't parse JSON" from the 7.6.1 plugin |
| Installed plugins | **Three load at once:** local `Rojo.rbxm` 7.7.0, local `RojoManagedPlugin.rbxm` 7.6.1, cloud plugin 13916111004 at 7.7.1 |
| Studio log | Cloud 7.7.1 hit `rejectWrongProtocolVersion` / `attempt to index number with 'protocolVersion'` 4 times. It also shows repeated WebSocket disconnects |
| Plugin source | `Reconciler.setProperty` writes `Source` through a permission-checked property write and has a specific `LackingPropertyPermissions` error |
| Studio log, other | `PatchScriptWithDrafts` and `PatchLiveScriptingSandboxedSources` task names appear |
| BuildStamp probe | **Not done:** Studio reports "Place is not open" (home screen, process from another session) |
| Build stamp on disk | `+dirty`, because of the untracked `HudSpec.json` |
| `MathShow.rbxl` | 3 KB, from 2026-10-25, so it holds no game scripts until a sync creates them |

## Findings

| Cause | Evidence | Confidence |
|---|---|---|
| The server or file watching | Probe shows changes reach the API in 0.5 s | **Ruled out** for a server started this way |
| Project file | The same probe served the changed source | **Ruled out** |
| Plugin 7.6.1 connecting | Can't parse this server's MessagePack | **Certain it can't work**, but not by itself the cause: it fails outright |
| Three Rojo plugins loaded | Log shows all three; each has its own panel, so it's easy to use the wrong one | **High** as a contributor |
| Plugin 7.7.1 against server 7.7.0 | Protocol error in the log, though the handoff says it connected at times | **Medium** |
| Plugin lacks script injection permission | Fits the symptom: `Source` writes are the gated ones, `StringValue` updates aren't. Not yet observed | **Medium, needs Studio** |
| Script drafts or an open editor holding old source | Task names in the log only | **Low, needs Studio** |

## Live results (2026-10-30)
Setup: Studio freshly restarted, `scripts/serve.sh`, `MathShow.rbxl`, only the 7.7.0 plugin enabled. jg reported Script Injection was already allowed, which **rules that suspect out**.

| Check | Result |
|---|---|
| BuildStamp, Studio vs disk | Match: `4ade979 2026-10-31T01:32:43Z` |
| `MenuTheme` source | 16,890 characters, same as disk |
| Comment added on disk | In Studio's `Source` at the first read, under 12 s window |
| Comment reverted | Gone at the first read; BuildStamp also followed |
| Play: `MenuTheme.Text.Title` | 46 (the old failure showed 40) |

**Most likely cause (not proven):** more than one Rojo plugin loaded, including 7.6.1, which can't speak this server's protocol, and 7.7.1, which logged a protocol error. Disabling them was one of several things that changed at once, alongside a Studio restart and a Studio update to 0.745. To prove it, re-enable a plugin and repeat the probe.

**Keep doing:** start with `scripts/serve.sh`, and keep one Rojo plugin enabled, matching the server's version.

**HudSpec:** the untracked `games/mathshow/src/shared/HudSpec.json` is gone from the main checkout, which clears its `+dirty` stamp. The file now exists only on this branch, as `docs/design/hud/HudSpec.json`, until the branch merges.

**Play ran from this branch, not `main`:** `git diff main...HEAD` touches nothing under `games/`, so the game code is the same.

**`serve.sh` refusal, checked by hand:** with Rojo on 34872, `--port 34999 --dry-run` exited 1 and named the running server. No automated test covers this branch.

## Gate results (fresh Play, viewport 1336x669)
Console: no errors from MathShow. Expected warnings: DataStores unavailable (unpublished place) and placeholder images. `rbxassetid://203785492` failed to load; it isn't in `games/`, and it appeared in Edit before Play too.

| Gate | Result |
|---|---|
| TASK-0107 TextFit, 844x390 / 1920x1080 / phone 812x375 | **PASS:** 953 rows each, 2,859 total, 0 failures |
| Margins | 2,007 rows measured across 210 elements; tightest 6.5 px (`Screen_blitz/Score` Value, `Screen_vs/Back` Label) against the 6 px rule |
| Not margin-measured | 852 rows: tap targets, stickers and labels not on a shard |

### TASK-0112 re-run, 2026-10-31 (real art, build 890ac77)

Fresh Play on `task/TASK-0112-startup-asset-warnings`, Rojo served from that worktree, BuildStamp `890ac77` confirmed in Edit before Play. `require(...StudioTests.TextFit).run()` on the client.

| Gate | Result |
|---|---|
| TextFit, 844x390 / 1920x1080 / phone 812x375 | **PASS:** 953 rows each, 2,859 total, 0 failures |
| Tightest margin | 6.5 px (`06a-blitz-question`, `Screen_blitz/Score/Group/Content/Value`), 6 px rule |

This run used the uploaded menu art. The TASK-0110 run above used placeholders, so this one is the stronger evidence. The 852 rows that are not margin-measured still stand, as does the TASK-0106 IdentityBoards gap.
| TASK-0106 IdentityBoards | 109 rows, 0 failed, **844x390 only** |
| TASK-0106 margins | **Still incomplete:** `ShapeProfiles` has no `shard-id-*` profiles, so its text rows have no 6 px check. The harness has one canvas, so the other viewports weren't run |

The gate measures geometry against shape profiles. With the 17 PNGs not uploaded, the visible menu is placeholders. Evidence: `docs/workflow/evidence/TASK-0110/menu-01-main-standard.jpg`. Full per-row output went to Studio's Output, and only this summary is saved. No identity board screenshot was taken.

### TASK-0113 tablet viewports, 2026-10-31 (build 9732f94)

BuildStamp `9732f94` confirmed in Edit before Play, after a Rojo reconnect. Fresh Play on `task/TASK-0113-menu-tablet-textfit`.

| Viewport | TextFit rows | TextFit failures | IdentityBoards rows | IdentityBoards failed |
|---|---|---|---|---|
| 844x390 | 953 | 0 | 109 | 0 |
| 1920x1080 | 953 | 0 | 109 | 0 |
| phone 812x375 | 953 | 0 | 109 | 0 |
| 1024x768 (new) | 953 | 0 | 109 | 0 |
| 1180x820 (new) | 953 | 0 | 109 | 0 |
| **Total** | **4,765** | **0** | | **0** |

- **Tightest TextFit margin:** 6.5 px at `844x390`, `06a-blitz-question`, `Screen_blitz/Score/Group/Content/Value`. The 6 px rule holds. Per-viewport tightest values were not recorded.
- **IdentityBoards tightest margin:** not reported. The harness prints failures only, so a pass means no row was under 6 px.
- **Before the fix:** the first IdentityBoards run failed at all five viewports. `FIRST CORRECT` on `shard-id-status-gold` measured 5 px, or 4.75 px at 1920x1080, and `[WWWWW]` on `shard-id-tag` measured 5.75 px. The fix is in `9732f94`: `ExtraWidth = 2` on the tag and status chips in `client/Identity/`. Text and icon positions did not change. After the fix, all five viewports passed.
- **Baseline mismatch:** the TASK-0106 entry above records 109 rows and 0 failures at 844x390. This build failed at that viewport before the fix, so its cause is not traced beyond the two chips.

### TASK-0114 extended gate, 2026-10-31 (build 9ccb8eb)

Fresh Play, Rojo from `task/TASK-0114-tap-target-audit`, BuildStamp `9ccb8eb` confirmed in Edit before Play. `TextFit.run()` and `IdentityBoards.run()` at 844x390, 1920x1080, phone 812x375, 1024x768 and 1180x820.

| Check | 844x390 | 1920x1080 | phone 812x375 | 1024x768 | 1180x820 |
|---|---|---|---|---|---|
| Historical unmeasured rows (reconciled) | 284 | 284 | 284 | 284 | 284 |
| Measured rows | 669 | 669 | 669 | 669 | 669 |
| Clip rows (fails) | 261 (0) | 261 (0) | 261 (0) | 261 (0) | 261 (0) |
| Collision rows (fails; intentional passes) | 481 (0) | 481 (0) | 481 (0) | 481 (0) | 481 (0) |
| Overlap, allow-listed | 8 | 8 | 8 | 8 | 8 |
| Review-row gap rows (fails) | 24 (0) | 24 (0) | 24 (0) | 24 (0) | 24 (0) |
| Tap rows (fails), design units, min 44 | 10 (0), smallest 44 | 10 (0), smallest 44 | 10 (0), smallest 44 | 10 (0), smallest 44 | 10 (0), smallest 44 |
| Screen-px margin rows under 6 (informational) | 0 | 0 | 0 | 0 | 0 |
| Tightest measured margin (design px) | 6.5 | 6.5 | 6.5 | 6.5 | 6.5 |
| IdentityBoards rows / failed / tightest margin | 109 / 0 / 7.0 | 109 / 0 / 6.75 | 109 / 0 / 6.75 | 109 / 0 / 6.75 | 109 / 0 / 6.75 |
| IdentityBoards GuiButtons | 0 | 0 | 0 | 0 | 0 |

- **Totals:** `TextFit` 8,685 rows across the five viewports, 0 failures. `TextFit` at the original three viewports is still 953 rows each.
- **Tightest measured margin:** 6.5 design px at `06a-blitz-question`, `Screen_blitz/Score/Group/Content/Value`. At phone scale that is 6.25 screen px, so nothing falls below 6 screen px.
- **Review rows:** minimum gap 2 px, at `07a-blitz-review-best`, `Screen_blitzreview Row1->Row2`.
- **Tap size:** `AbsoluteSize` divided by the gate scale, minimum 44 design px. The smallest control is `Screen_main/HowToPlay/Group/Content/Hit`, 230x44 design px, at every viewport. It passes at exactly 44, so there is no margin on that control.
- **Intentional composition passed and labelled:** screen-edge decor, sticker or label on its own control, glow and flash layers, NEW BEST badge across a card corner, duplicate text layer (shadow or glow), VS badge across the panel seam.

### TASK-0114 audit fixes, 2026-11-01 (build 0b8c767)

Fresh Play, Rojo from `task/TASK-0114-tap-target-audit`, BuildStamp `0b8c767` confirmed in Edit before Play. Full gate at five viewports: `TextFit.run()` and `IdentityBoards.run()`.

**Fixes (file:line in `games/mathshow/tests/studio/`)**

| Finding | Change | Where |
|---|---|---|
| P1 overlap allow-list | Only `Screen_settings/Row{music,sfx}/…/Hit` against the same row's `Minus`/`HitMinus`/`Plus`/`HitPlus` | `TextFit.luau:346` (`allowedSettingsPair`) |
| P2 image filter | Explicit decoration list (`Shard`, `Flash`, `Glow`, `Spark1-3`, `Touch`), counted per instance and viewport. Every other image and ImageButton is checked | `TextFit.luau:316` (`DECOR_IMAGE_NAMES`), `:498` (count), `:500` |
| P2 collision self-match | `d == L.inst` skipped | `TextFit.luau:506` |
| P2 duplicate text | Only a sibling (same Parent, same Name, same Text) | `TextFit.luau:363` |
| P2 sticker frames | Visible `FitSticker` Frames and ImageLabels in clip and collision checks | `TextFit.luau:456`, `:462` |
| P2 IdentityBoards census | GuiButton count before `gui:Destroy()` | `IdentityBoards.luau:278` (count), `:285` (destroy) |
| Edge exemption | Name prefix `Edge` only | `TextFit.luau:366` |
| NEW BEST exemption | Counterpart must be inside the same screen's `Card` | `TextFit.luau:377` |
| VS exemption | Counterpart must be `You` or `Rival` on the same screen | `TextFit.luau:386` |

**Exemption counts per viewport** (passed rows). Old numbers are the audit's figures, which I can't reproduce against a per-viewport basis.

| Category | Old (audit) | New, per viewport | New, total (5) |
|---|---|---|---|
| Edge | 205 | 4 | 20 |
| Own-control | 81 | 0 | 0 |
| Glow | 79 | 0 (now decoration) | 0 |
| NEW BEST | 2 | 0 | 0 |
| Dup | 110 | 0 | 0 |
| VS | 4 | 0 | 0 |

The old Glow, Shard and Flash collisions are no longer checked as collisions. They are on the decoration list instead, so the collision count dropped as a result.

**Decoration exclusions** (instances, per viewport, summed across fixtures):

| Name | 844×390 | 1920×1080 | phone 812×375 | 1024×768 | 1180×820 |
|---|---|---|---|---|---|
| Glow | 111 | 111 | 111 | 111 | 111 |
| Shard | 341 | 341 | 341 | 341 | 341 |
| Flash | 341 | 341 | 341 | 341 | 341 |

**Previously hidden shard images** (checked by the new rule): 240 per viewport, 0 overlapping, 0 failures.

**Full gate, build 0b8c767**

| Check | Result |
|---|---|
| TextFit rows, 5 viewports | 6,335 total, 0 failures |
| Clip | 264 rows per viewport, 0 failures |
| Collision | 4 rows per viewport (Edge exemptions), 0 failures |
| Overlap | 8 allow-listed pairs per viewport, 0 failures |
| Review-row gap | 24 rows per viewport, 0 failures |
| Tap (design px, min 44) | 10 rows per viewport, smallest 230×44 |
| Measured margin, tightest | 6.5 design px |
| IdentityBoards | 109 rows per viewport, 0 failures |
| IdentityBoards tightest margin | 7.0 at 844×390, 6.75 elsewhere |
| IdentityBoards GuiButtons (real count) | 0 at all five viewports |

**Caveat for the auditor.** The decoration list is now the main source of exclusions. It removes most collision checks against Glow, Shard and Flash images, which is where the old collision counts came from. Please check that list.


### TASK-0114 narrowed scope, 2026-11-01 (build 025b721)

Collision checking is removed from TASK-0114 and moves to TASK-0115 (ownership-based gate), after two failed audits. Fresh Play, Rojo from `task/TASK-0114-tap-target-audit`, BuildStamp `025b721` confirmed in Edit before Play and printed in the log header. `TextFit.run()` and `IdentityBoards.run()` at five viewports. The log now prints, before the row list: BuildStamp, per-viewport category counts (zeros included) and the reconciliation line. Each viewport also prints `collision: NOT COVERED -> TASK-0115`.

| Check | 844x390 | 1920x1080 | phone 812x375 | 1024x768 | 1180x820 |
|---|---|---|---|---|---|
| Measured rows | 669 | 669 | 669 | 669 | 669 |
| Unmeasured rows | 284 | 284 | 284 | 284 | 284 |
| Reconciliation (669 + 284 = 953) | OK | OK | OK | OK | OK |
| Clip rows (fails) | 264 (0) | 264 (0) | 264 (0) | 264 (0) | 264 (0) |
| Tap rows, design units, min 44 (fails) | 10 (0) | 10 (0) | 10 (0) | 10 (0) | 10 (0) |
| Overlap rows (fails) | 0 (0) | 0 (0) | 0 (0) | 0 (0) | 0 (0) |
| Overlap, allow-listed | 8 | 8 | 8 | 8 | 8 |
| Review-row gap rows (fails) | 24 (0) | 24 (0) | 24 (0) | 24 (0) | 24 (0) |
| Informational screen-px rows | 0 | 0 | 0 | 0 | 0 |
| Collision | NOT COVERED | NOT COVERED | NOT COVERED | NOT COVERED | NOT COVERED |
| IdentityBoards rows / failed / GuiButtons | 109 / 0 / 0 | 109 / 0 / 0 | 109 / 0 / 0 | 109 / 0 / 0 | 109 / 0 / 0 |

- **Totals:** `TextFit` 6,300 rows (1,260 per viewport), 0 failures. Unmeasured total 1,420 of 1,420 expected. The run fails if either reconciliation is off.
- **Removed:** pairwise collision checks, the decoration image list, the Edge, NEW BEST, VS and duplicate-text exemptions, and the hidden-image tally.
- **Kept:** tap size (design units, 44), the same-row settings allow-list, sticker and label clipping including FitSticker Frames, the review-row gap, the IdentityBoards census before destroy, and the 1,420-row reconciliation.
- **Smallest tap:** `Screen_main/HowToPlay/Group/Content/Hit`, 230x44 design units, at every viewport. TASK-0116 raises hit rects to 48.
- **Not covered by this gate:** overlap between controls, shards, labels, stickers and decoration other than the settings allow-list. TASK-0115 owns it.
