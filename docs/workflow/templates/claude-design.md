# Handoff to Claude Design: TASK-#### <title>

Claude Design can't read this repo, so paste what it needs (text, palette, screenshots) and attach images. It produces a package; Claude Code or Codex integrates it after the audit. Fill every section; write "none" rather than deleting one.

## Goal
One sentence: what the package lets the game show or do.

## In scope
- Screens, components or assets, each with its states

## Out of scope
- Code, remotes and game rules. Anything already approved that must not change.

## Files expected to change
Claude Design edits no repo files. List what the integrating task will change:
- `games/mathshow/assets/...`, `docs/design/<feature>/...`

## Owned files
Must match `files_owned` for the integrating task in `tasks/queue.json`. Owner: `claude-design` for the package, then the integrating agent.
-

## Export formats and where outputs land

| Output | Format | Destination | Notes |
|---|---|---|---|
| UI art, icons, 9-slice sources | PNG with transparency, at the sizes listed in the package README | `games/mathshow/art/<area>/` | Add each to that folder's `UPLOAD_LIST.md`. Uploads need jg's approval. |
| 2D textures | PNG, power-of-two size | `games/mathshow/art/<area>/` | |
| 3D source | GLB or FBX, with triangle count | `games/mathshow/art/<area>/` | Compare with `10 References/05 Misc/3D Model Quality Baseline.md` |
| 3D in game | **`.rbxmx`** | `games/mathshow/assets/` | **MeshId and TextureID need `.rbxmx`:** they survive in a saved Roblox model file, so don't rely on JSON or script-set values. |
| Layout specs, README, numbers, screenshots | Markdown, PNG | `docs/design/<feature>/` | Sizes, text fits, keep-clear zones, 9-slice values. Unzip packages into an empty scratch folder and never run scripts from them. |

UI rules: Merriweather Bold or Italic only; no TextTransform or letter-spacing; text fits with a 6 px margin; check every glyph against the font.

## Acceptance criteria and evidence
| Criterion | Evidence |
|---|---|
| | Package screenshots at 844x390 and 1920x1080, text-fit audit, shape profiles |

## Tier
light | standard | deep, for the integrating task. Follows AGENTS.md "Tiers".

## Test steps
1. Audit the package: text fit, glyphs, keep-clear zones.
2. After integration: `scripts/check.sh`, then the Studio TextFit gate in a fresh Play session.

## Approval gates
Stop for jg before: uploading any asset; visual and audio sign-off; spending Robux; publishing. Licence check for anything not original (`intake/README.md`).

## Remote-change triple
Design packages don't change remotes. If one implies a payload change, list it for the integrating task; otherwise "none".
| Remote | Sender | Server handler | Receiver |
|---|---|---|---|
| | | | |

## Report back
File list with sizes, what was and wasn't checked, and known risks.
