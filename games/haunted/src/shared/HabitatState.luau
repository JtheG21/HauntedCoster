--!strict
-- Replicated habitat rotation state (TASK-0029): a leaf module in the shape of SODT's RoundState. The
-- server (RotationService, HabitatService) writes these Workspace attributes; the client reads them for
-- the HUD countdown and the fog. Deadlines are Workspace:GetServerTimeNow() seconds.

local Workspace = game:GetService("Workspace")

local HabitatState = {}

HabitatState.Attr = {
	active = "ActiveHabitat", -- habitat id
	next = "HabitatNext", -- habitat id
	phase = "HabitatPhase", -- "open" | "warning" | "closing" | "pinned"
	swapAt = "HabitatSwapAt", -- server time of the next swap
	fog = "HabitatFog", -- true during the swap's fog fade
}

export type Snapshot = {
	active: string?,
	next: string?,
	phase: string,
	swapAt: number?,
	fog: boolean,
}

function HabitatState.read(): Snapshot
	local a = HabitatState.Attr
	local active = Workspace:GetAttribute(a.active)
	local nextId = Workspace:GetAttribute(a.next)
	local phase = Workspace:GetAttribute(a.phase)
	local swapAt = Workspace:GetAttribute(a.swapAt)
	return {
		active = if type(active) == "string" then active else nil,
		next = if type(nextId) == "string" then nextId else nil,
		phase = if type(phase) == "string" then phase else "pinned",
		swapAt = if type(swapAt) == "number" then swapAt else nil,
		fog = Workspace:GetAttribute(a.fog) == true,
	}
end

return HabitatState
