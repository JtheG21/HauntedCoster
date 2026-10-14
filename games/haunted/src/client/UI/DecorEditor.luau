--!strict
-- Exterior decoration editor (TASK-0051, hybrid placement per SYS-Haunted-Monetization-UI): a see-through preview
-- follows the pointer (mouse, touch tap or the screen centre on a controller) over the owner's plot, snaps to the
-- grid, rotates in 15-degree steps and allows a finer step. The shared PlacementRules colour it valid/invalid
-- live; Confirm asks the server (which re-validates), Cancel restores the prior placement, Store returns a placed
-- decoration to inventory. Previewing never changes the world or consumes anything.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Cosmetics = require(Shared:WaitForChild("Config"):WaitForChild("Cosmetics"))
local World = require(Shared.Config:WaitForChild("World"))
local PlacementRules = require(Shared:WaitForChild("Rules"):WaitForChild("PlacementRules"))
local ArtLoader = require(script.Parent.Parent.Art.ArtLoader)
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local DecorEditor = {}

local bar: Frame
local list: ScrollingFrame
local status: TextLabel
local fineButton: TextButton
local storeButton: TextButton
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end

local active = false
local itemId: string? = nil
local moveKey: string? = nil
local preview: Model? = nil
local highlight: Highlight? = nil
local rot, fine = 0, false
local x, z = 0, 0
local valid = false
local why = ""
local pointer: Vector2? = nil
local conns: { RBXScriptConnection } = {}
local busy = false

local function plotFrame(): CFrame?
	local idx = State.snap and State.snap.plotIndex
	return if idx then World.plotFrame(idx) else nil
end

local function placements(): { any }
	local c = State.snap and State.snap.cosmetics
	return (c and c.placements) or {}
end

local function clearPreview()
	if preview then
		preview:Destroy()
		preview = nil
	end
	highlight = nil
end

local function buildPreview(id: string)
	clearPreview()
	local item = Cosmetics.ById[id]
	local built = item and item.look.art and ArtLoader.build(item.look.art)
	if not built or not active or itemId ~= id then
		if built then
			built.model:Destroy()
		end
		return
	end
	for _, p in built.lod1 do
		p:Destroy()
	end
	local m = built.model
	m.Name = "DecorPreview"
	local s = (item :: Cosmetics.Item).look.scale or 1
	if s ~= 1 then
		m:ScaleTo(s)
	end
	for _, d in m:GetDescendants() do
		if d:IsA("BasePart") then
			d.Transparency = math.max(d.Transparency, 0.3)
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.CastShadow = false
		end
	end
	local h = Instance.new("Highlight")
	h.FillTransparency = 0.6
	h.OutlineTransparency = 0.1
	h.DepthMode = Enum.HighlightDepthMode.Occluded
	h.Parent = m
	m.Parent = Workspace
	preview = m
	highlight = h
end

local function update()
	local frame = plotFrame()
	local cam = Workspace.CurrentCamera
	if not (frame and cam and itemId) then
		return
	end
	local pos = pointer
	if UserInputService:GetLastInputType().Name:find("Gamepad") then
		pos = cam.ViewportSize / 2
	end
	if pos then
		local ray = cam:ViewportPointToRay(pos.X, pos.Y)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		local ignore: { Instance } = {}
		if preview then
			table.insert(ignore, preview)
		end
		local char = Players.LocalPlayer.Character
		if char then
			table.insert(ignore, char)
		end
		params.FilterDescendantsInstances = ignore
		local hit = Workspace:Raycast(ray.Origin, ray.Direction * 400, params)
		if hit then
			local lp = frame:PointToObjectSpace(hit.Position)
			x, z = lp.X, lp.Z
		end
	end
	local sx, sz, sr = PlacementRules.snap(x, z, rot, fine)
	local tier = (State.snap and State.snap.houseTier) or 0
	why = PlacementRules.check(itemId, sx, sz, sr, tier, placements(), moveKey)
	valid = why == "ok"
	if preview then
		preview:PivotTo(frame * CFrame.new(sx, 0, sz) * CFrame.Angles(0, math.rad(sr), 0))
	end
	if highlight then
		highlight.FillColor = if valid then Theme.Colors.good else Theme.Colors.bad
		highlight.OutlineColor = highlight.FillColor
	end
	local item = Cosmetics.ById[itemId]
	status.Text = if valid then `{item and item.name or ""}: ready to place` else `Can't place here: {why}`
	status.TextColor3 = if valid then Theme.Colors.good else Theme.Colors.bad
end

local function confirm()
	if busy or not itemId then
		return
	end
	if not valid then
		toast(`Can't place here: {why}`, "error")
		return
	end
	busy = true
	local ok, reason
	if moveKey then
		ok, reason = State.invoke("Cosmetic", "move", moveKey, x, z, rot, fine)
	else
		ok, reason = State.invoke("Cosmetic", "place", itemId, x, z, rot, fine)
	end
	busy = false
	if ok then
		toast(if moveKey then "Moved." else "Placed!", "success")
		DecorEditor.stopPreview()
	elseif reason then
		toast(reason, "error")
	end
end

-- Stops the preview but keeps the editor open on its list.
function DecorEditor.stopPreview()
	itemId = nil
	moveKey = nil
	clearPreview()
	storeButton.Visible = false
	status.Text = "Pick a decoration below, or a placed one to move."
	status.TextColor3 = Theme.Colors.dim
end

local function renderList()
	for _, c in list:GetChildren() do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local c = State.snap and State.snap.cosmetics
	if not c then
		Theme.notice(list, "Loading...", "loading")
		return
	end
	local order = 0
	for _, item in Cosmetics.Items do
		if item.category == "Decoration" and c.owned[item.id] then
			local placedN = 0
			for _, p in c.placements do
				if p.id == item.id then
					placedN += 1
				end
			end
			order += 1
			local b = Theme.button(list, `{item.name}  {placedN}/{item.limit or 1}`, function()
				DecorEditor.begin(item.id, nil)
			end, { Size = UDim2.new(1, 0, 0, 40), TextSize = 14, LayoutOrder = order }, "secondary")
			Theme.setEnabled(b, placedN < (item.limit or 1))
		end
	end
	for i, p in c.placements do
		local item = Cosmetics.ById[p.id]
		order += 1
		Theme.button(list, `Move {item and item.name or p.id} #{i}`, function()
			DecorEditor.begin(p.id, p.key)
		end, { Size = UDim2.new(1, 0, 0, 36), TextSize = 13, LayoutOrder = order })
	end
	if order == 0 then
		Theme.notice(list, "No decorations yet. Find them in the Curio Shop.")
	end
end

-- Starts previewing a decoration: a new copy (`key` nil) or moving placement `key`.
function DecorEditor.begin(id: string, key: string?)
	itemId = id
	moveKey = key
	rot = 0
	fine = false
	fineButton.Text = "Fine: Off"
	if key then
		for _, p in placements() do
			if p.key == key then
				x, z, rot = p.x, p.z, p.rot
			end
		end
	end
	storeButton.Visible = key ~= nil
	task.spawn(buildPreview, id)
end

function DecorEditor.open(id: string?, key: string?)
	if active then
		DecorEditor.close()
	end
	if not plotFrame() then
		toast("You need a home plot to decorate.", "error")
		return
	end
	active = true
	bar.Visible = true
	renderList()
	if id then
		DecorEditor.begin(id, key)
	else
		DecorEditor.stopPreview()
	end
	table.insert(
		conns,
		RunService.RenderStepped:Connect(function()
			if itemId then
				update()
			end
		end)
	)
	table.insert(
		conns,
		UserInputService.InputChanged:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				pointer = Vector2.new(input.Position.X, input.Position.Y)
			end
		end)
	)
	table.insert(
		conns,
		UserInputService.InputBegan:Connect(function(input, processed)
			if input.UserInputType == Enum.UserInputType.Touch and not processed then
				pointer = Vector2.new(input.Position.X, input.Position.Y)
			elseif processed then
				return
			elseif input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonR1 then
				rot = (rot + Cosmetics.Placement.rotationStep) % 360
			elseif input.KeyCode == Enum.KeyCode.ButtonL1 then
				rot = (rot - Cosmetics.Placement.rotationStep) % 360
			elseif
				input.KeyCode == Enum.KeyCode.Return
				or input.KeyCode == Enum.KeyCode.ButtonX
				or (input.UserInputType == Enum.UserInputType.MouseButton1 and itemId ~= nil)
			then
				confirm()
			end
		end)
	)
	table.insert(conns, State.Changed:Connect(renderList))
end

function DecorEditor.close()
	active = false
	for _, c in conns do
		c:Disconnect()
	end
	table.clear(conns)
	DecorEditor.stopPreview()
	bar.Visible = false
end

function DecorEditor.isOpen(): boolean
	return active
end

function DecorEditor.root(): GuiObject?
	return bar
end

-- Back: first leave the preview (Cancel restores the prior placement), then close the editor.
function DecorEditor.back(): boolean
	if itemId then
		DecorEditor.stopPreview()
		return true
	end
	return false
end

function DecorEditor.mount(gui: ScreenGui, toastFn: (string, string?) -> ())
	toast = toastFn
	bar = Theme.panel(gui, {
		Name = "DecorEditor",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 12, 1, -76),
		Size = UDim2.fromOffset(300, 380),
		Visible = false,
		ZIndex = 4,
	})
	Theme.pad(bar, 10)
	Theme.heading(bar, "Decorate", { TextSize = 26, Size = UDim2.new(1, -50, 0, 30) })
	Theme.button(bar, "X", DecorEditor.close, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(40, 32),
	}, "secondary")
	status = Theme.label(bar, "", {
		Position = UDim2.fromOffset(0, 34),
		Size = UDim2.new(1, 0, 0, 36),
		TextSize = 14,
	})
	local controls = Theme.frame(bar, {
		Position = UDim2.fromOffset(0, 72),
		Size = UDim2.new(1, 0, 0, 92),
		BackgroundTransparency = 1,
	})
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0.5, -4, 0, 42)
	grid.CellPadding = UDim2.fromOffset(8, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = controls
	Theme.button(controls, "Rotate (R)", function()
		rot = (rot + Cosmetics.Placement.rotationStep) % 360
	end, { LayoutOrder = 1, TextSize = 14 }, "secondary")
	fineButton = Theme.button(controls, "Fine: Off", function()
		fine = not fine
		fineButton.Text = if fine then "Fine: On" else "Fine: Off"
	end, { LayoutOrder = 2, TextSize = 14 }, "secondary")
	Theme.button(controls, "Confirm", confirm, { LayoutOrder = 3, TextSize = 15 })
	Theme.button(controls, "Cancel", function()
		DecorEditor.stopPreview()
	end, { LayoutOrder = 4, TextSize = 15 }, "secondary")
	storeButton = Theme.button(bar, "Store in inventory", function()
		if moveKey and not busy then
			busy = true
			local ok, reason = State.invoke("Cosmetic", "store", moveKey)
			busy = false
			if ok then
				toast("Stored. It's still yours.", "success")
				DecorEditor.stopPreview()
			elseif reason then
				toast(reason, "error")
			end
		end
	end, { Position = UDim2.fromOffset(0, 168), Size = UDim2.new(1, 0, 0, 36), Visible = false }, "danger")
	list = Theme.scroll(bar, { Position = UDim2.fromOffset(0, 210), Size = UDim2.new(1, 0, 1, -210) })
	Theme.list(list, 6)
end

return DecorEditor
