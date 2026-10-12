---
id: GAME-002-DESIGN
title: Game Design
type: design
project: GAME-002
status: proposed
version: 0.4
created: 2026-10-11
updated: 2026-10-12
tags:
  - game/design
related:
  - "[[INBOX-20261011-Haunted-Collector-Brief]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
  - "[[ADR-0006-M1-Tuning-And-Scope-Decisions]]"
  - "[[ADR-0007-World-Retrofit-Direction]]"
---
# Game design: Haunted Collector (draft v0.4, **proposed**)

> This draft is derived from [[INBOX-20261011-Haunted-Collector-Brief]]. Every number below is an **unvalidated starting guess**, kept in config so it can be tuned. The brief remains the requirement source. This note records the choices it left open.

## Pitch (1–2 sentences)
**Public hook (Round 20 Q5): "Build your haunted train."** Collect monsters and build a ride your friends can experience.

Explore an eerie graveyard with a flashlight, capture strange creatures, and race them home before they escape. Each one makes your haunted mansion and your self-built ghost train ride worth more.

## Target players & session length
Roblox players aged about 9–15 who like collection, tycoon and light spooky themes. First session 10–20 minutes. The first capture-and-return happens within about 5 minutes.

## Core loop
Explore → inspect a monster (rarity, value, variant) → capture meter → carry it home under a timer while slowed → secure it in containment → acclimation → passive income → buy a speed upgrade or house tier → the editor unlocks and the Sealed Crypt opens → edit the route and place exhibits → ride → server payout → hunt again, now for the crypt's rare. (v0.4: clue hunting removed, [[ADR-0007-World-Retrofit-Direction]].)

## Systems (MVP)
- **Map:** one compact graveyard next to a row of home plots. Areas: Gate path (lit, tutorial), Old Rows (ordinary), Mausoleum Hollow (dark), and the **Sealed Crypt** (gated: it opens at house tier 1, the Restored Manor; better spawns and the rare). Five landmarks (Weeping Angel, Bell Tower, Broken Hearse, Hollow Mausoleum, Old Well) are scenery and navigation points. They have no prompts and give no clues (v0.4). The west gap by the Old Well is always open. *M3 replaces this layout with radial plots and rotating habitats ([[ADR-0007-World-Retrofit-Direction]]).*
- **Flashlight:** a client SpotLight tool, always on, with no battery. Darkness comes from Lighting and Atmosphere, kept readable with lanterns and silhouettes along the paths. A home beacon is visible from the graveyard.
- **Roster (4):** Wisp (ghost, common), Stitched Hound (distorted animal, common), Hollow Gentleman (unsettling figure, uncommon), Bell Wraith (bizarre, rare: it lives only in the Sealed Crypt, at most one per server, and needs a Restored Manor to capture; v0.4). Each is a placeholder model built from parts with a distinct silhouette.
- **Variants:** a colour or particle overlay on the base model. The natural variant "Spectral" rolls 10% anywhere, ×1.5 income. The special **"Ashen"** variant is environmental: it rolls 30% only for monsters spawning in the Sealed Crypt, ×1.75 income ([[ADR-0006-M1-Tuning-And-Scope-Decisions]]).
- **Inspect:** a ProximityPrompt shows the name, rarity, variant label and an estimated income per minute.
- **Capture meter:** hold to fill while a needle sweeps. Release inside the green zone, which narrows with rarity, for one success. The server stores the timing; the client only sends the release time. A miss **startles** the monster: the meter closes and it hops 8–14 studs within its zone, and the player walks up and tries again. Hits and misses carry over between attempts, and it flees for good when the rarity's misses-allowed is used up (Common 2, Uncommon and Rare 3; revisit after Round 21 Q1). (v0.3, Round 20 Q2)
- **Return trip:** a timer of 75 s (common), 90 s (uncommon) or 120 s (rare). Carrying slows WalkSpeed to ×0.6 at speed level 0, and each Running Shoes level shrinks the penalty: ×0.7, ×0.8, ×0.9 (v0.3, Round 20 Q3). The beacon and an on-screen arrow point home. Securing happens at your own containment pad. **Escape chase (v0.3, Round 20 Q1):** when the timer runs out, the capture breaks free about 10 studs away and runs at 12.5 studs/s for 15 s. It stays on its side of the graveyard fence, and the HUD points at it. Get within 6 studs and press E to grab it, and the carry resumes with 20 s. It can only break free once per capture. If the chase runs out (or the player dies, leaves, or trips the speed check), it returns to its habitat and can be found again later; owned monsters are never lost ([[ADR-0005-Haunted-Collector-Direction]]).
- **Containment:** owned monsters are listed in the roster. Acclimation takes 30 s, then the monster earns full passive income. Base income per second: Wisp 1, Stitched Hound 1.5, Hollow Gentleman 3, Bell Wraith 8, times the variant multiplier. Official for M1 ([[ADR-0006-M1-Tuning-And-Scope-Decisions]]), tunable after playtests.
- **House tiers:** Tier 0 Shabby (starter). Tier 1 Restored, cost 250: adds space and unlocks the **track editor** and the Sealed Crypt key. Tier 2 Grand, cost 1,500: more exhibit slots and capped offline income (max 2 h, 25% rate). The **speed upgrade** has 3 levels costing 75, 200 and 450, +2 WalkSpeed each.
- **Ghost train:** a fixed starter loop works from the start. It includes one Scare Arch and passes one display (exhibit slot 2) so the first ride shows riding, monsters and a scare without being a tutorial level (v0.3, Round 20 Q4). The server moves the cart along a sampled spline with CFrame, so there is no physics. Payout on server-confirmed completion = base 40 × tier multiplier × (1 + 0.1 × exhibits in range, rarity-weighted) × route quality (0.9–1.2, from length and turn variety). There is a 20 s cooldown between paid rides.
- **Track editor:** control points inside the plot bounds, 4 to 16 points, total length 60–300 studs. Add, move and delete points, with a live preview, Confirm, Cancel and Exit. The server re-validates the route, and a rejected edit keeps the last valid route. There are 2 special pieces: a Scare Arch (+quality) and a Fog Tunnel. Exhibits use fixed slots near the plot, and the editor shows which slots sit within range of the route.
- **Journal:** known and unknown entries for types and variants, with where each lives. Completion rewards are trophies on the mansion only, with no stat bonuses. Species you've inspected glow and show their name in the world. (v0.4: the clue list and the Grave Scholar trophy are retired; old clue data stays in profiles.)
- **Tutorial:** a 12-step state machine after brief §12. Step 1 finishes on reaching your station, and step 8 on opening the Mansion or Journal. Steps 3 (explore up to a monster) and 12 (enter the Sealed Crypt) replaced the two clue steps in v0.4, so saved step numbers keep their meaning. It is saved, each step has a skip-forward check (for example, owning a monster completes steps 1–7), and it never blocks normal play. Catching the Bell Wraith is the post-tutorial hook, not a step.

## Progression & retention
Expanding the house unlocks systems, exhibits raise the train's value, and the Restored Manor opens the Sealed Crypt and its rare. The intended return hook is the Bell Wraith in the crypt.

## Social features
Players visit each other's plots, and one guest can ride with the owner if that's cheap to build. Otherwise it's deferred.

## Monetization
None in the MVP. No product IDs, crates or paid monsters. Cosmetics first later ([[INBOX-20261011-Haunted-Collector-Brief]] §14).

## MVP scope
| Feature | Priority | Status |
|---|---|---|
| Player data, plots, persistence (M1: memory-only accepted, rejoin test in M2, [[ADR-0006-M1-Tuning-And-Scope-Decisions]]) | P0 | proposed (TASK-0011) |
| Graveyard, flashlight, landmarks | P0 | proposed (TASK-0012) |
| Monsters, inspect, capture meter, variants | P0 | proposed (TASK-0013) |
| Return trip, containment, passive income | P0 | proposed (TASK-0014) |
| House tiers, speed upgrade, offline income | P0 | proposed (TASK-0015) |
| Starter train, server cart, exhibits, payout | P0 | proposed (TASK-0016) |
| Track editor | P0 | proposed (TASK-0017) |
| Journal UI, tutorial, rare hook (clues removed in v0.4) | P0 | proposed (TASK-0018, TASK-0025) |
| Guest rider | P2 | optional in TASK-0016 |

## Non-goals
Brief §15: second region (Haunted Forest and Mine is the first post-MVP update), branching track, train physics, breeding, trading, battery, quest chains, weather and time spawns, paid randomness, housing editor.

## Open questions
1. The expedition-failure rule (draft in ADR-0005).
2. Economy numbers are guesses; tune them after the first playtest.
3. Guest rider: include in TASK-0016 or defer?
4. Sound: use `roblox-sfx` to source Creator Store audio (offline sourcing only, no upload), or ship silent?
