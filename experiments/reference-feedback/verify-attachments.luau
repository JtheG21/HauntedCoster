--!strict
-- Client-side regression check using actual laid-out GuiObject bounds.
-- Prior top-anchored angled thread fails by ~6 px in portrait.
local pg = game:GetService("Players").LocalPlayer.PlayerGui
local art = pg.ReferenceFeedbackDemo:FindFirstChild("PaintedHalloweenFrame", true) :: ImageLabel
local branch = art:FindFirstChild("RootedTree") :: ImageLabel
local function rotate(point: Vector2, degrees: number): Vector2
	local angle = math.rad(degrees)
	return Vector2.new(
		point.X * math.cos(angle) - point.Y * math.sin(angle),
		point.X * math.sin(angle) + point.Y * math.cos(angle)
	)
end
local maxTop, maxBottom, minRotation, maxRotation = 0, 0, math.huge, -math.huge
for _ = 1, 100 do
	task.wait(0.1)
	local narrow = art:GetAttribute("Variant") == "portrait"
	local branchCenter = branch.AbsolutePosition + branch.AbsoluteSize / 2
	minRotation = math.min(minRotation, branch.Rotation)
	maxRotation = math.max(maxRotation, branch.Rotation)
	for i = 1, 2 do
		local u = if i == 1 then 0.085 else (if narrow then 0.75 else 0.90)
		local v = if i == 1 then 0.17 else (if narrow then 0.13 else 0.085)
		local bark = branchCenter
			+ rotate(Vector2.new((u - 0.5) * branch.AbsoluteSize.X, (v - 0.5) * branch.AbsoluteSize.Y), branch.Rotation)
		local line = art:FindFirstChild("SpiderThread" .. i) :: Frame
		local center = line.AbsolutePosition + line.AbsoluteSize / 2
		local top = center + rotate(Vector2.new(0, -line.AbsoluteSize.Y / 2), line.Rotation)
		local bottom = center + rotate(Vector2.new(0, line.AbsoluteSize.Y / 2), line.Rotation)
		local spider = art:FindFirstChild("WebSpider" .. i) :: ImageLabel
		local intendedHead = spider.AbsolutePosition + spider.AbsoluteSize / 2 - Vector2.new(0, 8)
		maxTop = math.max(maxTop, (top - bark).Magnitude)
		maxBottom = math.max(maxBottom, (bottom - intendedHead).Magnitude)
	end
end
assert(maxTop < 1.5 and maxBottom < 1.5, "Rendered thread attachment drift exceeds layout rounding tolerance")
return {
	maxBarkError = maxTop,
	maxSpiderError = maxBottom,
	minRotation = minRotation,
	maxRotation = maxRotation,
	variant = art:GetAttribute("Variant"),
}
