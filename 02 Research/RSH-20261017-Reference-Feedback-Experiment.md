---
id: RSH-20261017-Reference-Feedback-Experiment
title: Reference Feedback Experiment
type: research
status: research
sources:
  - "[[REF-CODE-011-Pinehollow-Night-Watch]]"
confidence: low
created: 2026-10-17
updated: 2026-10-17
tags:
  - research/reference-experiment
related:
  - "[[Reference Review 2026-10-17]]"
  - "[[Resource Catalog]]"
---
# Reference Feedback Experiment

## Question
Can one explicit state drive a readable meter, light indicator, action availability and recovery in an isolated Roblox demo?

## Sources
| Source | URL / local source | Accessed |
|---|---|---|
| [[REF-CODE-011-Pinehollow-Night-Watch]] | `Desktop/Prompts/FABLE 5.1 Games.zip`, `pinehollow-funland-standalone.html` | 2026-10-17 |
| Existing UI kit | `games/haunted/src/client/UI/Theme.luau` | 2026-10-17 |

## Observed mechanics (verified)
- Source observation: Pinehollow's `update` computes usage from doors, lights and monitor; `updateHUD` changes colors, labels and control availability; `updateBeds` and `interference` add sound and image consequences. Inspected HTML lines 3104–3221. This is source evidence; runtime quality remains unverified.
- Fact: browser attempts timed out; native app control also timed out. No new source-game screenshots or motion judgments were obtained.
- Decision: jg selected an isolated meter-and-light experiment on 2026-10-17 and confirmed the review wording. No Haunted Collector gameplay change.
- Fact: original experiment sources live in `experiments/reference-feedback/`, outside game sync. Existing Theme is reused, unchanged. No copied third-party assets, remotes, persistence or paid calls.

## Hypotheses
- Candidate: a single state description can prevent conflicting meter labels, colors and disabled actions. Logic verification alone does not prove visual clarity or player comprehension.

## Relevance to our game
Potential presentation technique only. Game-specific resource mechanics, balance and art choices require their own task. This demonstration changes no game code and establishes no new minimum visual standard.

## Original implementation ideas
A pure State module classifies normal (>25), low (>0 through 25) and depleted (0). A separate client view derives text, color and control availability. Demo presets and a continuous drain path allow repeatable checks. Thresholds and rates are experiment parameters, not adopted balance.

## Results and limits
- Implemented and tested: 15 headless assertions, including phase boundaries, drain rates, zero clamping, time subdivision and invalid input rejection.
- Implemented and tested: Selene reports zero errors/warnings; Luau-LSP analysis of both demo modules with the Roblox definitions and resolved source map reports no type errors. Rojo builds `/private/tmp/ReferenceFeedbackDemo.rbxl`.
- Needs manual Studio check: live UI controls, depletion/recovery, desktop/phone layout, Output and jg's visual judgment. At the first connection check MCP saw only AnimPipeline and WispRev3, not the supplied demo file; those places were not modified.
- Implemented and tested: built-place inspection confirms only the isolated State/Theme/client demo wiring; full `scripts/check.sh` passes, including 140 Luau specs and 133 Python tests. Existing warnings: missing optional ImportedArt asset and Python ResourceWarnings; no check failures.
- Connection limitation: after jg reported opening and connecting the demo, MCP still returned only AnimPipeline.rbxl and WispRev3.rbxl, neither with FeedbackDemo. No Play session was started; independent audit is deferred until runtime checks are green.
- Not tested: multiplayer, game balance, retention, performance on devices or original reference gameplay.

## Recommendations (max 3)
1. Validate the three states and recovery in the separate demo place.
2. Record jg's quality judgment and adjust only the selected demo scope.
3. Promote only the proven presentation method after runtime checks; keep a candidate recipe until then.

## Needs human review
- Unverified conclusions: visual readability, layout at small sizes and usefulness in a real game.
- Candidate recipe: choose an authoritative state; derive label/color/action/hint together; include text as well as color; prove boundary transitions and recovery; preserve a reproducible fixture; record actual runtime evidence and human acceptance. For shared gameplay, server authority must precede client presentation.

## Five-step progress and handoff
1. Main-vault integration completed locally at ffd92ed; merge commit ffd92ed was subsequently backed up after read-only evidence confirmed included main history was already on GitHub. Remote main merge completed in PR #76 at 525b378 on 2026-10-17.
2. First individual review recorded: Pinehollow → experiment. Ten other supplied games await individual review and runtime inspection; no mass decisions inferred.
3. Isolated original demo implemented; headless checks passed; runtime pending connection.
4. Findings recorded here and linked from the reference note.
5. Recipe remains candidate, not verified reuse. Continue through runtime + jg judgment before promotion.

## Runtime verification and visual rejection — 2026-10-17
This dated result supersedes the initial connection-blocked runtime state above; the earlier record is retained.

**Setup:** Opened `/private/tmp/ReferenceFeedbackDemo.rbxl` through native Studio controls. Verified place name, PlaceId 0, FeedbackDemo modules and client script in Edit before Play. Studio MCP ID `ef6681c2-e379-4266-8a23-459a26bb682f`. No Haunted Collector Rojo connection was used. AnimPipeline and WispRev3 were not modified.

| Check | Observed result |
|---|---|
| Initial mount | GUI mounted; NORMAL, charge 100, lamp off |
| Low preset | LOW, charge 20, lamp on |
| Drain to depletion | After Run drain and 3.5-second wait: DEPLETED, charge 0, lamp off |
| Disabled actions | Lamp and drain Active=false; clicking lamp left charge/phase/lamp unchanged |
| Recovery | Normal restored 100 charge and available lamp action |
| Desktop | 1336×709 initial viewport; all controls visible |
| Phone portrait | iPhone 14 simulated viewport 388×762; readable layout and controls observed |
| Phone landscape — initial failure | At 749×388 the fixed-height panel clipped controls |
| Phone landscape — fix | Added a vertical ScrollingFrame. Safe-area size 749×330, canvas height 538. Real scroll input moved CanvasPosition to (0,200), exposing controls and footer |

**Verification limits:** Mouse interaction inside the phone emulator is not physical-device touch validation. Gamepad input is not tested. The original browser game's runtime is still unverified. Console before restyling had no mentions of demo script errors; it contained CorePackages FoundationProvider warnings and asset-type warnings. Those warnings were not diagnosed as demo failures. No multiplayer, performance or gameplay claims.

**jg's judgment:** Functionality and spacing are fine. The initial purple UI looked cheap and AI-made. jg clarified that UI references should guide the styling. After viewing the real Check-UI showcase and button screenshots and adapting original styling code, the slate/cyan/beveled revision was also rejected as still needing visual changes. Neither style is an accepted quality baseline.

**Code and checks:** Responsive fix plus demo-local DemoTheme; base game Theme unchanged. No imported reference textures, icons, code framework or assets. Original State logic unchanged. Fifteen headless assertions pass, isolated build inspection passes, demo Selene and Luau-LSP checks pass. Full check.sh after the responsive fix passed (140 Luau specs, 152 Python tests); final style-specific lint/type/build checks passed afterward. The final source calibration has not had a further fresh Play run; its matching visual properties were adjusted in the running demo for review. Do not turn that into stronger runtime coverage.

**Evidence:** First UI: ![[low.jpg]]

Portrait before the scrolling correction: ![[portrait.jpg]]

Depleted after the scrolling correction: ![[feedback-runtime-depleted.jpg]]

Rejected slate/cyan visual revision: ![[feedback-rejected-slate.jpg]]

**Candidate recipe:** Keep state-to-label/color/action/hint derivation and explicit recovery tests as an implementation technique. Do not promote the UI art direction. New lesson to test: approve a concrete visual target before styling, compare the actual result against it, and preserve rejected screenshots.

**Handoff (under 20 lines):**
- Branch/worktree: chore/reference-feedback-runtime, `/private/tmp/rg1-feedback-runtime`.
- Runtime behavior verified; functionality and spacing accepted by jg; visual style rejected.
- Worktree contains responsive fix, demo-local skin and evidence; no new merge or backup approval inferred.
- Built artifact: `/private/tmp/ReferenceFeedbackDemoStyled.rbxl`.
- Studio demo remains in Play for inspection; other places unchanged.
- Two revision attempts reached; stopped under AGENTS.md.
- Required next input: one named game/interface or screenshot establishing the UI visual target.
- No third attempt, accepted style, production adoption or verified visual recipe claimed.
- Ten other supplied games remain in the individual review queue.

## New concrete target and illustrated application — 2026-10-17
After the earlier revision stop, jg supplied [[REF-UI-004-Illustrated-Halloween-Shop]] and explicitly asked to apply it to the demo. This authorizes the new concrete reference scope; it does not retroactively accept the earlier work.

- Observed source video in browser: themed header/frame/decorations and opening/closing states. Source implementation, ownership and exact animation curves remain unverified.
- Built-in image_gen produced original desktop and portrait artwork, preserving both originals and exact prompts in `experiments/reference-feedback/art/`. No copied source-post assets or icons, no uploads and no paid API fallback.
- A first nine-slice/composite rendering attempt distorted ornaments or produced seams. It was discarded in favor of complete desktop and narrow artwork variants; original imagery is preserved, and only import-format conversion is used for the local pixel payload.
- Implemented original FrameArt decoder with cache, dimension/palette/pixel-count checks and yielding decode. Render uses local EditableImage objects via ImageContent. Preserved original State and the control positions/spacing; added header typography alignment and original art around the controls.
- Fresh Studio Play: mounted with desktop art and NORMAL/100 state; Low + Run drain reached DEPLETED/0 with lamp and drain disabled; clicked disabled lamp and restored Normal to 100. Phone iPhone 14 viewport 388×762 selected portrait art. Phone landscape scroll reached CanvasPosition (0,200); desktop restored afterward.
- Fifteen headless state assertions, local payload round-trip checks, isolated build inspection, demo lint/type checks and full check.sh pass (140 Luau specs, 152 Python tests). Final art/cached variant module is included in the explicit type-check scope.
- Screenshots: desktop ![[halloween-desktop.jpg]] and portrait ![[halloween-phone.jpg]].
- Built artifact: `/private/tmp/ReferenceFeedbackHalloween.rbxl`. Source and evidence are in chore/reference-feedback-runtime. No game source or existing game place changed. Native controls remain live; the source video's full reveal/choreography was not recreated.
- Human visual acceptance remains pending. This is runtime evidence for the isolated demo, not production deployment, asset-rights clearance, performance certification or a universal quality floor.

**Final verification note:** Final demo-specific Selene and Luau-LSP checks pass, including FrameArt and the build inspector. Screenshot files are stored with their actual JPEG format. Studio was observed back in Edit after the test; no further Play session was started. Visual acceptance remains pending.

## User-directed motion and platform polish — 2026-10-17

**Decision:** jg called the illustrated direction “closer” and requested animations and polish across platforms. This is further direction, not final visual acceptance.

**Implemented and tested:** Short entrance settle, subtle artwork float, meter interpolation, lamp border pulse, button hover/focus/press feedback; reduced-motion preference and local toggle. Studio samples confirmed art stayed stationary with reduced motion and resumed afterward. Tab/Enter and D-pad/A virtual inputs navigated/activated controls; depletion disabled lamp/drain and navigation skipped them. Phone landscape (749×388) scrolled focused Empty into view; tablet (1179×819) and Xbox (1919×1079) layouts fit. Destroying the GUI removed its bindings/backdrop and restored CoreGui state.

**Validation:** 15 isolated state assertions, isolated place build/inspection, explicit demo Selene and Luau-LSP checks pass. Full check.sh passed 140 Luau specs and 152 Python tests after allowing the localhost round-trip test; initial sandbox run could not bind localhost. Final D-pad handler was additionally linted, typechecked and runtime-tested.

**Limits:** Physical touch/controller hardware, device performance, console safe-area preferences and published EditableImage behavior remain unverified. Final visual judgment pending. Artifact: `/private/tmp/ReferenceFeedbackAnimated.rbxl`. All changes remain isolated from game source and the other Studio places.

## Independent decorative motion — 2026-10-17

**Decision:** jg accepted the button effects, rejected entire-frame movement and requested subtle falling leaves, pumpkin-carving light, ghost/branch sway and spiders spinning down/up their threads.

**Implemented and tested:** Removed structural-frame float/rotation and entry scale. Built-in image_gen prepared clean desktop/portrait backplates and an original transparent sprite atlas; originals and exact prompts retained. Independent native image layers animate ghost/branch, two spiders with changing thread lengths, and ten recycled falling leaves. A slow background wash and localized carved-region illumination mask add ambient movement. Decoration is below text/controls; narrow layouts use smaller inward ornaments. State, control positions and button effects are preserved.

Studio time samples confirmed unchanged frame position/rotation while ghost/spider/glow changed. Reduced motion fixed poses/glow and hid leaves; re-enabling resumed effects. Desktop and phone portrait were visually inspected; phone decoration clipping/overlap was corrected. Explicit demo Selene/Luau-LSP, art payload round trips, isolated build inspection and fifteen state assertions pass. Prior full check.sh pass remains recorded above; no physical-device or production-performance claim. Screenshots: ![[decorations-desktop.jpg]] ![[decorations-phone.jpg]].

Artifact: `/private/tmp/ReferenceFeedbackDecorations.rbxl`. Demo left in Play on desktop for jg's motion review. Visual acceptance of this revision, independent audit, backup and merge remain pending. No game source or other Studio place changed.

## Rooted frame, raised presets and warm carvings — 2026-10-17

**Decision:** jg requested raised Normal/Low/Empty buttons, identical eye/mouth fade treatment for all three pumpkins, attached spider threads, a tree rooted around the right frame, and separate animated side/pumpkin twigs and leaves. jg then requested a warmer eye color and completion of the revision.

**Implemented and tested:** Presets raised 32 px; action buttons raised 24 px, with hint/footer adjusted to preserve clear gaps. Desktop inspection measured preset bottoms at y=470 and bottom-carving area beginning around y=490. Original bare desktop/portrait backplates and a rooted-tree/foliage atlas were generated with built-in image_gen; originals and exact prompts retained in `art/ROOTED-PROMPTS.md`. Seven separate side/hat twig clusters and two foliage groups behind the pumpkins sway without static duplicate decorations. Rooted tree art aligns around the right post; both silk origins follow explicit points on the tree, including its rotation. The narrow version uses a shorter tree and inward right thread origin.

All three carved faces use the same five-second opacity cycle and warm amber-orange RGB(255,170,48). A bounded connected-component mask follows dark carved features; the initial rectangle mask also lit some outlines and was replaced. Desktop and phone portrait visually checked. Runtime time samples confirmed changing glow/foliage/tree motion with a stationary frame; reduced motion held glow, foliage, tree and spider poses constant. Initial mask diagnostics attempted an unsupported EditableImage attribute method; fixed before final runtime checks. No current runtime error is claimed from that earlier attempt.

Final artifact: `/private/tmp/ReferenceFeedbackRooted.rbxl`. Screenshots: ![[rooted-warm-desktop.jpg]] ![[rooted-warm-phone.jpg]]. Explicit demo lint/type checks, isolated Rojo build/inspection and 15 state assertions pass. Physical device performance and published EditableImage behavior remain unverified. Human visual judgment, independent review and backup/merge are separate pending gates; this record does not mark the reference accepted or change its Intent/status.

The first attempt to restore desktop was blocked when automatic approval review reached a usage limit. After jg requested continuation, normal Studio actions succeeded; final desktop was restored and left running. No bypass was used. Source and notes remain in chore/reference-feedback-runtime; game code and other Studio places were not changed.

**Final validation:** Full scripts/check.sh passes (140 Luau specs, 152 Python tests; existing optional ImportedArt warning and Python ResourceWarnings). Final relocated Low/Run mouse sequence reached DEPLETED/0 and Normal restored power; motion remained enabled. Vault validation, reference Intent guard and diff whitespace check pass. No notes created in this final stage; this research note, demo README and art provenance were updated, with two new evidence images. Independent review and human visual approval remain pending rather than inferred.

## Full leaf silhouettes and restored pumpkin stems — 2026-10-17

**Decision:** jg supplied four closeups rejecting straight clipped leaf edges and the loss of earlier pumpkin stems.

**Evidence and fix:** The twig-cluster atlas rectangle ended in opaque leaf pixels (right-edge alpha 255). Expanded native image bounds include the full silhouette with transparent margin (right/top/bottom edge alpha 0; only near-transparent alpha 1 on left). All seven instances, including flipped clusters, use the corrected rectangle. Phone side clusters move inward to avoid clipping against the viewport. Built-in image_gen produced an original curled brown/purple stem with orange highlights using the preserved original frame as reference; two native sprites restore the bottom pumpkin stalks. Source and exact prompt retained in `art/halloween-pumpkin-stem.png` and `art/STEM-PROMPT.md`. Existing glow, buttons and decorative movement remain.

**Implemented and tested:** Fresh Studio desktop and iPhone 14 portrait inspection; explicit demo Selene and Luau-LSP pass; isolated build inspection includes StemArtData. Screenshots: ![[complete-leaves-stems-desktop.jpg]] ![[complete-leaves-stems-phone.jpg]]. Artifact: `/private/tmp/ReferenceFeedbackStems.rbxl`. Desktop restored and demo left in Play for human review. No new acceptance or merge approval inferred. This research note, README and art provenance updated; reference Intent/status and game source untouched. Human visual approval and independent review remain pending.

## User-identified fidelity failures and corrected review — 2026-10-17

**Decision and failure:** jg clarified that the intended stems were the original curled corner vines, not the newly generated stalks. jg also identified witch-smile pixel defects and the missing bottom-left nose, and explicitly asked that the workflow learn from these errors. Earlier claims of visual correction were too broad: technical checks and full-layout screenshots did not establish feature fidelity. Earlier records remain historical, not human approval.

**Root causes:** I substituted a new interpretation for a specific original feature; removal of baked ornaments also removed intended corner anatomy. The left nose was absent from the source as well as the emission. A strict color threshold omitted lighter carving pixels, and a misplaced right-nose seed omitted that feature. Binary mask boundaries exposed jagged seams. The old closeup review was insufficient.

**Correction and evidence:** Restored the original curled corner composition in desktop/portrait artwork with a small left carved nose. Removed the replacement stalk and added pumpkin-foliage sprites; retained rejected originals/provenance. Avoided duplicate side sprites over preserved artwork. Corner vines are now stationary in the backplate; this is a stated fidelity tradeoff, not a claim that every original ornament is separately animated. Expanded carving-color coverage, corrected feature seeds, closed isolated pixel gaps and antialiased emission edges. The first enlarged comparison still revealed witch-mouth holes and an unlit right nose; those were fixed before the final comparison.

**Repeatable review:** Added `experiments/reference-feedback/inspect-faces.luau`, which uses actual runtime base/emission image content to show all three faces at dim and lit extrema. Enlarged desktop AND portrait assets were inspected for eyes, nose, complete smile, edge coverage and ornament alignment. Both source variants now show all features at both extrema. Captures: ![[fidelity-desktop-faces-dim-lit.jpg]] ![[fidelity-portrait-faces-dim-lit.jpg]]; final composition ![[fidelity-restored-layout.jpg]]. Inspection GUI was removed and desktop demo restarted normally.

**Lesson recorded locally:** Identify and preserve the exact referenced feature before replacing it. Require feature-level dim/lit closeups and sprite-boundary checks for this asset recipe; do not infer visual approval from lint, runtime functionality or a whole-screen view. This is evidence in the recipe/research record, not an unapproved global LES or workflow policy change.

Artifact: `/private/tmp/ReferenceFeedbackFidelity.rbxl`. Explicit demo lint/type and isolated build/inspection pass. No game code, reference Intent/status, global rules or other Studio place changed. Human visual approval, independent review and merge remain pending. Updated this research note and README, added the reusable visual inspector and exact art prompts; no new Obsidian note was created.

## Spider attachment and ribbon-center correction — 2026-10-17

**Decision/evidence:** jg's closeups showed the left spider attached correctly, the right thread starting in transparent space, and the heading shifted right. The earlier claim that both anchors were attached was insufficiently verified.

**Fix:** Preserved the first anchor. At the second anchor's atlas column, actual opaque bark begins around normalized y=.072; the old desktop y=.055 was transparent. Moved that origin to y=.085 inside the branch and retained the shared rotated tree transform. Runtime read of the chosen atlas point returned alpha 251. The narrow anchor remains on its visible branch segment.

Header labels now belong to the painted frame with center anchors at the ribbon's visual midpoint (x=.53 of the artwork), instead of asymmetric 100/70 px card offsets. Desktop title/subtitle centers measured 688.932 px against ribbon center 688.932 px; phone centers measured 207.902 px against 207.902 px. No unequal inset remains between the two labels.

Desktop and iPhone portrait layouts inspected: ![[aligned-header-spider-desktop.jpg]] ![[aligned-header-spider-phone.jpg]]. Explicit demo Selene/Luau-LSP and isolated build inspection pass; vault, reference guard and whitespace checks pass. Artifact: `/private/tmp/ReferenceFeedbackAligned.rbxl`. Desktop restored, demo in Play. Updated this research note and demo README; no new Obsidian note, reference Intent/status or game-code change. Human visual acceptance remains pending.

Local recipe lesson: verify attachment coordinates against actual opaque art pixels and a shared transform, and center typography in the visible decoration's coordinate system. A plausible normalized point or card-centered label is not evidence of visual alignment.

## Continuous frame beneath tree roots — 2026-10-17

**Decision/evidence:** jg's closeup showed that the orange post baked inside the tree sprite, its heavy horizontal lower outline and flared base made the main frame appear to terminate halfway down. This was a compositional join failure, not a behavior failure.

**Correction:** Built-in image_gen removed the post/end cap and replaced the gaps with transparency while retaining the purple trunk, roots and canopy. Preserved original artwork and exact edit prompt in `art/POST-REMOVAL-PROMPT.md`. Added TreeArtData for the tree only; existing leaf/vine sprites still consume unchanged RootArtData, avoiding collateral alignment changes. The original continuous frame now shows through the roots. A sampled former post pixel changed from alpha 252 to 0; the corrected right spider-anchor pixel remains opaque (alpha 252).

**Verification:** Desktop and iPhone portrait compositions inspected: ![[continuous-frame-desktop.jpg]] ![[continuous-frame-phone.jpg]]. Explicit demo Selene/Luau-LSP and isolated build inspection pass. Artifact: `/private/tmp/ReferenceFeedbackContinuousFrame.rbxl`. Desktop restored and left running. Updated this research note, README and art provenance; no new Obsidian note or game-code change. Human visual approval remains pending.

Local review addition: inspect how each decoration joins the underlying frame; a complete isolated sprite can still introduce a false structural endpoint when composited. Preserve verified neighboring sprites when fixing one asset.

## Final narrow curled branch — 2026-10-17

**Direction:** jg requested curving the branch bottom around the UI and reducing its flared spread as the final visual adjustment. Replaced the wide lower roots with a slim tapered curl close to the frame. Built-in image_gen's first output had a tail cut off at the canvas boundary; rejected it and used a corrected complete tip with transparent margin. Original and exact prompts retained in `art/CURLED-TIP-PROMPTS.md`. Only TreeArtData changed; existing foliage atlas, header positioning, UI behavior and attachment transforms remain.

**Verification:** Desktop and iPhone portrait inspection: ![[final-curled-tip-desktop.jpg]] ![[final-curled-tip-phone.jpg]]. Runtime alpha samples: right spider attachment 252, left attachment 251, lower canvas margin 0. Both threads still attach to bark. Art payload round trip and isolated build inspection pass; this final adjustment changes only art input/payload, not Luau behavior. Prior explicit demo lint/type and full repository check results remain recorded above. Vault, reference guard and whitespace checks pass.

Final file: `/private/tmp/ReferenceFeedbackFinal.rbxl`. Desktop restored and left running for review. Updated research note, README, art source/provenance and screenshots; no new Obsidian note. No human visual acceptance, independent review, commit/push or merge is inferred from the conditional “we will be done.” The branch/worktree remains `chore/reference-feedback-runtime`, `/private/tmp/rg1-feedback-runtime`; backup/merge remains a separate pending step. No game source or other Studio place changed.

**Small position follow-up — 2026-10-17:** At jg's request nudged the branch right by 6 px on desktop and 3 px on narrow screens. Silk-origin transform includes the same position offset so both spiders follow the branch. Fresh Studio Play confirmed the offset; demo lint/type and rebuild pass. Updated `/private/tmp/ReferenceFeedbackFinal.rbxl`; human visual judgment remains pending.

**Second position increment — 2026-10-17:** jg requested one more identical rightward increment. Total branch offset is now 12 px desktop / 6 px narrow; the shared silk transform follows it. Updated Studio Edit source, restarted Play and rebuilt `/private/tmp/ReferenceFeedbackFinal.rbxl`. No other style or behavior change.

## Accepted experiment: closeout outcome — 2026-10-17

**Human approval:** After the second rightward increment, jg said “all good now.” jg then approved recommended steps 1–4: record visual approval, commit/push and reviewed merge preparation, final input checks, and a reusable recipe. This accepts the final isolated experiment's look/function; it does not approve game integration, a universal quality floor, source-post rights, or an ADR.

**Recipe:** [[RSH-20261017-Layered-UI-Production-Recipe]] is registered in Resource Catalog. It preserves the corrected art/process, technical limits and mistakes instead of treating rejected work as approved.

**Final input evidence:** Keyboard Tab/Return activated controls, D-pad/A navigated and started/paused drain, unavailable controls were skipped and Normal recovered power. Reduced motion held tree, spider and glow values constant. Phone portrait targets measured 48 px high (Motion 44 px). At 749×388 landscape, selected Empty was scrolled fully into the 330 px view. Desktop mouse Low/Normal activation retested successfully. Phone mouse injection generated no GUI input events, so emulated mouse/touch activation is not claimed. TouchGui appeared before the menu in hit order; menu DisplayOrder was raised to 10 and inspected above TouchGui, but that alone did not solve the tool's absent input events. Physical touch/controller hardware remains pending under the existing UI workflow.

**Scope:** Source/art/evidence and note changes only; game code, queue statuses and other Studio places untouched. Final source was reloaded into the demo and the desktop session restarted, clearing temporary input tracing. Independent review and Git outcome will be appended below.

**Closeout checks and backup block:** Final full scripts/check.sh passed (140 Luau specs, 152 Python tests); explicit full demo/visual-inspector Luau-LSP and Selene scopes pass, with an array-union annotation corrected in the inspector. Fifteen state assertions and isolated final place inspection pass. Final place SHA256: `f4345e6f0296584ed8e600b06f895f1cd329fba27727ca71b74e75e9c324f9ff`. Automatic approval review rejected the proposed GitHub backup because exact destination and upload categories require explicit user authorization. No commit/push ran. Independent read-only review is in progress; the exact upload scope will be presented after it is complete.

## Independent review correction — 2026-10-17
[[RSH-20261017-Reference-Feedback-Review-01]] records the initial changes-requested verdict. Fixed center-pivot branch math and midpoint-anchored spider threads without changing the approved visual direction. Actual runtime endpoint regression passes desktop and directly sized narrow artwork through both sway extrema (max error 1.202 px, threshold 1.5 px). Studio device simulator currently reports a 1×1 camera and screen capture did not return; no new device visual or touch pass is claimed. Final independent delta review pending.

## Final review and handoff — 2026-10-17
[[RSH-20261017-Reference-Feedback-Review-02]] passes the reviewed correction with no actionable findings. Repository checks: 140 Luau specs and 152 Python tests pass. Explicit demo Selene and Luau-LSP pass; 15 state assertions and rebuilt-place inspection pass. Rebuilt final place SHA256: `9994d8434e8bb41ceafdae9f2034bfa67557098bfc64159aded4eeedb051634a`. Normal responsive artwork restored and device simulation stopped after temporary geometry testing. No new device capture or physical input pass claimed.

**Handoff:** Approved isolated visual experiment, reusable recipe and two review records are ready in `/private/tmp/rg1-feedback-runtime` on `chore/reference-feedback-runtime`. Commit/push/merge remain pending exact GitHub destination and data-scope authorization after automatic approval review rejected the earlier backup. Preserve unrelated dirty main checkout and active game sessions. No task queue/game-state edits required for this research chore. Updated experiment, recipe, catalog/reference records; created review 01 and delta review 02. Physical hardware and production adoption checks remain pending by scope.
