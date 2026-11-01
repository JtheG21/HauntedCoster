--!strict
-- Approved cross-owner overlaps for the TextFit collision gate (TASK-0115). One entry per exact pair of element paths, with
-- the fixture it appears in and the reason. Nothing is exempt by name or class: a pair that overlaps and is not listed here
-- fails the gate, and an entry that matches nothing fails it too. Entries are added only with jg's approval, row by row.
-- Paths are relative to the gui root, e.g. "Screen_main/Play/Group/Shard"; the fixture is the Preview state id, plus
-- " [<player fixture>]" on the main menu, e.g. "01-main [standard]".

local CollisionRules = require(script.Parent.CollisionRules)

local manifest: { CollisionRules.ManifestEntry } = {}

return manifest
