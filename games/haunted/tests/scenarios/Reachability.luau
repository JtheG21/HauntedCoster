--!strict
-- Map reachability proof (TASK-0012 AC1), using the engine's own pathfinder on the built world:
--  * every landmark and every open zone is reachable on foot from a home plot,
--  * the Sealed Crypt interior is NOT reachable while its gate is closed (checked again with the gate open
--    as a control),
--  * the west shortcut by the Old Well is always open (ADR-0007), and
--  * a real walk (Humanoid:MoveTo along the path) from home reaches the Weeping Angel.
--   game:GetService("StudioTestService"):ExecutePlayModeAsync({ scenario = "Reachability" })

local PathfindingService = game:GetService("PathfindingService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local World = require(ReplicatedStorage.Shared.Config.World)

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
	while not Workspace:FindFirstChild("Graveyard") and os.clock() - t0 < 10 do
		task.wait(0.2)
	end
	task.wait(2)

	local plotIndex = player:GetAttribute("PlotIndex")
	while type(plotIndex) ~= "number" and os.clock() - t0 < 20 do
		task.wait(0.2)
		plotIndex = player:GetAttribute("PlotIndex")
	end
	local home = World.PlotCenters[if type(plotIndex) == "number" then plotIndex else 1] + World.Plot.spawn
	local function newPath(): Path
		return PathfindingService:CreatePath({
			AgentRadius = 2,
			AgentHeight = 5,
			AgentCanJump = true,
			WaypointSpacing = 6,
		})
	end
	-- Try the target and a few nearby points (targets can sit inside a tombstone or statue).
	local function reach(target: Vector3): (boolean, string)
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
				path:ComputeAsync(home, target + off + Vector3.new(0, 3, 0))
			end)
			last = if ok then tostring(path.Status) else "error"
			if ok and path.Status == Enum.PathStatus.Success then
				return true, last
			end
		end
		return false, last
	end

	for _, lm in World.Landmarks do
		local ok, status = reach(lm.position + Vector3.new(0, 0, 7))
		check(`landmark reachable on foot: {lm.name}`, ok, status)
	end
	for _, zone in World.Zones do
		local r = zone.rect
		local center = Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2)
		local ok, status = reach(center)
		if zone.gated then
			check(`gated zone NOT reachable while sealed: {zone.name}`, not ok, status)
		else
			check(`zone reachable on foot: {zone.name}`, ok, status)
		end
	end
	-- Shortcut: the west gap by the Old Well is open, so outside to inside is a short, direct path.
	local outside = World.Graveyard.shortcut + Vector3.new(-8, 3, 0)
	local inside = World.Graveyard.shortcut + Vector3.new(8, 3, 0)
	local p = newPath()
	pcall(function()
		p:ComputeAsync(outside, inside)
	end)
	local direct = p.Status == Enum.PathStatus.Success and #p:GetWaypoints() < 8
	check("west shortcut is open", direct, `{p.Status} waypoints={#p:GetWaypoints()}`)
	local graveyard = Workspace:FindFirstChild("Graveyard")
	check(
		"no overgrown shortcut gate is built",
		graveyard ~= nil and graveyard:FindFirstChild("OvergrownGate", true) == nil
	)

	-- Positive control: with the crypt gate open (server-side, for this check only) the same query must
	-- succeed, so the "not reachable" result above comes from the gate, not from bad targets or geometry.
	local cryptGate = graveyard and graveyard:FindFirstChild("CryptGate", true) :: BasePart?
	check("crypt gate found for the positive control", cryptGate ~= nil)
	if cryptGate then
		local cryptCollide = cryptGate.CanCollide
		cryptGate.CanCollide = false
		-- Always restore the gate, even if a control errors.
		local ran, err = pcall(function()
			-- Poll instead of a fixed wait: the navmesh updates asynchronously after a collision change.
			for _, zone in World.Zones do
				if zone.gated then
					local r = zone.rect
					local centre = Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2)
					local ok, status = false, "?"
					local w0 = os.clock()
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
		check("positive controls ran without error", ran, err)
		task.wait(1)
	end

	-- Real walk: home -> Weeping Angel along the computed path.
	character:PivotTo(CFrame.new(home + Vector3.new(0, 3, 0)))
	task.wait(1)
	local angel = (World.landmarkById("Angel") :: any).position + Vector3.new(0, 0, 7)
	local walk = newPath()
	pcall(function()
		walk:ComputeAsync(root.Position, angel)
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
		arrived = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(angel.X, 0, angel.Z)).Magnitude < 12
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
