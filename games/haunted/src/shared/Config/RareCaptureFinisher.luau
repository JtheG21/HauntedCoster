--!strict
-- Rare capture finisher (TASK-0054): a 12.8 s cosmetic sequence for the sequence runner (ADR-0012).
-- Phases after REF-VFX-001's methods, restated for this game: cold charge, white peak, purple release,
-- joined by two short flash bursts, with a changing camera. Flash budget: two flashes, 4 s apart.

local Sequence = require(script.Parent.Parent.Sequence)

local finisher: Sequence.Def = {
	id = "rare_capture_finisher",
	length = 12.8,
	cues = {
		-- input lock for the whole sequence; the runner always releases it
		{ id = "lock", at = 0, kind = "effect", duration = 12.6, params = { effect = "lock" } },

		-- the rune disc under the monster lives through all three phases and changes colour with them
		{
			id = "rune",
			at = 0,
			kind = "effect",
			duration = 12.2,
			params = {
				effect = "rune",
				size = 26,
				colors = {
					{ at = 0, c = { 0.55, 1, 0.9 } },
					{ at = 4, c = { 1, 1, 1 } },
					{ at = 8, c = { 0.85, 0.6, 1 } },
				},
			},
		},

		-- phase 1: charge (cold blue-green), slow push-in and orbit
		{
			id = "tint_charge",
			at = 0,
			kind = "effect",
			duration = 4.2,
			params = { effect = "tint", color = { 0.55, 1, 0.9 }, brightness = -0.08 },
		},
		{
			id = "aura",
			at = 0.3,
			kind = "effect",
			duration = 3.9,
			params = { effect = "aura", color = { 0.4, 1, 0.85 }, rate = 30 },
		},
		{
			id = "cam_orbit",
			at = 0,
			kind = "camera",
			duration = 4.1,
			params = { pos = "orbit", radius = 16, height = 5, fov = 55 },
		},

		-- burst 1 into the peak
		{
			id = "shock_1",
			at = 4,
			kind = "effect",
			duration = 1,
			params = { effect = "shockwave", color = { 1, 1, 1 }, size = 50 },
		},
		{ id = "flash_1", at = 4, kind = "effect", duration = 0.35, params = { effect = "flash", strength = 0.6 } },

		-- phase 2: peak (white pillar, lightning stack, shake and a wide cut)
		{
			id = "tint_peak",
			at = 4,
			kind = "effect",
			duration = 4.2,
			params = { effect = "tint", color = { 1, 1, 1 }, brightness = 0.06 },
		},
		{ id = "pillar", at = 4.1, kind = "effect", duration = 3.9, params = { effect = "pillar", height = 60 } },
		{
			id = "lightning",
			at = 4.3,
			kind = "effect",
			duration = 3.7,
			params = { effect = "sparks", rate = 40 },
		},
		{
			id = "cam_wide",
			at = 4.1,
			kind = "camera",
			duration = 2.0,
			params = { pos = "orbit", radius = 24, height = 8, fov = 82, shake = 0.35 },
		},
		{
			id = "cam_low",
			at = 6.1,
			kind = "camera",
			duration = 2.0,
			params = { pos = "low", radius = 14, fov = 68, shake = 0.2 },
		},

		-- burst 2 into the release
		{
			id = "shock_2",
			at = 8,
			kind = "effect",
			duration = 1,
			params = { effect = "shockwave", color = { 0.85, 0.6, 1 }, size = 50 },
		},
		{ id = "flash_2", at = 8, kind = "effect", duration = 0.35, params = { effect = "flash", strength = 0.6 } },

		-- phase 3: release (purple), orb orbits the ghost faster and faster then breaks off toward the player, camera pulls back
		{
			id = "tint_release",
			at = 8,
			kind = "effect",
			duration = 4.4,
			params = { effect = "tint", color = { 0.85, 0.6, 1 }, brightness = -0.04 },
		},
		{
			id = "burst",
			at = 8.1,
			kind = "effect",
			duration = 1.5,
			params = { effect = "burst", color = { 0.8, 0.5, 1 }, count = 60 },
		},
		{
			id = "orb",
			at = 8.2,
			kind = "effect",
			duration = 4.4,
			params = { effect = "orb", color = { 0.8, 0.5, 1 }, orbitTime = 3.3, snapTime = 0.55 },
		},
		{
			id = "cam_back",
			at = 8,
			kind = "camera",
			duration = 4.3,
			params = { pos = "orbit", radius = 28, height = 10, fov = 60 },
		},

		{ id = "done", at = 12.7, kind = "callback", cleanup = false },
	},
}

return finisher
