# Reference feedback experiment

Original client-only Roblox demonstration inspired by the feedback relationships in REF-CODE-011. Uses the existing Haunted Collector Theme module without changing it. No original game code/assets copied. This is isolated experiment tooling, outside both game Rojo projects; it does not implement a game mechanic.

From the repository root:

```sh
lune run experiments/reference-feedback/spec
rojo build experiments/reference-feedback/demo.project.json -o /private/tmp/ReferenceFeedbackDemo.rbxl
lune run experiments/reference-feedback/inspect-build /private/tmp/ReferenceFeedbackDemo.rbxl
```

Open that file in a separate Studio window. Do not connect the Haunted Collector Rojo server. Press Play. Normal / Low / Empty select deterministic states. Lamp toggles the simulated light panel. Run drain consumes 2 points/second idle or 8 with the lamp on. Normal restores power. Empty disables lamp and drain, with explanatory text. No audio, flashing, world lighting, remotes, saving, or paid assets.

Acceptance: show all three states; verify lamp action and recovery; let Low drain to zero; inspect desktop and phone layouts; check Output; obtain jg's visual judgment. GUI attributes Phase, Charge and LampOn expose state for inspection, not server authority. Headless tests cover boundary classification, clamping, invalid inputs and subdivision-invariant drain. A Rojo build is not runtime proof.

Reusable candidate: derive label, color, availability and hint from the same state; retain non-color cues; verify recovery. For a real shared resource, authoritative state belongs on the server. Do not adopt the demo thresholds, drain balance or browser-game structure as a production standard.
