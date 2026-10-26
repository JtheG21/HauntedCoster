--!strict
-- Studio text-fit gate (TASK-0098, MENU_TEXT_FIT_AUDIT.md section E). Studio only; never part of check.sh.
-- Run in a fresh Play session on the CLIENT (Server data model is wrong: the GUI lives on the client):
--   require(game.Players.LocalPlayer.PlayerScripts.StudioTests.TextFit).run()
-- Renders every built state (and each player stress fixture on the main menu) through client/Menu/Preview, then for every
-- visible text element: measures it with TextService:GetTextBoundsAsync, places it in its shard's local space and
-- calls TextFitRules.rectFits(profile, rect, 6). Also fails on clipped / wrapped / truncated text and on interactive
-- elements inside a keep-clear zone. Prints a table; the last line is TEXTFIT_RESULT.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudRules = require(Shared:WaitForChild("HudRules"))
local TextFitRules = require(Shared:WaitForChild("TextFitRules"))

local MARGIN = 6
local SLACK = 1 -- px of tolerance on keep-clear zones for rotated boxes
local SIZES: { { name: string, w: number, h: number } } = {
	{ name = "844x390", w = 844, h = 390 },
	{ name = "1920x1080", w = 1920, h = 1080 },
	{ name = "phone 812x375", w = 812, h = 375 },
}
-- x0, y0, x1, y1 on the 844x390 canvas.
local ZONES = {
	{ name = "top bar", x0 = 0, y0 = 0, x1 = 150, y1 = 44 },
	{ name = "jump", x0 = 664, y0 = 240, x1 = 844, y1 = 390 },
	{ name = "left inset", x0 = 0, y0 = 0, x1 = 44, y1 = 390 },
	{ name = "right inset", x0 = 800, y0 = 0, x1 = 844, y1 = 390 },
}

export type Row = { state: string, element: string, text: string, margin: string, pass: boolean, why: string }

local TextFit = {}

local function shapeOwner(inst: Instance): Frame?
	local node: Instance? = inst.Parent
	while node do
		if node:IsA("Frame") and node:GetAttribute("ShapeKey") ~= nil then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function visible(gui: GuiObject): boolean
	local node: Instance? = gui
	while node and not node:IsA("ScreenGui") do
		if node:IsA("GuiObject") and not node.Visible then
			return false
		end
		node = node.Parent
	end
	return gui.AbsoluteSize.X > 0
end

local function path(inst: Instance, stop: Instance): string
	local names: { string } = {}
	local node: Instance? = inst
	while node and node ~= stop do
		table.insert(names, 1, node.Name)
		node = node.Parent
	end
	return table.concat(names, "/")
end

local function measure(label: TextLabel | TextButton, factor: number): (number, number)
	local lineHeight = (label :: any).LineHeight :: number
	if label.TextScaled or lineHeight ~= 1 then
		-- GetTextBoundsParams has no LineHeight and cannot know the scaled size; the rendered bounds are exact.
		return label.TextBounds.X / factor, label.TextBounds.Y / factor
	end
	local params = Instance.new("GetTextBoundsParams")
	params.Text, params.Font, params.Size = label.Text, label.FontFace, label.TextSize
	params.Width = if label.TextWrapped then label.AbsoluteSize.X / factor else 100000
	local bounds = TextService:GetTextBoundsAsync(params)
	return bounds.X, bounds.Y
end

local function bestMargin(profile: TextFitRules.Profile, rect: TextFitRules.Rect, w: number, h: number): string
	local best: number? = nil
	for step = 0, 24 do
		if TextFitRules.rectFits(profile, rect, step * 0.5, w, h) then
			best = step * 0.5
		else
			break
		end
	end
	return if best then string.format("%.1f", best) else "<0"
end

local function rotatedBox(inst: GuiObject, root: Frame, scale: number): (number, number, number, number)
	local center = (inst.AbsolutePosition + inst.AbsoluteSize / 2 - root.AbsolutePosition) / scale
	local half = inst.AbsoluteSize / 2 / scale
	local rotation = 0
	local node: Instance? = inst
	while node and node ~= root.Parent do
		if node:IsA("GuiObject") then
			rotation += node.Rotation
		end
		node = node.Parent
	end
	local r = math.rad(rotation)
	local ex = math.abs(math.cos(r)) * half.X + math.abs(math.sin(r)) * half.Y
	local ey = math.abs(math.sin(r)) * half.X + math.abs(math.cos(r)) * half.Y
	return center.X - ex, center.Y - ey, center.X + ex, center.Y + ey
end

local function checkGui(gui: ScreenGui, state: string, rows: { Row })
	local root = gui:FindFirstChild("Root") :: Frame
	local uiScale = root:FindFirstChildOfClass("UIScale") :: UIScale
	local scale = uiScale.Scale
	for _, d in root:GetDescendants() do
		if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) then
			continue
		end
		local label = d :: TextLabel
		if d:GetAttribute("FitEdge") or not visible(label) then
			continue
		end
		local name = path(d, root)
		-- Interactive elements: keep-clear zones.
		if d:IsA("TextButton") then
			local x0, y0, x1, y1 = rotatedBox(label, root, scale)
			local hit = ""
			for _, zone in ZONES do
				if x0 < zone.x1 - SLACK and x1 > zone.x0 + SLACK and y0 < zone.y1 - SLACK and y1 > zone.y0 + SLACK then
					-- A box that only grazes a side inset by SLACK is fine; otherwise name the zone.
					hit = zone.name
				end
			end
			local small = (label.AbsoluteSize.X / scale < 43.5) or (label.AbsoluteSize.Y / scale < 43.5)
			if d.Name:sub(1, 3) == "Hit" then
				table.insert(rows, {
					state = state,
					element = name .. " [target]",
					text = string.format(
						"%dx%d",
						label.AbsoluteSize.X / scale + 0.5,
						label.AbsoluteSize.Y / scale + 0.5
					),
					margin = "-",
					pass = hit == "" and not small,
					why = if hit ~= "" then "inside keep-clear: " .. hit elseif small then "target under 44x44" else "",
				})
			end
		end
		if label.Text == "" then
			continue
		end
		local owner = shapeOwner(label)
		local bw, bh = measure(label, scale)
		local lw, lh = label.AbsoluteSize.X / scale, label.AbsoluteSize.Y / scale
		local problems: { string } = {}
		local allowTruncate = label:GetAttribute("AllowTruncate") == true
		local autoSized = label.AutomaticSize ~= Enum.AutomaticSize.None
		if not autoSized then
			if bw > lw + 0.5 and not allowTruncate then
				table.insert(problems, string.format("text %.0f wider than label %.0f", bw, lw))
			end
			if bh > lh + 0.5 then
				table.insert(problems, string.format("text %.0f taller than label %.0f", bh, lh))
			end
		end
		if label.TextTruncate ~= Enum.TextTruncate.None and bw > lw + 0.5 and not allowTruncate then
			table.insert(problems, "TextTruncate fires on a non-name label")
		end
		local marginText = "-"
		if owner and label:GetAttribute("FitSticker") ~= true then
			local key = owner:GetAttribute("ShapeKey") :: string
			local profile = TextFitRules.profile(key)
			local ow = owner:GetAttribute("ShapeW") :: number
			local oh = owner:GetAttribute("ShapeH") :: number
			local k = owner.AbsoluteSize.X / ow
			local lx = (label.AbsolutePosition.X - owner.AbsolutePosition.X) / k
			local ly = (label.AbsolutePosition.Y - owner.AbsolutePosition.Y) / k
			local rect: TextFitRules.Rect
			if label.BackgroundTransparency < 1 or autoSized then
				rect = { x0 = lx, y0 = ly, x1 = lx + lw, y1 = ly + lh } -- the visible box (tags)
			else
				local x = lx
				if label.TextXAlignment == Enum.TextXAlignment.Center then
					x = lx + (lw - math.min(bw, lw)) / 2
				elseif label.TextXAlignment == Enum.TextXAlignment.Right then
					x = lx + lw - math.min(bw, lw)
				end
				local y = ly
				if label.TextYAlignment == Enum.TextYAlignment.Center then
					y = ly + (lh - bh) / 2
				elseif label.TextYAlignment == Enum.TextYAlignment.Bottom then
					y = ly + lh - bh
				end
				rect = { x0 = x, y0 = y, x1 = x + math.min(bw, lw), y1 = y + bh }
			end
			if profile then
				if not TextFitRules.rectFits(profile, rect, MARGIN, ow, oh) then
					table.insert(problems, "margin under " .. MARGIN .. " to the shard edge")
				end
				marginText = bestMargin(profile, rect, ow, oh)
			else
				table.insert(problems, "no ShapeProfile for " .. key)
			end
		elseif label:GetAttribute("FitSticker") == true then
			marginText = "sticker"
		end
		table.insert(rows, {
			state = state,
			element = name,
			text = label.Text:gsub("\n", " / "),
			margin = marginText,
			pass = #problems == 0,
			why = table.concat(problems, "; "),
		})
	end
end

-- Runs every state and fixture at each viewport scale. Returns (rows, failures).
function TextFit.run(): ({ Row }, number)
	if not RunService:IsStudio() then
		return {}, 0
	end
	local Preview =
		require(Players.LocalPlayer.PlayerScripts:WaitForChild("Client"):WaitForChild("Menu"):WaitForChild("Preview"))
	local rows: { Row } = {}
	for _, size in SIZES do
		for _, state in Preview.States do
			local fixtures: { string? } = { nil }
			if state.screen == "main" then
				fixtures = {}
				for name in Preview.PlayerFixtures do
					table.insert(fixtures, name :: string)
				end
				table.sort(fixtures :: { string })
			end
			for _, fixture in fixtures do
				local view = Preview.show(state.id, fixture)
				if view then
					-- Emulate the viewport: the root scales to min(w / 844, h / 390) exactly as on that device.
					local uiScale = view.root:FindFirstChildOfClass("UIScale") :: UIScale
					uiScale.Scale = HudRules.rootScale(size.w, size.h)
					task.wait() -- let AbsoluteSize / TextBounds settle
					local label = size.name .. " " .. state.id .. (if fixture then " [" .. fixture .. "]" else "")
					checkGui(view.gui, label, rows)
				end
			end
		end
	end
	Preview.clear()
	local failures = 0
	print("[TextFit] state | element | text | margin | result")
	for _, row in rows do
		if not row.pass then
			failures += 1
		end
		print(
			string.format(
				"[TextFit] %s | %s | %s | %s | %s %s",
				row.state,
				row.element,
				row.text,
				row.margin,
				row.pass and "PASS" or "FAIL",
				row.why
			)
		)
	end
	print(`TEXTFIT_RESULT rows={#rows} failures={failures}`)
	return rows, failures
end

return TextFit
