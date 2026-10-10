---
type: index
tags: [decision]
---
# Decision log

Approved Architecture Decision Records live in `docs/adr/` (template: [[Decision Record]]). Only **approved** decisions go here.

| ADR | Title | Date | Status |
|---|---|---|---|
| *(none yet)* | | | |

Setup choices made on 2026-10-10 (approved in chat, not ADRs):
- Workflow role files go in `workflow/roles/`, because `agents/` would collide with the Smart Second Brain `Agents/` folder on macOS.
- The knowledge base lives in the same vault as the repo.
