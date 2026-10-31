--!strict
-- Exterior decoration editor state (TASK-0065). Holds one draft (place a new copy or move a placed one), the
-- live valid/invalid answer from the shared PlacementRules, and a client-only ghost marker on the plot. The
-- server decides everything again on Confirm; the ghost never touches a real decoration.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local World = require(Shared.Config.World)
local PlacementRules = require(Shared.Rules.PlacementRules)
local State = require(script.Parent.Parent.State)

local DecorEditor = {}

export type Draft = { id: string, index: number?, gx: number, gz: number, fx: number, fz: number, r: number }

local draft: Draft? = nil
local ghost: Part? = nil
local catalogFn: () -> any? = function()
	return nil
end

function DecorEditor.setCatalog(fn: () -> any?)
	catalogFn = fn
end

local function footprint(id: string): PlacementRules.Footprint
	local catalog = catalogFn()
	local item = catalog and catalog.Items[id]
	return (item and item.footprint) or PlacementRules.DefaultFootprint
end

local function tier(): number
	local snap = State.snap
	return if snap and type(snap.houseTier) == "number" then snap.houseTier else 0
end

function DecorEditor.active(): Draft?
	return draft
end

function DecorEditor.position(): (number, number)
	local d = draft :: Draft
	return d.gx + d.fx, d.gz + d.fz
end

-- (ok, text): the live feedback line.
function DecorEditor.status(): (boolean, string)
	local d = draft
	if not d then
		return false, ""
	end
	local x, z = DecorEditor.position()
	local reason = PlacementRules.refusal(x, z, footprint(d.id), d.r, tier())
	if reason then
		return false, PlacementRules.message(reason)
	end
	return true, "Good spot."
end

local function updateGhost()
	local d = draft
	local index = Players.LocalPlayer:GetAttribute("PlotIndex")
	if not d or type(index) ~= "number" then
		if ghost then
			ghost:Destroy()
			ghost = nil
		end
		return
	end
	local fp = footprint(d.id)
	local ghostPart: Part
	if ghost then
		ghostPart = ghost
	else
		ghostPart = Instance.new("Part")
		ghostPart.Name = "DecorGhost"
		ghostPart.Anchored = true
		ghostPart.CanCollide = false
		ghostPart.CanQuery = false
		ghostPart.CanTouch = false
		ghostPart.Transparency = 0.5
		ghostPart.Material = Enum.Material.Neon
		ghostPart.Parent = Workspace
		ghost = ghostPart
	end
	local x, z = DecorEditor.position()
	local ok = DecorEditor.status()
	ghostPart.Size = Vector3.new(fp.x, 0.4, fp.z)
	ghostPart.Color = if ok then Color3.fromRGB(90, 220, 120) else Color3.fromRGB(230, 80, 80)
	local frame = CFrame.new(World.plotToWorld(index, Vector3.new(x, 0.3, z)))
	local base = World.plotToWorld(index, Vector3.zero)
	local ahead = World.plotToWorld(index, Vector3.new(0, 0, 1)) - base
	ghostPart.CFrame = frame * CFrame.Angles(0, math.atan2(-ahead.X, -ahead.Z) + math.rad(d.r), 0)
end

-- Start placing a new copy (index = nil) or moving a placed one at (x, z, r).
function DecorEditor.start(id: string, index: number?, x: number?, z: number?, r: number?)
	local sx, sz = x, z
	local rot = r or 0
	if sx == nil or sz == nil then
		sx, sz = PlacementRules.firstSpot(footprint(id), rot, tier())
	end
	local gx = PlacementRules.snap(sx or 0, 0)
	local gz = PlacementRules.snap(sz or 0, 0)
	draft = { id = id, index = index, gx = gx, gz = gz, fx = (sx or 0) - gx, fz = (sz or 0) - gz, r = rot }
	local d = draft :: Draft
	d.fx = math.clamp(d.fx, -PlacementRules.Fine, PlacementRules.Fine)
	d.fz = math.clamp(d.fz, -PlacementRules.Fine, PlacementRules.Fine)
	updateGhost()
end

function DecorEditor.nudge(dx: number, dz: number)
	local d = draft
	if d then
		d.gx += dx * PlacementRules.Grid
		d.gz += dz * PlacementRules.Grid
		updateGhost()
	end
end

function DecorEditor.fine(dx: number, dz: number)
	local d = draft
	if d then
		d.fx = math.clamp(d.fx + dx * PlacementRules.Step, -PlacementRules.Fine, PlacementRules.Fine)
		d.fz = math.clamp(d.fz + dz * PlacementRules.Step, -PlacementRules.Fine, PlacementRules.Fine)
		updateGhost()
	end
end

function DecorEditor.rotate()
	local d = draft
	if d then
		d.r = (d.r + 90) % 360
		updateGhost()
	end
end

function DecorEditor.cancel()
	draft = nil
	updateGhost()
end

-- Sends the draft; the server answers (ok, message). On success the editor closes.
function DecorEditor.confirm(): (boolean, string?)
	local d = draft
	if not d then
		return false, nil
	end
	local x, z = DecorEditor.position()
	local ok, msg
	if d.index then
		ok, msg = State.invoke("EditDecoration", "move", d.index, x, z, d.r)
	else
		ok, msg = State.invoke("EditDecoration", "place", d.id, x, z, d.r)
	end
	if ok == true then
		DecorEditor.cancel()
		return true, nil
	end
	return false, if type(msg) == "string" then msg else "Something went wrong. Try again."
end

-- Stores a placed copy (it stays owned).
function DecorEditor.store(index: number): (boolean, string?)
	local ok, msg = State.invoke("EditDecoration", "store", index)
	if ok == true then
		return true, nil
	end
	return false, if type(msg) == "string" then msg else "Something went wrong. Try again."
end

return DecorEditor
