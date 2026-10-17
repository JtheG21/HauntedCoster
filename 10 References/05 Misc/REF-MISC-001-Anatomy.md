---
id: REF-MISC-001
title: Anatomy — Structural Modeling Exploration
type: reference
status: proposed
area: misc
source: https://github.com/wheresryan22/anatomy
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-16
related:
  - "[[Misc References]]"
  - "[[3D Model Quality Baseline]]"
tags:
  - reference/misc
  - reference/modeling
  - reference/needs-experimentation
---
# Anatomy — Structural Modeling Exploration

## Identity
- **Source:** https://github.com/wheresryan22/anatomy
- **Inspected:** README and https://raw.githubusercontent.com/wheresryan22/anatomy/main/SKILL.md on 2026-10-16; branch main, not pinned to a commit.
- **Purpose:** Explore whether structural planning and explanatory figures help Claude produce coherent Roblox models when uncertain about an object's construction.
- **Evaluation: needs experimentation.** Not installed or executed; examples, audit implementation and export capabilities have not been independently tested. Repository declares MIT; full licence text not inspected in this evaluation.

## Observations (source inspection)
The README describes interactive isometric illustrations using SVG, optional WebGL, and a beta 3D mode. Its skill instructions call for a parts list before geometry, deliberate component placement and close-up inspection. The repository describes geometry checks for supports, connections and intersections. Those are author claims about its tools, not verified performance or proof of real-world mechanical accuracy.

## Intent — interview with jg, 2026-10-16
- Desired improvements include recognizable shapes, correct proportions, believable connections and working mechanisms where appropriate.
- No specific past failure was identified; do not invent one.
- Potential subjects include machines, vehicles, buildings, props, creatures and anything structurally confusing. This breadth is jg's intended exploration, not evidence of the repository's capabilities for each subject.
- When uncertainty arises, use whichever approach best resolves it: a parts breakdown, illustrated explanation or clearer modeling plan.
- Mark this needs experimentation. Try one troublesome object and assess whether the resulting model is more coherent and whether the extra effort is worthwhile.

## Interpretation and implementation recommendations
- **Hypothesis:** Separating an object's parts, attachments, proportions and movement before modeling could reduce arbitrary geometry and confused construction.
- **Potential adaptation:** Use the planning and inspection ideas to produce a clear modeling handoff; adapt any useful techniques to the existing Roblox workflow.
- **Limits:** A generated explanation can itself be wrong. Validate against real references. No Roblox-ready mesh export or Roblox integration has been verified. SVG/WebGL artwork does not establish a usable game mesh, and geometry checks do not prove biological or mechanical truth.
- Do not import its fixed detail counts, visual style, workflow mandates or illustrative mechanisms as project rules. Game scale, performance, server authority and [[3D Model Quality Baseline]] remain governing requirements.

## Experiment and evidence to add
Choose one structurally confusing object when a real modeling task warrants it. Record the uncertainty, real source references, selected Anatomy material and commit, planning artifact, model output, before/after evidence where available, extra effort and jg's judgment. Inspect the actual example/source needed before adapting it. Distinguish diagram quality, structural improvement and final Roblox asset quality. Record failed or inconclusive results as well as useful ones.

## Open questions
- Does this improve model coherence beyond the existing reference-first process?
- Which subjects and planning artifacts benefit most?
- Can any geometry tools transfer practically, or is the value mainly in planning?

## Traceability
- No implementation tasks, installed skill or production assets yet.
- Next stage: a scoped experiment on one troublesome object, then update the usefulness assessment with evidence.
