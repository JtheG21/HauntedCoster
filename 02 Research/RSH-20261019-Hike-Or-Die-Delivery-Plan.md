---
id: RSH-20261019-Hike-Or-Die-Delivery-Plan
title: Hike or Die model-routed delivery and tool plan
type: research
project: GAME-003
status: proposed
confidence: medium
created: 2026-10-19
updated: 2026-10-19
tags:
  - research/production
related:
  - "[[RSH-20261019-Hike-Or-Die-Launch-Spec]]"
  - "[[RSH-20261019-Hike-Or-Die-Commercial-Plan]]"
---
# Hike or Die delivery and tool plan

## Question
How can the requested October 26–November 1 launch be attempted without wasting the subscription allowance or exceeding $50 remaining cash?

## Sources
| Source | URL / location | Accessed |
|---|---|---|
| Available model IDs and controls | Current Codex tool catalog; [official models guide](https://learn.chatgpt.com/docs/models) | 2026-10-19 |
| Shared usage / billing behavior | [official pricing and usage guide](https://learn.chatgpt.com/docs/pricing) | 2026-10-19 |
| Local rules and resources | [[Task Intake]], [[Workflow]], [[Resource Catalog]], `00 Studio/budget.json` | 2026-10-19 |
| Actual code and findings | [[AUD-20261019-TASK-0087-04]] | 2026-10-19 |

## Observed mechanics (verified)
The account tool reported Plus, 5% used of the five-hour window and 53% of the weekly window at audit start, with no credit balance. This is an account-wide snapshot, not this chat's consumption. Exact per-task token usage was unavailable. Current tool metadata lists `gpt-6.1-sol`, `gpt-6-luna`, and `gpt-6-astra`; a catalog listing does not guarantee account access at dispatch.

Official guidance favors Sol for complex repeated work, Luna for focused repeatable work and Astra for the hardest work. Higher effort costs more time/tokens. Standard speed conserves allowance; Fast currently consumes 2.5 times included usage. Usage also depends on context, tools and task complexity, so neither token counts nor message counts predict exact weekly consumption. Use the account usage tool to measure actual change. These facts do not promise a percentage saving from this plan. [Model guidance](https://learn.chatgpt.com/docs/models), [usage guidance](https://learn.chatgpt.com/docs/pricing).

## Hypotheses
**Recommendation, uncalibrated:** route deterministic upkeep to Luna, most implementation to Sol, and expensive failure-prone design/debugging to a narrowly scoped Astra session. Measure successful outputs per usage percentage and human rework before deciding this is cheaper. A cheaper failed attempt can cost more overall.

## Relevance to our game
jg explicitly requested GPT model assignments. The table is a GAME-003 routing proposal under that request, not an edit to shared Claude Sonnet/Opus policy. Keep all existing task, audit, security and human release gates. This documentation-only chore uses one primary agent; no subagents were run. Launch-package labels H00–H30 are stable planning references, not TASK IDs or approvals. Promote only the next approved slice to task notes and the orchestrator queue; machine state stays authoritative.

## Original implementation ideas
### Model routing
| Code | Model / effort / speed | Use and boundary |
|---|---|---|
| L | `gpt-6-luna`, high, Standard | Known-schema notes, inventory, copy and bounded data summaries. Never sole owner/reviewer of security, networking, data or receipts. |
| S | `gpt-6.1-sol`, medium, Standard | Scoped feature implementation, UI wiring, tests and routine tooling. |
| SH | `gpt-6.1-sol`, high, Standard | Stateful gameplay, integrations, performance diagnosis and adversarial fixes. |
| A | `gpt-6-astra`, high, Standard | Bounded camera root-cause work after previous failures, data/receipt architecture and hardest trust-boundary review. Use only if available; otherwise SH with independent high-risk review. No automatic API fallback. |
| J | jg / human testers | Device feel, fun, art/audio approval, cash purchases, account eligibility, merges and releases. Models can prepare evidence. |

Assignments below are judgment calls for this workload, not vendor benchmarks. Raise S to SH after a documented failing reproduction that requires deeper reasoning; escalate SH to A only for a specific unresolved cause. Do not use Max/Ultra by default. Stop after the repository's two revision attempts and report the smallest blocker; do not restart the same work under a new label to evade that limit. Camera repair must be a new task since TASK-0087 already used its revisions.

### Ordered work packages
Every package needs explicit owned files, acceptance evidence and a scoped task before implementation. Dependencies refer to H labels. Size is a planning envelope: XS = one small deliverable, S = one bounded work session, M = several implementation/test sessions, L = split into smaller TASKs before starting. They are not guaranteed hours or model-call counts. `J` means required human evidence, not an automatic delegation.

| ID | Deliverable / acceptance | Depends on | Owner / size | Tools / verification |
|---|---|---|---|---|
| H00 | Reconcile merged scope, recover original brief, current game/task status and platform ownership; record target devices and budget | — | L+J / XS | Git/queue/notes, read-only Dashboard; vault validator |
| H01 | Add HOD format/lint/type/spec/build/map/JSON to checks and CI; game-aware Studio preflight and source-sync verification | H00 | S / S | Shell, Rojo, Lune, Luau-LSP; injected HOD fault makes CI fail |
| H02 | Reproduce camera failure, agree input contract, repair transition/snapshot bug, mouse/touch yaw and camera cleanup | H00 | A+J / M | Minimal recorded repro, source, Studio MCP; no blind rewrite or repeated unsourced tweaks |
| H03 | Repeatable round/photo regression scenarios and human full-loop proof including restart audit fixes | H01,H02 | SH+J / M | Lune rules + Studio scenarios; 10 clean cycles and failure path |
| H04 | Fair chase/navigation/catch obstruction, usable cover and route readability | H02 | SH+J / M | Map prover, Studio walk/play, path-failure scenarios; actual escape proof |
| H05 | Real desktop/iOS/Android input matrix and first performance baseline | H03,H04 | S+J / M | Physical devices, Studio emulator as supplement, profiler; record exact device/build |
| H06 | Minimal funnel/event schema, observed hook study and replay decision | H03,H05 | S+L+J / S | Console export, test observer sheet; G1 counts and reasons; no retain/revenue claim |
| H07 | Approve launch content/art/rights list and reference brief; one production-quality specimen before batching | G1 | S+J / S | Reference skill, original assets, model baseline, rights ledger; approved scope |
| H08 | Co-op architecture and party/round state: roster, join/leave, late join, solo scaling | G1 | A / M | ADR, remotes/state diagrams, pure rules, independent review |
| H09 | Implement 1–4 player expedition, rescue/spectate, wipe/extract and party recovery | H08 | SH+J / L | Studio multi-client/manual 4-player sessions; fault scenarios |
| H10 | Evidence/payout invariants, anti-farming limits, round cap, replay-safe award identity | G1,H08 | SH / M | Pure rules, remote abuse scenarios; exactly-once progression grant |
| H11 | Journal, milestones, collection progress and next-goal presentation | H07,H10 | S / M | Config/rules/UI, unlock/duplicate/banked/lost tests |
| H12 | Durable profile/save/migration/concurrency/recovery foundation | H08,H10 | A / L | DataStore docs, fault harness, isolated authorized test universe; no production data |
| H13 | Approved sale/entitlement architecture and idempotent fulfillment | H12,H18 | A / M | Marketplace docs, receipt retry/concurrency/reconnect tests; one grant per purchase |
| H14 | First-time tutorial and camp/start/results navigation | H03,H11 | S+J / M | UI workflow, physical devices, fresh user observation |
| H15 | Second distinctive cryptid, three encounter variations and six contracts | H07,H09,H10 | SH+J / L | NPC reference inspection, config validation; all variants solvable, three runs novel |
| H16 | Final creature/world/camera/camp assets, rigs and animations | H07,H04 | S+J / L | Blender/approved asset workflow, baselines, import checks; no paid generation by default |
| H17 | Final HUD, journal/shop screens, reduced-motion/contrast/text/controls settings | H07,H11,H14 | S+J / M | UI references/Figma optional, Studio/device screenshots and input checks |
| H18 | Price/offer hypothesis and two direct cosmetic/supporter SKUs; free unlocks preserved | H06,H07 | S+J / S | Commercial plan, product preview and written benefits; approve SKU types before H13 |
| H19 | Shop UI, catalog IDs, ownership, equip and purchase feedback/recovery | H13,H17 | S / M | Dynamic price display, cancel/error/owned/rejoin tests; server grants only |
| H20 | Security and integrity hardening of final remotes, saves, extraction, rescue and sales | H09,H10,H12,H13,H19 | A / M | Bounded adversarial scenarios; independent high-risk review after checks |
| H21 | Production funnel/custom/economy analytics and cohort dashboard | H06,H10,H12,H19 | SH / M | Roblox AnalyticsService; verify events in authorized published test environment |
| H22 | Licensed soundscape and threat/feedback VFX, visual equivalents and accessibility | H07,H15,H16 | S+J / M | roblox-sfx, reference media, hearing/visual checks; pool/cleanup and mobile profile |
| H23 | Optimize against agreed frame/memory/load budgets at 4-player load | H09,H15,H16,H17,H22 | SH+J / M | MicroProfiler/Developer Console, physical devices, 30-minute soak/20 rounds |
| H24 | Release regression suite: data/receipt fault matrix, 1/2/4 players, network delay, every variant | H20,H21,H23 | SH+J / M | Exact commit/scenario logs, new TEST records; zero blocking defects |
| H25 | Fresh-player alpha study, balance/novelty fixes and mature cohort evaluation | H14,H15,H24 | S+L+J / M | Observations + Dashboard exports; separate acquisition source/device/cohort |
| H26 | Audience/maturity/rights eligibility and truthful icon/thumbs/trailer/store copy | H07,H16 | L+S+J / M | Current Roblox rules, original gameplay capture; human final checks |
| H27 | Staging/build flags, backup/rollback drill, release runbook and REL approval packet | H24,H26 | SH+J / M | Git/Rojo/Studio, approved publish flow; rollback without losing grants |
| H28 | Support/incident workflow, known issues and first week update queue | H24 | L+J / S | Repo issue template, triage sheet, owner escalation; no outbound messages without authorization |
| H29 | Limited release and organic acquisition experiment; 48-hour health review before wider reach | H25,H27,H28 | J+S / M | Creator Dashboard and approved publishing; no ad spend assumed |
| H30 | Following week's small content drops, retention/purchase experiments and net-income review | H29 | S+L+J / recurring manual work | H21 dashboard, cohort sheet, regression gates; staged releases only |

No scheduler, background autonomous dispatch, new chats or agent fan-out is authorized by this table. One implementation owner per task, one Studio/Rojo owner at a time. Standard/deep independent audits follow repository policy after cheap checks and relevant runtime evidence; at most one initial audit agent per task, delta review only for revisions. Unavailable required reviewer/model is reported, never replaced with a fake pass.

### Calendar and scope control
| Date (Pacific) | Intended result | Stop / fallback |
|---|---|---|
| Oct 19, today | This audit/spec; next authorized work should execute H00/H01 then H02–H04. Aim for one stable, demonstrably fun solo loop. | Do not spend the day fabricating dozens of assets while camera fails. “Most of the game today” is an aspiration with no measured throughput to support it. |
| Oct 20–21 | H05/H06; make G1 go/revise decision. In parallel only if separately authorized: human account/rights prep. | If framing/fair escape/replay still fail by Oct 21, next week becomes a controlled preview target, not a paid co-op launch. |
| Oct 22–25 | If G1 passes, H07–H24 in dependency order; concentrate on persistence/co-op and one polished asset pipeline. | These are multiple substantial sessions, potentially longer than the window. If G2 incomplete by Oct 25, reduce advertised scope with jg or move launch. No skipped data/purchase/device tests. |
| Oct 26–28 | Freeze release candidate, H24–H28; fix blocking issues, recruit fresh testers with human authorization. | Unsafe sales disabled; co-op claims require 4-player evidence. Account review delays move launch. |
| Oct 29–Nov 1 | Conditional limited launch, H29, monitor first 48 hours; retain rollback path. | If G3 fails, remain private/testing. No deadline-driven override of money/data reliability. |
| Nov 2–8 | H30: daily triage, two small planned content/quality releases if stable, one measured offer/retention experiment. | “Constant updates” means responsive support and frequent useful changes, not untested daily deployments. D7 matures only seven days after each cohort starts. |

### Usage and cash controls
- **Cash:** hard remaining cap $50 across the project, not $50/week. Default planned spend $0. Existing studio API limits are additional ceilings, not extra spending permission. No metered fallback, credits, ads or subscriptions purchased automatically.
- **Proposed weekly allocation:** 35% of remaining allowance core loop/co-op, 25% saves/security/sales, 20% integration/device work, 10% presentation/copy, 10% emergency reserve. If only G1 is approved, spend only its share and reassess. Percentages are planning envelopes, not enforceable per-task token budgets.
- Read usage before/after each substantial task; record account percentage change as a noisy observation (other chats share it), actual model/effort, revision count and achieved evidence. Never fabricate billed tokens from context size.
- At 80% weekly used, favor finishing an accepted slice and writing a compact handoff over starting L packages; preserve roughly 10% for critical diagnosis. If the allowance is exhausted, wait for reset or get explicit spending authorization. Do not lower safety review to fit a deadline.
- One narrow task packet: objective, owned files, exact reproduction, acceptance, current commit, tools and unresolved question. Reuse evidence; do not reread the entire vault or rerun unchanged test suites repeatedly. Run targeted checks during edits, full checks once before review and after material changes.
- No routine image/video generation, speculative plugin trials, large multi-model comparisons or repeated screenshot polling. Use existing tools and reference assets first. Tool purchase rule is in the commercial plan.

### Tools every working model should know
Availability below is **session-exposed or locally observed**, not proof that each integration is currently authenticated or suitable. Start with purpose-built APIs/CLI. Load only the relevant skill and tool schema. A higher model does not acquire extra permissions.

| Tool / skill | Productive use | Important boundary / fallback |
|---|---|---|
| `rg`, Git/gh, `apply_patch`, Python, repo scripts | Locate exact source, edit in task worktree, checks, queue and draft review artifacts | Guard every Git mutation with preflight; explicit checkout; no main edits, merge or unrelated cleanup |
| Rojo, StyLua, Selene, Lune, Luau-LSP | Reproducible HOD build and cheap tests | Until H01 is merged, run HOD commands explicitly; `check.sh` alone omits HOD |
| `studio-preflight` + Studio MCP `list_roblox_studios`, `get_studio_state`, `script_read`, `inspect_instance`, `execute_luau`, `screen_capture`, console/input/navigation tools | Read source/runtime state; matched local scenarios and visual evidence | Existing preflight assumes Haunted; use documented HOD equivalent until fixed. Verify exact place/project/checkout and changed Source (LES-0009). Never change another assistant's session. No touch injection proof; physical touch is human |
| `roblox-map` | Offline greybox plan/proof, route comparison | `~/.venvs/roblox-skills/bin/python`; never bootstrap protected existing places. Proof is not feel or chase validation |
| `reference-brief`, `refs.py`, `evidence.py`, `watch` | Inspect originals, pin evidence, define measurable visual criteria | Matching standards before substantial feature; keep references unchanged; summaries do not confer rights |
| `model-design`, local Blender, `art-import` | Concept approval, approved model/rig/export/import validation | Read model baseline/gallery; visual approval before batch work. Uploads require approval; Blender MCP not assumed |
| `roblox-sfx` and Studio asset search | Find compatible licensed audio; audition shortlist | jg hears/approves; asset ID existing is not licence/ownership verification |
| Figma tools/skills, UI/UX/accessibility skills | Optional reusable screen/layout or component specification | Read required Figma skills; verify connection; direct Studio UI is default when quicker. No duplicate design pipeline just because available |
| Local `~/Code/creator-docs`, web search | Engine API evidence and current Roblox/OpenAI policies | Local clone exists; check revision/current online docs for changing rules; only primary technical sources |
| Account usage tool, compact task notes, `orchestrator.py` | Track allowance, next task and exact handoff | Read usage only; do not create automation or message other chats without authorization |
| Imagegen / Meshy / Tripo / Higgsfield / Studio generation | Conditional concept or asset assistance if a measured bottleneck exists | Exposed capabilities, not approved spend. Check credits/charges/licence first; paid calls/uploads require explicit approval; prefer free local pipeline |
| Spreadsheet/document tools | Analyze exported cohorts or build a budget artifact if needed | Load workspace dependencies/skill; CSV + Python is adequate initially. No extra app installation required |

Do not use Sites, pet tools, unrelated plugins or web-app output as substitutes for the Roblox game. Never send Slack/email/invites/outreach without explicit permission. No credentials in prompts, notes or terminal output.

### Ready-to-use next task handoff
**Objective:** repair the GAME-003 camera and prove player-controlled photo→chase→extract→restart. **Receiver:** camera task implementation owner, A if available, otherwise SH. **Workspace:** discover an isolated task branch based on current remote main; do not reuse this documentation chore for game code. **Inputs:** audit F1/F2/F7, CameraClient, EvidenceService, RoundService, Gameplay, ADR-0015 and TEST-20261018-03. **Start:** Task Intake, inspect current source and matching references; create/approve the new task via normal gates. **Stage 1:** reproduce and record actual mouse/touch behavior and round-event reset. **Stage 2:** smallest fix preserving server aim bounds, clear transition versus snapshot handling. **Stage 3:** exact-build two consecutive photos without forced close, movement/aim, rejection, extraction/failure/restart and physical touch. **Acceptance:** H02/H03/H05 and R01; report any unverified device behavior. **Constraints:** no co-op/economy/art rewrite, publish, spend or change to GAME-002; at most two revisions. **Report:** commit, files, reproduction, checks, scenario evidence, remaining failures and usage snapshot. This packet is a dispatch template, not a claim that the task is already queued or running.

## Recommendations (max 3)
1. Use one short, high-quality camera debugging task first; let measured success set the pace for the week.
2. Keep model scope narrow and reusable tool instructions explicit; preserve high-risk review even when usage is low.
3. Treat the calendar as conditional; reduce optional breadth or release a truthful preview rather than spend the reserve on urgency.

## Needs human review
Production activation, launch scope and content counts, reviewer availability, cash purchase decisions and release approvals remain pending. All estimates are provisional; one complete production task is needed to calibrate throughput. No implementation, model setting, account configuration or automation changed in this documentation session.
