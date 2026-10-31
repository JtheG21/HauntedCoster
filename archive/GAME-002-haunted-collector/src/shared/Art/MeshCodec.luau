--!strict
-- Decodes HCM1 mesh text produced by games/haunted/art/hcart/codec.py (the two change together; spec:
-- tests/MeshCodec.spec.luau). Pure: no Roblox services, so it runs under Lune.

local MeshCodec = {}

export type Mesh = {
	positions: { Vector3 },
	normals: { Vector3 },
	colors: { Color3 },
	uvs: { Vector2 }?,
	faces: { { number } },
	min: Vector3,
	size: Vector3,
	centre: Vector3,
}

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local LOOKUP: { [number]: number } = {}
for i = 1, #ALPHABET do
	LOOKUP[string.byte(ALPHABET, i)] = i - 1
end

function MeshCodec.base64(text: string): buffer
	local len = #text
	local pad = 0
	if string.sub(text, -2) == "==" then
		pad = 2
	elseif string.sub(text, -1) == "=" then
		pad = 1
	end
	local outLen = (len // 4) * 3 - pad
	local out = buffer.create(outLen)
	local o = 0
	for i = 1, len, 4 do
		local a = LOOKUP[string.byte(text, i)] or 0
		local b = LOOKUP[string.byte(text, i + 1)] or 0
		local c = LOOKUP[string.byte(text, i + 2)] or 0
		local d = LOOKUP[string.byte(text, i + 3)] or 0
		local n = a * 262144 + b * 4096 + c * 64 + d
		if o < outLen then
			buffer.writeu8(out, o, n // 65536)
		end
		if o + 1 < outLen then
			buffer.writeu8(out, o + 1, (n // 256) % 256)
		end
		if o + 2 < outLen then
			buffer.writeu8(out, o + 2, n % 256)
		end
		o += 3
	end
	return out
end

local function octDecode(a: number, b: number): Vector3
	local x = a / 255 * 2 - 1
	local y = b / 255 * 2 - 1
	local z = 1 - math.abs(x) - math.abs(y)
	if z < 0 then
		local nx = (1 - math.abs(y)) * (if x >= 0 then 1 else -1)
		local ny = (1 - math.abs(x)) * (if y >= 0 then 1 else -1)
		x, y = nx, ny
	end
	local len = math.sqrt(x * x + y * y + z * z)
	if len == 0 then
		return Vector3.yAxis
	end
	return Vector3.new(x / len, y / len, z / len)
end

function MeshCodec.decode(text: string): Mesh
	local buf = MeshCodec.base64(text)
	assert(buffer.readstring(buf, 0, 4) == "HCM1", "not an HCM1 mesh")
	local n = buffer.readu32(buf, 4)
	local nf = buffer.readu32(buf, 8)
	local flags = buffer.readu8(buf, 12)
	local o = 13
	local minV = Vector3.new(buffer.readf32(buf, o), buffer.readf32(buf, o + 4), buffer.readf32(buf, o + 8))
	local size = Vector3.new(buffer.readf32(buf, o + 12), buffer.readf32(buf, o + 16), buffer.readf32(buf, o + 20))
	o += 24
	local positions = table.create(n) :: { Vector3 }
	local sx, sy, sz = size.X / 65535, size.Y / 65535, size.Z / 65535
	for i = 1, n do
		positions[i] = Vector3.new(
			minV.X + buffer.readu16(buf, o) * sx,
			minV.Y + buffer.readu16(buf, o + 2) * sy,
			minV.Z + buffer.readu16(buf, o + 4) * sz
		)
		o += 6
	end
	local normals = table.create(n) :: { Vector3 }
	for i = 1, n do
		normals[i] = octDecode(buffer.readu8(buf, o), buffer.readu8(buf, o + 1))
		o += 2
	end
	local colors = table.create(n) :: { Color3 }
	for i = 1, n do
		colors[i] = Color3.fromRGB(buffer.readu8(buf, o), buffer.readu8(buf, o + 1), buffer.readu8(buf, o + 2))
		o += 3
	end
	local uvs: { Vector2 }? = nil
	if flags % 2 == 1 then
		local list = table.create(n) :: { Vector2 }
		for i = 1, n do
			list[i] = Vector2.new(buffer.readi16(buf, o) / 256, buffer.readi16(buf, o + 2) / 256)
			o += 4
		end
		uvs = list
	end
	local faces = table.create(nf) :: { { number } }
	for i = 1, nf do
		faces[i] = { buffer.readu16(buf, o) + 1, buffer.readu16(buf, o + 2) + 1, buffer.readu16(buf, o + 4) + 1 }
		o += 6
	end
	assert(o == buffer.len(buf), "HCM1 length mismatch")
	return {
		positions = positions,
		normals = normals,
		colors = colors,
		uvs = uvs,
		faces = faces,
		min = minV,
		size = size,
		centre = minV + size / 2,
	}
end

return MeshCodec
