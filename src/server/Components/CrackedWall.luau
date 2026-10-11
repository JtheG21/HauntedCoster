--!strict
-- Cracked walls (TASK-0004). Tag a BasePart "CrackedWall". A strong enough Ki Burst breaks it once;
-- it restores itself after a delay. State lives in the "Broken" attribute (server-set).

local CollectionService = game:GetService("CollectionService")

local CrackedWall = {}

CrackedWall.Tag = "CrackedWall"

function CrackedWall.isWall(part: BasePart): boolean
	return CollectionService:HasTag(part, CrackedWall.Tag)
end

-- Breaks the wall if it is intact. Returns true only for the call that actually broke it.
function CrackedWall.tryBreak(part: BasePart, respawnSeconds: number): boolean
	if part:GetAttribute("Broken") == true then
		return false
	end
	part:SetAttribute("Broken", true)
	local transparency, canCollide = part.Transparency, part.CanCollide
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	task.delay(respawnSeconds, function()
		if part.Parent then
			part.Transparency = transparency
			part.CanCollide = canCollide
			part.CanQuery = true
			part:SetAttribute("Broken", false)
		end
	end)
	return true
end

return CrackedWall
