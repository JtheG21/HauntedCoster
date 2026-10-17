---
id: REF-MISC-001
title: Anatomy — Structural Modeling Exploration
type: reference
status: proposed
area: misc
source: https://github.com/wheresryan22/anatomy
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
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

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Source inspected 2026-10-17 at commit e9488296a4 (MIT, read in full). Anatomy is an explainer-figure skill: it invents a physical machine whose working illustrates a technical idea and renders it as an interactive isometric SVG page, with optional WebGL shaders and a beta 3D mode. Its README limits it to machines, instruments, tools and furniture, not people or exact maps, and it has no mesh or Roblox export. Its geometry audit (nothing passes through anything, every end sits on a mount, overlaps drawn in depth order) runs only on its own SVG solids. The transferable part is the method: collect the real numbers first, write a parts list before any geometry with each part sitting on another part, and verify like a critic with close-ups of every junction; never copy a reference's object, only its finish. Its fixed part counts (40-80 for a Figure, 80-150 for a Hero), SVG kit, WebGL and React are not transferable. It needs Node 20.10+ and headless Chrome (Node is not installed on this Mac); a Figure is quoted as under an hour and a Hero as 2-4 hours. It ships 5 eval prompts with expected outputs, a pattern we could reuse for our own skills. The note's earlier claims (SVG, optional WebGL, beta 3D, parts list before geometry, geometry checks) are confirmed. Rights ledger class moves from permissive-claimed to permissive-verified.
- **Evidence inspected:** Review packet; repo metadata and pinned tree at e9488296a4; LICENSE in full; README (what it makes, how it works, requirements, limits); SKILL.md (the idea, workflow, craft rules); CHANGELOG head; evals.json; two gallery images (raptor-engine-apart, dial-indicator) viewed
- **Still unverified:** Whether the method improves model coherence beyond the existing reference-first process; the examples' behaviour when run (Node is not installed, nothing was executed); the 3D mode; the eval prompts' quality; the repository's stability (nine days old)
- **Next action:** On the first structurally confusing object in a real model task (jg flags it), write a parts list with support relations and proportions before modeling and compare it against the baseline process, one revision each, recording the extra effort. Method only: do not install the skill (it needs Node 20.10+, which is not installed, and it makes illustrations, not meshes). Any structure check on Blender or Roblox output would be our own build, not part of this repository.
