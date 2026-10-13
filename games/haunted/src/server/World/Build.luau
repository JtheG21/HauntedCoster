--!strict
-- Small helpers for building anchored geometry from code. Visible art is client-side (client/Art): the
-- server builds invisible colliders, lights and prompts, plus `artSlot` anchors the client dresses.

local CollectionService = game:GetService("CollectionService")

local Build = {}

export type PartProps = {
	name: string?,
	size: Vector3,
	cframe: CFrame,
	color: Color3?,
	material: Enum.Material?,
	shape: Enum.PartType?,
	transparency: number?,
	collide: boolean?,
	parent: Instance?,
}

function Build.part(props: PartProps): Part
	local p = Instance.new("Part")
	p.Name = props.name or "Part"
	p.Anchored = true
	p.Size = props.size
	p.CFrame = props.cframe
	p.Color = props.color or Color3.fromRGB(120, 120, 120)
	p.Material = props.material or Enum.Material.SmoothPlastic
	if props.shape then
		p.Shape = props.shape
	end
	p.Transparency = props.transparency or 0
	p.CanCollide = if props.collide == nil then true else props.collide
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	if props.parent then
		p.Parent = props.parent
	end
	return p
end

-- A block standing on the ground at (x, z) with its base at `y`.
function Build.block(
	parent: Instance,
	name: string,
	size: Vector3,
	x: number,
	y: number,
	z: number,
	color: Color3,
	material: Enum.Material?,
	rotY: number?
): Part
	return Build.part({
		name = name,
		size = size,
		cframe = CFrame.new(x, y + size.Y / 2, z) * CFrame.Angles(0, math.rad(rotY or 0), 0),
		color = color,
		material = material,
		parent = parent,
	})
end

function Build.light(parent: BasePart, color: Color3, range: number, brightness: number, shadows: boolean?): PointLight
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = shadows == true
	l.Parent = parent
	return l
end

function Build.billboard(
	parent: BasePart,
	text: string,
	color: Color3,
	offsetY: number,
	maxDistance: number,
	scale: number?
): BillboardGui
	local s = scale or 1
	local gui = Instance.new("BillboardGui")
	gui.Name = "Label"
	gui.Size = UDim2.fromOffset(220 * s, 44 * s)
	gui.StudsOffsetWorldSpace = Vector3.new(0, offsetY, 0)
	gui.MaxDistance = maxDistance
	gui.AlwaysOnTop = false
	gui.LightInfluence = 0
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0.3
	label.Font = Enum.Font.Creepster
	label.TextScaled = true
	label.Parent = gui
	gui.Parent = parent
	return gui
end

-- A flat strip (road or path) between two points on the ground.
function Build.strip(
	parent: Instance,
	name: string,
	a: Vector3,
	b: Vector3,
	width: number,
	color: Color3,
	material: Enum.Material,
	y: number?
): Part
	local mid = (a + b) / 2
	local len = (Vector3.new(b.X, 0, b.Z) - Vector3.new(a.X, 0, a.Z)).Magnitude
	local cf = CFrame.lookAt(Vector3.new(mid.X, y or 0.06, mid.Z), Vector3.new(b.X, y or 0.06, b.Z))
	return Build.part({
		name = name,
		size = Vector3.new(width, 0.12, len),
		cframe = cf,
		color = color,
		material = material,
		parent = parent,
	})
end

-- Moves every part under `container` from local space into `frame`. Plot geometry is built at plot-local
-- coordinates and then placed with the plot's frame, so a rotated plot needs no other changes.
function Build.toFrame(container: Instance, frame: CFrame)
	for _, d in container:GetDescendants() do
		if d:IsA("BasePart") then
			d.CFrame = frame * d.CFrame
		end
	end
end

-- An invisible anchor at an asset's origin (base centre, front = LookVector) tagged for client art.
-- `attrs` may set ArtScale, ArtFollow, ArtLod, ArtCull, Tint_<Part>, Mat_<Part> (client/Art/Dressing).
function Build.artSlot(parent: Instance, key: string, cframe: CFrame, attrs: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = "Art_" .. key
	p.Anchored = true
	p.Size = Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cframe
	p.Transparency = 1
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p:SetAttribute("ArtKey", key)
	if attrs then
		for k, v in attrs do
			p:SetAttribute(k, v)
		end
	end
	CollectionService:AddTag(p, "ArtSlot")
	p.Parent = parent
	return p
end

-- An invisible collider (the art supplies the look). Keeps gameplay collision independent of meshes.
function Build.collider(parent: Instance, name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType?): Part
	local p =
		Build.part({ name = name, size = size, cframe = cframe, shape = shape, transparency = 1, parent = parent })
	p.CanTouch = false
	return p
end

function Build.folder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function Build.model(parent: Instance, name: string): Model
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = parent
	return m
end

return Build
