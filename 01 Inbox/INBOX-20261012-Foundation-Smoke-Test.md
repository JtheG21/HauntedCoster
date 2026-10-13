---
id: INBOX-20261012-Foundation-Smoke-Test
title: Foundation Smoke Test
type: inbox
status: inbox
created: 2026-10-12
updated: 2026-10-12
tags:
  - inbox/workflow
related:
  - "[[ADR-0009-Shared-Production-Foundation]]"
---
# Smoke test: the reference-to-handoff pipeline (documentation only)

**What this is:** a dry run of [[Task Intake]] on a **hypothetical** task. It is not a reference decision. Map references are on hold (jg, 2026-10-12), so nothing was written to `10 References/` and no game file changed. Keep it as a worked example, or delete it; jg decides.

**Hypothetical request:** "Use the first map screenshot to plan a creepier tree prop for the Cursed Woodland."

## 1. Intake and routing
- **Project / task:** GAME-002; there would be a new TASK (none created).
- **Classification:** image reference, then 3D asset or prop (primary), with a map element. Workflows: [[Reference Analysis Workflow]], then [[Asset Workflow]].
- **Depth:** standard. It is a new prop in an existing habitat, reversible, and touches no shared state.
- **Proceed or ask:** proceed with the analysis. **Ask** before any build, because the art direction is "accepted for now, revamp later" (jg, 2026-10-12), so a new art style is jg's call.

## 2. Reference analysis (would become `REF-MAP-001-…`)
- **File:** `10 References/02 Map/Screenshot 2026-10-11 at 11.30.10 PM.png`, embedded by [[Reference1]]. Source and licence not recorded.
- **Observations:**
  - A dense conifer forest at night under a blue-green canopy, with a dirt floor and sparse broad-leaf plants.
  - Two foreground trees have large carved faces: glowing orange eye rims and lit teeth, with branch-arms.
  - Three small humanoid characters stand in a clearing behind them.
  - Low light, with the faces as the brightest elements.
- **Inferences:**
  - The faces act as landmarks and as the scare: the glow reads in the dark.
  - The clearing frames the characters as the focal point.
  - The low-poly, stylised textures suggest a game screenshot. Which game is unknown.
- **Uncertainty:** the scale is unknown (no known-size object; the characters' size is not established). Wide-angle distortion is likely, and the image is cropped at the edges.
- **Intent:**
  - **Adapt:** a glowing face carved into a tree trunk as a dark-area landmark.
  - **Inspiration:** a lit clearing that frames the goal.
  - **Exclude:** the characters and the exact face designs (possibly another game's IP), and the photographic textures.

## 3. Reuse check
- [[Resource Catalog]]: the prop kit `games/haunted/src/server/World/Props.luau` already has `Props.deadTree` (line 295), which the Woodland builder uses.
- **Decision:** **extend** `deadTree` with an optional face variant (parts plus a `SurfaceGui` or neon inlays) rather than adding a mesh. Blender isn't needed for this silhouette.
- No VFX reuse is needed beyond a `PointLight`, because the glow can be neon material.

## 4. Handoff ([[T - Handoff]], light)
> **Task:** TASK-#### (to be created): add an optional glowing-face variant to `Props.deadTree` for the Cursed Woodland.
> **Receiver:** Claude Code. **Workspace:** `/Users/jg/Desktop/Rg1`, branch `task/TASK-####-Woodland-Face-Tree`, code root `games/haunted/`.
> **Start by** reading `AGENTS.md`, `04 Agents/Task Intake.md` and `04 Agents/Workflows/Asset Workflow.md`, then run `git status`. If anything below is unavailable, stop and report it.
> **Inputs:** `games/haunted/src/server/World/Props.luau` (`deadTree`), `games/haunted/src/server/World/Habitats/Woodland.luau`, and this note's analysis.
> **Keep unchanged:**
> - the existing `deadTree` output when the variant is off
> - the habitat layouts
> - the gameplay and the reachability proofs
>
> **Constraints:**
> - Parts only; no generated or uploaded assets.
> - At most 1 light per tree, and at most N face trees per habitat (N to be proposed).
> - No new art direction without jg.
>
> **Acceptance:**
> - [ ] `check.sh` passes.
> - [ ] Default trees are identical (same part count).
> - [ ] A face tree reads in the dark at gameplay distance (Studio screenshot).
> - [ ] Its collision doesn't trap players (a walk test).
> - [ ] Instance counts are recorded before and after.
>
> **Report:** files changed, the check output, screenshots, the counts, and what is unverified.

## 5. What the receiver must verify (Claude can't from this note)
- Visual readability and taste: jg in Studio.
- Performance at 2 players: Studio `Stats`.
- On-device look: deferred until the game is nearly finished.

## Result
The pipeline produced:
- a routed, tiered intake
- an analysis that keeps observations, inferences and intent apart
- a reuse decision backed by a real file and line
- a self-contained light handoff, with acceptance criteria and the manual checks listed

The weak spot is video intake, which is blocked until `ffmpeg` and `yt-dlp` are installed.
