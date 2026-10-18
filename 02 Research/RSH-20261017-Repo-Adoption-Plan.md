---
id: RSH-20261017-Repo-Adoption-Plan
title: Repo Adoption Plan
type: research
status: proposed
confidence: medium
created: 2026-10-17
updated: 2026-10-17
tags:
  - research
  - workflow/tooling
related:
  - "[[Resource Catalog]]"
  - "[[RSH-20261017-Agent-Reach-Integration]]"
  - "[[RSH-20261017-EasySpider-Integration]]"
  - "[[RSH-20261017-Public-APIs-Integration]]"
  - "[[RSH-20261017-Mods-Workflow-Efficiency-Handoff]]"
---
# Repo Adoption Plan

## Question
How do we turn the reviewed repositories into less effort and faster delivery without installing redundant tools?

## Sources
All accessed 2026-10-17 during the repository-review chat.
| Source | URL | Accessed |
|---|---|---|
| Anydoc README and selected source | https://github.com/firecrawl/anydoc | 2026-10-17 |
| Claudex Loop README, Route skill and runtime documentation | https://github.com/chaseai-yt/claudex-loop | 2026-10-17 |
| Claude of Tanks README, skill and license policy | https://github.com/Kevin-Liu-01/Claude-of-Tanks | 2026-10-17 |
| DeepSeek Harness README, package configuration and safety notice | https://github.com/deepseek-ai/deepseek-harness | 2026-10-17 |
| Strix README | https://github.com/usestrix/strix | 2026-10-17 |

## Observed mechanics (verified)
- Anydoc converts supported document formats to Markdown locally; optional hosted OCR uploads the whole document. MIT licensed. Selected source and package configuration inspected, not executed.
- Claudex Route can stand alone for recommendations or one bounded handoff. The full Loop adds plan review, revisions and final inspection. Documentation inspected; runner behavior not independently verified.
- Claude of Tanks documents reproducible scene capture and simulation/presentation separation. Its current license policy excludes vehicle/world code, media and several production guides from the default MIT grant. Runtime and capture code have not been verified.
- DeepSeek Harness explicitly describes itself as developer-preview software with breaking changes expected. Strix focuses on AI-driven application penetration testing. Neither fills a demonstrated current Roblox production gap.
- Decision: jg accepted the preceding recommendations and asked to move forward on 2026-10-17. Capture these as optional candidates; no blanket installation or replacement of project policy follows.

## Hypotheses
- Local document extraction and selective reading may reduce repeated parsing and context load.
- One bounded handoff may help a difficult task; adding routine review loops may consume more usage than they save.
- Repeatable camera/scene settings may make visual regressions easier to detect. These benefits remain unmeasured.

## Relevance to our game
Reuse the existing Sequence runner, Studio test pads, task queue and research tools. A repository is consulted when a current task exposes a specific gap, not added as a required stage.

## Original implementation ideas
| Trigger | Candidate | Minimum action |
|---|---|---|
| Incoming Office document or text PDF needs extraction | Anydoc | Compare local conversion with current extractor on that file; save reusable text and provenance |
| Existing tools fail on a relevant public source | Agent Reach | Trial just the needed channel; see its integration note |
| Repeated structured website collection | EasySpider | Compare one saved collection task with current method |
| Approved task needs external data | Public APIs | Discover candidates, verify selected provider separately |
| Difficult task needs a second perspective | Claudex Route ideas | One scoped handoff with relevant evidence; retain existing task records |
| Visual task needs consistent comparisons | Claude of Tanks ideas | Specify repeatable captures using existing Roblox tooling; inspect relevant implementation and licenses first |
| Coordination visibility becomes a demonstrated bottleneck | Claude mods | Follow efficiency handoff; prefer deterministic read-only state |

### First trial: Anydoc, when a real input arrives
1. Keep the original file and record its provenance. Use an isolated, pinned local package outside game dependencies; hosted OCR remains off.
2. Write a small expected-content checklist from the original: headings, a representative table, notes and equations when present.
3. Convert once and compare those items with the original and the existing extraction method. Record missing content; Markdown is not visual evidence or formula verification.
4. Read only task-relevant sections of the cached Markdown. Measure extraction time, required corrections and actual AI usage when available. Do not equate output size or time alone with token savings.
5. Adopt an optional extraction command only if it simplifies the real task. Otherwise keep the existing tools.

Preparation finding: a filename search under 02 Research and 10 References on 2026-10-17 found no docx, pptx, pdf or xlsx inputs. This does not establish that none exist elsewhere. No production document has been selected; no package installed and no conversion run.

### Defer
Strix and DeepSeek Harness: no adoption work until a concrete need justifies their overhead. FreeForDev: optional discovery bookmark only. Full Claudex Loop: do not make it a default workflow.

## Recommendations (max 3)
1. Use a real consuming task as the adoption trigger; avoid standalone infrastructure work without a gap.
2. Extract once, read selectively and link existing evidence. Prefer deterministic operations over unnecessary model calls.
3. Keep only demonstrated improvements. No new registry, orchestration system or automatic model loop is needed.

## Needs human review
- Runtime compatibility, accuracy and savings remain unverified for new tools.
- Proposed policy simplification stays in the separate mods handoff; existing approved rules apply until changed.

## Session handoff
Claude: start with the trigger table and existing integration notes. Continue current production work; trial a candidate only when it solves a present need. No installations, paid calls, policy changes or live-game changes performed in this review session.
