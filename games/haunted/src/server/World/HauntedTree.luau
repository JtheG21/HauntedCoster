--!strict
-- Haunted-tree prop (TASK-0041): three stationary archetypes built from parts, with an optional face whose
-- eyes, upper lids and jaw are separate anchored parts that the client animates (client/HauntedTrees).
-- The trunk, roots and branches never move. Pivot: base centre; the face looks down the pivot's LookVector.
--   Pillar  - ASSET-REF-001: a thick, base-flared, near-cylindrical trunk with a low, heavy-browed face.
--   Broad   - squat and wide, a wide grinning face with teeth (ASSET-REF-002 proportions, toned down).
--   Angular - narrow, faceted and leaning, with a V brow and spiky limbs (ASSET-REF-003 construction).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Build = require(script.Parent.Build)
local HauntedTrees =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("HauntedTrees"))

local HauntedTree = {}

type Spec = {
	r: number, -- trunk radius at the face
	h: number, -- trunk height
	eyeY: number,
	eyeSep: number, -- half the distance between the eyes
	eyeR: number, -- eyeball radius
	mouthY: number,
	mouthW: number,
	bark: Color3,
	barkDark: Color3,
	faceted: boolean,
	lean: number, -- degrees, the upper trunk only (the face section stays upright)
	browTilt: number, -- degrees, positive = angry V
	teeth: boolean,
}

local SPECS: { [string]: Spec } = {
	Pillar = {
		r = 1.6,
		h = 9.5,
		eyeY = 4.4,
		eyeSep = 0.62,
		eyeR = 0.3,
		mouthY = 3.15,
		mouthW = 1.2,
		bark = Color3.fromRGB(74, 74, 62),
		barkDark = Color3.fromRGB(52, 52, 44),
		faceted = false,
		lean = 0,
		browTilt = 0,
		teeth = false,
	},
	Broad = {
		r = 2.1,
		h = 8,
		eyeY = 4.2,
		eyeSep = 0.82,
		eyeR = 0.34,
		mouthY = 2.85,
		mouthW = 1.8,
		bark = Color3.fromRGB(66, 54, 40),
		barkDark = Color3.fromRGB(46, 37, 28),
		faceted = false,
		lean = 0,
		browTilt = 8,
		teeth = true,
	},
	Angular = {
		r = 1.25,
		h = 10.5,
		eyeY = 4.8,
		eyeSep = 0.5,
		eyeR = 0.26,
		mouthY = 3.75,
		mouthW = 0.85,
		bark = Color3.fromRGB(70, 64, 44),
		barkDark = Color3.fromRGB(48, 44, 30),
		faceted = true,
		lean = 6,
		browTilt = 16,
		teeth = false,
	},
}

local SOCKET = Color3.fromRGB(14, 10, 8)
local MOSS = Color3.fromRGB(46, 62, 40)

-- Movement ranges the client reads from attributes on the face parts (studs, before scale).
HauntedTree.LID_TRAVEL = 1.55 -- times eyeR
HauntedTree.JAW_TRAVEL = 0.4

export type Options = {
	archetype: string,
	cframe: CFrame, -- base centre on the ground; LookVector = face direction
	scale: number,
	palette: HauntedTrees.Palette?, -- nil: no face
	id: string,
	rng: Random, -- shape jitter only
}

function HauntedTree.spec(archetype: string): Spec
	return SPECS[archetype] or SPECS.Pillar
end

function HauntedTree.build(parent: Instance, o: Options): Model
	local spec = HauntedTree.spec(o.archetype)
	local s, base, rng = o.scale, o.cframe, o.rng
	local model = Instance.new("Model")
	model.Name = if o.palette then "HauntedTree" else "OldTree"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	-- Every position is in tree-local studs before scale: +X right, +Y up, +F forward (out of the face).
	local function at(x: number, y: number, f: number, rot: CFrame?): CFrame
		return base * CFrame.new(x * s, y * s, -f * s) * (rot or CFrame.identity)
	end
	local function put(
		name: string,
		size: Vector3,
		cf: CFrame,
		color: Color3,
		material: Enum.Material?,
		collide: boolean?,
		shape: Enum.PartType?
	): Part
		local p = Build.part({
			name = name,
			size = size * s,
			cframe = cf,
			color = color,
			material = material or Enum.Material.Wood,
			collide = collide == true,
			shape = shape,
			parent = model,
		})
		if not collide then
			p.CanTouch = false
			p.CanQuery = false
		end
		return p
	end
	local CYL = CFrame.Angles(0, 0, math.rad(90)) -- cylinder axis (X) to vertical
	local FWD = CFrame.Angles(0, math.rad(90), 0) -- cylinder axis (X) to forward

	-- Trunk: an upright lower section carrying the face, then two jittered, tapering upper sections.
	local r, h = spec.r, spec.h
	local lowerH = spec.eyeY + 1.6
	local function trunkSection(name: string, y0: number, y1: number, radius: number, cf: CFrame)
		local height = y1 - y0
		if spec.faceted then
			-- Two overlapping square blocks, 45 degrees apart: an octagonal, faceted section.
			put(name, Vector3.new(radius * 2, height, radius * 2), cf, spec.bark, nil, true)
			put(
				name,
				Vector3.new(radius * 2, height, radius * 2),
				cf * CFrame.Angles(0, math.rad(45), 0),
				spec.barkDark
			)
		else
			put(
				name,
				Vector3.new(height, radius * 2, radius * 2),
				cf * CYL,
				spec.bark,
				nil,
				true,
				Enum.PartType.Cylinder
			)
		end
	end
	trunkSection("Trunk", 0, lowerH, r, at(0, lowerH / 2, 0))
	local leanCF = CFrame.Angles(math.rad(rng:NextNumber(-2, 2)), 0, math.rad(spec.lean + rng:NextNumber(-2, 2)))
	local midH = (h - lowerH) * 0.55
	local mid = at(0, lowerH, 0) * leanCF * CFrame.new(0, midH / 2 * s, 0)
	trunkSection("Trunk", lowerH, lowerH + midH, r * 0.88, mid)
	local topH = h - lowerH - midH
	local top = mid
		* CFrame.new(0, midH / 2 * s, 0)
		* CFrame.Angles(math.rad(rng:NextNumber(-4, 4)), 0, math.rad(rng:NextNumber(-4, 4)))
		* CFrame.new(0, topH / 2 * s, 0)
	trunkSection("Trunk", 0, topH, r * 0.72, top)

	-- Flared base and roots.
	if spec.faceted then
		put(
			"Flare",
			Vector3.new(r * 2.5, 1, r * 2.5),
			at(0, 0.5, 0, CFrame.Angles(0, math.rad(22), 0)),
			spec.barkDark,
			nil,
			true
		)
	else
		put(
			"Flare",
			Vector3.new(1.1, r * 2.6, r * 2.6),
			at(0, 0.55, 0, CYL),
			spec.barkDark,
			nil,
			true,
			Enum.PartType.Cylinder
		)
	end
	local roots = if o.archetype == "Broad" then 6 else 4
	for i = 1, roots do
		local a = math.rad(i * 360 / roots + rng:NextNumber(-18, 18) + 20)
		local len = rng:NextNumber(2.2, 3.4)
		put(
			"Root",
			Vector3.new(0.7 * r, 0.6 * r, len),
			base
				* CFrame.new(math.sin(a) * r * 1.1 * s, 0.35 * s, math.cos(a) * r * 1.1 * s)
				* CFrame.Angles(0, a, 0)
				* CFrame.Angles(math.rad(14), 0, 0),
			spec.barkDark
		)
	end
	put(
		"Moss",
		Vector3.new(r * 2.2, 0.25, r * 1.6),
		at(rng:NextNumber(-0.4, 0.4), 1.05, -0.3),
		MOSS,
		Enum.Material.LeafyGrass
	)

	-- Limbs from the upper trunk: stubs (Pillar), heavy limbs (Broad), thin spikes (Angular).
	local limbs = if o.archetype == "Pillar" then 2 elseif o.archetype == "Broad" then 4 else 6
	for i = 1, limbs do
		local yaw = math.rad(i * 360 / limbs + rng:NextNumber(-25, 25) + 45)
		local onTop = rng:NextNumber() < 0.5
		local anchor = if onTop then top else mid
		local thick = if o.archetype == "Angular" then 0.3 elseif o.archetype == "Broad" then 0.8 else 0.95
		local len = if o.archetype == "Pillar" then rng:NextNumber(1.6, 2.6) else rng:NextNumber(3, 4.6)
		local up = if o.archetype == "Angular" then rng:NextNumber(5, 20) else rng:NextNumber(25, 45)
		put(
			"Limb",
			Vector3.new(thick, thick, len),
			anchor
				* CFrame.new(0, rng:NextNumber(-0.3, 0.4) * s, 0)
				* CFrame.Angles(0, yaw, 0)
				* CFrame.Angles(math.rad(up), 0, 0)
				* CFrame.new(0, 0, -len / 2 * s),
			spec.bark
		)
	end
	-- A broken, jagged crown.
	for i = 1, 2 do
		put(
			"Crown",
			Vector3.new(r * 0.7, 1.4, r * 0.5),
			top
				* CFrame.new((i - 1.5) * r * 0.6 * s, topH / 2 * s + 0.4 * s, 0)
				* CFrame.Angles(0, 0, math.rad((i - 1.5) * 30)),
			spec.barkDark
		)
	end

	model.WorldPivot = base
	model:SetAttribute("Archetype", o.archetype)
	model:SetAttribute("TreeId", o.id)

	if o.palette then
		HauntedTree.face(spec, o.palette, at, put, FWD)
		model:SetAttribute("Palette", o.palette.id)
		model:SetAttribute("Frozen", false)
		CollectionService:AddTag(model, HauntedTrees.tag)
	end
	model.Parent = parent
	return model
end

type At = (number, number, number, CFrame?) -> CFrame
type Put = (string, Vector3, CFrame, Color3, Enum.Material?, boolean?, Enum.PartType?) -> Part

-- The face, set into the front of the lower trunk. Animated parts: PupilL/R, LidL/R, Jaw.
function HauntedTree.face(spec: Spec, palette: HauntedTrees.Palette, at: At, put: Put, FWD: CFrame)
	local r, eR, eY = spec.r, spec.eyeR, spec.eyeY
	local front = r
	local midY = (eY + spec.mouthY) / 2
	local radius = math.max(spec.eyeSep + eR * 1.6, (eY - spec.mouthY) / 2 + 0.6)

	local root = put("FaceRoot", Vector3.new(0.2, 0.2, 0.2), at(0, midY, front + 0.25), spec.bark)
	root.Transparency = 1
	root:SetAttribute("Radius", radius * (root.Size.X / 0.2))

	-- Brow ridge (the open lids tuck under it), cheeks and a nose ridge: forms that blend the face into bark.
	local browY = eY + eR * 1.55
	for side = -1, 1, 2 do
		put(
			"Brow",
			Vector3.new(spec.eyeSep + eR * 1.5, 0.42, 0.45),
			at(
				side * (spec.eyeSep * 0.5 + eR * 0.4),
				browY,
				front + eR + 0.35,
				CFrame.Angles(0, 0, math.rad(-side * spec.browTilt))
			),
			spec.barkDark
		)
		put(
			"Cheek",
			Vector3.new(eR * 2.4, eR * 1.6, 0.4),
			at(
				side * (spec.eyeSep + eR * 0.3),
				eY - eR * 2,
				front + 0.12,
				CFrame.Angles(0, math.rad(side * 12), math.rad(side * 8))
			),
			spec.bark
		)
	end
	put(
		"Nose",
		Vector3.new(0.34, (eY - spec.mouthY) * 0.6, 0.4),
		at(0, midY + 0.12, front + 0.18, CFrame.Angles(math.rad(-14), 0, 0)),
		spec.barkDark
	)

	for side = -1, 1, 2 do
		local tag = if side < 0 then "L" else "R"
		local x = side * spec.eyeSep
		if spec.faceted then
			put(
				"Socket",
				Vector3.new(eR * 2.3, eR * 2.3, 0.15),
				at(x, eY, front + 0.02, CFrame.Angles(0, 0, math.rad(45))),
				SOCKET,
				Enum.Material.SmoothPlastic
			)
		else
			put(
				"Socket",
				Vector3.new(0.15, eR * 2.7, eR * 2.7),
				at(x, eY, front + 0.02, FWD),
				SOCKET,
				Enum.Material.SmoothPlastic,
				false,
				Enum.PartType.Cylinder
			)
		end
		local eye = put(
			"Eye" .. tag,
			Vector3.new(eR * 2, eR * 2, eR * 2),
			at(x, eY, front + 0.02),
			palette.eye,
			if palette.neon then Enum.Material.Neon else Enum.Material.SmoothPlastic,
			false,
			Enum.PartType.Ball
		)
		eye.Reflectance = if palette.neon then 0 else 0.12
		put(
			"Pupil" .. tag,
			Vector3.new(eR * 0.9, eR * 0.9, eR * 0.9),
			at(x, eY, front + 0.02 + eR * 0.72),
			palette.pupil,
			Enum.Material.SmoothPlastic,
			false,
			Enum.PartType.Ball
		):SetAttribute("Orbit", eR * 0.72 * (eye.Size.X / (eR * 2)))
		put("Lid" .. tag, Vector3.new(eR * 2.5, eR * 2.2, 0.35), at(x, eY + eR * 1.65, front + eR + 0.2), spec.barkDark):SetAttribute(
			"Travel",
			HauntedTree.LID_TRAVEL * eR * (eye.Size.X / (eR * 2))
		)
	end

	-- Mouth: a dark cavity behind a static upper lip; the jaw slides down to open it.
	local mY, mW = spec.mouthY, spec.mouthW
	put("MouthCavity", Vector3.new(mW, 0.62, 0.2), at(0, mY - 0.08, front + 0.02), SOCKET, Enum.Material.SmoothPlastic)
	if spec.teeth then
		for i = 1, 4 do
			put(
				"Tooth",
				Vector3.new(mW * 0.16, 0.16, 0.1),
				at((i - 2.5) * mW * 0.22, mY + 0.03, front + 0.14),
				Color3.fromRGB(118, 106, 80)
			)
		end
	end
	put("Lip", Vector3.new(mW + 0.3, 0.3, 0.35), at(0, mY + 0.24, front + 0.17), spec.bark)
	local jaw = put("Jaw", Vector3.new(mW + 0.2, 0.48, 0.35), at(0, mY - 0.15, front + 0.17), spec.bark)
	jaw:SetAttribute("Travel", HauntedTree.JAW_TRAVEL * (jaw.Size.Y / 0.48))
end

return HauntedTree
