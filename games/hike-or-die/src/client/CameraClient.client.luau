--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local actionRemote = remotes:WaitForChild("Action") :: RemoteEvent
local eventRemote = remotes:WaitForChild("Event") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "HikeOrDieHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
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
local reticle = label("Reticle", "+", UDim2.new(0.5, -18, 0.5, -24), UDim2.fromOffset(36, 48))
reticle.BackgroundTransparency = 1
reticle.TextSize = 32
reticle.Visible = false
shutterButton.Visible = false

local cameraOpen = false
local yaw = 0
local pitch = math.rad(-5)
local roundPhase = "active"
local evidenceCount = 0
local priorCameraType = camera.CameraType
local priorCameraSubject = camera.CameraSubject
local dragging = false
local touchPosition: Vector2? = nil

local function setHint(text: string)
	hint.Text = text
	task.delay(4, function()
		if hint.Parent and hint.Text == text then
			hint.Text = "C / CAMERA: raise camera   Q: call into the woods"
		end
	end)
end

local function setCamera(open: boolean)
	cameraOpen = open and roundPhase == "active"
	if cameraOpen then
		yaw = 0
		priorCameraType = camera.CameraType
		priorCameraSubject = camera.CameraSubject
		camera.CameraType = Enum.CameraType.Scriptable
		actionRemote:FireServer("camera_opened")
	else
		camera.CameraType = priorCameraType
		if priorCameraSubject then
			camera.CameraSubject = priorCameraSubject
		end
	end
	reticle.Visible = cameraOpen
	shutterButton.Visible = cameraOpen
	cameraButton.Text = if cameraOpen then "LOWER  [C]" else "CAMERA  [C]"
	if cameraOpen then
		hint.Text = if UserInputService.TouchEnabled
			then "Drag to aim  ·  PHOTO to shoot  ·  CALL to provoke"
			else "Right-drag to aim  ·  SPACE / PHOTO to shoot  ·  Q to provoke"
	else
		hint.Text = "C / CAMERA: raise camera   Q: call into the woods"
	end
end

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
	elseif input.UserInputType == Enum.UserInputType.Touch then
		touchPosition = Vector2.new(input.Position.X, input.Position.Y)
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		dragging = false
	end
	if input.UserInputType == Enum.UserInputType.Touch then
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
	elseif cameraOpen and input.UserInputType == Enum.UserInputType.Touch and touchPosition then
		local position = Vector2.new(input.Position.X, input.Position.Y)
		local delta = position - touchPosition
		touchPosition = position
		yaw -= delta.X * 0.006
		pitch = math.clamp(pitch - delta.Y * 0.006, math.rad(-55), math.rad(42))
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
	local pos = head.Position + root.CFrame.LookVector * 3.4 + root.CFrame.RightVector * 2.4 + Vector3.new(0, 1.2, 0)
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
end)
