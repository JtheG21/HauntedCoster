--!strict
-- Map reachability proof on the built world, using the engine's own pathfinder (TASK-0012 AC1, TASK-0026 AC6):
--  * every hub gate, open zone and landmark of the active habitat is reachable on foot from home,
--  * every plot reaches the habitat, and the hub wall blocks between gates,
--  * the Sealed Crypt interior is NOT reachable while its gate is closed (checked again with it open),
--  * a real walk (Humanoid:MoveTo along the path) from home reaches the Weeping Angel, and
--  * the longest walk home (habitat zone -> pen) is measured and reported for tuning.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "Reachability" })

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)
local Habitats = require(ReplicatedStorage.Shared.Config.Habitats)
local EconomyRules = require(ReplicatedStorage.Shared.Rules.EconomyRules)

return function(_args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local root = character:WaitForChild("HumanoidRootPart") :: BasePart
	local t0 = os.clock()
	while not Workspace:FindFirstChild("Habitat") and os.clock() - t0 < 10 do
		task.wait(0.2)
	end
	task.wait(2)

	local plotIndex = player:GetAttribute("PlotIndex")
	while type(plotIndex) ~= "number" and os.clock() - t0 < 20 do
		task.wait(0.2)
		plotIndex = player:GetAttribute("PlotIndex")
	end
	local myPlot: number = if type(plotIndex) == "number" then plotIndex else 1
	local home = World.plotToWorld(myPlot, World.Plot.spawn)
	local habitat = Habitats.active()

	local function newPath(): Path
		return PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 6,
		})
	end
	local function pathLength(path: Path): number
		local wps = path:GetWaypoints()
		local len = 0
		for i = 2, #wps do
			len += (wps[i].Position - wps[i - 1].Position).Magnitude
		end
		return len
	end
	-- Path from `from` to `target` or a few nearby points (targets can sit inside a tombstone or statue).
	local function route(from: Vector3, target: Vector3): (boolean, string, Path?)
		local offsets = {
			Vector3.zero,
			Vector3.new(6, 0, 0),
			Vector3.new(-6, 0, 0),
			Vector3.new(0, 0, 6),
			Vector3.new(0, 0, -6),
			Vector3.new(8, 0, 8),
		}
		local last = "?"
		for _, off in offsets do
			local path = newPath()
			local ok = pcall(function()
				path:ComputeAsync(from, target + off + Vector3.new(0, 3, 0))
			end)
			last = if ok then tostring(path.Status) else "error"
			if ok and path.Status == Enum.PathStatus.Success then
				return true, last, path
			end
		end
		return false, last, nil
	end
	local function reach(target: Vector3): (boolean, string)
		local ok, status = route(home, target)
		return ok, status
	end

	-- Gates, zones, landmarks of the active habitat
	for g = 1, #World.Hub.gateAngles do
		local ok, status = reach(World.gatePoint(g, World.Hub.moduleRadius - 8))
		check(`hub gate {g} reachable from home`, ok, status)
	end
	for _, lm in habitat.landmarks do
		local ok, status = reach(lm.position + Vector3.new(0, 0, 7))
		check(`landmark reachable on foot: {lm.name}`, ok, status)
	end
	for _, zone in habitat.zones do
		local r = zone.rect
		local ok, status = reach(Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2))
		if zone.gated then
			check(`gated zone NOT reachable while sealed: {zone.name}`, not ok, status)
		else
			check(`zone reachable on foot: {zone.name}`, ok, status)
		end
	end
	-- Every plot reaches the habitat's centre
	for i = 1, #World.PlotCenters do
		local ok, status = route(World.plotToWorld(i, World.Plot.spawn), World.Hub.center + Vector3.new(0, 0, 8))
		check(`plot {i} reaches the habitat`, ok, status)
	end
	-- The hub wall blocks between gates: from just outside to just inside the wall, half way between two
	-- gates, the way round (through a gate) is far longer than the 12 studs straight across.
	do
		local between = (World.Hub.gateAngles[1] + World.Hub.gateAngles[2]) / 2
		local outside = World.polar(between, World.Hub.wallRadius + 6)
		local inside = World.polar(between, World.Hub.wallRadius - 6)
		local ok, status, path = route(outside, inside)
		local len = if path then pathLength(path) else math.huge
		check("the hub wall blocks between gates", not ok or len > 60, `{status} length {math.floor(len)}`)
	end

	-- Positive control: with the crypt gate open (server-side, for this check only) the same query must
	-- succeed, so "not reachable" above comes from the gate, not from bad targets or geometry.
	local habitatFolder = Workspace:FindFirstChild("Habitat")
	local cryptGate = habitatFolder and habitatFolder:FindFirstChild("CryptGate", true) :: BasePart?
	check("crypt gate found for the positive control", cryptGate ~= nil)
	if cryptGate then
		local cryptCollide = cryptGate.CanCollide
		cryptGate.CanCollide = false
		-- Always restore the gate, even if a control errors.
		local ran, err = pcall(function()
			for _, zone in habitat.zones do
				if zone.gated then
					local r = zone.rect
					local centre = Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2)
					local ok, status = false, "?"
					local w0 = os.clock()
					-- Poll: the navmesh updates asynchronously after a collision change.
					repeat
						ok, status = reach(centre)
						if not ok then
							task.wait(0.5)
						end
					until ok or os.clock() - w0 > 8
					check(`gated zone reachable once open (control): {zone.name}`, ok, status)
				end
			end
		end)
		cryptGate.CanCollide = cryptCollide
		check("positive control ran without error", ran, err)
		task.wait(1)
	end

	-- Longest walk home: every open zone to every pen, at the slowest carry speed (TASK-0026 AC6).
	do
		local carry = EconomyRules.walkSpeed(0, true)
		local worst, worstAt = 0, "?"
		local perPlot: { string } = {}
		for i = 1, #World.PlotCenters do
			local plotWorst = 0
			for _, zone in habitat.zones do
				if not zone.gated then
					local r = zone.rect
					local from = Vector3.new((r.x1 + r.x2) / 2, 3, (r.z1 + r.z2) / 2)
					local ok, _, path = route(from, World.plotToWorld(i, World.Plot.pen))
					if ok and path then
						local len = pathLength(path)
						plotWorst = math.max(plotWorst, len)
						if len > worst then
							worst, worstAt = len, `{zone.name} -> plot {i}`
						end
					end
				end
			end
			table.insert(perPlot, `{i}:{math.floor(plotWorst)}`)
		end
		check(
			"walks home measured",
			worst > 0,
			string.format(
				"longest %d studs (%s), %.0f s at carry speed %.1f; per plot %s",
				worst,
				worstAt,
				worst / carry,
				carry,
				table.concat(perPlot, " ")
			)
		)
	end

	-- Real walk: home -> Weeping Angel along the computed path.
	character:PivotTo(CFrame.new(home + Vector3.new(0, 3, 0)))
	task.wait(1)
	local angelPos = (Habitats.landmarkById("Angel") :: any).position + Vector3.new(0, 0, 7)
	local walk = newPath()
	pcall(function()
		walk:ComputeAsync(root.Position, angelPos)
	end)
	local arrived = false
	local started = os.clock()
	if walk.Status == Enum.PathStatus.Success then
		humanoid.WalkSpeed = 32 -- speed up the walk; physics and collisions are unchanged
		-- Poll the distance to each waypoint (MoveToFinished can time out a stud short of a waypoint).
		for _, wp in walk:GetWaypoints() do
			if wp.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(wp.Position)
			local w0 = os.clock()
			while os.clock() - w0 < 3 do
				if Vector3.new(root.Position.X - wp.Position.X, 0, root.Position.Z - wp.Position.Z).Magnitude < 3 then
					break
				end
				task.wait(0.05)
			end
			if os.clock() - started > 90 then
				break
			end
		end
		arrived = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(angelPos.X, 0, angelPos.Z)).Magnitude
			< 12
	end
	check(
		"walked from home to the Weeping Angel",
		arrived,
		string.format("%.0fs, end %s", os.clock() - started, tostring(root.Position))
	)

	local failed = 0
	for _, c in checks do
		if not c.ok then
			failed += 1
		end
	end
	return { ok = failed == 0, passed = #checks - failed, failed = failed, checks = checks }
end
