--!strict
-- HubCosmetics (TASK-0126): the rank crystal over the plaza plinth turns and bobs. Client-only and cosmetic: it sends and
-- reads nothing from the server, one RenderStepped connection moves one model, and any failure warns once and stops the
-- effect (gameplay is untouched). The map is generated; this only animates `Hub.Plaza.RankCrystal` locally.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HubCosmetics = {}

-- Visual constants are client-only, so they live here (AGENTS.md "Layout constants").
local THEME = table.freeze({
	FindTimeout = 15, -- seconds to wait for the streamed-in hub before giving up
	SpinRadiansPerSecond = math.rad(24),
	BobHeight = 0.35, -- studs, each way
	BobSeconds = 5,
	CullDistance = 260, -- skip the update while the camera is farther than this
	FrameBudgetSeconds = 0.002, -- one update may take this long...
	OverrunLimit = 30, -- ...for this many frames in a row before the effect stops itself
})

local started = false
local connection: RBXScriptConnection? = nil

local function stop(reason: string)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	warn(`[MathShow] HubCosmetics stopped: {reason}`)
end

local function run(crystal: Model)
	local home = crystal:GetPivot()
	local overruns = 0
	local angle = 0
	local clock = 0
	connection = RunService.RenderStepped:Connect(function(dt: number)
		local began = os.clock()
		local ok, err = pcall(function(): string?
			local camera = Workspace.CurrentCamera
			if camera and (camera.CFrame.Position - home.Position).Magnitude > THEME.CullDistance then
				return nil
			end
			angle = (angle + THEME.SpinRadiansPerSecond * dt) % (2 * math.pi)
			clock = (clock + dt) % THEME.BobSeconds
			local bob = math.sin(clock / THEME.BobSeconds * 2 * math.pi) * THEME.BobHeight
			crystal:PivotTo(home * CFrame.new(0, bob, 0) * CFrame.Angles(0, angle, 0))
			return nil
		end)
		if not ok then
			stop(tostring(err))
			return
		end
		if os.clock() - began > THEME.FrameBudgetSeconds then
			overruns += 1
			if overruns >= THEME.OverrunLimit then
				stop("over the frame budget")
			end
		else
			overruns = 0
		end
	end)
end

-- Idempotent. Returns immediately; the model is looked up on a task so a slow load never blocks the client entry point.
function HubCosmetics.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local ok, err = pcall(function()
			local hub = Workspace:WaitForChild("Hub", THEME.FindTimeout)
			local plaza = hub and hub:WaitForChild("Plaza", THEME.FindTimeout)
			local crystal = plaza and plaza:WaitForChild("RankCrystal", THEME.FindTimeout)
			if not (crystal and crystal:IsA("Model")) then
				error("Hub.Plaza.RankCrystal not found")
			end
			run(crystal)
		end)
		if not ok then
			warn(`[MathShow] HubCosmetics not started: {err}`)
		end
	end)
end

return HubCosmetics
