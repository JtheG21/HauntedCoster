# AGENTS.md: operating rules for AI agents in this studio

This is the permanent instruction file. `CLAUDE.md` imports it. Role details live in `04 Agents/` (the only copy), naming and metadata in `00 Studio/Obsidian Conventions.md`, and the process in `04 Agents/Workflow.md`.

## Project map
- Game code: `src/server|shared|client` (Luau). Rojo (`default.project.json`) syncs it with `tests/luau` to Studio. **Only these reach the game.**
- Machine state, which is authoritative for task status: `tasks/queue.json`, `tasks/usage-ledger.jsonl`, `project-state.json`. Policy: `00 Studio/budget.json`.
- Tools: `scripts/check.sh` (all cheap checks), `scripts/orchestrator.py` (task gates), `scripts/validate_vault.py` (note conventions), `scripts/typecheck.sh`.
- The vault is this repo. Notes go in numbered folders (`00 Studio` … `99 Templates`). The current game is `03 Games/GAME-001 Rg1/`.
- **Do not edit:** `Agents/`, `Chats/` (the Smart Second Brain plugin), `.obsidian/` (plugin settings).

## Safety rules
- One scoped task at a time, on branch `task/TASK-####-slug`. Docs and tooling use `chore/<slug>`. Never commit straight to `main`, and never merge without human approval.
- The server is authoritative. Every client input is validated and rate-limited.
- Never publish, spend money or Robux, change a live experience, or make paid API calls without explicit human approval.
- At most 2 revision attempts per task. Then stop and report.
- Run `scripts/check.sh` before any AI review. Read only the files a task needs; don't scan the whole repo.
- Never read, print or store credentials (`.env`, keys) in code or notes.

## Obsidian knowledge management protocol
1. Before creating a note, search for its ID, title and related notes (`grep -rl "id: TASK-0001"`). Update the existing note instead of making a duplicate.
2. Use the folder structure, filename patterns, YAML schema and controlled statuses in `00 Studio/Obsidian Conventions.md`.
3. Create notes from the matching `99 Templates/T - *.md` and keep its required headings and metadata. When generating a note, write resolved values (real dates, titles), not template placeholders.
4. Update `updated:` whenever a note changes. Never fabricate dates, evidence, test results, sources or approvals.
5. Link tasks to their system notes, approved requirements, audits and related decisions, using `[[ID-Title]]` links, not paths.
6. In research, keep observations, hypotheses and recommendations apart. Keep source URLs and access dates.
7. Audits are new records (`AUD-…-NN`). Never delete earlier findings or turn a failed audit into a pass.
8. Record major architecture and design decisions as `ADR-` notes. Set `status: approved` only after explicit human approval, and record who approved it and when.
9. After each completed task, update the task note's Outcome, the game's `00 Overview`, the relevant `SYS-` notes, the architecture note, and (through the orchestrator) the project state.
10. After each milestone, write a short `RETRO-` note: progress, blockers, regressions, token use when known, and improvements.
11. Promote a lesson to `09 Knowledge/LES-` only with evidence, and link it to the original task, test or audit.
12. Keep notes short. Don't copy whole code files into notes. No secrets in the vault.
13. Use the existing vault and the plugins already installed. Don't create another vault, install plugins or change plugin settings without approval.
14. Mark generated conclusions that aren't verified as drafts, and list what needs human review.
15. Task status lives in `tasks/queue.json`, and the orchestrator mirrors it to the note. If the two disagree (`validate_vault.py` reports it), flag the mismatch; don't guess.
16. Never silently change approved design decisions or delete historical records.
17. At the end of each work session, summarize which notes were created, updated, or left pending, and why.
