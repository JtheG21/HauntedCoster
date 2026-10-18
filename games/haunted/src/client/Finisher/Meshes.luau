--!strict
-- Mesh templates for the finisher. Creating a MeshPart yields, so load them once with preload() before
-- a sequence runs; get() then clones synchronously and returns nil for anything that did not load.

local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(ReplicatedStorage.Shared.Config.FinisherAssets)

local Meshes = {}

local templates: { [string]: MeshPart } = {}
local state: "idle" | "loading" | "done" = "idle"

-- Yields until every mesh has loaded or failed; a failed mesh is skipped, not retried. A second caller
-- waits for the first instead of returning early.
function Meshes.preload()
	if state == "done" then
		return
	end
	if state == "loading" then
		while state == "loading" do
			task.wait()
		end
		return
	end
	state = "loading"
	local ids: { [string]: number } = Assets.Meshes
	for name, id in ids do
		local ok, mesh = pcall(function()
			return InsertService:CreateMeshPartAsync(
				"rbxassetid://" .. id,
				Enum.CollisionFidelity.Box,
				Enum.RenderFidelity.Automatic
			)
		end)
		if ok and mesh then
			templates[name] = mesh
		else
			warn(`Finisher: mesh {name} ({id}) did not load, skipping it`)
		end
	end
	state = "done"
end

-- A neon, non-colliding copy of a preloaded mesh, or nil when it is not available.
function Meshes.get(name: string, color: Color3, transparency: number): MeshPart?
	local template = templates[name]
	if not template then
		return nil
	end
	local m = template:Clone()
	m.Anchored = true
	m.CanCollide = false
	m.CanQuery = false
	m.CanTouch = false
	m.CastShadow = false
	m.Material = Enum.Material.Neon
	m.Color = color
	m.Transparency = transparency
	return m
end

return Meshes
