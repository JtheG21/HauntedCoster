---
type: index
tags: [lesson]
---
# Lessons learned

Short entries only. Link to the source (audit, bug, task). For a longer write-up, use the [[Lesson Learned]] template.

## Bug patterns
- Rojo plugin/server version mismatch shows up as `attempt to index number with 'protocolVersion'`: 7.7 sends MessagePack, 7.6 sends JSON. Keep `rokit.toml` matched to the Studio plugin. (2026-10-10)
- Strict Luau: an untyped test param `t` gets its type from its first use. Annotate it as `TestRunner.T`. (T-001)
## Failed approaches
## Good patterns
## Process
- The first full workflow run (T-001) worked: checks → Studio MCP playtest → fresh-agent audit came to about 75k audit tokens for a small task. The independent audit found real gaps the executor missed (exploit rate limits, a check that skips but still reports PASS). (2026-10-10)
