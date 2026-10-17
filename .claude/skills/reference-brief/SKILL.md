---
name: reference-brief
description: Build the reference brief and interview for a Standard or Deep Rg1 task before planning it. Pulls the matching reference notes, checks their rights class, turns their own interview lists into one batched question set, adds an expert-lens check and an independent-evidence plan, and writes a short Intake block into the task note. Use at Task Intake steps 5-7 for visual, motion, asset, UI, audio or pipeline work when notes exist in 10 References, or when jg asks for an expert-informed brief.
argument-hint: TASK-#### or a category (map, vfx, ui, asset, audio, systems, game)
---
# Reference brief for $ARGUMENTS

Method: [[REF-CODE-007-Expert-Informed-Briefs]] (supported direction, still an experiment). Skip for Light tasks. It sharpens the brief; it does not widen the objective. Task Intake and AGENTS.md win on any conflict.

## 1. Pull
`python3 scripts/refs.py brief --task $ARGUMENTS` (or `--category <name>`; add `--tier deep` for Deep). Treat `approved` as jg's preference and quality floor, not proof of feasibility. Open media only for the beat you need (`scripts/evidence.py frames|strip`). Prefer the quality notes' own interview lists over inventing questions.

## 2. Rights
For any note whose code or assets would be adapted: `python3 scripts/refs.py rights --check <REF-ID> --use code|asset`. Methods and ideas are restated in our own words. A blocked result goes into the brief as a constraint.

## 3. Interview, one batch
Ask only what changes the result, each with a recommended default:
- from each note: the questions it lists (for example subject and action, phases and durations, camera, palette, scale, player control, performance target; for worlds palette, density, lighting, landmarks, viewpoint);
- the expert lens: what would a relevant expert ask or inspect that this brief lacks; which original sources, assets or data exist; which methods or tools fit this environment; what evidence of correctness does not depend on our impressions.
Model-generated expert advice is a proposal to verify, not authority.

## 4. Evidence plan
Behavior: Lune spec or Studio scenario. Visuals: matched-view sheet (`evidence.py sheet`). Motion: paired frame strips at the same beats; on-screen flashing: `evidence.py series`. Preference: jg. Tests do not establish taste; a good render does not establish runtime correctness.

## 5. Write the Intake block (25 lines or fewer)
In the task note: **References** (IDs), **Qualities taken** (quoted from Intent), **Not taken** (exclusions, rights limits), **Evidence plan**, **Open questions** (the batch), **Ambition proposals** (listed separately; each needs jg's yes or no before it enters scope), **Rights**.

## 6. Measure it
After jg answers, add one line to the task note: `Brief review: <N> additions proposed, <M> accepted by jg, interview <K> questions`. `python3 scripts/refs.py ledger` reports the rest. If few additions are accepted over several tasks, drop the step.

## Never
Expand the objective unasked; install, spend, publish or add agents; treat a reference as permission to copy its characters, layouts or assets.
