--!strict
-- Convergence Gate tuning (TASK-0005).

local GateConfig = table.freeze({
	Tag = "ConvergenceGate",
	KiTargetTag = "KiTarget",
	-- Powers a gate asks for when it has no "Powers" attribute ("Shinobi,Ki" style list).
	DefaultPowers = table.freeze({ "Shinobi", "Ki" }),
	ApplyWindowSeconds = 10, -- every required power must have been applied within this many seconds of now
	OpenSeconds = 8, -- how long an opened gate stays open
	ShrineDelaySeconds = 20, -- Echo Shrine bypass opens this long after the first arrival
	PollSeconds = 0.1,
	OpenTransparency = 0.85,
})

return GateConfig
