--!strict
-- Control-point track editor (unlocked by the Restored Manor tier). Top-down camera over the plot;
-- mouse, touch or gamepad cursor. Tap/click to add a point after the selected one, tap a point to select it, then Move/Delete or add a
-- special piece. The live preview uses the same TrackRules the server validates with; the server
-- re-validates on Confirm and keeps the last valid route if anything is wrong.

local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("Config")
local World = require(Config:WaitForChild("World"))
local Track = require(Config:WaitForChild("Track"))
local Economy = require(Config:WaitForChild("Economy"))
local TrackRules = require(Shared:WaitForChild("Rules"):WaitForChild("TrackRules"))
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local TrackEditor = {}

type EditPoint = { x: number, z: number, kind: string? }

local player = Players.LocalPlayer
local toast: (string, string?) -> () = function(_text: string, _kind: string?) end

local panel: Frame
local status: TextLabel
local modeLabel: TextLabel
local editing = false
local points: { EditPoint } = {}
local selected: number? = nil
local mode: "add" | "move" = "add"
local preview: Folder? = nil
local inputConn: RBXScriptConnection? = nil
local savedCameraType: Enum.CameraType = Enum.CameraType.Custom
local origin = Vector3.zero
local busy = false
local cursor: TextLabel
local cursorPos = Vector2.zero
local stick = Vector2.zero
local padConn: RBXScriptConnection? = nil

local function plotOrigin(): Vector3?
	local snap = State.snap
	local idx = snap and snap.plotIndex
	return if idx then World.PlotCenters[idx] else nil
end

local function loadStarter()
	points = {}
	for i, v in World.Plot.starterRoute do
		local kind: string? = nil
		for _, piece in World.Plot.starterPieces do
			if piece.i == i then
				kind = piece.kind
			end
		end
		table.insert(points, { x = v.X, z = v.Y, kind = kind })
	end
end

local function loadSaved()
	points = {}
	local snap = State.snap
	local route = snap and snap.route
	if route and route.points then
		for i, p in route.points do
			local kind: string? = nil
			for _, piece in route.pieces or {} do
				if piece.i == i then
					kind = piece.kind
				end
			end
			table.insert(points, { x = p.x, z = p.z, kind = kind })
		end
	else
		loadStarter()
	end
	selected = nil
end

local function toRoute(): ({ TrackRules.P }, { TrackRules.Piece })
	local pts: { TrackRules.P } = {}
	local pieces: { TrackRules.Piece } = {}
	for i, p in points do
		table.insert(pts, { x = p.x, z = p.z })
		if p.kind then
			table.insert(pieces, { i = i, kind = p.kind })
		end
	end
	return pts, pieces
end

local function part(parent: Instance, size: Vector3, cf: CFrame, color: Color3, shape: Enum.PartType?): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.Neon
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end

local function redraw()
	if preview then
		preview:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "TrackEditorPreview"
	preview = folder
	local b = World.Plot.trackBounds
	-- Build-area outline
	local y = 0.4
	local corners = {
		Vector3.new(b.x1, y, b.z1),
		Vector3.new(b.x2, y, b.z1),
		Vector3.new(b.x2, y, b.z2),
		Vector3.new(b.x1, y, b.z2),
	}
	for i = 1, 4 do
		local a, c = origin + corners[i], origin + corners[i % 4 + 1]
		part(
			folder,
			Vector3.new(0.4, 0.2, (c - a).Magnitude),
			CFrame.lookAt((a + c) / 2, c),
			Color3.fromRGB(255, 220, 120)
		)
	end
	local pts, pieces = toRoute()
	local v = TrackRules.validate(pts, pieces, b)
	local sampled = v.sampled or TrackRules.sample(pts)
	local color = if v.ok then Color3.fromRGB(120, 255, 150) else Color3.fromRGB(255, 90, 90)
	local sp = sampled.points
	for i = 1, #sp do
		local a = origin + Vector3.new(sp[i].x, 1.6, sp[i].z)
		local c = origin + Vector3.new(sp[i % #sp + 1].x, 1.6, sp[i % #sp + 1].z)
		if (c - a).Magnitude > 0.05 then
			part(folder, Vector3.new(0.5, 0.3, (c - a).Magnitude), CFrame.lookAt((a + c) / 2, c), color)
		end
	end
	for i, p in points do
		local pos = origin + Vector3.new(p.x, 2.2, p.z)
		local col = if i == selected
			then Color3.fromRGB(255, 230, 80)
			elseif p.kind then Color3.fromRGB(255, 120, 220)
			else Color3.fromRGB(180, 140, 255)
		local ball = part(folder, Vector3.new(2.4, 2.4, 2.4), CFrame.new(pos), col, Enum.PartType.Ball)
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(60, 24)
		gui.StudsOffsetWorldSpace = Vector3.new(0, 2.2, 0)
		gui.AlwaysOnTop = true
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.3
		l.Font = Theme.Bold
		l.TextScaled = true
		l.Text = if p.kind then `{i} {Track.Pieces[p.kind].label}` else tostring(i)
		l.Parent = gui
		gui.Parent = ball
	end
	-- Exhibit range rings so players can see which exhibits count
	local snap = State.snap
	local slots = Economy.HouseTiers[((snap and snap.houseTier) or 0) + 1].exhibitSlots
	for s = 1, slots do
		local lp = World.Plot.exhibitSlots[s]
		local inRange = TrackRules.nearestDistance(sampled, lp.X, lp.Z) <= Economy.ExhibitRange
		local ring = part(
			folder,
			Vector3.new(0.2, Economy.ExhibitRange * 2, Economy.ExhibitRange * 2),
			CFrame.new(origin + Vector3.new(lp.X, 0.3, lp.Z)) * CFrame.Angles(0, 0, math.rad(90)),
			if inRange then Color3.fromRGB(120, 255, 150) else Color3.fromRGB(140, 140, 160),
			Enum.PartType.Cylinder
		)
		ring.Transparency = 0.82
	end
	folder.Parent = Workspace

	local pieceCount = #pieces
	if v.ok and v.sampled then
		local tier = Economy.HouseTiers[((snap and snap.houseTier) or 0) + 1]
		local quality = TrackRules.quality(v.sampled, pieces)
		status.Text = string.format(
			"Valid! %d/%d points  ·  %d studs  ·  quality %.2f  ·  pieces %d/%d  ·  ride x%.1f",
			#points,
			Track.MaxPoints,
			math.floor(v.sampled.length),
			quality,
			pieceCount,
			Track.MaxPieces,
			tier.rideMultiplier
		)
		status.TextColor3 = Theme.Colors.good
	else
		status.Text =
			`{v.reason or "Invalid"}  ·  {#points}/{Track.MaxPoints} points  ·  {math.floor(sampled.length)} studs ({Track.MinLength}-{Track.MaxLength})`
		status.TextColor3 = Theme.Colors.bad
	end
	modeLabel.Text = if mode == "move"
		then "Tap where the selected point should go"
		elseif selected then `Point {selected} selected: tap ground to add after it, or Move / Delete`
		else "Tap the ground to add a point, tap a point to select it"
end

local function groundHit(screenPos: Vector2): Vector3?
	local cam = Workspace.CurrentCamera
	if not cam then
		return nil
	end
	local ray = cam:ViewportPointToRay(screenPos.X, screenPos.Y)
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil
	end
	local t = (1.5 - ray.Origin.Y) / ray.Direction.Y
	if t < 0 then
		return nil
	end
	return ray.Origin + ray.Direction * t
end

local function onTap(screenPos: Vector2)
	local hit = groundHit(screenPos)
	if not hit then
		return
	end
	local lx, lz = hit.X - origin.X, hit.Z - origin.Z
	local b = World.Plot.trackBounds
	-- Select an existing point if the tap is close to one.
	for i, p in points do
		if math.sqrt((p.x - lx) ^ 2 + (p.z - lz) ^ 2) < 3 then
			if mode == "move" and selected == i then
				mode = "add"
			else
				selected = i
				mode = "add"
			end
			redraw()
			return
		end
	end
	if lx < b.x1 or lx > b.x2 or lz < b.z1 or lz > b.z2 then
		toast("Keep points inside the yellow build area.", "error")
		return
	end
	lx = math.floor(lx * 2 + 0.5) / 2
	lz = math.floor(lz * 2 + 0.5) / 2
	if mode == "move" and selected then
		points[selected].x = lx
		points[selected].z = lz
		mode = "add"
	else
		if #points >= Track.MaxPoints then
			toast(`At most {Track.MaxPoints} points.`, "error")
			return
		end
		local at = if selected then selected + 1 else #points + 1
		table.insert(points, at, { x = lx, z = lz })
		selected = at
	end
	redraw()
end

local function setPiece(kind: string)
	local i = selected
	if not i then
		toast("Select a point first.", "error")
		return
	end
	if points[i].kind == kind then
		points[i].kind = nil
	else
		local count = 0
		for _, p in points do
			if p.kind then
				count += 1
			end
		end
		if count >= Track.MaxPieces and not points[i].kind then
			toast(`At most {Track.MaxPieces} special pieces.`, "error")
			return
		end
		points[i].kind = kind
	end
	redraw()
end

local function doMove()
	if selected then
		mode = "move"
		redraw()
	else
		toast("Select a point first.", "error")
	end
end

local function doDelete()
	if selected then
		table.remove(points, selected)
		selected = nil
		mode = "add"
		redraw()
	end
end

local function doConfirm()
	if busy then
		return
	end
	busy = true
	local pts, pieces = toRoute()
	local ok, reason = State.invoke("SubmitRoute", pts, pieces)
	busy = false
	if ok then
		TrackEditor.close()
	else
		toast(`Route rejected: {reason or "unknown"}. Your last valid route is unchanged.`, "error")
	end
end

-- Gamepad: the left stick moves an on-screen cursor, A taps at it, Y = Move, X = Delete,
-- D-pad left/right cycles the selected point, Start or R1 confirms (Start can be taken by the Roblox menu
-- on console), B exits.
local function bindGamepad()
	local cam = Workspace.CurrentCamera
	if cam then
		cursorPos = cam.ViewportSize / 2
	end
	ContextActionService:BindActionAtPriority(
		"HauntedEditorPad",
		function(_, state, input)
			if input.KeyCode == Enum.KeyCode.Thumbstick1 then
				stick = Vector2.new(input.Position.X, -input.Position.Y)
				if stick.Magnitude < 0.15 then
					stick = Vector2.zero
				end
				return Enum.ContextActionResult.Sink
			end
			if state ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Sink
			end
			local key = input.KeyCode
			if key == Enum.KeyCode.ButtonA then
				onTap(cursorPos)
			elseif key == Enum.KeyCode.ButtonY then
				doMove()
			elseif key == Enum.KeyCode.ButtonX then
				doDelete()
			elseif key == Enum.KeyCode.DPadRight or key == Enum.KeyCode.DPadLeft then
				if #points > 0 then
					local step = if key == Enum.KeyCode.DPadRight then 1 else -1
					selected = ((selected or 0) - 1 + step) % #points + 1
					mode = "add"
					redraw()
				end
			elseif key == Enum.KeyCode.ButtonStart or key == Enum.KeyCode.ButtonR1 then
				task.spawn(doConfirm)
			elseif key == Enum.KeyCode.ButtonB then
				TrackEditor.close()
			end
			return Enum.ContextActionResult.Sink
		end,
		false,
		Enum.ContextActionPriority.High.Value + 20,
		Enum.KeyCode.Thumbstick1,
		Enum.KeyCode.ButtonA,
		Enum.KeyCode.ButtonB,
		Enum.KeyCode.ButtonX,
		Enum.KeyCode.ButtonY,
		Enum.KeyCode.DPadLeft,
		Enum.KeyCode.DPadRight,
		Enum.KeyCode.ButtonStart,
		Enum.KeyCode.ButtonR1
	)
	padConn = RunService.RenderStepped:Connect(function(dt)
		local view = Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
		cursorPos = Vector2.new(
			math.clamp(cursorPos.X + stick.X * 500 * dt, 0, view.X),
			math.clamp(cursorPos.Y + stick.Y * 500 * dt, 0, view.Y)
		)
		cursor.Visible = UserInputService.GamepadEnabled
		-- The cursor label lives under the scaled ScreenGui; convert pixels to its coordinate space.
		local scale = 1
		local uiScale = cursor.Parent and cursor.Parent:FindFirstChildOfClass("UIScale")
		if uiScale then
			scale = uiScale.Scale
		end
		local inset = GuiService:GetGuiInset()
		cursor.Position = UDim2.fromOffset(cursorPos.X / scale, (cursorPos.Y - inset.Y) / scale)
	end)
end

local function unbindGamepad()
	ContextActionService:UnbindAction("HauntedEditorPad")
	if padConn then
		padConn:Disconnect()
		padConn = nil
	end
	stick = Vector2.zero
	if cursor then
		cursor.Visible = false
	end
end

-- The character stays put while editing, so a tap on the mobile thumbstick or jump area (or a stick on
-- a gamepad) can't walk it away while it is also placing points.
local controls: any = nil

local function getControls(): any
	if controls == nil then
		local scripts = Players.LocalPlayer:FindFirstChild("PlayerScripts")
		local module = scripts and scripts:FindFirstChild("PlayerModule")
		if module and module:IsA("ModuleScript") then
			local ok, c = pcall(function()
				return (require(module) :: any):GetControls()
			end)
			if ok then
				controls = c
			end
		end
	end
	return controls
end

-- Matches movement to the editor state. It never yields and always applies the CURRENT state, so an
-- open/close race can't leave the controls off.
local function syncMovement()
	local c = getControls()
	if c == nil and editing then
		task.delay(0.5, syncMovement) -- PlayerModule not loaded yet; try again while still editing
		return
	end
	if c then
		pcall(function()
			if editing then
				c:Disable()
			else
				c:Enable()
			end
		end)
	end
end

function TrackEditor.close()
	if not editing then
		return
	end
	editing = false
	panel.Visible = false
	ProximityPromptService.Enabled = true
	syncMovement()
	if preview then
		preview:Destroy()
		preview = nil
	end
	if inputConn then
		inputConn:Disconnect()
		inputConn = nil
	end
	unbindGamepad()
	local cam = Workspace.CurrentCamera
	if cam then
		cam.CameraType = savedCameraType
	end
end

function TrackEditor.open()
	if editing then
		return
	end
	local snap = State.snap
	local o = plotOrigin()
	if not snap or not o then
		toast("Your plot isn't ready yet.", "error")
		return
	end
	if not Economy.HouseTiers[(snap.houseTier or 0) + 1].unlocksEditor then
		toast("Restore your house to unlock the Track Editor.", "error")
		return
	end
	if snap.riding then
		toast("Finish your ride first.", "error")
		return
	end
	if snap.carrying then
		toast("Secure your monster first: its return timer keeps running.", "error")
		return
	end
	origin = o
	editing = true
	loadSaved()
	mode = "add"
	local cam = Workspace.CurrentCamera
	if cam then
		savedCameraType = cam.CameraType
		local b = World.Plot.trackBounds
		local center = origin + Vector3.new((b.x1 + b.x2) / 2, 0, (b.z1 + b.z2) / 2)
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CFrame = CFrame.lookAt(center + Vector3.new(0, 78, 26), center)
	end
	panel.Visible = true
	-- World prompts (e.g. the station's Ride prompt) would sit over the top-down view and swallow taps.
	ProximityPromptService.Enabled = false
	syncMovement()
	inputConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed or not editing then
			return
		end
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			-- Mouse/touch positions exclude the top-bar inset; groundHit takes viewport points (like the
			-- gamepad cursor), so add the inset back or taps land several studs above the cursor.
			local inset = GuiService:GetGuiInset()
			local pos: Vector3 = input.Position
			onTap(Vector2.new(pos.X, pos.Y + inset.Y))
		end
	end)
	bindGamepad()
	redraw()
end

function TrackEditor.isOpen(): boolean
	return editing
end

function TrackEditor.mount(gui: ScreenGui, toastFn: (string, string?) -> ())
	toast = toastFn
	panel = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = UDim2.new(0.96, 0, 0, 150),
		Visible = false,
		ZIndex = 6,
	})
	local sc = Instance.new("UISizeConstraint")
	sc.MaxSize = Vector2.new(720, 190)
	sc.Parent = panel
	Theme.pad(panel, 10)
	Theme.label(
		panel,
		"Track Editor",
		{ Font = Theme.Title, TextSize = 24, Size = UDim2.new(0.4, 0, 0, 26), TextColor3 = Theme.Colors.gold }
	)
	modeLabel = Theme.label(panel, "", {
		Position = UDim2.new(0.3, 0, 0, 2),
		Size = UDim2.new(0.7, 0, 0, 22),
		TextSize = 14,
		TextColor3 = Theme.Colors.dim,
		TextXAlignment = Enum.TextXAlignment.Right,
	})
	status =
		Theme.label(panel, "", { Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 20), TextSize = 14 })
	local row1 = Theme.frame(
		panel,
		{ Position = UDim2.fromOffset(0, 54), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }
	)
	Theme.list(row1, 6, true)
	local row2 = Theme.frame(
		panel,
		{ Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 38), BackgroundTransparency = 1 }
	)
	Theme.list(row2, 6, true)
	local small = { Size = UDim2.fromOffset(104, 36), TextSize = 14 }
	Theme.button(row1, "Move", doMove, small)
	Theme.button(row1, "Delete", doDelete, small)
	Theme.button(row1, "Deselect", function()
		selected = nil
		mode = "add"
		redraw()
	end, small)
	Theme.button(row1, "Scare Arch", function()
		setPiece("ScareArch")
	end, { Size = UDim2.fromOffset(110, 36), TextSize = 14, BackgroundColor3 = Color3.fromRGB(150, 60, 110) })
	Theme.button(row1, "Fog Tunnel", function()
		setPiece("FogTunnel")
	end, { Size = UDim2.fromOffset(110, 36), TextSize = 14, BackgroundColor3 = Color3.fromRGB(150, 60, 110) })
	Theme.button(row1, "Starter Loop", function()
		loadStarter()
		selected = nil
		redraw()
	end, small)
	Theme.button(
		row2,
		"Confirm",
		doConfirm,
		{ Size = UDim2.fromOffset(150, 36), BackgroundColor3 = Color3.fromRGB(60, 140, 80) }
	)
	cursor = Theme.label(gui, "+", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Size = UDim2.fromOffset(40, 40),
		Font = Theme.Bold,
		TextSize = 40,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextColor3 = Color3.fromRGB(255, 230, 80),
		TextStrokeTransparency = 0.2,
		Visible = false,
		ZIndex = 7,
	})
	Theme.button(row2, "Undo changes", function()
		loadSaved()
		redraw()
	end, { Size = UDim2.fromOffset(150, 36), TextSize = 14 })
	Theme.button(
		row2,
		"Exit",
		TrackEditor.close,
		{ Size = UDim2.fromOffset(110, 36), BackgroundColor3 = Theme.Colors.buttonOff }
	)
	player.CharacterRemoving:Connect(function()
		TrackEditor.close()
	end)
end

return TrackEditor
