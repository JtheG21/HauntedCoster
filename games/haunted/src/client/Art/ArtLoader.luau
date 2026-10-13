--!strict
-- Builds client-side visuals from ReplicatedStorage.Shared.ArtData (HCM1 meshes exported by
-- games/haunted/art). Each part is decoded once into an EditableMesh, turned into one template MeshPart
-- and cloned for every use, so all copies share one mesh (multi-reference). Art is presentation only:
-- if a mesh can't be built (memory budget, or EditableMesh disabled in a live game), `build` returns
-- nil after one warning and the server's colliders keep gameplay working.

local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MeshCodec = require(Shared:WaitForChild("Art"):WaitForChild("MeshCodec"))
local ArtData = Shared:WaitForChild("ArtData")

local ArtLoader = {}

export type PartSpec = {
	name: string, -- StringValue name, e.g. "Iron" or "Iron@lod1"
	part: string, -- logical part
	material: Enum.Material,
	alpha: number,
	lod: number,
	centre: Vector3,
	pivot: Vector3?,
	value: StringValue,
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
local templates: { [StringValue]: MeshPart | false } = {}
local building: { [StringValue]: boolean } = {}
local warned: { [string]: boolean } = {}
local stats = { meshes = 0, triangles = 0, failures = 0, buildSeconds = 0 }

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

function ArtLoader.spec(key: string): Spec?
	local cached = specs[key]
	if cached == false then
		return nil
	elseif cached then
		return cached :: Spec
	end
	local folder = ArtData:FindFirstChild(key)
	if not folder then
		specs[key] = false
		warnOnce(key, `no art data for "{key}"`)
		return nil
	end
	local parts: { PartSpec } = {}
	for _, v in folder:GetChildren() do
		if v:IsA("StringValue") then
			local px, py, pz = v:GetAttribute("PX"), v:GetAttribute("PY"), v:GetAttribute("PZ")
			table.insert(parts, {
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
				value = v,
			})
		end
	end
	table.sort(parts, function(a, b)
		return a.name < b.name
	end)
	local s: Spec = { key = key, parts = parts, attrs = folder:GetAttributes() }
	specs[key] = s
	return s
end

local function buildTemplate(value: StringValue): MeshPart?
	local t0 = os.clock()
	local mesh = MeshCodec.decode(value.Value)
	local em = AssetService:CreateEditableMesh()
	-- CreateMeshPartAsync keeps raw vertex coordinates, so centre them on the bounding box: the part's
	-- Position is then the box centre and culling/bounds match what renders.
	local centre = mesh.centre
	local local_ = table.create(#mesh.positions) :: { Vector3 }
	for i, p in mesh.positions do
		local_[i] = p - centre
	end
	local vIds = em:BatchAdd(Enum.MeshAttribute.Vertex, local_)
	local nIds = em:BatchAdd(Enum.MeshAttribute.Normal, mesh.normals)
	local alphas = table.create(#mesh.colors, 1)
	local cIds = em:BatchAdd(Enum.MeshAttribute.Color, mesh.colors, alphas)
	local uIds = if mesh.uvs then em:BatchAdd(Enum.MeshAttribute.UV, mesh.uvs) else nil
	local nf = #mesh.faces
	local fv = table.create(nf)
	local fn = table.create(nf)
	local fc = table.create(nf)
	local fu = if uIds then table.create(nf) else nil
	for i, f in mesh.faces do
		local a, b, c = f[1], f[2], f[3]
		fv[i] = { vIds[a], vIds[b], vIds[c] }
		fn[i] = { nIds[a], nIds[b], nIds[c] }
		fc[i] = { cIds[a], cIds[b], cIds[c] }
		if fu and uIds then
			fu[i] = { uIds[a], uIds[b], uIds[c] }
		end
	end
	local faceIds = em:BatchAdd(Enum.MeshAttribute.Face, fv)
	em:BatchSetFaceAttributes(faceIds, fn)
	em:BatchSetFaceAttributes(faceIds, fc)
	if fu then
		em:BatchSetFaceAttributes(faceIds, fu)
	end
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em), {
		CollisionFidelity = Enum.CollisionFidelity.Box,
		RenderFidelity = Enum.RenderFidelity.Precise,
	})
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Color = Color3.new(1, 1, 1)
	stats.meshes += 1
	stats.triangles += nf
	stats.buildSeconds += os.clock() - t0
	return part
end

-- Yields the first time a part is requested (EditableMesh -> MeshPart is async); later calls are instant.
function ArtLoader.template(value: StringValue): MeshPart?
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
		mp.CFrame = CFrame.new(p.centre)
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
			if hasLod1[p.part] and o.lod == nil then
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
