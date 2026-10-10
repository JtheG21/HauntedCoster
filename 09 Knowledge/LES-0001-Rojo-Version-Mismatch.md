---
id: LES-0001
title: Rojo Version Mismatch
type: lesson
status: approved
category: bug-pattern
evidence:
  - "Studio console 2026-10-10: cloud_13916111004.Rojo.Plugin.ApiContext:28 attempt to index number with 'protocolVersion'"
  - "curl /api/rojo: 7.6.1 returned JSON, 7.7.0 returned MessagePack"
applies_to:
  - rokit.toml
created: 2026-10-10
updated: 2026-10-10
tags:
  - knowledge/lesson
---
# Rojo plugin and server versions must match

## Problem
Rojo Connect failed with `attempt to index number with 'protocolVersion'`.

## Root cause
The Studio plugin (Creator Store, 7.7) decodes replies as MessagePack. The `rojo serve` server was 7.6.1 and replied in JSON. The first byte of the JSON, `{`, decodes as the number 123.

## Solution
Pin `rojo-rbx/rojo@7.7.0` in `rokit.toml`, restart `rojo serve`, and keep only one Rojo plugin enabled in Studio.

## Validation
After the restart, the sync worked both ways: a test file was added and then removed, and the smoke spec passed 2/2.

## Where this applies
Any time the Studio plugin auto-updates. Check `rojo --version` against the plugin's version first.
