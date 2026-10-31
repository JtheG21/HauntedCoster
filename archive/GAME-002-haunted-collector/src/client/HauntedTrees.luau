--!strict
-- Haunted-tree faces on the client (TASK-0041, ADR-0010): the local camera gaze test and its reports, and
-- every face's eye, lid and jaw animation. One render-step loop drives all nearby faces; animation is
-- target-and-damp (no tweens), so any interruption settles into a valid pose. The face is frozen while the
-- server's `Frozen` attribute is set, and also at once while this client is looking (and for the resume
-- delay after), so the looker never sees it move. Trunks, roots and branches are never touched.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HauntedTrees = require(Shared:WaitForChild("Config"):WaitForChild("HauntedTrees"))
local GazeRules = require(Shared:WaitForChild("Rules"):WaitForChild("GazeRules"))
local TreeSight = require(Shared:WaitForChild("TreeSight"))

local Controller = {}

local G = HauntedTrees.gaze
local F = HauntedTrees.face
local PARTS = { "FaceRoot", "EyeL", "EyeR", "PupilL", "PupilR", "LidL", "LidR", "Jaw" }

type Eye = { pupil: BasePart, center: Vector3, orbit: number, lid: BasePart, lidRest: CFrame, lidTravel: number }

type Face = {
	model: Model,
	id: string,
	root: BasePart,
	eyes: { Eye },
	jaw: BasePart,
	jawRest: CFrame,
	jawTravel: number,
	rng: Random,
	-- animation (current and target)
	yaw: number,
	pitch: number,
	tYaw: number,
	tPitch: number,
	lid: number,
	mouth: number,
	nextBlink: number,
	blinkUntil: number,
	nextGlance: number,
	nextMouth: number,
	mouthUntil: number,
	mouthTarget: number,
	wasFrozen: boolean,
	wakeAt: number, -- when the current recovery began
	-- tracking cache
	target: Vector3?,
	nextSight: number,
	-- local gaze
	looking: boolean,
	lastReport: number,
	lookEnded: number,
}

local faces: { [Model]: Face } = {}
local mouthOverride: { [string]: number } = {}
local remote: RemoteEvent? = nil
local started = false
local nextCheck = 0
local testAim: Face? = nil -- Studio test camera: the face it last aimed at
local testForceAt = 0 -- Studio test: last forced report
local testReportAt = 0 -- Studio test: last client-view report

local function damp(cur: number, target: number, rate: number, dt: number): number
	return cur + (target - cur) * (1 - math.exp(-rate * dt))
end

local function between(rng: Random, range: { number }): number
	return rng:NextNumber(range[1], range[2])
end

local function faceGeom(f: Face): GazeRules.Face
	local cf = f.root.CFrame
	return { pos = cf.Position, forward = cf.LookVector, radius = (f.root:GetAttribute("Radius") :: number?) or 1 }
end

local function report(f: Face, looking: boolean)
	if remote then
		remote:FireServer(f.id, looking)
	end
	f.lastReport = os.clock()
end

local function setPose(f: Face)
	local cf = f.root.CFrame
	local cy, sy = math.cos(math.rad(f.yaw)), math.sin(math.rad(f.yaw))
	local cp, sp = math.cos(math.rad(f.pitch)), math.sin(math.rad(f.pitch))
	local dir = cf:VectorToWorldSpace(Vector3.new(sy * cp, sp, -cy * cp))
	for _, e in f.eyes do
		e.pupil.CFrame = CFrame.lookAt(e.center + dir * e.orbit, e.center + dir * (e.orbit + 1))
		e.lid.CFrame = e.lidRest * CFrame.new(0, -f.lid * e.lidTravel, 0)
	end
	f.jaw.CFrame = f.jawRest * CFrame.new(0, -f.mouth * f.jawTravel, 0)
end

local function add(model: Instance)
	if not model:IsA("Model") or faces[model] then
		return
	end
	task.spawn(function()
		for _, name in PARTS do
			if not model:WaitForChild(name, 10) then
				return
			end
		end
		if not model:IsDescendantOf(Workspace) or faces[model] then
			return
		end
		local root = model:FindFirstChild("FaceRoot") :: BasePart
		local function eye(tag: string): Eye
			local ball = model:FindFirstChild("Eye" .. tag) :: BasePart
			local pupil = model:FindFirstChild("Pupil" .. tag) :: BasePart
			local lid = model:FindFirstChild("Lid" .. tag) :: BasePart
			return {
				pupil = pupil,
				center = ball.Position,
				orbit = (pupil:GetAttribute("Orbit") :: number?) or (ball.Size.X * 0.36),
				lid = lid,
				lidRest = lid.CFrame,
				lidTravel = (lid:GetAttribute("Travel") :: number?) or (ball.Size.X * 0.78),
			}
		end
		local jaw = model:FindFirstChild("Jaw") :: BasePart
		local id = model:GetAttribute("TreeId")
		local now = os.clock()
		local rng = Random.new()
		faces[model] = {
			model = model,
			id = if typeof(id) == "string" then id else "",
			root = root,
			eyes = { eye("L"), eye("R") },
			jaw = jaw,
			jawRest = jaw.CFrame,
			jawTravel = (jaw:GetAttribute("Travel") :: number?) or 0.4,
			rng = rng,
			yaw = 0,
			pitch = 0,
			tYaw = 0,
			tPitch = 0,
			lid = 0,
			mouth = 0,
			nextBlink = now + between(rng, F.blinkEvery),
			blinkUntil = 0,
			nextGlance = now + between(rng, F.glanceEvery),
			nextMouth = now + between(rng, F.mouthEvery),
			mouthUntil = 0,
			mouthTarget = 0,
			wasFrozen = false,
			wakeAt = -math.huge,
			target = nil,
			nextSight = 0,
			looking = false,
			lastReport = 0,
			lookEnded = -math.huge,
		}
	end)
end

local function remove(model: Instance)
	local f = faces[model :: Model]
	if f then
		if f.looking then
			report(f, false)
		end
		faces[model :: Model] = nil
	end
end

-- The nearest visible character head in front of the face, refreshed a few times a second.
local function trackTarget(f: Face, now: number): Vector3?
	if now < f.nextSight then
		return f.target
	end
	f.nextSight = now + 0.25
	local geom = faceGeom(f)
	local best: Vector3?, bestD = nil, math.huge
	for _, p in Players:GetPlayers() do
		local char = p.Character
		local head = char and char:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			local d = (head.Position - geom.pos).Magnitude
			if d < bestD and GazeRules.inFront(head.Position, geom, F.trackRange, 85) then
				if TreeSight.clear(geom.pos, head.Position, { f.model, char :: Model }) then
					best, bestD = head.Position, d
				end
			end
		end
	end
	f.target = best
	return best
end

local function animate(f: Face, now: number, dt: number)
	local frozen = f.model:GetAttribute("Frozen") == true or f.looking or now - f.lookEnded < G.resumeDelay
	local lidT, mouthT, rate
	if frozen then
		f.tYaw, f.tPitch = 0, 0
		lidT, mouthT, rate = F.frozenLid, F.frozenMouth, F.settleRate
		f.wasFrozen = true
	else
		if f.wasFrozen then
			-- Waking: a small unsettling twitch first, then a slow blend back to normal speed.
			f.wasFrozen = false
			f.wakeAt = now
			f.tYaw = f.rng:NextNumber(-1, 1) * F.yawLimit * 0.6
			f.tPitch = f.rng:NextNumber(-0.3, 0.3) * F.pitchLimit
			f.mouthUntil, f.mouthTarget = now + 0.25, 0.18
			f.nextGlance = now + 0.5
			f.nextBlink = now + between(f.rng, F.blinkEvery)
		end
		local wake = math.clamp((now - f.wakeAt) / F.recoverSeconds, 0, 1)
		rate = if now - f.wakeAt < 0.2 then F.settleRate * 0.6 else 1.5 + (F.idleRate - 1.5) * wake
		local target = if now - f.wakeAt > 0.5 then trackTarget(f, now) else nil
		if target then
			local v = f.root.CFrame:VectorToObjectSpace(target - f.root.Position)
			f.tYaw = math.clamp(math.deg(math.atan2(v.X, -v.Z)), -F.yawLimit, F.yawLimit)
			f.tPitch =
				math.clamp(math.deg(math.atan2(v.Y, math.sqrt(v.X * v.X + v.Z * v.Z))), -F.pitchLimit, F.pitchLimit)
		elseif now >= f.nextGlance then
			f.nextGlance = now + between(f.rng, F.glanceEvery)
			if f.rng:NextNumber() < 0.3 then
				f.tYaw, f.tPitch = 0, 0
			else
				f.tYaw = f.rng:NextNumber(-0.7, 0.7) * F.yawLimit
				f.tPitch = f.rng:NextNumber(-0.5, 0.4) * F.pitchLimit
			end
		end
		if now >= f.nextBlink then
			f.blinkUntil = now + 0.14
			f.nextBlink = now + between(f.rng, F.blinkEvery)
		end
		lidT = if now < f.blinkUntil then 1 else 0.06
		if now >= f.nextMouth then
			f.nextMouth = now + between(f.rng, F.mouthEvery)
			f.mouthUntil, f.mouthTarget = now + f.rng:NextNumber(0.4, 1.1), f.rng:NextNumber(0.2, 0.6)
		end
		mouthT = mouthOverride[f.id] or (if now < f.mouthUntil then f.mouthTarget else F.restMouth)
	end
	f.yaw = damp(f.yaw, f.tYaw, rate, dt)
	f.pitch = damp(f.pitch, f.tPitch, rate, dt)
	f.lid = damp(f.lid, lidT, if not frozen and now < f.blinkUntil + 0.1 then 45 else rate, dt)
	f.mouth = damp(f.mouth, mouthT, rate, dt)
	setPose(f)
end

-- Local gaze: edges and keepalives only, never per frame.
local function checkGaze(now: number)
	local cam = Workspace.CurrentCamera
	local char = Players.LocalPlayer.Character
	local head = char and char:FindFirstChild("Head")
	local alive = char and char:FindFirstChildOfClass("Humanoid")
	local ok = cam ~= nil and head ~= nil and head:IsA("BasePart") and alive ~= nil and alive.Health > 0
	for _, f in faces do
		local looking = false
		if ok then
			local geom = faceGeom(f)
			local headPos = (head :: BasePart).Position
			if (headPos - geom.pos).Magnitude <= G.checkRadius then
				local view = { camPos = cam.CFrame.Position, camLook = cam.CFrame.LookVector, headPos = headPos }
				-- The server checks from the head, so require both: the looker then never sees a local-only
				-- freeze the server would reject (AUD-20261013-TASK-0041-01 finding 5).
				looking = GazeRules.qualifies(view, geom, f.looking)
					and TreeSight.clear(view.camPos, geom.pos, { f.model, char :: Model })
					and TreeSight.clear(headPos, geom.pos, { f.model, char :: Model })
			end
		end
		if looking ~= f.looking then
			f.looking = looking
			if not looking then
				f.lookEnded = now
			end
			report(f, looking)
		elseif looking and now - f.lastReport >= G.keepalive then
			report(f, true)
		end
	end
end

-- Studio-only test camera (TASK-0041 scenario): inert unless ReplicatedStorage has HC_GazeTest = true.
-- The scenario sets this player's HC_LookAt attribute to a tree id ("" looks away), and the real camera
-- is aimed so the real gaze test and remote are exercised.
local function testCamera()
	if not RunService:IsStudio() then
		return
	end
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end
	if ReplicatedStorage:GetAttribute("HC_GazeTest") ~= true then
		if cam.CameraType == Enum.CameraType.Scriptable and cam:GetAttribute("HC_Test") then
			cam.CameraType = Enum.CameraType.Custom
			cam:SetAttribute("HC_Test", nil)
		end
		return
	end
	local me = Players.LocalPlayer
	local char = me.Character
	local head = char and char:FindFirstChild("Head")
	local lookAt = me:GetAttribute("HC_LookAt")
	local id = if typeof(lookAt) == "string" then lookAt else ""
	-- "forge:<id>": send what an exploiter would, through the real remote, every frame.
	local forged = string.match(id, "^forge:(.+)$")
	if forged and remote then
		remote:FireServer(forged, true)
		remote:FireServer({}, true)
		remote:FireServer(forged, "yes")
		remote:FireServer(nil, nil)
		id = ""
	end
	-- "force:<id>": claim to be looking at that tree, whatever the camera shows, at the keepalive rate. Tests
	-- the server's own range, facing and line-of-sight checks (AUD-20261013-TASK-0041-01 finding 2).
	local forcedLook = string.match(id, "^force:(.+)$")
	if forcedLook then
		if remote and os.clock() - testForceAt >= G.keepalive then
			testForceAt = os.clock()
			remote:FireServer(forcedLook, true)
		end
		id = ""
	end
	-- What this client sees on the scenario's tree, sent back on a test-only remote the scenario creates
	-- (AUD-20261013-TASK-0041-01 finding 3).
	local reportTo = ReplicatedStorage:FindFirstChild("HC_TestReport")
	local reportTree = ReplicatedStorage:GetAttribute("HC_TestTree")
	if
		reportTo
		and reportTo:IsA("RemoteEvent")
		and typeof(reportTree) == "string"
		and os.clock() - testReportAt >= 0.1
	then
		testReportAt = os.clock()
		for _, f in faces do
			if f.id == reportTree then
				local e = f.eyes[1]
				local rest = e.center + f.root.CFrame.LookVector * e.orbit
				reportTo:FireServer(f.model:GetAttribute("Frozen") == true, (e.pupil.Position - rest).Magnitude)
			end
		end
	end
	if not (head and head:IsA("BasePart")) then
		return
	end
	local target: Face? = nil
	local nearest: Face?, nd = nil, math.huge
	for _, f in faces do
		local d = (f.root.Position - head.Position).Magnitude
		if f.id == id then
			target = f
		end
		if d < nd then
			nearest, nd = f, d
		end
	end
	cam.CameraType = Enum.CameraType.Scriptable
	cam:SetAttribute("HC_Test", true)
	if target then
		testAim = target
	end
	-- Looking away turns from the face it last aimed at (another tree may be nearer).
	local aim = target or (if testAim and faces[testAim.model] then testAim else nearest)
	if not aim then
		return
	end
	local toFace = (aim.root.Position - head.Position).Unit
	local camPos = head.Position + Vector3.new(0, 0.6, 0) - toFace * 1.2
	-- Aimed at the requested face, or directly away from the nearest one.
	cam.CFrame = if target then CFrame.lookAt(camPos, aim.root.Position) else CFrame.lookAt(camPos, camPos - toFace)
end

-- Future voice-synced mouth control: alpha in 0..1 drives the jaw while the face is unobserved; nil clears.
function Controller.setMouthOverride(id: string, alpha: number?)
	if alpha == nil then
		mouthOverride[id] = nil
	else
		mouthOverride[id] = math.clamp(alpha, 0, 1)
	end
end

function Controller.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		local remotes = ReplicatedStorage:WaitForChild("Remotes")
		remote = remotes:WaitForChild("TreeGaze") :: RemoteEvent
	end)
	CollectionService:GetInstanceAddedSignal(HauntedTrees.tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(HauntedTrees.tag):Connect(remove)
	for _, m in CollectionService:GetTagged(HauntedTrees.tag) do
		add(m)
	end
	local animRadius = G.checkRadius * 1.5
	RunService:BindToRenderStep("HauntedTrees", Enum.RenderPriority.Camera.Value + 1, function(dt: number)
		local now = os.clock()
		testCamera()
		if now >= nextCheck then
			nextCheck = now + 1 / G.checkHz
			checkGaze(now)
		end
		local cam = Workspace.CurrentCamera
		local camPos = if cam then cam.CFrame.Position else Vector3.zero
		for model, f in faces do
			if not model.Parent then
				faces[model] = nil
			elseif (f.root.Position - camPos).Magnitude <= animRadius then
				animate(f, now, dt)
			end
		end
	end)
end

return Controller
