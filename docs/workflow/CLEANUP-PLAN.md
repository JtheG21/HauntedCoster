# Repo cleanup plan (chore/repo-cleanup)

Phase 0 inventory, 2026-10-31. Snapshot: `main` at 80e39b8. Read-only: nothing has been removed, pruned, deleted or moved.
Approve rows by ID (for example "W1–W7, P1, P2, P4, P5, P7, P8, P10, U2, U3, U4, U7, U8"). Rows not approved stay as they are.

## Rojo

- No rojo process is running. `pgrep -fl rojo` is empty, nothing listens on the default port 34872, and `lsof -nP -iTCP -sTCP:LISTEN | grep -ic rojo` returns 0.
- So acceptance criterion 3 (no worktree serving rojo) holds now. It needs re-checking after Studio is reconnected.
- Studio is open (RobloxStudio, pid 78217). Not touched in this phase.

## How the rows were classified

- **Merged** means an ancestor of `main` (`git merge-base --is-ancestor`). This is the test `git branch -d` uses. An ancestor branch has zero commits that `main` lacks.
- **PR merged** means the branch name matches a merged PR (`gh pr list --state merged`, 155 PRs). A squash-merged branch is not an ancestor, so `git branch -d` refuses it. Those branches are kept, and `-D` is out of scope.
- **Dirty** means `git status --porcelain`, with untracked files counted.
- The first pass called two prunable paths "0 dirty". They are not git checkouts (see D1 and D2), so that count was wrong.

## Worktrees to remove (phase 1 candidates)

Each row runs `git -C <main> worktree remove <path>`, with no `--force`. If git refuses, stop and report. Then `git branch -d <branch>`.

| ID | Path | Branch | Merged | Dirty | Process | Proposed action |
|---|---|---|---|---|---|---|
| W1 | ~/Desktop/Rg1-worktrees/executor-usage | chore/executor-usage-and-audit-scope | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W2 | ~/Desktop/Rg1-worktrees/serve-guard | chore/serve-guard-followups | yes, PR merged (#161) | 0 | none | Remove worktree, delete branch |
| W3 | ~/Desktop/Rg1-worktrees/task-0055 | task/TASK-0055-Rare-Capture-Hookup | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W4 | ~/Desktop/Rg1-worktrees/task-0056 | task/TASK-0056-Studio-Test-Pads | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W5 | ~/Desktop/Rg1-worktrees/task-0089-close | chore/task-0089-close | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W6 | ~/Desktop/Rg1-worktrees/task-0097 | task/TASK-0097-MathShow-HUD-Shards | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W7 | ~/Desktop/Rg1-worktrees/workflow-efficiency | chore/workflow-efficiency-20261018 | yes, PR merged | 0 | none | Remove worktree, delete branch |
| W8 | ~/.codex/worktrees/hike-or-die-gate-1/Rg1 | detached at 8da812f | commit is an ancestor of main | 0 | none | Remove worktree (no branch). Codex created it, so confirm first |
| W9 | ~/Desktop/Rg1-worktrees/task-0110 | task/TASK-0111-identity-gate | yes, PR #160 | 0 | **HOLD**: zsh pid 64782 has its cwd inside; com.apple pid 72596 has docs/design/hud/HudSpec.json open | Close that shell, then remove worktree and delete branch |
| W10 | ~/Desktop/Rg1-worktrees/chore-mathshow-intake | chore/mathshow-intake | yes, PR merged | 1 untracked: `.codex/` | none | **HOLD** until U1 is decided. Then remove worktree and delete branch |

## Worktrees to keep

| ID | Path | Branch | Merged | Dirty | Reason |
|---|---|---|---|---|---|
| K1 | ~/Desktop/Rg1-worktrees/art-automation | chore/art-automation | no, 22 commits ahead; PR head name is merged (probably squash) | 0 | Unmerged by git's test. Check the PR before anything else |
| K2 | ~/Desktop/Rg1-worktrees/creature-pipeline | chore/creature-pipeline | no, 25 ahead, no PR | 0 | Unmerged work |
| K3 | ~/Desktop/Rg1-worktrees/TASK-0040 | task/TASK-0040-Audio-Pass | no, 8 ahead, no PR | 0 | Unmerged work |
| K4 | ~/Desktop/Rg1-worktrees/wisp | task/TASK-0043-Wisp-Revision | no, 24 ahead, no PR | 0 | Unmerged work |
| K5 | ~/Desktop/Rg1-worktrees/overhaul | task/TASK-0046-Mansion-Plot-And-Train-Art | no, 4 ahead, no PR | 7 | Uncommitted edits to GAME-002 task notes, project-state.json and tasks/queue.json, plus untracked `08 Reviews/HLT-20261015.md`. Not ours to discard |
| K6 | ~/.codex/worktrees/game-003-h01-checks/Rg1 | chore/game-003-h01-checks | no, 3 ahead, local only | 18 | Uncommitted Codex work in scripts/, tests/ and AGENTS.md |
| K7 | ~/.codex/worktrees/game-003-launch-audit/Rg1 | chore/game-003-launch-audit | no, 1 ahead, remote | 0 | Unmerged work |
| K8 | ~/.codex/worktrees/game-003-luna-prep/Rg1 | chore/game-003-luna-prep | no, 3 ahead, remote | 0 | Unmerged work |

## Prunable metadata (directory already gone)

Each row runs `git worktree prune`, which removes the registration only. Branches are then deleted only where the table says so.

| ID | Former path | Branch | Merged | Action after prune |
|---|---|---|---|---|
| P1 | /private/tmp/rg1-codex-handoff-review | chore/codex-handoff-review-20261018 | yes, PR merged, local only | Delete branch |
| P2 | /private/tmp/rg1-feedback-runtime | chore/reference-feedback-runtime | yes, PR merged, remote exists | Delete local branch (remote kept) |
| P3 | /private/tmp/rg1-individual-media-assessments | chore/individual-media-assessments | no, 1 ahead, remote | Keep branch |
| P4 | /private/tmp/rg1-monetization-model-baseline | chore/monetization-model-baseline | yes, local only | Delete branch |
| P5 | /private/tmp/rg1-monetization-ui-baseline | chore/monetization-ui-baseline | yes, local only | Delete branch |
| P6 | /private/tmp/rg1-orchestrator-ownership | chore/orchestrator-ownership | no, 1 ahead, remote | Keep branch |
| P7 | /private/tmp/rg1-reference-feedback | chore/reference-feedback-experiment | yes, PR merged, remote exists | Delete local branch (remote kept) |
| P8 | /private/tmp/rg1-references-20261017 | chore/references-20261017 | yes, PR merged, remote exists | Delete local branch (remote kept) |
| P9 | /private/tmp/rg1-repo-integration-notes | chore/repo-integration-notes | no, 2 ahead, remote | Keep branch |
| P10 | /private/tmp/rg1-task-0086 | task/TASK-0086-Accepted-Wisp-Revision-Recovery | yes, local only | Delete branch |
| P11 | /private/tmp/rg1-video-workflow-adoption | chore/video-workflow-adoption | no, 4 ahead, remote | Keep branch |

## Directories on disk that are not git checkouts

These are not in `git worktree list` as live checkouts. Their `.git` file is gone, so they are not git checkouts. Removing them means `rm -rf`, which is destructive. That needs your row approval, and I will list their contents first.

| ID | Path | Contents | Branch | Proposed action |
|---|---|---|---|---|
| D1 | /private/tmp/rg1-model-approval-workflow | `.claude/` (Oct 13) | chore/model-approval-workflow: no, 1 ahead, remote | Keep branch. Ask before deleting the folder |
| D2 | /private/tmp/rg1-shared-model-viewer | `tools/` (Oct 18) | chore/shared-model-viewer: no, 1 ahead, local only | Keep branch. Ask before deleting the folder |

## Local branches

- 100 local branches before cleanup. 78 are ancestors of `main`, excluding `main`. 21 are not merged.
- Appendix A lists the 62 ancestor branches that have no worktree. They can be deleted with `git branch -d` as one approved row.
- Ancestor branches still checked out (W1–W10 and P1, P4, P5, P7, P8, P10) are deleted when their row runs.
- Appendix B lists the 21 unmerged branches. All are kept. Three of them had PRs merged under the same name, so they look squash-merged and keep their commits: `chore/art-automation`, `chore/video-research-3d-models`, `task/TASK-0024-FullLoop-Landmark-Flake`. Also kept: `worktree-agent-a43df52601336427d`, a leftover Claude agent branch.

## Remote branches (inventory only, nothing deleted)

- 133 origin feature branches. 116 are ancestors of `origin/main` and are proposed for later deletion (Appendix C). 17 are not merged and are kept (Appendix D).
- Deleting remote branches is outward-facing, so it gets its own approval in a later task.

## Untracked files in the main checkout

| ID | Path | Proposed action | Why |
|---|---|---|---|
| U1 | `.codex/` (agents/auditor.toml, hooks/, hooks.json) | **Your decision.** Commit it, or add `.codex/` to .gitignore. Default: leave it | Not a cleanup candidate. It mirrors `.claude/`. A copy also sits untracked in W10. The tracked AUDIT-2026-10-30 says "left alone" |
| U2 | `02 Research/RSH-20261015-Claude-Restart.md` | Vault: commit after `validate_vault.py` passes | Named by the tracked `docs/workflow/AUDIT-2026-10-30.md`, so it is not stale |
| U3 | `02 Research/RSH-20261015-Cloud-Hill-Game-Prompt.md` | Vault: commit after `validate_vault.py` passes | Same as U2 |
| U4 | `02 Research/RSH-20261015-Cosmic-Bullet-Hell-Game-Prompt.md` | Vault: commit after `validate_vault.py` passes | Same as U2 |
| U5 | `02 Research/assets/wisp-pilot/user-reference-01.png` | .gitignore: `02 Research/assets/wisp-pilot/user-reference-*.png` | Your standing rule: user-reference images stay out of the repo. The file stays on disk |
| U6 | `02 Research/assets/wisp-pilot/user-reference-02.png` | Same as U5 | Same as U5 |
| U7 | `HANDOFF-MathShow-2026-10-30.md` | Move to `98 Archive/` | Describes the state as of 10-30 and has been overtaken. The AUDIT doc names it as "left alone", so confirm it is not the live handoff |
| U8 | `TASK-0094-claude-code-handoff.md` | Move to `98 Archive/` | TASK-0094 is `done` in `tasks/items/TASK-0094.json` |

Each `.gitignore` change in U5 (and any in U1) needs your approval. Nothing is ignored yet.

## Generated leftovers

- Most worktrees hold `sourcemap.json` and `BuildStamp.txt`. They go away with the worktree in W/P rows.
- The main checkout keeps its ignored `sourcemap.json` and `games/mathshow/src/shared/BuildStamp.txt`.

## Phase 1 commands (approved rows only)

```bash
git -C /Users/jg/Desktop/Rg1 worktree remove <path>
git -C /Users/jg/Desktop/Rg1 worktree prune
git -C /Users/jg/Desktop/Rg1 branch -d <branch>
```

Never `--force` and never `-D`. Each command is chained after `scripts/preflight.sh --root /Users/jg/Desktop/Rg1 --branch main` where it changes state.

## Appendices

Snapshot files from this phase: `git branch --merged main` and `git branch --no-merged main` (before), and `git worktree list --porcelain`.


### Appendix A: local branches that are ancestors of main, with no worktree (delete candidates, 62)
```
chore/archive-0008-0010-0020
chore/game-002-active-context
chore/game-002-haunted-collector-setup
chore/game-002-m1-retro
chore/m1-discovery
chore/m2-roadmap
chore/mathshow-closeout
chore/mathshow-setup
chore/menu-followup-tasks
chore/obsidian-conventions
chore/overhaul-base
chore/skills-integration
chore/task-0021-post-merge
chore/task-0024-outcome
chore/task-0033-proposal
chore/task-0088-close
chore/task-0104-close
chore/usage-policy
chore/world-retrofit-plan
claude/eloquent-nash-d8d41f
task/T-001-collectibles
task/TASK-0002-Ability-Framework
task/TASK-0003-Factions-And-Echo-Clone
task/TASK-0004-Ki-Burst
task/TASK-0005-Convergence-Gate
task/TASK-0006-Match-Flow-And-Onboarding
task/TASK-0007-Ring-Out-Finale
task/TASK-0009-Multi-Client-Test-Harness
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
task/TASK-0029-Habitat-Rotation
task/TASK-0030-House-And-Train-Presentation
task/TASK-0031-Failed-Capture-Retaliation
task/TASK-0032-Retaliation-Hardening
task/TASK-0033-Retaliation-Begin-Cleanup
task/TASK-0042-Art-Pipeline-And-Direction
task/TASK-0043-Creature-Models-And-Animation
task/TASK-0044-Environment-Kit-And-Ground
task/TASK-0045-Habitat-Landmarks
task/TASK-0088-mathshow-scaffold
task/TASK-0098-MathShow-Menu-Shell
task/TASK-0099-MathShow-Profile-Store-And-Settings-Save
task/TASK-0100-MathShow-Group-Join-And-Watching-Banner
task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder
task/TASK-0102-MathShow-Skill-Test-Play-And-Result
task/TASK-0103-MathShow-Blitz
task/TASK-0104-MathShow-VS-Matchmaking-And-Flow
task/TASK-0110-studio-sync
```

### Appendix B: local branches not merged into main (keep, 21)
```
chore/archive-task-0008
chore/art-automation
chore/creature-pipeline
chore/game-003-h01-checks
chore/game-003-launch-audit
chore/game-003-luna-prep
chore/git-safety
chore/individual-media-assessments
chore/model-approval-workflow
chore/orchestrator-ownership
chore/repo-integration-notes
chore/shared-model-viewer
chore/vault-navigation
chore/video-research-3d-models
chore/video-workflow-adoption
task/TASK-0008-Prototype-Telemetry
task/TASK-0024-FullLoop-Landmark-Flake
task/TASK-0040-Audio-Pass
task/TASK-0043-Wisp-Revision
task/TASK-0046-Mansion-Plot-And-Train-Art
worktree-agent-a43df52601336427d
```

### Appendix C: remote branches that are ancestors of origin/main (proposed for later, 116)
```
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
task/TASK-0110-studio-sync
task/TASK-0111-identity-gate
```

### Appendix D: remote branches not merged into origin/main (keep, 17)
```
chore/archive-task-0008
chore/art-automation
chore/creature-pipeline
chore/game-003-launch-audit
chore/game-003-luna-prep
chore/individual-media-assessments
chore/model-approval-workflow
chore/orchestrator-ownership
chore/repo-integration-notes
chore/universal-modder-evaluation
chore/vault-navigation
chore/video-research-3d-models
chore/video-workflow-adoption
task/TASK-0024-FullLoop-Landmark-Flake
task/TASK-0040-Audio-Pass
task/TASK-0043-Wisp-Revision
task/TASK-0046-Mansion-Plot-And-Train-Art
```

## Execution Log (Phase 1 and Phase 2)

Phase 1 ran the approved rows only. Phase 2 (this section) changed no worktree, registration, or branch. The commands below are the ones run in this session, in order.

| Row | Command | Result |
|---|---|---|
| W1–W8 | `scripts/preflight.sh --root /Users/jg/Desktop/Rg1 --branch main`, then for each path: `git -C <path> status --porcelain`, then `git worktree remove <path>` (no `--force`) | 8 of 8 removed. Every path showed 0 status lines before removal. None refused. Worktree count went 33 → 25 |
| P1, P2, P4, P5, P7, P8, P10 | `git worktree remove <former path>` for each missing directory | 7 of 7 registrations removed. Prunable count 13 → 6. `git worktree prune` was **not** run, because it would also have removed the held registrations (P3, P6, P9, P11, D1, D2) |
| W/P branches (14) | `git branch -d <name>` for each | 14 of 14 deleted. Git printed each tip SHA (see manifest) |
| Appendix A (62) | `git branch -d` in a loop, output sent to /dev/null | 61 deleted, 1 refused: `task/TASK-0032-Retaliation-Hardening`. The loop did not record the 61 tip SHAs (see caveat below) |
| task/TASK-0032 | `git merge-base --is-ancestor` (ancestor: yes); `git branch --unset-upstream task/TASK-0032-Retaliation-Hardening`; `git branch -d task/TASK-0032-Retaliation-Hardening` | Upstream unset. Branch deleted (was `ca4f12a`). Its upstream `origin/task/TASK-0032-Retaliation-Hardening` was left untouched on the remote |
| U8 | `mv TASK-0094-claude-code-handoff.md "98 Archive/"` in the main checkout | Moved (untracked in main) |
| U2–U4 | `mv` the three RSH-20261015 notes into the cleanup worktree; `python3 scripts/validate_vault.py` | 0 errors, 0 warnings. Committed as `21765a8` on `chore/repo-cleanup` |

Total deleted: 14 + 61 + 1 = **76 branches**, matching the approved rows (W/P 14, Appendix A 62 with TASK-0032 included).

Phase 2 commands:

| Step | Command | Result |
|---|---|---|
| Copy the archived handoff into the cleanup worktree | `cp` from main to `98 Archive/`, then `cmp` | Identical. Committed as `614087c` on `chore/repo-cleanup`. Main still has its untracked copy; removing it is a Phase 3 row |
| Gate | `scripts/check.sh` in the cleanup worktree | Exit 0. Log: `/private/tmp/claude-501/-Users-jg-Desktop-Rg1/a925946b-fa96-495e-994a-99d9ac2efdc9/scratchpad/check-phase2.log` |

### Caveat on recorded SHAs

- Git printed the tip SHA for the 15 branches deleted with a visible `-d` result (14 W/P branches and `task/TASK-0032-Retaliation-Hardening`).
- The Appendix A loop sent git's output to /dev/null, so the local tips of the other 61 were not recorded. Reflogs do not survive a branch deletion, and the Phase 0 snapshot stored names only.
- For 40 of the 61, the remote-tracking ref `origin/<name>` still exists. Its SHA is listed as **origin tip only**. It may differ from the deleted local tip.
- For 21 branches, neither a local tip nor a remote-tracking ref survives, so their SHA is **none recoverable**. Each of these branches was an ancestor of `main` when deleted, so its commits remain in `main`'s history.

### Deleted-branch manifest (76)

| Branch | Last SHA | Source |
|---|---|---|
| chore/executor-usage-and-audit-scope | 5c4c7f4 | local-recorded |
| chore/serve-guard-followups | b12e4f5 | local-recorded |
| task/TASK-0055-Rare-Capture-Hookup | b2c1d77 | local-recorded |
| task/TASK-0056-Studio-Test-Pads | a299edf | local-recorded |
| chore/task-0089-close | 31adb7f | local-recorded |
| task/TASK-0097-MathShow-HUD-Shards | 98a8ad9 | local-recorded |
| chore/workflow-efficiency-20261018 | 47c362b | local-recorded |
| chore/codex-handoff-review-20261018 | 18be4ef | local-recorded |
| chore/reference-feedback-runtime | 7876c04 | local-recorded |
| chore/monetization-model-baseline | 36d6b06 | local-recorded |
| chore/monetization-ui-baseline | f495955 | local-recorded |
| chore/reference-feedback-experiment | ba6da7b | local-recorded |
| chore/references-20261017 | ffd92ed | local-recorded |
| task/TASK-0086-Accepted-Wisp-Revision-Recovery | 18be4ef | local-recorded |
| task/TASK-0032-Retaliation-Hardening | ca4f12a | local-recorded |
| chore/archive-0008-0010-0020 | 73562a3 | origin-tip-only |
| chore/game-002-active-context | 531bc74 | origin-tip-only |
| chore/game-002-haunted-collector-setup | - | none-recoverable |
| chore/game-002-m1-retro | 4ed2095 | origin-tip-only |
| chore/m1-discovery | - | none-recoverable |
| chore/m2-roadmap | - | none-recoverable |
| chore/mathshow-closeout | 338d589 | origin-tip-only |
| chore/mathshow-setup | 62011ff | origin-tip-only |
| chore/menu-followup-tasks | 37fb988 | origin-tip-only |
| chore/obsidian-conventions | - | none-recoverable |
| chore/overhaul-base | - | none-recoverable |
| chore/skills-integration | - | none-recoverable |
| chore/task-0021-post-merge | 08f02ab | origin-tip-only |
| chore/task-0024-outcome | 24f4142 | origin-tip-only |
| chore/task-0033-proposal | 648b18a | origin-tip-only |
| chore/task-0088-close | 51d7432 | origin-tip-only |
| chore/task-0104-close | acec5da | origin-tip-only |
| chore/usage-policy | - | none-recoverable |
| chore/world-retrofit-plan | - | none-recoverable |
| claude/eloquent-nash-d8d41f | - | none-recoverable |
| task/T-001-collectibles | - | none-recoverable |
| task/TASK-0002-Ability-Framework | - | none-recoverable |
| task/TASK-0003-Factions-And-Echo-Clone | - | none-recoverable |
| task/TASK-0004-Ki-Burst | - | none-recoverable |
| task/TASK-0005-Convergence-Gate | - | none-recoverable |
| task/TASK-0006-Match-Flow-And-Onboarding | - | none-recoverable |
| task/TASK-0007-Ring-Out-Finale | - | none-recoverable |
| task/TASK-0009-Multi-Client-Test-Harness | - | none-recoverable |
| task/TASK-0011-Haunted-Scaffold-And-Player-Data | 5638c12 | origin-tip-only |
| task/TASK-0012-Graveyard-And-Landmarks | 3a41941 | origin-tip-only |
| task/TASK-0013-Monsters-And-Capture | c781088 | origin-tip-only |
| task/TASK-0014-Return-Trip-And-Containment | b9a4ff0 | origin-tip-only |
| task/TASK-0015-House-Tiers-And-Upgrades | bb738ae | origin-tip-only |
| task/TASK-0016-Starter-Ghost-Train | 1a5b290 | origin-tip-only |
| task/TASK-0017-Track-Editor | 0afc208 | origin-tip-only |
| task/TASK-0018-Journal-Tutorial-And-Rare-Clue | bb24bdc | origin-tip-only |
| task/TASK-0019-Persistence-And-Rejoin-Test | 8bf819c | origin-tip-only |
| task/TASK-0021-Anti-Cheat-Hardening | 395e018 | origin-tip-only |
| task/TASK-0022-M1-Polish | f28c092 | origin-tip-only |
| task/TASK-0023-Round-20-Design-Changes | 77661ca | origin-tip-only |
| task/TASK-0025-Clue-Hunting-Removal | 9a759f8 | origin-tip-only |
| task/TASK-0026-Radial-Plot-Layout | 7272082 | origin-tip-only |
| task/TASK-0027-Habitat-Modules-And-Blockouts | bec9de3 | origin-tip-only |
| task/TASK-0028-Cemetery-Vignette-And-Atmosphere | 154b9ff | origin-tip-only |
| task/TASK-0029-Habitat-Rotation | bb8c71a | origin-tip-only |
| task/TASK-0030-House-And-Train-Presentation | 5382f20 | origin-tip-only |
| task/TASK-0031-Failed-Capture-Retaliation | 75cd7b1 | origin-tip-only |
| task/TASK-0033-Retaliation-Begin-Cleanup | a690fb5 | origin-tip-only |
| task/TASK-0042-Art-Pipeline-And-Direction | - | none-recoverable |
| task/TASK-0043-Creature-Models-And-Animation | - | none-recoverable |
| task/TASK-0044-Environment-Kit-And-Ground | - | none-recoverable |
| task/TASK-0045-Habitat-Landmarks | - | none-recoverable |
| task/TASK-0088-mathshow-scaffold | 68ddc96 | origin-tip-only |
| task/TASK-0098-MathShow-Menu-Shell | 370f6e3 | origin-tip-only |
| task/TASK-0099-MathShow-Profile-Store-And-Settings-Save | 74bfc0d | origin-tip-only |
| task/TASK-0100-MathShow-Group-Join-And-Watching-Banner | 9b1ff28 | origin-tip-only |
| task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder | d20c98f | origin-tip-only |
| task/TASK-0102-MathShow-Skill-Test-Play-And-Result | bc93394 | origin-tip-only |
| task/TASK-0103-MathShow-Blitz | e2d6312 | origin-tip-only |
| task/TASK-0104-MathShow-VS-Matchmaking-And-Flow | 2a9a38f | origin-tip-only |
| task/TASK-0110-studio-sync | c553954 | origin-tip-only |

Counts: local-recorded 15, origin-tip-only 40, none-recoverable 21, total 76

## Check gate output (Phase 2 re-run)

Exit code: 0. Tail of the log (last 30 lines):

```

PASS  StyLua (format, GAME-004)
PASS  Selene (lint, GAME-004)
PASS  Luau types (strict, GAME-004)
PASS  Unit specs (Lune, GAME-004)
PASS  Rojo build (mathshow.project.json)
PASS  JSON files
PASS  Task files (schema, files_owned overlap)
PASS  Task queue (orchestrator)
PASS  Vault conventions
PASS  Reference notes
PASS  Project skills
PASS  Python tests
ALL CHECKS PASSED (active)
Note: play scenarios and gameplay need Studio, see AGENTS.md "Tests". Archived games: scripts/check.sh --archive.
check exit=0
```

## Held rows: evidence and recommendation

These rows were held in Phase 1. Nothing here was changed. Recommendations are for jg to approve in Phase 3.
The Phase 2 request labelled U1 as the MathShow handoff and U7 as `.codex/`. The plan's own IDs are the other way round: **U1 = `.codex/`, U7 = `HANDOFF-MathShow-2026-10-30.md`**. This table uses the plan IDs.

| ID | Subject | Recommendation | Evidence |
|---|---|---|---|
| W9 | `task-0110` worktree (`task/TASK-0111-identity-gate`) | **remove** after the shell releases its directory | `lsof -a -d cwd` shows one holder: login `zsh -l` pid 64782 (started Oct 30 16:45) with cwd inside the worktree. Branch is an ancestor of main (PR #160). 0 status lines |
| W10 | `chore-mathshow-intake` worktree (`chore/mathshow-intake`) | **keep** until U1 is decided, then **remove** | Only dirty item is untracked `.codex/`. Its copy differs from main's: `agents/auditor.toml` and `hooks.json` differ, and `hooks/ref-lint.sh` exists only here. Branch is an ancestor of main (PR merged) |
| U1 | `.codex/` in main (4 files, 8,381 bytes) | **commit** only after jg confirms Codex loads repo hooks, and after reconciling with W10's copy | Not referenced in AGENTS.md, CLAUDE.md, `.gitignore`, `tests/` or `scripts/`. `.agents/skills/` is tracked, but `.codex/` is not. Main's copy and W10's copy have diverged |
| U5 | `02 Research/assets/wisp-pilot/user-reference-01.png` (647 KB) | **ignore** | Proposed line for `.gitignore`: `02 Research/assets/wisp-pilot/user-reference-*.png`. Tested with a temporary excludes file (`.gitignore` untouched): it matches this file. It does not match the tracked `wisp-approved-concept.png` |
| U6 | `02 Research/assets/wisp-pilot/user-reference-02.png` (530 KB) | **ignore** | Same line as U5. Matched by the same dry run |
| U7 | `HANDOFF-MathShow-2026-10-30.md` | **keep** in place; do not archive | Newest MathShow handoff by header date: "state as of 2026-10-30". The others are in `98 Archive/` (10-25, 10-18). Named only in AUDIT-2026-10-30 line 162 as "left alone". Not referenced in AGENTS.md, `tasks/queue.json`, or the vault |
| D1 | `/private/tmp/rg1-model-approval-workflow` | **remove** the folder and its admin entry, after approval | Classified as a **broken registration**. `.git/worktrees/rg1-model-approval-workflow/gitdir` points to `/private/tmp/rg1-model-approval-workflow/.git`, which does not exist. The folder contains no regular files, only empty `.claude/skills/` |
| D2 | `/private/tmp/rg1-shared-model-viewer` | **remove** the folder and its admin entry, after approval. Keep branch `chore/shared-model-viewer` | Classified as a **broken registration**, same pattern as D1. The folder holds only `tools/model-viewer/node_modules/` (pnpm tree, no regular files). `main` has no `tools/` directory, so a diff against main is not applicable. The source lives on the branch (`tools/model-viewer/` and `pnpm-lock.yaml`), so `node_modules` can be reinstalled |
| K5 | `overhaul` worktree (`task/TASK-0046-Mansion-Plot-And-Train-Art`) | **keep** | `git status --short`: 6 modified files and 1 untracked (`08 Reviews/HLT-20261015.md`). `git diff --stat`: 6 files, 31 insertions, 10 deletions. Uncommitted work, so its owner must commit or discard it |
| K6 | `game-003-h01-checks` worktree (`chore/game-003-h01-checks`) | **keep** | `git status --short`: 11 modified and 7 untracked. `git diff --stat`: 11 files, 155 insertions, 219 deletions. Codex-owned uncommitted work |
| S1 | `chore/art-automation` (squash) | **delete with -D** after approval | Merged PR #64 (2026-10-16). 53 files changed since merge-base. Scoped diff vs `origin/main`: 0 lines |
| S2 | `chore/video-research-3d-models` (squash) | **delete with -D** after approval | Merged PR #50 (2026-10-14). 1 file changed. Scoped diff: 0 lines |
| S3 | `task/TASK-0024-FullLoop-Landmark-Flake` (squash) | **delete with -D** after approval | Merged PR #15 (2026-10-12). 4 files changed. Scoped diff: 0 lines |
| R1 | Remote branches merged into `origin/main` (Appendix C, 116) | **delete later**, in a separate approved task | `gh pr list --state open` returns **0** open PRs (`gh` is authenticated; 161 PRs total), so no remote branch is marked KEEP for an open PR. Manifest below |

Scoped diff used for S1–S3: `git diff origin/main <branch> -- $(git diff --name-only $(git merge-base origin/main <branch>) <branch>)`.

### Remote-branch manifest (Appendix C, 116 merged, name and origin SHA)

```
chore/TASK-0057-proposal	647eb0e
chore/TASK-0058-proposal	70a49af
chore/TASK-0059-proposal	421bea1
chore/TASK-0059-state	6018c34
chore/TASK-0060-approvals	3844245
chore/anim-pipeline-pointer	43736d4
chore/approve-les-0008	5734a86
chore/approve-monetization-0062-0067	e635489
chore/archive-0008-0010-0020	73562a3
chore/art-skills	0cca8bd
chore/brain-intake	608f4c6
chore/claude-automations	ad70020
chore/close-approved-art-tasks	f64454d
chore/close-superseded-art-tasks	2102cb0
chore/codex-handoff-20261018	cde4363
chore/dev-tooling	93ae0ec
chore/executor-usage-and-audit-scope	5c4c7f4
chore/game-002-active-context	531bc74
chore/game-002-m1-retro	4ed2095
chore/knowledge-entry-points	747b3ad
chore/les-0008-link	a6c616e
chore/light-task-model-default	0790fef
chore/lune-rules-specs	7399cbf
chore/mathshow-closeout	338d589
chore/mathshow-intake	c1462e5
chore/mathshow-setup	62011ff
chore/memory-to-vault	39bc0bc
chore/menu-followup-tasks	37fb988
chore/monetization-task-slices	f5d3361
chore/orchestrator-light-path	ea292e5
chore/propose-art-salvage	cf50316
chore/reference-automations-2	e3bf325
chore/reference-evidence	9b57e0a
chore/reference-feedback-experiment	ba6da7b
chore/reference-feedback-runtime	7876c04
chore/reference-first-development	91f28b4
chore/reference-review-anatomy	5589efd
chore/reference-review-floors	6119cd5
chore/reference-review-session	4407f6f
chore/reference-skills	b0704d3
chore/reference-tooling	e339e02
chore/references-20261017	ffd92ed
chore/repo-adoption-workflow	3255358
chore/sequence-runner-docs	58a3514
chore/sequence-runner-proposal	a320fce
chore/serve-guard-followups	b12e4f5
chore/session-ownership	04057f1
chore/task-0021-post-merge	08f02ab
chore/task-0024-outcome	24f4142
chore/task-0033-proposal	648b18a
chore/task-0088-close	51d7432
chore/task-0089-close	31adb7f
chore/task-0093-close	3a8f8d9
chore/task-0104-close	acec5da
chore/token-efficiency-process	b60df19
chore/vfx-dense-review	481287a
chore/video-prompt-variants	23a3fbb
chore/video-research-3d-monster-npc	f7b884c
chore/video-research-index	6adb3b3
chore/video-research-index-update	3c3920c
chore/video-research-mrwonder-batch	79d24cf
chore/video-research-notes-batch	b74b990
chore/video-research-recipe	146fdbb
chore/workflow-efficiency-20261018	47c362b
task/TASK-0011-Haunted-Scaffold-And-Player-Data	5638c12
task/TASK-0012-Graveyard-And-Landmarks	3a41941
task/TASK-0013-Monsters-And-Capture	c781088
task/TASK-0014-Return-Trip-And-Containment	b9a4ff0
task/TASK-0015-House-Tiers-And-Upgrades	bb738ae
task/TASK-0016-Starter-Ghost-Train	1a5b290
task/TASK-0017-Track-Editor	0afc208
task/TASK-0018-Journal-Tutorial-And-Rare-Clue	bb24bdc
task/TASK-0019-Persistence-And-Rejoin-Test	8bf819c
task/TASK-0021-Anti-Cheat-Hardening	395e018
task/TASK-0022-M1-Polish	f28c092
task/TASK-0023-Round-20-Design-Changes	77661ca
task/TASK-0025-Clue-Hunting-Removal	9a759f8
task/TASK-0026-Radial-Plot-Layout	7272082
task/TASK-0027-Habitat-Modules-And-Blockouts	bec9de3
task/TASK-0028-Cemetery-Vignette-And-Atmosphere	154b9ff
task/TASK-0029-Habitat-Rotation	bb8c71a
task/TASK-0030-House-And-Train-Presentation	5382f20
task/TASK-0031-Failed-Capture-Retaliation	75cd7b1
task/TASK-0032-Retaliation-Hardening	3443397
task/TASK-0033-Retaliation-Begin-Cleanup	a690fb5
task/TASK-0041-Interactive-Haunted-Trees	d68b5d9
task/TASK-0053-Sequence-Runner	7df964c
task/TASK-0054-Rare-Capture-Finisher	e29b2f5
task/TASK-0055-Rare-Capture-Hookup	b2c1d77
task/TASK-0056-Studio-Test-Pads	a299edf
task/TASK-0057-Overview-Evidence-Sync	af92655
task/TASK-0058-SetExhibit-Input-Rules	dd648cf
task/TASK-0059-ExhibitRules-Corrupt-Tier-Guard	a0d3b24
task/TASK-0060-Monetization-Persistence-Schema	2dd2c32
task/TASK-0061-Shop-And-Owned-Inventory-UI	0c75063
task/TASK-0062-Ghost-Skins-And-Auras-Equipment	0ccbb21
task/TASK-0063-Capture-Effects-Equipment	fc39614
task/TASK-0064-Mansion-Themes	ccefbb7
task/TASK-0065-Exterior-Decoration-Editor	f5f8d1f
task/TASK-0066-Journal-Collection-Rewards	dd4515f
task/TASK-0067-Coin-Purchases	c1e803d
task/TASK-0068-Robux-Purchase-Research-And-ADR	7e5bfe2
task/TASK-0069-Art-Salvage-From-Overhaul-Branch	92652e3
task/TASK-0088-mathshow-scaffold	68ddc96
task/TASK-0089-mathshow-problemrules	705afed
task/TASK-0093-MathShow-Hud	418d066
task/TASK-0097-MathShow-HUD-Shards	98a8ad9
task/TASK-0098-MathShow-Menu-Shell	370f6e3
task/TASK-0099-MathShow-Profile-Store-And-Settings-Save	74bfc0d
task/TASK-0100-MathShow-Group-Join-And-Watching-Banner	9b1ff28
task/TASK-0101-MathShow-Practice-Home-Skill-Test-Intro-And-Rank-Ladder	d20c98f
task/TASK-0102-MathShow-Skill-Test-Play-And-Result	bc93394
task/TASK-0103-MathShow-Blitz	e2d6312
task/TASK-0104-MathShow-VS-Matchmaking-And-Flow	2a9a38f
task/TASK-0110-studio-sync	c553954
task/TASK-0111-identity-gate	265f8f8
```

## Phase 3–4 Log

### Approved rows

| Row | Action | Result |
|---|---|---|
| S1 `chore/art-automation` | Removed K1 worktree (clean; `git worktree remove`, no `--force`), then `git branch -D` | Deleted. Last SHA `1887dd8`. Squash check passed earlier: PR #64 merged, scoped diff 0 lines |
| S2 `chore/video-research-3d-models` | `git branch -D` | Deleted. Last SHA `92b86ba`. PR #50 merged, scoped diff 0 lines |
| S3 `task/TASK-0024-FullLoop-Landmark-Flake` | `git branch -D` | Deleted. Last SHA `f701276`. PR #15 merged, scoped diff 0 lines |
| D1 `/private/tmp/rg1-model-approval-workflow` | `rm -rf` the folder (verified 0 regular files first), then `git worktree remove` for its admin entry | Removed. Broken registration; folder held only empty directories |
| D2 `/private/tmp/rg1-shared-model-viewer` | `rm -rf` the folder (verified 0 regular files first), then `git worktree remove` | Removed. Folder held only `tools/model-viewer/node_modules` (pnpm tree). Source remains on `chore/shared-model-viewer` |
| U5, U6 | `.gitignore` line `02 Research/assets/wisp-pilot/user-reference-*.png`, committed as `4343b11` | Committed on the branch. Takes effect in main after merge. The two PNGs stay on disk |
| K1 | Removed with S1 | See S1 |

### A1: duplicate handoff in main

- `git hash-object "98 Archive/TASK-0094-claude-code-handoff.md"` (main copy): `8240000fa7557e3892222291fbecfdec2a6b0b2b`
- `git rev-parse 614087c:"98 Archive/TASK-0094-claude-code-handoff.md"`: `8240000fa7557e3892222291fbecfdec2a6b0b2b`
- Hashes match. Main copy removed. The committed copy in `614087c` is unchanged.

### A2: W9 (task-0110 worktree)

- **Skipped.** After the user confirmed closing the terminal tab, PID 64782 (`/bin/zsh -l`) still has its cwd at `/Users/jg/Desktop/Rg1-worktrees/task-0110`. The worktree itself is clean (0 status lines), and `task/TASK-0111-identity-gate` is an ancestor of main (PR #160).
- A second process, `com.apple` PID 72596, holds `docs/design/hud/HudSpec.json` read-only. It does not hold the cwd.
- The worktree and branch were left untouched.

### A4: prunable registrations (not pruned)

`git worktree list --porcelain`, prunable entries:

| Entry | HEAD | Branch | Gitdir target | Directory on disk | Advice |
|---|---|---|---|---|---|
| `/private/tmp/rg1-individual-media-assessments` | `4ba838a` | `chore/individual-media-assessments` | `/private/tmp/rg1-individual-media-assessments/.git` (missing) | missing | **Keep the branch** (1 commit ahead, remote exists). Prune the registration after approval |
| `/private/tmp/rg1-orchestrator-ownership` | `7d3f36d` | `chore/orchestrator-ownership` | `/private/tmp/rg1-orchestrator-ownership/.git` (missing) | missing | **Keep the branch** (1 ahead). Prune the registration after approval |
| `/private/tmp/rg1-repo-integration-notes` | `d399ae0` | `chore/repo-integration-notes` | `/private/tmp/rg1-repo-integration-notes/.git` (missing) | missing | **Keep the branch** (2 ahead). Prune the registration after approval |
| `/private/tmp/rg1-video-workflow-adoption` | `1e9ee4f` | `chore/video-workflow-adoption` | `/private/tmp/rg1-video-workflow-adoption/.git` (missing) | missing | **Keep the branch** (4 ahead). Prune the registration after approval |

Each gitdir target is missing, so these are broken registrations. Pruning removes only the metadata. The branches have unmerged commits and must be kept.

### Studio verification (MathShow.rbxl)

- Rojo 7.7.0 served `mathshow.project.json` from main (stamp `80e39b8`) on 127.0.0.1:34872 via `scripts/serve.sh`. The user confirmed the plugin was connected.
- Play started, then waited 10 s, then console read. Verdict: **PASS**. No `require` errors and no "is not a valid member" errors.
- Console excerpt:

```
[MathShow] phase=Intermission waiting for players
[MathShow] server ready
[MathShow] GetDataStore failed: You must publish this place to the web to access DataStore.
[MathShow] DataStores unavailable (...); jg_57565 runs in memory-only mode
[MathShow] Menu image shard-menu-title-violet-v2 has no asset id yet; showing a flat placeholder
[MathShow] Menu image glow-menu-title-violet-v2 has no asset id yet; showing a flat placeholder
[MathShow] client ready
[MathShow] Hud first RoundState after 0.04s
[MathShow] match seed=86446885
[MathShow] phase=Intermission q=0 seed=86446885 endsAt=1793467597.63
ContentId: rbxassetid://203785492 failed due to: Asset type does not match requested type   (x3)
```

- Non-blocking warnings: DataStore is unavailable in an unpublished place, two menu images have no asset id yet, and one asset ID (`203785492`) has the wrong type. None of these come from this cleanup. The cleanup changed no file under `games/`, `src/` or `tests/`; the only changes since `80e39b8` are the docs, `.gitignore` and `98 Archive/`.
- Play stopped. `scripts/serve.sh` stopped. Nothing listens on 34872 and no rojo process remains.

### Branch state

- `git branch --no-merged main` now differs from the Phase 1 snapshot by: `chore/repo-cleanup` (added), and `chore/art-automation`, `chore/video-research-3d-models` and `task/TASK-0024-FullLoop-Landmark-Flake` (removed by S1–S3).
- W9's branch `task/TASK-0111-identity-gate` was not removed.

### Final check gate

`scripts/check.sh` on commit `2889458`: exit 0. Tail of the log:

```

PASS  StyLua (format, GAME-004)
PASS  Selene (lint, GAME-004)
PASS  Luau types (strict, GAME-004)
PASS  Unit specs (Lune, GAME-004)
PASS  Rojo build (mathshow.project.json)
PASS  JSON files
PASS  Task files (schema, files_owned overlap)
PASS  Task queue (orchestrator)
PASS  Vault conventions
PASS  Reference notes
PASS  Project skills
PASS  Python tests
ALL CHECKS PASSED (active)
Note: play scenarios and gameplay need Studio, see AGENTS.md "Tests". Archived games: scripts/check.sh --archive.
```

## Closeout

### Merge and B1–B3

- **PR #162 merged** as `45cbe45` (merge commit, 2026-10-31 17:34 UTC). Merged on your request. No auto-merge was enabled and the branch was not deleted by the merge.
- **B1:** `main` fast-forwarded from `80e39b8` to `45cbe45`. `git status --short` now lists only `.codex/` and `HANDOFF-MathShow-2026-10-30.md`. The two wisp PNGs are ignored.
- **B2:** `chore/repo-cleanup` worktree removed (clean, no `--force`). Local branch deleted with `-d` (was `a08d3b3`). GitHub had not deleted `origin/chore/repo-cleanup` on merge, so it was deleted with `git push origin --delete`.
- **B3:** the W9 worktree at `/Users/jg/Desktop/Rg1-worktrees/task-0110` removed (clean, no `--force`). Git accepted the removal although pid 64782 still had its cwd there. Local branch `task/TASK-0111-identity-gate` deleted with `-d` (was `265f8f8`).

### PR #160 head-ref check

- `gh pr view 160`: `headRefName` = `task/TASK-0111-identity-gate`, state `MERGED`.
- The B3 mismatch was between the worktree directory name (`task-0110`) and the branch checked out in it (`task/TASK-0111-identity-gate`). The branch matches PR #160.
- `git branch --list 'task/TASK-0110*'`: no local branches. `git ls-remote --heads origin 'task/TASK-0110*' 'task/TASK-0111*'`: `origin/task/TASK-0110-studio-sync` (`c553954`, already on main) and `origin/task/TASK-0111-identity-gate` (`265f8f8`). Both remote branches were left in place.
- Local `task/TASK-0110-studio-sync` was deleted in Phase 1 (Appendix A). Its tip was `c553954`.

### Held rows (unchanged)

| Row | Subject | State |
|---|---|---|
| W10 | `chore-mathshow-intake` worktree (`chore/mathshow-intake`) | Held. Dirty only with `.codex/` |
| U1 | `.codex/` in main | Held. Commit only after jg confirms Codex loads repo hooks |
| U7 | `HANDOFF-MathShow-2026-10-30.md` | Held. Stays in place |
| K5 | `overhaul` worktree (`task/TASK-0046-Mansion-Plot-And-Train-Art`) | Held. 6 modified, 1 untracked |
| K6 | `game-003-h01-checks` worktree (`chore/game-003-h01-checks`) | Held. 11 modified, 7 untracked |
| R1 | 116 merged remote branches (Appendix C) | Held. Needs its own approval |
| — | `chore/individual-media-assessments`, `chore/orchestrator-ownership`, `chore/repo-integration-notes`, `chore/video-workflow-adoption` | Local branches left by P3/P6/P9/P11. Kept. Registrations pruned |
