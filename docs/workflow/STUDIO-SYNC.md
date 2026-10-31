# Studio sync: why Studio stopped receiving scripts (TASK-0110)

**Status:** Phase 0. The cause isn't confirmed yet: the checks that need an open place are waiting on Studio.

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

## Still to do with a place open
1. Read the Rojo panel and Output for `lacking permission` or property errors on connect.
2. Compare `BuildStamp` and a script's `Source` with disk.
3. Change a comment on disk and see whether `Source` follows.
