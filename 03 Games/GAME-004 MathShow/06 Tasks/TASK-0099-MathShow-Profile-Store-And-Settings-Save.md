---
id: TASK-0099
title: "MathShow Profile Store And Settings Save"
type: task
project: GAME-004
status: in_progress
priority: medium
risk: high
owner: executor
depends_on:
  - TASK-0098
branch: task/TASK-0099-MathShow-Profile-Store-And-Settings-Save
related:
  - "[[GAME-004 MathShow/00 Overview]]"
  - "[[TASK-0098-MathShow-Menu-Shell]]"
created: 2026-10-26
updated: 2026-10-26
tags:
  - workflow/task
---

# MathShow Profile Store And Settings Save

## Goal
A server-authoritative player profile (DataStore) with settings save, loaded at join, so the menu shows real data and settings persist.

## Scope
- **In:** see the acceptance criteria; handoff `Game_spec_UI2elements.zip` (README, RULES_SPEC, ENGINEERING_NEEDS) and `MENU_TEXT_FIT_AUDIT.md` are the spec.
- **Out (non-goals):** work belonging to the other follow-up tasks; GAME-001..003.
- **Keep unchanged:** server authority (validate type, range, ownership, rate limit); the existing match flow unless this task says so.

## Intake
- **Category → workflow, depth:** UI + server, deep tier. Deep: Opus audit.
- **References:** `10 References/01 UI` (adapt, not copy); menu patterns from [[TASK-0098-MathShow-Menu-Shell]] (Shard, Fx, Preview, TextFit gate).
- **Decisions / assumptions:** ENGINEERING_NEEDS.md PROPOSED payloads. Open decision (default): profile key `MathShow_Profile_<userId>`, one DataStore, UpdateAsync.
- **Plan status:** proposed 2026-10-26 from the TASK-0098 follow-up list; jg asked for all follow-ups to be built (2026-10-26).

## Files expected to change
- `games/mathshow/src/{server,shared,client}`, `games/mathshow/tests`, this note, `tasks/queue.json`.

## Acceptance criteria
- [ ] AC1 Server `ProfileService` (idempotent start, pcall-isolated DataStore calls with retries and a session cache; never blocks the match loop) stores `{settings, bestRank, lastTestAt, blitzBest}` with a schema version; pure `ProfileRules` validates and migrates it with boundary specs.
- [ ] AC2 New remotes `MenuRequest` (client asks for its profile) and `SettingsSave` (client sends settings): server validates type, range, ownership and rate limit, ignores everything else, and debounces writes.
- [ ] AC3 Menu main card shows the real best rank, UNRANKED when none, and RANK UNAVAILABLE when the profile fails to load; settings load on join and save debounced; a DataStore failure warns and never blocks the menu or the match.
- [ ] AC4 check.sh green, MathShow specs rise; Studio run with a DataStore failure simulated; Opus audit (DataStore and remotes).

## Tests
- **Automated:** `scripts/check.sh` (baseline: MathShow 134 specs).
- **Studio playtest procedure:** `scripts/studio-preflight.sh --game mathshow`; fresh Play session; TextFit gate for new states; 2-client run where the task says so.

## Risks / notes
- Depends on the tasks listed above; do not start before they are done.

---
## Implementation record

## Audits

## Outcome
