---
id: RSH-20261019-Hike-Or-Die-Sol-Handoff
title: Hike or Die preparation and Sol handoff
type: research
project: GAME-003
status: research
sources:
  - "[[RSH-20261019-Hike-Or-Die-Preparation]]"
  - "[[RSH-20261019-Hike-Or-Die-Launch-Spec]]"
  - "[[RSH-20261019-Hike-Or-Die-Delivery-Plan]]"
created: 2026-10-19
updated: 2026-10-19
tags:
  - research/handoff
  - game/GAME-003
---
# Hike or Die preparation and Sol handoff

## Sol handoff — H01 tooling
**Objective:** wire isolated HOD checks and source/place synchronization without changing GAME-001/002 behavior.
**Inputs:** `scripts/check.sh`, `scripts/typecheck.sh`, `scripts/studio-preflight.sh`, shared project map/Studio Index, `hike-or-die.project.json`, `games/hike-or-die/`, audit F4, [[AUD-20261019-TASK-0087-04]], and [[RSH-20261019-Hike-Or-Die-Delivery-Plan]] H01.
**Present omissions:** audit confirms repo checks/typecheck omit HOD; Studio preflight assumes Haunted; no HOD CI gate or source-sync proof exists. HOD previously passed direct StyLua/Selene, six Lune cases, isolated Rojo build and map proof, but those do not run from shared checks. Generated map Luau uses `--!nocheck`; source analyzer omitted no diagnosis for source at audit time. Never pair the HOD project with either other place.
**Proposed files:** `scripts/check.sh`, `scripts/typecheck.sh`, `scripts/studio-preflight.sh`, the shared project map/Studio Index discovered by current code inspection, the relevant workflow tests, and CI config only if the existing CI pattern requires a narrow wiring edit. Do not modify HOD gameplay source for H01.
**Acceptance:** (1) check/typecheck/build map cover all intended HOD artifacts and preserve current GAME-001/002 behavior; (2) HOD preflight confirms exact HOD project/place/checkout and rejects Haunted/Rg1 mismatches without mutating Studio; (3) source-sync check verifies the checked-out source matches the HOD Rojo project; (4) injected formatting/lint/spec/map/build fault in HOD makes the shared check fail; (5) equivalent HOD Studio mismatch is rejected; (6) focused tests and `scripts/check.sh` pass; (7) report actual CI evidence and any manual Studio limits. No Studio/Rojo session mutation without the required matched session coordination.
**Receiver:** GPT-6 Sol, medium effort per delivery routing; implementation owner for H01 only. Create/approve a normal scoped task before implementation per Task Intake; this packet itself is not a queue entry.

## Stronger route required: H02 camera
H02 is not part of Luna implementation. Route as bounded root-cause debugging with the stronger model path specified by delivery plan (Astra high if available; otherwise Sol high with independent high-risk review). Begin from the current source and recorded user failure; audit F1/F2 are scoped leads, not a complete diagnosis. Reproduce on exact build, define mouse/touch aim-input contract, preserve server trust boundary/ADR-0015, fix only demonstrated causes, then prove sequential shots, state updates, cleanup and physical touch. No blind rewrite or claim based on historical injected rays.

## H06/H25 blank observer protocol
Use `Hike-Or-Die-Observer.csv` as one row per participant/run/attempt. Before formal sessions, record build hash, map/config version, device/OS, input, party size, source/cohort, familiarity, consent/eligibility code chosen by human, and observer. Do not store player identifiers, raw images, chat or unnecessary personal data. Keep fields blank until observed. Ask the objective/comprehension prompts before coaching; log exact paraphrase or `no answer`, coaching, time and exclusions. Record shot attempt/reject reason, quality explanation comprehension, chase/counterplay, extract/bank/loss and duration. Ask replay only after outcome; voluntary replay requires participant-initiated selection without prompt, and record their stated reason. Mark absent/staged instrumentation separately from verified source events. Five fresh users, four comprehension/photo and three voluntary replay are only the proposed directional G1 threshold in the spec; two real touch participants only if mobile is targeted. This sheet does not satisfy H06/H25.

## H05/H06 scenario checklist
- [ ] 1 player: baseline shot, second consecutive shot without camera reset, rejected shot, risky shot, cover escape, bank, restart, failure/loss and reset.
- [ ] 2 players: lobby/party entry, leader leave, disconnect at each phase, mixed outcome and safe solo return (co-op feature requires implementation first).
- [ ] 4 players: full encounter/performance/network profile; no extrapolation from 1–2 players.
- [ ] Devices: exact desktop keyboard/mouse; physical iOS and Android/touch only if those platforms are targeted; record device/OS/build and real-input behavior. Emulator is supplementary. Gamepad excluded unless selected.
- [ ] Failure matrix: empty extraction; death/exit race; chase blocked by cover; no-path fallback; catch after shutter; invalid/out-of-view/occluded shot; rapid shutter; restart overlap; disconnect/quit; missing asset/load; low FPS/background-resume; save/purchase failures only after those systems exist.
- [ ] For each row record expected behavior, actual raw behavior, outcome, reason, duration and evidence pointer; mark NOT RUN until executed. Scenario coverage does not itself establish fair human escape or user comprehension.

## H28 support/incident template and week-one triage
Copy `Hike-Or-Die-Incident.csv` once per report. Do not include passwords, payment details, player names/IDs, screenshots containing private information, or unneeded chat. Human chooses severity and support channel.
| Field | Entry |
|---|---|
| Incident ID / date-time / reporter-safe reference | |
| Build/version / device/OS / input / party size | |
| Symptom / expected vs actual | |
| Reproduction steps / frequency / evidence location | |
| Severity (S0 data/purchase/security; S1 core blocker; S2 major; S3 minor) | |
| Data loss / purchase risk / exploit / privacy risk | |
| Workaround / affected scope | |
| Owner / next check / status | |
| Escalation: stop sales? freeze update? rollback candidate? human decision/evidence | |
| Resolution build / verification / player-facing known issue text | |

Week one (Nov 2–8, conditional): each day capture build/device, save/purchase/error health, support count and severity, active blockers, rollback/sale-disable recommendation and owner. Route S0 immediately to jg for sale disable/rollback decision; S1 same-day triage; do not announce fix until exact-build verification. This template does not supply runtime telemetry, an authorized channel, an on-call owner, or release permission.

## Compact draft copy — not final/published
**TODAY'S SOLO PROTOTYPE — internal/test description:** “A solo prototype about photographing a cryptid on a short forest trail and trying to reach the marked exit. Camera controls and the complete round are still under test.”

**CONDITIONAL CO-OP LAUNCH COPY — use only after every advertised feature passes and jg approves:** “Explore a haunted trail with up to three friends, photograph two distinct cryptids, and bring your discoveries back from the expedition.” This is conditional; no co-op or two-cryptid feature is currently claimed as implemented.

- Objective: “Photograph the creature, then reach the marked exit.”
- Tutorial: “Raise your camera. Aim until the creature is clearly framed. Take a photo, then watch for its reaction.”
- Shot rejected: “No usable evidence: {reason}. Reframe and try again.” Use only a verified reason string; do not claim saved images.
- Banked: “Expedition complete. {count} evidence record(s) banked.”
- Lost: “Expedition ended before extraction. Carried evidence was not banked.”
- Pending save: “Your progress is still saving. Please wait before leaving.” Use only if a save system exists and reports pending.
- Pending purchase: “Purchase pending. Your item will appear after confirmation; do not buy again yet.” Use only with implemented receipt/status handling.

## Current asset / rights / permission inventory
The adjacent `Hike-Or-Die-Asset-Rights.csv` is a source-tree inventory. Existing map JSON/PNG and generated Luau are prototype source outputs, not final art. Source ownership and inspiration approval are separate: jg's approval of ADRs or reference direction does not establish ownership/licence for any imported asset. Current rights, upload permission and publishing permission are unknown for any future sourced asset. No art was generated, imported or commissioned here.

## H00 unresolved facts / further independent Luna work
- Factual: brief source was present in Downloads and copied verbatim; source/archive SHA-256 matches. Prototype/task state and approved ADRs clarified. Existing audit records remain unchanged.
- Unknown: Roblox owner/universe/place and eligibility, account security/roles, target audience/age disclosure, target devices, asset rights, tester access/recruitment, support channel and human-selected launch promise. These require jg or permitted read-only dashboard evidence.
- No additional independent Luna work remains from this bounded packet. H01 implementation belongs to Sol; H02 to the stronger debugging/review route; H06/H25 require actual future sessions and human participants; H07/H26/H29 require human decisions/approval.
- Queue acceptance text conflicts with revised TASK-0087 scope in the audit. Proposed correction for the next authorized queue edit: preserve TASK-0087 done/status/history and append a note that AC4/AC7 accepted existence-stage artifacts only, with camera, physical touch, repeatable full-loop/hook study, cohort telemetry and launch evidence explicitly deferred; never rewrite the original queue history or change status/approvals in this packet.
