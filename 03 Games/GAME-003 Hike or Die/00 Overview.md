---
id: GAME-003
title: Hike or Die Overview
type: overview
project: GAME-003
status: in_progress
created: 2026-10-18
updated: 2026-10-19
tags:
  - game/overview
---

# GAME-003: Hike or Die

**Phase:** Gate 1 existence prototype merged; the photographic risk/reward loop remains unproven. The project is a candidate and is not the studio's active game. The original brief is archived byte-for-byte in `08 Evidence/Hike_or_Die_GAME-003_Gate_1_Brief.original.md.source`; provenance is summarized in [[RSH-20261019-Hike-Or-Die-Preparation]]. Gate 1 is not a production or commercial greenlight.

**Code:** implemented as an isolated source root at games/hike-or-die/ with hike-or-die.project.json and a local Rojo build output, separate from default.project.json (GAME-001) and haunted.project.json (GAME-002). No published place is part of this task.

**Status:** An isolated existence prototype was merged in PR #120 (remote main `c85b279`) under [[TASK-0087-Hike-Or-Die-Gate-1]]. One rotating roam start and three spawn positions, plus local console event counts, are implemented; these are limited prototype variation/instrumentation, not cohort analytics. jg reports the camera still does not work; repair, physical touch evaluation and a successful full-loop test are deferred. This does not activate GAME-003 or authorize release. Task status remains in tasks/queue.json.

## Project profile
- **Status and phase:** Candidate; existence prototype merged in PR #120. Camera failure and incomplete full-loop validation are known follow-up work.
- **Player cap:** one player for the first prototype. Co-op is deferred to Gate 2.
- **Art direction:** handcrafted readable haunted trail blockout. [[REF-MAP-001-Dark-Fantasy-World]] and [[REF-MAP-002-Stylized-Swamp-Encounter]] guide atmosphere, layered depth, clear silhouettes, and readable route choices only; neither supplies assets or a final style decision.
- **Performance targets:** record a representative desktop baseline and evaluate touch. No numeric guarantee is set before measurement.
- **Validation:** direct game-specific format/lint/spec/map proof/Rojo build; repo-wide wiring is pending a separate chore; local-place Studio scenarios and device checks remain manual evidence.
- **Tools:** Rojo, Lune specs, Studio only against the dedicated GAME-003 place; no third-party asset import or paid API use in Gate 1.
- **Game-specific conventions:** no persistence, monetization, screenshots stored by the game, or client-authoritative rewards in Gate 1.

[[GAME-003 Hike or Die/01 Game Design]] · [[GAME-003 Hike or Die/02 Technical Architecture]] · [[GAME-003 Hike or Die/03 Roadmap]]

## Launch planning — 2026-10-19
The user requested an income-focused launch plan, aiming for next week with most development today, frequent subsequent updates, and a maximum $50 remaining cash reserve for necessary high-value tools. The target is conditional; the project is not launch-ready and this planning request does not activate production or approve release.

**Start here for subsequent GAME-003 work:**

- [[AUD-20261019-TASK-0087-04]] — current progress, source findings, verification and limitations.
- [[RSH-20261019-Hike-Or-Die-Launch-Spec]] — proposed release requirements and gates.
- [[RSH-20261019-Hike-Or-Die-Delivery-Plan]] — ordered work packages, GPT model/effort routing, calendar, tools and next-task handoff.
- [[RSH-20261019-Hike-Or-Die-Commercial-Plan]] — offers, income sensitivity, measurement and $50 reserve rules.

These plans are proposed. Package labels are not queued TASKs, completed features, spending approvals or a promised launch date. The queue remains authoritative.

## Preparation evidence — 2026-10-19
The original Gate 1 brief was recovered from `/Users/jg/Downloads/Hike_or_Die_GAME-003_Gate_1_Brief.md` and archived byte-for-byte under this game's `08 Evidence/`. Current rights, platform ownership/eligibility, and target devices remain unknown. See [[RSH-20261019-Hike-Or-Die-Preparation]] and [[RSH-20261019-Hike-Or-Die-Sol-Handoff]].
