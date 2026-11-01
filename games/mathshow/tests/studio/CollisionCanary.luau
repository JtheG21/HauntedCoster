--!strict
-- Planted-fault fixtures for the TextFit collision gate (TASK-0115). They live in tests/studio, built from plain Instances,
-- so nothing here ships in the menu path. The gate must flag the two faults and pass the composition control, or the gate
-- itself fails: a collision check that cannot fail proves nothing.

local CollisionCanary = {}

export type Fixture = { id: string, expectFail: boolean, why: string }

CollisionCanary.fixtures = {
	{ id = "canary-overlap", expectFail = true, why = "control A's shard overlaps control B's shard" },
	{
		id = "canary-label-on-foreign-shard",
		expectFail = true,
		why = "control A's label sits over control B's shard",
	},
	{ id = "canary-composition", expectFail = false, why = "a control's label over its own shard" },
} :: { Fixture }

local function control(parent: Instance, name: string, x: number, y: number, w: number, h: number, text: string)
	local root = Instance.new("Frame")
	root.Name = name
	root.Position = UDim2.fromOffset(x, y)
	root.Size = UDim2.fromOffset(w, h)
	root.BackgroundTransparency = 1
	root.Parent = parent
	local group = Instance.new("CanvasGroup")
	group.Name = "Group"
	group.Size = UDim2.fromScale(1, 1)
	group.BackgroundTransparency = 1
	group.Parent = root
	local shard = Instance.new("ImageLabel")
	shard.Name = "Shard"
	shard.Size = UDim2.fromScale(1, 1)
	shard.BackgroundColor3 = Color3.fromRGB(60, 80, 140)
	shard.BackgroundTransparency = 0.05
	shard.Parent = group
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.fromScale(1, 1)
	content.BackgroundTransparency = 1
	content.Parent = group
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextSize = 18
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = content
	return label
end

-- Builds the fixture under a fresh ScreenGui > Root (844x390 design canvas with a UIScale) and returns the gui.
function CollisionCanary.build(id: string, playerGui: Instance): ScreenGui
	local gui = Instance.new("ScreenGui")
	gui.Name = "CollisionCanary"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	local root = Instance.new("Frame")
	root.Name = "Root"
	root.Size = UDim2.fromOffset(844, 390)
	root.BackgroundTransparency = 1
	root.Parent = gui
	local uiScale = Instance.new("UIScale")
	uiScale.Parent = root
	local screen = Instance.new("Frame")
	screen.Name = id
	screen.Size = UDim2.fromScale(1, 1)
	screen.BackgroundTransparency = 1
	screen.Parent = root
	if id == "canary-overlap" then
		control(screen, "A", 60, 120, 200, 80, "A")
		control(screen, "B", 160, 140, 200, 80, "B")
	elseif id == "canary-label-on-foreign-shard" then
		local label = control(screen, "A", 40, 120, 200, 80, "FOREIGN LABEL")
		label.Position = UDim2.fromOffset(200, 0)
		label.Size = UDim2.fromOffset(160, 80)
		label.TextXAlignment = Enum.TextXAlignment.Left
		control(screen, "B", 270, 120, 200, 80, "B")
	else
		control(screen, "A", 60, 120, 200, 80, "A")
		control(screen, "C", 500, 120, 200, 80, "C")
	end
	gui.Parent = playerGui
	return gui
end

return CollisionCanary
