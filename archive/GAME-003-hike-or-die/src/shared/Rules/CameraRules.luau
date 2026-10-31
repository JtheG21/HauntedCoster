--!strict
local CameraRules = {}

local function finite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

function CameraRules.isFiniteDirection(x: number, y: number, z: number): boolean
	return finite(x) and finite(y) and finite(z)
end

function CameraRules.isPlausibleDirection(
	x: number,
	y: number,
	z: number,
	facingX: number,
	facingY: number,
	facingZ: number,
	minFacingDot: number
): boolean
	if
		not CameraRules.isFiniteDirection(x, y, z)
		or not CameraRules.isFiniteDirection(facingX, facingY, facingZ)
		or not finite(minFacingDot)
	then
		return false
	end
	local magnitude = math.sqrt(x * x + y * y + z * z)
	local facingMagnitude = math.sqrt(facingX * facingX + facingY * facingY + facingZ * facingZ)
	if magnitude < 0.95 or magnitude > 1.05 or facingMagnitude < 0.95 then
		return false
	end
	local dot = (x * facingX + y * facingY + z * facingZ) / (magnitude * facingMagnitude)
	return dot >= minFacingDot
end

return table.freeze(CameraRules)
