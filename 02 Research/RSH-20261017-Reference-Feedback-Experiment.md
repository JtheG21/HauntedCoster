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
