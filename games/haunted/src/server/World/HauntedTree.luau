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
		h = 8,
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
		h = 7,
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
		h = 9,
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

-- Movement ranges the client reads from attributes on the face parts (studs, before scale).
HauntedTree.LID_TRAVEL = 1.75 -- times eyeR
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
	local FWD = CFrame.Angles(0, math.rad(90), 0) -- cylinder axis (X) to forward

	-- Trunk, roots, limbs and crown are one carved mesh (art: tree_haunted_<archetype>, faceless tree_old_<...>,
	-- TASK-0044) whose face band is exactly radius r, so the eyes below sit in its carved sockets. One solid
	-- collider stands in for it (blocks movement and gaze sight lines, shared/TreeSight).
	local r, h = spec.r, spec.h
	-- The old part builder drew this many numbers (jitter, roots, moss, limbs); burn them so the Woodland layout
	-- after each tree is unchanged.
	local draws = if o.archetype == "Broad" then 37 elseif o.archetype == "Angular" then 43 else 23
	for _ = 1, draws do
		rng:NextNumber()
	end
	local trunk = put("Trunk", Vector3.new(r * 1.9, h * 0.75, r * 1.9), at(0, h * 0.375, 0), spec.bark, nil, true)
	trunk.Transparency = 1
	trunk:SetAttribute("Solid", true)
	Build.artSlot(
		model,
		(if o.palette then "tree_haunted_" else "tree_old_") .. string.lower(o.archetype),
		base,
		{ ArtScale = s }
	)

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

-- Animated face parts keep their invisible part (the client moves it) and get a welded bark mesh.
local function dress(part: BasePart, key: string, scale: number)
	part.Transparency = 1
	part:SetAttribute("ArtKey", key)
	part:SetAttribute("ArtFollow", true)
	part:SetAttribute("ArtScale", scale)
	CollectionService:AddTag(part, "ArtSlot")
end

-- The face, set into the front of the lower trunk. Animated parts: PupilL/R, LidL/R, Jaw.
function HauntedTree.face(spec: Spec, palette: HauntedTrees.Palette, at: At, put: Put, _FWD: CFrame)
	local r, eR, eY = spec.r, spec.eyeR, spec.eyeY
	local front = r
	local midY = (eY + spec.mouthY) / 2
	local radius = math.max(spec.eyeSep + eR * 1.6, (eY - spec.mouthY) / 2 + 0.6)

	local root = put("FaceRoot", Vector3.new(0.2, 0.2, 0.2), at(0, midY, front + 0.25), spec.bark)
	root.Transparency = 1
	root:SetAttribute("Radius", radius * (root.Size.X / 0.2))

	-- Brow, cheeks, nose, sockets and the mouth cavity are carved into the trunk mesh (TASK-0044).

	for side = -1, 1, 2 do
		local tag = if side < 0 then "L" else "R"
		local x = side * spec.eyeSep
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
		local lid = put(
			"Lid" .. tag,
			Vector3.new(eR * 2.5, eR * 2, 0.15),
			at(x, eY + eR * 1.75, front + eR + 0.11),
			spec.barkDark
		)
		lid:SetAttribute("Travel", HauntedTree.LID_TRAVEL * eR * (eye.Size.X / (eR * 2)))
		dress(lid, "tree_lid", lid.Size.X / 0.75)
	end

	-- Mouth: the cavity, upper lip and (Broad) teeth are carved into the trunk; the jaw slides down to open it.
	local mY, mW = spec.mouthY, spec.mouthW
	local jaw = put("Jaw", Vector3.new(mW + 0.2, 0.48, 0.35), at(0, mY - 0.15, front + 0.17), spec.bark)
	jaw:SetAttribute("Travel", HauntedTree.JAW_TRAVEL * (jaw.Size.Y / 0.48))
	dress(jaw, "tree_jaw", jaw.Size.X / 1.4)
end

return HauntedTree
