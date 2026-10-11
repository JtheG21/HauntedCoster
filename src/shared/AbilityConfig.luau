--!strict
-- Ability tuning and limits (TASK-0002). Server and client both read this; only the server enforces it.

export type AbilityDef = {
	cooldown: number, -- seconds between activations
	keyCode: Enum.KeyCode, -- default keyboard binding (client)
	label: string, -- touch button label (client)
}

local AbilityConfig = table.freeze({
	RemoteName = "AbilityRemote",
	-- Max requests per player per window, counting rejected ones, so spam is cheap to drop.
	MaxRequestsPerWindow = 5,
	RateWindowSeconds = 1,
	-- Minimum seconds between rejection warnings per player (keeps the server log readable).
	WarnIntervalSeconds = 5,

	Abilities = table.freeze({
		Dash = table.freeze({
			cooldown = 1.0,
			keyCode = Enum.KeyCode.Q,
			label = "Dash",
		}),
		EchoClone = table.freeze({
			cooldown = 8.0,
			keyCode = Enum.KeyCode.E,
			label = "Clone",
		}),
	}) :: { [string]: AbilityDef },

	Dash = table.freeze({
		Speed = 60, -- studs/second, horizontal
		Duration = 0.2, -- seconds the velocity constraint stays active
		-- Finite cap so a dash can't fling heavy assemblies. Gives the full dash at character mass 11.8 (TEST-20261010-04).
		MaxForce = 40000,
	}),

	EchoClone = table.freeze({
		Duration = 6, -- seconds the clone exists (and holds a plate)
		Size = Vector3.new(2, 5, 1),
		Transparency = 0.5,
	}),
})

return AbilityConfig
