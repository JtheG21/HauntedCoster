--!strict
-- Terrain presentation for the flat ground (TASK-0044). Ground discs and path strips (Props.disc, Build.strip)
-- are marked `Ground`; painting turns each into Roblox terrain of its material (grass blades, soft material
-- blends, cobbles, dirt) and hides the part, which keeps colliding, so walk heights are unchanged. Paint order
-- is by top height, so paths overwrite the ground they cross. Habitat modules repaint on activation.

local Workspace = game:GetService("Workspace")

local GroundPainter = {}

local DEPTH = 4 -- studs of terrain under each surface

-- Part materials that terrain can show; anything else stays a visible part.
local TERRAIN: { [Enum.Material]: boolean } = {
	[Enum.Material.Grass] = true,
	[Enum.Material.LeafyGrass] = true,
	[Enum.Material.Ground] = true,
	[Enum.Material.Mud] = true,
	[Enum.Material.Cobblestone] = true,
	[Enum.Material.Slate] = true,
	[Enum.Material.Rock] = true,
	[Enum.Material.Sand] = true,
	[Enum.Material.WoodPlanks] = true,
	[Enum.Material.Brick] = true,
	[Enum.Material.Concrete] = true,
	[Enum.Material.Basalt] = true,
	[Enum.Material.Limestone] = true,
	[Enum.Material.Pavement] = true,
	[Enum.Material.Asphalt] = true,
	[Enum.Material.Sandstone] = true,
	[Enum.Material.Salt] = true,
}

-- The night palette for terrain materials (art direction: moss, dirt and stone under indigo light).
local COLORS: { [Enum.Material]: Color3 } = {
	[Enum.Material.Grass] = Color3.fromRGB(58, 78, 50),
	[Enum.Material.LeafyGrass] = Color3.fromRGB(64, 84, 52),
	[Enum.Material.Ground] = Color3.fromRGB(88, 72, 58),
	[Enum.Material.Mud] = Color3.fromRGB(70, 58, 48),
	[Enum.Material.Cobblestone] = Color3.fromRGB(104, 100, 108),
	[Enum.Material.Slate] = Color3.fromRGB(96, 96, 104),
	[Enum.Material.Rock] = Color3.fromRGB(100, 98, 102),
	[Enum.Material.WoodPlanks] = Color3.fromRGB(96, 74, 56),
}

function GroundPainter.supported(material: Enum.Material): boolean
	return TERRAIN[material] == true
end

-- Marks a flat ground part (disc: a Cylinder lying flat; strip: a block) for painting.
function GroundPainter.mark(part: BasePart)
	if TERRAIN[part.Material] then
		part:SetAttribute("Ground", true)
	end
end

local function top(part: BasePart): number
	local up = part.CFrame:VectorToObjectSpace(Vector3.yAxis)
	local half = math.abs(up.X) * part.Size.X / 2 + math.abs(up.Y) * part.Size.Y / 2 + math.abs(up.Z) * part.Size.Z / 2
	return part.Position.Y + half
end

-- Smooth terrain draws a surface 2 studs above the top of a block fill and FillCylinder rounds up a whole voxel
-- (measured in Studio, 2026-10-13), so blocks fill to `surface - 2` and discs are written as voxels: a full
-- layer below and a top layer whose occupancy puts the surface exactly at `surface`.
local function fillBlock(terrain: Terrain, cf: CFrame, size: Vector2, surface: number, material: Enum.Material)
	local p = cf.Position
	local at = CFrame.new(p.X, surface - 2 - DEPTH / 2, p.Z) * cf.Rotation
	terrain:FillBlock(at, Vector3.new(size.X, DEPTH, size.Y), material)
end

local function fillDisc(terrain: Terrain, centre: Vector3, radius: number, surface: number, material: Enum.Material)
	-- Ground in this game tops out below y = 2 (two 4-stud voxel layers between y -8 and 0 carry it); anything
	-- higher would be silently capped, so say so (AUD-20261013-TASK-0044-01 finding 6).
	if surface > 2 then
		warn(`[GroundPainter] disc surface {surface} above 2 is capped`)
	end
	local region = Region3.new(
		Vector3.new(centre.X - radius, -8, centre.Z - radius),
		Vector3.new(centre.X + radius, 0, centre.Z + radius)
	):ExpandToGrid(4)
	local mats, occs = (terrain :: any):ReadVoxels(region, 4)
	local size = mats.Size
	local origin = region.CFrame.Position - region.Size / 2
	local topOcc = math.clamp((surface + 2) / 4, 0.05, 1)
	-- A disc smaller than a voxel still writes the cell under its centre.
	local r2 = math.max(radius * radius, 8)
	for x = 1, size.X do
		local cx = origin.X + (x - 0.5) * 4
		for z = 1, size.Z do
			local cz = origin.Z + (z - 0.5) * 4
			if (cx - centre.X) ^ 2 + (cz - centre.Z) ^ 2 <= r2 then
				mats[x][1][z] = material
				occs[x][1][z] = 1
				mats[x][2][z] = material
				occs[x][2][z] = topOcc
			end
		end
	end
	terrain:WriteVoxels(region, 4, mats, occs)
end

local function paintPart(terrain: Terrain, part: BasePart, remap: { [Enum.Material]: Enum.Material }?)
	local t = top(part)
	local p = part.Position
	local material = if remap and remap[part.Material] then remap[part.Material] else part.Material
	if part:IsA("Part") and part.Shape == Enum.PartType.Cylinder then
		fillDisc(terrain, p, math.max(part.Size.Y, part.Size.Z) / 2, t, material)
	else
		local look = part.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local cf = if flat.Magnitude > 1e-3 then CFrame.lookAt(p, p + flat) else CFrame.new(p)
		fillBlock(terrain, cf, Vector2.new(part.Size.X, part.Size.Z), t, material)
	end
	part.Transparency = 1
end

-- Paints every marked part under `container`, lowest top first. `remap` swaps materials (the hunting habitats
-- use LeafyGrass, which has no grass blades, so graves and creatures stay readable).
-- `current` (optional) is checked between batches: painting stops once it returns false, so a superseded habitat
-- activation never paints a module that has gone back to storage.
function GroundPainter.paint(
	container: Instance,
	remap: { [Enum.Material]: Enum.Material }?,
	current: (() -> boolean)?
): boolean
	local terrain = Workspace.Terrain
	local parts: { BasePart } = {}
	for _, d in container:GetDescendants() do
		if d:IsA("BasePart") and d:GetAttribute("Ground") == true then
			table.insert(parts, d)
		end
	end
	table.sort(parts, function(a, b)
		return top(a) < top(b)
	end)
	for i, part in parts do
		if current and not current() then
			return false
		end
		paintPart(terrain, part, remap)
		if i % 40 == 0 then
			task.wait()
		end
	end
	return true
end

-- The outer world ground: paint a bounded square of grass over it, slightly raised, and keep the part visible
-- beyond (far away, where terrain would only cost memory).
local outer: { material: Enum.Material, surface: number }? = nil
function GroundPainter.paintOuter(part: BasePart, halfExtent: number)
	outer = { material = part.Material, surface = top(part) + 0.08 }
	fillBlock(
		Workspace.Terrain,
		CFrame.new(part.Position),
		Vector2.new(halfExtent * 2, halfExtent * 2),
		top(part) + 0.08,
		part.Material
	)
end

-- Puts the outer ground back over a disc (a habitat footprint), clearing whatever the previous module painted
-- there, including its gate-path ends past the wall (finding 5). Callers repaint what sits on top.
function GroundPainter.reset(centre: Vector3, radius: number)
	local o = outer
	if o then
		fillDisc(Workspace.Terrain, centre, radius, o.surface, o.material)
	end
end

local styled = false
function GroundPainter.style()
	if styled then
		return
	end
	styled = true
	local terrain = Workspace.Terrain
	for material, color in COLORS do
		terrain:SetMaterialColor(material, color)
	end
end

return GroundPainter
