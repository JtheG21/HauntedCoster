--!strict
-- Habitat rotation schedule (ADR-0007): a fixed, repeating order, 900 s per habitat (a 60-minute cycle),
-- aligned to UTC epoch seconds so every server agrees without messaging. A warning shows 60 s before
-- each swap and new captures close in the last 15 s. Studio test runs may pass a faster copy through the
-- `rotation` test argument (RotationService); live servers only ever read this table.

export type Config = {
	order: { string }, -- habitat ids in rotation order
	slotSeconds: number,
	warningSeconds: number,
	closingSeconds: number,
	epoch: number, -- UTC seconds where slot 0 (the first habitat) starts
}

local Rotation: Config = {
	order = { "Cemetery", "Woodland", "SpiderWoodland", "Settlement" },
	slotSeconds = 900,
	warningSeconds = 60,
	closingSeconds = 15,
	epoch = 0,
}

return Rotation
