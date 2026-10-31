# Handoff: TASK-0094 MathShow Scores (leaderstats + Results screen)

**Task:** TASK-0094. Add a per-player `Score` leaderstat that updates at each Reveal, and a client Results screen that shows the final standings from the `scores` RoundState already sends. No remote payload change, no persistence.
**Receiver:** Claude Code (executor), tier **light** (Sonnet). Light audit rule: green `scripts/check.sh`, no audit subagent.
**Workspace:** `/Users/jg/Desktop/Rg1` (repo `JtheG21/HauntedCoster`), branch `task/TASK-0094-MathShow-Scores`, GAME-004, code root `games/mathshow/`. Main checkout stays on `main` at `881266e`; work in a new worktree (e.g. `/Users/jg/Desktop/Rg1-worktrees/task-0094`).

## Start by
1. Read `AGENTS.md`, `04 Agents/Task Intake.md`, `04 Agents/Workflows/UI Workflow.md` and `Systems Workflow.md`.
2. `python3 scripts/orchestrator.py status`. TASK-0094 is `proposed`; if `start` is refused for lack of approval, stop and ask jg to run `approve`. Then `python3 scripts/orchestrator.py start TASK-0094`.
3. **Take the context-usage reading now** and note it in the task note (TASK-0093 closed without one).
4. Create the worktree: `scripts/preflight.sh --root /Users/jg/Desktop/Rg1 --branch main && git -C /Users/jg/Desktop/Rg1 worktree add /Users/jg/Desktop/Rg1-worktrees/task-0094 -b task/TASK-0094-MathShow-Scores main`. Never switch branches in the main checkout (LES-0003).
5. If a file, tool or permission listed here is missing, stop and report. Do not guess.

## Inputs (repo-relative, read only these)
- Spec: `03 Games/GAME-004 MathShow/06 Tasks/TASK-0094-MathShow-Scores.md`; design: `games/mathshow/DESIGN.md`.
- Server: `games/mathshow/src/server/Services/RoundService.luau`, `server/init.server.luau`. Shared: `shared/Net.luau` (`ScoreEntry`), `shared/HudRules.luau`, `shared/HudConfig.luau`, `shared/ScoringConfig.luau`. Client: `client/Hud/init.luau`, `View.luau`, `Theme.luau`. Tests: `tests/HudRules.spec.luau`, `tests/TestRunner.luau`.
- Precedent for conventions and the playtest write-up: `03 Games/GAME-004 MathShow/06 Tasks/TASK-0093-MathShow-Hud.md`, `07 Playtests/TEST-20261025-02.md`.
- References: none specific (task note). Check `10 References/01 UI/` only for a results/podium layout; adapt, don't copy. Reuse: Roblox's built-in `leaderstats` pattern plus the existing Hud `Theme`/`View` helpers.

## Keep unchanged
- RoundService **scoring and submission logic** (`onSubmit`, `scores()`, `payload()`, secrecy rules). The client consumes `scores`; it never recomputes them.
- `Net.luau`, `Remotes.luau` and every remote's payload: **no sender/handler/receiver change**.
- Untracked files in the main checkout (`HudSpec.json`, `.codex/`, `RSH-20261015-*`, `02 Research/assets/wisp-pilot/`): don't touch, stage or commit. Other games' code, `10 References/`, `Agents/`, `Chats/`, `.obsidian/`.

## Constraints
- `--!strict`, StyLua, Selene, no new packages or Wally deps, `task.*` only, no yields between a debounce and its state change.
- No DataStore, no `MarketplaceService`, no publish, no Robux, no assets (UI built in code, Theme colours and fonts only).
- Cosmetics are pcall-isolated and every caught error is `warn`ed. Never edit scripts in Studio.
- Max 2 revision attempts, then stop and report.

## Design (decisions made; follow them)
1. **Leaderstats update at Reveal, not on submit.** DESIGN.md sends `scores` only in Reveal/Results; an IntValue changing at submit time would replicate to everyone and leak who answered. So publish synchronously when the Reveal phase starts. AC1 says "after each Reveal".
2. **New `server/Services/LeaderstatsService.luau`** (idempotent `start()`, per AGENTS). `start()` creates `leaderstats` Folder + `Score` IntValue (create the IntValue first, parent the Folder last) for current and future players, guarded by `started`. API: `publish(scores: { Net.ScoreEntry })` sets each current player's `Score` to the cleaned points of their entry, else 0 (non-participants, late joiners); `reset()` sets all to 0. No yields. Server `init.server.luau` starts it **before** `RoundService.start()`.
3. **RoundService wiring only** (three small edits): require the service; call `reset()` inside `resetMatch()`; in `runPhase`, when `nextPhase == "Reveal"`, call `publish(scores())` immediately before `broadcast()` and add one log line `[MathShow] leaderstats published n=<count>`. Wrap each call in `pcall` and `warn` on failure so a leaderstats fault can never stop the match loop. Match-level scores reset at match start (assumption, recorded in the task note).
4. **New pure module `shared/StandingsRules.luau` + `shared/StandingsConfig.luau` + `tests/StandingsRules.spec.luau`** (use `scripts/new-service.sh` only if you want the stamp; this task needs no Rules-only service, so hand-write the three files). Config (frozen): `PodiumSize = 3`, `ListRows = 5`, `MaxNameChars = 20`, `MaxPoints = 2147483647`. Rules, all non-throwing:
   - `isValidScores(any): boolean`: array of tables with finite integer `userId`, string `name`, finite `points >= 0`; rejects holes, non-tables, duplicates of `userId`.
   - `cleanPoints(any): number`: non-finite or negative -> 0, floor, cap at `MaxPoints`.
   - `displayName(any): string`: non-string -> `"?"`, empty -> `"?"`, longer than `MaxNameChars` is cut with an ellipsis (Unicode-safe via `utf8`).
   - `build(scores, localUserId): Model` where `Model = { empty: boolean, podium: {Row}, others: {Row}, you: Row?, hiddenCount: number }` and `Row = { rank, userId, name, points, isYou }`. Sort by points desc then userId asc (server's order), **competition ranking** (ties share a rank: 1,1,3), `podium` = first `PodiumSize` rows, `others` = next `ListRows`, `you` = local row only when it is **outside** podium and others, `hiddenCount` = remaining rows not shown (excluding `you`).
5. **Hud**: `HudRules.visibility` gains `results = true` for `Results` only (update the type and `HudRules.spec`). `HudConfig.Strings` gains `ResultsTitle = "Final standings"`, `NoScores = "No scores this match"`, `ScoresUnavailable = "Scores unavailable"`, `PointsFormat = "%d pts"`. `View.build` adds a `Results` panel and `view.setResults(model: StandingsRules.Model?, message: string?)`; `nil` hides it. `Hud.applyState`: when `show.results`, validate `payload.scores` with `isValidScores`, build with `Players.LocalPlayer.UserId`, call `setResults` inside `pcall` (warn on error). Invalid scores: `warn` and show `ScoresUnavailable`. Any other phase: `setResults(nil)`.
6. **Results layout** (phone landscape 844x390, same safe-inset ScreenGui, scale positions plus `UISizeConstraint`/`UITextSizeConstraint`, min text 12): title; podium of up to 3 columns ordered 2nd-1st-3rd with 1st tallest; unused podium slots hidden (1 player = centre column only); below it up to `ListRows` rows `rank. name - pts`; a highlighted "you" row (Theme `accent`) when `isYou`, and `+N more` when `hiddenCount > 0`. Pre-create the fixed set of labels in `build` and only set text/visibility afterwards. No tweens in this task.
7. Results screen text is the only UI in scope. Showing who got each question in Reveal is **out of scope** (needs a payload change); don't fold it in.

## Stages
1. Worktree + `start` + context reading.
2. `StandingsConfig`/`StandingsRules` + spec, then `scripts/check.sh 2>&1 | tail -30`.
3. `LeaderstatsService`, `init.server` start order, RoundService wiring. Check again.
4. `HudRules.visibility`/spec, `HudConfig` strings, `View` Results panel, `Hud` wiring. Check again; `TYPECHECK_REQUIRED=1 scripts/typecheck.sh`.
5. Studio playtest (below), then fill the task note's Implementation record, commit, push, open a **draft** PR.

## Spec cases (boundaries and edges, not implementation)
- `isValidScores`: empty array ok; non-table, string, nil rejected; hole in array, NaN/inf/negative/fractional points, non-integer or duplicate `userId`, non-string name rejected.
- `cleanPoints`: 0, 7.9 -> 7, -1 -> 0, NaN -> 0, inf -> 0, string -> 0, above cap -> cap.
- `displayName`: empty, non-string, exactly `MaxNameChars`, one over (ellipsis), multi-byte characters not split.
- `build`: empty list -> `empty = true`; 1, 2, 3 players; exactly `PodiumSize + ListRows` players (no `hiddenCount`, no `you`); one more (`hiddenCount = 1`); local player rank 1, rank 4, and beyond the list (`you` set); local player absent; ties at 1st (ranks 1,1,3) and tie across the podium/list boundary; unsorted input is sorted identically to the server (points desc, userId asc); all-zero scores.
- `HudRules.visibility`: `results` true only for `Results` (and false for nil/unknown input).
- Use scalar `t.eq` on fields (the runner has no deep-equal).

## Acceptance criteria
- [ ] AC1 Each player has a visible `Score` leaderstat that updates after each Reveal (not before). Proof: server log `leaderstats published` once per Reveal, `Score` values read in Play, player list screenshot.
- [ ] AC2 Results shows a ranked podium matching the server's `scores` at match end. Proof: Hud rows compared with the server's final `scores` and the `Score` values.
- [ ] AC3 No DataStore or persistence call. Proof: `grep -rniE "DataStore|MarketplaceService" games/mathshow` returns nothing.

## Tests
- **Automated:** `scripts/check.sh 2>&1 | tail -30` (expect MathShow specs above 57 passed, ALL CHECKS PASSED) and `TYPECHECK_REQUIRED=1 scripts/typecheck.sh`.
- **Studio (one player, via Studio MCP):** `studio-preflight` is GAME-002-only, so check by hand: `ps aux | grep "rojo serve"` shows exactly one server, `mathshow.project.json` from the **worktree**; place is `~/Desktop/Rg1/MathShow.rbxl` (no other Studio window); Play in a fresh session (LES-0005). Confirm `Client.Hud`, `Server.Services.LeaderstatsService` and `Shared.StandingsRules` synced. Play one full match: answer some questions right and skip one. Verify: `Score` unchanged during Question, changes when Reveal starts, equals the running total shown in Reveal; final Results shows the podium (1 player = centre column + "you" highlighted), then Intermission hides it and `Score` returns to 0 at the next match start. Console tail: no new warnings (the `ContentId rbxassetid://203785492` lines are pre-existing). Prefer the console log to screenshots; take one screenshot of Results.
- **Write up** as the next `TEST-` note in `07 Playtests/` (follow TEST-20261025-02's shape), link it from the task note.
- **Cannot verify here (say so, don't claim):** two or more players, ties on screen, `+N more`, joining/leaving mid-match (TASK-0095); phone-landscape emulator, touch, gamepad (jg manual check); the default player-list leaderboard on mobile.

## Open questions
None blocking. Assumptions to record in the task note: leaderstats are match-level (reset at match start, in-memory only); leaderstat updates at Reveal for secrecy; podium capped at 3 plus 5 list rows plus the local player's row; ties share a rank.

## Report back with
Files changed (new/modified), check.sh and typecheck output tails, the TEST note path, per-AC evidence, anything unverified, and the follow-ups still open (Reveal "who got it", `studio-preflight.sh`/`stamp.sh` GAME-002-only, FireServer-failure message). Use: implemented and tested / implemented, not tested / planned / blocked / needs a manual check. Do **not** merge, run `approve-merge`, or clean up worktrees; jg approves the merge and runs `task-close`.
