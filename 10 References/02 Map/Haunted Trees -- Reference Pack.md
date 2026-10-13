# Interactive Haunted Trees — Visual Reference Pack

Purpose: give Claude Code and the asset builder a shared visual direction for the Haunted Collector interactive tree feature.

## Reference hierarchy

1. **ASSET-REF-001_Primary-Physical-Reference.png** — authoritative for physical appearance: organic trunk, face integrated into bark, subdued horror atmosphere.
2. **ASSET-REF-002_Facial-Expression-Reference.png** — supporting inspiration for expressive eyes and mouth proportions; do not copy its scale literally.
3. **ASSET-REF-003_Alternate-Construction-Reference.png** — supporting inspiration for alternate sculpted features and silhouette. These three IDs are stable and must not be renumbered.
4. **Haunted-Trees_Overview-Concept-Board.png** — generated summary board for quick orientation. Treat any generated text, dimensions, or diagrams as approximate; the approved written specification is the source of truth.

## High-resolution archetype concept images (Higgsfield Soul Cinema)

These standalone images were generated as modeling references. Open each link and save the image into this folder if a local copy is needed by Claude Code:

- **Archetype A — Classic / subtle face / black eyes:** https://d8j0ntlcm91z4.cloudfront.net/user_3KX8LzqVgYxYPhb4jA7IPh9KIxo/hf_20261013_073603_bb0fb9de-6363-454d-9f03-47d03073c98d.png
- **Archetype B — Broad trunk / wider face / orangey-yellow eyes:** https://d8j0ntlcm91z4.cloudfront.net/user_3KX8LzqVgYxYPhb4jA7IPh9KIxo/hf_20261013_073623_070b5333-70b5-4c47-b351-4f0faf8681ec.png
- **Archetype C — Narrow angular trunk / purple eyes:** https://d8j0ntlcm91z4.cloudfront.net/user_3KX8LzqVgYxYPhb4jA7IPh9KIxo/hf_20261013_073535_8b8ce154-e947-489e-b328-5d177a219b0f.png

**Important:** the eye colors in the concept images are examples only. Runtime eye palette must be randomized independently of archetype with equal probability across black/dark, orangey-yellow, and purple; a specific color is not permanently tied to one tree type.

## Approved design brief

- Three distinct tree archetypes, sharing one reusable behavior system.
- Trees are stationary. Trunks, roots, and branches never move; only facial components animate.
- Organic, short imposing trees: most around 1.5–2 Roblox avatar heights, with some smaller trees; no giant redwood-scale trees.
- About half the intended forest trees have faces, distributed naturally.
- Faces are bark-integrated, subtle at first glance, with separately controllable 3D eyes, eyelids, and mouth.
- When unobserved, faces can track the nearest visible player within range, blink, glance, and occasionally move their mouths silently.
- A qualifying gaze begins when a face is visible and unobstructed, the player is within an initial tunable 9–14 studs, and the camera aims within an initial tunable 10–15 degree region around the face.
- When any player catches a tree looking, its eyes quickly return to rest and its expression becomes lifeless; the face freezes for everyone.
- The face resumes gradually only after no player has observed it for a continuous one second. A new observer cancels the pending resume.
- Leave hooks for future voice-synced mouth control, but do not add sound or voice lines to the initial implementation.

## How Claude should use these references

1. Inspect this pack and the actual local project references before modeling.
2. Use ASSET-REF-001 to anchor the overall physical style; use the other supplied images for secondary inspiration only.
3. Use the three Higgsfield renders to distinguish the proposed archetype silhouettes, not as exact reproducible meshes.
4. Do not infer exact stud dimensions, topology, rigs, UVs, collision, or animation implementation from rendered images. Determine these from the existing pipeline, a scale prototype, and Studio verification.
5. Preserve existing `MAP-REF-001` through `MAP-REF-007` and all their recorded visual observations. These asset references do not replace or renumber map references.
6. Follow the repository's actual `AGENTS.md`, task queue, asset workflow, and approval gates. Do not claim these references have been added to Obsidian until the real file operation is performed.

## Provenance

- Original inspiration images: supplied by the user in this conversation.
- Overview board: generated with OpenAI image generation for this concept brief.
- Three archetype renders: generated with Higgsfield Soul Cinema on 2026-10-13.
- State: **captured concept references**. They are not production meshes, tested rigs, or verified in-game assets.
