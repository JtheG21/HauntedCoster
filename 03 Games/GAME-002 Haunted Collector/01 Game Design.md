---
id: GAME-002-DESIGN
title: Game Design
type: design
project: GAME-002
status: proposed
version: 0.1
created: 2026-10-11
updated: 2026-10-11
tags:
  - game/design
related:
  - "[[INBOX-20261011-Haunted-Collector-Brief]]"
  - "[[ADR-0005-Haunted-Collector-Direction]]"
---
# Game design: Haunted Collector (draft v0.1, **proposed**)

> This draft is derived from [[INBOX-20261011-Haunted-Collector-Brief]]. Every number below is an **unvalidated starting guess**, kept in config so it can be tuned. The brief remains the requirement source. This note records the choices it left open.

## Pitch (1–2 sentences)
Explore an eerie graveyard with a flashlight, capture strange creatures, and race them home before they escape. Each one makes your haunted mansion and your self-built ghost train ride worth more.

## Target players & session length
Roblox players aged about 9–15 who like collection, tycoon and light spooky themes. First session 10–20 minutes. The first capture-and-return happens within about 5 minutes.

## Core loop
Explore → investigate landmarks (clues) → inspect a monster (rarity, value, variant) → capture meter → carry it home under a timer while slowed → secure it in containment → acclimation → passive income → buy a speed upgrade or house tier → the editor unlocks → edit the route and place exhibits → ride → server payout → a clue to a rarer monster → explore again.

## Systems (MVP)
- **Map:** one compact graveyard next to a row of home plots. Areas: Gate path (lit, tutorial), Old Rows (ordinary), Mausoleum Hollow (dark), and the **Sealed Crypt** (gated: it opens after the player investigates 3 landmarks *and* reaches house tier 1; better spawns and the rare). 4–5 landmarks, such as the Weeping Angel, the Bell Tower, the Broken Hearse and the Crypt Door. Each one adds a journal clue and a marker, and one unlocks a shortcut back to the plots.
- **Flashlight:** a client SpotLight tool, always on, with no battery. Darkness comes from Lighting and Atmosphere, kept readable with lanterns and silhouettes along the paths. A home beacon is visible from the graveyard.
- **Roster (4):** Wisp (ghost, common), Stitched Hound (distorted animal, common), Hollow Gentleman (unsettling figure, uncommon), Bell Wraith (bizarre, rare: it only appears in the Sealed Crypt after the Bell Tower clue). Each is a placeholder model built from parts with a distinct silhouette.
- **Variants:** a colour or particle overlay on the base model. Natural chance about 8%. The special "Ashen" variant is tied to the Bell Tower clue. Income ×1.5 (tunable from 1.3 to 1.7).
- **Inspect:** a ProximityPrompt shows the name, rarity, variant label and an estimated income per minute.
- **Capture meter:** hold to fill while a needle sweeps. Release inside the green zone, which narrows with rarity, for one success. The server stores the timing; the client only sends the release time. Three misses scare the monster off.
- **Return trip:** a timer of 90 s (common) to 120 s (rare). WalkSpeed ×0.7 while carrying. The beacon and an on-screen arrow point home. Securing happens at your own containment pad. Failure means the capture escapes ([[ADR-0005-Haunted-Collector-Direction]]).
- **Containment:** owned monsters are listed in the roster. Acclimation takes 60 s, then the monster earns full passive income. Base income: common 2/s, uncommon 4/s, rare 10/s, times the variant multiplier. These are draft numbers.
- **House tiers:** Tier 0 Shabby (starter). Tier 1 Restored, cost 300: adds space and unlocks the **track editor** and the Sealed Crypt key. Tier 2 Grand, cost 2,000: more exhibit slots and capped offline income (max 2 h, 25% rate). The **speed upgrade** costs 100 per level, 3 levels, +2 WalkSpeed each.
- **Ghost train:** a fixed starter loop works from the start. The server moves the cart along a sampled spline with CFrame, so there is no physics. Payout on server-confirmed completion = base 50 × tier multiplier × (1 + 0.1 × exhibits in range, rarity-weighted) × route quality (0.9–1.2, from length and turn variety). There is a cooldown between paid rides.
- **Track editor:** control points inside the plot bounds, 4 to 16 points, total length 60–300 studs. Add, move and delete points, with a live preview, Confirm, Cancel and Exit. The server re-validates the route, and a rejected edit keeps the last valid route. There are 2 special pieces: a Scare Arch (+quality) and a Fog Tunnel. Exhibits use fixed slots near the plot, and the editor shows which slots sit within range of the route.
- **Journal:** known and unknown entries for types and variants, plus the clue list. Completion rewards are trophies on the mansion only, with no stat bonuses.
- **Tutorial:** a 12-step state machine following brief §12. It is saved, each step has a skip-forward check (for example, if the player already owns a monster, step 6 is complete), and it never blocks normal play.

## Progression & retention
Expanding the house unlocks systems, exhibits raise the train's value, and clues open the Sealed Crypt and the rare. The intended return hook is the Bell Wraith clue revealed after the first ride.

## Social features
Players visit each other's plots, and one guest can ride with the owner if that's cheap to build. Otherwise it's deferred.

## Monetization
None in the MVP. No product IDs, crates or paid monsters. Cosmetics first later ([[INBOX-20261011-Haunted-Collector-Brief]] §14).

## MVP scope
| Feature | Priority | Status |
|---|---|---|
| Player data, plots, persistence | P0 | proposed (TASK-0011) |
| Graveyard, flashlight, landmarks | P0 | proposed (TASK-0012) |
| Monsters, inspect, capture meter, variants | P0 | proposed (TASK-0013) |
| Return trip, containment, passive income | P0 | proposed (TASK-0014) |
| House tiers, speed upgrade, offline income | P0 | proposed (TASK-0015) |
| Starter train, server cart, exhibits, payout | P0 | proposed (TASK-0016) |
| Track editor | P0 | proposed (TASK-0017) |
| Journal UI, tutorial, rare clue | P0 | proposed (TASK-0018) |
| Guest rider | P2 | optional in TASK-0016 |

## Non-goals
Brief §15: second region (Haunted Forest and Mine is the first post-MVP update), branching track, train physics, breeding, trading, battery, quest chains, weather and time spawns, paid randomness, housing editor.

## Open questions
1. The expedition-failure rule (draft in ADR-0005).
2. Economy numbers are guesses; tune them after the first playtest.
3. Guest rider: include in TASK-0016 or defer?
4. Sound: use `roblox-sfx` to source Creator Store audio (offline sourcing only, no upload), or ship silent?
