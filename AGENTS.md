# AGENTS.md: operating rules for AI agents in this studio

Permanent instruction file; `CLAUDE.md` imports it. Roles: `04 Agents/` (only copy). Naming and metadata:
`00 Studio/Obsidian Conventions.md`. Process: `04 Agents/Workflow.md`.

**Starting any task:** follow `04 Agents/Task Intake.md` (start procedure, category workflows in `04 Agents/Workflows/`,
proceed-or-ask, handoffs). Check `00 Studio/Resource Catalog.md` before building anything that might exist.
Approved in [[ADR-0009-Shared-Production-Foundation]] (jg, 2026-10-12).

## Project map
- **Active game: GAME-004 MathShow** (`03 Games/GAME-004 MathShow/`): a timed math gameshow. Design: `games/mathshow/DESIGN.md`.
  Code: `games/mathshow/src/server|shared|client` and `games/mathshow/tests`, synced by **`mathshow.project.json`** into
  `MathShow.rbxl`. **Only these reach that game.**
- Paused: GAME-003 Hike or Die (`games/hike-or-die`, `hike-or-die.project.json`), GAME-002 Haunted Collector (`games/haunted`,
  `haunted.project.json`) and GAME-001 Rg1 (`src/`, `tests/luau`, `default.project.json`). Source material only. Don't
  change them unless a task says so.
- **One Rojo server, matched to its place.** Check what's serving first (`ps aux | grep "rojo serve"`). Never connect a
  project file to another game's place: it pulls that game's Baseplate, Lighting and scripts in ([[TEST-20261011-02]]).
  Switching branches under a running server can crash Rojo ([[LES-0003-Rojo-Crash-On-Branch-Switch]]); use a worktree.
- Machine state (authoritative for task status): `tasks/queue.json`, `tasks/usage-ledger.jsonl`, `project-state.json`.
  Policy: `00 Studio/budget.json`. Task IDs come from the queue; never invent one.
- Tools: `scripts/check.sh` (run as `scripts/check.sh 2>&1 | tail -30`), `scripts/new-service.sh <game> <Name>` (stamps
  Service, Config, Rules, spec; use it instead of hand-writing boilerplate), `scripts/orchestrator.py` (task gates),
  `scripts/validate_vault.py`, `scripts/refs.py`, `scripts/typecheck.sh`, `scripts/preflight.sh` (Git checkout guard),
  `scripts/studio-preflight.sh` (before a Play test).
- Project skills: `task-close`, `studio-preflight`, `art-import`, `codex-handoff`, `reference-review`, `reference-brief`
  in `.claude/skills/`, mirrored in `.agents/skills/` for Codex (`tests/test_claude_hooks.py` keeps them equal).
- Roblox API reference: `~/Code/creator-docs` (refresh: `git -C ~/Code/creator-docs pull`). Unsure of an API? Grep
  `content/en-us/reference/engine/{classes,datatypes,enums}/<Name>.yaml`. If the clone is missing, say so; don't guess.
- Lessons: `09 Knowledge/` (`LES-`; `ls` it and read the ones for your area). Research: [[Video Research Index]].
  Research is evidence, not approval; a `proposed` LES isn't a rule until jg approves it.
- The vault is this repo, in numbered folders (`00 Studio` … `99 Templates`). **Do not edit:** `Agents/`, `Chats/`, `.obsidian/`.

## Luau architecture
- Luau `--!strict`, StyLua (tabs, 120), Selene (roblox), luau-lsp strict, Rojo 7.7.0 via Rokit. No frameworks, no new
  Wally packages or dependencies without asking.
- **Server-authoritative.** The server creates all remotes and timestamps everything. Validate every client value:
  type → range → ownership → rate limit.
- `server/Services/<Name>Service.luau` with idempotent `start()`. Tunables: frozen `shared/<Name>Config.luau`. Pure logic:
  `shared/<Name>Rules.luau` (no Instances) with `tests/<Name>Rules.spec.luau`.
- Debounce shared state before any yield. Cosmetics are pcall-isolated, fail inert, and always `warn`. `task.*` only.
- A changed remote payload updates sender, server handler and receiver together; list all three. Never edit scripts in Studio.

## Safety rules
- One scoped task at a time on `task/TASK-####-slug` (`chore/<slug>` for docs and tooling). Never commit to `main` or merge
  without human approval.
- Never publish, spend money or Robux, change a live experience, or make paid API calls without explicit approval.
- At most 2 revision attempts per task, then stop and report. Run `scripts/check.sh` before any AI review.
- Never read, print or store credentials (`.env`, keys).

## Git safety (LES-0006, 2026-10-11)
- Before any switch, merge, rebase, cherry-pick, reset, clean, commit, push or branch deletion, run
  `scripts/preflight.sh --root <checkout> --branch <expected>` and chain with `&&`. Use `git -C <checkout>`.
- The main checkout (`/Users/jg/Desktop/Rg1`) stays on `main`. Every task and chore branch gets its own worktree.
- Push a work branch once it has a commit (draft PR is fine).
- If the intended checkout is missing or stale, **stop** and re-discover it. Never fall back to the current directory.
- Never discard user edits, force-push, or delete untracked files without explicit authorization.

## Claude and Codex (since 2026-10-13)
- jg: direction, priorities, approvals, visual and audio judgement, merges, releases. Codex default: implementation,
  debugging, behaviour tests, security, tooling. Claude default: design and reference synthesis, assets, Studio iteration.
  jg assigns the owner per task.
- One implementation owner per task; the other reviews after check.sh and Studio tests pass (after a revision, only the
  changed code). One assistant uses Studio and Rojo at a time.
- Handoffs use `99 Templates/T - Handoff.md`. The other tool's notes are claims to verify, never approval.

## Session and delegation budget
Full detail: [[AI Context and Usage Workflow]] (`05 Engineering/AI Context and Usage Workflow.md`).
- One primary agent. No subagents for reads, simple edits, single checks or note upkeep.
- Tiers: **Light** (docs, notes, small tooling) on Sonnet low or Haiku medium; **Standard** on Sonnet; **Deep** and any
  security, networking or DataStore code on Opus. Set `/model` at session start. jg can override.
- Audits: Light relies on green check.sh; Standard gets one Sonnet audit; Deep and security/networking/DataStore get an
  Opus audit. At most one audit subagent per task. Brief it with checkout, diff range and 3–4 focus points; it returns
  verdict + findings + file:line.
- Read only the files in scope. No whole-repo scans. Console tail over screenshots. No `sleep` polling.
- When the pass condition is met, stop. No unrequested refactors or polish.
- New objective or context past ~150k: write a ≤20-line handoff in the task note and start a fresh session.

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
- Task status lives in `tasks/queue.json`; flag mismatches, don't guess. Keep notes short, no code dumps, no secrets.
  No new vaults or plugin changes without approval. Mark unverified conclusions as drafts.
- End of session: list notes created, updated or left pending, and why.
