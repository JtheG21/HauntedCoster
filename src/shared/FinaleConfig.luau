--!strict
-- Ring-out finale tuning (TASK-0007). Arena layout is proven offline with roblox-map:
-- maps/finale_arena.json (deck top here = spec y 0; ring-out 20 studs below = 0.45 s fall).

local FinaleConfig = table.freeze({
	MaxSeconds = 60, -- the finale ends early once one player (or nobody) is left
	PollSeconds = 0.1, -- eliminations found in the same poll are simultaneous

	-- Arena (greybox). Centre X/Z = MatchConfig.Zones.Finale; the deck top sits at TopY.
	TopY = 60,
	DeckSize = Vector3.new(56, 4, 56),
	BumpSize = Vector3.new(6, 2, 6),
	BumpRadius = 14,
	RingOutDepth = 20, -- eliminated once the root is this far below the deck top
	BoundsRadius = 70, -- ... or this far from the centre horizontally (flung away)
	Spawns = table.freeze({
		Vector3.new(0, 3, 20),
		Vector3.new(0, 3, -20),
		Vector3.new(20, 3, 0),
		Vector3.new(-20, 3, 0),
		Vector3.new(14, 3, 14),
		Vector3.new(-14, 3, -14),
		Vector3.new(14, 3, -14),
		Vector3.new(-14, 3, 14),
	}),
	SpectateOffset = Vector3.new(0, 0, 50), -- spectator pad beside the arena, at ground level

	-- Knockback (players only, finale only). Applied by the server as a short LinearVelocity.
	Knockback = table.freeze({
		Range = 12, -- same reach as the obby Ki Burst
		MinSpeed = 45, -- horizontal studs/s at minimum charge
		MaxSpeed = 95, -- ... at full charge
		UpSpeed = 30, -- lift so the target leaves the ground
		Duration = 0.2,
		MaxForce = 60000,
	}),
	EchoBurstFraction = 0.6, -- a borrowed (Echo) Ki Burst hits like a 60% charge
	GuardSeconds = 6, -- an Echo Clone in the finale absorbs one hit within this time
})

return FinaleConfig
