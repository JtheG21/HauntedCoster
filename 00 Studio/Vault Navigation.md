---
id: STUDIO-VAULT-NAVIGATION
title: Vault Navigation
type: index
status: in_progress
created: 2026-10-14
updated: 2026-10-14
tags:
  - studio/navigation
---
# Using the studio dashboard

## Start a session
Open [[Studio Index]], then [[GAME-002 Haunted Collector/00 Overview]]. The home page shows cross-studio tasks, proposed decisions and recently updated notes. The game dashboard filters tasks, decisions and research to GAME-002.

## Read the views
- **Open tasks:** task notes except done/archived. Status is mirrored; `tasks/queue.json` remains authoritative. An empty table is valid.
- **Proposed decisions:** proposed ADRs only. This is not a complete list of human playtests or art reviews; consult the game overview and roadmap too.
- **Recent notes/research:** sorted by the note’s `updated` property. Research is not approved implementation work.
- **Reference library:** image cards open existing reference assets. Read the linked collection notes before using them.
- **System map:** [[Haunted Systems.canvas]] links the overview and three maintained system documents.

Use the view menu on [[Notes.base]], [[Haunted Dashboard.base]] or [[Reference Images.base]] to switch views. In Obsidian Reading view, the embeds render as tables or image cards. No additional community plugin is required; Bases and Canvas must be available/enabled in your existing installation.

## Maintenance
Update `updated` when changing a note. Keep task state in the orchestrator and preserve historical audit/test records. The game overview’s completed task history and milestone snapshot are collapsed, not deleted. Keep current direction near the top and dated evidence below it.

## Session record — 2026-10-14
Created this guide, [[Reference Library]], two dashboard/gallery Bases files, and the system Canvas. Updated [[Studio Index]], [[Notes.base]], the Haunted Collector overview, and [[RSH-20261014-CSM-Custom-Rig-Import-Video]] (one verified ADR target; unavailable citations labelled rather than invented). Reference assets, settings, game code and task state were left unchanged. Verified in Obsidian 1.14.4: studio and game dashboard views render; map gallery shows seven images with working previews; quality gallery finds 70 images. `scripts/check.sh` passed (125 game specs and 41 Python tests); vault validation reports zero errors and zero warnings.
