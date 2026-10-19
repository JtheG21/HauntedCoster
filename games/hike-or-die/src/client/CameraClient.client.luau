--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local eventRemote = remotes:WaitForChild("Event") :: RemoteEvent
local Gameplay = require(ReplicatedStorage.Shared.Config.Gameplay)

local gui = Instance.new("ScreenGui")
gui.Name = "HikeOrDieHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
gui.ClipToDeviceSafeArea = true
gui.Parent = player:WaitForChild("PlayerGui")

local function label(name: string, text: string, position: UDim2, size: UDim2): TextLabel
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = Color3.fromRGB(17, 25, 23)
	item.BackgroundTransparency = 0.18
	item.BorderSizePixel = 0
	item.TextColor3 = Color3.fromRGB(237, 230, 203)
	item.Font = Enum.Font.GothamMedium
	item.TextSize = 16
	item.TextWrapped = true
	item.Text = text
	item.Parent = gui
	return item
end

local function button(name: string, text: string, position: UDim2): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = UDim2.fromOffset(132, 48)
	item.BackgroundColor3 = Color3.fromRGB(126, 91, 55)
	item.BackgroundTransparency = 0.08
	item.BorderSizePixel = 0
	item.TextColor3 = Color3.fromRGB(255, 246, 219)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 15
	item.Text = text
	item.Parent = gui
	return item
end

local function aimButton(name: string, text: string, position: UDim2): TextButton
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = UDim2.fromOffset(44, 44)
	item.BackgroundColor3 = Color3.fromRGB(61, 74, 64)
	item.BackgroundTransparency = 0.08
	item.BorderSizePixel = 0
	item.TextColor3 = Color3.fromRGB(245, 239, 215)
	item.Font = Enum.Font.GothamBold
	item.TextSize = 22
	item.Text = text
	item.Visible = false
	item.Parent = gui
	return item
end

local status = label(
	"Status",
	"Find the trail. Photograph the cryptid. Reach the beacon.",
	UDim2.new(0.5, -210, 0, 24),
	UDim2.fromOffset(420, 52)
)
status.TextSize = 17
local behavior = label("Behavior", "Behavior: listening", UDim2.fromOffset(18, 24), UDim2.fromOffset(260, 38))
local score = label("Score", "Proof: 0 photos", UDim2.fromOffset(18, 68), UDim2.fromOffset(260, 38))
local hint = label(
	"Hint",
	"C / CAMERA: raise camera   Q: call into the woods",
	UDim2.new(0.5, -210, 1, -82),
	UDim2.fromOffset(420, 42)
)
local cameraButton = button("CameraButton", "CAMERA  [C]", UDim2.new(1, -150, 1, -120))
local shutterButton = button("ShutterButton", "PHOTO  [SPACE]", UDim2.new(1, -150, 1, -64))
local provokeButton = button("ProvokeButton", "CALL  [Q]", UDim2.new(0, 18, 1, -64))
local aimLeftButton = aimButton("AimLeft", "◀", UDim2.new(0.5, -70, 1, -154))
local aimRightButton = aimButton("AimRight", "▶", UDim2.new(0.5, 26, 1, -154))
local aimUpButton = aimButton("AimUp", "▲", UDim2.new(0.5, -22, 1, -202))
local aimDownButton = aimButton("AimDown", "▼", UDim2.new(0.5, -22, 1, -154))
local reticle = label("Reticle", "+", UDim2.new(0.5, -18, 0.5, -24), UDim2.fromOffset(36, 48))
reticle.BackgroundTransparency = 1
reticle.TextSize = 32
reticle.Visible = false
shutterButton.Visible = false

if UserInputService.TouchEnabled then
	status.AnchorPoint = Vector2.new(0.5, 0)
	status.Position = UDim2.new(0.5, 0, 0, 12)
	status.Size = UDim2.new(0.92, 0, 0, 54)
	behavior.Position = UDim2.fromOffset(18, 76)
	score.Position = UDim2.fromOffset(18, 118)
	cameraButton.Position = UDim2.new(1, -150, 0, 80)
	shutterButton.Position = UDim2.new(1, -150, 0, 136)
	provokeButton.Position = UDim2.fromOffset(18, 166)
	hint.AnchorPoint = Vector2.new(0.5, 0)
	hint.Position = UDim2.new(0.5, 0, 1, -82)
	hint.Size = UDim2.fromOffset(360, 42)
	-- Keep tap-to-aim controls left of the reticle and clear of the move stick.
	aimLeftButton.Position = UDim2.new(0.5, -212, 1, -178)
	aimRightButton.Position = UDim2.new(0.5, -116, 1, -178)
	aimUpButton.Position = UDim2.new(0.5, -164, 1, -226)
	aimDownButton.Position = UDim2.new(0.5, -164, 1, -130)
end

local function defaultHint(): string
	return if UserInputService.TouchEnabled
		then "CAMERA: raise  ·  CALL: provoke"
		else "C / CAMERA: raise camera   Q: call into the woods"
end

local cameraOpen = false
local yaw = 0
local pitch = math.rad(-5)
local roundPhase = "active"
local evidenceCount = 0
local priorCameraType = camera.CameraType
local priorCameraSubject = camera.CameraSubject
local cameraHumanoid: Humanoid? = nil
local priorAutoRotate = true
local dragging = false
local touchDragInput: InputObject? = nil
local touchPosition: Vector2? = nil

local function adjustAim(horizontal: number, vertical: number)
	local step = math.rad(3)
	yaw = math.clamp(yaw + horizontal * step, math.rad(-80), math.rad(80))
	pitch = math.clamp(pitch + vertical * step, math.rad(-55), math.rad(42))
end

local aimActionName = "HikeOrDieCameraAim"
local function handleAimAction(_: string, state: Enum.UserInputState, input: InputObject): Enum.ContextActionResult
	if not cameraOpen then
		return Enum.ContextActionResult.Pass
	end
	if state == Enum.UserInputState.Begin then
		if input.KeyCode == Enum.KeyCode.Left then
			adjustAim(-1, 0)
		elseif input.KeyCode == Enum.KeyCode.Right then
			adjustAim(1, 0)
		elseif input.KeyCode == Enum.KeyCode.Up then
			adjustAim(0, 1)
		elseif input.KeyCode == Enum.KeyCode.Down then
			adjustAim(0, -1)
		end
	end
	return Enum.ContextActionResult.Sink
end

local function setHint(text: string)
	hint.Text = text
	task.delay(4, function()
		if hint.Parent and hint.Text == text then
			hint.Text = defaultHint()
		end
	end)
end

local function setCamera(open: boolean)
	cameraOpen = open and roundPhase == "active"
	if cameraOpen then
		yaw = 0
		priorCameraType = camera.CameraType
		priorCameraSubject = camera.CameraSubject
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			cameraHumanoid = humanoid
			priorAutoRotate = humanoid.AutoRotate
			humanoid.AutoRotate = false
		end
		camera.CameraType = Enum.CameraType.Scriptable
		ContextActionService:BindActionAtPriority(
			aimActionName,
			handleAimAction,
			false,
			Enum.ContextActionPriority.High.Value,
			Enum.KeyCode.Left,
			Enum.KeyCode.Right,
			Enum.KeyCode.Up,
			Enum.KeyCode.Down
		)
		actionRemote:FireServer("camera_opened")
	else
		touchDragInput = nil
		touchPosition = nil
		if cameraHumanoid and cameraHumanoid.Parent then
			cameraHumanoid.AutoRotate = priorAutoRotate
		end
		cameraHumanoid = nil
		ContextActionService:UnbindAction(aimActionName)
		camera.CameraType = priorCameraType
		if priorCameraSubject then
			camera.CameraSubject = priorCameraSubject
		end
	end
	reticle.Visible = cameraOpen
	shutterButton.Visible = cameraOpen
	local showAimButtons = cameraOpen and (UserInputService.TouchEnabled or RunService:IsStudio())
	aimLeftButton.Visible = showAimButtons
	aimRightButton.Visible = showAimButtons
	aimUpButton.Visible = showAimButtons
	aimDownButton.Visible = showAimButtons
	cameraButton.Text = if cameraOpen then "LOWER  [C]" else "CAMERA  [C]"
	if cameraOpen then
		hint.Text = if UserInputService.TouchEnabled
			then "Drag on the right to move camera  ·  move with left stick  ·  PHOTO to shoot"
			else "Right-drag or arrow keys to move camera  ·  WASD to move  ·  SPACE / PHOTO to shoot"
	else
		hint.Text = defaultHint()
	end
end

RunService:BindToRenderStep("HikeOrDieSelfieMovement", Enum.RenderPriority.Input.Value + 1, function()
	if not cameraOpen then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		return
	end

	-- Roblox's default controls are camera-relative. The raised selfie camera
	-- faces back toward the hiker, so remap that input to the hiker's heading.
	local cameraForward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
	local cameraRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
	local characterForward = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
	local characterRight = Vector3.new(root.CFrame.RightVector.X, 0, root.CFrame.RightVector.Z)
	if cameraForward.Magnitude < 0.001 or cameraRight.Magnitude < 0.001 then
		return
	end

	cameraForward = cameraForward.Unit
	cameraRight = cameraRight.Unit
	characterForward = characterForward.Unit
	characterRight = characterRight.Unit
	local currentMove = humanoid.MoveDirection
	local forwardInput = currentMove:Dot(cameraForward)
	local rightInput = currentMove:Dot(cameraRight)
	local characterRelativeMove = characterForward * forwardInput + characterRight * rightInput
	humanoid:Move(characterRelativeMove, false)
end)

local function shoot()
	if not cameraOpen or roundPhase ~= "active" then
		return
	end
	actionRemote:FireServer("shutter", camera.CFrame.Position, camera.CFrame.LookVector)
end

local function provoke()
	if roundPhase == "active" then
		actionRemote:FireServer("provoke")
	end
end

cameraButton.Activated:Connect(function()
	if roundPhase == "extracted" or roundPhase == "failed" then
		actionRemote:FireServer("restart")
	else
		setCamera(not cameraOpen)
	end
end)
shutterButton.Activated:Connect(shoot)
provokeButton.Activated:Connect(provoke)
aimLeftButton.Activated:Connect(function()
	adjustAim(-1, 0)
end)
aimRightButton.Activated:Connect(function()
	adjustAim(1, 0)
end)
aimUpButton.Activated:Connect(function()
	adjustAim(0, 1)
end)
aimDownButton.Activated:Connect(function()
	adjustAim(0, -1)
end)

UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.C then
		setCamera(not cameraOpen)
	elseif input.KeyCode == Enum.KeyCode.Space or input.UserInputType == Enum.UserInputType.MouseButton1 then
		shoot()
	elseif input.KeyCode == Enum.KeyCode.Q then
		provoke()
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = true
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = false
	end
end)

UserInputService.TouchStarted:Connect(function(input: InputObject, processed: boolean)
	if not cameraOpen or processed then
		return
	end

	local position = Vector2.new(input.Position.X, input.Position.Y)
	local viewport = camera.ViewportSize
	local inAimZone = position.X >= viewport.X * 0.52
		and position.Y >= viewport.Y * 0.4
		and position.Y <= viewport.Y * 0.82
	if inAimZone then
		touchDragInput = input
		touchPosition = position
	end
end)

UserInputService.TouchMoved:Connect(function(input: InputObject)
	if not cameraOpen or input ~= touchDragInput or not touchPosition then
		return
	end

	local position = Vector2.new(input.Position.X, input.Position.Y)
	local delta = position - touchPosition
	touchPosition = position
	yaw -= delta.X * 0.006
	pitch = math.clamp(pitch - delta.Y * 0.006, math.rad(-55), math.rad(42))
end)

UserInputService.TouchEnded:Connect(function(input: InputObject)
	if input == touchDragInput then
		touchDragInput = nil
		touchPosition = nil
	end
end)

UserInputService.InputChanged:Connect(function(input: InputObject)
	if
		cameraOpen
		and input.UserInputType == Enum.UserInputType.MouseMovement
		and (dragging or UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
	then
		yaw -= input.Delta.X * 0.004
		pitch = math.clamp(pitch - input.Delta.Y * 0.004, math.rad(-55), math.rad(42))
	end
end)

RunService:BindToRenderStep("HikeOrDieSelfieCamera", Enum.RenderPriority.Camera.Value + 1, function()
	if not cameraOpen then
		return
	end
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (head and head:IsA("BasePart") and root and root:IsA("BasePart")) then
		return
	end
	local pos = head.Position
		+ root.CFrame.LookVector * Gameplay.SelfieForwardOffset
		+ root.CFrame.RightVector * Gameplay.SelfieSideOffset
		+ Vector3.new(0, Gameplay.SelfieHeightOffset, 0)
	-- Mouse yaw also shifts the camera around the hiker. Keep this positional
	-- adjustment inside the origin tolerance enforced by EvidenceService.
	pos += root.CFrame.RightVector * (math.sin(yaw) * Gameplay.MaxAimOriginOffset)
	local baseYaw = math.atan2(root.CFrame.LookVector.X, root.CFrame.LookVector.Z)
	local direction = CFrame.fromOrientation(pitch, baseYaw + yaw, 0).LookVector
	camera.CFrame = CFrame.lookAt(pos, pos + direction)
	camera.Focus = CFrame.new(pos + direction * 16)
end)

local function onCharacter()
	setCamera(false)
	if roundPhase == "extracted" or roundPhase == "failed" then
		cameraButton.Text = "RESTART"
	end
	task.wait(0.25)
	camera.CameraType = Enum.CameraType.Custom
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end
player.CharacterAdded:Connect(onCharacter)

local function renderBreakdown(payload: { [string]: any })
	local reasons = payload.breakdown or {}
	local text = table.concat(reasons, " · ")
	setHint(string.format("%s • %d points\n%s", payload.tier or "Sighting", payload.points or 0, text))
end

eventRemote.OnClientEvent:Connect(function(payload: any)
	if type(payload) ~= "table" then
		return
	end
	if payload.type == "round" then
		roundPhase = payload.phase or roundPhase
		evidenceCount = payload.evidenceCount or evidenceCount
		score.Text = string.format("Proof: %d photos", evidenceCount)
		if roundPhase ~= "active" then
			setCamera(false)
			local total = payload.totalPoints or 0
			status.Text = payload.message or ("Expedition " .. tostring(roundPhase))
			score.Text = string.format("Banked: %d photos  •  %d points", payload.banked or 0, total)
			hint.Text = "Choose a new expedition to replay this trail."
			cameraButton.Text = "RESTART"
		else
			setCamera(false)
			evidenceCount = 0
			behavior.Text = "Behavior: listening"
			status.Text = "Get proof, then reach the beacon at the far end of the trail."
			cameraButton.Text = "CAMERA  [C]"
			setHint("Find the trail. Watch the cryptid. Extract with proof.")
		end
	elseif payload.type == "photo" then
		evidenceCount = payload.evidenceCount or evidenceCount + 1
		score.Text = string.format("Proof: %d photos", evidenceCount)
		renderBreakdown(payload)
	elseif payload.type == "shot_rejected" then
		setHint(payload.message or "The frame did not capture the cryptid.")
	elseif payload.type == "cryptid_state" then
		behavior.Text = "Behavior: " .. tostring(payload.state)
	elseif payload.type == "hint" then
		setHint(payload.text or "Listen for movement.")
	elseif payload.type == "locked" then
		status.Text = payload.message or "Solo test session."
	end
end)

script.Destroying:Connect(function()
	RunService:UnbindFromRenderStep("HikeOrDieSelfieCamera")
	RunService:UnbindFromRenderStep("HikeOrDieSelfieMovement")
end)
