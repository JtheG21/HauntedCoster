--!strict
-- Approved cross-owner overlaps for the TextFit collision gate (TASK-0115). One entry per exact pair of element paths, with
-- the fixture it appears in and the reason. Nothing is exempt by name or class: a pair that overlaps and is not listed here
-- fails the gate, and an entry that matches nothing fails it too. Entries are added only with jg's approval, row by row.
-- Paths are relative to the gui root, e.g. "Screen_main/Play/Group/Shard"; a fixture is the Preview state id, plus
-- " [<player fixture>]" on the main menu, e.g. "01-main [standard]". An entry lists every fixture where the pair appears; a listed
-- fixture that does not produce the pair makes the entry unused, which fails the gate.

local CollisionRules = require(script.Parent.CollisionRules)

local manifest: { CollisionRules.ManifestEntry } = {
	{
		a = "Screen_ladder/Rung1/Group/Shard",
		b = "Screen_ladder/Rung0/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung2/Group/Shard",
		b = "Screen_ladder/Rung1/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung3/Group/Shard",
		b = "Screen_ladder/Rung2/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung4/Group/Shard",
		b = "Screen_ladder/Rung3/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung6/Group/Shard",
		b = "Screen_ladder/Rung5/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung7/Group/Shard",
		b = "Screen_ladder/Rung6/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung8/Group/Shard",
		b = "Screen_ladder/Rung7/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_ladder/Rung9/Group/Shard",
		b = "Screen_ladder/Rung8/Group/Shard",
		fixtures = { "16a-rank-ladder", "16b-rank-ladder-demon", "16c-rank-ladder-unranked" },
		reason = "staggered rank stack, intentional",
	},
	{
		a = "Screen_blitzreview/Card/Group/Shard",
		b = "Screen_blitzreview/NewBest",
		fixtures = { "07a-blitz-review-best", "07b-blitz-review-perfect-first" },
		reason = "NEW BEST corner badge, intentional",
	},
	{
		a = "Toasts/Toast/Group/Shard",
		b = "Screen_main/Title/Group/Shard",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Shard",
		b = "Screen_main/PlayerCard/Group/Shard",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Content/Mark",
		b = "Screen_main/Title/Group/Shard",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Content/Label",
		b = "Screen_main/Title/Group/Shard",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Shard",
		b = "Screen_skill/Choice3/Group/Shard",
		fixtures = { "14b-skill-choice-locked", "14c-skill-choice-reveal-wrong" },
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Shard",
		b = "Screen_main/Spark3",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
	{
		a = "Toasts/Toast/Group/Content/Label",
		b = "Screen_main/Spark3",
		fixtures = {
			"20-coming-soon [demon2]",
			"20-coming-soon [official]",
			"20-coming-soon [standard]",
			"20-coming-soon [unavailable]",
			"20-coming-soon [unranked]",
			"20-coming-soon [wide20]",
		},
		reason = "transient toast overlay",
	},
}

return manifest
