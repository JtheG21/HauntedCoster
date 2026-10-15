--!strict
-- Builds client-side visuals from the server-baked art templates: ReplicatedStorage.ArtTemplates/<asset>/<part>
-- (server/Services/ArtBakeService bakes ServerStorage.ArtData, the HCM1 meshes exported by games/haunted/art).
-- Every use is a clone of the template, so copies share one mesh. Where the raw data is reachable (Studio Edit,
-- the command bar) a part can also be built locally from an EditableMesh. Art is presentation only: if a part
-- can't be had, `build` returns nil after one warning and the server's colliders keep gameplay working.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MeshBuild = require(Shared:WaitForChild("Art"):WaitForChild("MeshBuild"))

local ArtLoader = {}

export type PartSpec = {
	name: string, -- StringValue name, e.g. "Iron" or "Iron@lod1"
	part: string, -- logical part
	material: Enum.Material,
	alpha: number,
	lod: number,
	centre: Vector3,
	pivot: Vector3?,
	detail: boolean, -- small detail shown only at LOD0 distance
	value: Instance, -- baked template MeshPart, or the raw HCM1 StringValue (local builds)
}

export type Spec = {
	key: string,
	parts: { PartSpec },
	attrs: { [string]: any },
}

export type Built = {
	model: Model,
	parts: { [string]: { BasePart } }, -- logical part -> LOD0 (and shared) MeshParts
	lod1: { BasePart },
	lod0: { BasePart }, -- parts that have an LOD1 twin
	shared: { BasePart }, -- parts without one
}

export type Options = {
	castShadow: boolean?,
	tint: { [string]: Color3 }?, -- logical part -> colour multiplied with the vertex colours
	material: { [string]: Enum.Material }?,
	alpha: { [string]: number }?,
	lod: number?, -- force 0 or 1 (default: both built, Lod module switches)
}

local specs: { [string]: Spec | false } = {}
local templates: { [Instance]: MeshPart | false } = {}
local building: { [Instance]: boolean } = {}
local warned: { [string]: boolean } = {}
local stats = { meshes = 0, triangles = 0, failures = 0, buildSeconds = 0, localBuilds = 0 }

local function warnOnce(key: string, msg: string)
	if not warned[key] then
		warned[key] = true
		warn(`[ArtLoader] {msg}`)
	end
end

local function materialOf(name: any): Enum.Material
	local ok, m = pcall(function()
		return (Enum.Material :: any)[name]
	end)
	return if ok and m then m else Enum.Material.SmoothPlastic
end

-- The asset's folder: baked templates while the game runs; the raw data where it is reachable (Studio Edit).
local function source(key: string): Instance?
	if RunService:IsRunning() then
		local root = ReplicatedStorage:WaitForChild("ArtTemplates", 30)
		if not root then
			return nil
		end
		local deadline = os.clock() + 45
		while os.clock() < deadline do
			local folder = root:FindFirstChild(key)
			if folder and folder:GetAttribute("Ready") then
				return folder
			end
			if not folder and root:GetAttribute("Ready") then
				return nil
			end
			task.wait(0.1)
		end
		return nil
	end
	local data = ServerStorage:FindFirstChild("ArtData")
	return data and data:FindFirstChild(key)
end

function ArtLoader.spec(key: string): Spec?
	local cached = specs[key]
	if cached == false then
		return nil
	elseif cached then
		return cached :: Spec
	end
	local folder = source(key)
	if not folder then
		specs[key] = false
		warnOnce(key, `no art for "{key}"`)
		return nil
	end
	local parts: { PartSpec } = {}
	for _, v in folder:GetChildren() do
		if v:IsA("StringValue") or v:IsA("MeshPart") then
			local px, py, pz = v:GetAttribute("PX"), v:GetAttribute("PY"), v:GetAttribute("PZ")
			table.insert(
				parts,
				{
					name = v.Name,
					part = (v:GetAttribute("Part") :: string?) or v.Name,
					material = materialOf(v:GetAttribute("Material")),
					alpha = (v:GetAttribute("Alpha") :: number?) or 0,
					lod = (v:GetAttribute("Lod") :: number?) or 0,
					centre = Vector3.new(
						(v:GetAttribute("CX") :: number?) or 0,
						(v:GetAttribute("CY") :: number?) or 0,
						(v:GetAttribute("CZ") :: number?) or 0
					),
					pivot = if px then Vector3.new(px :: number, py :: number, pz :: number) else nil,
					detail = v:GetAttribute("Detail") == true,
					value = v :: Instance,
				} :: PartSpec
			)
		end
	end
	table.sort(parts, function(a, b)
		return a.name < b.name
	end)
	local s: Spec = { key = key, parts = parts, attrs = folder:GetAttributes() }
	specs[key] = s
	return s
end

local function buildTemplate(value: Instance): MeshPart?
	if value:IsA("MeshPart") then
		stats.meshes += 1
		stats.triangles += (value:GetAttribute("Tris") :: number?) or 0
		return value
	end
	local t0 = os.clock()
	stats.localBuilds += 1
	local part = MeshBuild.local_(value :: StringValue)
	stats.meshes += 1
	stats.triangles += (value:GetAttribute("Tris") :: number?) or 0
	stats.buildSeconds += os.clock() - t0
	return part
end

-- Yields the first time a part is requested (EditableMesh -> MeshPart is async); later calls are instant.
function ArtLoader.template(value: Instance): MeshPart?
	local cached = templates[value]
	if cached == false then
		return nil
	elseif cached then
		return cached :: MeshPart
	end
	while building[value] do
		task.wait()
	end
	local after = templates[value]
	if after == false then
		return nil
	elseif after then
		return after :: MeshPart
	end
	building[value] = true
	local ok, result = pcall(buildTemplate, value)
	building[value] = nil
	if ok and result then
		templates[value] = result
		return result
	end
	templates[value] = false
	stats.failures += 1
	warnOnce(value:GetFullName(), `could not build {value:GetFullName()}: {tostring(result)}`)
	return nil
end

function ArtLoader.preload(keys: { string })
	for _, key in keys do
		local s = ArtLoader.spec(key)
		if s then
			for _, p in s.parts do
				ArtLoader.template(p.value)
			end
		end
	end
end

-- Builds a Model whose pivot is the asset origin (base centre, front = -Z). Parts are anchored and
-- non-colliding; the caller pivots or welds it. Returns nil if any LOD0 part failed.
function ArtLoader.build(key: string, opts: Options?): Built?
	local s = ArtLoader.spec(key)
	if not s then
		return nil
	end
	local o: Options = opts or {}
	local model = Instance.new("Model")
	model.Name = key
	local built: Built = { model = model, parts = {}, lod1 = {}, lod0 = {}, shared = {} }
	local hasLod1: { [string]: boolean } = {}
	for _, p in s.parts do
		if p.lod == 1 then
			hasLod1[p.part] = true
		end
	end
	for _, p in s.parts do
		if o.lod ~= nil and hasLod1[p.part] and p.lod ~= o.lod then
			continue
		end
		local template = ArtLoader.template(p.value)
		if not template then
			if p.lod == 0 then
				model:Destroy()
				return nil
			end
			continue
		end
		local mp = template:Clone()
		mp.Name = p.name
		local yaw = mp:GetAttribute("ImportYaw")
		mp.CFrame = if type(yaw) == "number"
			then CFrame.new(p.centre) * CFrame.Angles(0, math.rad(yaw), 0)
			else CFrame.new(p.centre)
		mp.Material = if o.material and o.material[p.part] then o.material[p.part] else p.material
		mp.Transparency = if o.alpha and o.alpha[p.part] then o.alpha[p.part] else p.alpha
		if o.tint and o.tint[p.part] then
			mp.Color = o.tint[p.part]
		end
		mp.CastShadow = if o.castShadow == false then false else p.material ~= Enum.Material.Neon and p.alpha < 0.5
		mp:SetAttribute("ArtPart", p.part)
		if p.pivot then
			mp:SetAttribute("PivotX", p.pivot.X)
			mp:SetAttribute("PivotY", p.pivot.Y)
			mp:SetAttribute("PivotZ", p.pivot.Z)
		end
		mp.Parent = model
		if p.lod == 1 then
			table.insert(built.lod1, mp)
		else
			local list = built.parts[p.part]
			if not list then
				list = {}
				built.parts[p.part] = list
			end
			table.insert(list, mp)
			if (hasLod1[p.part] or p.detail) and o.lod == nil then
				table.insert(built.lod0, mp)
			else
				table.insert(built.shared, mp)
			end
		end
	end
	model.WorldPivot = CFrame.new()
	return built
end

function ArtLoader.stats(): { [string]: number }
	return table.clone(stats)
end

return ArtLoader
