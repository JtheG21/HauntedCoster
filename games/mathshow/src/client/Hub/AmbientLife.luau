--!strict
-- AmbientLife (TASK-0144, Map Finish B2): cosmetic ambient life for the hub. An occasional shooting star streaks across the night sky
-- and two low-volume ambient loops (night air, distant festival) play. Client-only: no remotes, nothing read from or sent to the server.
-- Every part of it is pcall-isolated, warns on failure and then stops that effect (fail inert), uses task.* only, and cleans up its
-- connection and instances. One RenderStepped connection moves one pooled streak part, under a frame budget. The geometry and timing
-- are pure (shared/AmbientRules.luau, headless spec); this file only turns them into a Part.

local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AmbientRules = require(ReplicatedStorage.Shared.AmbientRules)

local AmbientLife = {}

-- Visual and audio constants are client-only, so they live here (AGENTS.md "Layout constants").
local THEME = table.freeze({
	StreakShape = table.freeze({
		distance = 420,
		elevationMinDegrees = 22,
		elevationMaxDegrees = 55,
		travel = 120,
		dropFraction = 0.35,
	} :: AmbientRules.StreakShape),
	StreakLifeSeconds = 1.3,
	StreakFadeFraction = 0.3,
	StreakLength = 30, -- studs
	StreakThickness = 0.6,
	StreakColor = Color3.fromRGB(190, 240, 255), -- Holo Cyan family, pushed to white so it reads as a streak of light
	DelayMinSeconds = 7,
	DelayMaxSeconds = 16,
	FirstDelaySeconds = 4,
	FrameBudgetSeconds = 0.002, -- one update may take this long...
	OverrunLimit = 30, -- ...for this many frames in a row before the effect stops itself
	SoundGroupWait = 5, -- seconds to wait for the menu's "Sfx" SoundGroup before playing ungrouped
	SoundLoadWait = 12, -- seconds before an unloaded ambient sound is reported
	-- Free Creator Store audio used by id (no upload). Lengths measured in Studio (TimeLength) on 2026-11-06.
	Sounds = table.freeze({
		table.freeze({ name = "NightAir", id = 9112764546, volume = 0.1 }), -- "Crickets Night 1", 36.01 s loop
		table.freeze({ name = "DistantFestival", id = 9112766533, volume = 0.05 }), -- "Crowd Outdoor 2", 36.01 s loop
	}),
})

-- pcall wrapper: returns (ok, error message). Keeps the strict typechecker happy for callbacks that return nothing.
local function try(fn: () -> ()): (boolean, any)
	local results = table.pack(pcall(fn))
	return results[1] :: boolean, results[2]
end

local started = false
local connection: RBXScriptConnection? = nil
local streakPart: Part? = nil
local soundFolder: Folder? = nil

local function stopStars(reason: string)
	if connection then
		connection:Disconnect()
		connection = nil
	end
	if streakPart then
		streakPart:Destroy()
		streakPart = nil
	end
	warn(`[MathShow] AmbientLife shooting stars stopped: {reason}`)
end

local function makeStreakPart(): Part
	local part = Instance.new("Part")
	part.Name = "ShootingStar"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = THEME.StreakColor
	part.Size = Vector3.new(THEME.StreakThickness, THEME.StreakThickness, THEME.StreakLength)
	part.Transparency = 1
	part.Parent = Workspace.CurrentCamera -- the camera folder is local to this client and out of raycasts
	return part
end

local function runStars()
	local rng = Random.new()
	local part = makeStreakPart()
	streakPart = part
	local timer = THEME.FirstDelaySeconds
	local flying = false
	local age = 0
	local origin = Vector3.zero
	local direction = Vector3.zero
	local overruns = 0

	connection = RunService.RenderStepped:Connect(function(dt: number)
		local began = os.clock()
		local ok, err = try(function()
			if flying then
				age += dt
				local t = age / THEME.StreakLifeSeconds
				if t >= 1 then
					flying = false
					part.Transparency = 1
					timer = AmbientRules.nextDelay(THEME.DelayMinSeconds, THEME.DelayMaxSeconds, rng:NextNumber())
					return
				end
				local position = origin + direction * (THEME.StreakShape.travel * t)
				part.CFrame = CFrame.lookAt(position, position + direction)
				part.Transparency = AmbientRules.transparency(t, THEME.StreakFadeFraction)
				return
			end
			timer -= dt
			if timer > 0 then
				return
			end
			local camera = Workspace.CurrentCamera
			if not camera or GuiService.ReducedMotionEnabled then
				timer = AmbientRules.nextDelay(THEME.DelayMinSeconds, THEME.DelayMaxSeconds, rng:NextNumber())
				return
			end
			local streak = AmbientRules.streak(THEME.StreakShape, rng:NextNumber(), rng:NextNumber(), rng:NextNumber())
			origin = camera.CFrame.Position + Vector3.new(streak.offset.x, streak.offset.y, streak.offset.z)
			direction = Vector3.new(streak.direction.x, streak.direction.y, streak.direction.z)
			age = 0
			flying = true
		end)
		if not ok then
			stopStars(tostring(err))
			return
		end
		if os.clock() - began > THEME.FrameBudgetSeconds then
			overruns += 1
			if overruns >= THEME.OverrunLimit then
				stopStars("over the frame budget")
			end
		else
			overruns = 0
		end
	end)
end

local function startSounds()
	local folder = Instance.new("Folder")
	folder.Name = "HubAmbience"
	folder.Parent = SoundService
	soundFolder = folder
	local group = SoundService:WaitForChild("Sfx", THEME.SoundGroupWait)
	for _, entry in THEME.Sounds do
		local ok, err = try(function()
			local sound = Instance.new("Sound")
			sound.Name = entry.name
			sound.SoundId = `rbxassetid://{entry.id}`
			sound.Volume = entry.volume
			sound.Looped = true
			if group and group:IsA("SoundGroup") then
				sound.SoundGroup = group
			end
			sound.Parent = folder
			sound:Play()
			task.delay(THEME.SoundLoadWait, function()
				if sound.Parent and not sound.IsLoaded then
					warn(`[MathShow] AmbientLife sound {entry.name} ({entry.id}) did not load`)
				end
			end)
		end)
		if not ok then
			warn(`[MathShow] AmbientLife sound {entry.name} failed: {err}`)
		end
	end
end

-- Idempotent. Returns immediately; each effect starts on its own task and fails inert on its own.
function AmbientLife.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local ok, err = try(runStars)
		if not ok then
			warn(`[MathShow] AmbientLife shooting stars not started: {err}`)
		end
	end)
	task.spawn(function()
		local ok, err = try(startSounds)
		if not ok then
			warn(`[MathShow] AmbientLife sounds not started: {err}`)
		end
	end)
end

-- Removes everything this module made (used by tests and Studio scripts).
function AmbientLife.stop()
	started = false
	if connection then
		connection:Disconnect()
		connection = nil
	end
	if streakPart then
		streakPart:Destroy()
		streakPart = nil
	end
	if soundFolder then
		soundFolder:Destroy()
		soundFolder = nil
	end
end

return AmbientLife
