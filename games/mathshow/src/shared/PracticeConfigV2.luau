--!strict
-- Tunables for PracticeRulesV2 (blueprint section 4, split plan decision 5). Frozen: never mutate at runtime.

local PracticeConfigV2 = table.freeze({
	Questions = 6, -- one practice assessment
	MaxSuggestions = 3, -- skill tags suggestNext returns
})

return PracticeConfigV2
