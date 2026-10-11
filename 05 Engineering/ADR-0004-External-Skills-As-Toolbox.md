---
id: ADR-0004
title: External Skills As Toolbox
type: adr
status: proposed
approved_by:
approved_on:
created: 2026-10-10
updated: 2026-10-10
tags:
  - workflow/decision
related:
  - "[[External Skills]]"
---
# ADR-0004: Third-party skill packs are tools under our workflow, not a second orchestrator

## Context
The SyphoDev skill pack includes its own end-to-end orchestrator (`create-roblox-game`, `roblox-build-orchestrator`) with separate state, an auto-publish stage and implied approvals, alongside useful specialist skills. Audit: [[External Skills]].

## Options considered
1. Adopt the pack's orchestrator as the main pipeline.
2. Run both orchestrators.
3. **Install only specialist skills, project-local and pinned, and drive them from our own tasks, gates and vault.**

## Decision
*(Proposed. Mark approved only after explicit approval.)* Option 3. One orchestrator (`scripts/orchestrator.py` plus `tasks/queue.json`) owns status, gates, retries and memory. External skills produce artifacts that feed `TASK-` notes, never publish or upload, and touch Studio only inside approved tasks.

## Consequences
We give up the pack's end-to-end automation. In exchange: no competing state, and our human gates and audits stay intact. Each new skill gets a short audit and a pinned commit before install.
