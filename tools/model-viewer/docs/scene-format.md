# Scene format v1

Export from the viewer to obtain all fields. A minimal package scene is:

```json
{"version":1,"model":"library/ghost-v1/model.glb"}
```

Paths are deliberately restricted to `library/<letters-digits-hyphens-underscores>/model.glb`. Null model means a loose-file preset: the matching file must be opened manually first. Scenes do not contain model bytes.

Optional fields and defaults are defined in src/state.js and validated again by the package CLI: camera/target (three finite coordinates each), lighting (`studio`, `bright`, `night`), background hex color, exposure 0.1–3, grid/wireframe/turntable booleans, effect (`none`, `aura`, `sparks`, `rings`), effectColor hex, effectIntensity 0–3, mappings (Idle/Move/Ability clip names), clip name, time seconds, speed 0.1–3 and loop boolean. Unknown fields and unsupported versions fail clearly. Import pauses playback. A minimal scene without mappings retains name-based mappings generated from the actual model clips.

Package manifest records version, display name, model path, SHA-256, source filename and clip names. `library/index.json` is a derived list of display name/model pairs. Use the CLI to add or validate; do not hand-edit the model hash to conceal a geometry revision.
