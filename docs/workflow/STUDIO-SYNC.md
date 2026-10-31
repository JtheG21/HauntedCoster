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

