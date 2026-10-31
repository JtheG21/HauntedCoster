---
id: HANDOFF-0000
title: "{{title}}"
type: handoff
status: proposed
task_id: TASK-0000
receiver: claude-code
created: {{date:YYYY-MM-DD}}
updated: {{date:YYYY-MM-DD}}
---

*(How to use: [[Task Intake]], "Handoffs to another tool or session". For a task with `files_owned` in the queue, start from the matching file in `docs/workflow/templates/` instead; this template stays for short handoffs.
- **Size it to the task.** For a **light** task keep only Objective, Inputs, Constraints, Acceptance and Report, in 15 lines or fewer. For a **mechanic** add the State and Stages sections. For a **game stage**, add the approved scope and the release criteria.
- **Link, don't paste.** Paste text only when the receiver can't read the repo (Claude Design, chat), and then attach the images too.
- **Where it goes:** paste the filled prompt into the receiving tool, or save it in the task note under "Handoff". It is a prompt, not a vault note.)*

# Handoff: {{title}}

**Task:** TASK-0000. Objective in one sentence.
**Receiver:** Claude Code / Studio MCP session / jg in Studio / Blender / Claude Design. **Why this tool:** …
**Workspace:** `/Users/jg/Desktop/Rg1` (repo `JtheG21/HauntedCoster`), branch `task/TASK-0000-slug`, project `GAME-00N`, code root `games/<slug>/`.

## Start by
1. Read `AGENTS.md`, then `04 Agents/Task Intake.md`, then the workflow `04 Agents/Workflows/<Name> Workflow.md`.
2. Run `git status` on the branch above. Preserve unrelated changes, and run `scripts/preflight.sh` before any Git state change.
3. Read the inputs below and inspect the real files before changing anything.
4. **If a file, image, tool or permission listed here is unavailable, stop and report the blocker. Do not guess.**

## Inputs (repo-relative)
- **Spec:** `03 Games/…/06 Tasks/TASK-0000-….md`
- **References:** `10 References/…/REF-…md` (plus images: attached / at path)
- **Reuse:** `…` (from the Resource Catalog), with whether to reuse, adapt or replace it
- **Decisions already made:** ADR-…, or "jg, YYYY-MM-DD: …"

## Keep unchanged
-

## Constraints
- **Technical:** server authority, performance budget, Luau standards, …
- **Scope:** no publishing, no uploads, no live DataStore writes, no asset generation without approval.

## Plan / stages *(mechanic and larger)*
1.

## State and edge cases *(mechanic)*
-

## Acceptance criteria
- [ ] AC1, with how it will be proven (spec, scenario, screenshot, TEST note)

## Tests
- **Automated:** `scripts/check.sh`, plus …
- **Manual / Studio / Blender:** steps and the expected result
- **The receiver cannot verify:** … (say so in the report instead of claiming it)

## Open questions *(only ones that could block safe execution)*
-

## Report back with
Files changed, checks run and their output, what each acceptance criterion's evidence is, what is unverified, and the remaining work. Use these states: implemented and tested / implemented, not tested / planned / blocked / needs a manual check.
