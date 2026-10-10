---
id: LES-0004
title: Wait For Client Physics
type: lesson
status: approved
category: bug-pattern
evidence:
  - "CollectibleRace runs 2026-10-10: round 1 had touches=0 and farthestAfter=0.0 in 4 of 5 runs; after the readiness wait, 2 of 2 runs passed 4/4 rounds"
applies_to:
  - tests/luau/multiclient
created: 2026-10-10
updated: 2026-10-10
tags:
  - knowledge/lesson
---
# Wait for client physics before multi-client assertions

## Problem
In automated 2-client tests, the first server-teleported touch never registered (0 touches), but later rounds worked.

## Root cause
Right after joining, a test client didn't simulate its character yet. The character sat motionless exactly at the teleport point (0.0 studs drift), so no contact events fired. Clients own their characters' physics, and the server can't produce touches for a character that isn't simulating.

## Solution
Before asserting, lift each character and wait until it falls (`root.Position.Y` drops). Then run the scenario.

## Validation
2 consecutive runs passed 4/4 rounds after the fix ([[TEST-20261010-02]]).

## Where this applies
Every multi-client scenario, and any server logic that assumes newly joined characters respond to physics right away.
