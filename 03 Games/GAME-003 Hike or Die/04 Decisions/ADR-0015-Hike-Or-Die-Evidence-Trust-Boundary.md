---
id: ADR-0015
title: Hike or Die Evidence Trust Boundary
type: adr
project: GAME-003
status: approved
approved_by: jg
approved_on: 2026-10-18
related:
  - "[[TASK-0087-Hike-Or-Die-Gate-1]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - game/decision
---

# Hike or Die Evidence Trust Boundary

## Context
Photo quality depends on camera framing, distance, behavior state and risk. A client camera is locally controlled, while evidence awards must remain server-authoritative.

## Options considered
1. Client reports score and target. Rejected as untrustworthy.
2. Client reports an aim ray; server bounds its origin/cone, raycasts, checks current state and computes score.
3. Server uses only character facing and ignores camera aim.

## Decision
**Decision (jg, 2026-10-18):** prototype option 2 with strict server-side plausibility checks and adversarial probes; retain option 3 as a fallback if client aim cannot be constrained. No client-reported score or subject identity is accepted.

## Consequences
Aim cannot be proven to match the rendered camera against a modified client. The server must cap rate, validate geometry and derive all rewards. The test cannot claim exploit-proof camera framing.
