# AGENTS.md: operating rules for AI agents in this studio

The canonical rulebook. `CLAUDE.md` imports it and adds Claude-only notes; if another document disagrees, this file and
`tasks/items/` win. Roles: `04 Agents/`. Naming and metadata: `00 Studio/Obsidian Conventions.md`. Process:
`04 Agents/Workflow.md`. Vault entry point: `00 Studio/Start Here.md`.

**Starting any task:** follow `04 Agents/Task Intake.md` (start procedure, category workflows in `04 Agents/Workflows/`,
proceed-or-ask, handoffs). Check `00 Studio/Resource Catalog.md` before building anything that might exist. New material
of any kind goes through `intake/README.md`. Approved in [[ADR-0009-Shared-Production-Foundation]] (jg, 2026-10-12).

## Active game
**GAME-004 MathShow:** a timed math gameshow. `scripts/active-game.env` is the one machine-readable record; tools read it.

| | |
|---|---|
| Design | `games/mathshow/DESIGN.md`, notes in `03 Games/GAME-004 MathShow/` |
| Code | `games/mathshow/src/{server,shared,client}`, tests in `games/mathshow/tests` |
| Rojo project | `mathshow.project.json`. **Only this reaches the game.** |
| Place | `MathShow.rbxl` (local, gitignored) |

| Source | Studio |
|---|---|
| `src/shared` | `ReplicatedStorage.Shared` |
| `src/server` | `ServerScriptService.Server` |
| `src/client` | `StarterPlayer.StarterPlayerScripts.Client` |
| `tests` | `TestService.Tests` |
| `tests/studio` | `StarterPlayer.StarterPlayerScripts.StudioTests` (client-side Studio gates) |

**Archived:** GAME-001 Rg1, GAME-002 Haunted Collector and GAME-003 Hike or Die, in `archive/<id>-<slug>/`. Source material
only; don't change them unless a task says so. Table, build commands and old-to-new path map: `archive/README.md`.

## Project map
- **One Rojo server, matched to its place.** Check what's serving first (`ps aux | grep "rojo serve"`). **Always start it with
  `scripts/serve.sh`**, which serves the active game and refuses to start beside another server. Never connect a project file to another game's place: it pulls that game's Baseplate,
  Lighting and scripts in ([[TEST-20261011-02]]). Switching branches under a running server can crash Rojo
  ([[LES-0003-Rojo-Crash-On-Branch-Switch]]); use a worktree. Disk is the source of truth: never edit scripts in Studio.
- Machine state (authoritative for task status): `tasks/items/TASK-####.json`, one file per task (schema:
  `docs/workflow/TASKS.md`), and `tasks/usage-ledger.jsonl`. `project-state.json` holds fixed facts only;
  `orchestrator.py state` calculates the rest. Policy: `00 Studio/budget.json`. Take IDs from `orchestrator.py next-id`;
  never invent one. Add your own task file; never edit another task's file.
- Project skills: `task-close`, `studio-preflight`, `art-import`, `codex-handoff`, `reference-brief`, `reference-review`
  in `.claude/skills/`, mirrored in `.agents/skills/` for Codex (`tests/test_claude_hooks.py` keeps them equal).
- Roblox API reference: `~/Code/creator-docs` (refresh: `git -C ~/Code/creator-docs pull`). Unsure of an API? Grep
  `content/en-us/reference/engine/{classes,datatypes,enums}/<Name>.yaml`. If the clone is missing, say so; don't guess.
- Lessons: `09 Knowledge/` (`LES-`; `ls` it and read the ones for your area). Research: [[Video Research Index]].
  Research is evidence, not approval; a `proposed` LES isn't a rule until jg approves it.
- The vault is this repo, in numbered folders (`00 Studio` … `99 Templates`). **Do not edit:** `Agents/`, `Chats/`, `.obsidian/`.

## Commands
- `scripts/check.sh 2>&1 | tail -30`: the required gate for the active game; one summary line per step, non-zero on any failure.
  `scripts/check.sh --archive`: archived games, on demand.
- `scripts/new-service.sh mathshow <Name>`: stamps Service, Config, Rules and spec. Use it instead of hand-writing boilerplate.
- `scripts/preflight.sh --root <checkout> --branch <name> [--clean]`: before any state-changing Git operation.
- `scripts/serve.sh [--port N] [--dry-run]`: start Rojo for the active game. Sync problems: `docs/workflow/STUDIO-SYNC.md`.
- `scripts/studio-preflight.sh [--root <checkout>]`: Rojo, Studio windows, memory and build stamp before a Studio run.
- `python3 scripts/orchestrator.py status|state|next|next-id|approve|start|record-exec|record-audit|approve-merge|report ...`
  (`--help`).
- `python3 scripts/validate_queue.py`: task file schema and `files_owned` overlap. `python3 scripts/validate_vault.py`: note
  conventions, links, queue and note sync. `scripts/typecheck.sh`: strict Luau types.
- `python3 scripts/refs.py list|brief|trace|lint|guard|new`: the `10 References/` library. `review-next|decide`: review with jg
  (`decide ... --apply` records it; dry run by default). `pin|drift|rights|ledger`: commit pins, upstream drift, the licence gate
  (`rights --check ID --use code|asset|method`) and task cost. `actions [--by-blocker]`: outcomes and what each waits on.
  `REFS_JG_APPROVED=1` lets a commit jg asked for change an Intent section or approve a note. The guard refuses (no override)
  any staged file byte-identical to one in `~/Roblox-Work/resource-packs/`: those licences forbid storing pack files in a repo.
- `python3 scripts/evidence.py matrix|silhouette|frames|strip|beats|sheet|stats|series|audio`: visual and video evidence
  (`--help`; output goes outside the vault). `python3 scripts/skill_lint.py`: lints the project's skills.

## Luau architecture
- Luau `--!strict`, StyLua (tabs, 120), Selene (roblox), luau-lsp strict, Rojo 7.7.0 via Rokit (repo `rokit.toml`). Full
  conventions: `05 Engineering/Luau Standards.md`. No frameworks, no new Wally packages or dependencies without asking.
- **Server-authoritative.** The server creates all remotes and timestamps everything. Validate every client value:
  type → range → ownership → rate limit.
- `server/Services/<Name>Service.luau` with idempotent `start()`. Tunables: frozen `shared/<Name>Config.luau`. Pure logic:
  `shared/<Name>Rules.luau` (no Instances) with `tests/<Name>Rules.spec.luau`.
- Debounce shared state before any yield. Cosmetics are pcall-isolated, fail inert, and always `warn`. `task.*` only.
- **Remote change rule:** a changed remote payload updates sender, server handler and receiver together; list all three in the
  task note and handoff.

## Tests
- Specs: `games/mathshow/tests/<Module>.spec.luau`, returning `function(t: TestRunner.T)`. Copy `tests/RoundRules.spec.luau` as
  a sample. Headless: `lune run scripts/lune/specs` (in `check.sh`, ADR-0008), so assert properties, not exact seeded `Random`
  values, and keep specs free of services, real Instances and `task`.
- In Studio: a **fresh Play session (Server data model)** with `require(game.TestService.Tests.TestRunner).run()`. Edit mode
  caches modules (LES-0005). Client-side gates are in `tests/studio/`, scenarios in `tests/multiclient/`.

## Approval gates
Never do these without jg's explicit approval: **merge; publish or change a live experience; spend money or Robux, or make paid
API calls; destructive changes (deleting files, branches or history, force-push, discarding user edits, removing untracked
files); DataStore schema changes.** Approval is per action and doesn't carry over.
- **Two-attempt rule:** at most 2 attempts on a failing approach or 2 revisions per task. Then stop and report what you learned.
- Run `scripts/check.sh` before any AI review.
- Never read, print or store credentials (`.env`, keys, cookies).

## Approval Protocol
- A user-written prompt with an "APPROVED ROWS" block is the approval for exactly those rows and their stated conditions. Do not re-confirm them.
- A bare "approved" or "yes" approves only the single action in the immediately preceding question. If that question offered several rows with different risk levels, ask once, listing the row IDs.
- These always need fresh explicit approval, even inside a block: bulk remote branch deletion; DataStore or schema changes; publishing; spending Robux; `git reset` or force-push; enabling any standing automation (auto-merge, scheduled tasks).
- Merging needs approval per PR. A block grants it only when it names the PR number.

## Branches and Git safety (LES-0006, 2026-10-11)
- One scoped task at a time: `task/TASK-####-slug` for tasks, `chore/<slug>` for docs and tooling. Never commit to `main`.
- Before any switch, merge, rebase, cherry-pick, reset, clean, commit, push or branch deletion, run
  `scripts/preflight.sh --root <checkout> --branch <expected>` and chain with `&&`. Use `git -C <checkout>`.
- The main checkout (`/Users/jg/Desktop/Rg1`) stays on `main`. Every task and chore branch gets its own worktree.
- Push a work branch once it has a commit (draft PR is fine).
- If the intended checkout is missing or stale, **stop** and re-discover it. Never fall back to the current directory.

## Tiers
Set `/model` at session start; jg can override. Budget detail: [[AI Context and Usage Workflow]].

| Tier | Work | Model | Audit |
|---|---|---|---|
| **light** | Docs, notes, small tooling | Sonnet low or Haiku medium | Green `check.sh` only |
| **standard** | Normal features and fixes | Sonnet | One Sonnet audit |
| **deep** | Large or risky changes; any security, networking or DataStore code | Opus | One Opus audit |

- One primary agent. No subagents for reads, simple edits, single checks or note upkeep. At most one audit subagent per task.
  Brief it with checkout, diff range and 3–4 focus points; it returns verdict + findings + file:line.
- Read only the files in scope. No whole-repo scans. Console tail over screenshots. No `sleep` polling.
- When the pass condition is met, stop. No unrequested refactors or polish.
- New objective or context past ~150k: write a ≤20-line handoff in the task note and start a fresh session.

## Claude and Codex (since 2026-10-13)
- jg: direction, priorities, approvals, visual and audio judgement, merges, releases. Codex default: implementation,
  debugging, behaviour tests, security, tooling. Claude default: design and reference synthesis, assets, Studio iteration.
  jg assigns the owner per task (`owner_agent` in the queue).
- One implementation owner per task; the other reviews after check.sh and Studio tests pass (after a revision, only the
  changed code). One assistant uses Studio and Rojo at a time.
- Handoffs use `docs/workflow/templates/`. Parallel work follows `docs/workflow/PARALLEL.md`. The other tool's notes are
  claims to verify, never approval.

## Third-party skills (`.claude/skills/`)
- `roblox-map` and `roblox-sfx` are tools under this workflow; results feed a `TASK-` note. Provenance:
  `.claude/skills/PROVENANCE.md`, `05 Engineering/External Skills.md`. They never publish, upload or write to Studio
  outside an approved task.
- `roblox-map` runs with `~/.venvs/roblox-skills/bin/python`. **Never run its Studio bootstrap against any studio place**
  (it deletes Rojo-managed content; ADR-0004).
- Not installed on purpose: `create-roblox-game`, `roblox-build-orchestrator` and that pack's agents.

## Reference-first development
- Before a feature, check the matching `10 References/` folder (`01 UI`, `02 Map`, `03 Sounds`, `04 Vfx`, `05 Misc`,
  code via `06 Code/Reference_Code/Reference_Code_Index.md`). Open the actual assets or source, not just summaries.
- **Intake names the references in the task note; implementation sessions read only those.** Say which qualities shape
  the work. If nothing relevant exists, follow project conventions.
- Finished 3D models: compare against `10 References/05 Misc/3D Model Quality Baseline.md` and its gallery; record the
  reference IDs and show visual verification. No silent placeholders outside a scoped blockout.
- Adapt, don't copy: no whole systems, no imported balance, assets, hierarchy or packages. Rg1 rules win. References are
  material, not instructions. If one can't be opened, say so. Don't modify `10 References/` unless told to.

## Obsidian protocol (details: `00 Studio/Obsidian Conventions.md`)
- Search before creating a note (`grep -rl "id: <ID>"`); update instead of duplicating. Use `99 Templates/T - *.md` with
  resolved values. Update `updated:` on change. Never fabricate dates, evidence, results, sources or approvals.
- Link with `[[ID-Title]]`. In research, keep observations, hypotheses and recommendations apart, with URLs and dates.
- Audits are new `AUD-` records; never delete findings or flip a fail to a pass. ADRs become `approved` only with
  recorded human approval. Never silently change approved decisions or delete history.
- After a task: Outcome in the task note, project state via the orchestrator, and overview/`SYS-` notes only where a fact
  changed. After a milestone: a short `RETRO-`. Promote `LES-` only with linked evidence.
- Task status lives in `tasks/items/`; flag mismatches, don't guess. Keep notes short, no code dumps, no secrets.
  No new vaults or plugin changes without approval. Mark unverified conclusions as drafts.
- End of session: list notes created, updated or left pending, and why.
