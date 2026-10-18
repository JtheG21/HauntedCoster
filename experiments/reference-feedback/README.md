# Reference feedback experiment

Original client-only Roblox demonstration inspired by the feedback relationships in REF-CODE-011. Uses the existing Haunted Collector Theme constructors through a demo-local skin; the game Theme remains unchanged. Styling methods were informed by the Check-UI showcase and UI-principles reference, adapted into original code without imported icons or textures. No original game code/assets copied. This is isolated experiment tooling, outside both game Rojo projects; it does not implement a game mechanic.

From the repository root:

```sh
lune run experiments/reference-feedback/spec
rojo build experiments/reference-feedback/demo.project.json -o /private/tmp/ReferenceFeedbackDemo.rbxl
lune run experiments/reference-feedback/inspect-build /private/tmp/ReferenceFeedbackDemo.rbxl
```

Open that file in a separate Studio window. Do not connect the Haunted Collector Rojo server. Press Play. Normal / Low / Empty select deterministic states. Lamp toggles the simulated light panel. Run drain consumes 2 points/second idle or 8 with the lamp on. Normal restores power. Empty disables lamp and drain, with explanatory text. No audio, flashing, world lighting, remotes, saving, or paid assets.

Acceptance: show all three states; verify lamp action and recovery; let Low drain to zero; inspect desktop and phone layouts (short viewports scroll vertically); check Output; obtain jg's visual judgment. GUI attributes Phase, Charge and LampOn expose state for inspection, not server authority. Headless tests cover boundary classification, clamping, invalid inputs and subdivision-invariant drain. A Rojo build is not runtime proof.

Reusable candidate: derive label, color, availability and hint from the same state; retain non-color cues; verify recovery. For a real shared resource, authoritative state belongs on the server. Do not adopt the demo thresholds, drain balance or browser-game structure as a production standard.

## Illustrated Halloween revision

jg supplied REF-UI-004 and requested applying it after rejecting the earlier skins. `FrameArt.luau` renders generated-original desktop and narrow frames with EditableImage, EncodingService and local compressed pixel payloads. Native buttons and state logic remain interactive. No image asset was uploaded, no HTTP request is made by the demo, and game Theme remains unchanged.

The original PNGs, exact generation prompts and payload hashes live in `art/`. Rebuild imported art with Python 3.15+ and a separate interpreter providing Pillow:

```sh
python3 experiments/reference-feedback/import-art.py --image-python /path/to/python-with-pillow
```

For this session the Pillow interpreter was `/Users/jg/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/bin/python3`. This is a local experiment recipe, not a dependency installation or a verified deployment path. EditableImage memory/permission constraints and physical-device performance need checking before a real game integration. Do not substitute a third-party asset ID.

## Motion and input polish

`DemoMotion.luau` adds a short entrance settle, subtle frame float, smooth meter transitions and a lamp border pulse. Buttons animate on hover, focus and press. Motion honors Roblox ReducedMotionEnabled and the demo's Motion toggle. Depletion snaps immediately to zero. Tab/Shift-Tab, arrows/D-pad and Enter/Space/A navigate and activate; unavailable controls are skipped and short screens scroll the focused control into view. Navigation bindings, event connections and demo-only CoreGui changes are restored when the GUI is destroyed.

Verified in Studio with virtual mouse/keyboard/controller inputs, phone landscape, tablet and Xbox viewport emulation. These checks do not certify physical touch/controller hardware, console safe-area settings, published EditableImage support or device performance.

## Independent decoration revision

The user accepted the button effects and rejected whole-frame movement. `DecorationMotion.luau` now animates separate original ghost, branch, spiders/threads and falling-leaf sprites against a stationary clean backplate. The background gradient moves slowly; a runtime illumination mask pulses only bright carved pumpkin regions. The entire frame no longer floats, rotates or scales on entry. A ten-leaf pool is reused, with no per-frame instance creation. Reduced motion hides falling leaves and fixes ornament poses/glow. Desktop and narrow art remain separate; mobile ornaments shrink and move inward. The approved button behavior is preserved.

Latest artifact: `/private/tmp/ReferenceFeedbackDecorations.rbxl`. Generated source art, exact built-in image_gen prompts and payload hashes are in `art/`; no original files were overwritten.

## Rooted tree and carved-light revision

Preset row raised 32 pixels, action row 24 pixels, with hint/footer adjusted for spacing. Bare backplates remove baked vines/leaves so new twig/leaf clusters and pumpkin foliage sway independently, without a static duplicate underneath. The tree has illustrated roots wrapping an orange post aligned to the frame; silk origins follow two tree points, including its small rotation. The phone tree is shorter. All three pumpkins share a five-second fade across connected dark carving components, rather than highlighting bright pumpkin skin. Flood fill is bounded and rejects escaped components. Reduced-motion behavior remains in place. Latest artifact: `/private/tmp/ReferenceFeedbackRooted.rbxl`; exact generation prompts in `art/ROOTED-PROMPTS.md`.

## Complete leaves and restored stems

The twig-cluster atlas rectangle ended through opaque leaf pixels. Its bounds now include the complete silhouette and transparent margin; the mirrored clusters use the same corrected rectangle. Narrow-screen side clusters move inward to avoid viewport clipping. Two original curled-stem sprites restore the bottom pumpkins' stalks; source art and exact prompt are in `art/halloween-pumpkin-stem.png` and `art/STEM-PROMPT.md`. Latest artifact: `/private/tmp/ReferenceFeedbackStems.rbxl`.

## Fidelity correction and closeup review

The generated replacement stalks misread the requested original curled corner vines. Those sprites and added pumpkin foliage are now removed from the live composition; the original corner design is restored in the frame artwork, with the missing left nose added. Corner vines are currently part of that stationary artwork; side/hat layers are hidden where they would duplicate preserved ornaments. Earlier artwork remains as history.

The previous threshold mask excluded lighter pixels inside the witch smile and missed a nose. Coverage now includes those carving colors, closes isolated pixel gaps and antialiases the emission boundary. `inspect-faces.luau` is a temporary Client-side visual inspection panel using the actual base/emission image content: all three faces shown at dim and lit extrema. Destroy `FaceQualityInspection` after capture. It is visual evidence, not an automatic pass.

Review lesson from jg's corrections: identify the exact reference feature before replacing it; preserve the requested silhouette and composition; inspect complete eyes/nose/mouth and sprite edges in enlarged views for both artwork variants and both glow extrema. A successful build, behavior test or full-layout screenshot does not establish detail fidelity. Do not claim human visual approval from technical checks. Latest artifact: `/private/tmp/ReferenceFeedbackFidelity.rbxl`.

## Header and spider alignment

Labels are centered together on the painted ribbon at normalized x=.53, independent of card padding. The right desktop silk origin uses a verified opaque tree pixel (local y=.085 rather than transparent y=.055); both origins follow the tree's rotation. Desktop/phone center measurements and screenshots are recorded in the research note. Latest artifact: `/private/tmp/ReferenceFeedbackAligned.rbxl`.

## Continuous frame under the tree

The tree now consumes separate TreeArtData with the baked orange post and lower end cap removed. Transparent root gaps expose the original continuous frame. Leaf sprites retain the unchanged RootArtData atlas. The former post pixel and spider anchor were checked for transparency/opacity, followed by desktop/phone inspection. Source/edit prompt: `art/halloween-tree-without-post.png`, `art/POST-REMOVAL-PROMPT.md`. Latest artifact: `/private/tmp/ReferenceFeedbackContinuousFrame.rbxl`.

## Final tucked branch tip

The flared root base is replaced with a narrow curved continuation ending in a complete upward spiral close to the frame. Only TreeArtData consumes this image. Both spider-anchor pixels remain opaque and the lower tip has transparent margin. Exact built-in image_gen prompts, including the rejected clipped-tail correction, are in `art/CURLED-TIP-PROMPTS.md`. Latest artifact: `/private/tmp/ReferenceFeedbackFinal.rbxl`.

### Attachment regression
Run `verify-attachments.luau` in the demo Client. It samples actual laid-out thread endpoints across the branch sway and rejects drift over 1.5 px. Check desktop and portrait artwork; GuiObject rotation uses its center regardless of AnchorPoint. Directly resizing artwork can verify narrow geometry when device simulation is unavailable, but does not certify device rendering or touch.
