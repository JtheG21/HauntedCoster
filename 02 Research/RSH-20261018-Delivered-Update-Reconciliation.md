---
id: RSH-20261018-Delivered-Update-Reconciliation
title: "Delivered Update Reconciliation"
type: research
project: GAME-002
status: research
created: 2026-10-18
updated: 2026-10-18
sources:
  - "Local Git main 494be30 and preserved work branches, inspected 2026-10-18"
tags:
  - game/art
  - workflow/integration
related:
  - "[[Handoff to Codex 2026-10-18]]"
  - "[[TASK-0086-Accepted-Wisp-Revision-Recovery]]"
---
# Delivered update reconciliation

## Question
jg reports old wisps, tree issues and z-fighting in a playtest on 2026-10-18. Which updates are actually absent from main versus present but still failing?

## Verified observations
| Area | Evidence | Conclusion |
|---|---|---|
| Accepted lantern-perch Wisp | Branch `task/TASK-0043-Wisp-Revision` at `5ecb890` is not in main. Its task Outcome records jg acceptance on 2026-10-16 and deferred delivery through TASK-0052. Current main still has the earlier creature_wisp data. | **Missing from main.** Acceptance is recorded on the preserved branch; no new merge approval is inferred. |
| Textured imported Wisp and animation | Main lacks `games/haunted/assets/ImportedArt.rbxm`, its ServerStorage mapping, MeshBuild.imported, ArtBake imported preference, ImportYaw support and revised Wisp pose/scale. Studio Edit also has no ImportedArt. | The missing model includes a missing dependency chain, not just a mesh swap. |
| Trees | Current main and the Wisp revision branch have no differences in HauntedTree, client HauntedTrees, shared tree config or tree art data. Environment art commits `1a178b6`, `fb9dfcc` are ancestors of main. | No omitted tree delta found in those source branches. A current visual/runtime regression remains possible. |
| Environment revision | `3ddc2e6` IS an ancestor of main. Current code includes terrain reset/repaint and activation generation protection, RNG/collider fixes. Only the pinned-type cast differs in GroundPainter from the old overhaul branch. | The handoff's claim that the revision was never done is inaccurate about the code. Re-review still owed; do not blindly reapply historical fixes. |
| Original z-fighting fixes | `cc73749` IS an ancestor of main; HubBuilder still removes stray Baseplate. Studio Edit currently contains Terrain and Camera only, no Baseplate. | No evidence the original fix commit was omitted. Current flicker location/cause is not diagnosed. |
| Reusable art tooling | `1887dd8` (review.sh/budget tests), `121c15c` (sourced/surface/template creature pipeline) are outside main. | Additional completed tooling lives on preserved branches; it does not change current runtime appearance by itself. |
| Audio pass | `30387d1` on TASK-0040 is outside main; branch note records placeholder SoundBank/Sfx/hooks/mute, with runtime and by-ear checks outstanding. | Implemented elsewhere but unfinished/unverified; not an approved final sound set. |
| Old overhaul UI/cosmetics | `a5f0aaa`, `199a82b`, `197c153`, `1e9ee4f` excluded deliberately by TASK-0069. Main uses replacement TASK-0060–0067 code. | Not accidental omissions. Wholesale restoration would overwrite newer state/UI and variant rules. |
| New verification fixes | TASK-0070–0085 on the Codex review branch are proposed only. | These are findings/plans, not already-implemented fixes. |

Studio read-only verification in Edit: **151/151 script lengths/hashes match main**; stamp `494be30 2026-10-18T21:25:38Z`. This rules out those script sources being stale at inspection time, not stale mesh content or problems in another saved place. No Play session or source change performed in this investigation.

## Corrections to earlier records
The initial handoff/source review repeated the historical statement that TASK-0044's revision was not completed. Commit `3ddc2e6` proves several code corrections did land. Historical audit records are preserved; this note supersedes that interpretation. TASK-0076 remains useful for current reproduction and missing evidence, not blanket reapplication of all old findings.

## Recommendation
Recover the final accepted Wisp asset and its minimal runtime dependencies selectively. Preserve main's CosmeticLooks, SkinId/AuraId protocol, rare-variant restrictions and pinned-type casts; the old Creatures module is not a drop-in replacement. Do not merge the full Wisp branch, because its ancestry includes the deliberately excluded backend/UI overhaul. Proposed scope: [[TASK-0086-Accepted-Wisp-Revision-Recovery]].

Reproduce z-fighting/tree issues at jg's reported locations before deciding on geometry edits. jg was asked which area/place was tested; response pending at recording time. Use [[TASK-0076-Environment-Revision-Remediation]] for confirmed current defects, keeping proposed status until approved.

## Limits
This is a targeted inventory of the preserved game/art branches, not proof that every historical chat request was delivered. Branch notes and prior approvals are evidence to verify, not a substitute for current human gates. No production code, model, saved place or task approval changed.
