--!strict
-- Two-player haunted-tree gaze scenario (TASK-0041 AC3, AC4, AC6, AC7). Both REAL client cameras are aimed
-- by the Studio-only test camera in client/HauntedTrees (armed by ReplicatedStorage.HC_GazeTest, steered by
-- each player's HC_LookAt attribute), so the real gaze test, TreeGaze remote and server checks run.
--   game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(2, { scenario = "HauntedTrees", habitat = "Woodland" })

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local HauntedTrees = require(ReplicatedStorage.Shared.Config.HauntedTrees)
local TreeSight = require(ReplicatedStorage.Shared.TreeSight)
local Services = ServerScriptService:WaitForChild("Server"):WaitForChild("Services")
local HauntedTreeService = require(Services.HauntedTreeService) :: any
local CaptureService = require(Services.CaptureService) :: any

return function(args: any): { [string]: any }
	local checks: { { name: string, ok: boolean, detail: string? } } = {}
	local function check(name: string, ok: boolean, detail: any?)
		table.insert(checks, { name = name, ok = ok == true, detail = if detail ~= nil then tostring(detail) else nil })
	end
	local stats: { [string]: any } = {}
	local function finish(infra: boolean?)
		ReplicatedStorage:SetAttribute("HC_GazeTest", nil)
		local failed = 0
		for _, c in checks do
			if not c.ok then
				failed += 1
			end
		end
		return {
			ok = failed == 0 and not infra,
			passed = #checks - failed,
			failed = failed,
			checks = checks,
			stats = stats,
			infra = infra,
		}
	end

	local timeout = (type(args) == "table" and args.timeout) or 90
	local t0 = os.clock()
	while #Players:GetPlayers() < 2 and os.clock() - t0 < timeout do
		task.wait(0.5)
	end
	local list = Players:GetPlayers()
	check("two players joined", #list >= 2, #list)
	if #list < 2 then
		return finish(true)
	end
	local a, b = list[1], list[2]
	for _, p in { a, b } do
		if not p.Character then
			p.CharacterAdded:Wait()
		end
	end
	task.wait(3)

	-- Inventory and per-tree counts (AC1 / AC8 evidence).
	local all, faced = 0, 0
	local parts, archetypes, palettes = 0, {}, {}
	local folder = Workspace:FindFirstChild("HauntedTrees", true)
	if folder then
		for _, m in folder:GetChildren() do
			if m:IsA("Model") then
				all += 1
				local n = 0
				for _, d in m:GetDescendants() do
					if d:IsA("BasePart") then
						n += 1
					end
				end
				parts += n
				local arch = m:GetAttribute("Archetype") :: string
				archetypes[arch] = (archetypes[arch] or 0) + 1
				if CollectionService:HasTag(m, HauntedTrees.tag) then
					faced += 1
					local pal = m:GetAttribute("Palette") :: string
					palettes[pal] = (palettes[pal] or 0) + 1
				end
			end
		end
	end
	stats.trees, stats.faced, stats.parts = all, faced, parts
	stats.archetypes, stats.palettes = archetypes, palettes
	check(
		"woodland has haunted trees, about half with faces",
		all >= 10 and math.abs(faced - all / 2) <= 1,
		`{faced}/{all}`
	)
	local nArch = 0
	for _ in archetypes do
		nArch += 1
	end
	check("all three archetypes placed", nArch == 3, nArch)

	-- Pick a faced tree with clear standing room 7 studs in front of its face.
	local tree: Model?, root: BasePart?, spot: Vector3?
	local far: Model? = nil
	for _, m in CollectionService:GetTagged(HauntedTrees.tag) do
		if m:IsDescendantOf(Workspace) and m:IsA("Model") then
			local r = m:FindFirstChild("FaceRoot") :: BasePart
			local stand = r.Position + r.CFrame.LookVector * 7
			local ground = Vector3.new(stand.X, 0, stand.Z)
			if not tree and TreeSight.clear(ground + Vector3.new(0, 4.5, 0), r.Position, { m }) then
				tree, root, spot = m, r, ground
			elseif tree and root and (r.Position - root.Position).Magnitude > 50 then
				far = m
			end
		end
	end
	check("found a faced tree with standing room", tree ~= nil)
	if not (tree and root and spot) then
		return finish()
	end
	local id = tree:GetAttribute("TreeId") :: string
	stats.tree = id
	local right = root.CFrame.RightVector

	local function tp(p: Player, pos: Vector3)
		(p.Character :: Model):PivotTo(
			CFrame.lookAt(pos + Vector3.new(0, 3, 0), Vector3.new(root.Position.X, pos.Y + 3, root.Position.Z))
		)
		CaptureService.noteTeleport(p)
	end
	local function look(p: Player, target: string)
		p:SetAttribute("HC_LookAt", target)
	end
	local function frozen(): boolean
		return tree:GetAttribute("Frozen") == true
	end
	local function snap(): any
		return HauntedTreeService.snapshot(id)
	end
	-- Waits up to `secs` for `cond`; returns whether it held.
	local function within(secs: number, cond: () -> boolean): boolean
		local t = os.clock()
		while os.clock() - t < secs do
			if cond() then
				return true
			end
			task.wait(0.05)
		end
		return cond()
	end
	local function holds(secs: number, cond: () -> boolean): boolean
		local t = os.clock()
		while os.clock() - t < secs do
			if not cond() then
				return false
			end
			task.wait(0.05)
		end
		return true
	end
	local function unfrozenTime(): number
		local t = os.clock()
		while frozen() and os.clock() - t < 5 do
			task.wait(0.02)
		end
		return os.clock() - t
	end

	look(a, "")
	look(b, "")
	tp(a, spot - right * 1.5)
	tp(b, spot + right * 1.5)
	ReplicatedStorage:SetAttribute("HC_GazeTest", true)
	task.wait(2.5)
	check("starts unfrozen with both looking away", not frozen(), snap() and snap().observers)

	-- AC6: A looks -> frozen for everyone (one server attribute).
	look(a, id)
	check("A looks: frozen", within(1.5, frozen))
	check(
		"A looks: one observer",
		within(1, function()
			return snap().observers == 1
		end),
		snap().observers
	)
	-- B joins; A looks away; B keeps it frozen.
	look(b, id)
	check(
		"B looks too: two observers",
		within(1.5, function()
			return snap().observers == 2
		end),
		snap().observers
	)
	look(a, "")
	check("A away, B still looking: stays frozen for 2 s", holds(2, frozen))
	check("A away: one observer left", snap().observers == 1, snap().observers)
	-- Both away: resume after about one second (the server step plus replication).
	look(b, "")
	local t = unfrozenTime()
	stats.resumeAfterBothAway = math.floor(t * 100) / 100
	check("both away: resumes after the 1 s delay (0.9-2.2 s incl. report latency)", t >= 0.9 and t <= 2.2, t)

	-- Reacquire during the delay cancels it.
	look(a, id)
	within(1.5, frozen)
	look(a, "")
	task.wait(0.6)
	look(b, id)
	task.wait(0.5)
	look(b, "")
	check("look during the delay: still frozen 0.7 s after the new release", holds(0.7, frozen))
	t = unfrozenTime()
	check("then resumes", not frozen(), t)

	-- Character reset clears A's observation at once.
	look(a, id)
	within(1.5, frozen)
	a:LoadCharacter()
	check(
		"reset: observer cleared",
		within(1, function()
			return snap().observers == 0
		end),
		snap().observers
	)
	check(
		"reset: resumes",
		within(3, function()
			return not frozen()
		end)
	)
	look(a, "")
	a.CharacterAdded:Wait()
	task.wait(1.5)
	tp(a, spot - right * 1.5)
	task.wait(1)

	-- Rapid toggling leaves at most the real observers and a clean resume.
	for i = 1, 30 do
		look(a, if i % 2 == 1 then id else "")
		task.wait(0.1)
	end
	look(a, "")
	check(
		"rapid toggling: resumes cleanly",
		within(4, function()
			return not frozen() and snap().observers == 0
		end),
		snap().observers
	)

	-- AC3: an opaque wall between A and the face blocks eye contact.
	local wall = Instance.new("Part")
	wall.Anchored = true
	wall.Size = Vector3.new(8, 10, 0.5)
	wall.CFrame = CFrame.lookAt(root.Position + root.CFrame.LookVector * 3.5, root.Position)
	wall.Parent = Workspace
	task.wait(0.3)
	look(a, id)
	check(
		"blocked face: no freeze",
		holds(1.5, function()
			return not frozen()
		end)
	)
	look(a, "")
	wall:Destroy()

	-- Out of range: 20 studs away, looking straight at it.
	tp(a, Vector3.new(root.Position.X, 0, root.Position.Z) + root.CFrame.LookVector * 20)
	task.wait(0.8)
	look(a, id)
	check(
		"out of range (20 studs): no freeze",
		holds(1.5, function()
			return not frozen()
		end)
	)
	look(a, "")

	-- AC7: forged reports (a far tree's id, malformed arguments, every frame) through the real remote.
	if far then
		local farId = far:GetAttribute("TreeId") :: string
		look(a, "forge:" .. farId)
		check(
			"forged far-tree reports: far tree never freezes",
			holds(2, function()
				return far:GetAttribute("Frozen") == false
			end)
		)
		look(a, "")
		check("forged reports left no observer", HauntedTreeService.snapshot(farId).observers == 0)
	else
		check("found a far tree for the forged-report check", false)
	end

	ReplicatedStorage:SetAttribute("HC_GazeTest", nil)
	return finish()
end
