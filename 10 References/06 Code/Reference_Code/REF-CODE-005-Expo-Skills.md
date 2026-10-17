---
id: REF-CODE-005
title: Expo Skills — Agent Knowledge and Workflow Reference
type: reference
status: proposed
area: code
source: https://github.com/expo/skills
accessed: 2026-10-16
created: 2026-10-16
updated: 2026-10-17
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

## Review decision (2026-10-17)
- **Outcome:** propose a scoped experiment
- **Decided by:** jg
- **Summary:** Source inspected 2026-10-17 at commit 927dd7cc20 (MIT text read in full), including the README, the tree, the evaluation skill, the feedback skill, one typical skill and the open pull requests. Expo Skills is an official collection of 25 skills for Expo, EAS and React Native plus a repo-local expo-skill-eval skill (48 KB with scripts); it is created 2025-11-30, has about 2.9k stars and 88 open issues, and nothing in it targets Roblox. Each skill is a SKILL.md with a references folder, with an index in the SKILL.md and cross-references between skills. The evaluation skill runs paired with-skill and without-skill comparisons, a trigger-accuracy check, code checks and simulator screenshots through claude -p calls (paid usage in our setup) and confirms scope with the user up front. Of the 68 open pull requests, a 2026-10-05/06 cluster hardens the skills (remove broad shell-tool preauthorization, pin setup helpers, centralize feedback and environment disclosure); PR 198 trims about 8,000 lines of duplicated documentation for progressive disclosure and states how Codex limits skill descriptions (1,024 characters each; a catalog of about 4,000 tokens across all skills for a 200k context), which I did not verify; PR 190 reports a with/without evaluation of 4 tasks with 12 of 12 passes in both conditions, no observed benefit on a small sample (the contributors' claims, unverified). The expo-skill-feedback skill instructs the agent to run npx --yes submit-expo-feedback@latest and bundles opt-in telemetry, so it is outbound network use and an unpinned package run and stays off limits. Against our skills: project descriptions are 340 to 494 characters (about 4.5k characters across eight skills), none uses allowed-tools preauthorization or an unpinned npx; the third-party roblox-map description is 1,232 characters and its SKILL.md 908 lines, which our lint does not cover. Rights ledger class moves from permissive-claimed to permissive-verified.
- **Evidence inspected:** Review packet; repo metadata and pinned tree (193 files); LICENSE and README in full; the skill list with sizes; expo-skill-eval SKILL.md (scope questions, pipeline, runner options) and its file list; expo-skill-feedback SKILL.md and file list; expo-router SKILL.md head; the open pull-request list (68) and bodies of PRs 231, 198 and 190; our own skills' description lengths and frontmatter
- **Still unverified:** The Codex description and catalog limits (taken from PR 198); the claims in PRs 190, 198 and the hardening cluster; the evaluation harness behaviour when run (not run: needs bun, Xcode and Android tooling, and paid claude -p calls); the content quality of the individual Expo skills; whether skills in this style improve our task outcomes
- **Next action:** (1) Write 3 to 5 realistic trigger prompts per project skill as an offline check list (no paid runs). (2) Extend skill_lint to warn on any skill description over 1,024 characters (third-party included) and on the total description budget. (3) Judge the reference-brief skill with a paired with/without comparison on a real task, using the REF-CODE-007 hit-rate. Any paid claude -p evaluation run needs jg's approval. Do not install the Expo skills, the feedback skill or its telemetry.
