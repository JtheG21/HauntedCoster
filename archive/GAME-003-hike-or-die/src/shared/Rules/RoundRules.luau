--!strict
local RoundRules = {}

function RoundRules.canPhotograph(phase: string): boolean
	return phase == "active"
end

function RoundRules.canExtract(phase: string): boolean
	return phase == "active"
end

function RoundRules.canRestart(phase: string): boolean
	return phase == "failed" or phase == "extracted"
end

function RoundRules.photoStartsPursuit(state: string): boolean
	return state == "Investigating"
end

return table.freeze(RoundRules)
