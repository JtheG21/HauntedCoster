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
Deep tier (DataStore + remotes). Baseline: check.sh green, MathShow 134 specs.

- **Shared (pure):** `ProfileRules` (defaults, lenient `sanitize` for stored data, strict `sanitizeSettings` for client data, `merge`: bests only go up, settings last writer wins, last test follows the newest start, `toClient`, `loadFailure`), `RateRules` (sliding window), `MenuConfig` additions, `Net` names and `MenuProfileReply` type. MathShow specs 134 -> 151.
- **Server:** `ProfileService` (one DataStore `MathShow_Profiles_v1`, key `p_<userId>`; GetAsync on load with retries, UpdateAsync that merges on save, debounced 2 s, autosave 60 s, saved on leave and `BindToClose`; modes saved / memory / readonly / loading); `Remotes` gains `MenuRequest` (RemoteFunction) and `SettingsSave` (RemoteEvent). API for later tasks: `ProfileService.get`, `.apply(player, patch)`, `.persistence`, `.waitLoaded`.
- **Deviations / decisions:** no session lock (merge-on-save instead); settings-save limit is 2 per 2 s, not 1 per s (client 1 s debounce plus jitter would drop the latest change); a Studio-only hook `workspace:SetAttribute("MathShowForceProfileFail", true)` simulates a load failure.
- **Client:** `Menu/init` requests the profile on open (pcall, never blocks), applies the server's settings unless the player already changed some, sends `SettingsSave` 1 s after the last change, and shows the real best rank, UNRANKED or RANK UNAVAILABLE.
- **Fix found in Studio (TASK-0098 regression):** the settings row's hit area (z 10) hid the stepper `+`/`-` buttons (z 5), so mouse and touch could not change volume. Squares are now z 15. A second Studio finding: in an unpublished place `GetDataStore` itself errors ("You must publish this place to the web"); the error text was lost, so the player never fell to memory mode. Fixed (`storeError`).

## Studio verification (Rojo from this worktree, fresh Play sessions)
- Unpublished place: `MenuRequest` replies `ok` with `persistence = "memory"`, the default settings and `modes = {group = true, blitz = false, vs = false}` in 0.06 s.
- Bad requests (`kind = "admin"`, an extra key, a string) reply `bad request`, and do not use a rate slot.
- `MenuRequest` limit 5 per 30 s: the sixth reply is `rate`.
- `SettingsSave`: a valid payload changes the server profile; `music = 99`, an extra `admin` key, `5.5`, a string and nil change nothing; a burst of three within 2 s keeps two (the third is dropped).
- UI end to end: two mouse clicks on MUSIC `+` change the UI 7 -> 9 and, after the debounce, the server profile (9).
- Simulated load failure (attribute set before join, cleared afterwards): the player card shows RANK UNAVAILABLE, `MenuRequest` replies `unavailable`, `SettingsSave` is ignored, and the match loop keeps running (Intermission -> Question).
- **Not verified:** a real published place with real DataStore reads and writes (Studio had no API access: memory mode only), so UpdateAsync merging, autosave and `BindToClose` are covered by pure specs and code review only; a 2-server race; real controller/touch.


## Audits

## Outcome
