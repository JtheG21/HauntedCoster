# R1 manifest: remote branch sweep (dry run)

Inventory taken 2026-11-01 after `git fetch --prune origin`, with `origin/main` at `31ac516`. **Nothing has been deleted.** Each batch needs its own approval from jg.

## Counts

| Class | Meaning | Count |
|---|---|---|
| M | Tip is an ancestor of `origin/main` | 116 |
| S | Merged PR from this branch, and an empty scoped diff against `origin/main` | 1 |
| U | Everything else, not excluded | 3 |
| X | Excluded: Closeout kept-unmerged table | 18 |
| | **Total origin branches, excluding `main`** | **138** |

The total matches `git ls-remote --heads origin` (139 heads, minus `main`). `chore/r1-remote-sweep`, which holds this file, was created after the inventory and is not counted: it has an open PR, so it is excluded and is never a candidate.

Other exclusion checks: `gh pr list --state all` shows 0 open PRs. `gh api .../branches?protected=true` returns no protected branches, and the repo has no rulesets. The default branch is `main`.

## Points for approval

- **`task/TASK-0110-studio-sync` is class M.** The R1 brief excluded it until classified. Its tip `c553954` is an ancestor of `origin/main`, 0 commits ahead, and equals the head of merged PR #159. It is not in the Closeout table. It has a batch of its own so it can be decided separately.
- **`chore/video-research-3d-models` meets the S rule, but its tip commit did not come through its PR.** PR #50 merged with head `ac7bace`; the tip is `92b86ba`, committed a minute before that merge. The commit adds one file, and that file is byte-identical on main (it arrived through `f3a3489`). No content is lost, but `92b86ba` exists on no other branch. `CLEANUP-PLAN.md` Appendices B and D listed this branch as kept, though it is not in the Closeout table. It has a batch of its own.
- **U branches stay.** `chore/art-automation` and `task/TASK-0024-FullLoop-Landmark-Flake` have merged PRs but non-empty scoped diffs, so they fail the S rule.

## Class M

116 branches. All are 0 commits ahead of `origin/main`, and each tip equals the head of a merged PR. The set and SHAs match the Appendix C manifest in `CLEANUP-PLAN.md`.

| Name | SHA | Date | PR# | Reason |
|---|---|---|---|---|
| chore/TASK-0057-proposal | 647eb0e | 2026-10-18 | #88 | Ancestor of origin/main; tip = merged PR head |
| chore/TASK-0058-proposal | 70a49af | 2026-10-18 | #90 | Ancestor of origin/main; tip = merged PR head |
| chore/TASK-0059-proposal | 421bea1 | 2026-10-18 | #93 | Ancestor of origin/main; tip = merged PR head |
| chore/TASK-0059-state | 6018c34 | 2026-10-18 | #95 | Ancestor of origin/main; tip = merged PR head |
| chore/TASK-0060-approvals | 3844245 | 2026-10-18 | #100 | Ancestor of origin/main; tip = merged PR head |
| chore/anim-pipeline-pointer | 43736d4 | 2026-10-16 | #65 | Ancestor of origin/main; tip = merged PR head |
| chore/approve-les-0008 | 5734a86 | 2026-10-15 | #61 | Ancestor of origin/main; tip = merged PR head |
| chore/approve-monetization-0062-0067 | e635489 | 2026-10-18 | #103 | Ancestor of origin/main; tip = merged PR head |
| chore/archive-0008-0010-0020 | 73562a3 | 2026-10-12 | #32 | Ancestor of origin/main; tip = merged PR head |
| chore/art-skills | 0cca8bd | 2026-10-16 | #63 | Ancestor of origin/main; tip = merged PR head |
| chore/brain-intake | 608f4c6 | 2026-10-15 | #58 | Ancestor of origin/main; tip = merged PR head |
| chore/claude-automations | ad70020 | 2026-10-15 | #57 | Ancestor of origin/main; tip = merged PR head |
| chore/close-approved-art-tasks | f64454d | 2026-10-18 | #114 | Ancestor of origin/main; tip = merged PR head |
| chore/close-superseded-art-tasks | 2102cb0 | 2026-10-18 | #113 | Ancestor of origin/main; tip = merged PR head |
| chore/codex-handoff-20261018 | cde4363 | 2026-10-18 | #115 | Ancestor of origin/main; tip = merged PR head |
| chore/dev-tooling | 93ae0ec | 2026-10-12 | #18 | Ancestor of origin/main; tip = merged PR head |
| chore/executor-usage-and-audit-scope | 5c4c7f4 | 2026-10-18 | #92 | Ancestor of origin/main; tip = merged PR head |
| chore/game-002-active-context | 531bc74 | 2026-10-11 | #3 | Ancestor of origin/main; tip = merged PR head |
| chore/game-002-m1-retro | 4ed2095 | 2026-10-11 | #11 | Ancestor of origin/main; tip = merged PR head |
| chore/knowledge-entry-points | 747b3ad | 2026-10-15 | #59 | Ancestor of origin/main; tip = merged PR head |
| chore/les-0008-link | a6c616e | 2026-10-15 | #62 | Ancestor of origin/main; tip = merged PR head |
| chore/light-task-model-default | 0790fef | 2026-10-18 | #87 | Ancestor of origin/main; tip = merged PR head |
| chore/lune-rules-specs | 7399cbf | 2026-10-12 | #19 | Ancestor of origin/main; tip = merged PR head |
| chore/mathshow-closeout | 338d589 | 2026-10-26 | #150 | Ancestor of origin/main; tip = merged PR head |
| chore/mathshow-intake | c1462e5 | 2026-10-25 | #122 | Ancestor of origin/main; tip = merged PR head |
| chore/mathshow-setup | 62011ff | 2026-10-25 | #121 | Ancestor of origin/main; tip = merged PR head |
| chore/memory-to-vault | 39bc0bc | 2026-10-15 | #60 | Ancestor of origin/main; tip = merged PR head |
| chore/menu-followup-tasks | 37fb988 | 2026-10-26 | #142 | Ancestor of origin/main; tip = merged PR head |
| chore/monetization-task-slices | f5d3361 | 2026-10-18 | #97 | Ancestor of origin/main; tip = merged PR head |
| chore/orchestrator-light-path | ea292e5 | 2026-10-18 | #96 | Ancestor of origin/main; tip = merged PR head |
| chore/propose-art-salvage | cf50316 | 2026-10-18 | #104 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-automations-2 | e3bf325 | 2026-10-17 | #75 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-evidence | 9b57e0a | 2026-10-17 | #69 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-feedback-experiment | ba6da7b | 2026-10-17 | #77 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-feedback-runtime | 7876c04 | 2026-10-17 | #85 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-first-development | 91f28b4 | 2026-10-11 | #1 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-review-anatomy | 5589efd | 2026-10-17 | #73 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-review-floors | 6119cd5 | 2026-10-17 | #74 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-review-session | 4407f6f | 2026-10-17 | #72 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-skills | b0704d3 | 2026-10-17 | #71 | Ancestor of origin/main; tip = merged PR head |
| chore/reference-tooling | e339e02 | 2026-10-17 | #68 | Ancestor of origin/main; tip = merged PR head |
| chore/references-20261017 | ffd92ed | 2026-10-17 | #76 | Ancestor of origin/main; tip = merged PR head |
| chore/repo-adoption-workflow | 3255358 | 2026-10-18 | #99 | Ancestor of origin/main; tip = merged PR head |
| chore/sequence-runner-docs | 58a3514 | 2026-10-17 | #80 | Ancestor of origin/main; tip = merged PR head |
| chore/sequence-runner-proposal | a320fce | 2026-10-17 | #78 | Ancestor of origin/main; tip = merged PR head |
| chore/serve-guard-followups | b12e4f5 | 2026-10-30 | #161 | Ancestor of origin/main; tip = merged PR head |
| chore/session-ownership | 04057f1 | 2026-10-18 | #101 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0021-post-merge | 08f02ab | 2026-10-12 | #31 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0024-outcome | 24f4142 | 2026-10-11 | #16 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0033-proposal | 648b18a | 2026-10-12 | #27 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0088-close | 51d7432 | 2026-10-25 | #124 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0089-close | 31adb7f | 2026-10-25 | #126 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0093-close | 3a8f8d9 | 2026-10-25 | #135 | Ancestor of origin/main; tip = merged PR head |
| chore/task-0104-close | acec5da | 2026-10-26 | #149 | Ancestor of origin/main; tip = merged PR head |
| chore/token-efficiency-process | b60df19 | 2026-10-18 | #86 | Ancestor of origin/main; tip = merged PR head |
| chore/vfx-dense-review | 481287a | 2026-10-17 | #70 | Ancestor of origin/main; tip = merged PR head |
| chore/video-prompt-variants | 23a3fbb | 2026-10-14 | #49 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-3d-monster-npc | f7b884c | 2026-10-14 | #51 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-index | 6adb3b3 | 2026-10-14 | #54 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-index-update | 3c3920c | 2026-10-14 | #56 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-mrwonder-batch | 79d24cf | 2026-10-14 | #55 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-notes-batch | b74b990 | 2026-10-14 | #48 | Ancestor of origin/main; tip = merged PR head |
| chore/video-research-recipe | 146fdbb | 2026-10-14 | #47 | Ancestor of origin/main; tip = merged PR head |
| chore/workflow-efficiency-20261018 | 47c362b | 2026-10-18 | #119, #117 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0011-Haunted-Scaffold-And-Player-Data | 5638c12 | 2026-10-11 | #2 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0012-Graveyard-And-Landmarks | 3a41941 | 2026-10-11 | #4 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0013-Monsters-And-Capture | c781088 | 2026-10-11 | #5 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0014-Return-Trip-And-Containment | b9a4ff0 | 2026-10-11 | #6 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0015-House-Tiers-And-Upgrades | bb738ae | 2026-10-11 | #7 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0016-Starter-Ghost-Train | 1a5b290 | 2026-10-11 | #8 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0017-Track-Editor | 0afc208 | 2026-10-11 | #9 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0018-Journal-Tutorial-And-Rare-Clue | bb24bdc | 2026-10-11 | #10 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0019-Persistence-And-Rejoin-Test | 8bf819c | 2026-10-12 | #29 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0021-Anti-Cheat-Hardening | 395e018 | 2026-10-12 | #30 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0022-M1-Polish | f28c092 | 2026-10-11 | #12 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0023-Round-20-Design-Changes | 77661ca | 2026-10-11 | #14 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0025-Clue-Hunting-Removal | 9a759f8 | 2026-10-12 | #17 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0026-Radial-Plot-Layout | 7272082 | 2026-10-12 | #20 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0027-Habitat-Modules-And-Blockouts | bec9de3 | 2026-10-12 | #21 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0028-Cemetery-Vignette-And-Atmosphere | 154b9ff | 2026-10-12 | #22 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0029-Habitat-Rotation | bb8c71a | 2026-10-12 | #23 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0030-House-And-Train-Presentation | 5382f20 | 2026-10-12 | #24 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0031-Failed-Capture-Retaliation | 75cd7b1 | 2026-10-12 | #25 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0032-Retaliation-Hardening | 3443397 | 2026-10-12 | #26 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0033-Retaliation-Begin-Cleanup | a690fb5 | 2026-10-12 | #28 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0041-Interactive-Haunted-Trees | d68b5d9 | 2026-10-13 | #45 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0053-Sequence-Runner | 7df964c | 2026-10-17 | #79 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0054-Rare-Capture-Finisher | e29b2f5 | 2026-10-17 | #81 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0055-Rare-Capture-Hookup | b2c1d77 | 2026-10-17 | #84 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0056-Studio-Test-Pads | a299edf | 2026-10-17 | #83, #82 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0057-Overview-Evidence-Sync | af92655 | 2026-10-18 | #89 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0058-SetExhibit-Input-Rules | dd648cf | 2026-10-18 | #91 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard | a0d3b24 | 2026-10-18 | #94 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0060-Monetization-Persistence-Schema | 2dd2c32 | 2026-10-18 | #98 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0061-Shop-And-Owned-Inventory-UI | 0c75063 | 2026-10-18 | #102 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0062-Ghost-Skins-And-Auras-Equipment | 0ccbb21 | 2026-10-18 | #106 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0063-Capture-Effects-Equipment | fc39614 | 2026-10-18 | #107 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0064-Mansion-Themes | ccefbb7 | 2026-10-18 | #108 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0065-Exterior-Decoration-Editor | f5f8d1f | 2026-10-18 | #110 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0066-Journal-Collection-Rewards | dd4515f | 2026-10-18 | #109 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0067-Coin-Purchases | c1e803d | 2026-10-18 | #111 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0068-Robux-Purchase-Research-And-ADR | 7e5bfe2 | 2026-10-18 | #112 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0069-Art-Salvage-From-Overhaul-Branch | 92652e3 | 2026-10-18 | #105 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0088-mathshow-scaffold | 68ddc96 | 2026-10-25 | #123 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0089-mathshow-problemrules | 705afed | 2026-10-25 | #125 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0093-MathShow-Hud | 418d066 | 2026-10-25 | #134 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0097-MathShow-HUD-Shards | 98a8ad9 | 2026-10-26 | #140 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0098-MathShow-Menu-Shell | 370f6e3 | 2026-10-26 | #141 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0099-MathShow-Profile-Store-And-Settings-Save | 74bfc0d | 2026-10-26 | #143 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0100-MathShow-Group-Join-And-Watching-Banner | 9b1ff28 | 2026-10-26 | #144 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder | d20c98f | 2026-10-26 | #145 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0102-MathShow-Skill-Test-Play-And-Result | bc93394 | 2026-10-26 | #146 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0103-MathShow-Blitz | e2d6312 | 2026-10-26 | #147 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0104-MathShow-VS-Matchmaking-And-Flow | 2a9a38f | 2026-10-26 | #148 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0110-studio-sync | c553954 | 2026-10-30 | #159 | Ancestor of origin/main; tip = merged PR head |
| task/TASK-0111-identity-gate | 265f8f8 | 2026-10-31 | #160 | Ancestor of origin/main; tip = merged PR head |

## Class S

| Name | SHA | Date | PR# | Reason |
|---|---|---|---|---|
| chore/video-research-3d-models | 92b86ba | 2026-10-14 | #50 | Merged PR #50; scoped diff empty (1 file): `git diff origin/main 92b86ba -- "02 Research/RSH-20261014-Blender-To-Roblox-Animation-Import-Export-Video.md"` |

## Class U

Never proposed.

| Name | SHA | Date | PR# | Reason |
|---|---|---|---|---|
| chore/art-automation | 1887dd8 | 2026-10-16 | #64 | Merged PR, but scoped diff lists 53 of 53 files; 22 commits ahead |
| chore/universal-modder-evaluation | 7c7b864 | 2026-10-13 | — | No PR; 3 commits ahead |
| task/TASK-0024-FullLoop-Landmark-Flake | f701276 | 2026-10-11 | #15 | Merged PR, but scoped diff lists 3 of 4 files; 1 commit ahead |

## Class X

Never proposed. Every row is in the Closeout kept-unmerged table of `CLEANUP-PLAN.md`, and all of them would otherwise be class U.

| Name | SHA | Date | PR# | Reason |
|---|---|---|---|---|
| chore/archive-task-0008 | cb960a1 | 2026-10-11 | #13 | Closeout kept-unmerged table |
| chore/creature-pipeline | 121c15c | 2026-10-16 | #66 | Closeout kept-unmerged table |
| chore/game-003-h01-checks | 560528a | 2026-11-01 | — | Closeout kept-unmerged table |
| chore/game-003-launch-audit | d165494 | 2026-10-19 | — | Closeout kept-unmerged table |
| chore/game-003-luna-prep | fee53dc | 2026-10-19 | — | Closeout kept-unmerged table |
| chore/git-safety | 503746b | 2026-10-11 | — | Closeout kept-unmerged table |
| chore/individual-media-assessments | 4ba838a | 2026-10-15 | — | Closeout kept-unmerged table |
| chore/model-approval-workflow | 612231a | 2026-10-13 | — | Closeout kept-unmerged table |
| chore/orchestrator-ownership | 7d3f36d | 2026-10-13 | — | Closeout kept-unmerged table |
| chore/repo-integration-notes | 4d1491b | 2026-10-17 | — | Closeout kept-unmerged table |
| chore/shared-model-viewer | 4155c77 | 2026-10-18 | — | Closeout kept-unmerged table |
| chore/vault-navigation | 8d6955d | 2026-10-14 | — | Closeout kept-unmerged table |
| chore/video-workflow-adoption | 1e9ee4f | 2026-10-13 | — | Closeout kept-unmerged table |
| task/TASK-0008-Prototype-Telemetry | af72448 | 2026-10-10 | — | Closeout kept-unmerged table |
| task/TASK-0040-Audio-Pass | b9eaed9 | 2026-10-14 | — | Closeout kept-unmerged table |
| task/TASK-0043-Wisp-Revision | 5ecb890 | 2026-10-16 | — | Closeout kept-unmerged table |
| task/TASK-0046-Mansion-Plot-And-Train-Art | 3b740ec | 2026-11-01 | — | Closeout kept-unmerged table |
| worktree-agent-a43df52601336427d | af72448 | 2026-10-10 | — | Closeout kept-unmerged table |

## Proposed batches

Drawn only from M and S. Each is approved separately, with a limit of 40 branches.

| Batch | Count | Source | Range |
|---|---|---|---|
| B-R1-1 | 40 | M | chore/TASK-0057-proposal … chore/reference-skills |
| B-R1-2 | 40 | M | chore/reference-tooling … task/TASK-0028-Cemetery-Vignette-And-Atmosphere |
| B-R1-3 | 35 | M | task/TASK-0029-Habitat-Rotation … task/TASK-0111-identity-gate |
| B-R1-4 | 1 | M | task/TASK-0110-studio-sync |
| B-R1-5 | 1 | S | chore/video-research-3d-models. **Held, not deleted** |

Cross-check: 117 names, no duplicates, and none is in class U, class X or the 18-row Closeout table.

### B-R1-1

```text
chore/TASK-0057-proposal
chore/TASK-0058-proposal
chore/TASK-0059-proposal
chore/TASK-0059-state
chore/TASK-0060-approvals
chore/anim-pipeline-pointer
chore/approve-les-0008
chore/approve-monetization-0062-0067
chore/archive-0008-0010-0020
chore/art-skills
chore/brain-intake
chore/claude-automations
chore/close-approved-art-tasks
chore/close-superseded-art-tasks
chore/codex-handoff-20261018
chore/dev-tooling
chore/executor-usage-and-audit-scope
chore/game-002-active-context
chore/game-002-m1-retro
chore/knowledge-entry-points
chore/les-0008-link
chore/light-task-model-default
chore/lune-rules-specs
chore/mathshow-closeout
chore/mathshow-intake
chore/mathshow-setup
chore/memory-to-vault
chore/menu-followup-tasks
chore/monetization-task-slices
chore/orchestrator-light-path
chore/propose-art-salvage
chore/reference-automations-2
chore/reference-evidence
chore/reference-feedback-experiment
chore/reference-feedback-runtime
chore/reference-first-development
chore/reference-review-anatomy
chore/reference-review-floors
chore/reference-review-session
chore/reference-skills
```

### B-R1-2

```text
chore/reference-tooling
chore/references-20261017
chore/repo-adoption-workflow
chore/sequence-runner-docs
chore/sequence-runner-proposal
chore/serve-guard-followups
chore/session-ownership
chore/task-0021-post-merge
chore/task-0024-outcome
chore/task-0033-proposal
chore/task-0088-close
chore/task-0089-close
chore/task-0093-close
chore/task-0104-close
chore/token-efficiency-process
chore/vfx-dense-review
chore/video-prompt-variants
chore/video-research-3d-monster-npc
chore/video-research-index
chore/video-research-index-update
chore/video-research-mrwonder-batch
chore/video-research-notes-batch
chore/video-research-recipe
chore/workflow-efficiency-20261018
task/TASK-0011-Haunted-Scaffold-And-Player-Data
task/TASK-0012-Graveyard-And-Landmarks
task/TASK-0013-Monsters-And-Capture
task/TASK-0014-Return-Trip-And-Containment
task/TASK-0015-House-Tiers-And-Upgrades
task/TASK-0016-Starter-Ghost-Train
task/TASK-0017-Track-Editor
task/TASK-0018-Journal-Tutorial-And-Rare-Clue
task/TASK-0019-Persistence-And-Rejoin-Test
task/TASK-0021-Anti-Cheat-Hardening
task/TASK-0022-M1-Polish
task/TASK-0023-Round-20-Design-Changes
task/TASK-0025-Clue-Hunting-Removal
task/TASK-0026-Radial-Plot-Layout
task/TASK-0027-Habitat-Modules-And-Blockouts
task/TASK-0028-Cemetery-Vignette-And-Atmosphere
```

### B-R1-3

```text
task/TASK-0029-Habitat-Rotation
task/TASK-0030-House-And-Train-Presentation
task/TASK-0031-Failed-Capture-Retaliation
task/TASK-0032-Retaliation-Hardening
task/TASK-0033-Retaliation-Begin-Cleanup
task/TASK-0041-Interactive-Haunted-Trees
task/TASK-0053-Sequence-Runner
task/TASK-0054-Rare-Capture-Finisher
task/TASK-0055-Rare-Capture-Hookup
task/TASK-0056-Studio-Test-Pads
task/TASK-0057-Overview-Evidence-Sync
task/TASK-0058-SetExhibit-Input-Rules
task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard
task/TASK-0060-Monetization-Persistence-Schema
task/TASK-0061-Shop-And-Owned-Inventory-UI
task/TASK-0062-Ghost-Skins-And-Auras-Equipment
task/TASK-0063-Capture-Effects-Equipment
task/TASK-0064-Mansion-Themes
task/TASK-0065-Exterior-Decoration-Editor
task/TASK-0066-Journal-Collection-Rewards
task/TASK-0067-Coin-Purchases
task/TASK-0068-Robux-Purchase-Research-And-ADR
task/TASK-0069-Art-Salvage-From-Overhaul-Branch
task/TASK-0088-mathshow-scaffold
task/TASK-0089-mathshow-problemrules
task/TASK-0093-MathShow-Hud
task/TASK-0097-MathShow-HUD-Shards
task/TASK-0098-MathShow-Menu-Shell
task/TASK-0099-MathShow-Profile-Store-And-Settings-Save
task/TASK-0100-MathShow-Group-Join-And-Watching-Banner
task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder
task/TASK-0102-MathShow-Skill-Test-Play-And-Result
task/TASK-0103-MathShow-Blitz
task/TASK-0104-MathShow-VS-Matchmaking-And-Flow
task/TASK-0111-identity-gate
```

### B-R1-4

```text
task/TASK-0110-studio-sync
```

### B-R1-5

**Held by jg's row R2.** kept: tip 92b86ba not on any other ref

```text
chore/video-research-3d-models
```

## Restore

Any listed branch is restored with:

```bash
git push origin <SHA>:refs/heads/<name>
```

Use the full SHA below. `git push --dry-run` accepted all 138 refspecs on 2026-11-01, using temporary names so that no ref was written.

The commit must exist in the clone doing the push. M tips stay reachable from `main`. `92b86ba` (B-R1-5) would be held only by the main checkout's object store once its remote-tracking ref is gone, and Git can eventually garbage-collect it. Before deleting that branch, keep a tag or bundle of it if the commit should survive.

```text
git push origin 647eb0ee80cb792e62b75ba8e8c9af7cfb1b06f8:refs/heads/chore/TASK-0057-proposal
git push origin 70a49af29b88a8596c9bbd6c331c8b9623237a17:refs/heads/chore/TASK-0058-proposal
git push origin 421bea184648721c7b3eb2b7be94fdbbad992ff1:refs/heads/chore/TASK-0059-proposal
git push origin 6018c34e0af7f241ec5247fdedd4be3a09deb544:refs/heads/chore/TASK-0059-state
git push origin 38442453a40df0bf4c42fe4ad74d53def823aed1:refs/heads/chore/TASK-0060-approvals
git push origin 43736d4981e255bc31d1907fa4891a0cc22c6fcb:refs/heads/chore/anim-pipeline-pointer
git push origin 5734a86dbd9661267a822c506c05be4693e2223c:refs/heads/chore/approve-les-0008
git push origin e6354893f25c70972aa79e34dd933d867b42143b:refs/heads/chore/approve-monetization-0062-0067
git push origin 73562a3832eae5fe9496f2bb56b6be8961292014:refs/heads/chore/archive-0008-0010-0020
git push origin cb960a1a2018e8f5050bb2e6f52c0b9bf6cf202b:refs/heads/chore/archive-task-0008
git push origin 1887dd8ae81bc917ff3c4ee58f216bd0e4316e18:refs/heads/chore/art-automation
git push origin 0cca8bd07f13f21fe37c4e26754e10616f940e27:refs/heads/chore/art-skills
git push origin 608f4c6c363f85949908b228c4128f4596b0e413:refs/heads/chore/brain-intake
git push origin ad700203f1eace5437f92d5577a815c9512e1fad:refs/heads/chore/claude-automations
git push origin f64454d13491c258b4e6aee17a98b2a79024bcaf:refs/heads/chore/close-approved-art-tasks
git push origin 2102cb05bd45edcc720b30ce8d60a94b55bee685:refs/heads/chore/close-superseded-art-tasks
git push origin cde4363d47110ab8ddeb13c3af2def0174df4e73:refs/heads/chore/codex-handoff-20261018
git push origin 121c15c2071563d0bf70cb746cd0e8d10fe25bd2:refs/heads/chore/creature-pipeline
git push origin 93ae0ecb69cb1180023ef14ef389c2d0e0e8788b:refs/heads/chore/dev-tooling
git push origin 5c4c7f4eadcdd87ecf8d4937aca06b122673ca32:refs/heads/chore/executor-usage-and-audit-scope
git push origin 531bc74e3c63b162d7cf26bc93292cc40512bcfd:refs/heads/chore/game-002-active-context
git push origin 4ed2095944979d17b82eb61a3972eaec80c7ff76:refs/heads/chore/game-002-m1-retro
git push origin 560528a50ef809a5fdb196ee8c4a9a95d33251ce:refs/heads/chore/game-003-h01-checks
git push origin d165494145b633fa7edb17acef110c1da8d66f4d:refs/heads/chore/game-003-launch-audit
git push origin fee53dcaad6da3c88411b320267089245083c214:refs/heads/chore/game-003-luna-prep
git push origin 503746b467616f0307ef449b98db34eee6fe0c5a:refs/heads/chore/git-safety
git push origin 4ba838a80c00f1a6d69919460fbe664d6398d805:refs/heads/chore/individual-media-assessments
git push origin 747b3ad226d0b47f5563d8e49c0b464a6529c9ef:refs/heads/chore/knowledge-entry-points
git push origin a6c616e25a5715e45f3b9779f814000a7153bb86:refs/heads/chore/les-0008-link
git push origin 0790fef53e096d8b8f25a96d544d9d3358dfb7e7:refs/heads/chore/light-task-model-default
git push origin 7399cbfd362347e8c9a0f6cf7e7a575819a637bb:refs/heads/chore/lune-rules-specs
git push origin 338d589d6223c246617a800b99a505c7daf6c960:refs/heads/chore/mathshow-closeout
git push origin c1462e5e0373ace3af97145a7de63a5bb87998d5:refs/heads/chore/mathshow-intake
git push origin 62011ff05f69bda79f6b61b561c8a727343e29c5:refs/heads/chore/mathshow-setup
git push origin 39bc0bc4a16f7fca8e8bacbbe4b2de9dc81d49a2:refs/heads/chore/memory-to-vault
git push origin 37fb988b922a89cc6b302e49db0ee47bd3837f78:refs/heads/chore/menu-followup-tasks
git push origin 612231a5e4d43b3382a8b318a524f68f39b669b1:refs/heads/chore/model-approval-workflow
git push origin f5d336181255853f8ef293e2e33e5cd8cd104d08:refs/heads/chore/monetization-task-slices
git push origin ea292e593f2c0e6c3d546b98fde71d591a1fd907:refs/heads/chore/orchestrator-light-path
git push origin 7d3f36d4f2518ea8498c1ef800d4610e7d2fd8fe:refs/heads/chore/orchestrator-ownership
git push origin cf50316c1c57639edc77b6e8f917cd89b1abbe36:refs/heads/chore/propose-art-salvage
git push origin e3bf32520f370e8aaedc603c0c8602474bae0282:refs/heads/chore/reference-automations-2
git push origin 9b57e0ac31289cf2d68cd43dc75d27a88cc3435d:refs/heads/chore/reference-evidence
git push origin ba6da7b39d1f0c59ca73d1012f29d47c088ed69e:refs/heads/chore/reference-feedback-experiment
git push origin 7876c0480b80d0897ddf4373655893e9833e355c:refs/heads/chore/reference-feedback-runtime
git push origin 91f28b43c58248e8121b06bbd611c137f04d4bb9:refs/heads/chore/reference-first-development
git push origin 5589efd9a416e7c24cf40ee239a3d956b57adb40:refs/heads/chore/reference-review-anatomy
git push origin 6119cd5a8f857b2d9045de01ff30e630070acbfd:refs/heads/chore/reference-review-floors
git push origin 4407f6fd0e6b141ed246bf09032bf038efd91f26:refs/heads/chore/reference-review-session
git push origin b0704d3c8801a5cfbbf09009f6ddbf05ce5982c3:refs/heads/chore/reference-skills
git push origin e339e027585fbea5f1d17fabf29e4249cc9e3050:refs/heads/chore/reference-tooling
git push origin ffd92edfdb90d2c92d3ef8da88aa75e12de76fcf:refs/heads/chore/references-20261017
git push origin 32553584da84cc366ec4e76b5d7c13202e7f5e5d:refs/heads/chore/repo-adoption-workflow
git push origin 4d1491b9548c23a3e7171325cec42f505c0145e4:refs/heads/chore/repo-integration-notes
git push origin 58a3514eb9be5d3220d53a38485faece5a159793:refs/heads/chore/sequence-runner-docs
git push origin a320fce2d69dacafac9ac849942fcdd55f6bef8a:refs/heads/chore/sequence-runner-proposal
git push origin b12e4f59b99878b9c3585dbeff85b07b6039f151:refs/heads/chore/serve-guard-followups
git push origin 04057f1ae8460d914bcb78b8427297816451265f:refs/heads/chore/session-ownership
git push origin 4155c778d073ea7bee79bb0cc7e3d5891989e607:refs/heads/chore/shared-model-viewer
git push origin 08f02ab708e0b7b765a4ffa0561ac1ff7f4dbc77:refs/heads/chore/task-0021-post-merge
git push origin 24f4142287cfb98abd6595f549c62a66fb9db8fc:refs/heads/chore/task-0024-outcome
git push origin 648b18a01dd5299da523dd375c887e803cf473a5:refs/heads/chore/task-0033-proposal
git push origin 51d74323b717368325a9f23d11ced2bd487a48ea:refs/heads/chore/task-0088-close
git push origin 31adb7f23f67d089d0c4fe211497198aec5c99cf:refs/heads/chore/task-0089-close
git push origin 3a8f8d978ce3d8d80a1100e8295ad1f7b5515d96:refs/heads/chore/task-0093-close
git push origin acec5da5e9a04fb84992193d6d74c81a0ae15127:refs/heads/chore/task-0104-close
git push origin b60df19b285ae7be14f41365716d34e6c9be4bd5:refs/heads/chore/token-efficiency-process
git push origin 7c7b8648870c10f78e6ec5efe3657a6a3ffb43d5:refs/heads/chore/universal-modder-evaluation
git push origin 8d6955da391e4cb4a103fce9ccdab7fd2c24d1c1:refs/heads/chore/vault-navigation
git push origin 481287ad28eae9b2e84fc22d1378a54aee481df0:refs/heads/chore/vfx-dense-review
git push origin 23a3fbb52040f48d7b76519d47500c3f94d5ee76:refs/heads/chore/video-prompt-variants
git push origin 92b86ba9fb7fa2fceac0a6c244aba9de5f30aa9e:refs/heads/chore/video-research-3d-models
git push origin f7b884c8f0e46c95eee0e22e4471e987606a0fdd:refs/heads/chore/video-research-3d-monster-npc
git push origin 6adb3b3db2ba8fe305fa8f514ddb6e11408fef84:refs/heads/chore/video-research-index
git push origin 3c3920cf44d40eadcdddf07cc45fedb97eeb047e:refs/heads/chore/video-research-index-update
git push origin 79d24cf37ba691f7bce9a1f16d9ad839e87e7699:refs/heads/chore/video-research-mrwonder-batch
git push origin b74b990a71a712b64ece46bb14b663ee4a9ce034:refs/heads/chore/video-research-notes-batch
git push origin 146fdbb0c2b27eb3d420cd5ba2a3bd1bae5b043c:refs/heads/chore/video-research-recipe
git push origin 1e9ee4ffd81703de905b263c90436fd0f91e042d:refs/heads/chore/video-workflow-adoption
git push origin 47c362b2b60033838f2379395ed13227aa98bdee:refs/heads/chore/workflow-efficiency-20261018
git push origin af7244822d071f38ed8e80204453a52aad69f244:refs/heads/task/TASK-0008-Prototype-Telemetry
git push origin 5638c12dd8fbe88d1c82df20d576ec6bff5cb773:refs/heads/task/TASK-0011-Haunted-Scaffold-And-Player-Data
git push origin 3a4194136a575500d0714f8c26e75f56d6e0fa37:refs/heads/task/TASK-0012-Graveyard-And-Landmarks
git push origin c781088c462da46f73e9602db9202f7f5deb92bd:refs/heads/task/TASK-0013-Monsters-And-Capture
git push origin b9a4ff0d9cc0a1cd258dfebfcf9d4ee0e41aa658:refs/heads/task/TASK-0014-Return-Trip-And-Containment
git push origin bb738ae3bde50201ee1f5208c0b883bfd011ae8b:refs/heads/task/TASK-0015-House-Tiers-And-Upgrades
git push origin 1a5b29062a6726ad5b954a9a99fe6c9d2e81e01a:refs/heads/task/TASK-0016-Starter-Ghost-Train
git push origin 0afc20837f4cd006f24f13601788632092b79086:refs/heads/task/TASK-0017-Track-Editor
git push origin bb24bdc585653efea5c17d16ea840e0bcd615d67:refs/heads/task/TASK-0018-Journal-Tutorial-And-Rare-Clue
git push origin 8bf819cb0807f80ea0c37ab2fd949d7c23a5456d:refs/heads/task/TASK-0019-Persistence-And-Rejoin-Test
git push origin 395e01865fd3567969aa20b9d72cf82df343b508:refs/heads/task/TASK-0021-Anti-Cheat-Hardening
git push origin f28c09265326c63d748a928c3d30fe27f3f8146c:refs/heads/task/TASK-0022-M1-Polish
git push origin 77661ca8b04d858ba22b5534bb593d93cf95827c:refs/heads/task/TASK-0023-Round-20-Design-Changes
git push origin f701276a21e466c8bf31634c475a0c6589f95ddf:refs/heads/task/TASK-0024-FullLoop-Landmark-Flake
git push origin 9a759f825c0ea7fb27b87b4ea135fbee8ddfeb65:refs/heads/task/TASK-0025-Clue-Hunting-Removal
git push origin 7272082cba11614871cd5823c3d7d181deeace66:refs/heads/task/TASK-0026-Radial-Plot-Layout
git push origin bec9de3af47ad2db5f7f072c3bb9bda17113dae6:refs/heads/task/TASK-0027-Habitat-Modules-And-Blockouts
git push origin 154b9ffa7c594e60ff4c293b87c34795e46d9881:refs/heads/task/TASK-0028-Cemetery-Vignette-And-Atmosphere
git push origin bb8c71ad92f52ee7f278b44bdba22a08cdbe8da0:refs/heads/task/TASK-0029-Habitat-Rotation
git push origin 5382f20dd6a34a3c3e633e26e3ef0c82b9ceb2eb:refs/heads/task/TASK-0030-House-And-Train-Presentation
git push origin 75cd7b172bcda9b523d6738f2a621f197343823e:refs/heads/task/TASK-0031-Failed-Capture-Retaliation
git push origin 34433972772a047787189aeea2f5bc02bb253080:refs/heads/task/TASK-0032-Retaliation-Hardening
git push origin a690fb51e1706da65e134915837a58973ab7ceed:refs/heads/task/TASK-0033-Retaliation-Begin-Cleanup
git push origin b9eaed97e8014104f679a0d319d291846d4e1238:refs/heads/task/TASK-0040-Audio-Pass
git push origin d68b5d9b70af8a6f9de4dc699a15715564b01437:refs/heads/task/TASK-0041-Interactive-Haunted-Trees
git push origin 5ecb890905fd8a957456ccb1cc76aab3e20b6aba:refs/heads/task/TASK-0043-Wisp-Revision
git push origin 3b740ec52ccba7f82da21b05bf4ceefe04a17f1b:refs/heads/task/TASK-0046-Mansion-Plot-And-Train-Art
git push origin 7df964c8e65cfb24dadbd9dfe37900385d88d2f9:refs/heads/task/TASK-0053-Sequence-Runner
git push origin e29b2f55b3ed2221b570dc8f5c75e906b6af3ae7:refs/heads/task/TASK-0054-Rare-Capture-Finisher
git push origin b2c1d7759a25848ff2132aace64299adc226385b:refs/heads/task/TASK-0055-Rare-Capture-Hookup
git push origin a299edf2ef34fd9bdf670e2024152a326938a2a2:refs/heads/task/TASK-0056-Studio-Test-Pads
git push origin af926552e8e43b07c21f0b8e746340d23886773e:refs/heads/task/TASK-0057-Overview-Evidence-Sync
git push origin dd648cff64d59f40e04afdd9c6d1e47d40f59719:refs/heads/task/TASK-0058-SetExhibit-Input-Rules
git push origin a0d3b2433ef053d476e752be30157be9dec2dc94:refs/heads/task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard
git push origin 2dd2c32ed8f981749194780718f3ac3bda414511:refs/heads/task/TASK-0060-Monetization-Persistence-Schema
git push origin 0c7506360860e27d234f093cc6bda96419bfd7ad:refs/heads/task/TASK-0061-Shop-And-Owned-Inventory-UI
git push origin 0ccbb218876b3c2e8cc71351704e61b83be126c4:refs/heads/task/TASK-0062-Ghost-Skins-And-Auras-Equipment
git push origin fc396142b94d953a223bf7d64f0774a4116f3350:refs/heads/task/TASK-0063-Capture-Effects-Equipment
git push origin ccefbb7af2c0ac9e1d224714865ffe1d4c83cead:refs/heads/task/TASK-0064-Mansion-Themes
git push origin f5f8d1f8f7a7ba72a39cfc9b0c5f0f64aabb77d0:refs/heads/task/TASK-0065-Exterior-Decoration-Editor
git push origin dd4515fa86b1ed09345bd1a6a8bdf9eb83bf2448:refs/heads/task/TASK-0066-Journal-Collection-Rewards
git push origin c1e803deedeb7fb1246317a86fb7c722865115e7:refs/heads/task/TASK-0067-Coin-Purchases
git push origin 7e5bfe270f37cdc527c68f747cb43a1f571463ce:refs/heads/task/TASK-0068-Robux-Purchase-Research-And-ADR
git push origin 92652e381b7b5fabadc19d097f7f85ba41ddbb03:refs/heads/task/TASK-0069-Art-Salvage-From-Overhaul-Branch
git push origin 68ddc968e8fa8ccc3439bd7a0db1730602aa5a18:refs/heads/task/TASK-0088-mathshow-scaffold
git push origin 705afed5305ae74b4c279c1e3566ca12fbf13d85:refs/heads/task/TASK-0089-mathshow-problemrules
git push origin 418d0662a5cef4aed13bdbd77e52735d647e3e86:refs/heads/task/TASK-0093-MathShow-Hud
git push origin 98a8ad97ed54ee4e6a73c76e28b5c344a42cf96a:refs/heads/task/TASK-0097-MathShow-HUD-Shards
git push origin 370f6e3c20efcb6cc502f05f1de2abd11ba8733e:refs/heads/task/TASK-0098-MathShow-Menu-Shell
git push origin 74bfc0d9dd6538a2ef8217d1abb7e4a756e365d3:refs/heads/task/TASK-0099-MathShow-Profile-Store-And-Settings-Save
git push origin 9b1ff288fc462fd692940b43ee1d29f97c08d014:refs/heads/task/TASK-0100-MathShow-Group-Join-And-Watching-Banner
git push origin d20c98fc3fe3be359957028f2d59436e4265bca1:refs/heads/task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder
git push origin bc933945ab31654afdef55484c4d18050fe2ec07:refs/heads/task/TASK-0102-MathShow-Skill-Test-Play-And-Result
git push origin e2d6312e2f4baa6b9f1de70af2da989ce3b21437:refs/heads/task/TASK-0103-MathShow-Blitz
git push origin 2a9a38f823cb3178ff38997664b1ab045fc38063:refs/heads/task/TASK-0104-MathShow-VS-Matchmaking-And-Flow
git push origin c5539549e50be80a8a1faec1ea1dc6c7065da027:refs/heads/task/TASK-0110-studio-sync
git push origin 265f8f8a12a7ce578d7c67b3437a15eeb8bb3784:refs/heads/task/TASK-0111-identity-gate
git push origin af7244822d071f38ed8e80204453a52aad69f244:refs/heads/worktree-agent-a43df52601336427d
```

## Results

Executed 2026-11-01 under jg's approved rows for PR #174. Before each batch, each tip was re-checked against this manifest and against `origin/main` ancestry. After each batch, `git ls-remote --heads origin` was re-read.

| Batch | Listed | Deleted | Skipped | Heads after |
|---|---|---|---|---|
| B-R1-1 | 40 | 40 | 0 | 100 |
| B-R1-2 | 40 | 40 | 0 | 60 |
| B-R1-3 | 35 | 35 | 0 | 25 |
| B-R1-4 | 1 | 1 | 0 | 24 |
| B-R1-5 | 1 | 0 | Held | 24 |

Totals: 116 deleted, 0 skipped, 1 held. Origin has 24 heads as this is written; removing `chore/r1-remote-sweep` after merge leaves 23: `main`, 18 X, 3 U and the held branch.

## U/S disagreement (row R3)

Phase 3 recorded "PR merged, scoped diff 0 lines" for both branches below and force-deleted them locally. This manifest classed both as U. Both origin tips equal the deleted local SHAs (`1887dd8`, `f701276`), so the branches did not move. The results differ, and the log records no command, so the Phase 3 check cannot be replayed.

- **`chore/art-automation`: U is correct, and the Phase 3 entry is wrong.** PR #64 merged into `task/TASK-0043-Wisp-Revision`, not `main`, and its merge commit `d484019` is not on `main`. None of its 22 commits has a patch-equivalent on `main`, and the PR's 3 files are absent from `main`. The commits survive on this branch, `chore/creature-pipeline` and `task/TASK-0043-Wisp-Revision`. The S rule here does not check a PR's base, but the non-empty diff still failed it.
- **`task/TASK-0024-FullLoop-Landmark-Flake`: the work is on `main`, and U is a strict-rule result.** PR #15 merged head `484b5c9`. The tip `f701276` came one commit later, and `git cherry` finds it patch-equivalent to `24f4142` on `main`. The scoped diff is non-empty only because `main` moved on: `project-state.json` and the Overview note changed later, and `tasks/queue.json` was later removed. The S rule compares with current `main`, so later edits count against a branch; a patch-equivalence check does not.

Both remote branches are kept.
