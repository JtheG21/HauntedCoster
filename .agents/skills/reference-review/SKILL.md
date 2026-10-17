---
name: reference-review
description: Review one reference note from the Reference Review Index with jg, one item at a time. Prints the review packet, opens the real source, asks jg for the decision in one batch, then records it (dated section, Index tick, Catalog tag) without touching jg's Intent or the note's status. Use when jg says to review a reference, work through the reference queue, or names a REF id. Only jg starts it.
argument-hint: [REF-ID]
disable-model-invocation: true
---
# Review reference $ARGUMENTS

Procedure: `00 Studio/Reference Review Index.md` ("How to review one item"). Tooling: `scripts/refs.py`. One item per run. The decision is jg's; you prepare it. Never record a conclusion about material you did not open.

## 1. Packet
`python3 scripts/refs.py review-next` (add `--id $ARGUMENTS` if one is named). Read the packet: identity, what was inspected, jg's Intent, open questions, rights class, pin, and the spec's proposed automations for this note.

## 2. Open the real source
- Archived media: `python3 scripts/evidence.py frames <REF-ID> ...`, then `strip`, `beats`, `series`, `audio` as the question needs. Read contact sheets, not dozens of single frames. Outputs go outside the vault.
- Live link or repo: read it (web fetch, `gh api`); pin GitHub sources with `python3 scripts/refs.py pin --ids <REF-ID>` (read-only, appends to `tasks/reference-pins.jsonl`).
- Rights: `python3 scripts/refs.py rights --check <REF-ID> --use code|asset|method`.
- Say what you could not open. Sampled frames are not a motion review; a README is not the code.

## 3. Prepare for jg
Keep four things apart: observed, inferred, jg's preference (from Intent), your recommendation. Add: one concrete use, what the Resource Catalog or existing tools already cover (`grep -i`), the cheapest next step, and the cost or gate it hits (download, upload, account, install: all need jg's explicit yes).

## 4. Ask once
One `AskUserQuestion` batch: the outcome (`keep`, `investigate`, `experiment`, `unsuitable`), the next action or the stated use it is unsuitable for, and anything in the note jg says is wrong. Put your recommended option first.

## 5. Record, only after jg answers
1. Work in a chore worktree, not the main checkout: `git worktree list`; create `chore/ref-review-<id>` if none, chained after `scripts/preflight.sh --root <checkout> --branch <branch>`.
2. Dry run: `python3 scripts/refs.py decide <REF-ID> --outcome ... --summary ... --inspected ... --unverified ... [--next ...] --by jg`. Show jg the wording.
3. After jg confirms the wording in chat: add `--apply`. It appends `## Review decision (date)`, ticks the Index box, tags the Catalog row and runs the lint.
4. `python3 scripts/refs.py guard --base main` must pass (it fails if Intent or `status` changed). Commit with preflight chained, push, and tell jg; open a PR only if asked.

## Never
Edit `## Intent` or `status`; erase earlier findings; start the experiment; install, download, upload, spend or create accounts; review several items in one go.

## Report
Which item, what you opened, findings, jg's decision, what is still unverified, and the next item in the queue.
