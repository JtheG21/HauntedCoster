---
id: GAME-001-ROADMAP
title: Roadmap
type: roadmap
project: GAME-001
status: proposed
created: 2026-10-10
updated: 2026-10-10
tags:
  - game/roadmap
related:
  - "[[01 Game Design]]"
  - "[[EXP-0001-M2-Validation-Experiments]]"
---
# Roadmap: Rival Realms (GAME-001), **proposed**

> M0 and M1 are history. M2–M8 are a **proposal** awaiting approval. Later milestones are deliberately rough. They get detailed tasks only when the previous gate passes, and **any milestone can end in "rework" or "pivot"** if the evidence says so. Effort is a rough part-time estimate and hasn't been validated. **AI usage:** everything runs on the Claude subscription, with **$0 paid API** (`00 Studio/budget.json`). Per-task subscription use is logged with `record-usage` where it can be measured.

## Done
### M0: Foundation & technical validation ✅ 2026-10-10 ([[RETRO-M0-Workflow-Foundation]])
Workflow, checks, vault conventions, [[TASK-0001-Collectible-Pickup]]. Open: [[TEST-20261010-02]] (2-player test, manual).

### M1: Research & concept selection ✅ 2026-10-10
[[RSH-20261010-Candidate-Comparison]] → [[ADR-0002-Game-Direction]] → [[ADR-0003-Original-Factions-IP-Policy]] → [[01 Game Design]] v0.1 approved.

---

## M2: Core gameplay prototype (next)
- **Objective:** prove or disprove the riskiest assumptions R1–R4 in [[01 Game Design]] with the smallest build.
- **Deliverables:** 2 factions (Shinobi, Ki), 1 course (race → gate → race), Echo charges, a ring-out finale, a 30 s onboarding trial, telemetry, and a written experiment result.
- **Dependencies:** the [[EXP-0001-M2-Validation-Experiments]] plan approved, for the run at the end of M2.
- **Tasks:**

| Task | Title | Depends on | Risk |
|---|---|---|---|
| [[TASK-0002-Ability-Framework]] | Server-authoritative ability framework (spike) | none | medium |
| [[TASK-0003-Factions-And-Echo-Clone]] | Faction selection plus the Shinobi *Echo Clone* | 0002 | medium |
| [[TASK-0004-Ki-Burst]] | Ki Vanguard *Ki Burst*: breakable walls, pushable blocks | 0002 | medium |
| [[TASK-0005-Convergence-Gate]] | Convergence Gate plus Echo charges plus Echo Shrine fallback | 0003, 0004 | medium |
| [[TASK-0006-Match-Flow-And-Onboarding]] | Match flow (lobby → course → finale → results) plus 30 s trial | 0002 | low |
| [[TASK-0007-Ring-Out-Finale]] | Ring-out finale arena plus category results | 0003, 0004, 0006 | medium |
| [[TASK-0008-Prototype-Telemetry]] | Telemetry for EXP-0001 (first power time, gate waits) | 0006 | low |
| [[TASK-0009-Multi-Client-Test-Harness]] | Find a repeatable multi-client test method | none | low |

- **Acceptance criteria:** every task passes its audit; one full match runs with 2 and with 4 clients without errors; exploit probes are rejected; first power use is <60 s in an internal test.
- **Test evidence:** `scripts/check.sh`, Luau specs, `TEST-` notes for 2-client and 4-client sessions and 1 mobile device session, `AUD-` per task.
- **Risks:** shared physics and ability desync (the TASK-0002 spike is designed to surface this first); griefing at gates (fallback included); scope creep into 4 factions too early.
- **Rough effort:** 2–3 weeks part-time. AI: about 8 executor and 8 auditor sessions (subscription).
- **Approval gates:** each task plan (`approve`), each merge (`approve-merge`), then the EXP-0001 results.
- **Exit criteria:** EXP-0001 sessions A–E done with ≥6 testers, and a **go / rework / pivot** decision recorded as an ADR.

## M3: First playable vertical slice
- **Objective:** a complete, fair 4-faction match people would play again.
- **Deliverables:** Tide Corsairs (*Stretch Grab*) and Spirit Blades (*Flash Step*), 6–8 modular course sections picked at random, 2 gate types, finale polish, ping wheel, basic sound and VFX (primitive art), basic mobile controls.
- **Dependencies:** the M2 "go" decision.
- **Tasks:** planned after M2 (expected: 2 ability tasks, a module system, 4–6 section tasks, ping/emote, mobile controls, balance pass).
- **Acceptance criteria:** a 4-faction match is completed by 8 testers. No faction wins any category >50% of matches in internal tests (a rough balance check).
- **Test evidence:** playtests repeating EXP-0001 A–D; balance spreadsheet from telemetry.
- **Risks:** balance across 4 kits; the amount of content needed.
- **Rough effort:** 6–10 weeks. **Gate:** you approve the slice before any public exposure.
- **Exit criteria:** players ask for "one more match" (EXP-0001 C repeated) and there are no blocker bugs.

## M4: Retention, progression & economy validation
- **Objective:** a reason to return without manipulation.
- **Deliverables:** DataStore persistence (**ADR first**: schema, session locking, versioning), faction mastery XP plus cosmetic unlocks, Faction War board (weekly global totals: MessagingService/MemoryStore/OrderedDataStore, **ADR first**).
- **Acceptance criteria:** no data loss in forced-disconnect tests; Faction War totals match the sum of match logs.
- **Test evidence:** persistence test plan, `AUD-` with a security focus.
- **Risks:** data loss, DataStore limits. **Gate:** both ADRs approved before implementation.
- **Rough effort:** 3–5 weeks. **Exit:** a private or unlisted test (with your approval) shows D1 returners exist. Benchmarks will be set against Creator Analytics data, not invented here.

## M5: Content, polish & performance
- **Objective:** clear readability, a distinct look, and stable on mobile.
- **Deliverables:** original faction visual identity (in line with the IP policy), VFX and audio pass, thumbnail and icon, performance budget (server and client frame time, memory on low-end mobile), 10+ course sections.
- **Risks:** art capability (consider buying a small budget of assets, **only with your approval**).
- **Rough effort:** 4–6 weeks. **Gate:** you approve the visual identity. **Exit:** the performance budget is met on a low-end phone.

## M6: Monetization implementation & testing
- **Objective:** fair, cosmetic-only revenue.
- **Deliverables:** cosmetic shop (VFX colours, trails, emotes, banners), private servers, purchase-flow security (receipt handling, idempotent grants), profitability model (Phase 7: conservative, base and optimistic, with explicit assumptions).
- **Acceptance criteria:** the purchase grant is idempotent under retry; no paid item affects match outcomes (audited).
- **Gate:** **you approve every price and product.** No dark patterns. **Rough effort:** 2–3 weeks.

## M7: Controlled release & analytics
- **Objective:** real-player evidence at small scale.
- **Deliverables:** release checklist, `REL-0.1.0` note, analytics dashboard review (bounce, D1/D7, session length, play days), moderation and report flow, Experience Guidelines questionnaire.
- **Gate:** **publishing needs your explicit approval.** Ads need your separate approval and budget.
- **Exit:** 2–4 weeks of data plus a decision: scale, iterate or stop.

## M8: Post-launch iteration
Weekly update cadence (new sections, gates, arenas), Faction War seasons, a possible 5th original faction, retros per update. Continuing is decided on evidence, not momentum.
