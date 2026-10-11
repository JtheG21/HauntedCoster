--!strict
-- Ability tuning and limits (TASK-0002+). Server and client both read this; only the server enforces it.

export type AbilityDef = {
	cooldown: number, -- seconds between activations
	keyCode: Enum.KeyCode?, -- keyboard binding (client). Abilities without one are only fired via `releaseId`
	label: string?, -- touch button label (client)
	releaseId: string?, -- if set, releasing the key fires this ability id (hold-to-charge abilities)
}

local abilities: { [string]: AbilityDef } = {
	Dash = {
		cooldown = 1.0,
		keyCode = Enum.KeyCode.Q,
		label = "Dash",
	},
	EchoClone = {
		cooldown = 8.0,
		keyCode = Enum.KeyCode.E,
		label = "Clone",
	},
	-- Ki Burst is hold-to-charge: key down sends KiCharge, key up sends KiBurst. The server times
	-- the charge between the two requests; the client never reports a charge amount.
	KiCharge = {
		cooldown = 0.25,
		keyCode = Enum.KeyCode.R,
		label = "Ki",
		releaseId = "KiBurst",
	},
	KiBurst = {
		cooldown = 3.0,
	},
}
for _, def in abilities do
	table.freeze(def)
end

local AbilityConfig = table.freeze({
	RemoteName = "AbilityRemote",
	-- Max requests per player per window, counting rejected ones, so spam is cheap to drop.
	MaxRequestsPerWindow = 5,
	RateWindowSeconds = 1,
	-- Minimum seconds between rejection warnings per player (keeps the server log readable).
	WarnIntervalSeconds = 5,

	Abilities = table.freeze(abilities),

	Dash = table.freeze({
		Speed = 60, -- studs/second, horizontal
		Duration = 0.2, -- seconds the velocity constraint stays active
		-- Finite cap so a dash can't fling heavy assemblies. Gives the full dash at character mass 11.8 (TEST-20261010-04).
		MaxForce = 40000,
	}),

	KiBurst = table.freeze({
		MinChargeSeconds = 0.5, -- held less than this = minimum power
		MaxChargeSeconds = 1.5, -- held this long or more = full power
		StaleChargeSeconds = 5, -- a charge older than this is discarded (minimum power)
		Range = 12, -- studs in front of the character
		MinPushSpeed = 15, -- velocity change (studs/s) given to a HeavyBlock at minimum charge
		MaxPushSpeed = 45, -- ... and at full charge (impulse = speed * block mass)
		WallBreakFraction = 0.5, -- charge fraction needed to break a CrackedWall
		WallRespawnSeconds = 10,
	}),

	EchoClone = table.freeze({
		Duration = 6, -- seconds the clone exists (and holds a plate)
		Size = Vector3.new(2, 5, 1),
		Transparency = 0.5,
	}),
})

return AbilityConfig
