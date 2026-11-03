--!strict
-- HubCosmetics (TASK-0126, TASK-0132): the rank crystal over the plaza plinth turns and bobs, and the decorative holo symbols
-- (Hub.Holo parts tagged HubHolo, each carrying a BillboardGui TextLabel) bob and sway. Client-only and cosmetic: it sends and
-- reads nothing from the server, one RenderStepped connection moves everything, and any failure warns once and stops the
-- effect (gameplay is untouched). The map is generated; this only animates the parts locally. The holos float far above
-- anything walkable and never carry a GlyphSpawn tag, so they are never mistaken for a collectible Glyph.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local HubCosmetics = {}

-- Visual constants are client-only, so they live here (AGENTS.md "Layout constants").
local THEME = table.freeze({
	FindTimeout = 15, -- seconds to wait for the streamed-in hub before giving up
	SpinRadiansPerSecond = math.rad(24),
	BobHeight = 0.35, -- studs, each way
	BobSeconds = 5,
	HoloTag = "HubHolo",
	HoloBobHeight = 1.4, -- studs, each way
	HoloBobSeconds = 7,
	HoloSwayDegrees = 9, -- the label rocks this far each way (a BillboardGui always faces the camera, so it cannot spin)
	HoloSwaySeconds = 9,
	CullDistance = 260, -- skip the update while the camera is farther than this
	FrameBudgetSeconds = 0.002, -- one update may take this long...
	OverrunLimit = 30, -- ...for this many frames in a row before the effect stops itself
})

type Holo = { part: BasePart, label: TextLabel?, home: CFrame, phase: number }

local started = false
local connection: RBXScriptConnection? = nil
local crystalModel: Model? = nil
local crystalHome: CFrame? = nil
local holos: { [Instance]: Holo } = {}
local holoCount = 0

local function stop(reason: string)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	warn(`[MathShow] HubCosmetics stopped: {reason}`)
end

local function addHolo(instance: Instance)
	if holos[instance] or not instance:IsA("BasePart") then
		return
	end
	local label: TextLabel? = nil
	local found = instance:FindFirstChildWhichIsA("TextLabel", true)
	if found then
		label = found
	end
	holoCount += 1
	holos[instance] = { part = instance, label = label, home = instance.CFrame, phase = holoCount * 1.3 }
end

local function removeHolo(instance: Instance)
	holos[instance] = nil
end

local function step(angle: number, clock: number, holoClock: number, swayClock: number)
	local camera = Workspace.CurrentCamera
	local cameraPosition = if camera then camera.CFrame.Position else nil
	local crystal, home = crystalModel, crystalHome
	if
		crystal
		and home
		and not (cameraPosition and (cameraPosition - home.Position).Magnitude > THEME.CullDistance)
	then
		local bob = math.sin(clock / THEME.BobSeconds * 2 * math.pi) * THEME.BobHeight
		crystal:PivotTo(home * CFrame.new(0, bob, 0) * CFrame.Angles(0, angle, 0))
	end
	for _, holo in holos do
		if not holo.part.Parent then
			continue
		end
		if cameraPosition and (cameraPosition - holo.home.Position).Magnitude > THEME.CullDistance + 120 then
			continue
		end
		local bob = math.sin(holoClock / THEME.HoloBobSeconds * 2 * math.pi + holo.phase) * THEME.HoloBobHeight
		holo.part.CFrame = holo.home * CFrame.new(0, bob, 0)
		local label = holo.label
		if label then
			label.Rotation = math.sin(swayClock / THEME.HoloSwaySeconds * 2 * math.pi + holo.phase)
				* THEME.HoloSwayDegrees
		end
	end
end

local function run()
	local overruns = 0
	local angle = 0
	local clock = 0
	local holoClock = 0
	local swayClock = 0
	connection = RunService.RenderStepped:Connect(function(dt: number)
		local began = os.clock()
		local ok, err = pcall(function()
			angle = (angle + THEME.SpinRadiansPerSecond * dt) % (2 * math.pi)
			clock = (clock + dt) % THEME.BobSeconds
			holoClock = (holoClock + dt) % (THEME.HoloBobSeconds * 1000)
			swayClock = (swayClock + dt) % (THEME.HoloSwaySeconds * 1000)
			step(angle, clock, holoClock, swayClock)
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
			crystalModel = crystal
			crystalHome = crystal:GetPivot()
			for _, tagged in CollectionService:GetTagged(THEME.HoloTag) do
				addHolo(tagged)
			end
			CollectionService:GetInstanceAddedSignal(THEME.HoloTag):Connect(addHolo)
			CollectionService:GetInstanceRemovedSignal(THEME.HoloTag):Connect(removeHolo)
			run()
		end)
		if not ok then
			warn(`[MathShow] HubCosmetics not started: {err}`)
		end
	end)
end

return HubCosmetics
