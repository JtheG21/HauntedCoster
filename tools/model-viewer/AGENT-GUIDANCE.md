# Shared viewer instructions

Claude and Codex use the same CLI, library schema and browser controls. Read README.md before adding or reviewing assets. Follow the parent repository's AGENTS.md for code changes and reviews.

- Start with a real model. Do not substitute the animated test triangle for an art deliverable or call an existing asset newly approved.
- Keep originals unchanged. Use a new package ID for geometry revisions. Review effects-off neutral views before cinematic presentation.
- Portable handoff = package folder + scene JSON + viewport captures + actual clip names and known limits. Browser storage alone is not a handoff.
- Library is ignored. Keep asset packages in established backed-up asset storage; never imply a source-code push backed up local models.
- Run scripts/check.sh here for this tool, and repository-root scripts/check.sh before independent review. Browser tests require the real Wisp and fixture packages described in README.md.
- Never start a server at the vault root. serve.py is loopback-only; it has no file-writing API. Do not add arbitrary filesystem or network loaders casually.
- Web review does not prove Roblox import, scale, rig deformation, materials or runtime performance. Report those limits and use the approved separate import process when requested.
