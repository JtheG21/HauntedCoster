--!strict
-- Tunables for StandingsRules (Results screen, TASK-0094). Frozen: never mutate at runtime.

local StandingsConfig = table.freeze({
	PodiumSize = 3, -- rows on the podium
	ListRows = 5, -- rows listed under the podium
	MaxNameChars = 20, -- longer names are cut with an ellipsis
	MaxPoints = 2147483647, -- IntValue limit; also the display cap
})

return StandingsConfig
