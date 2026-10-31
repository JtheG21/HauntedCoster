--!strict
-- Plot assignment (TASK-0037): the lowest-numbered free plot, or nil when every plot is taken.

local PlotRules = {}

function PlotRules.firstFree(owners: { [number]: any }, count: number): number?
	for i = 1, count do
		if owners[i] == nil then
			return i
		end
	end
	return nil
end

return PlotRules
