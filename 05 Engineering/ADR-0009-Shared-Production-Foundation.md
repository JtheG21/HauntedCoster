---
id: ADR-0009
title: Shared Production Foundation
type: adr
status: approved
approved_by: jg
approved_on: 2026-10-12
related:
  - "[[Task Intake]]"
  - "[[Resource Catalog]]"
  - "[[Workflow]]"
created: 2026-10-12
updated: 2026-10-12
tags:
  - workflow/decision
---
# ADR-0009: A small shared production foundation inside the existing vault

## Context
jg asked (2026-10-12) for a reusable, cross-project system that turns ideas, screenshots, videos and project knowledge into implementation-ready work for Claude Code, Studio, Blender and Claude Design.

Reconnaissance found most of the foundation already in place:
- Rules in `AGENTS.md`, process in [[Workflow]].
- Templates, validators and the orchestrator; the reference-first rule with the `10 References/` areas; the [[Reference_Code_Index]].
- The `roblox-map` and `roblox-sfx` skills.

What was missing:
- A start procedure and task routing.
- A proceed-or-ask policy.
- Image and video intake.
- A catalog of reusable resources with honest verification states.
- Per-category production workflows.
- A handoff format.

## Options considered
1. **A separate framework** (a new top-level folder or a second instruction file). Rejected: it duplicates `AGENTS.md` and [[Workflow]] and creates two authorities.
2. **Everything in `AGENTS.md`.** Rejected: it would load every procedure into every session.
3. **Extend what exists** (chosen):
   - One entry note ([[Task Intake]]) linked from `AGENTS.md`.
   - Eight workflow notes under `04 Agents/Workflows/`, loaded only when a task needs them.
   - One [[Resource Catalog]] in `00 Studio/`.
   - Two new templates (`T - Reference`, `T - Handoff`) and an Intake section in `T - Task`.

## Decision
Option 3, **approved by jg on 2026-10-12**. The details:

- **Scopes.**
  - Shared material lives in `04 Agents/`, `00 Studio/`, `05 Engineering/` and `99 Templates/`.
  - Project configuration lives in each game's `00 Overview` "project profile" and its design and architecture notes.
  - Task material lives in the TASK note and an optional handoff.
- **Reference IDs** extend the existing `REF-<AREA>-INDEX` prefix to `REF-<AREA>-NNN`. The existing `referenceN` map notes keep their names, since they are on hold.
- **Catalog identity** is the resource's path or existing ID. No new ID scheme.
- **Lifecycle states** (captured, proposed, implemented, verified, approved, deprecated) are catalog columns, not note statuses, so the controlled status vocabulary is unchanged.
- **No validator change.** The new notes use the existing types `agent` and `index`. Reference notes sit under `10 References/`, which the validator doesn't frontmatter-check.

Mark this ADR `status: approved` only after jg approves it, and record who and when.

## Consequences
- **Reversible:** these are docs only. No game code, Rojo mapping, queue entry or validator changed.
- **Upkeep:** the catalog only stays useful if each task's close-out adds or updates rows (step 10 of [[Task Intake]]).
- **Open trade-offs:**
  - `AGENTS.md` is still partly GAME-002-specific (its project map). A second active game should move that map into the game's project profile.
  - Limitations resolved 2026-10-12 (jg chose the recommended options): `ffmpeg` and `yt-dlp` installed; a Blender test cube exported for jg to import (scale to be recorded as a LES); the empty `00 Reference index.md` folder replaced by a real index; Figma being authorized by jg for a trial of reusable UI designs; Claude Design handoffs carry images plus a written spec; the `AGENTS.md` project map stays until a second game is active.
