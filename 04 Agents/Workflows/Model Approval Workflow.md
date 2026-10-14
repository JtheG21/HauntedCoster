---
id: AGENT-WF-Model-Approval
title: Model Approval Workflow
type: agent
status: approved
created: 2026-10-13
updated: 2026-10-13
related:
  - "[[Asset Workflow]]"
  - "[[3D Model Quality Baseline]]"
tags:
  - workflow/production
---
# Model Approval Workflow

## Purpose
Reduce repeated guessing and rework by settling the visual target and proving one model before scaling production. jg authorized implementation of this workflow in this chat on 2026-10-13. This approves the process, not individual designs, models, uploads or merges.

## Ownership
- Codex: focused interview, actual concept images and edits, reference research, build brief, independent visual review, reusable methods and evidence.
- Claude: model construction, scoped code implementation and local Studio testing.
- jg: visual target, model acceptance and existing human gates.
- One owner per task and one operator per Studio/Rojo session. Coordinate through written handoffs; never edit another agent's moving checkout. Review stable commits. Dependencies and status remain in tasks/queue.json.

## Process
1. Describe the asset and inspect relevant original references. Read [[3D Model Quality Baseline]] and [[3D Model Quality Gallery]]. Record selected reference IDs and defining qualities.
2. Codex asks only missing questions that affect appearance or use, then creates a draft image. Preserve accepted features during revisions. Concept images are proposed appearance, not proof of geometry or performance.
3. jg explicitly approves a visual target. Codex prepares the brief: final image/version, proportions, materials, scale, visible hidden surfaces, independent moving pieces, pivot, collision, gameplay distance, performance budget and acceptance evidence. Resolve inconsistent generated views before building.
4. Claude builds one representative model with an approach capable of meeting the target. Preserve editable source. Under the current GAME-002 direction use Blender; a new generator or paid method requires separate authorization. Use procedural scripts for proven repeatable structures; retain editable .blend work where needed for sculpting or controlled finishing.
5. Codex compares actual front/side/rear/three-quarter captures in neutral and game lighting, with effects off where they obscure geometry. Report visual findings separately from scale, collision, rigging, loading and performance checks. jg accepts the finished model explicitly.
6. Expand variants only after the pilot passes. Save a verified recipe using [[T - Model Recipe]]; untested approaches stay proposed. Reuse the method next time and interview only new design choices.

## Current overhaul handoff
Evidence reviewed on 2026-10-13: TASK-0044 reports HauntedTrees 23/28; TASK-0045 reports intermittent delayed tree meshes and its first audit passes despite AC3 being undemonstrated at review time. Later sheets exist; they still require comparison and user acceptance. These are recorded observations, not a new task-state verdict.

Claude should finish its current bounded TASK-0046 step and preserve work, then avoid expanding additional model families until representative visual acceptance. Reproduce or resolve the five HauntedTrees failures rather than assuming memory pressure explains them. Investigate delayed meshes with repeatable loading/memory evidence. Any deferral of required criteria needs explicit human scope approval. Keep changes isolated by task; review a stable revision after project checks.

Codex's first contribution: a focused review of one haunted tree and an architectural pilot, followed by the model-design interview and approved concept for the next family. No existing work is discarded. The current workflow does not declare any existing model accepted.

## Reuse and boundaries
Use $model-design in Codex. The installed skill is /Users/jg/.codex/skills/model-design/SKILL.md. Recipe notes preserve approved concept files, actual final captures, source/settings, tested method, rejected approaches and reuse limitations. Existing two-revision, merge, upload, publishing and spending rules continue to apply.
