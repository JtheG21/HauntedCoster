--!strict
-- Rotatable 3D previews for menus (TASK-0051): a ViewportFrame holding a clone of an art asset with optional
-- per-part tints/materials (skins, themes). Previews never touch the live world. Drag to rotate; idles slowly.

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local ArtLoader = require(script.Parent.Parent.Art.ArtLoader)

local Preview = {}

export type Handle = { set: (key: string?, opts: ArtLoader.Options?, variant: string?) -> (), destroy: () -> () }

local VARIANT_TINT = {
	Spectral = Color3.fromRGB(196, 242, 255),
	Ashen = Color3.fromRGB(78, 72, 70),
}

-- Mounts a preview into `parent` (sized by the caller). Returns a handle to swap the shown asset.
function Preview.mount(parent: GuiObject): Handle
	local vp = Instance.new("ViewportFrame")
	vp.Name = "Preview"
	vp.Size = UDim2.fromScale(1, 1)
	vp.BackgroundTransparency = 1
	vp.Ambient = Color3.fromRGB(150, 140, 170)
	vp.LightColor = Color3.fromRGB(255, 236, 210)
	vp.LightDirection = Vector3.new(-1, -1.4, -0.8)
	vp.Parent = parent
	local world = Instance.new("WorldModel")
	world.Parent = vp
	local cam = Instance.new("Camera")
	cam.FieldOfView = 30
	cam.Parent = vp
	vp.CurrentCamera = cam
	local model: Model? = nil
	local yaw, pitch = 200, 14
	local dragging = false
	local radius, centre = 10, Vector3.zero
	local token = 0

	local function place()
		cam.CFrame = CFrame.new(centre)
			* CFrame.Angles(0, math.rad(yaw), 0)
			* CFrame.Angles(math.rad(-pitch), 0, 0)
			* CFrame.new(0, 0, radius)
	end

	local conn = RunService.RenderStepped:Connect(function(dt: number)
		if model and not dragging and vp.Visible then
			yaw += dt * 18
			place()
		end
	end)
	vp.InputBegan:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = true
		end
	end)
	vp.InputEnded:Connect(function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			dragging = false
		end
	end)
	local moveConn = UserInputService.InputChanged:Connect(function(input: InputObject)
		if
			dragging
			and (
				input.UserInputType == Enum.UserInputType.MouseMovement
				or input.UserInputType == Enum.UserInputType.Touch
			)
		then
			yaw -= input.Delta.X * 0.5
			pitch = math.clamp(pitch + input.Delta.Y * 0.3, -10, 60)
			place()
		end
	end)

	local function set(key: string?, opts: ArtLoader.Options?, variant: string?)
		token += 1
		local mine = token
		if model then
			model:Destroy()
			model = nil
		end
		if not key then
			return
		end
		task.spawn(function()
			local built = ArtLoader.build(key, opts)
			if not built or mine ~= token or not vp.Parent then
				if built then
					built.model:Destroy()
				end
				return
			end
			for _, p in built.lod1 do
				p:Destroy() -- the preview always shows full detail
			end
			local vname: string = variant or "Normal"
			local v = (VARIANT_TINT :: { [string]: Color3 })[vname]
			local ashen, spectral = vname == "Ashen", vname == "Spectral"
			for logical, parts in built.parts do
				for _, p in parts do
					if logical == "Ember" and not ashen then
						p:Destroy()
					elseif v and p.Material ~= Enum.Material.Neon then
						p.Color = p.Color:Lerp(v, 0.65)
						if spectral then
							p.Transparency = math.max(p.Transparency, 0.35)
						end
					end
				end
			end
			local m = built.model
			m.Parent = world
			local cf, size = m:GetBoundingBox()
			centre = cf.Position
			radius = math.max(size.X, size.Y, size.Z) * 1.9 + 1
			model = m
			place()
		end)
	end

	return {
		set = set,
		destroy = function()
			token += 1
			conn:Disconnect()
			moveConn:Disconnect()
			vp:Destroy()
		end,
	}
end

return Preview
