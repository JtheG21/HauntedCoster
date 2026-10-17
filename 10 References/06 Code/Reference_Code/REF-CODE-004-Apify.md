---
id: REF-CODE-004
title: Apify — Research and Reference Gathering
type: reference
status: proposed
area: code
source: https://github.com/apify
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Reference_Code_Index]]"
tags:
  - reference/code
  - reference/automation
  - reference/research
  - reference/needs-experimentation
---
# Apify — Research and Reference Gathering

## Identity
- **Primary source:** https://github.com/apify — an organization containing multiple repositories, not one implementation.
- **Additional source supplied:** https://www.scraperapi.com/blog/apify-alternatives/#elementor-toc__heading-anchor-7
- **Purpose:** Explore web research, reference collection and repetitive-task automation that could give Claude stronger evidence for Roblox game production across projects.
- **Evaluation: needs experimentation.** No tools installed or executed, collection jobs run, or service connections created.

## Inspection and evidence
The Apify GitHub organization overview was inspected on 2026-10-16. It describes Actors for collection/automation, Crawlee crawling libraries, an MCP server and other developer tools. Individual repository source files, dependency requirements, licences, service terms and behavior have not been assessed. Organization-level descriptions do not prove suitability for a particular task.

The supplied ScraperAPI comparison article could not be retrieved: the web reader reported a page-size limit. Its comparisons, named alternatives and anchored section remain uninspected. Preserve it as a discovery lead, not evidence for choosing a provider. The article is hosted by a scraping vendor; check candidate capabilities against their own documentation when comparing.

## Intent — interview with jg, 2026-10-16
- Interests include collecting references, researching games, automating repetitive web tasks and giving Claude more context.
- Potential material includes documentation, tutorials, repositories, images, game listings and player feedback, selected by the task.
- Desired outputs combine searchable Obsidian notes, source lists, comparisons and asset shortlists as appropriate.
- Compare Apify and alternatives when a concrete collection job is identified; no broad provider comparison is required now.
- Mark needs experimentation. Start with one bounded research task and assess source accuracy, usefulness, effort saved and cost.

## Interpretation and implementation recommendations
- **Hypothesis:** Structured collection could reduce unsupported guesses and manual reference gathering when current tools cannot retrieve enough relevant material efficiently.
- **Recommendation:** Define the question, sources, limits and desired output before selecting an Actor, library or provider. Compare with existing browsing and research capabilities first.
- Preserve source URLs, access dates and evidence context; distinguish source observations, jg's preferences, inference and recommendations. More collected material is not automatically better evidence.
- Keep unverified results as research/captured references. Collection does not establish asset rights, factual correctness or approval to reuse code/assets.
- Reuse the vault's templates, indexes and resource catalog; do not create a second knowledge store. Update findings per tool and collection task.
- Interest in exploration does not approve paid calls, account connections, private-data transmission or changes to the current tool setup. A concrete experiment must fit the existing project gates.

## Experiment and evidence to add
For one bounded collection job record: question, selected sources and limits, candidates and primary documentation checked, exact tool/repository version, dependencies and costs, existing-method baseline, collected output and provenance, sampled accuracy/completeness, duplicates or unsupported claims, measured effort if available, and jg's judgment. Record failed retrievals and unresolved gaps. Choose useful, not useful in this context, or unresolved based on evidence.

## Open questions
- Which real collection task benefits beyond existing browsing?
- Which tool/provider fits that task's sources, output and cost?
- How much verification and cleanup is required before notes become useful?

## Traceability
- No implementation tasks or collected datasets yet.
- Next stage: identify a bounded research job, compare suitable options then, and record the experiment findings here.

## Review decision (2026-10-17)
- **Outcome:** keep as reference
- **Decided by:** jg
- **Summary:** Source inspected 2026-10-17: the Apify GitHub organization (270 public repos), the pricing page, the Store (search for Roblox), two repository READMEs and the ScraperAPI comparison article; nothing was signed up for, installed or run. Apify is open-source libraries plus a paid cloud platform. Crawlee (Node, 26k stars) and crawlee-python (Python 3.10+, 9.6k stars) are Apache-2.0 by GitHub's label (texts not read); the Apify MCP server is MIT with a hosted endpoint at mcp.apify.com; agent-skills has no licence. Three repositories (fingerprint-suite, impit, camoufox-js) exist to evade bot detection and are off limits under the rule against bypassing bot detection. The platform needs an account: Free is 0 USD with 5 USD of usage a month and no card, Starter 19 USD a month, Scale 199, Business 999; Actors bill per event or per usage; overage rates were not on the page read. The Store lists 22 Roblox-related Actors, mostly small (2 to 52 users) and pay-per-event, including one Roblox Email Scraper that should not be used. The ScraperAPI article is dated 2026-01-30, published by a competitor, readable only to the first of 11 alternatives, and its claim that Apify also starts at 49 USD contradicts Apify's pricing page (Free 0, Starter 19). A baseline probe with the built-in browser read ActorCore's free motion listing (first 16 items, category tree with counts such as 5,237 total motions, infinite scroll) without Apify; that listing says up to 10 free daily downloads after sign-up, relevant to REF-MISC-006. This session's other reviews paginated a 176-product listing and read minified page code with web fetch, gh api, the built-in browser and curl, so no collection job beyond existing tools has been identified. Kept as a reference. Revisit only for a job beyond those tools, using local Crawlee before any hosted Actor, never the evasion libraries, and no account or spend without jg. Rights ledger basis updated; class stays per-item.
- **Evidence inspected:** Review packet; org metadata and the 16 largest non-fork repositories with licence labels; pricing page; Store search for Roblox (22 results, pricing models); README excerpts for apify-mcp-server and crawlee-python; the ScraperAPI article (partial); ActorCore free listing in the built-in browser as a baseline probe; no sign-in, install, purchase or Actor run
- **Still unverified:** Licence texts (labels only); Apify platform terms and the Store Actors' terms; overage rates; whether any Roblox Actor's data collection is allowed by Roblox's terms (not checked); the rest of the ScraperAPI article and the other alternatives; Crawlee's robots.txt handling and behaviour when run; a full clean item list of the ActorCore free catalog
- **Next action:** none selected
