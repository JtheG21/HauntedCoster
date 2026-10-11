---
id: INBOX-20261011-Haunted-Collector-Brief
title: Haunted Collector MVP Brief
type: inbox
status: inbox
project: GAME-002
created: 2026-10-11
updated: 2026-10-11
tags:
  - inbox/brief
related:
  - "[[GAME-002 Haunted Collector/00 Overview]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# Haunted Collector MVP Brief (source request)

The user pasted this brief into chat on 2026-10-11. They asked for it to become a new game, GAME-002, under the studio workflow: an overview, an ADR and proposed tasks, with **no code until approved**. It does not replace GAME-001.

**Workflow overrides.** The brief says to work in one pass and not ask for per-feature approval. [[AGENTS]] (one scoped task at a time, human approval gates) takes precedence. On 2026-10-11 the user chose the "New GAME-002 setup" path.

The text below condenses the brief section by section. Every requirement, limit and prohibition is kept, but repetition and prose are tightened, so this is **not a verbatim copy**. Paste the original below if exact wording is ever needed. §7 mentions "Round 19" options whose wording was not preserved. Per the brief, they are not reconstructed here.

---

## 1. Role and mission
Act as a senior Roblox game developer, Luau engineer, gameplay systems designer, technical artist, UI developer, and QA engineer. Inspect, implement, integrate, and test a complete, playable MVP of the haunted-house game inside the existing development environment. Implementation, not another design document. Work independently. If a tool, asset, service, or capability is unavailable, use the simplest reliable alternative and continue. Do not claim to have tested or implemented something that could not be verified.

## 2. Inspect and preserve the existing environment first
Inventory Studio services, the Workspace, maps, assets, scripts, remotes, UI, build tooling, conventions, saving/currency/progression systems. Use the workflow that actually exists (filesystem/Rojo if present). Preservation rules: reuse existing assets and systems; do not wipe the map or reset the project; no duplicate systems; preserve unrelated parts; adapt conflicting systems safely; if mostly empty, create the smallest coherent structure; never invent asset IDs, credentials, developer-product IDs or external dependencies; if something cannot be modified, finish the rest and report the outstanding requirement.

## 3. Concept
Explore an eerie graveyard, discover and capture strange creatures, risk a dangerous return trip to a haunted mansion, and use the collection to build a personalised, rideable haunted train attraction. Fantasy: hunt something frightening → risk losing it on the way home → turn it into a better attraction → build a better ride → venture farther for something rarer. Differentiation is the connection: personal exploration to find monsters; capture creates a meaningful return journey; creatures become part of the mansion and attraction; creative track and display decisions; the train grows in value with mansion and collection; clues drive return expeditions. Not a generic simulator, not a generic cart builder, not complex survival horror.

## 4. Design priorities (in order)
1. Functioning end-to-end loop. 2. Clear first-session tutorial. 3. Responsive cross-platform interactions (PC, mobile, console). 4. Meaningful link between exploration, collection, house progression and train income. 5. Reliable saving, server authority, basic exploit protection. 6. Haunted atmosphere and satisfying feedback. 7. Small, extendable architecture.
First meaningful capture-and-return loop in about five minutes or less. Small but complete scope.

## 5. Primary loop
1. Spawn at own shabby haunted house plot. 2. See a fixed starter ghost train; short intro to hunting and building. 3. Enter a compact graveyard with a flashlight and clear landmarks. 4. Inspect landmarks, record clues, encounter roaming monsters. 5. Inspect a monster's appearance, rarity and estimated value before capture. 6. Simple readable capture-meter challenge. 7. On capture, a return timer starts; carrying slows the player. 8. Navigate home in the dark. 9. Secure the monster; collection and progression rewards; passive income after a short acclimation. 10. Spend on a movement upgrade or first house expansion. 11. First meaningful house upgrade unlocks custom track editing. 12. Edit a route with control points, validate it, position monster exhibits near the track. 13. Ride the attraction; payout on completion. 14. Reveal a clue toward a rarer monster or harder discovery. 15. Clear reason to start another expedition.

## 6. World and exploration
**Starting environment:** outskirts of an old graveyard. One compact connected map: readable entrance and return route; tombstones, mausoleums, crypt entrances, paths, fences; several distinctive landmarks for navigation and clues; one atmospheric dark section; one harder gated section with more valuable encounters; clear relationship to the home plot. Do not build an enormous map.
**Darkness and navigation:** flashlight plus visible landmarks. Usable flashlight; atmospheric darkness that is not unfair; distinctive light sources, signs, silhouettes; distinction between ordinary and dangerous areas; reasonable visibility of paths, obstacles and the way home. **No flashlight battery management.** Darkness creates tension, not frustration.
**Landmarks and regional tasks:** gameplay objects. Visiting/investigating records clues in a lightweight journal, reveals/updates map markers, improves finding unusual encounters in the region, occasionally reveals a route or unlocks a meaningful shortcut (reserve shortcuts for milestones). Few simple interactions; no long puzzle chains or quest trees.
**Special encounters:** most monsters found by location and exploration; a few need one additional readable condition (visit a landmark, investigate evidence). No complicated weather/time/random/hidden-objective combinations for the first rare encounter. The player understands what they found and the next practical step.

## 7. Monsters, capture, variants
**Roster:** three or four distinct types drawn from ghosts/spirits, distorted animals, human-like freaks/unsettling figures, bizarre supernatural creatures. Use existing models or recognisable placeholder creatures from built-in parts. Distinct silhouette, appearance, display name, identity. Data-driven definitions.
**Pre-capture info:** name/identity, rarity, estimated value/economic usefulness, visible variant info. Informed risk-taking.
**Capture mechanic:** one reusable capture-meter minigame; clear instructions; obvious success/failure; brief; visual/audio feedback where assets permit; difficulty configurable by rarity; server validates results.
**Transport and escape:** visible return timer; movement-speed penalty while carrying; clear home destination/direction; meaningful consequence for failing recovery; reliable way to secure on return. A failed recovery may create a chase setback or require another encounter. **It must never delete monsters already permanently owned.** (The original Round 19 multiple-choice wording for transport and escape recovery was not preserved; do not invent its meaning. Use the explicit behaviour above.)
**Variants:** visibly recognisable (colour, markings, silhouette details, simple effect); mostly natural encounters, a few special variants tied to clues or conditions; clearly labelled; moderate meaningful income advantage (not mandatory-grind powerful, not pointless); variant data separate from the base definition; reuse the base model.

## 8. Collection journal and discovery rewards
Lightweight journal: permanently discovered types and variants; known and unknown entries; preserved clues; works with map markers; shows what remains. Rewards are cosmetics, trophies or display achievements; **no permanent power bonuses** for catalog completion. Persistent via the normal saving system.

## 9. Mansion, containment and economy
Start: shabby starter house, modest building space, basic containment, room for the starter train. Implement: one basic containment system; roster of owned monsters; short acclimation before full passive income; a small number of meaningful house tiers; a movement-speed upgrade; an early expansion that unlocks route editing; later tiers unlock selected advanced economic or attraction features. Expansions add usable space; not purely cosmetic.
**Early economy:** secure → onboarding reward → passive income after acclimation → affordable early upgrade → first expansion unlocks train editing. No grinding or long timers to reach the first upgrade.
**Later economy:** train income grows in importance. Balance with house tier/upgrades, rarity and variant bonuses, route quality (controlled range), monsters displayed near the attraction, train/attraction upgrades. Tunable config for prices, payouts, acclimation, variant bonuses, route limits. Capped offline income may unlock at a later tier, bounded and based on validated saved timestamps.
**Placement and roles:** monsters contribute passive income via containment; monsters displayed near the route contribute to attraction payouts; simple placement rules respecting the owner's plot; a few practical exhibit positions rather than free placement. Preserve the option of later dual-role upgrades.

## 10. Ghost train and player-built track
Central feature; players see, modify and ride their attraction.
**Starter train:** functional fixed starter ride from the start; works before the editor unlocks.
**Track editor:** unlocks after the first house expansion. Control-point editor: tap/click to add points; select to reposition or remove; platform-appropriate controls; readable preview; stays within the building area; max length and point count; clear confirm, cancel and exit. Not a CAD tool.
**Route validation:** convert saved control points into visible track geometry; reject too short, too long, out of bounds or otherwise invalid; incomplete edits never corrupt the last valid route; a small selection of special pieces or effects; route saved across sessions.
**Cart movement:** the cart actually follows the route; dependable movement with clear start and completion; not fragile client physics; client never sets its reward. Owner can ride; one additional rider where feasible; single-player must stay reliable.
**Payout:** validated server-side on legitimate completion; may depend on completion, house/attraction upgrades, eligible displayed monsters, variant bonuses, a small route-quality modifier. No payouts for start-then-cancel or remote spam. Make the upgrade → income relationship visible.

## 11. Interface
Functional UI for currency and income; objectives and return timer; capture and outcomes; rarity and value; owned roster; journal and clues; house upgrades and costs; track editing and validation; ride start/completion/payout; unlocks and next recommended action. No excessive menus, text dumps or complex inventories. Concise, readable, works across aspect ratios and inputs; nothing hover-only. Consistent haunted-attraction look using engine elements; no unverified external visual assets.

## 12. Tutorial and first session
1. Arrive, notice the train. 2. Learn to enter the graveyard. 3. Investigate a nearby landmark. 4. Find an ordinary monster, inspect rarity and value. 5. Learn the capture meter. 6. Capture; recognise the return journey began. 7. Return and secure. 8. See collection and passive-income progress. 9. Buy the first upgrade. 10. Unlock and try the editor. 11. Complete the starter ride and see the payout. 12. Discover a clue that gives a reason to return.
Compact tutorial state machine that resumes sensibly and never traps the player. Introduce instructions when useful. Show why the collection matters to the train.

## 13. Persistence and multiplayer reliability
Persist currency and economic progression, owned monsters and variants, collection and clues, house state, unlocked systems, validated track layout, offline-income timestamps. Server-authoritative with safe defaults, protected DataStore calls, retries and validation. Never trust the client to award currency, declare captures, grant monsters, complete rides or purchase upgrades. Validate remote inputs, distances, ownership, prices, cooldowns, requirements. No cross-plot edits via client identifiers. Never save malformed values. Avoid racing saves. Handle failures without crashing. Never delete existing data during migration. Keep temporary expedition state separate from permanent ownership. If DataStores are unavailable in local testing, use a clearly reported fallback; never claim persistence was verified when it wasn't. Works for one or more players.

## 14. Monetization boundaries
Future direction: cosmetics first (mansion themes, train looks/effects, track styles/lighting, display effects, trophies), restrained convenience second. For the MVP: gameplay economy first; no Robux required for the first session; no paid-exclusive monsters; no paid random crates; no invented product IDs; no artificial waits to push spending; leave a clean extension point, no nonfunctional purchase buttons.

## 15. Out of MVP scope
Second region; the Haunted Forest and Mine biome (first major update afterwards, reusing capture, return, clue, collection and economy systems with a few new monsters and one signature encounter); large rosters; branching track; complicated train physics; NPC/employee simulation; breeding; trading; complex survival; flashlight battery; long quest chains or puzzles; extensive weather/time spawns; paid random items; complex housing customisation; large multiplayer train capacity; elaborate catalog stat trees.

## 16. Technical requirements
Clear responsibilities for shared config and monster definitions; server encounters and capture validation; player data and progression; economy and upgrade validation; house and plot ownership; track construction, validation and persistence; server-controlled cart completion and rewards; client UI and input; journal and clues; tutorial. No god script, no excessive abstraction. Config values in one manageable place. Check instances exist before use; no unprotected assumptions about character, respawn, plot assignment, PrimaryPart, movement state or script start order. No unnecessary external libraries. No silent placeholder functions behind working-looking UI. Report simplifications.

## 17. Visuals and performance
Spooky, strange, playful, commercially approachable; not excessively dark or noisy. Clear landmarks, distinct silhouettes, identifiable home plot, visible starter train, recognisable capture feedback, clear route previews, obvious reward feedback, good low-end performance. Reuse base models; avoid unanchored parts, unnecessary constraints, uncontrolled particles, costly per-frame loops. Missing sounds, animations or models must not break the game.

## 18. Competitor-informed checks
The player must do something interesting to acquire monsters; the return trip has tension; the train is more than a passive-income button; the editor allows a genuine creative decision; monsters change the attraction's appeal or value; the house becomes more functional; landmarks drive discovery; the first rare-monster clue creates a concrete reason to return. Cut systems that don't feed the loop. Don't use competitor popularity as proof.

## 19. Testing and completion criteria
**Integrity:** starts without new critical errors; required instances exist; references resolve; existing environment intact. **Exploration:** graveyard navigable; flashlight and landmarks work; landmark interactions record discoveries; indicators update; encounters spawn in valid locations; gated area has a readable requirement. **Capture and recovery:** inspect before capture; success and failure states; capture starts the timer; carrying slows; returning home adds the capture; failure never deletes the collection. **Economy:** roster shows owned monsters; acclimation and income work; currency updates; valid upgrades purchasable; insufficient funds and locks handled; first expansion unlocks the editor; no repeat-income exploits. **Track and rides:** starter ride usable pre-editor; editor opens on unlock; points placed and manipulated; invalid routes rejected; last valid route preserved; cart follows the route; eligible monsters contribute; completed ride pays out server-side; route saved and restored. **Saving and UI:** journal consistent; progress survives leave/rejoin; UI communicates outcomes; input usable on supported platforms; DataStore failures and missing assets don't crash.
Do not claim live multiplayer, mobile or persistence tests that weren't performed. List unverified tests.

## 20. Definition of done
A new player arrives at a small haunted mansion, discovers a fixed starter train, ventures into the graveyard, identifies and captures a monster, brings it home under pressure, sees it added to the collection, begins earning income, buys an upgrade, unlocks a custom track, builds and rides a working attraction, receives a payout, and discovers a clue toward a more unusual creature. Progress is preserved by the saving system. Compact map, small roster, functional train, connected systems. The expansion is not built prematurely.

## 21. Final report requested
1. What was built. 2. What was reused. 3. What changed. 4. What was tested. 5. What remains incomplete. 6. How to playtest in Studio. 7. Next recommended milestone.
