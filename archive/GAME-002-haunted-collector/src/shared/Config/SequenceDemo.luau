--!strict
-- Demo sequence for the runner (TASK-0053): a short charge and release beat. Cosmetic only.
-- Flash-risk budget: one light pulse, under the 3 per second guideline; checked with
-- evidence.py series --max-transitions 6 on a screen take.

local Sequence = require(script.Parent.Parent.Sequence)

local demo: Sequence.Def = {
	id = "demo_charge_release",
	length = 6,
	cues = {
		{ id = "push_in", at = 0, kind = "camera", duration = 2.5, params = { fov = 58 } },
		{ id = "aura", at = 0.5, kind = "effect", duration = 2.5, params = { effect = "aura", rate = 24 } },
		{ id = "burst", at = 3, kind = "effect", duration = 1.2, params = { effect = "burst", count = 40 } },
		{ id = "pulse", at = 3, kind = "camera", duration = 0.4, params = { fov = 74 } },
		{ id = "done", at = 5.5, kind = "callback", cleanup = false },
	},
}

return demo
