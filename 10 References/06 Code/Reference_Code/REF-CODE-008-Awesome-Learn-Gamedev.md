---
id: REF-CODE-008
title: Awesome Learn Gamedev — Research Directory
type: reference
status: proposed
area: code
source: https://github.com/dawdle-deer/awesome-learn-gamedev
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
related:
  - "[[Reference_Code_Index]]"
  - "[[REF-CODE-007-Expert-Informed-Briefs]]"
tags:
  - reference/code
  - reference/research
  - reference/needs-evaluation
---
# Awesome Learn Gamedev — Research Directory

## Identity
- **Source:** https://github.com/dawdle-deer/awesome-learn-gamedev
- **Purpose:** Discovery directory for Claude's research and the entire Roblox production workflow across projects. Its scope extends beyond code despite filing under the code reference index.
- **Evaluation:** Captured directory; evaluate each resource before relying on it. No linked course, book, repository or technique has been validated by this capture.

## Observations and evidence limits
Repository README inspected remotely on 2026-10-16; main branch, not pinned to a commit. Its sections include programming, technical art, rigging, VFX, illustration, 3D, animation, design, level design, UI/UX, audio, writing and production. It emphasizes craft and general knowledge and includes both free and paid resources. Individual links and their content were not inspected; availability, current prices and applicability are unverified.

The repository identifies CC0-1.0 licensing. That does not establish the licences or access terms of linked resources. The curator's recommendations and rankings are opinions, not project approvals or verified effectiveness. Some resources target other engines or older technology and require compatibility checks.

## Intent — interview with jg, 2026-10-16
- The whole collection, filling knowledge gaps, improving quality and discovering expert methods all interest jg.
- Primary audience: Claude's research and the broader production workflow, not a requested personal curriculum.
- Discover relevant resources when a task needs them and identify useful material during the later note-by-note review.
- **Free only.** Do not select paid courses/books or treat a limited paid-service trial as a default free solution. Confirm access conditions when choosing a resource.
- Capture as a research directory with evaluation per resource. Actual workflow changes remain deferred to the later review.

## Interpretation and possible application
- **Hypothesis:** A curated cross-discipline directory may help locate expertise when the workflow encounters uncertainty.
- **Recommendation for later review:** Pick a concrete question, locate a plausible free resource, open the actual source and assess authority, age, applicability and evidence. Do not infer that every item is useful because it appears in the directory.
- Compare with existing reference notes and [[Resource Catalog]] first. Record inspected findings in the relevant existing note or a focused new reference, preserving source provenance and avoiding duplicate summaries.
- Adapt general principles to Roblox and the game's architecture. Other-engine examples do not establish Luau or Roblox API behavior; verify those against the project's authoritative engine references.
- Free access does not grant unrestricted copying or asset redistribution. Respect per-resource terms and summarize rather than importing entire works.

## Future evaluation and evidence
During the later review or a relevant task, record the question, selected resource URL and access date, verified free access, actual sections inspected, useful principles, compatibility limits, proposed application and any validation performed. Distinguish researched guidance from implemented/tested results. Keep failures and obsolete or inaccessible resources visible rather than guessing their content.

## Open questions
- Which free resources add value beyond material already indexed?
- Which disciplines reveal the most useful gaps in the current workflow?
- Which recommendations remain accurate and relevant to Roblox?

## Traceability
- Capture only: no curriculum, course purchase, dependency or workflow change created.
- Next action: later review with jg; investigate individual free resources as concrete needs arise.

## Review decision (2026-10-17)
- **Outcome:** keep as reference
- **Decided by:** jg
- **Summary:** Review 2026-10-17 of a research directory, including an end-to-end run of the question-to-resource-to-card method. Source: dawdle-deer/awesome-learn-gamedev at commit 28e61535a7, created 2022-08-14, about 3.6k stars, last pushed 2026-06-01; the CC0 1.0 legal code was read and covers the list itself only. The README is 51 KB with 274 unique links across Programming (78 links), Art (39), Design (33), Technical Art (24), General (19), Job Hunting (17), Other (15), Audio (9), Marketing (7), Writing (6) and Production (5); it never mentions Roblox, so everything is general or tied to other engines. The README says nearly all resources are free and paid ones are clearly marked, but the marking is prose (44 lines mention free, 10 carry a price warning, one is free for non-commercial use only, one is a free trial), so a free-only filter must read each entry and free does not mean free for commercial use. Link health, checked once with read-only requests: 252 of 274 respond normally; 17 return a 4xx (many are bot-blocking on Udemy, ArtStation, Shadertoy, MIT Press and ACM, so unknown); two are confirmed 404 (a Flipped Normals hair tutorial and a personal site); 4 had network errors and 1 returned 503; about 92 percent reachable. End-to-end test on the question 'where can we learn VFX timing and layering for free to complement the Roqer methods': resource card 1, the realtimevfx.com Start Here thread, is public and free to read but dated 2018, points to Unreal 4 and Unity-era tools (Cascade, Shader Forge), does not cover timing in any depth, does not mention Roblox and states no reuse terms, so a weak fit; resource card 2, the BiteyCastle Academy 2dFX Animation Course on Gumroad, shows a price of 0 USD or more (pay what you like, zero allowed), software-agnostic, over 21 hours of video, 2.27 GB, hundreds of examples, 11,661 downloads and a 99 percent five-star rating from 302 ratings, covering the physics, timing and design of elemental effects (electricity, fire, smoke, water); the author's credentials are self-stated, the page states no reuse terms so it is personal study only, whether checkout needs an email or account is unverified, and it is 2D hand animation rather than Roblox implementation, so a strong conceptual fit but not an implementation guide. The directory's animation section offers nothing on sourcing mocap, so it did not help with the ActorCore question. Kept as a reference for on-demand use for one concrete question at a time; nothing downloaded or signed up for. Rights ledger basis updated; class stays per-item.
- **Evidence inspected:** Review packet; repository metadata, pinned tree and the CC0 licence text; the README structure, About, Key and the rigging, VFX and animation sections; counts of Roblox mentions, free and paid markers and links per section; a one-time read-only liveness check of all 274 unique links; the realtimevfx.com thread through the fetch tool; the BiteyCastle Gumroad page in the built-in browser; no download, sign-in or purchase
- **Still unverified:** The content and quality of every linked resource beyond the two cards; whether the BiteyCastle checkout requires an email or account; the 17 4xx links that may only be bot-blocking; how current the list stays (last pushed 2026-06-01); the author's credentials; whether the course content transfers to Roblox effects
- **Next action:** none selected
