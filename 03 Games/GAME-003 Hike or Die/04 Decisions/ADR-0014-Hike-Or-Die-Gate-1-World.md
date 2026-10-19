---
id: ADR-0014
title: Hike or Die Gate 1 World Approach
type: adr
project: GAME-003
status: proposed
approved_by:
approved_on:
related:
  - "[[TASK-0087-Hike-Or-Die-Gate-1]]"
created: 2026-10-18
updated: 2026-10-18
tags:
  - game/decision
---

# Hike or Die Gate 1 World Approach

## Context
The Gate 1 brief recommends a small handcrafted trail with controlled encounter variation and leaves fixed versus modular generation open. A map architecture decision should minimize navigation bugs and make playtests reproducible.

## Options considered
1. Handcrafted connected trail with controlled cryptid variation.
2. Fixed route network with randomized encounter placement/objectives.
3. Modular interconnected segments.

## Decision
**Proposed:** use option 1 for the Gate 1 experiment. It is the smallest reversible way to test landmarks, cover, alternative approach, chase reliability and extraction readability. This is not approval for the full-game world architecture.

## Consequences
The test layout is reproducible and quick to inspect, with limited replay variation. Do not build a generator or claim production map architecture. Human acceptance of visual quality remains open.
