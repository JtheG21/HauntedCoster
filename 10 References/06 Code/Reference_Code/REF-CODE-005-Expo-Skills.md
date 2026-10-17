---
id: REF-CODE-005
title: Expo Skills — Agent Knowledge and Workflow Reference
type: reference
status: proposed
area: code
source: https://github.com/expo/skills
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-16
related:
  - "[[Reference_Code_Index]]"
tags:
  - reference/code
  - reference/ui
  - reference/automation
  - reference/needs-experimentation
---
# Expo Skills — Agent Knowledge and Workflow Reference

## Identity
- **Repository:** https://github.com/expo/skills
- **Additional research leads:** https://github.com/expo/skills/pulls
- **Purpose:** Explore transferable agent knowledge, visual-development methods, implementation practices and automation for Roblox games and supporting production tools.
- **Evaluation: needs experimentation.** No installation, execution, adaptation or runtime test performed.

## Inspection and evidence
Repository README and open pull-request listing inspected remotely on 2026-10-16. Individual skill files, implementation code, evaluation harness and PR diffs have not been inspected. Main branch was not pinned to a commit.

The README describes official Expo/React Native skills for UI, animation, design systems, project organization, debugging and development/service workflows. These are mobile/web ecosystem resources, not established Roblox/Luau integrations. The README identifies MIT licensing; full terms and file-specific notices remain to be checked for a concrete adaptation. Its separation of framework guidance, services and experimental material may be worth studying, but has not been evaluated here.

The pull-request listing contains proposed changes. Titles and status alone do not establish correctness, relevance or inclusion in main; inspect a specific PR's diff, discussion, tests and current status when using it as evidence.

## Intent — interview with jg, 2026-10-16
- The whole package interests jg; no individual skill selected yet.
- Desired improvements: Claude's knowledge, visual quality, implementation reliability and automation.
- Use pull requests as additional research leads when relevant, not as automatically adopted guidance.
- Explore both Roblox adaptations and useful supporting tools outside Roblox, such as dashboards or production utilities, when a task warrants them.
- Mark needs experimentation. Evaluate individual methods on real tasks and record whether they improve results.

## Interpretation and implementation recommendations
- **Hypothesis:** How the collection organizes focused knowledge and workflows may transfer more directly than its platform-specific APIs or commands.
- **Potential adaptation:** Inspect relevant UI/design-system, animation, debugging or automation guidance and translate the useful principles into this project's conventions.
- **Compatibility:** React Native, Expo APIs, EAS services and mobile deployment assumptions do not establish Roblox equivalents. Do not add their dependencies to game code by default.
- **Supporting tools:** A future utility may benefit directly from Expo if its requirements justify it. No utility, app, installation or service migration is requested by capturing this reference.
- Compare proposed practices with existing task intake, reference indexes, checks and tooling before adding duplicate workflow layers. Upstream instructions are reference material, not local rules or authority to install, transmit feedback, deploy or spend money.

## Experiment and evidence to add
For each method record: real task/problem, exact source files and commit or PR revision, inspected content, proposed benefit, platform assumptions, adaptation, baseline and result, relevant tests/visual evidence, effort and jg's judgment. Distinguish Roblox improvements from supporting-tool improvements. Retain failures and unresolved limits; success with one method does not validate the full collection.

## Open questions
- Which methods add value beyond the current workflow?
- Which guidance transfers to Roblox, and which only helps an external tool?
- Do evaluation or maintenance techniques improve reliability enough to justify their overhead?

## Traceability
- No implementation tasks or installed skills yet.
- Next stage: select a relevant method for a scoped task, inspect its actual files and test the adaptation.
