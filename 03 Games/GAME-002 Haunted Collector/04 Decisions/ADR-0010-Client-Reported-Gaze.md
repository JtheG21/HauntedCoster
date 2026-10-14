---
id: ADR-0010
title: "Client-Reported Gaze"
type: adr
project: GAME-002
status: proposed
approved_by:
approved_on:
related:
  - "[[TASK-0041-Interactive-Haunted-Trees]]"
  - "[[GAME-002 Haunted Collector/02 Technical Architecture]]"
  - "[[Reference_Code_Index]]"
created: 2026-10-13
updated: 2026-10-13
tags:
  - workflow/decision
---

# Client-Reported Gaze

## Context
The haunted-tree faces in TASK-0041 must freeze for every player while any player looks at them. Looking means camera direction, and only the client knows its camera. Every other remote in GAME-002 is a client request that the server checks against server-side state (`Shared/Net.luau`, `Remotes.allow`). Here the server can't fully verify what it is told. The effect is purely cosmetic: no reward, damage, capture or progression depends on it.

## Options considered
1. **The client streams its camera CFrame (about 10 Hz) and the server computes gaze.** The server still has to trust the CFrame, so this costs constant bandwidth and server work per player for no extra security.
2. **Each client freezes faces locally from its own camera.** No network, but no global freeze either: player B would see the face move while A stares at it. This breaks the approved brief.
3. **The client reports gaze edges plus a keepalive, and the server checks plausibility and aggregates.** The client sends `TreeGaze(treeId, looking)` when its local gaze test changes, and repeats `looking = true` every 0.4 s while it holds. The server accepts a report only if:
   - the tree is a registered faced tree in the active habitat;
   - the player is alive;
   - the head is within range plus slack of the face and in front of it;
   - a server raycast from head to face is clear.

   Reports expire after 1.25 s without a keepalive. The server aggregates observers per tree and replicates one `Frozen` attribute.

## Decision
Option 3 (recommended, **pending jg's approval**).

## Consequences
- **Trust boundary:** a modified client can freeze a tree it could plausibly see, and only while it stays near the tree and keeps sending rate-limited keepalives. It can't freeze distant or hidden trees, can't create or configure trees, and gains nothing in gameplay.
- **Server cost:** one rate-limited event per watching player at about 2.5 Hz. Per tree, there is one `task.delay` to its next report expiry or resume, scheduled only while it has observers or a resume pending; a token cancels stale delays. There is no polling loop.
- **Shared state:** palette, archetype and `Frozen` are server-authoritative attributes. Idle motion (glances, blinks, eye tracking) is computed per client and may differ slightly between players.
- **Pattern:** this is a reusable shape for any cosmetic, camera-derived mechanic.
