--!strict
-- Pure rules for the rare capture finisher's reduce-effects option (TASK-0054): how much weaker
-- flashes, shake and particle rates get. Kept free of Roblox services so Lune can test them.

local FinisherRules = {}

FinisherRules.REDUCED = { flash = 0.25, shake = 0.2, rate = 0.5, fovSwing = 0.5 }

-- Returns the strength/amplitude/rate to use for a cue param, given the reduce-effects setting.
function FinisherRules.scale(kind: "flash" | "shake" | "rate" | "fovSwing", value: number, reduced: boolean): number
	if not reduced then
		return value
	end
	return value * FinisherRules.REDUCED[kind]
end

-- Field of view for a camera cue; reduced mode keeps half of the swing away from the base FOV.
function FinisherRules.fov(base: number, target: number, reduced: boolean): number
	return base + (target - base) * FinisherRules.scale("fovSwing", 1, reduced)
end

return FinisherRules
