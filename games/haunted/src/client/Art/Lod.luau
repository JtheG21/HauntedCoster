--!strict
-- Distance LOD for client art: parts with an LOD1 twin show LOD0 near the camera and LOD1 beyond the
-- asset's LodDistance (attribute, default 70 studs). Hidden parts are unparented, so they cost nothing
-- to render. One 0.4 s sweep over registered models; entries drop when their model leaves the tree.

local RunService = game:GetService("RunService")

local Lod = {}

type Entry = {
	model: Model,
	lod0: { BasePart },
	lod1: { BasePart },
	shared: { BasePart }, -- parts without an LOD twin (hidden only when culled)
	distance: number,
	cull: number?,
	state: number, -- 0 near, 1 far, 2 culled
}

local entries: { Entry } = {}
local started = false

local function apply(e: Entry, state: number)
	if e.state == state then
		return
	end
	e.state = state
	for _, p in e.lod0 do
		p.Parent = if state == 0 then e.model else nil
	end
	for _, p in e.lod1 do
		p.Parent = if state == 1 then e.model else nil
	end
	if e.cull then
		for _, p in e.shared do
			p.Parent = if state == 2 then nil else e.model
		end
	end
end

local function sweep()
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local eye = cam.CFrame.Position
	local i = 1
	while i <= #entries do
		local e = entries[i]
		if not e.model.Parent then
			for _, p in e.lod0 do
				p:Destroy()
			end
			for _, p in e.lod1 do
				p:Destroy()
			end
			for _, p in e.shared do
				p:Destroy()
			end
			entries[i] = entries[#entries]
			entries[#entries] = nil
			continue
		end
		local d = (e.model:GetPivot().Position - eye).Magnitude
		apply(e, if e.cull and d > e.cull then 2 elseif d > e.distance then 1 else 0)
		i += 1
	end
end

function Lod.register(
	model: Model,
	lod0: { BasePart },
	lod1: { BasePart },
	shared: { BasePart },
	distance: number?,
	cull: number?
)
	if #lod1 == 0 and #lod0 == 0 and not cull then
		return
	end
	local e: Entry =
		{ model = model, lod0 = lod0, lod1 = lod1, shared = shared, distance = distance or 70, cull = cull, state = -1 }
	table.insert(entries, e)
	apply(e, 0)
	if not started then
		started = true
		task.spawn(function()
			while true do
				sweep()
				task.wait(0.4)
			end
		end)
	end
	if not RunService:IsRunning() then
		sweep()
	end
end

function Lod.count(): number
	return #entries
end

return Lod
