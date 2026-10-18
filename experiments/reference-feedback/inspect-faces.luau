--!strict
-- Run in this standalone demo's Client through Studio MCP. Visual evidence, not an automatic pass.
local pg = game:GetService("Players").LocalPlayer.PlayerGui
local art = pg.ReferenceFeedbackDemo:FindFirstChild("PaintedHalloweenFrame", true) :: ImageLabel
local emission = art:FindFirstChild("CarvedPumpkinGlow") :: ImageLabel
local old = pg:FindFirstChild("FaceQualityInspection")
if old then
	old:Destroy()
end
local narrow = art:GetAttribute("Variant") == "portrait"
local size = if narrow then Vector2.new(576, 768) else Vector2.new(768, 682)
local rects: { { number } } = if narrow
	then { { 0.09, 0.09, 0.18, 0.13 }, { 0.02, 0.82, 0.25, 0.18 }, { 0.74, 0.82, 0.25, 0.18 } }
	else { { 0.05, 0.09, 0.25, 0.20 }, { 0.02, 0.75, 0.25, 0.23 }, { 0.74, 0.75, 0.25, 0.23 } }
local gui = Instance.new("ScreenGui")
gui.Name = "FaceQualityInspection"
gui.DisplayOrder = 100
gui.IgnoreGuiInset = true
local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(26, 19, 30)
bg.Parent = gui
for row = 0, 1 do
	for i, rect in rects do
		local image = Instance.new("ImageLabel")
		image.BackgroundTransparency = 1
		image.Position = UDim2.fromScale((i - 1) / 3 + 0.012, row * 0.5 + 0.035)
		image.Size = UDim2.fromScale(0.31, 0.43)
		image.ImageContent = art.ImageContent
		image.ImageRectOffset = Vector2.new(math.floor(rect[1] * size.X), math.floor(rect[2] * size.Y))
		image.ImageRectSize = Vector2.new(math.floor(rect[3] * size.X), math.floor(rect[4] * size.Y))
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = bg
		local glow = image:Clone()
		glow.ImageContent = emission.ImageContent
		glow.ImageTransparency = if row == 0 then 0.97 else 0.03
		glow.Parent = bg
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = 18
		label.Text = (if row == 0 then "DIM " else "LIT ") .. ({ "WITCH", "LEFT", "RIGHT" })[i]
		label.Position = UDim2.fromScale((i - 1) / 3, row * 0.5)
		label.Size = UDim2.fromScale(1 / 3, 0.04)
		label.Parent = bg
	end
end
gui.Parent = pg
return "Inspect eyes, nose, complete smile, edges and source ornament alignment. Destroy FaceQualityInspection after capture."
