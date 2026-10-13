--!strict
-- Attaches client art to server anchors. The server tags an invisible, non-colliding anchor part
-- "ArtSlot" whose CFrame is the asset origin (base centre, front = LookVector) and sets:
--   ArtKey     asset name in ReplicatedStorage.Shared.ArtData (changing it rebuilds the visual)
--   ArtScale   uniform scale (default 1)
--   ArtFollow  true for anchors the server moves (the visual is welded instead of anchored)
--   ArtLod     LOD1 distance in studs (default: the asset's LodDistance, else 70)
--   ArtCull    hide beyond this distance (optional, for small clutter)
--   Tint_<Part>, Mat_<Part>  per-part colour / material overrides (mansion themes, variants)
-- Builds run off a queue a few per frame so a habitat swap never hitches.

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local ArtLoader = require(script.Parent.ArtLoader)
local Lod = require(script.Parent.Lod)

local Dressing = {}

local TAG = "ArtSlot"
local PER_FRAME = 12

local current: { [BasePart]: Model } = {}
local queue: { BasePart } = {}
local queued: { [BasePart]: boolean } = {}
local listeners: { [BasePart]: { RBXScriptConnection } } = {}

local function options(anchor: BasePart): ArtLoader.Options
	local tint: { [string]: Color3 } = {}
	local mat: { [string]: Enum.Material } = {}
	for name, value in anchor:GetAttributes() do
		if typeof(value) == "Color3" and string.sub(name, 1, 5) == "Tint_" then
			tint[string.sub(name, 6)] = value
		elseif type(value) == "string" and string.sub(name, 1, 4) == "Mat_" then
			local ok, m = pcall(function()
				return (Enum.Material :: any)[value]
			end)
			if ok and m then
				mat[string.sub(name, 5)] = m
			end
		end
	end
	return { tint = tint, material = mat, castShadow = anchor:GetAttribute("ArtShadow") ~= false }
end

local function clear(anchor: BasePart)
	local old = current[anchor]
	if old then
		current[anchor] = nil
		old:Destroy()
	end
end

local function attach(anchor: BasePart)
	clear(anchor)
	local key = anchor:GetAttribute("ArtKey")
	if type(key) ~= "string" or not anchor.Parent then
		return
	end
	local built = ArtLoader.build(key, options(anchor))
	if not built or not anchor.Parent then
		if built then
			built.model:Destroy()
		end
		return
	end
	local model = built.model
	model.Name = "Art_" .. key
	local scale = anchor:GetAttribute("ArtScale")
	model:PivotTo(anchor.CFrame)
	if type(scale) == "number" and scale > 0 and scale ~= 1 then
		model:ScaleTo(scale)
	end
	if anchor:GetAttribute("ArtFollow") then
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.Anchored = false
				local w = Instance.new("WeldConstraint")
				w.Part0 = anchor
				w.Part1 = p
				w.Parent = p
			end
		end
	end
	model.Parent = anchor
	current[anchor] = model
	local spec = ArtLoader.spec(key)
	local dist = anchor:GetAttribute("ArtLod") or (spec and spec.attrs.LodDistance) or 70
	Lod.register(model, built.lod0, built.lod1, built.shared, dist :: number, anchor:GetAttribute("ArtCull") :: number?)
end

local function enqueue(anchor: BasePart)
	if not queued[anchor] then
		queued[anchor] = true
		table.insert(queue, anchor)
	end
end

local function watch(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local anchor = inst :: BasePart
	if listeners[anchor] then
		return
	end
	local conns = {}
	table.insert(
		conns,
		anchor.AttributeChanged:Connect(function(name)
			if
				name == "ArtKey"
				or name == "ArtScale"
				or string.sub(name, 1, 5) == "Tint_"
				or string.sub(name, 1, 4) == "Mat_"
			then
				enqueue(anchor)
			end
		end)
	)
	listeners[anchor] = conns
	enqueue(anchor)
end

local function unwatch(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end
	local anchor = inst :: BasePart
	local conns = listeners[anchor]
	if conns then
		for _, c in conns do
			c:Disconnect()
		end
	end
	listeners[anchor] = nil
	queued[anchor] = nil
	clear(anchor)
end

local started = false
function Dressing.start()
	if started then
		return
	end
	started = true
	CollectionService:GetInstanceAddedSignal(TAG):Connect(watch)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(unwatch)
	for _, inst in CollectionService:GetTagged(TAG) do
		watch(inst)
	end
	task.spawn(function()
		while true do
			local n = 0
			while #queue > 0 and n < PER_FRAME do
				local anchor = table.remove(queue, 1) :: BasePart
				queued[anchor] = nil
				if listeners[anchor] then
					local ok, err = pcall(function()
						attach(anchor)
					end)
					if not ok then
						warn(`[Dressing] {anchor:GetFullName()}: {err}`)
					end
				end
				n += 1
			end
			RunService.Heartbeat:Wait()
		end
	end)
end

function Dressing.pending(): number
	return #queue
end

function Dressing.visual(anchor: BasePart): Model?
	return current[anchor]
end

return Dressing
