---
id: REF-3D-QUALITY-BASELINE
title: 3D Model Quality Baseline
type: research
status: research
sources:
  - /Users/jg/Desktop/3dModels
  - /Users/jg/Desktop/3dModelRef
confidence: high
created: 2026-10-13
updated: 2026-10-15
tags:
  - reference/3d
  - studio/art-quality
---
# 3D Model Quality Baseline

## Question
What visual finish must every future model meet? This is a studio-wide reference for Claude and Codex, including creatures, props, vehicles, trees, buildings and paid cosmetic assets.

**User requirement (jg, 2026-10-13):** the models in `3dModels` worked well but looked bad and are examples of what not to repeat. The assets in `3dModelRef` are the **bare minimum acceptable quality**, with a goal of doing better. A model request means a finished visual asset; a simple-looking placeholder does not satisfy it. The written criteria below are the agent's interpretation of the inspected examples and remain refinable by jg. This does not replace existing approved game design or approve any new asset implementation.

## Sources
| Source | Location | Accessed |
|---|---|---|
| Rejected results, 17 screenshots | `/Users/jg/Desktop/3dModels` → `3D Model Quality/Rejected/` | 2026-10-13 |
| Minimum standard, 70 screenshots | `/Users/jg/Desktop/3dModelRef` → `3D Model Quality/Minimum Standard/` | 2026-10-13 |
| Complete original filename, dimensions and SHA-256 mapping | `3D Model Quality/manifest.json` | 2026-10-13 |
| All images with stable IDs, embedded boards and links to originals | [[3D Model Quality Gallery]] | 2026-10-13 |

The supplied folder was called `3dModelsRef` in chat; the actual Desktop folder is `3dModelRef`. Originals were copied without alteration or deletion. The copy IDs are MODEL-BAD-001–017 and MODEL-MIN-001–070, assigned by original filename order. IDs never change when new references arrive. They are separate from monetization's MON-REF IDs.

## Observed mechanics (verified)
All 87 screenshots were visually inspected on eight contact sheets; representative originals BAD-005, BAD-012, BAD-013, MIN-015, MIN-031, MIN-038 and MIN-067 were opened individually. These are screenshot observations, not mesh/topology or performance inspections.

| Reference group | Visible qualities / failure pattern |
|---|---|
| BAD-001–005, haunted trees | Repeated cylinder-like trunk masses, abrupt chunky branch/root joins, limited taper and surface shaping; rectangular facial features feel attached to the trunk. Wood material does not supply missing form. |
| BAD-006–012, hounds | Box torso/head/legs with little anatomical transition; minimal ears/muzzle/feet and limited visible stitched identity. Bright eyes and sparkles do not resolve the underlying shape. |
| BAD-013–014, cart | Flat platform, basic seats and posts; weak vehicle construction detail; bright front glow obscures form. |
| BAD-015–016, lamps | Plain post and box lantern; little frame/glass/cap construction and a dominant glow. |
| BAD-017, shack | Basic box house/roof with sparse surface and construction detail. This is a rejected visual benchmark, not authorization to rebuild it. |
| MIN-001–009 | Historical creature images: strong silhouettes, expressive focal features, articulated limbs, distinctive accessories and surface treatment. Some are illustrations/product previews; they establish visual aspiration, not verified game-ready geometry. |
| MIN-010 | Expressive tree with integrated face, bark relief, tapered roots and irregular silhouette. |
| MIN-011–012 | Compact dark stylized creature previews with a clear focal face/mouth. Small screenshots limit fine-detail conclusions. |
| MIN-013–015, dragon | Coherent body anatomy, shaped head/jaw, articulated feet, tapering tail, horns/spines, layered wings and scale-like material detail. |
| MIN-016–020, MIN-023–024, assorted pets | Cubic stylization can meet the standard: purposeful proportions, expressive faces, ears/horns/wings and category-specific details. These are not a mandate for every Haunted Collector asset to be cube-shaped. |
| MIN-021–022, MIN-025–027 | Organic novelty characters with facial volume, limb definition, integrated material texture, silhouette detail and multiple view coverage. Subject/theme is reference material rather than an approved game addition. |
| MIN-028–033 | Blocky dragons/turtle/spider: layered bodies, segmented legs, teeth/spines, deliberate color regions and detailed silhouettes. MIN-031 contrasts directly with the hound's bare box assembly. |
| MIN-034–036 | Rounded articulated character bodies, shaped faces/mouths/hands, accessories and visible material finish. Borrow finish, not recognizable franchise identities. |
| MIN-037–044 | Antlered creature and skeleton: anatomy, tapered fingers/limbs, ribs, skull shape, depth and front/side/back consistency. |
| MIN-045–047 | Deliberately layered blocky monster with ribs, multiple heads, spikes, gloss and color hierarchy. Geometry reads coherently rather than as a few unrelated blocks. |
| MIN-048–053 | Rat/zombie: recognizable anatomy, shaped features, fur/clothing/skin variation and details sustained on side/rear views. |
| MIN-054–056 | Both faceted and textured trees: taper, branching hierarchy, angular rhythm and convincing root spread. Smoothness is not a universal requirement. |
| MIN-057–059 | Vehicle: finished body silhouette, wheels, windows, headlights, panel forms and consistent detailing across views. |
| MIN-060–070 | Prop packs: shaped pumpkins, furniture, lights, witchcraft objects, trees, grave markers and layered architecture. Useful minimum finish by category; tiny objects on overview sheets need full-size inspection before specific modeling decisions. |

## Hypotheses
The common quality signal is deliberate form and finish, not triangle count or photorealism. Confidence: high from the range of accepted styles. Screenshot lighting and texture can hide geometry defects; confirm finished assets in neutral light and actual gameplay before judging success.

## Relevance to our game
Working mechanics do not compensate for weak appearance. Functional correctness and visual acceptance are separate gates. Existing prototype acceptance does not make prototype geometry the quality target for newly requested finished assets. Preserve established interaction/collision requirements while improving render geometry. Relevant notes: [[Map References]], [[Misc References]], [[RSH-20261013-Haunted-Monetization-Discovery]].

## Original implementation ideas
### Required process for Claude and Codex
1. Before any model creation or revision, read this baseline and the matching subject references. Open relevant original screenshots, not just this summary. Select at least two useful positive references and one relevant rejected example where available; record their IDs and the qualities to carry forward.
2. Define the intended style and the subject-specific quality target: silhouette/proportions, primary and secondary forms, face/anatomy or construction detail, materials, scale and gameplay role. The reference collection contains multiple styles; select a coherent direction compatible with the game instead of mixing all of them.
3. Use the production method needed to reach the target. Primitive parts, procedural construction, mesh modeling and generators are methods; no method excuses crude final geometry. Low-poly means purposeful simplification, not missing anatomy, arbitrary joints or unfinished surfaces. A blockout is acceptable only when the user asks for that stage or the scoped task explicitly identifies it as an intermediate deliverable.
4. Inspect front, side, rear and three-quarter views under neutral lighting plus the intended game lighting, with scale and a reference comparison. If animated, also inspect the required poses/motion. Check geometry without glow/particles so effects cannot conceal weak modeling. Screenshots of the final model are required evidence; a successful script or import alone is insufficient.
5. **Compare side by side with the approved concept at a matched camera** (same angle, framing, background and lighting feel) on every iteration, and list the concrete differences left before claiming progress. The bar is close to 1:1 with the reference (jg, 2026-10-14, Wisp pilot); being better than the last iteration is not the bar, and four-view sheets alone are not enough. Read the reference literally (in the Wisp, the "teeth" were twine stitches and the dark back lobe was part of the sacking head) and ask when unsure. The Blender tool `games/haunted/art/tools/compare.py` renders matched cameras and tiles reference | render (on `task/TASK-0043-Wisp-Revision` until it merges). Don't export or integrate until jg likes the look.
6. Report visual and technical results separately. If the model falls below the selected references, call it unfinished and revise within the project's revision budget; after the limit, report the gap. Never silently lower the target or label an unreviewed asset user-approved.

### Visual acceptance rubric
| Criterion | Required evidence | Typical reason to fail |
|---|---|---|
| Silhouette and proportions | Recognizable intentional shape at gameplay distance, with subject-appropriate taper/volume | Generic box/cylinder mass substituted for the defining form |
| Primary/secondary forms | Coherent anatomy or construction, convincing transitions and intentional detail hierarchy | Abrupt pasted-on limbs/branches, sparse props, missing defining features |
| Identity/expression | Face, pose or characteristic details express the intended character | Glowing eyes or color alone provide all identity |
| Materials/surfaces | Deliberate palette, material separation, and scale-appropriate surface finish | Flat generic material or repeated texture disguises crude form |
| All-view finish | Side/rear/underside where visible are finished, with no distracting joins or clipping | Only the front presentation works |
| Reference comparison | Asset meets or exceeds subject-relevant minimum examples at comparable framing | Technical success is offered as a substitute for visible quality |

No numeric score can average away a visibly failed criterion. A deliberately smooth or simple surface may pass when it matches the selected style; adding random detail does not improve quality by itself.

### Technical acceptance remains necessary
Check scale, pivots, collision, ownership/replication where relevant, rig/deformation, materials and in-game performance against the scoped task. Set mesh/texture/part budgets for the actual use case; screenshots cannot establish safe budgets or prove topology/rigging. If a budget forces unacceptable simplification, report the trade-off rather than delivering below the visual floor.

## Recommendations (max 3)
1. Apply this reference baseline to every finished 3D request and explicitly compare the output to the selected examples.
2. Start with the closest category references, then improve silhouette, form transitions and material finish before adding effects or incidental detail.
3. Keep the complete positive and rejected archive. Add future user verdicts as evidence without overwriting this history or changing these IDs.

## Needs human review
- The user explicitly set the positive folder as the minimum and negative folder as rejected. The detailed rubric and individual diagnoses above are an interpretation, not a separate user approval of each statement.
- Screenshots establish appearance only. Asset creators, IDs, licences, mesh topology, rigging and performance were not verified. They are visual references, not permission to import/copy the models.
- No model was generated, purchased, uploaded or changed in this session. No generator or specific production budget was chosen.
