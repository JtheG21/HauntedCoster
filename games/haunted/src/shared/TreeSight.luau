--!strict
-- Line of sight to a haunted-tree face (TASK-0041), shared so the client's gaze test and the server's
-- plausibility check agree. See-through parts (Transparency >= 0.5) and characters don't block; the tree
-- itself and the viewer's own character are excluded up front. Invisible colliders that stand in for client
-- art (Build.collider, attribute Solid) do block: the mesh the player sees is there.

local Workspace = game:GetService("Workspace")

local TreeSight = {}

local MAX_PASSES = 4

local function isCharacterPart(part: BasePart): boolean
	local m = part:FindFirstAncestorOfClass("Model")
	return m ~= nil and m:FindFirstChildOfClass("Humanoid") ~= nil
end

function TreeSight.clear(from: Vector3, to: Vector3, exclude: { Instance }): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local list = table.clone(exclude)
	params.FilterDescendantsInstances = list
	for _ = 1, MAX_PASSES do
		local hit = Workspace:Raycast(from, to - from, params)
		if not hit then
			return true
		end
		local part = hit.Instance
		if (part.Transparency >= 0.5 and part:GetAttribute("Solid") ~= true) or isCharacterPart(part) then
			table.insert(list, part)
			params.FilterDescendantsInstances = list
		else
			return false
		end
	end
	return false
end

return TreeSight
