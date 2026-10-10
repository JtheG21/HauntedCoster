---
id: LES-0002
title: Typed Test Context
type: lesson
status: approved
category: good-pattern
evidence:
  - "luau-lsp analyze on TASK-0001: 'Expected this to be boolean, but got string' in CollectibleRules.spec until t was annotated"
applies_to:
  - tests/luau
created: 2026-10-10
updated: 2026-10-10
tags:
  - knowledge/lesson
---
# Annotate the test context in strict Luau specs

## Problem
In strict mode, the type checker reported false errors in `t.eq(...)` calls.

## Root cause
An unannotated `t` parameter gets its function types from its first use (`t.eq(ok, true)` → boolean). Every later call with another type then fails.

## Solution
Spec modules use `return function(t: TestRunner.T)`. For `pcall` on a `() -> ()` value, cast it: `pcall(fn :: any)`.

## Validation
`scripts/typecheck.sh` was clean on [[TASK-0001-Collectible-Pickup]].

## Where this applies
Every `tests/luau/*.spec.luau`.
