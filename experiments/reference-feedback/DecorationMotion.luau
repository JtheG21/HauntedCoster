--!strict
-- Independent decorative layers; the structural frame never moves.
local FrameArt = require(script.Parent.FrameArt)
local Decoration = {}
function Decoration.mount(art: ImageLabel, backdrop: Frame)
	local atlas = Content.fromObject(FrameArt.image("SpriteArtData"))
	local function sprite(name: string, cell: number, parent: Instance): ImageLabel
		local image = Instance.new("ImageLabel")
		image.Name = name
		image.BackgroundTransparency = 1
		image.ImageContent = atlas
		local crops = {
			{ 0.035, 0.15, 0.28, 0.37 },
			{ 0.34, 0.08, 0.32, 0.45 },
			{ 0.7, 0.26, 0.27, 0.22 },
			{
				0.04,
				0.6,
				0.28,
				0.32,
			},
			{
				0.35,
				0.6,
				0.3,
				0.32,
			},
		}
		local crop = crops[cell + 1]
		image.ImageRectOffset = Vector2.new(math.floor(crop[1] * 768), math.floor(crop[2] * 768))
		image.ImageRectSize = Vector2.new(math.floor(crop[3] * 768), math.floor(crop[4] * 768))
		image.ScaleType = Enum.ScaleType.Fit
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ZIndex = 1
		image.Parent = parent
		return image
	end
	local ghost = sprite("SwayingGhost", 0, art)
	local rooted = Content.fromObject(FrameArt.image("RootArtData"))
	local treeContent = Content.fromObject(FrameArt.image("TreeArtData"))
	local function ornament(name: string, crop: { number }): ImageLabel
		local image = Instance.new("ImageLabel")
		image.Name = name
		image.BackgroundTransparency = 1
		image.ImageContent = rooted
		image.ImageRectOffset = Vector2.new(math.floor(crop[1] * 1024), math.floor(crop[2] * 342))
		image.ImageRectSize = Vector2.new(math.floor(crop[3] * 1024), math.floor(crop[4] * 342))
		image.AnchorPoint = Vector2.new(0.5, 0.5)
		image.ZIndex = 1
		image.Parent = art
		return image
	end
	local branch = ornament("RootedTree", { 0.02, 0, 0.22, 1 })
	branch.ImageContent = treeContent
	branch.AnchorPoint = Vector2.new(0.5, 1)
	branch.ScaleType = Enum.ScaleType.Stretch
	local ornaments: { ImageLabel } = {}
	for i = 1, 7 do
		ornaments[i] = ornament("SideTwigLeaves" .. i, { 0.30, 0.27, 0.20, 0.56 })
		ornaments[i].ScaleType = Enum.ScaleType.Fit
	end
	local spiders = { sprite("WebSpider1", 2, art), sprite("WebSpider2", 2, art) }
	local threads: { Frame } = {}
	for i = 1, 2 do
		local line = Instance.new("Frame")
		line.Name = "SpiderThread" .. i
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BorderSizePixel = 0
		line.BackgroundColor3 = Color3.fromRGB(168, 139, 183)
		line.BackgroundTransparency = 0.45
		line.ZIndex = 1
		line.Parent = art
		threads[i] = line
	end
	local leaves: { ImageLabel } = {}
	for i = 1, 10 do
		local leaf = sprite("FallingLeaf" .. i, if i % 3 == 0 then 4 else 3, backdrop)
		leaf.ZIndex = 2
		leaf.ImageTransparency = 0.48
		leaf.Size = UDim2.fromOffset(22 + (i % 3) * 5, 30 + (i % 3) * 7)
		leaves[i] = leaf
	end
	-- A soft, low-contrast background gradient moves independently of the panel.
	local wash = Instance.new("Frame")
	wash.Name = "AmbientBackground"
	wash.Size = UDim2.fromScale(1, 1)
	wash.BorderSizePixel = 0
	wash.BackgroundColor3 = Color3.fromRGB(59, 28, 65)
	wash.ZIndex = 1
	wash.Parent = backdrop
	local gradient = Instance.new("UIGradient")
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.5, 0.78),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Rotation = 25
	gradient.Parent = wash
	-- Backdrop drawing order is below the card, with non-interactive leaves outside its edges.
	wash.LayoutOrder = -1
	local glow = Instance.new("ImageLabel")
	glow.Name = "CarvedPumpkinGlow"
	glow.BackgroundTransparency = 1
	glow.Size = UDim2.fromScale(1, 1)
	glow.ZIndex = 1
	glow.Parent = art
	local desktopGlow = Content.fromObject(FrameArt.glow("ArtData"))
	local portraitGlow = Content.fromObject(FrameArt.glow("PortraitArtData"))
	local function tick(t: number, enabled: boolean)
		local narrow = art:GetAttribute("Variant") == "portrait"
		local phase = if enabled then t else 0
		glow.ImageContent = if narrow then portraitGlow else desktopGlow
		glow.ImageTransparency = if enabled then 0.50 + 0.47 * math.cos(t * (2 * math.pi / 5)) else 0.50
		local gx = if narrow then 0.10 else 0.05
		local gy = if narrow then 0.46 else 0.52
		ghost.Position = UDim2.fromScale(gx, gy + math.sin(phase * 1.25) * 0.003)
		ghost.Size = UDim2.fromScale(if narrow then 0.10 else 0.13, 0.19)
		ghost.Rotation = math.sin(phase * 0.9) * 1.8
		branch.Position =
			UDim2.new(if narrow then 0.875 else 0.89, if narrow then 6 else 12, if narrow then 0.49 else 0.635, 0)
		branch.Size = UDim2.fromScale(if narrow then 0.15 else 0.22, if narrow then 0.34 else 0.61)
		branch.Rotation = math.sin(phase * 0.65) * 0.22
		-- Both silk origins follow visible fork tips, including tree rotation.
		local function treePoint(u: number, v: number): Vector2
			local localPoint = Vector2.new((u - 0.5) * branch.AbsoluteSize.X, (v - 0.5) * branch.AbsoluteSize.Y)
			local angle = math.rad(branch.Rotation)
			local rotated = Vector2.new(
				localPoint.X * math.cos(angle) - localPoint.Y * math.sin(angle),
				localPoint.X * math.sin(angle) + localPoint.Y * math.cos(angle)
			)
			return Vector2.new(
				branch.Position.X.Scale * art.AbsoluteSize.X
					+ branch.Position.X.Offset
					+ (0.5 - branch.AnchorPoint.X) * branch.AbsoluteSize.X,
				branch.Position.Y.Scale * art.AbsoluteSize.Y
					+ branch.Position.Y.Offset
					+ (0.5 - branch.AnchorPoint.Y) * branch.AbsoluteSize.Y
			) + rotated
		end
		for i, spider in spiders do
			local start = treePoint(
				if i == 1 then 0.085 else (if narrow then 0.75 else 0.90),
				if i == 1 then 0.17 else (if narrow then 0.13 else 0.085)
			)
			local endPoint = start
				+ Vector2.new(
					if narrow and i == 2 then -12 else 0,
					36 + (i - 1) * 18 + (if enabled then math.sin(phase * 0.58 + i * 1.8) * 9 else 0)
				)
			local delta = endPoint - start
			local midpoint = (start + endPoint) / 2
			threads[i].Position = UDim2.fromOffset(midpoint.X, midpoint.Y)
			threads[i].Size = UDim2.fromOffset(1, delta.Magnitude)
			threads[i].Rotation = math.deg(math.atan2(-delta.X, delta.Y))
			spider.Position = UDim2.fromOffset(endPoint.X, endPoint.Y + 8)
			spider.Size = UDim2.fromScale(if narrow then 0.045 else 0.05, 0.055)
			spider.Rotation = if enabled then math.sin(phase * 0.7 + i) * 1.5 else 0
		end
		local sites = {
			{ 0.055, 0.34 },
			{ 0.055, 0.68 },
			{ 0.055, 0.81 },
			{ 0.95, 0.40 },
			{ 0.95, 0.70 },
			{ 0.95, 0.82 },
			{
				0.245,
				0.14,
			},
		}
		for i, image in ornaments do
			local site = sites[i]
			image.Visible = i ~= 3 and i ~= 6 and not (narrow and (i == 5 or i == 7))
			local siteX = if narrow and i <= 3 then 0.09 elseif narrow and i <= 6 then 0.905 else site[1]
			image.Position = UDim2.new(siteX, math.sin(phase * 0.9 + i) * 0.6, site[2], math.sin(phase * 1.1 + i) * 1.2)
			image.Size = UDim2.fromScale(if narrow then 0.10 else 0.115, 0.14)
			image.Rotation = (if i > 3 and i < 7 then 180 else 0) + math.sin(phase * 0.8 + i) * 2.2
		end
		for i, leaf in leaves do
			leaf.Visible = enabled
			local fraction = (t * (0.025 + i * 0.001) + (i * 0.137)) % 1
			local side = if i % 2 == 0 then 0.1 else 0.9
			leaf.Position = UDim2.fromScale(side + math.sin(t * 0.35 + i) * 0.07, fraction * 1.15 - 0.075)
			leaf.Rotation = i * 31 + math.sin(t * 0.55 + i) * 35
			leaf.ImageTransparency = 0.5 + 0.35 * math.abs(fraction - 0.5) * 2
		end
		gradient.Offset = Vector2.new(math.sin(phase * 0.11) * 0.35, math.cos(phase * 0.09) * 0.22)
	end
	tick(0, false)
	return { step = tick }
end
return Decoration
