--!strict
-- Local prototype art decoder. No uploads, HTTP, external assets or API keys.
-- Payload is generated from the preserved original PNG by import-art.py.
local AssetService = game:GetService("AssetService")
local EncodingService = game:GetService("EncodingService")
local cached: { [string]: EditableImage } = {}
local Art = { glowCounts = {} :: { [string]: { number } } }
function Art.image(folder: string): EditableImage
	if cached[folder] then
		return cached[folder]
	end
	local data = script.Parent:FindFirstChild(folder)
	assert(data, "Missing local frame art")
	local width = (data:FindFirstChild("Width") :: IntValue).Value
	local height = (data:FindFirstChild("Height") :: IntValue).Value
	assert(
		(width == 768 and height == 682)
			or (width == 576 and height == 768)
			or (width == 768 and height == 768)
			or (width == 1024 and height == 342)
			or (width == 256 and height == 256),
		"Unexpected frame dimensions"
	)
	local chunks = {}
	for _, child in data:GetChildren() do
		if child:IsA("StringValue") and string.match(child.Name, "^Chunk%d+$") then
			table.insert(chunks, child)
		end
	end
	table.sort(chunks, function(a, b)
		return a.Name < b.Name
	end)
	local strings = {}
	for _, child in chunks do
		table.insert(strings, child.Value)
	end
	local compressed = EncodingService:Base64Decode(buffer.fromstring(table.concat(strings)))
	local indices = EncodingService:DecompressBuffer(compressed, Enum.CompressionAlgorithm.Zstd)
	assert(buffer.len(indices) == width * height, "Incorrect frame pixel count")
	local palette =
		EncodingService:Base64Decode(buffer.fromstring((data:FindFirstChild("Palette") :: StringValue).Value))
	local pixels = buffer.create(width * height * 4)
	for i = 0, width * height - 1 do
		local offset = buffer.readu8(indices, i) * 4
		assert(offset + 4 <= buffer.len(palette), "Invalid palette index")
		buffer.writeu32(pixels, i * 4, buffer.readu32(palette, offset))
		if i > 0 and i % 32768 == 0 then
			task.wait()
		end
	end
	local result = AssetService:CreateEditableImage({ Size = Vector2.new(width, height) })
	assert(result, "EditableImage memory budget unavailable")
	result:WritePixelsBuffer(Vector2.zero, Vector2.new(width, height), pixels)
	cached[folder] = result
	return result
end
-- Runtime illumination mask fills dark carved eyes/mouths inside each face.
function Art.glow(folder: string): EditableImage
	local key = folder .. "Glow"
	if cached[key] then
		return cached[key]
	end
	local source = Art.image(folder)
	local size = source.Size
	local pixels = source:ReadPixelsBuffer(Vector2.zero, size)
	local mask = buffer.create(size.X * size.Y * 4)
	local narrow = folder == "PortraitArtData"
	local faces: { { { number } } } = if narrow
		then {
			{ { 0.16, 0.154 }, { 0.197, 0.148 }, { 0.18, 0.161 }, { 0.18, 0.17 } },
			{ { 0.10, 0.90 }, { 0.15, 0.894 }, { 0.13, 0.903 }, { 0.125, 0.92 } },
			{ { 0.862, 0.895 }, { 0.913, 0.904 }, { 0.879, 0.908 }, { 0.887, 0.922 } },
		}
		else {
			{ { 0.14, 0.19 }, { 0.212, 0.172 }, { 0.18, 0.201 }, { 0.17, 0.23 } },
			{ { 0.111, 0.86 }, { 0.163, 0.85 }, { 0.139, 0.863 }, { 0.133, 0.895 } },
			{ { 0.848, 0.848 }, { 0.895, 0.866 }, { 0.854, 0.863 }, { 0.87, 0.90 } },
		}
	local counts: { number } = { 0, 0, 0 }
	local visited = buffer.create(size.X * size.Y)
	local function dark(index: number): boolean
		local offset = index * 4
		return buffer.readu8(pixels, offset) < 205
			and buffer.readu8(pixels, offset + 1) < 130
			and buffer.readu8(pixels, offset + 2) < 120
			and buffer.readu8(pixels, offset + 3) > 200
	end
	for face, seeds in faces do
		for _, seed in seeds do
			local sx, sy = math.floor(seed[1] * size.X), math.floor(seed[2] * size.Y)
			local nearest: number? = nil
			local distance = math.huge
			for dy = -6, 6 do
				for dx = -6, 6 do
					local x, y = sx + dx, sy + dy
					if x >= 0 and x < size.X and y >= 0 and y < size.Y then
						local index = y * size.X + x
						if dx * dx + dy * dy < distance and dark(index) then
							nearest = index
							distance = dx * dx + dy * dy
						end
					end
				end
			end
			if nearest and buffer.readu8(visited, nearest) == 0 then
				local queue = { nearest }
				buffer.writeu8(visited, nearest, 1)
				local head = 1
				while head <= #queue and #queue < 4000 do
					local index = queue[head]
					head += 1
					local x, y = index % size.X, math.floor(index / size.X)
					for _, delta in { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } } do
						local nx, ny = x + delta[1], y + delta[2]
						if nx >= 0 and nx < size.X and ny >= 0 and ny < size.Y then
							local nextIndex = ny * size.X + nx
							if buffer.readu8(visited, nextIndex) == 0 and dark(nextIndex) then
								buffer.writeu8(visited, nextIndex, 1)
								table.insert(queue, nextIndex)
							end
						end
					end
				end
				assert(#queue < 4000, "Carving mask escaped its feature")
				for _, index in queue do
					local offset = index * 4
					buffer.writeu8(mask, offset, 255)
					buffer.writeu8(mask, offset + 1, 170)
					buffer.writeu8(mask, offset + 2, 48)
					buffer.writeu8(mask, offset + 3, 245)
				end
				counts[face] += #queue
			end
		end
	end
	-- Fill isolated one-pixel gaps, then antialias the emission edge.
	-- Orange teeth connected to the outside are preserved.
	local closed = buffer.create(size.X * size.Y)
	for y = 1, size.Y - 2 do
		for x = 1, size.X - 2 do
			local index = y * size.X + x
			local core = buffer.readu8(mask, index * 4 + 3)
			if core == 0 then
				local neighbors = 0
				for _, delta in { -1, 1, -size.X, size.X } do
					if buffer.readu8(mask, (index + delta) * 4 + 3) > 0 then
						neighbors += 1
					end
				end
				if neighbors >= 3 then
					core = 245
				end
			end
			buffer.writeu8(closed, index, core)
		end
	end
	for y = 1, size.Y - 2 do
		for x = 1, size.X - 2 do
			local index = y * size.X + x
			local coverage = buffer.readu8(closed, index) * 4
			for _, delta in { -1, 1, -size.X, size.X } do
				coverage += buffer.readu8(closed, index + delta)
			end
			if coverage > 0 then
				local offset = index * 4
				buffer.writeu8(mask, offset, 255)
				buffer.writeu8(mask, offset + 1, 170)
				buffer.writeu8(mask, offset + 2, 48)
				buffer.writeu8(mask, offset + 3, math.floor(coverage / 8 + 0.5))
			end
		end
		if y % 64 == 0 then
			task.wait()
		end
	end
	local result = AssetService:CreateEditableImage({ Size = size })
	assert(result, "Glow image budget unavailable")
	result:WritePixelsBuffer(Vector2.zero, size, mask)
	Art.glowCounts[folder] = counts
	cached[key] = result
	return result
end
function Art.mount(parent: GuiObject): ImageLabel
	local desktop = Content.fromObject(Art.image("ArtData"))
	local portrait = Content.fromObject(Art.image("PortraitArtData"))
	local image = Instance.new("ImageLabel")
	image.Name = "PaintedHalloweenFrame"
	image.BackgroundTransparency = 1
	image.Size = UDim2.new(1.2, 50, 0, 588)
	image.Position = UDim2.new(-0.1, -24, 0, -82)
	image.ZIndex = 1
	image.Parent = parent
	local function layout()
		local narrow = image.AbsoluteSize.X < 530
		image.ImageContent = if narrow then portrait else desktop
		image:SetAttribute("Variant", if narrow then "portrait" else "desktop")
	end
	image:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
	layout()
	return image
end
function Art.release()
	for _, image in cached do
		image:Destroy()
	end
	table.clear(cached)
end
return Art
