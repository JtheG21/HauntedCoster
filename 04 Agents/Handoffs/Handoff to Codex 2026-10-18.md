---
id: AGENT-Handoff-Codex-20261018
title: "Handoff to Codex: verify and finish the monetization baseline and the ported art"
type: agent
status: proposed
receiver: codex
created: 2026-10-18
updated: 2026-10-18
---

# Handoff (prompt for Codex): verify and finish the monetization baseline and the ported art

**Objective:** independently review everything Claude built on 2026-10-18, close the verification gaps (nothing was played in Studio), fix what that finds, and turn the follow-ups and jg's open decisions into scoped tasks.
**Receiver:** Codex (independent reviewer, then implementer for fixes jg assigns). **Why this tool:** Claude implemented every task below, so AGENTS.md "Claude and Codex" wants the other tool to review; Codex defaults to debugging, behaviour tests and security checks.
**Workspace:** `/Users/jg/Desktop/Rg1` (repo `JtheG21/HauntedCoster`, **not** `Rg1`), `main` at `727324e` or later, project `GAME-002`, code root `games/haunted/`. Use a worktree and a `chore/` or `task/` branch for anything you change; never commit to `main`.

## Start by
1. Read `AGENTS.md`, `04 Agents/Task Intake.md`, `04 Agents/Workflow.md` ("Who owns what").
2. `git -C /Users/jg/Desktop/Rg1 status`, then `python3 scripts/orchestrator.py status` (all tasks should be `done` or `archived`). Run `scripts/preflight.sh --root <checkout> --branch <name> &&` before any Git state change.
3. `scripts/check.sh` must print ALL CHECKS PASSED (265 Lune specs at the time of writing). Treat that as a baseline, not proof the game works.
4. If Studio, Rojo or a plugin connection is unavailable, stop and say so. Studio and Rojo are used by one assistant at a time; jg connects the Rojo plugin, and `scripts/studio-preflight.sh --root <checkout>` checks the setup.

## What was built (all merged, all `done`; each task note has an Implementation record with limits and an `AUD-` audit)
| Task | PR | What | Audit |
|---|---|---|---|
| 0059 | 94-96 | ExhibitRules corrupt tier guard; Light-tier closure path in the orchestrator | none (Light) |
| 0060 | earlier | Profile schema 2 `cosmetics` (entitlements, ghostLooks, captureEffect, mansionTheme, placements, rewardsClaimed) | Opus |
| 0061 | 102 | Shop and Owned UI, read-only `GetCatalog` | Sonnet |
| 0069 | 105 | Art salvage: ported art for 0042-0046 from `task/TASK-0046-Mansion-Plot-And-Train-Art` (not its cosmetics or UI) | Opus |
| 0062 | 106 | Ghost skin and aura equip (`EquipLook`, `LookRules`) | Sonnet |
| 0063 | 107 | Capture effect equip and preview (`EquipCaptureEffect`, `CaptureFx`) | Sonnet |
| 0064 | 108 | Mansion themes with tier coverage and upgrade fallback (`EquipTheme`, `ThemeRules`) | Sonnet |
| 0066 | 109 | Journal milestone rewards with Claim (`ClaimReward`, `MilestoneRules`, `Config/Milestones`) | Sonnet |
| 0065 | 110 | Exterior decoration editor (`EditDecoration`, `PlacementRules`, `DecorEditor`) | Opus |
| 0067 | 111 | Coin purchases (`BuyItem`, `PurchaseRules`, `PurchaseService`) | Opus |
| 0068 | 112 | Research note and draft ADR-0013 (Robux mechanism); no code | Opus |
| 0042-0046 | 113, 114 | Old overhaul-branch tasks closed as done or archived | n/a |

The monetization design is in `03 Games/GAME-002 Haunted Collector/05 Systems/SYS-Haunted-Monetization-UI.md` and `04 Decisions/ADR-0011-Monetization-UI-Scope.md`. Samples in `Config/Catalog.luau` (`SkinMoss`, `AuraEmbers`, `FxSparks`, `DecoLantern`, `ThemeMoonlit`) are placeholders; prices are placeholders.

## Phase 1: independent review (read-only first)
Verify, don't trust the notes or the audits. For each remote (`EquipLook`, `EquipCaptureEffect`, `EquipTheme`, `ClaimReward`, `EditDecoration`, `BuyItem`) in `src/server/Services/CosmeticService.luau` and `PurchaseService.luau`: argument validation, rate limit, atomicity inside one `PlayerDataService.update`, replay and race behaviour, and that a refusal changes nothing. Then the house upgrade path in `EconomyService.luau` (theme fallback, decoration storing, `markDirty`), `PlotService`/`PlotBuilder` (house tint, decorations, rejoin), and the ported art loading path (`ArtBakeService`, `client/Art/*`, `shared/Art/*`).

## Phase 2: Studio verification (needs jg to connect the Rojo plugin; run `studio-preflight` first)
Nothing below has been run. Use a fresh Play session (Server data model) for specs and `ExploitProbe`; see `05 Engineering/Multi-Client Testing.md` (max 2 Studio clients). To own the sample items in a test session, give the test profile Coins or entitlements through a Studio-only scenario shortcut and say so in the TEST note; do not touch live data.
1. **Art (TASK-0069):** creatures, habitat landmarks, mansion tiers 0-2, plot dressing and ghost train render; no console errors; note art bake time (~11 MB at server start, before `PlayerDataService`) and memory. Desktop and phone screenshots.
2. **Shop and Owned (0061):** tabs, filters, details, Back keeps scroll; layouts at 300-520 px; the Mansion header Shop button against the title.
3. **Buy (0067):** Buy then Confirm, pending state, exact shortfall, owned after purchase, rejoin keeps it. Run `scenarios/ExploitProbe` (extended with forged `BuyItem` calls) and `FullLoop`.
4. **Equip (0062, 0063, 0064):** skin and aura on pen and exhibit models, visible to a second client, survive rejoin; Spectral and Ashen refuse skins; capture effect plays after a real capture and the preview does not touch live models; a theme tints Walls, Trim and Roof, equip is refused at the Shack, and an upgrade past the covered tiers drops it with a notice.
5. **Journal (0066):** Claim appears only when eligible, grants once, the reward shows in Owned; replay refused.
6. **Decorations (0065):** place, move, rotate, store with the nudge buttons; ghost marker green and red; every plot orientation (`World.plotFrame`); keep-out areas match the real house, pen, exhibits and track area at each tier; an upgrade stores colliding decorations with a notice.
7. Record results in a `TEST-` note; anything unverified stays "needs a manual check".

## Known gaps and follow-ups (turn into scoped tasks through `Task Intake`; classify and ask jg to approve)
- **Load-time re-validation:** `CosmeticRules.sanitize` checks plot bounds and rotation only, so a saved decoration can reload into a keep-out area (`PlacementRules.refusal` at the stored tier). Opus audit finding on TASK-0065.
- **Stable placement IDs:** move and store use array indexes, so two in-flight edits can hit the wrong decoration.
- **Missing direct specs:** `CosmeticService.equipTheme`/`claimReward`/`editDecoration`/`equipCaptureEffect`, `PurchaseService.buy` and the `EconomyService` theme and decoration fallback have only pure-rule specs. Add behaviour tests (they need a fake profile and Remotes, or a Studio scenario).
- **Editor limits:** decorations move with buttons, not drag; no full-exterior theme preview (only coverage text and swatches); AC2 of TASK-0064 and AC1 of 0065 are partly unmet.
- **Cleanups from audits:** duplicate banner and refusal code in `ShopUI` and `CosmeticService`; entrance keep-out uses hard-coded z values in `PlacementRules.keepOut`; `firstSpot` scans the margin; `markDirty` calls after `update`.
- **TASK-0044's revision request was never done** (environment kit and ground); the code came across as it stood.
- **Robux:** nothing built. See `ADR-0013` (proposed) and its seven questions.

## Decisions only jg can make (collect them in one batch; do not decide for jg)
Prices (placeholders: SkinMoss 300, AuraEmbers 250, DecoLantern 150 Coins) from measured income; whether a purchase forces a save; the milestone list and which sample each reward grants (SpiderWoodland and Settlement have no milestone); decoration grid 2, fine 1, margin 3, caps; real item art meeting `10 References/05 Misc/3D Model Quality Baseline.md`; ADR-0013 options and questions (mechanism, prices, regional pricing, Listed, publishing, Coin versus Robux race, processed-receipt storage and two-server safety); visual approval of the ported art.

## Keep unchanged
Gameplay, income, capacity, rarity and capture rules; the Coin purchase atomicity in `PurchaseRules.apply`; server authority on every remote; no Robux, product IDs, prices set for real, publishing, uploads or live DataStore writes without jg's explicit approval.

## Constraints
- **Technical:** `--!strict`, tabs/StyLua, Selene, `scripts/typecheck.sh`. CI (`.github/workflows`) type-checks against **pinned older definitions** (luau-lsp 1.63.0), stricter than the local VS Code ones: newer engine APIs (`EditableMesh:BatchAdd`, `Terrain:ReadVoxels` returns) needed `any` casts. Test with `LUAU_DEFS` pointing at those definitions before opening a PR.
- **Process:** one owner per task; `approve --by jg`, `start`, `record-exec`, `record-audit --report`, `approve-merge --by jg` via `scripts/orchestrator.py`; audits by depth tier (economy, persistence and networking get an Opus audit); merges only after jg's approval, with `approve-merge` committed on the branch first.
- Log usage with `record-usage`. Claude's weekly plan was at 97% on 2026-10-18 and resets 2026-10-21, which is why this handoff exists.

## Acceptance criteria
- [ ] AC1 Review findings listed per remote and per system, each with file:line and a verdict.
- [ ] AC2 Studio checklist run, with a `TEST-` note and screenshots, or each unrun item marked "needs a manual check" with the reason.
- [ ] AC3 Follow-ups above filed as proposed tasks (not started) and jg's decisions collected as one list.
- [ ] AC4 `scripts/check.sh` green on every branch; no change to `main` without jg's merge approval.

## Report back with
Files changed, checks run and their output, the evidence for each acceptance criterion, what is unverified, and the remaining work, using: implemented and tested / implemented, not tested / planned / blocked / needs a manual check.


## Codex verification record (2026-10-18)
- **Reviewed:** main `494be30`; [[AUD-20261018-TASK-0069-02]] records per-remote and per-system verdicts. Changes requested; historical completed tasks stay terminal.
- **Implemented and tested:** documentation/evidence only on `chore/codex-handoff-review-20261018`, checkout `/private/tmp/rg1-codex-handoff-review`. No production fixes started.
- **Studio:** [[TEST-20261018-01]]; repaired 109 stale/empty scripts after Rojo connection, verified 151/151 source hashes, used memory-only test profiles, restored original source/helpers and verified again.
- **Results:** Server specs 265/0; ExploitProbe 14/14; art 333 parts/0 bake failures, about 10–11 s. Cosmetic service probe 32 pass/1 failure (saved blocked decoration retained). FullLoop aborts at :223 without an owned monster. Two-client appearance: only 1/2 observer reports, no pass claimed.
- **Needs a manual check:** full visual tour/reference comparison, all orientation/tier keep-outs, complete UI/input journeys, real-capture effect and isolated persistent rejoin. TEST note lists each omission and reason; screenshots preserved there.
- **Environment:** Haunted placeId 108419797534540, Edit, no test helpers/override; Rojo from main on localhost:34872. Main checkout's unrelated edits preserved.
- **Checks:** review branch `scripts/check.sh` ALL CHECKS PASSED with CI-pinned 1.63.0 definitions; 265 Lune specs, 157 Python tests.
- **Usage:** no reliable token-growth counter or billing was exposed; no token count estimated. Subscription use recorded separately.

## Proposed follow-ups (filed by Codex; no approval or start)
- [[TASK-0070-Decoration-Load-Revalidation]] — deep; high risk.
- [[TASK-0071-Stable-Decoration-Identity]] — deep; high risk.
- [[TASK-0072-Cosmetic-Service-Behavior-Tests]] — deep; high risk.
- [[TASK-0073-Complete-Mansion-Theme-Preview]] — standard; medium risk.
- [[TASK-0074-Decoration-Editor-Interaction-Completion]] — standard; medium risk.
- [[TASK-0075-Cosmetic-Cleanup-And-Placement-Constants]] — standard; medium risk.
- [[TASK-0076-Environment-Revision-Remediation]] — deep; high risk.
- [[TASK-0077-Monetization-Decision-Packet]] — light; low risk.
- [[TASK-0078-Art-Loading-Failure-Recovery]] — standard; medium risk.
- [[TASK-0079-Vacant-Plot-Decoration-Cleanup]] — standard; medium risk.
- [[TASK-0080-Monetization-And-Art-Studio-Verification]] — deep; high risk.
- [[TASK-0081-Finished-Cosmetic-Asset-Brief]] — standard; medium risk.
- [[TASK-0082-Readonly-Cosmetic-Mutation-Guard]] — deep; high risk.
- [[TASK-0083-Exhibit-Tier-Guard-Ordering]] — light; low risk.
- [[TASK-0084-FullLoop-Capture-Secure-Investigation]] — deep; high risk.
- [[TASK-0085-Narrow-Viewport-Hud-Navigation]] — standard; medium risk.

## Decisions for jg (one batch; all unanswered)
1. **Coin prices:** approve measured-income pricing for the placeholder SkinMoss 300, AuraEmbers 250 and DecoLantern 150 only after measurement; these values are not release approvals.
2. **Save policy:** should a Coin purchase force a confirmed save, and what should players see on save failure?
3. **Rewards:** approve the milestone list and sample reward mapping, including whether SpiderWoodland and Settlement need milestones.
4. **Decorations:** approve grid 2, fine 1, margin 3, per-item/global caps; confirm direct/drag interaction requirements against the baseline before an editor redesign. Any stable-ID schema migration requires separate approval.
5. **Finished art:** select and approve real cosmetic concepts meeting the quality baseline; review the ported creatures, habitats, houses and train visually. Current screenshots are evidence, not approval.
6. **ADR-0013:** choose products/passes/hybrid; individual items versus separately approved bundles; Robux prices/regional pricing; Listed status; publishing timing and product creator; dual Coin/Robux purchase race policy; processed-receipt storage/retention and two-server safety. ADR remains proposed; no implementation/product IDs/spend/publishing authorized.
7. **Work priority:** approve or amend the scoped proposals before implementation. Recommendation: readonly mutation guard and FullLoop investigation first, then decoration safety and missing behavior evidence. This is a recommendation, not a priority decision by jg.


## Reported stale updates: source reconciliation (2026-10-18)
[[RSH-20261018-Delivered-Update-Reconciliation]] identifies the accepted Wisp revision and imported-mesh dependency chain as missing from main; [[TASK-0086-Accepted-Wisp-Revision-Recovery]] is proposed, not started. The original z-fighting commit and environment revision `3ddc2e6` are already ancestors of main; the earlier claim that no environment revision was done was inaccurate about the code. Current tree source/data match the preserved revision branch; z-fighting/tree symptoms still need location-specific reproduction. Art tooling and unfinished placeholder audio also remain on side branches. Old overhaul UI/backend exclusions were deliberate. No production fixes or branch merges performed.
