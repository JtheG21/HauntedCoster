---
id: TASK-0138
title: "MathShow Lifetime Glyph Total (G-DS)"
type: task
project: GAME-004
status: review
priority: medium
risk: high
owner: claude-code
depends_on: []
branch: task/TASK-0138-glyph-lifetime
related: []
created: 2026-11-03
updated: 2026-11-03
tags:
  - workflow/task
---

# MathShow Lifetime Glyph Total (G-DS)

## Goal
Persist a lifetime glyph total in the player profile (one new field, `glyphsLifetime`) and show it on the glyph HUD.

## Scope
- **In:** `ProfileRules.migrate`/`addGlyphs` (+ spec), `ProfileService` migrate-on-load and a server-only increment, `GlyphService` call after a successful collect, `GlyphState.lifetime` (sender `GlyphService`, `Net` type, receiver `GlyphController`).
- **Out (non-goals):** quests/XP, other profile fields, key renames/deletions, data wipes, the live experience, publishing, merging.
- **Keep unchanged:** DataStore name and key scheme, save cadence, retry and memory-only behaviour, no client-to-server change.

## Intake
- **Category, depth:** DataStore schema, deep. References: none relevant.
- **Decisions:** schema change approved by jg in chat ("approve G-DS"), 2026-11-03; nothing beyond it.
- **Remote change rule:** sender `GlyphService`, payload type in `Net`, receiver `GlyphController`.

## Files expected to change
See `files_owned` in `tasks/items/TASK-0138.json`.

## Acceptance criteria
See the task file; ticked in the Outcome once measured.

## Tests
- **Automated:** `scripts/check.sh`, `ProfileRules.spec`.
- **Studio:** memory-only run on unpublished place; persistence on the private test experience.

---
## Implementation record
- `ProfileRules` v2 (`migrate`, `addGlyphs`, `isNewerVersion`, max-merge of `glyphsLifetime`), `ProfileService` migrate-on-load and `addGlyphs`, `GlyphService` add-after-collect with a pending amount while the profile loads, `GlyphState.lifetime` to the HUD (`Net`, `GlyphController`).
- Studio: `docs/workflow/evidence/TASK-0138/gds.txt` (memory-only; private test experience migration, persistence and accumulation). The API-access disable step was waived by jg in chat; the setting was left on.

## Audits
- [[AUD-20261103-TASK-0138-01]]: pass. Minors fixed after the audit; one release requirement: shut down all old servers before the first publish.
