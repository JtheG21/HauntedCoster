--!strict
-- Turns one HCM1 StringValue (ReplicatedStorage.Shared.ArtData/<asset>/<part>) into a MeshPart.
--   MeshBuild.bake(value)  -- server: EditableMesh -> DataModel-scoped content -> MeshPart that replicates to
--                             every client like a normal mesh, so clients never spend their EditableMesh budget.
--   MeshBuild.local_(value) -- fallback on either side: a MeshPart linked to a live EditableMesh.
-- Vertices are recentred on the bounding box (CreateMeshPartAsync keeps raw coordinates), so the part's
-- Position is the box centre (attribute CX/CY/CZ in asset space).

local AssetService = game:GetService("AssetService")

local MeshCodec = require(script.Parent.MeshCodec)

local MeshBuild = {}

local function editable(value: StringValue): (EditableMesh, number)
	local mesh = MeshCodec.decode(value.Value)
	local em = AssetService:CreateEditableMesh()
	if not em then
		error("EditableMesh budget exhausted")
	end
	local centre = mesh.centre
	local positions = table.create(#mesh.positions) :: { Vector3 }
	for i, p in mesh.positions do
		positions[i] = p - centre
	end
	local vIds = em:BatchAdd(Enum.MeshAttribute.Vertex, positions)
	local nIds = em:BatchAdd(Enum.MeshAttribute.Normal, mesh.normals)
	local cIds = em:BatchAdd(Enum.MeshAttribute.Color, mesh.colors, table.create(#mesh.colors, 1))
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
	return em, nf
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
	local result, content = AssetService:CreateDataModelContentAsync(Content.fromObject(em))
	if result ~= Enum.CreateContentResult.Success then
		em:Destroy()
		return nil, tostring(result)
	end
	local part = AssetService:CreateMeshPartAsync(content, OPTIONS)
	em:Destroy()
	return finish(part, value), nil
end

function MeshBuild.local_(value: StringValue): MeshPart
	local em, _ = editable(value)
	local part = AssetService:CreateMeshPartAsync(Content.fromObject(em), OPTIONS)
	return finish(part, value)
end

return MeshBuild
