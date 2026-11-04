--!strict
-- Hub route walkability gate (TASK-0136). Studio only; never part of check.sh. Run in a fresh Play session on the CLIENT, after
-- scripts/studio-preflight.sh --game mathshow and with the BuildStamp confirmed in Edit:
--   require(game.Players.LocalPlayer.PlayerScripts.StudioTests.HubRoutes).run()          all six routes + the canary
--   require(game.Players.LocalPlayer.PlayerScripts.StudioTests.HubRoutes).run({ only = "Daily" })   one route (+ canary unless noCanary)
-- Engine behaviour, not geometry: the local character, with jumping disabled, is put at the plaza spawn and driven with
-- Humanoid:MoveTo along each polyline of Hub.routes.json (HubRoutesData is that file, symlinked: one source) to its pad. A route
-- PASSES when the character ends within ARRIVE_STUDS of the pad centre, never jumped, AND the pad's ModePadOpen screen fired.
-- The canary walks to a point inside a sealed box built in memory for the test; it must NOT arrive, or the gate itself fails.
-- Prints the BuildStamp, one row per route and a last line HUBROUTES_RESULT. Walking takes about 12 s per route.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ModePadRules = require(Shared:WaitForChild("ModePadRules"))
local Routes = require(script.Parent:WaitForChild("HubRoutesData")) :: any

local SPAWN = Vector3.new(0, 4, 47) -- plaza, on the floor; same start as the TASK-0136 evidence runs
local ARRIVE_STUDS = 1.0 -- final distance to the pad centre, horizontal
local WAYPOINT_STUDS = 2.0 -- intermediate polyline points
local ROUTE_TIMEOUT = 30 -- seconds per real route
local CANARY_TIMEOUT = 10 -- the canary only has to fail; a legitimate walk takes about 12 s
local REISSUE = 0.2 -- MoveTo is re-issued this often so it never times out (it gives up after 8 s)
local SCREEN_WAIT = 3 -- seconds after arriving for the pad's screen (the server polls every 0.25 s)

local HubRoutes = {}

export type Row = {
	name: string,
	arrived: boolean,
	seconds: number,
	distance: number,
	jumps: number,
	screen: string,
	want: string,
	canary: boolean,
	pass: boolean,
}

local function buildStamp(): string
	local value = Shared:FindFirstChild("BuildStamp")
	return if value and value:IsA("StringValue") then value.Value else "MISSING"
end

local function horizontal(a: Vector3, b: Vector3): number
	return Vector3.new(a.X - b.X, 0, a.Z - b.Z).Magnitude
end

-- Four walls and a roof around a pad-sized spot on the plaza, no gap anywhere. Returns the spot and the folder to destroy.
local function buildSealedBox(): (Vector3, Folder)
	local folder = Instance.new("Folder")
	folder.Name = "HubRoutesCanary"
	local cx, cz = 30, 20
	local hit = Workspace:Raycast(Vector3.new(cx, 60, cz), Vector3.new(0, -120, 0))
	local floorY = if hit then hit.Position.Y else 0
	local function wall(name: string, centre: Vector3, size: Vector3)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = true
		part.Size = size
		part.Position = centre
		part.Transparency = 0.6
		part.Parent = folder
	end
	local half, height, thick = 8, 14, 2
	for _, dir in { { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } } do
		local alongX = dir[1] == 0
		wall(
			"CanaryWall",
			Vector3.new(cx + dir[1] * (half + thick / 2), floorY + height / 2, cz + dir[2] * (half + thick / 2)),
			Vector3.new(
				if alongX then 2 * (half + thick) else thick,
				height,
				if alongX then thick else 2 * (half + thick)
			)
		)
	end
	wall(
		"CanaryRoof",
		Vector3.new(cx, floorY + height + thick / 2, cz),
		Vector3.new(2 * (half + thick), thick, 2 * (half + thick))
	)
	folder.Parent = Workspace
	return Vector3.new(cx, floorY + 3, cz), folder
end

local function walk(
	character: Model,
	humanoid: Humanoid,
	waypoints: { Vector3 },
	target: Vector3,
	timeout: number
): (boolean, number, number)
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local started = os.clock()
	local index = 1
	while os.clock() - started < timeout do
		local goal = waypoints[index]
		local final = index == #waypoints
		humanoid:MoveTo(goal)
		task.wait(REISSUE)
		local d = horizontal(root.Position, goal)
		if final then
			if horizontal(root.Position, target) <= ARRIVE_STUDS then
				return true, os.clock() - started, horizontal(root.Position, target)
			end
		elseif d <= WAYPOINT_STUDS then
			index += 1
		end
	end
	return false, os.clock() - started, horizontal(root.Position, target)
end

function HubRoutes.run(opts: { only: string?, noCanary: boolean? }?): ({ Row }, number)
	if not RunService:IsStudio() then
		return {}, 0
	end
	local only = if opts then opts.only else nil
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local hub = Workspace:WaitForChild("Hub")

	-- No jumping at all: every way a Humanoid can leave the ground is off, and any jump that happens anyway is counted.
	humanoid.UseJumpPower = true
	humanoid.JumpPower = 0
	humanoid.JumpHeight = 0
	humanoid.AutoJumpEnabled = false
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
	local jumps = 0
	humanoid.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			jumps += 1
		end
	end)

	local screens: { string } = {}
	local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("ModePadOpen") :: RemoteEvent
	remote.OnClientEvent:Connect(function(payload: any)
		if typeof(payload) == "table" and typeof(payload.screen) == "string" then
			table.insert(screens, payload.screen)
		end
	end)

	local rows: { Row } = {}
	local failures = 0
	print(`[HubRoutes] BuildStamp {buildStamp()}`)
	print("[HubRoutes] route | arrived | seconds | final distance | jumps | screen (want) | result")

	local function runRoute(name: string, waypoints: { Vector3 }, target: Vector3, want: string, canary: boolean)
		root.AssemblyLinearVelocity = Vector3.zero
		character:PivotTo(CFrame.new(SPAWN))
		task.wait(0.5)
		table.clear(screens)
		jumps = 0
		local arrived, seconds, distance =
			walk(character, humanoid, waypoints, target, if canary then CANARY_TIMEOUT else ROUTE_TIMEOUT)
		local screen = ""
		if arrived and not canary then
			local waited = os.clock()
			while #screens == 0 and os.clock() - waited < SCREEN_WAIT do
				task.wait(0.1)
			end
			screen = table.concat(screens, ",")
		end
		local row: Row = {
			name = name,
			arrived = arrived,
			seconds = seconds,
			distance = distance,
			jumps = jumps,
			screen = screen,
			want = want,
			canary = canary,
			pass = if canary then not arrived else (arrived and jumps == 0 and screen == want),
		}
		table.insert(rows, row)
		if not row.pass then
			failures += 1
		end
		print(
			string.format(
				"[HubRoutes] %s | arrived=%s | %.1fs | dist=%.2f | jumps=%d | %s (%s) | %s",
				name,
				if arrived then "y" else "n",
				seconds,
				distance,
				jumps,
				if screen == "" then "none" else screen,
				want,
				if canary
					then (if row.pass then "CANARY BLOCKED (gate works)" else "CANARY ARRIVED (gate broken)")
					elseif row.pass then "PASS"
					else "FAIL"
			)
		)
	end

	for _, route in Routes.routes do
		if only ~= nil and route.mode ~= only then
			continue
		end
		local pad = hub:FindFirstChild("Pad_" .. route.mode, true) :: BasePart?
		if not pad then
			failures += 1
			print(`[HubRoutes] {route.mode} | Pad_{route.mode} not found | FAIL`)
			continue
		end
		local want = ModePadRules.screenFor(pad:GetAttribute("Mode")) or "?"
		local waypoints: { Vector3 } = {}
		for _, p in route.points do
			table.insert(waypoints, Vector3.new(p[1], SPAWN.Y, p[2]))
		end
		waypoints[#waypoints] = pad.Position -- the last polyline point is the pad centre; use the part itself
		runRoute(route.mode, waypoints, pad.Position, want, false)
	end

	if not (opts and opts.noCanary) then
		local spot, folder = buildSealedBox()
		local ok, err = pcall(function()
			runRoute("CANARY", { Vector3.new(spot.X, SPAWN.Y, SPAWN.Z), spot }, spot, "", true)
		end)
		folder:Destroy()
		if not ok then
			failures += 1
			warn(`[HubRoutes] canary errored: {err}`)
		end
	end

	local passed = 0
	for _, row in rows do
		if row.pass and not row.canary then
			passed += 1
		end
	end
	print(
		`HUBROUTES_RESULT routes={passed}/{if only then 1 else #Routes.routes} failures={failures} stamp={buildStamp()}`
	)
	return rows, failures
end

return HubRoutes
