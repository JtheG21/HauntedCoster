--!strict
-- Bakes every client art part once per server (TASK-0042). Each HCM1 part in ReplicatedStorage.Shared.ArtData
-- becomes a template MeshPart in ReplicatedStorage.ArtTemplates/<asset>/<part> backed by DataModel-scoped
-- content, which replicates like a normal mesh; clients clone templates (client/Art/ArtLoader) instead of
-- building EditableMeshes against their small per-device budget. Presentation only: a failed bake leaves the
-- asset to the client's local fallback, and gameplay never waits on art.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MeshBuild = require(ReplicatedStorage.Shared.Art.MeshBuild)

local ArtBakeService = {}

local CONCURRENCY = 6
local started = false
local stats = { parts = 0, failed = 0, seconds = 0 }

-- Assets everyone sees first bake first; everything else follows in name order.
local FIRST =
	{ "lamp_post", "creature_wisp", "creature_hound", "creature_gentleman", "creature_bellwraith", "capture_jar" }

function ArtBakeService.start()
	if started then
		return
	end
	started = true
	local data = ReplicatedStorage.Shared:WaitForChild("ArtData")
	local root = Instance.new("Folder")
	root.Name = "ArtTemplates"
	root.Parent = ReplicatedStorage
	local order: { Instance } = {}
	for _, name in FIRST do
		local f = data:FindFirstChild(name)
		if f then
			table.insert(order, f)
		end
	end
	local rest = data:GetChildren()
	table.sort(rest, function(a, b)
		return a.Name < b.Name
	end)
	for _, f in rest do
		if not table.find(order, f) then
			table.insert(order, f)
		end
	end
	local queue: { { folder: Folder, value: StringValue } } = {}
	for _, assetFolder in order do
		local out = Instance.new("Folder")
		out.Name = assetFolder.Name
		for k, v in assetFolder:GetAttributes() do
			out:SetAttribute(k, v)
		end
		out.Parent = root
		for _, v in assetFolder:GetChildren() do
			if v:IsA("StringValue") then
				table.insert(queue, { folder = out, value = v })
			end
		end
	end
	local t0 = os.clock()
	local active = 0
	local pending: { [Folder]: number } = {}
	for _, job in queue do
		pending[job.folder] = (pending[job.folder] or 0) + 1
	end
	task.spawn(function()
		for _, job in queue do
			while active >= CONCURRENCY do
				task.wait()
			end
			active += 1
			task.spawn(function()
				local ok, part, err = pcall(MeshBuild.bake, job.value)
				if ok and part then
					part.Parent = job.folder
					stats.parts += 1
				else
					stats.failed += 1
					warn(`[ArtBake] {job.value:GetFullName()}: {if ok then err else part}`)
				end
				pending[job.folder] -= 1
				if pending[job.folder] == 0 then
					job.folder:SetAttribute("Ready", true)
				end
				active -= 1
			end)
		end
		while active > 0 do
			task.wait()
		end
		stats.seconds = os.clock() - t0
		root:SetAttribute("Ready", true)
		print(`[ArtBake] {stats.parts} parts baked, {stats.failed} failed, {string.format("%.1f", stats.seconds)} s`)
	end)
end

function ArtBakeService.stats(): { [string]: number }
	return table.clone(stats)
end

return ArtBakeService
