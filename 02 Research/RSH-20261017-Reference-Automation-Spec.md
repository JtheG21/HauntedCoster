---
id: RSH-20261017-Reference-Automation-Spec
title: Reference Automation Spec
type: research
status: research
sources:
  - 00 Studio/Reference Review Index.md
  - 00 Studio/Resource Catalog.md
  - 04 Agents/Task Intake.md
  - 04 Agents/Workflows/Reference Analysis Workflow.md
  - 10 References/**/REF-*.md (all 19, read in full)
  - .claude/settings.json, .claude/hooks/guard.sh, scripts/check.sh, scripts/validate_vault.py, scripts/orchestrator.py
confidence: medium
created: 2026-10-17
updated: 2026-10-17
tags:
  - workflow/production
  - reference/review
---
# Reference automation spec

**Draft for jg's review. Nothing here is built, installed or approved.** Every item is a proposal. Approvals stay with jg ([[Reference Review Index]] says implementation waits for the one-by-one review).

## Question
Which automations can the project add around the 19 notes in [[Reference Review Index]], and how should the notes be used in day-to-day work so they save effort instead of adding reading?

## How this was produced
- **Read in full:** the Review Index, all 19 `REF-*` notes, [[Resource Catalog]], [[Task Intake]], [[Reference Analysis Workflow]], `.claude/settings.json`, `guard.sh`, `check.sh`, `validate_vault.py` (header), `orchestrator.py --help`, `T - Task` and `T - Reference`.
- **Checked on this Mac (2026-10-17):** ffmpeg and ffprobe, `gh`, `lune` and Python 3 are present. **Pillow, numpy and ImageMagick are not.** ffmpeg has `tile`, `hstack`, `xstack`, `select`, `scdet`, `mpdecimate`, `signalstats`, `palettegen`, `erosion`, `edgedetect`, `noise`, **but not `drawtext`** (so no burned-in timestamps). The creator-docs clone has `ParticleEmitter.FlipbookLayout`, `Highlight`, `EditableImage`, `SurfaceAppearance`, `UIGradient`, `UIStroke`, `Atmosphere`, `ColorCorrectionEffect`, `BloomEffect`.
- **Not done:** I did not open the archived videos or images, follow any source link, or run any tool. Statements about what the sources *are* come from the notes' own evidence, with their limits. Where a note says "unverified", this spec keeps it unverified.
- **Size:** the 19 notes are 86,919 bytes (about 22k tokens by a 4-chars-per-token estimate). Reading all of them for every task is the cost the "brief" tooling below is meant to avoid.

## Summary
1. **Build the plumbing first (Phase 0, one chore task, no new dependencies):** a reference lint, a `refs.py` CLI that prints a short *brief* per task, and a review-queue driver. Every later item uses these.
2. **Protect jg's approvals mechanically.** Add a diff check that flags edits to `## Intent — interview with jg` sections and any `status: approved` change. Autonomous maintenance (REF-MISC-002) then has a hard edge.
3. **Turn "minimum quality floor" into evidence.** Five approved visual notes (VFX-001, MAP-001, MAP-002, MISC-004, MISC-005) say "compare to the reference", but nothing produces the comparison. An ffmpeg-only frame, strip and side-by-side tool does, with no new installs.
4. **Record the "one prompt" expectation honestly.** Four notes carry it. A small ledger from existing task history shows what each attempt actually took.
5. **Gate tools, don't adopt them.** Roqer (AGPL, Windows target), RoPilot, Apify, Expo and Shaders each get a zero-cost first step (read, pin, map to what we have). Installs, accounts, downloads and recurring jobs stay behind jg.
6. **Reuse before building.** Most "automation" the tool references advertise already exists here in part: Studio MCP, scenarios, `studio-preflight`, Mixamo pipeline, Blender export, `roblox-map`, `auditor`. The spec names the actual gap for each.

## Findings from reading (verified, worth fixing regardless)
| # | Finding | Evidence | Suggested fix |
|---|---|---|---|
| F1 | The vault validator never looks at `10 References/`, so a typo in a REF note's `id`, `status` or embed is invisible. | `NOTE_DIRS = ^(0\d\|99) `; the Catalog's own Limits column says it "doesn't check frontmatter under `10 References/`" | X2 |
| F2 | The Review Index says publication "remains pending human-approved merge". The merge already happened. | Git log: `e31fad7 Merge pull request #67 … (approved by jg)`; the note is in the main checkout | Update the stale line when the queue is next edited |
| F3 | The Catalog row for the `watch` skill says "Not yet run on a real video". Seven notes record local `watch` extraction on real videos. | [[REF-VFX-001-Cinematic-Energy-Sequence]] and others ("Local watch extraction") | Update the row's state/evidence |
| F4 | No task machine-record links to a REF. `queue.json` has no references field. The `T - Task` Intake has a free-text **References:** line. | `tasks/queue.json` task schema; `99 Templates/T - Task.md` | Parse that line (X1 `trace`); do not add a schema field |
| F5 | Roqer is AGPL-3.0-or-later, yet the note's intent includes "adapt compatible recipes/code". | [[REF-CODE-001-Roqer]] | Methods-only rule until jg decides (X8) |
| F6 | Three notes say a thorough interview makes the result achievable "from one prompt"; [[REF-CODE-007-Expert-Informed-Briefs]] says briefs are the thing to strengthen. These are consistent only if the interview is counted as part of the cost. | VFX-001, MAP-001, MAP-002 vs CODE-007 | X7 ledger records interview length with the prompt count |
| F7 | Eight videos are on disk, matching the Index. Images were not recounted (133 image files exist under `10 References/`, of which the Index claims 25). | `find` on 2026-10-17 | X2 checks embeds resolve instead of trusting counts |

## Constraints every automation must obey
| Source | Constraint | Consequence for this spec |
|---|---|---|
| AGENTS.md | One owner per task; worktree per branch; `scripts/preflight.sh` before Git state changes; never commit to main | Each phase is a chore/task branch in its own worktree; this note is the only thing written in the main checkout |
| AGENTS.md / guard.sh | `10 References/` edits ask jg | Tools that write there are dry-run by default and run only when jg says so |
| REF-CODE-006 | No new agents, installs, scheduled jobs or delegation changes | Drift/watch jobs are manual commands first; a scheduler is listed as an optional decision |
| REF-MISC-006, REF-CODE-008 | Free only | Every ActorCore or directory resource card carries "free verified on DATE" |
| Prohibited list | No account creation, payments, or credential entry by an agent | Apify, RoPilot, Resource Boy and ActorCore accounts are jg-only |
| Permission rules | Downloads, uploads, form submissions need explicit approval each time | Pack, motion and texture steps stop at "ask jg" |
| Token economy memory | Skip unneeded tests, batch the rest, lean agents | Deterministic scripts do the counting; the model reads only a sheet or section |
| Codex parity | Skills have identical copies in `.agents/skills/`; Codex relies on the git pre-commit hook | New skills get both copies; lint also runs in `scripts/hooks/pre-commit` |
| Reference rules | Derived summaries must not overwrite jg's preferences | X9 and the Intent-section diff check |

## Part A: Using the notes efficiently in the workflow

### A1. Routing table (Task Intake classification to notes)
Open only the row's notes. The status column tells you how to treat the note.

| Task category ([[Task Intake]]) | Notes to pull | Treat as |
|---|---|---|
| Whole game / art direction | [[REF-MISC-004-Illustrated-Surreal-World]], [[REF-MAP-001-Dark-Fantasy-World]], [[REF-MAP-002-Stylized-Swamp-Encounter]] | Approved quality floors. Pick one style per game; do not blend |
| Environment and map | MAP-001, MAP-002, [[REF-MISC-005-Dark-Fantasy-Boss-Presentation]] (staging), MISC-004 | Floors. Interview first |
| 3D asset or prop | [[REF-MISC-003-Character-Sheet-Workflow]], [[REF-MISC-001-Anatomy]], MISC-005 (silhouette, scale) | Proposed process. Do not apply without jg selecting the experiment |
| VFX and animation | [[REF-VFX-001-Cinematic-Energy-Sequence]], [[REF-CODE-001-Roqer]], [[REF-CODE-003-Shaders]], [[REF-MISC-006-ActorCore-Free-Motions]] | VFX-001 is a floor; the rest are unproven techniques |
| UI and graphics | [[REF-UI-001-Throwie]], [[REF-UI-002-Resource-Boy]], MISC-004 (UI framing), CODE-003 | Proposed; experiment per treatment or pack |
| Systems / pipelines / tooling | [[REF-CODE-002-RoPilot]], [[REF-CODE-005-Expo-Skills]], [[REF-CODE-006-Orchestrated-Agent-Workflows]], [[REF-CODE-004-Apify]] | Method sources. Compare with existing tools first |
| Any task at Standard/Deep tier | [[REF-CODE-007-Expert-Informed-Briefs]], [[REF-MISC-002-Reference-Library-Approach]] | Governs how the brief is written |
| A knowledge gap with no match | [[REF-CODE-008-Awesome-Learn-Gamedev]] | Discovery only; evaluate each resource |

### A2. Reading protocol (cheap first)
1. Read **frontmatter + `## Intent` + `## Interpretation` + `## Open questions`** only. That is the decision-relevant 20-30% of each note.
2. Read **Observations/Inspection** only when you will claim something about the source.
3. Open **media** only for the specific beat or frame the task needs; extract with the frame tool (X6) rather than watching.
4. Never treat `approved` as "proven": an approved note records jg's preference. The `needs-experimentation` tag on an approved note is intentional (VFX-001 says so).

### A3. The reference block in every Standard/Deep task
Add to the TASK note's Intake, filled by the brief tool (X1) or by hand:
```
References: REF-VFX-001 (floor: layering, timing, camera), REF-CODE-007 (brief method)
Qualities taken: <3-5 bullets quoted from each note's Intent>
Not taken: <exclusions, rights limits>
Evidence plan: behavior -> spec; visuals -> matched-view sheet; motion -> frame strip; preference -> jg
```
This matches the existing **References:** line, so it needs no template change.

### A4. Close the loop (extends `task-close`)
When a task cites a REF: append a dated line to that note's Traceability (what was tried, result, effort), update the Catalog row's state/limits, record "floor met: yes / no / partly, by jg, date" in the task Outcome, and add a RETRO line if it changes the one-prompt picture (X7). All of that is append-only.

## Part B: Shared automations
Effort: S under a day, M one to three days, L longer. Gate: **G0** normal task and merge; **G1** jg asks (edits in `10 References/`, uploads); **G2** explicit approval (installs, accounts, downloads, recurring jobs, delegation).

| ID | Automation | Type | Effort | Gate | Builds on / replaces |
|---|---|---|---|---|---|
| X1 | `scripts/refs.py`: `brief`, `trace`, `rights`, `list` (stdlib only, no stored registry) | Script + tests | M | G0 | Parses frontmatter and headings on demand. Nineteen files, so no second store (REF-MISC-002) |
| X2 | Reference lint added to `validate_vault.py` (or `refs.py lint`): frontmatter, `id` equals filename, status vocabulary, `area` equals folder, embeds resolve, local-source path exists, Catalog and Index rows exist for every REF and vice versa, state mapping (note `proposed` to Catalog `captured`/`proposed`; `approved` to `approved`) | Validator rule | S | G0 | Fixes F1. Scope to `REF-*.md` so older `referenceN` notes stay untouched |
| X3 | Review-queue driver: `refs.py review-next` prints a packet for the next unchecked item; `refs.py decide REF-ID --outcome …` appends a dated `## Review decision` section, ticks the Index box, updates the Catalog row. Dry-run by default | Script | M | G1 per run | Automates steps 3-4 of the Index's "How to review one item", append-only |
| X3s | Skill `/reference-review [REF-ID]`: walks jg through one note: packet, opens the real source, asks the decision as one batch, then calls `decide` | Skill (+ `.agents` copy) | S | G0 | Claude-owned by default (AGENTS "Claude and Codex") |
| X4 | Skill `reference-brief`: for a task, selects notes (A1), emits the interview as one batched question set (from each note's own "interview for…" list), an expert-lens pass, an evidence plan and acceptance criteria citing REF IDs | Skill | M | G0 | Operationalizes REF-CODE-007 and the "interview first" method in memory (`pipeline-builder`) |
| X5 | `refs.py pin` and `refs.py drift`: record source commit SHA, licence SPDX and date in an append-only `tasks/reference-pins.jsonl`; compare to current `HEAD`; HEAD-check links | Script (`gh api`, read-only) | M | G0 (read-only); scheduled run is G2 | Closes "main branch, not pinned" in eight notes. Mirrors `usage-ledger.jsonl` |
| X6 | Evidence tooling on ffmpeg only: `frames` (dense extraction), `strip` (tile contact sheets, index printed in tile order since no `drawtext`), `sheet` (reference and render side by side), `beats` (scene-change timestamps with `scdet`/`select`), `stats` (luminance, clipped-highlight %, dominant palette with `signalstats`/`palettegen`) | Script | M | G0 | Output to the session scratchpad, never the vault. Fold into `games/haunted/art/tools/review.sh` if it exists by then rather than duplicating |
| X7 | One-prompt ledger: for tasks that cite the four "easily achievable" notes, tabulate interview length, prompts, revisions (queue history), elapsed time and tokens (`usage-ledger.jsonl`), plus jg's floor verdict | Script reading existing state | S | G0 | Gives the "assess honestly from observed results" lines in VFX-001, MAP-001, MAP-002 a data source |
| X8 | Rights ledger: `refs.py rights` classes each note: permissive-verified / permissive-claimed / copyleft / platform-terms / per-item / unknown / reference-only. Adaptation gate: no code or asset adaptation from `copyleft`, `unknown`, or `reference-only` without jg's recorded decision | Script + rule text | S | G0 | Needed by F5 and every "rights unverified" line |
| X9 | Connection pass: deterministic part (`refs.py graph`: orphans, shared tags, REF notes never cited by a task) plus a model pass that writes an `RSH-…-Reference-Connections` note with evidence-backed links, possible uses and contradictions. Never edits Intent or approvals | Script + manual session | S | G0 | Delivers what REF-MISC-002 asked for without a service |
| X10 | Hooks: PostToolUse on `Edit\|Write` of `REF-*.md` or the Index runs the lint on that file (warn, never block); `orchestrator.py start TASK-####` prints the brief; `scripts/hooks/pre-commit` runs lint and the **preference-immutability diff** (flags changed `## Intent` sections and `status:` moving to `approved` without jg's name in the commit trailer or an `approved_by` line) | Hooks + tests in `tests/test_claude_hooks.py` | M | G0 | Same shape as `luau-format.sh`; guard's ask on `10 References/` stays |
| X11 | Context test pads for Studio: three small scenarios (`games/haunted/tests/scenarios/`): **UI pad** (an image at 48, 128, 512 px on dark and light), **VFX pad** (emitter with a given texture at 3 distances, leak and particle-count check), **surface pad** (a texture on a wall under the game's Lighting). Each captures with `screen_capture` and prints a metrics line | Scenario scripts | M | G0 to build; G1 per texture upload | Reused by Throwie, Resource Boy, Shaders, Roqer, Illustrated-world. Run after `studio-preflight`; remember LES-0005 (fresh Play session) |
| X12 | `refs.py new`: scaffold from `T - Reference` with the next free `REF-<AREA>-NNN`, an area-index row and a Catalog draft row, then lint | Script | S | G0 | Step 2 and 8 of [[Reference Analysis Workflow]] |

Each script gets a `unittest` in `tests/` and a line in `scripts/check.sh`. Python stays standard-library only, like the existing tools.

## Part C: Note by note
Each section: **Offers** (what the note actually supports), **Enters the workflow at**, **Automations**, **First experiment**, **Blocked or not to automate**, **Decision for jg**.

### 1. REF-UI-001 Throwie (image effects for text and graphics)
- **Offers:** a web image-effects tool (metallic, halftone, grain, sketch, erosion and more by label). jg likes distressed, eerie, hand-drawn treatments. Export format, transparency, font handling and rights are all unverified.
- **Enters at:** [[UI Workflow]] when a logo, menu title, button, sign or thumbnail needs a treatment.
- **Automations:**
  - **TH-1 Treatment matrix (X6):** from one source text artwork and N exported treatments, build one sheet with each treatment at three real display sizes, so legibility is judged at size, not on a large preview. Store a JSON sidecar of effect names and settings, since the note requires reproducibility.
  - **TH-2 Readability pad (X11):** after jg approves one upload, render the winning treatment on the UI pad in Studio at mobile and desktop sizes.
  - **TH-3 Local fallback, conditional:** if jg's favorites turn out to be grain, erosion or edge/sketch, test whether ffmpeg's `noise`, `erosion` and `edgedetect` reproduce them scriptably. If not, drop it. Not worth building before the experiment.
- **First experiment:** one text artwork, 3-4 treatments in the distressed/eerie/hand-drawn range, judged by jg at size. Use GAME-002 title text if a logo task exists; otherwise a neutral string.
- **Blocked or not to automate:** driving the web UI needs a browser session; saving each export is a download that needs jg's yes. Font and output rights stay a manual check recorded in the TASK.
- **Decision for jg:** which of the treatments, if any, count as "liked", and may the matrix use a neutral test string?

### 2. REF-UI-002 Resource Boy Exclusives (fonts, brushes, textures, overlays)
- **Offers:** a broad listing of fonts, doodles, Photoshop brushes, gradients, textures, overlays and text effects. Nothing was downloaded; terms and formats are per pack. jg wants use directly, modify and combine, and inspiration.
- **Enters at:** [[UI Workflow]], [[VFX Workflow]] (textures) and the texture side of [[Asset Workflow]].
- **Automations:**
  - **RB-1 Pack intake record (X1/X12-style):** a one-screen checklist generated per pack: URL and date, licence evidence, formats, tools required (Photoshop-only items are unusable without it; whether jg has Photoshop is unknown, so ask), intended use, effort. The pack is only "useful" once the record is complete.
  - **RB-2 Texture-in-context tests:** VFX-candidate textures go through the VFX pad (X11); surface textures through the surface pad. The note says a preview image is not evidence.
  - **RB-3 Rights ledger (X8):** each pack is classed by its own terms. A site-wide verdict is never recorded.
- **First experiment:** one pack in a category jg already named (fog textures, grunge, or a lens flare), through intake, one Studio test, one verdict.
- **Blocked:** the note asks for no purchases, uploads or accounts. Whether any "exclusive" is paid is unknown, and the note invents no cost policy, so this spec does not either.
- **Decision for jg:** is a free-only filter wanted here too? (Only ActorCore and the directory carry one today.)

### 3. REF-MISC-001 Anatomy (structural planning skill)
- **Offers:** a planning method: parts list first, deliberate placement, close-up inspection, plus claimed geometry checks (supports, connections, intersections). Not installed; MIT declared, full text not inspected; output is SVG/WebGL, not a Roblox mesh.
- **Enters at:** [[Asset Workflow]], between the reference sheet and the model build, when the object's construction is unclear.
- **Automations:**
  - **AN-1 Model contract (shared with CS-1):** one artifact per asset made of the visual sheet (REF-MISC-003) and a *parts graph* (parts, parent attachment, proportion ratios, degrees of freedom, source references). One contract, not two workflows.
  - **AN-2 Structure check on the output, not the diagram:** a Blender-headless script next to `scripts/blender/export_for_roblox.py` reads the parts graph and checks that every part touches or overlaps its parent, none float, and bounding-box ratios sit within the stated tolerance. It validates the model against the plan, so a wrong plan passes. The note's warning about unverified explanations applies; real references still decide.
  - **AN-3 Method adaptation:** write our own planning prompt from the inspected `SKILL.md` at a pinned commit (X5). Paraphrase; do not import its fixed detail counts or mandates.
- **First experiment:** one structurally confusing object when a real model task arises, a baseline run versus a parts-first run, one revision each, compared on a side-by-side sheet (X6). Record the extra effort.
- **Not to automate:** whether the object is mechanically right. That needs real references and jg.
- **Decision for jg:** is the parts graph worth its overhead for every Standard asset, or only for objects jg flags as confusing?

### 4. REF-CODE-001 Roqer (Roblox production agent: animation and VFX skill)
- **Offers:** methods for character and creature animation, VFX design (purpose, palette, contrast, layering, timing), flipbooks, explosions, and reference-clip comparison; playback lifecycle, cleanup, performance. Only the README, LICENSE, one skill and two reference files (partly) were inspected. **AGPL-3.0-or-later; Windows is the setup target, macOS untested.**
- **Enters at:** [[VFX Workflow]] and animation work. Compare with [[vfx_template]] and the Mixamo pipeline first.
- **Automations:**
  - **RQ-1 Pin and rights (X5, X8):** record the commit and licence. Rule: **methods only, no code copied** until jg decides on AGPL.
  - **RQ-2 Technique cards:** distil each reusable technique in our own words into a guide note beside the `vfx_template` guide (the Code Index already has one guide per repo). One card per technique, with a "needs verification" line from the note's own list.
  - **RQ-3 Effect lifecycle check (X11):** a reusable scenario assertion: after an effect finishes, the descendant count and connection count return to baseline, and the peak particle count stays inside a budget. Roqer's emphasis on cleanup is a project need whether or not the repo is used.
  - **RQ-4 Reference-clip comparison:** the `reference_clip` / `capture_moments` ideas map to our own X6 `beats` and `strip` (same timestamps from the reference and the render). Roqer's actual calls are not established tools here and are not reimplemented from its code.
- **First experiment:** one technique (for example layered VFX timing) applied to one ability effect, with the `vfx_template` result as baseline.
- **Blocked:** installing the Roqer agent (Windows target, AGPL, MCP overlap with Studio MCP). Not proposed.
- **Decision for jg:** AGPL position: methods only, or evaluate code reuse with a lawyerly check later?

### 5. REF-CODE-002 RoPilot (workflow automation product)
- **Offers:** vendor claims of a connected loop: read the game, change it, test with simulated input, capture screenshots, repair and retest; plus rendered item icons. Homepage only; demos not watched; jg is interested in the *workflow*, not the showcase visuals.
- **Enters at:** [[Systems Workflow]] and [[Workflow]] gates.
- **Automations:**
  - **RP-1 Gap map (no spend):** a table of each claimed capability against what exists here. From the repo and tools: scripting and UI (Claude + Rojo) have; Blender modeling (headless export) partial, rigs and animation untested; Studio import (`art-import`) have; playtest input and screenshots (Studio MCP, `Multi-Client Testing`) have; repair-and-retest (manual, capped at 2 revisions) partial; item icons (bake in `review.sh`, arriving) partial. The actual gaps then name themselves.
  - **RP-2 TEST-note drafter:** the most likely true gap is *evidence capture after a scenario*. A skill that, after a Studio run, saves console output (`get_console_output`), screenshots and the pass/fail summary into a draft `TEST-` note from `T - Playtest`. Builds on `studio-preflight`.
  - **RP-3 Demo review:** run the `watch` skill on the linked demos with a frame cap, and record what is shown versus claimed. Free and read-only.
- **First experiment:** RP-1, then RP-2 if the drafter is the top gap. A product trial only if jg asks (account, possible cost, Studio permissions all gated).
- **Not to automate:** judging output quality from a showcase.
- **Decision for jg:** is RP-2 the right first gap, or is another bottleneck costing more?

### 6. REF-CODE-003 Shaders (WebGPU effects library)
- **Offers:** layered procedural effects (gradients, noise, glass, glow, distortion, particles, transitions) with ordered layers, blending, masks and animated parameters. Browser WebGPU, not Luau. MIT for the package; the platform editor and presets have separate terms.
- **Enters at:** [[VFX Workflow]], [[UI Workflow]], surfaces and transitions.
- **Automations:**
  - **SH-1 Effect dissection card:** for one effect record layers, blend, masks, parameters, palette and timing, then map each to Roblox primitives: `UIGradient`, `UIStroke`, `ParticleEmitter` with `FlipbookLayout`, `Beam`, `Trail`, `SurfaceAppearance`, `Atmosphere`, `ColorCorrectionEffect`, `BloomEffect`, and `EditableImage` for runtime procedural textures. These classes exist in the local creator-docs; whether each can reproduce a given effect is untested.
  - **SH-2 Recreate versus bake decision:** try the cheapest native recreation first (for example an animated `UIGradient`), then a baked flipbook only if needed. Rule from the note: choose the simplest method that meets quality and performance.
  - **SH-3 Bake pipeline (experimental):** drive the effect in the built-in browser, capture a seamless loop of frames, tile with ffmpeg into a flipbook sheet. Unverified: WebGPU in the in-app browser, alpha capture, loop seams, export rights.
  - **SH-4 Perf record (X11):** every baked or recreated effect goes through the VFX pad and logs particle count and frame time.
- **First experiment:** one effect (glow or noise gradient) recreated natively and baked, compared at matched views.
- **Blocked:** installing packages or using platform presets without a terms check.
- **Decision for jg:** is the bake route worth exploring at all, given native recreation may be enough?

### 7. REF-CODE-004 Apify and alternatives (research and collection)
- **Offers:** an organization with Actors, Crawlee, an MCP server and tools. Only the org overview was read. The ScraperAPI comparison article could not be retrieved, and its vendor is a competitor, so it is a lead, not evidence.
- **Enters at:** [[Reference Analysis Workflow]] and research tasks (`02 Research`).
- **Automations:**
  - **AP-1 Research-job spec:** a short template: question, sources, limits, output format, cost cap (default **$0**), sample-check size, and a baseline run with tools we already have (`WebSearch`, `WebFetch`, `gh api`, `watch`, the browsers). The note requires comparing with existing browsing first.
  - **AP-2 Provenance fields:** every collected row carries URL and access date; sample 10% for accuracy, record duplicates and unsupported claims.
  - **AP-3 Cost recording:** log any spend or quota with `orchestrator.py record-usage`.
- **First experiment:** one bounded job. Best fit with other notes: build a structured list of the *free* ActorCore motion catalog (name, tags, duration, format) to feed REF-MISC-006. Compare plain Python fetching with Crawlee (local, free) before any hosted Actor.
- **Blocked:** accounts, hosted Actors, the Apify MCP server, private data, anything paid. All G2 and jg-only.
- **Decision for jg:** is the ActorCore catalog list a good first job, or is another collection need more pressing?

### 8. REF-CODE-005 Expo Skills (agent knowledge and workflow collection)
- **Offers:** how a mature skills collection is organized: focused skills, separation of framework guidance, services and experimental material, evaluations, and open PRs as research leads. Expo/React Native APIs do not transfer. README and PR list only; MIT per README.
- **Enters at:** [[Systems Workflow]] (our own `.claude/skills/` and `.agents/skills/`).
- **Automations:**
  - **EX-1 Skill audit of our own skills:** a lint for each `SKILL.md`: frontmatter present, description names triggers, size reasonable, references split out, `.agents` copy identical (the test exists), no dead links. Cheap, and it measures our skills, not theirs.
  - **EX-2 PR mining:** `gh pr list -R expo/skills` then read 3-5 diffs that concern failures or evals. Output: candidate lessons as `proposed` LES notes only, with the PR and revision cited. Read-only.
  - **EX-3 Eval cases, offline:** write expected-behavior prompts for our own skills as documents. Running them against a model costs API budget and stays gated.
  - **Dashboards:** an Expo app is not needed for a status view; an HTML Artifact over `orchestrator.py status` and `refs.py list` does it without a new stack (my inference, not verified against any requirement jg stated).
- **First experiment:** EX-1 on `art-import` and `studio-preflight`.
- **Blocked:** adding Expo dependencies; any telemetry or feedback transmission the upstream instructions mention.
- **Decision for jg:** is skill hygiene (EX-1) worth doing before any new skills are added?

### 9. REF-MISC-002 Reference Library Approach (approved)
- **Offers:** the organizing principle: source to curated notes to task output; summaries, links, possible uses and contradiction flags maintained by the model, with jg's preferences and approvals kept distinct. jg said no further investigation is needed.
- **Mapping to this vault:** raw = `10 References/**/Media` and archived originals; wiki = REF notes, area indexes, [[Resource Catalog]]; master index = [[Reference Review Index]]; output = TASK notes and briefs.
- **Automations:** this note is the license for **X1, X2, X9, X10, X12**.
  - **LB-1 Retrieval stays grep-plus-brief.** No vector store. Revisit if the REF count passes about 100 or the briefs miss relevant notes (a threshold for jg to confirm).
  - **LB-2 Labelled maintained summaries:** the model may add a `### Maintained summary (DATE)` block listing what was inspected and what is unverified. It never edits the Intent, Identity or approval lines (enforced by X10).
  - **LB-3 Contradiction log:** F5 and F6 above are the first entries.
- **Decision for jg:** confirm the retrieval threshold and the maintained-summary block format.

### 10. REF-VFX-001 Cinematic Energy Sequence (approved quality floor)
- **Offers:** a 25.2 s clip, eight sampled frames, no motion review. jg likes the whole sequence (layering, timing, camera, transformation, ability VFX) and expects it achievable from one prompt after a thorough interview. Rights and author unverified; reference only.
- **Enters at:** [[VFX Workflow]]; cutscenes; ability presentation.
- **Automations:**
  - **VF-1 Dense beat list:** `beats` finds cut and change points; `frames` at 4 fps over 25 s gives about 100 frames; `strip` packs them into ~5 sheets. A session reads the sheets and appends a timestamped beat list (G1, edits the note). The note itself says sparse sampling cannot support choreography claims.
  - **VF-2 Interview module (X4):** subject and action, emotional beats, phase order and duration, camera behavior, palette, scale, player control, gameplay context, performance target. These are the note's own list.
  - **VF-3 Paired motion check:** jg records one screen take of the render (macOS screen recording; recording is jg's action). `frames` extracts the same beat timestamps from both, `sheet` pairs them. The note says playback alone does not meet the floor.
  - **VF-4 Lifecycle and budget (RQ-3, X11):** cleanup and particle budget on every run.
  - **VF-5 Candidate shared module (needs a TASK and ADR-0009 treatment):** a data-driven sequence runner (camera keys, effect cues, cleanup) with pure ordering and cleanup rules tested in Lune ([[ADR-0008-Headless-Specs-With-Lune]]); visuals verified in Studio. Check [[RSH-20261014-Claude-MCP-Skill-Cutscene-Video]] and [[RSH-20261014-Animation-Event-Ability-System-Video]] before designing it. I have not read them.
  - **VF-6 Sound, optional:** `roblox-sfx` at cue times. The note makes no judgment of the source's audio.
- **First experiment:** one ability sequence of 10-15 s, one interview, one prompt, ledger X7 filled in.
- **Not to automate:** whether it reaches the floor (jg's call).
- **Decision for jg:** which beats from the clip must carry over, and is VF-5 wanted as a shared system?

### 11. REF-MAP-001 Dark Fantasy World (approved quality floor)
- **Offers:** a look-and-feel floor: rich textures, colored light and fog, dense scenery, fantasy architecture; six frames kept. Promotional grading may shape the look; lighting and material settings are unknown. Gameplay is not the takeaway.
- **Enters at:** [[Map Workflow]] and any environment brief. Its companion is REF-MISC-005, kept separate by jg's request.
- **Automations:**
  - **DW-1 Atmosphere profile (X6 `stats`):** luminance range, clipped-highlight share, warm/cool balance and dominant palette from the six frames. The same numbers from matched-view Studio screenshots give a distance-to-reference *aid*. Grading means numbers inform, jg decides.
  - **DW-2 Named camera anchors:** a `CameraAnchors` folder per area so identical viewpoints are re-captured every revision. The before/after sheet shows progress inside the 2-revision cap.
  - **DW-3 Lighting preset module:** `Lighting`, `Atmosphere`, `ColorCorrectionEffect`, `BloomEffect` as a data table plus a scenario that applies a preset and captures the anchors. Presets are compared, not guessed from screenshots.
  - **DW-4 Density and landmark audit:** a Studio `execute_luau` count of parts and props per grid cell, and landmark spacing, against the interviewed target. Does not replace the `roblox-map` playability prover; it measures richness.
  - **DW-5 Performance snapshot:** memory and instance counts at each anchor, checked against the project's budget.
- **First experiment:** one 200x200-stud vignette (gateway, path, forest) after an interview, with X7 recording prompts and revisions.
- **Blocked:** copying layouts, characters or textures from the clip.
- **Decision for jg:** does dark fantasy fit GAME-002 itself, or is this floor for a later game?

### 12. REF-CODE-006 Orchestrated Agent Workflows (approved direction)
- **Offers:** principles: scoped instructions, templates, memory, task queues, decision gates, orchestrator and worker communication, isolated worktrees. 161.5 s video, eight frames and an automatic transcript; PR-count claims are unverified; a tool name ("FirstMate") is uncertain. The speaker's worktree preference does not override ours.
- **Enters at:** [[Workflow]], [[Task Intake]], the session and delegation budget.
- **Automations (inside current rules; none adds agents or jobs):**
  - **OR-1 Baseline first:** extend `orchestrator.py report` with per-task cycle data from existing history: revisions, time proposed to in_review, tokens. Without a baseline "faster" cannot be shown.
  - **OR-2 Handoff completeness lint:** for tasks in `in_review`, check the `T - Handoff` fields (checkout path, branch, commit range, checks run, known failures) exist and are non-empty.
  - **OR-3 Parallel-safe report:** `orchestrator.py next --parallel-safe` lists ready tasks whose "Files expected to change" do not overlap and which do not both need Studio or Rojo. It reports; starting parallel work still needs jg's explicit authorization ([[AGENTS]] delegation budget).
  - **OR-4 Repeated-explanation mining:** a manual pass over local session transcripts (stay local) to find instructions jg gave more than twice, as candidates for AGENTS.md, memory or a skill. The `consolidate-memory` skill covers part of this.
  - **OR-5 Tool lead verification:** confirm "FirstMate" exists and what it is (web search) before any repository link or capability claim is written down.
- **First experiment:** OR-1 plus OR-3 as a read-only report; look at it before proposing any policy change.
- **Not to automate:** changing delegation limits (the note says that needs its own explicit approval).
- **Decision for jg:** is the report enough to answer "when are parallel agents worth it", or do you want a controlled two-task trial?

### 13. REF-MAP-002 Stylized Swamp Encounter (approved quality floor)
- **Offers:** a 38.7 s clip, six frames: clear silhouettes, simple deliberate shapes, restrained colors, atmospheric depth, glowing accents; interest spans visuals, gameplay and animation. The "Bro RUN" caption is not evidence of a chase mechanic. Exact choreography, attack timing and camera are unknown.
- **Enters at:** [[Map Workflow]], encounter design, creature work.
- **Automations:**
  - **SW-1 Motion beats from the video:** `scdet`/`select` find change points; `frames` at 2-4 fps give the creature's apparent states. Output a labelled *candidate* beat list. No AI, hitbox or combat logic may be inferred from it.
  - **SW-2 Silhouette sheet:** binarized reference frames next to binarized renders of the creature at the three gameplay camera distances, for jg's judgment of readability.
  - **SW-3 Encounter rules in Lune:** once jg specifies behaviors, the state machine (pure rules, server-authoritative) is tested headlessly; the Studio scenario covers animation events. Start from [[Npc_template]] in the Code Index.
  - **SW-4 Shared anchors and stats** with DW-2 and DW-1.
  - **SW-5 Model-quality guard:** angular forms are a style, not a pass on the floor, so the asset still goes through [[3D Model Quality Baseline]] and the triangle-budget test arriving with TASK-0042/43.
- **First experiment:** a small arena slice with one creature and three behaviors from the interview; X7 records effort.
- **Decision for jg:** which behaviors count as the "encounter" for the first test?

### 14. REF-MISC-003 Character Sheet to Playable Model (process)
- **Offers:** a process: gather references, refine one consolidated sheet with jg, give sheet and prompt to Claude with Blender, compare against the sheet, rig, animate, import. 55.7 s video, eight frames and a transcript. Perfect-match and game-ready claims are unverified. The mouse is a process example, not a baseline. jg wants a note only for now.
- **Enters at:** [[Asset Workflow]], with [[Blender Pipeline]], the Mixamo pipeline and `art-import` underneath.
- **Automations:**
  - **CS-1 Model contract (with AN-1):** a sheet contract: panels (front, side, back, three-quarter), color callouts, props, scale marker, expression set, construction notes, proportion callouts. The existing `ASSET-REF-002_Facial-Expression-Reference.png` in `10 References/02 Map/` is a related input. A mechanical check covers panel count, resolution and presence of each field; a vision pass lists inconsistencies between views and is labelled unverified.
  - **CS-2 Comparison loop within budget:** `review.sh` (arriving) renders turntable views matched to the sheet's; X6 `sheet` pairs them; output is a **concrete difference list** ("tail thicker than sheet"), not a verdict. Five separate columns, as the note requires: fidelity, structure, finish, animation, Roblox suitability. Single-agent pass, no recurring review agent, two revisions at most.
  - **CS-3 Separate mechanical checks:** triangle budget (`test_art_budgets.py`, arriving), scale/pivot ([[LES-0007-Blender-Studio-Scale]]), bone names and weights (Blender script), rig retarget-check (Mixamo repo, humanoids), import round-trip (`art-import`). Each reports separately.
  - **CS-4 Gap flag:** automatic rig and animation of non-humanoid characters is unproven here. Existing research on custom rigs ([[RSH-20261014-CSM-Custom-Rig-Import-Video]], [[RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video]]) should be read first. I have not read them.
- **First experiment:** deferred by jg. When selected: one asset, one sheet, jg approves the sheet, then the loop with a time record.
- **Decision for jg:** is the sheet contract acceptable as a required step for Deep-tier characters only?

### 15. REF-MISC-004 Illustrated Surreal World (approved style floor)
- **Offers:** an art direction: hand-drawn outlines and hatching, paper-like borders, restrained earth colors, surreal shapes, dense detail, a decorative icon bar. Five frames at 21.3 s, 576x576. Whether the source is 2D, 3D or mixed is unknown. jg says "easily achievable", with no one-prompt requirement attached.
- **Enters at:** [[UI Workflow]], [[Map Workflow]], character and menu design; whole-game direction.
- **Automations:**
  - **IS-1 Style bible template:** palette (max N colors), line rules (weight, hatching), texture set, shape vocabulary, UI framing, plus *excluded* looks. One per game, stored in the game's `00 Overview` or a `SYS-` note, not in the reference.
  - **IS-2 Three-method comparison board** (Studio pads, X11): (a) 3D with `Highlight` outlines and `ColorCorrectionEffect`; (b) 3D with inverted-hull outline meshes (Blender headless option) and hatched textures; (c) 2D layered billboards. Same scene, same camera. jg picks. These are hypotheses; none is verified to match the look.
  - **IS-3 Palette conformance (X6 `stats`):** compare every shipped texture's palette to the style bible. A flag, not a gate.
  - **IS-4 Generative textures:** Studio MCP has `generate_texture` and `generate_material`. Their cost and rights are unknown, so they are used only after jg approves a trial.
  - **IS-5 Links:** hand-drawn UI treatments connect to REF-UI-001 and REF-UI-002.
- **First experiment:** IS-2 on one small scene.
- **Decision for jg:** which of 2D or 3D should the first board lead with?

### 16. REF-MISC-005 Dark Fantasy Boss and Effect Presentation (approved; companion to MAP-001)
- **Offers:** distinct silhouettes, color themes, intimidating scale, attack effects and environmental staging; six supplied photos plus three video frames; texture style chosen per game (jg does not adopt the speaker's anti-stud stance).
- **Enters at:** encounter and boss briefs in [[Map Workflow]] and [[VFX Workflow]].
- **Automations:**
  - **BP-1 Encounter presentation brief:** silhouette, theme color, scale ratio to the player, telegraph and impact effect beats, staging. Move sets, AI and hitboxes are explicitly absent until motion evidence exists.
  - **BP-2 Scale check:** the brief states boss height as a multiple of the player character; a Studio check measures it from bounding boxes.
  - **BP-3 Readability check (X6 `stats`):** clipped-highlight share and mean luminance contrast around the player and telegraph region in captured frames. This is the "preserve gameplay readability" caution made measurable; it is a flag.
  - **BP-4 Companion pull:** the brief tool follows mutual `related` links so MAP-001 and MISC-005 are offered together while staying separate notes.
  - **BP-5 Texture policy:** recorded in each game's `00 Overview` ("textures: …"), not in this note.
- **First experiment:** one boss silhouette and scale test in a gray-box arena, then one effect beat.
- **Decision for jg:** should boss tasks always pull both Dark Fantasy notes?

### 17. REF-CODE-007 Expert-Informed Briefs and Independent Verification
- **Offers:** a brief-strengthening method: what would a relevant expert ask or inspect that the brief lacks, which original sources exist, which methods and tools fit, what independent evidence shows correctness. From a 76.9 s commentary; the underlying article (credited in the video to Felix Rieseberg) was not retrieved. jg: propose improvements, but get agreement before expanding the objective.
- **Enters at:** [[Task Intake]] step 7 (Plan), Standard and Deep tiers only.
- **Automations:**
  - **EB-1 `reference-brief` skill (X4):** at most about 25 lines: missing requirements, expert lens, primary sources, methods, evidence plan, **scope-expansion proposals listed separately for jg's yes/no**.
  - **EB-2 Evidence-plan table** (also in A3): behavior to Lune spec or scenario; visuals to matched-view sheet; motion to paired frame strip; preference to jg. It states that tests do not establish taste and a good render does not establish runtime correctness.
  - **EB-3 Verify the source:** retrieve and read the article itself (read-only) before the method is cited as established.
  - **EB-4 Usefulness measurement:** each use logs how many added requirements jg confirmed. If the hit rate is low after a handful of tasks, drop the step. This honors "needs experimentation".
- **First experiment:** run EB-1 on the next Standard task and compare with what the existing process would have asked.
- **Decision for jg:** trial it on Standard and Deep tasks, or Deep only?

### 18. REF-MISC-006 ActorCore Free Motions
- **Offers:** a possible library of free motion clips. The supplied URL could not be opened; an alternate official catalog URL listed movement, dance, spell-casting and combat clips marked free. Formats FBX/BVH per Reallusion material; per-item terms, rig and retargeting are unknown. **Free only.**
- **Enters at:** animation work, after the existing Mixamo-to-Roblox catalog is checked.
- **Automations:**
  - **AC-1 Gap-first lookup:** run `python3 scripts/pipeline.py lookup "<term>" --rig R15` in `~/Code/mixamo-roblox-pipeline` (25 published animations, per the Catalog). Only if nothing fits does ActorCore get a look.
  - **AC-2 Free-clip register:** name, URL, access date, **free verified on date**, format, terms evidence. Never a paid clip. Built with AP-1's first job.
  - **AC-3 Objective motion checks** (a Blender-headless script alongside the Blender pipeline): foot-skate during stance, loop-seam pose error, root drift, peak joint angular velocity. These cover "contacts, foot sliding, joint limits, root motion, looping" from the note; the thresholds need calibration against a known-good Mixamo clip.
  - **AC-4 Bone map:** record the source skeleton and a mapping to the Mixamo/R15 naming. Whether the existing pipeline takes non-Mixamo skeletons is unknown; check before assuming.
  - **AC-5 Storage and ownership rules:** do not commit source FBX to the repo (same rule the Catalog states for Mixamo); published animations belong to jg's personal account, so they play only in jg-owned games.
- **First experiment:** one missing action (the Catalog list does not show spell-casting; confirm via AC-1) from one free clip through AC-3 to a Studio playback check.
- **Blocked:** downloads need jg's yes per file; no account linking.
- **Decision for jg:** is spell-cast the right first gap?

### 19. REF-CODE-008 Awesome Learn Gamedev (research directory)
- **Offers:** a curated map of learning resources across programming, technical art, rigging, VFX, illustration, 3D, animation, design, level design, UI/UX, audio, writing and production. CC0 repository; linked resources have their own terms; free and paid are mixed; ranking is the curator's opinion. README only. **Free only.**
- **Enters at:** any task with a knowledge gap that the vault and [[Resource Catalog]] cannot fill.
- **Automations:**
  - **AG-1 Gap-to-resource skill:** given one concrete question, fetch the README at a pinned SHA, shortlist candidates in the matching section, verify each is free, read the actual source, and write a **resource card** (authority, age, applicability, Roblox compatibility, free-verified date). Other-engine material is marked as not Luau/Roblox behavior.
  - **AG-2 Discipline gap detector:** if audit and bug findings share a category, count by discipline each month and suggest the top gap to research. Whether `AUD-` findings carry consistent categories is unchecked; if not, a category field would have to be added first.
  - **AG-3 Link rot (X5):** HEAD-check cards' URLs; mark inaccessible ones rather than guessing content.
  - **Not building** a local copy or scrape of the directory: a second store, and README links change.
- **First experiment:** answer one real open question (for example the retargeting terms, or a VFX timing reference) using AG-1 end to end.
- **Decision for jg:** which discipline gap has bitten most so far?

## Part D: Phasing and approvals

### Review order suggestion (jg decides; each still gets its own pass)
1. REF-MISC-002 (already approved; confirms what the tools may do), REF-CODE-007 (shapes every later interview).
2. The five quality floors: VFX-001, MAP-001, MISC-005 (together), MAP-002, MISC-004.
3. The model process pair: MISC-003 with MISC-001.
4. Tools: Roqer, RoPilot, Shaders, Throwie, Resource Boy.
5. Infrastructure and research: CODE-006, Apify, Expo, CODE-008, ActorCore.

### Phases
| Phase | Contents | Gate | Done when |
|---|---|---|---|
| 0 Foundation | X1, X2, X10, X12, F2/F3 doc fixes | G0 chore task, jg merges | Lint passes in `check.sh` and CI; `orchestrator.py start` prints a brief; tests cover the immutability check |
| 1 Evidence | X6, X5, X7, X8, X11 (pads), OR-1/OR-3 reports | G0; texture uploads G1 | `strip`/`sheet`/`beats` produce output from the 8 archived videos; pins recorded for 7 repos |
| 2 Skills | X3 and X3s (`reference-review`), X4 (`reference-brief`), EX-1, plus `.agents` copies | G0 | Each skill used once on a real item and noted in the Catalog as `implemented` |
| 3 Experiments | One per note jg selects, each a TASK on its own branch | Per task; G2 for installs, accounts, downloads | Result appended to the REF note and Catalog, including failures |

**Status 2026-10-17:** Phase 0 (#68) and Phase 1 (#69) are merged, apart from X11. Phase 2 is built on `chore/reference-skills`: X3 (`review-next`, `decide`), X3s (`reference-review`), X4 (`reference-brief`) and EX-1 (`skill_lint.py`). (Original note: Phase 0 was in PR #68.) Phase 1 is built except X11 (Studio test pads, which need Studio runs) on `chore/reference-evidence`: X5 (`pin`, `drift`), X6 (`evidence.py`), X7 (`ledger`), X8 (`rights`), OR-1 (`cycles`) and OR-3 (`next --parallel-safe`).

Phase 0 and 1 introduce no dependencies and no spend. A task slot is proposed per phase; no TASK IDs are reserved here.

## Part E: Deliberately not proposed
- A RAG or vector service (REF-MISC-002 says none is needed).
- Scheduled or recurring agents and cron jobs. Possible later with jg's separate approval (REF-CODE-006).
- Installing Roqer, RoPilot, Apify, Expo or Shaders packages.
- Any account, purchase, upload or download by an agent without jg's per-action yes.
- Extra subagents for review (AGENTS delegation budget).
- Using a similarity score or color distance as a pass/fail on visual floors. They are aids only.
- Writing inside `10 References/` outside X3/X9 flows that jg triggers.

## Open decisions for jg (batched)
1. Phase 0 first as one chore task? (Recommended.)
2. Immutability check: fail the commit, or warn? (Recommend fail unless the commit message carries jg's approval.)
3. AGPL stance for Roqer: methods only?
4. Retrieval threshold to revisit a RAG-like approach (about 100 REF notes proposed).
5. Does the reference brief apply to Standard and Deep tiers, or Deep only?
6. Which first experiments (one per note) to queue, and in what order?
7. Photoshop availability, for the Resource Boy intake.
8. Whether a free-only filter should apply to Resource Boy and Throwie.

## Needs human review
- Whether the inferred gaps (RP-2 evidence capture, AC-3 motion metrics, OR-3 parallel-safe report) are the real bottlenecks.
- All Roblox-class mappings in SH-1 and IS-2 are untested proposals.
- Effort and gate estimates are mine and unmeasured.
- I have not read the research notes I link ([[RSH-20261014-Claude-MCP-Skill-Cutscene-Video]], [[RSH-20261014-Animation-Event-Ability-System-Video]], [[RSH-20261014-CSM-Custom-Rig-Import-Video]], [[RSH-20261014-Monster-NPC-Sculpt-And-Rig-Video]]); they may already cover parts of VF-5, CS-4 and SW-3.
