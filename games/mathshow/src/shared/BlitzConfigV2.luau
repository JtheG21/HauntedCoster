--!strict
-- Tunables for BlitzRulesV2 (blueprint section 8, split plan decision 1). Frozen: never mutate at runtime.
-- TotalSeconds is a design tunable, see split plan decision 1; do not hardcode 10 anywhere else.

local BlitzConfigV2 = table.freeze({
	Questions = 10, -- slots in one run
	TotalSeconds = 10, -- one clock for the whole run
})

return BlitzConfigV2
