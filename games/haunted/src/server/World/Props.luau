--!strict
-- Shared prop kit for the hub and the habitat modules: lanterns, fences, graves, trees, mausoleums, the
-- landmark builders and the walled crypt. Simple parts and built-in materials only (ADR-0007). Moved from
-- the TASK-0012 graveyard builder; TASK-0028 details the Weeping Angel and Bell Tower.

local Build = require(script.Parent.Build)
local GroundPainter = require(script.Parent.GroundPainter)

local Props = {}

-- Consumes `n` random draws. The art builders draw fewer numbers than the part builders they replaced; burning the
-- difference keeps every later draw - and so every habitat layout Reachability validated - exactly as before.
function Props.burn(rng: Random, n: number)
	for _ = 1, n do
		rng:NextNumber()
	end
end

Props.C = {
	grass = Color3.fromRGB(38, 52, 40),
	dirt = Color3.fromRGB(58, 50, 44),
	stone = Color3.fromRGB(105, 105, 112),
	darkStone = Color3.fromRGB(70, 70, 78),
	iron = Color3.fromRGB(25, 25, 28),
	cobble = Color3.fromRGB(82, 80, 84),
	wood = Color3.fromRGB(70, 52, 38),
	lantern = Color3.fromRGB(205, 82, 18), -- warm orange glass; Neon brightens it (TASK-0028)
	lanternLight = Color3.fromRGB(255, 145, 70),
	pumpkin = Color3.fromRGB(214, 98, 24),
	moss = Color3.fromRGB(52, 78, 50),
	marble = Color3.fromRGB(205, 205, 210),
	ghost = Color3.fromRGB(140, 120, 255),
}
local C = Props.C

-- The lamp family (TASK-0028, art TASK-0042): an iron post with a scroll arm and a hanging hexagonal
-- lantern. The server keeps the post collider and the light; the client dresses the `lamp_post` art.
-- `shadows` is for the few key lights only (the light budget allows shadows on a handful).
function Props.lantern(parent: Instance, x: number, z: number, y: number?, shadows: boolean?)
	local base = y or 0
	Build.collider(parent, "LanternPost", Vector3.new(0.6, 8, 0.6), CFrame.new(x, base + 4, z))
	Build.artSlot(parent, "lamp_post", CFrame.new(x, base, z))
	local head = Build.part({
		name = "Lantern",
		size = Vector3.new(0.4, 0.4, 0.4),
		cframe = CFrame.new(x, base + 5.1, z + 1.4),
		transparency = 1,
		collide = false,
		parent = parent,
	})
	head.CanQuery = false
	Build.light(head, C.lanternLight, 30, 2.6, shadows)
end

-- A carved pumpkin (art: pumpkin / pumpkin_lit, TASK-0044). `size` keeps the old footprint; lit ones keep their
-- small warm light. No collider (it never had one).
function Props.pumpkin(parent: Instance, x: number, z: number, size: number, yaw: number, lit: boolean?)
	Build.artSlot(
		parent,
		if lit then "pumpkin_lit" else "pumpkin",
		CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0),
		{ ArtScale = size / 2, ArtCull = 220 }
	)
	if lit then
		local glow = Build.part({
			name = "PumpkinGlow",
			size = Vector3.new(0.4, 0.4, 0.4),
			cframe = CFrame.new(x, size * 0.3, z),
			transparency = 1,
			collide = false,
			parent = parent,
		})
		glow.CanQuery = false
		Build.light(glow, C.lanternLight, 10, 1)
	end
end

-- Low edge stones along both sides of a path segment (art: edge_stone_a/b, culled beyond 140 studs).
function Props.curbStones(parent: Instance, a: Vector3, b: Vector3, width: number, rng: Random)
	local d = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
	local len = d.Magnitude
	if len < 1 then
		return
	end
	local unit = d / len
	local perp = Vector3.new(-unit.Z, 0, unit.X)
	for side = -1, 1, 2 do
		local t = 1.5
		while t < len - 1.5 do
			local p = a + unit * t + perp * side * (width / 2 + 0.5)
			Props.burn(rng, 2) -- the old builder drew 6 numbers per stone
			Build.artSlot(
				parent,
				if rng:NextNumber() < 0.5 then "edge_stone_a" else "edge_stone_b",
				CFrame.lookAt(Vector3.new(p.X, 0, p.Z), Vector3.new(p.X, 0, p.Z) + unit)
					* CFrame.Angles(0, math.rad(rng:NextNumber(-12, 12)), 0),
				{ ArtScale = rng:NextNumber(0.8, 1.2), ArtCull = 140 }
			)
			t += rng:NextNumber(2.4, 3.4)
		end
	end
end

-- A mossy grass patch on the ground (soft ground transitions beside paths).
function Props.mossPatch(parent: Instance, x: number, z: number, radius: number, top: number)
	return Props.disc(parent, "Moss", Vector3.new(x, 0, z), radius, top, C.moss, Enum.Material.Grass)
end

-- A cemetery gate over a path: two stone pillars with ball finials and lamps, and a wrought-iron arch between
-- them (art: gate_pillar, gate_arch stretched to the span). `centre` is on the path; `facing` is along it.
function Props.cemeteryGate(parent: Instance, centre: Vector3, facing: Vector3, width: number)
	local unit = Vector3.new(facing.X, 0, facing.Z).Unit
	local perp = Vector3.new(-unit.Z, 0, unit.X)
	for side = -1, 1, 2 do
		local p = centre + perp * side * (width / 2 + 1)
		Build.collider(parent, "GatePillar", Vector3.new(2, 9.9, 2), CFrame.new(p.X, 4.95, p.Z))
		Build.artSlot(parent, "gate_pillar", CFrame.lookAt(Vector3.new(p.X, 0, p.Z), Vector3.new(p.X, 0, p.Z) + unit))
		Props.lantern(parent, p.X + perp.X * side * 1.6, p.Z + perp.Z * side * 1.6)
	end
	local top = Vector3.new(centre.X, 9.15, centre.Z)
	Build.artSlot(parent, "gate_arch", CFrame.fromMatrix(top, perp, Vector3.yAxis), { ArtStretchX = (width + 2) / 8 })
end

-- A broken stretch of old masonry with a fallen block (art: ruin_wall). Colliders follow the mesh's five block
-- columns, whose heights are fixed in the art (games/haunted/art/assets/graveyard.py ruin_wall, seed 12).
local RUIN_TOPS = { 3.119, 3.704, 3.733, 2.056, 1.635 }
function Props.ruinedWall(parent: Instance, rng: Random, x: number, z: number, yaw: number)
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0)
	-- Mesh +X is world -X of the art frame (Blender -> Roblox), so column i sits at -(-5.1 + 2.05 * (i - 1) + 1.025).
	for i, h in RUIN_TOPS do
		local cx = -(-5.1 + 2.05 * (i - 1) + 1.025)
		Build.collider(parent, "RuinBlock", Vector3.new(2, h, 1.4), cf * CFrame.new(cx, h / 2, 0))
	end
	Props.burn(rng, 7) -- the old builder drew 7 numbers per wall
	Build.artSlot(parent, "ruin_wall", cf)
end

-- A cluster of dripping candles on a grave or a step (art: candles). Lit clusters keep their small light.
function Props.candles(parent: Instance, rng: Random, x: number, z: number, lit: boolean)
	Props.burn(rng, 8) -- the old builder drew 9 numbers per cluster
	Build.artSlot(
		parent,
		"candles",
		CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
		{ ArtCull = 160 }
	)
	if lit then
		local glow = Build.part({
			name = "CandleGlow",
			size = Vector3.new(0.3, 0.3, 0.3),
			cframe = CFrame.new(x, 1.4, z),
			transparency = 1,
			collide = false,
			parent = parent,
		})
		glow.CanQuery = false
		Build.light(glow, C.lanternLight, 9, 0.9)
	end
end

-- A wrought-iron fence from a to b (art: fence_post at each post, fence_panel stretched between them) with one
-- invisible collider for the whole run. `posts` remembers placed posts so lines that share a corner don't stack.
function Props.fenceLine(parent: Instance, a: Vector3, b: Vector3, posts: { [string]: boolean })
	local dir = b - a
	local len = dir.Magnitude
	if len < 0.5 then
		return
	end
	local unit = dir.Unit
	local flat = Vector3.new(unit.X, 0, unit.Z).Unit
	local n = math.max(1, math.floor(len / 4))
	for i = 0, n do
		local p = a + unit * (len * i / n)
		local key = `{math.floor(p.X * 10 + 0.5)}:{math.floor(p.Z * 10 + 0.5)}`
		if not posts[key] then
			posts[key] = true
			Build.artSlot(parent, "fence_post", CFrame.new(p.X, 0, p.Z))
		end
		if i < n then
			local q = a + unit * (len * (i + 0.5) / n)
			Build.artSlot(
				parent,
				"fence_panel",
				CFrame.fromMatrix(Vector3.new(q.X, 0, q.Z), flat, Vector3.yAxis),
				{ ArtStretchX = len / n / 4 }
			)
		end
	end
	local mid = (a + b) / 2
	Build.part({
		name = "FenceCollider",
		size = Vector3.new(0.6, 8, len),
		cframe = CFrame.lookAt(Vector3.new(mid.X, 4, mid.Z), Vector3.new(b.X, 4, b.Z)),
		transparency = 1,
		parent = parent,
	})
end

-- A grave: headstone, Celtic cross, obelisk or a broken leaning slab, with a mound in front (art: grave_*).
-- Colliders keep the old footprints.
local GRAVE_ART = { "grave_headstone", "grave_cross", "grave_obelisk", "grave_leaning" }
local GRAVE_SIZE =
	{ Vector3.new(2.4, 3.2, 0.6), Vector3.new(0.6, 4, 0.6), Vector3.new(1.2, 5.5, 1.2), Vector3.new(2.2, 2.6, 0.5) }
function Props.tombstone(parent: Instance, rng: Random, x: number, z: number)
	local kind = rng:NextInteger(1, 4)
	local rot = rng:NextNumber(-12, 12)
	local scale = rng:NextNumber(0.9, 1.08)
	local base = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rot), 0)
	-- One draw for the lean, as the old builder took (AUD-20261013-TASK-0044-01 finding 1).
	local l = if kind == 4 then rng:NextNumber(-1, 1) else 0
	local lean = if kind == 4 then CFrame.Angles(math.rad(14 * l), 0, math.rad(-6 * l)) else CFrame.identity
	local size = GRAVE_SIZE[kind] * scale
	Build.collider(parent, "Tombstone", size, base * lean * CFrame.new(0, size.Y / 2, 0))
	Build.artSlot(parent, GRAVE_ART[kind], base * lean, { ArtScale = scale })
	-- Grave mound (a low step, as before), towards +Z of the stone.
	Build.collider(parent, "Mound", Vector3.new(2.6, 0.4, 5), base * CFrame.new(0, 0.2, 3))
	Build.artSlot(parent, "grave_mound", base * CFrame.new(0, 0, 3), { ArtCull = 180 })
end

-- A dead, twisted tree with spreading roots (art: tree_dead_a/b/c, 13 studs tall at scale 1).
local DEAD_TREES = { "tree_dead_a", "tree_dead_b", "tree_dead_c" }
function Props.deadTree(parent: Instance, rng: Random, x: number, z: number)
	local h = rng:NextNumber(10, 16)
	Props.burn(rng, 10) -- the old builder drew 13 numbers per tree
	Build.collider(parent, "Trunk", Vector3.new(1.4, h, 1.4), CFrame.new(x, h / 2, z)) -- the old trunk's full height
	Build.artSlot(
		parent,
		DEAD_TREES[math.floor(rng:NextNumber() * #DEAD_TREES) + 1], -- a NextNumber, like the old root draw it replaces
		CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 360)), 0),
		{ ArtScale = h / 13 }
	)
end

-- Faces a landmark's art front (its LookVector) toward +Z, the way the old part builds faced their paths.
local function facingSouth(x: number, z: number, yaw: number?): CFrame
	return CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(180 + (yaw or 0)), 0)
end

-- A classical tomb (art TASK-0045, `landmark_mausoleum`, scaled 0.7-1.3): stepped base and body colliders; the
-- iron door faces +Z as before.
function Props.mausoleum(parent: Instance, x: number, z: number, scale: number, name: string): Part
	local s = scale
	local base = Build.collider(parent, name, Vector3.new(12 * s, s, 10 * s), CFrame.new(x, s / 2, z))
	Build.collider(parent, name .. "Body", Vector3.new(10 * s, 10 * s, 8 * s), CFrame.new(x, s + 5 * s, z))
	Build.artSlot(parent, "landmark_mausoleum", facingSouth(x, z), { ArtScale = s })
	base:SetAttribute("LabelHeight", 13.4 * s + 2.5) -- above the pediment
	return base
end

-- The Weeping Angel (TASK-0028, art TASK-0045): a robed figure on a stepped plinth with both hands over her face
-- and tall folded wings, facing the main gate path (+Z). Two shadow-casting lanterns light it (key lights).
function Props.angel(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.collider(parent, "AngelPedestal", Vector3.new(8, 1.2, 8), CFrame.new(x, 0.6, z))
	Build.collider(parent, "AngelStep", Vector3.new(6, 1.2, 6), CFrame.new(x, 1.8, z))
	Build.collider(parent, "AngelPlinth", Vector3.new(4, 2.6, 4), CFrame.new(x, 3.7, z))
	Build.collider(parent, "AngelFigure", Vector3.new(3.2, 8.6, 3), CFrame.new(x, 9.3, z))
	Build.artSlot(parent, "landmark_angel", facingSouth(x, z))
	Props.lantern(parent, x + 5.5, z + 4, nil, true)
	Props.lantern(parent, x - 5.5, z + 4, nil, true)
	return anchor
end

-- A Victorian funeral carriage (art TASK-0045), turned 15 degrees as before, one wheel off beside it.
function Props.hearse(parent: Instance, pos: Vector3): BasePart
	local cf = CFrame.new(pos.X, 0, pos.Z) * CFrame.Angles(0, math.rad(15), 0)
	local anchor = Build.collider(parent, "HearseBody", Vector3.new(5.2, 5.6, 11), cf * CFrame.new(0, 2.8, 0))
	Build.artSlot(parent, "landmark_hearse", cf)
	return anchor
end

-- The old well (art TASK-0045): a stone ring collider; posts, roof, crank and bucket are art.
function Props.well(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.collider(
		parent,
		"WellRing",
		Vector3.new(2.7, 6, 6),
		CFrame.new(x, 1.35, z) * CFrame.Angles(0, 0, math.rad(90)),
		Enum.PartType.Cylinder
	)
	for _, dx in { -2.6, 2.6 } do
		Build.collider(parent, "WellPost", Vector3.new(0.5, 6, 0.5), CFrame.new(x + dx, 3, z))
	end
	Build.artSlot(parent, "landmark_well", CFrame.new(x, 0, z))
	return anchor
end

-- The Bell Tower (TASK-0028, art TASK-0045): buttressed shaft, open belfry with a lit bell (the one
-- shadow-casting light up high) and a steep spire with an iron cross, ~45 studs. Colliders cover what a player
-- can touch; the belfry and spire are art only.
function Props.bellTower(parent: Instance, pos: Vector3): BasePart
	local x, z = pos.X, pos.Z
	local anchor = Build.collider(parent, "TowerBase", Vector3.new(10, 2, 10), CFrame.new(x, 1, z))
	Build.collider(parent, "Tower", Vector3.new(7, 22, 7), CFrame.new(x, 13, z))
	for _, c in { { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } } do
		Build.collider(parent, "Buttress", Vector3.new(2, 10, 2), CFrame.new(x + c[1] * 3.6, 7, z + c[2] * 3.6))
	end
	Build.artSlot(parent, "landmark_belltower", facingSouth(x, z))
	anchor:SetAttribute("LabelHeight", 47) -- above the spire cross
	local bell = Build.part({
		name = "Bell",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new(x, 26.5, z),
		transparency = 1,
		collide = false,
		parent = parent,
	})
	Build.light(bell, Color3.fromRGB(255, 190, 90), 34, 1.4, true)
	Props.lantern(parent, x + 2.6, z + 6)
	return anchor
end

-- A walled crypt with an iron gate in one wall (art TASK-0045: ashlar `crypt_wall` runs with spiked cresting
-- and two `crypt_gate_leaf` leaves). Returns the gate: an invisible collider, closed on the server; the client
-- opens it locally (clears CanCollide and swings the leaves) for players whose house tier unlocks the crypt.
function Props.crypt(
	parent: Instance,
	r: { x1: number, x2: number, z1: number, z2: number },
	gateSide: string,
	gateAt: number,
	gateWidth: number
): BasePart
	local h = 12
	local centre = Vector3.new((r.x1 + r.x2) / 2, 0, (r.z1 + r.z2) / 2)
	local function wall(a: Vector3, b: Vector3)
		local len = (b - a).Magnitude
		if len < 0.5 then
			return
		end
		local mid = (a + b) / 2
		-- Walls along X are 0.2 taller so overlapping corner tops never share a plane.
		local wh = if math.abs(a.Z - b.Z) < 0.01 then h + 0.2 else h
		Build.collider(
			parent,
			"CryptWall",
			Vector3.new(2, wh, len + 2),
			CFrame.lookAt(Vector3.new(mid.X, wh / 2, mid.Z), Vector3.new(b.X, wh / 2, b.Z))
		)
		-- Art runs of about 8 studs (the buttress side faces out of the crypt).
		local along = (b - a).Unit
		local out = Vector3.new(mid.X - centre.X, 0, mid.Z - centre.Z)
		local right = if out:Dot(Vector3.new(0, 1, 0):Cross(along)) > 0 then along else -along -- LookVector = up x right
		local total = len + 2
		local n = math.max(1, math.round(total / 8))
		for i = 0, n - 1 do
			local c = mid + along * ((i + 0.5) / n - 0.5) * total
			Build.artSlot(
				parent,
				"crypt_wall",
				CFrame.fromMatrix(Vector3.new(c.X, 0, c.Z), right, Vector3.yAxis),
				{ ArtStretchX = total / n / 8, ArtStretchY = wh / 12 }
			)
		end
	end
	local corners: { [string]: { Vector3 } } = {
		x1 = { Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x1, 0, r.z2) },
		x2 = { Vector3.new(r.x2, 0, r.z1), Vector3.new(r.x2, 0, r.z2) },
		z1 = { Vector3.new(r.x1, 0, r.z1), Vector3.new(r.x2, 0, r.z1) },
		z2 = { Vector3.new(r.x1, 0, r.z2), Vector3.new(r.x2, 0, r.z2) },
	}
	local gateCenter: Vector3 = Vector3.zero
	local alongX = false
	local gateUnit = Vector3.xAxis
	for side, ends in corners do
		local a, b = ends[1], ends[2]
		if side == gateSide then
			alongX = side == "z1" or side == "z2"
			local unit = (b - a).Unit
			gateUnit = unit
			gateCenter = if alongX then Vector3.new(gateAt, 0, a.Z) else Vector3.new(a.X, 0, gateAt)
			wall(a, gateCenter - unit * (gateWidth / 2))
			wall(gateCenter + unit * (gateWidth / 2), b)
		else
			wall(a, b)
		end
	end
	local gate = Build.collider(
		parent,
		"CryptGate",
		if alongX then Vector3.new(gateWidth, h - 2, 1) else Vector3.new(1, h - 2, gateWidth),
		CFrame.new(gateCenter.X, (h - 2) / 2, gateCenter.Z)
	)
	gate:SetAttribute("Solid", nil) -- iron bars: sight passes through
	-- Two leaves hinged at the gateposts. A leaf mesh runs from its hinge along the anchor's -RightVector, so the
	-- right vector points away from the gate centre; `Swing` (degrees about the hinge) turns it into the crypt.
	local outward = Vector3.new(gateCenter.X - centre.X, 0, gateCenter.Z - centre.Z)
	for _, s in { -1, 1 } do
		local right = gateUnit * s
		-- Hinges sit 1 stud inside each gate edge, clear of the walls (which overlap the opening by 1).
		local rest = CFrame.fromMatrix(gateCenter + right * (gateWidth / 2 - 1), right, Vector3.yAxis)
		local leaf = Build.artSlot(gate, "crypt_gate_leaf", rest, {
			ArtFollow = true,
			ArtStretchX = (gateWidth / 2 - 1) / 4,
			GateRest = rest,
			Swing = if outward:Dot(rest.LookVector) > 0 then 100 else -100,
		})
		leaf.Name = "GateLeaf"
	end
	Build.billboard(gate, "SEALED CRYPT", Color3.fromRGB(200, 120, 255), 7, 120, 1.2)
	-- Coffins and an eerie glow inside (same seeded draws as before)
	local rng = Random.new(77)
	for _ = 1, 6 do
		local cx, cz = rng:NextNumber(r.x1 + 6, r.x2 - 6), rng:NextNumber(r.z1 + 6, r.z2 - 6)
		local cf = CFrame.new(cx, 0, cz) * CFrame.Angles(0, math.rad(rng:NextNumber(0, 180)), 0)
		Build.collider(parent, "Coffin", Vector3.new(3, 1.4, 7), cf * CFrame.new(0, 0.7, 0))
		Build.artSlot(parent, "coffin", cf)
	end
	local glow = Build.part({
		name = "CryptGlow",
		size = Vector3.new(1, 1, 1),
		cframe = CFrame.new((r.x1 + r.x2) / 2, 6, (r.z1 + r.z2) / 2),
		transparency = 1,
		collide = false,
		parent = parent,
	})
	Build.light(glow, C.ghost, 45, 1.4)
	return gate
end

-- A flat disc lying on the ground with its top face at `top` (Cylinder parts extend along X).
function Props.disc(
	parent: Instance,
	name: string,
	center: Vector3,
	radius: number,
	top: number,
	color: Color3,
	material: Enum.Material
): Part
	local thickness = 0.2
	local disc = Build.part({
		name = name,
		size = Vector3.new(thickness, radius * 2, radius * 2),
		cframe = CFrame.new(center.X, top - thickness / 2, center.Z) * CFrame.Angles(0, 0, math.rad(90)),
		color = color,
		material = material,
		shape = Enum.PartType.Cylinder,
		parent = parent,
	})
	GroundPainter.mark(disc) -- shown as terrain once painted (TASK-0044)
	return disc
end

return Props
