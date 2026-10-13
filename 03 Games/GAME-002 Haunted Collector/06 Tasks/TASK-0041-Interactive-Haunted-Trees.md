---
id: TASK-0041
title: "Interactive Haunted Trees"
type: task
project: GAME-002
status: in_progress
priority: medium
risk: medium
owner: executor
depends_on:
  - TASK-0039
branch: task/TASK-0041-Interactive-Haunted-Trees
related:
  - "[[GAME-002 Haunted Collector/01 Game Design]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[ADR-0007-World-Retrofit-Direction]]"
  - "[[Map References]]"
  - "[[Haunted Trees -- Visual Reference]]"
  - "[[Haunted Trees -- Reference Pack]]"
  - "[[Interactive Haunted Trees - READ ME]]"
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
  - "[[Reference_Code_Index]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/task
---

# Interactive Haunted Trees

## Goal
Add stationary trees to the Cursed Woodland whose bark faces watch players and go lifeless when caught. The freeze applies to everyone: a face stays frozen while any player looks at it and resumes only after 1 s with no observer. This is atmosphere only: no damage, rewards or gameplay effect. The brief comes from jg's pasted execution prompt (2026-10-13) and [[Haunted Trees -- Reference Pack]].

## Confirmed decisions (jg, 2026-10-13 brief; not re-asked)
- Three archetypes share one behavior system. Only face parts move: never the trunk, roots or branches.
- Height: most trees are 1.5–2 avatar heights, some smaller. No giant trees.
- About 50% of the new trees have faces, placed naturally.
- Eye palette: black, orange-yellow or purple at equal odds. The server picks it once per instance, so every client sees the same color, and it is independent of archetype.
- Gaze: face visible, unobstructed, 9–14 studs away, camera within 10–15° of the face. All are config values to calibrate in Studio.
- The freeze is global per tree. A 1 s continuous no-observer delay is needed before resuming, and any new observer cancels it. Recovery opens with a small twitch, then returns to idle.
- Mouth movement is silent. Leave a hook for future voice-synced mouth control, with no audio.
- Placement: Cursed Woodland.

## References (inspected 2026-10-13)
- **ASSET-REF-001** (`10 References/02 Map/ASSET-REF-001_Primary-Physical-Reference.png`) is **byte-identical** to [[reference4]] (`Screenshot 2026-10-11 at 11.32.37 PM.png`; md5 prefix f54246b8).
  - *Observed:* dark teal pillar forest. Straight, near-cylindrical trunks flare at the base, with a flat stone-like face low on the trunk (about knee to chest height of a man). Shallow eye slits and an open mouth. Low-poly, heavy texture.
  - *Implementation:* Archetype A uses a thick trunk flared at the base, with a low face set into shallow recesses.
- **ASSET-REF-002** has the same dimensions as `Reference1` (`11.30.10 PM`, 1414×1312) but different bytes, so it is probably a re-export.
  - *Observed:* cartoon green trunks with glowing orange rimmed eyes and toothy grins.
  - *Use:* eye-rim and mouth proportions only, toned down.
- **ASSET-REF-003** has the same dimensions as `reference2` (`11.30.27 PM`, 1432×1310) (that note and screenshot are deleted, uncommitted, in jg's main checkout; see Risks).
  - *Observed:* tall spiky pines, and a purple octagonal mask face with amber eyes and a wide smile.
  - *Use:* the faceted, angular face for Archetype C.
- **Secondary (not ASSET-REF):** the foggy photoreal carved-bark screenshot (`Screenshot 2026-10-13 at 12.43.31 AM.png`) and the overview board (`Haunted-Trees_Overview-Concept-Board.png`, renamed from `Pasted image 20261013005321.png` on 2026-10-13 to the name the pack README uses). The board's text and dimensions are approximate. The three Higgsfield archetype renders exist only as CDN links and have **not been viewed**.
- **Map reference IDs:** the local map references carry no `MAP-REF-00N` IDs. They are `Reference1`, `reference2` … `reference7` in [[Map References]]. They stay as they are; this task links them and does not renumber them.
- **Code:** SODT-RC-1 `PerceptionService.luau` (fetched from GitHub on 2026-10-13).
  - *Reuse:* separate "seen right now" flags, `os.clock()` timestamps, a throttled sensor, and its note to replicate camera LookVector at about 10 Hz.
  - *Adapt:* camera facing is client-only here, so clients report gaze changes and the server checks them for plausibility instead of polling.
  - *Don't take:* its beast/hiding model or its Balance module.

## Intake
- **Category → workflow, depth:** Systems (a networked mechanic) → [[Systems Workflow]], plus 3D prop → [[Asset Workflow]], plus face animation → [[VFX Workflow]]. **Deep** tier: shared replicated state and a new client→server remote. The trust model is in [[ADR-0010-Client-Reported-Gaze]] (proposed).
- **References:** ASSET-REF-001 to 003 and the pack notes above. All the files were tidied into `10 References/02 Map/` on 2026-10-13 (jg: "tidy the files"). ASSET-REF-001 duplicates `reference4`'s media byte for byte; both are kept because the pack's notes embed the ASSET-REF name.
- **Reuse:** the [[Resource Catalog]] lists "Prop kit" (`Props.luau`, implemented) → **extend**. "Server-validated remotes" (verified) → **reuse** the shape: `Net.luau` plus `Remotes.allow`. "Pure rules plus Lune specs" (verified) → **reuse**. "Blender pipeline" is verified for static meshes only and an import uploads to jg's account → **not used**, see Risks.
- **Decisions:** jg approved the plan on 2026-10-13 ("approved, pause audio, use a worktree, tidy the files"). TASK-0040 is paused. Work happens in the worktree `/Users/jg/Desktop/Rg1-worktrees/TASK-0041`, branched from `origin/main` 9ed593e.
- **Assumptions (reversible):**
  - About 16 new trees, added alongside the existing pines rather than replacing them.
  - The palette is unseeded per server; the layout and archetype use the Woodland's seeded RNG.
  - The idle animation is client-local.

## Reuse assessment
- `Props.deadTree`, and the pines in `World/Habitats/Woodland.luau`, are single-block trunks that can't hold faces. The new trees are a sibling prop module, `World/HauntedTree.luau` (its own module because `Props.luau` is already 653 lines), built with the same `Build.part` helper. The existing pines, dead trees, landmarks and scatter are not touched.
- Habitats are built once and reparented between `ServerStorage.HabitatModules` and `Workspace.Habitat` (HabitatService). So trees exist for the server's lifetime, and clients see them only while the Woodland is active. Observers are cleared in `onDeactivating`.
- Remotes follow `Shared/Net.luau` (one new C→S event) and are rate-limited with `Remotes.allow`. Tuning goes in a `Shared/Config` module and pure logic in `Shared/Rules`, per the Luau conventions.

## Plan
1. **Config** (`Shared/Config/HauntedTrees.luau`):
   - Face chance 0.5, the archetype list, the three palettes (low-emission colors, not Neon for black).
   - Gaze range 12 and angle 12° plus the face's angular radius; track range about 30; resume delay 1.0 s.
   - Observer time-to-live 1.25 s, client keepalive 0.4 s, rate limit.
2. **Rules** (`Shared/Rules/GazeRules.luau`, pure, time is passed in):
   - `qualifies(camPos, camLook, facePos, faceFwd, faceRadius, cfg)`: distance, angle widened by `atan(radius/dist)`, and camera in front of the face.
   - Observer aggregation: `observe`, `release`, `expire`, `step(now)` → frozen/resumeAt. Covers multiple observers, the cancelled resume, the full-second rule, removal on leave, and expiry of stale reports.
   - `pickAppearance(rng)`.
3. **Prop** (`World/HauntedTree.build(parent, options)`):
   - Built from irregular, slightly rotated parts.
   - **A** follows REF-001: thick, flared, face low.
   - **B**: squat and broad, with a wide face and heavy brow.
   - **C**: narrow and leaning, with a faceted face (REF-003).
   - Face parts are sockets, eyeballs, pupils, upper lids, brow, cheeks, nose and a mouth (cavity, lip, jaw). They are non-colliding and anchored, and are referenced from an invisible `FaceRoot` part whose LookVector is the face direction. *(As built; the original plan said lower lids and a `Face` submodel.)*
   - The model carries attributes (`Archetype`, `Palette`, `TreeId`) and a `HauntedTree` tag. The trunk collides as one simple part; everything else does not.
4. **Woodland placement:** about 16 trees along the trails and clearing edges, at seeded positions clear of zone centres. Faced trees face the nearest path point, and their dark eyes suit the Black Thicket.
5. **Server** (`Services/HauntedTreeService.luau`, idempotent `start()`):
   - **Registry:** collects tagged faced trees from the built Woodland.
   - **`TreeGaze` event `(treeId, looking)`:** checks that the tree exists and is in the active habitat, and that the player is alive. Then distance from the head to the face ≤ range + slack, the head is in front of the face, and a server raycast from head to face is clear. Rate-limited.
   - **State:** observers are aggregated through GazeRules and the `Frozen` attribute is set on the tree. Per tree, one token-guarded `task.delay` runs to its next expiry or resume, and there is no loop. *(As built; the plan said a 4 Hz sweep.)*
   - **Cleanup:** on PlayerRemoving, CharacterRemoving and habitat deactivation.
6. **Client** (`client/HauntedTrees.luau`):
   - Watches tagged trees via CollectionService. One RenderStepped loop runs for faced trees within about 40 studs.
   - Local gaze test (same GazeRules plus a raycast). It sends edges and a keepalive, never per-frame spam.
   - **Animation:** one solver per face, by interpolating CFrames, with no stacked tweens. Eyes track the nearest visible player, with idle glances, blinks and small mouth shifts.
   - **`Frozen`:** pupils snap to rest within about 0.12 s, lids settle half-lowered and the mouth closes. Animation stops until the attribute clears, then a twitch, then idle.
   - **Hook:** `HauntedTrees.setMouthOverride(treeId, alpha?)` for future speech.
7. **Tests:**
   - `GazeRules.spec.luau`: range and angle limits, behind the face, multiple observers, cancelled resume, full second, leave and expiry, appearance palettes and odds.
   - `scripts/check.sh`.
8. **Studio:** check scale next to an avatar. Run a 2-player scenario `tests/scenarios/HauntedTrees.luau` (A looks, B looks, A leaves, both leave, B looks again inside 1 s, a character reset), plus screenshots at gameplay distance. Record a `TEST-` note.
9. **Notes:** Outcome, Overview, a `SYS-` note if warranted, Map References links, then the audit (one Opus audit, since this touches networking).

## Scope
- **In:** the plan above.
- **Out (non-goals):**
  - Sound or voice, Blender meshes or uploads, skeletal rigs.
  - Changes to other habitats or to the existing Woodland props.
  - Any gameplay effect.

## Files expected to change
- **New:** `games/haunted/src/shared/Config/HauntedTrees.luau`, `games/haunted/src/shared/Rules/GazeRules.luau`, `games/haunted/src/server/Services/HauntedTreeService.luau`, `games/haunted/src/client/HauntedTrees.luau`, `games/haunted/tests/GazeRules.spec.luau`, `games/haunted/tests/scenarios/HauntedTrees.luau`.
- **Modified:** `games/haunted/src/server/World/Habitats/Woodland.luau` (the planned `Props.luau` change became the new `World/HauntedTree.luau` plus `shared/TreeSight.luau`), `games/haunted/src/shared/Net.luau`, `games/haunted/src/server/init.server.luau`, `games/haunted/src/client/init.client.luau`.
- **Notes:** this note, a `TEST-` note, `00 Overview`, `02 Technical Architecture` (a new C→S remote), [[Map References]] (an ASSET-REF section).

## Acceptance criteria
- [ ] AC1 **Visuals:** *(everything below is evidenced except the taste call, which is jg's)*
  - Three visibly distinct archetypes, with A closest to ASSET-REF-001 and faces set into the bark.
  - Heights checked against an avatar in Studio (most 1.5–2×, some smaller).
  - About 50% of the new Woodland trees have faces.
  - The trunk, roots and branches never move.
  - Faces are readable in the darkest Woodland lighting without looking neon. Screenshots taken at gameplay distance.
  - Evidence: [[TEST-20261013-01]]. 3 archetypes; 8/16 faced; heights 1.4–2.0× against a 5.37-stud avatar; no trunk moved; faces readable in dark and lit spots after two fixes (heights, Pillar eyes hidden by a deep brow).
  - **Open:** jg's judgement that Pillar is "closest to ASSET-REF-001" and that the overall quality is acceptable. The part-built faces read as carved bark totems, blockier than the reference.
- [x] AC2 **Palette:** black, orange-yellow or purple at equal odds (spec), set once per instance on the server and identical on both clients. Evidence: `GazeRules.spec` (shares 0.28–0.39 over 3000 rolls); the server sets the `Palette` attribute once at build (`Woodland.luau`), and clients only read it. Two servers rolled different palettes, as intended ([[TEST-20261013-01]]).
- [x] AC3 **Gaze:** triggers within the configured range and angle. It does not trigger when the aim misses, when the face is behind the camera, or when the face is blocked (spec plus Studio). Evidence: `GazeRules.spec`; [[TEST-20261013-01]] (wall: no freeze; 20 studs: no freeze; normal camera 34° off: no freeze).
- [x] AC4 **Freeze and recovery:**
  - When caught, pupils return to rest, the face settles and animation stops.
  - The face resumes only after 1 continuous second with no observer, and reacquiring gaze cancels it. Recovery is gradual.
  - Interrupted animations always settle into a valid pose.
  - Evidence: [[TEST-20261013-01]]. Froze after 0.28 s with the pupil exactly at rest; resumed at 1.07 s and 1.20 s; a twitch, then back to tracking; a re-look during the delay cancelled it. Damped targets, with no tweens, by design. Rapid toggling was checked on the server side; the client-side visual under rapid toggling was not inspected frame by frame.
- [x] AC5 **Unobserved behavior:** eyes track the nearest visible player in range, otherwise idle glances and blinks. Eyes, lids and mouth are controlled independently. A mouth override hook exists. Evidence: [[TEST-20261013-01]] (pupils, lids and jaw moved independently on 4 unobserved faces; the eyes tracked a stationary player). `HauntedTrees.setMouthOverride` exists but is not exercised (no audio yet).
- [x] AC6 **Multiplayer (2 clients):**
  - A looks and both clients see the freeze. With A away and B still looking, it stays frozen. Both away → resumes after 1 s on both. A look during the delay resets it.
  - Leaving or resetting leaves no stale state, and rapid toggling leaves no leaks.
  - Evidence: [[TEST-20261013-01]], run 4 (20/20) and revision 1 (28/28), through the real client cameras and remote. Revision 1 also takes each client's own view: both saw `Frozen`, with pupils at rest, and both saw the resume. Disconnects are covered by the spec (expiry) and the `PlayerRemoving` code path, not by a Studio disconnect.
- [x] AC7 **Security:**
  - The remote checks tree, habitat, life, distance, facing and line of sight, and is rate-limited.
  - A report expires without a keepalive. It grants no gameplay effect and can't create or configure trees.
  - The trust boundary is documented.
  - Evidence: [[TEST-20261013-01]]. Forged far-tree and malformed reports every frame: no freeze, no observer left. Revision 1: forced reports skipping the client filter were rejected through a wall and from behind the tree, while the clear-view control froze. Also [[ADR-0010-Client-Reported-Gaze]] (proposed) and the trust-boundary section of `02 Technical Architecture`.
- [x] AC8 **Checks:** `scripts/check.sh` passes, existing Studio scenarios show no regression, and part and instance counts are recorded. Evidence: `scripts/check.sh` all pass (140 specs); Woodland `Reachability` 23/23 and `HabitatRotation` 28/28; 415 parts and 431 instances ([[TEST-20261013-01]]).

## Tests
- **Automated:** `scripts/check.sh` (new `GazeRules.spec.luau`).
- **Studio playtest procedure:**
  1. Check that `rojo serve haunted.project.json` is the only Rojo server (`ps aux | grep "rojo serve"`), then sync into the Haunted Collector place.
  2. Edit mode: compare an avatar against each archetype, and take screenshots at about 12 studs in the Thicket and the Clearing.
  3. 2-player Test (Server data model): run the `HauntedTrees` scenario (the AC6 sequence), reading the `Frozen` attribute from both clients.
  4. Re-run `FullLoop` and `HabitatRotation` for regressions.
  5. Record a `TEST-` note. 6-player behavior is **not** verified, because Studio is capped at 2 players.

## Risks / notes
- **Trust boundary:** the server can't see a client's camera. It accepts a "looking" report only when the reporter could plausibly see the face (near, in front, clear line of sight). A modified client near a tree could freeze it, but only while nearby and while sending rate-limited keepalives. The effect is purely cosmetic.
- **Idle animation per client:** the idle randomness (glance timing) is client-local, so two players may see slightly different idle motion. The `Frozen` state, palette and archetype are server-authoritative and identical everywhere.
- **Asset method:** Studio-native parts. This matches the Woodland's built-in-parts blockout (ADR-0007), needs no upload or approval, and avoids the untested Blender rig pipeline. Blender is installed (`/Applications/Blender.app`) but a mesh would need an asset upload, so it is out of scope.
- **Foundation docs:** `Task Intake` and `Resource Catalog` came with `origin/main` 9ed593e (ADR-0009). That merge was missing from the local main checkout, so the worktree branches from it.
- **Working-tree state, owner jg:**
  - TASK-0040 Audio Pass is `in_progress` with uncommitted work on this checkout's branch.
  - `Reference1.md`, `reference2.md`, `reference8.md`, their context notes and `Screenshot 2026-10-11 at 11.30.27 PM.png` are deleted but uncommitted.
  - The new ASSET-REF and screenshot files are untracked at the repo root.
  - This task does not touch any of these.

---
## Implementation record
- **Worktree and branch:** `/Users/jg/Desktop/Rg1-worktrees/TASK-0041`, `task/TASK-0041-Interactive-Haunted-Trees`, from `origin/main` 9ed593e.
- **Asset method:** Studio-native parts (see Risks). Archetypes:
  - **Pillar:** a thick cylindrical trunk with a flared base; a low face with a heavy flat brow.
  - **Broad:** squat and wide; a wide face with a V brow and teeth that show when the mouth opens.
  - **Angular:** an octagonal faceted trunk that leans; a narrow face with diamond sockets, a sharp V brow and thin spiky limbs.
- **Files:**
  - **New:** `shared/Config/HauntedTrees.luau` (all tuning), `shared/Rules/GazeRules.luau` (pure gaze test, observer aggregation, appearance), `shared/TreeSight.luau` (shared line-of-sight raycast), `server/World/HauntedTree.luau` (the prop), `server/Services/HauntedTreeService.luau`, `client/HauntedTrees.luau` (gaze reports, face animation, Studio-only test camera), `tests/GazeRules.spec.luau` (15 specs), `tests/scenarios/HauntedTrees.luau` (2 players).
  - **Changed:** `Woodland.luau` (16 trees placed along the trails after the existing scenery, so the seeded layout is unchanged), `Net.luau` (`TreeGaze`), the server and client `init`.
- **How it works:**
  - The client tests gaze at 15 Hz for faces within 40 studs (`GazeRules.qualifies` plus `TreeSight`). It fires `TreeGaze` only on changes, plus a "still looking" every 0.4 s.
  - The server checks plausibility, then applies `GazeRules.observe`, `release` and `step`, and writes `Frozen` on the tree model. One `task.delay` per tree is scheduled for the next expiry or resume, so there is no loop.
  - The client freezes a face when `Frozen` is set, or at once while it is itself looking (so the looker never sees it move).
  - On unfreeze, the face twitches and then blends back to idle over 1.2 s.
- **Tuning found in Studio:**
  - Trunk heights cut by 1–1.5 studs and the normal scale range set to 0.85–1.0. The first build measured 2.2–2.3 avatar heights.
  - Amber dimmed and moved toward yellow.
  - A rest mouth opening of 0.1, because a closed mouth was invisible.
  - Shallower brow and lids, because they hid the Pillar's eyes from the gameplay camera.
- **Scenario bug fixed (test code):** a `CharacterAdded:Wait()` after `LoadCharacter()` hung the scenario.
- **Checks:**
  - `scripts/check.sh` all pass: StyLua, Selene, types, 140 Lune specs, both Rojo builds, JSON, queue, vault, Python tests.
  - Studio: [[TEST-20261013-01]] (synced through MCP `Source` writes, hash-checked, because the Rojo plugin wasn't connected).
- **Revision 1** (jg, 2026-10-13: "fix the audit items now, then merge"). Fixes for [[AUD-20261013-TASK-0041-01]] findings 1–6:
  1. Releases have their own rate bucket, and a release from someone not observing that tree is ignored.
  2. A Studio-only `force:<id>` hook sends "looking" reports past the client filter, so the scenario now tests the server's wall and facing rejections.
  3. A Studio-only client-view report: each client tells the scenario whether it sees `Frozen` and where its pupils are.
  4. Woodland clearance uses each part's horizontal reach plus a 3.2-stud tree footprint.
  5. The client also requires head line of sight, matching the server.
  6. The resume-after-cancel step is bounded at 0.05–1.0 s.

  Checks: `check.sh` all pass; [[TEST-20261013-01]] revision 1 (28/28 two-player, `Reachability` 23/23).
- **Reference-code reuse:** SODT `PerceptionService`. Took the separate "seen now" flag, `os.clock()` timing and the idea of sending a throttled camera report. Did not take its polling loop or beast model.

## Audits
- [[AUD-20261013-TASK-0041-01]]: **pass with notes**. No blockers. Finding 7 (stale plan text) was fixed after the audit; findings 1–6 were fixed in revision 1.

## Outcome
