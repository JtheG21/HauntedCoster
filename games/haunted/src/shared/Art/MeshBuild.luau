--!strict
-- Turns one HCM1 StringValue (ServerStorage.ArtData/<asset>/<part>) into a MeshPart.
--   MeshBuild.bake(value)  -- server: EditableMesh -> DataModel-scoped content -> MeshPart that replicates to
--                             every client like a normal mesh, so clients never spend their EditableMesh budget.
--   MeshBuild.local_(value) -- fallback on either side: a MeshPart linked to a live EditableMesh.
--   MeshBuild.imported(value) -- server: jg's Studio import of the same part (ServerStorage.ImportedArt/<asset>/<part>,
--                             a MeshPart with its SurfaceAppearance PBR maps), preferred over the HCM1 build when present.
-- Vertices are recentred on the bounding box (CreateMeshPartAsync keeps raw coordinates), so the part's
-- Position is the box centre (attribute CX/CY/CZ in asset space).

local AssetService = game:GetService("AssetService")

local MeshCodec = require(script.Parent.MeshCodec)

local MeshBuild = {}

local function fill(em: EditableMesh, mesh: MeshCodec.Mesh)
	local centre = mesh.centre
	local positions = table.create(#mesh.positions) :: { Vector3 }
	for i, p in mesh.positions do
		positions[i] = p - centre
	end
	local vIds = em:BatchAdd(Enum.MeshAttribute.Vertex, positions)
	local nIds = em:BatchAdd(Enum.MeshAttribute.Normal, mesh.normals)
	local cIds = (em :: any):BatchAdd(Enum.MeshAttribute.Color, mesh.colors, table.create(#mesh.colors, 1))
	local uIds = if mesh.uvs then em:BatchAdd(Enum.MeshAttribute.UV, mesh.uvs) else nil
	local nf = #mesh.faces
	local fv, fn, fc = table.create(nf), table.create(nf), table.create(nf)
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
end

local function editable(value: StringValue): (EditableMesh, number)
	local mesh = MeshCodec.decode(value.Value)
	task.wait() -- spread decode and build over frames so baking never stalls a server tick for long
	local em = AssetService:CreateEditableMesh()
	if not em then
		error("EditableMesh budget exhausted")
	end
	local ok, err = pcall(function()
		fill(em, mesh)
	end)
	if not ok then
		em:Destroy()
		error(err)
	end
	return em, #mesh.faces
end

local function finish(part: MeshPart, value: StringValue): MeshPart
	part.Name = value.Name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.Color = Color3.new(1, 1, 1)
	for k, v in value:GetAttributes() do
		part:SetAttribute(k, v)
	end
	return part
end

local OPTIONS = { CollisionFidelity = Enum.CollisionFidelity.Box, RenderFidelity = Enum.RenderFidelity.Precise }

function MeshBuild.bake(value: StringValue): (MeshPart?, string?)
	local em, _ = editable(value)
	local ok, result, part = pcall(function()
		local r, content = AssetService:CreateDataModelContentAsync(Content.fromObject(em))
		if r ~= Enum.CreateContentResult.Success then
			return r, nil
		end
		return r, AssetService:CreateMeshPartAsync(content, OPTIONS)
	end)
	em:Destroy() -- the baked content no longer needs it
	if not ok then
		return nil, tostring(result)
	elseif not part then
		return nil, tostring(result)
	end
	return finish(part, value), nil
end

-- The imported production mesh for this part, if the place has one. LOD1 twins ("@lod1") always come from HCM1.
-- An "ImportYaw" attribute on the asset folder (degrees) corrects an import that came in turned about Y.
function MeshBuild.imported(value: StringValue): MeshPart?
	local root = game:GetService("ServerStorage"):FindFirstChild("ImportedArt")
	local asset = root and value.Parent and root:FindFirstChild(value.Parent.Name)
	local src = asset and asset:FindFirstChild(value.Name)
	if not (src and src:IsA("MeshPart")) then
		return nil
	end
	local part = finish(src:Clone(), value)
	local yaw = asset and asset:GetAttribute("ImportYaw")
	if type(yaw) == "number" and yaw ~= 0 then
		part:SetAttribute("ImportYaw", yaw)
	end
	part:SetAttribute("Imported", true)
	return part
end

-- The returned part stays linked to its EditableMesh, which is kept alive by that link.
function MeshBuild.local_(value: StringValue): MeshPart
	local em, _ = editable(value)
	local ok, part = pcall(AssetService.CreateMeshPartAsync, AssetService, Content.fromObject(em), OPTIONS)
	if not ok then
		em:Destroy()
		error(part)
	end
	return finish(part, value)
end

return MeshBuild
