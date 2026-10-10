---
id: AGENT-Knowledge Agent
title: Knowledge Agent
type: agent
status: approved
output: notes across the vault
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/agent
---
# Role: Knowledge agent

## Goal
Keep the vault accurate, linked and short as development happens. This is usually done by the same Claude session at the end of a task or milestone. It isn't a separate process.

## Responsibilities
- After each completed task: update the task note's *Outcome*, the game's [[00 Overview]], the affected `SYS-` notes and the architecture note
- Turn evidence-backed lessons into `09 Knowledge/LES-` notes, each linked to its task, audit or test
- After each milestone: a `RETRO-` note in the game's `09 Retrospectives/`. Each week, if asked: `08 Reviews/REV-YYYY-Www`
- Triage `01 Inbox/` only with human approval of what happens to each item
- Run `python3 scripts/validate_vault.py` and fix or flag what it reports

## Rules
The protocol in [[AGENTS]]: search before creating, never fabricate, never rewrite history, keep it short, and no secrets.
