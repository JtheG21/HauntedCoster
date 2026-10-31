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
-- TASK-0114. Tap minimum is in screen points, with no root-scale division. Other checks are in design px unless noted.
local TAP_MIN = 44
local REVIEW_GAP_MIN = 2 -- review rows: gap between neighbours, design px
local CLIP_TOL = 0.5 -- ancestor overflow tolerated, design px
local OVERLAP_EPS = 0.01 -- positive-area test for interactive overlap
local SCREEN_MARGIN_MIN = 6 -- informational: text margin in screen px
-- Interactive pairs allowed to overlap, by state and control name. The reason is written to the ledger.
local ALLOW_OVERLAP_NAMES = { Hit = true, HitMinus = true, HitPlus = true, Minus = true, Plus = true }
local SIZES: { { name: string, w: number, h: number } } = {
	{ name = "844x390", w = 844, h = 390 },
	{ name = "1920x1080", w = 1920, h = 1080 },
	{ name = "phone 812x375", w = 812, h = 375 },
	{ name = "1024x768", w = 1024, h = 768 },
	{ name = "1180x820", w = 1180, h = 820 },
}
-- x0, y0, x1, y1 on the 844x390 canvas.
local ZONES = {
	{ name = "top bar", x0 = 0, y0 = 0, x1 = 150, y1 = 44 },
	{ name = "jump", x0 = 664, y0 = 240, x1 = 844, y1 = 390 },
	{ name = "left inset", x0 = 0, y0 = 0, x1 = 44, y1 = 390 },
	{ name = "right inset", x0 = 800, y0 = 0, x1 = 844, y1 = 390 },
}

export type Row = {
	state: string,
	element: string,
	text: string,
	margin: string,
	pass: boolean,
	why: string,
	class: string?,
	category: string?,
}

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
			local small = label.AbsoluteSize.X < TAP_MIN or label.AbsoluteSize.Y < TAP_MIN
			if d.Name:sub(1, 3) == "Hit" then
				table.insert(rows, {
					state = state,
					element = name .. " [target]",
					text = string.format("%dx%d", label.AbsoluteSize.X + 0.5, label.AbsoluteSize.Y + 0.5),
					margin = "-",
					pass = hit == "" and not small,
					why = if hit ~= ""
						then "inside keep-clear: " .. hit
						elseif small then "tap under 44 screen px"
						else "",
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
			-- Centre-to-centre offset, un-rotated by the shard's own rotation: AbsolutePosition alone drifts by
			-- up to 2 px on a tilted row because ancestors rotate the child's position but not its box.
			local theta = math.rad(owner.AbsoluteRotation)
			local dx = (label.AbsolutePosition.X + label.AbsoluteSize.X / 2)
				- (owner.AbsolutePosition.X + owner.AbsoluteSize.X / 2)
			local dy = (label.AbsolutePosition.Y + label.AbsoluteSize.Y / 2)
				- (owner.AbsolutePosition.Y + owner.AbsoluteSize.Y / 2)
			local cx = (dx * math.cos(theta) + dy * math.sin(theta)) / k
			local cy = (-dx * math.sin(theta) + dy * math.cos(theta)) / k
			local lx = ow / 2 + cx - lw / 2
			local ly = oh / 2 + cy - lh / 2
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

local function isRelated(a: Instance, b: Instance): boolean
	return a:IsDescendantOf(b) or b:IsDescendantOf(a)
end

-- The nearest ancestor with the given name, below root.
local function ancestorNamed(inst: Instance, root: Frame, name: string): Instance?
	local n: Instance? = inst.Parent
	while n and n ~= root do
		if n.Name == name then
			return n
		end
		n = n.Parent
	end
	return nil
end

-- Where the glyphs of a text label actually sit (design px), so a long, centred label does not count as its full box.
local function glyphBox(lab: TextLabel, root: Frame, scale: number): { number }
	local x0, y0, x1, y1 = rotatedBox(lab, root, scale)
	if lab.Text == "" then
		return { x0, y0, x1, y1 }
	end
	local bw, bh = measure(lab, scale)
	local lw, lh = x1 - x0, y1 - y0
	local w, h = math.min(bw, lw), math.min(bh, lh)
	local gx = x0
	if lab.TextXAlignment == Enum.TextXAlignment.Center then
		gx = x0 + (lw - w) / 2
	elseif lab.TextXAlignment == Enum.TextXAlignment.Right then
		gx = x1 - w
	end
	local gy = y0
	if lab.TextYAlignment == Enum.TextYAlignment.Center then
		gy = y0 + (lh - h) / 2
	elseif lab.TextYAlignment == Enum.TextYAlignment.Bottom then
		gy = y1 - h
	end
	return { gx, gy, gx + w, gy + h }
end

local function overlapBox(a: { number }, b: { number }): { number }
	return { math.max(a[1], b[1]), math.max(a[2], b[2]), math.min(a[3], b[3]), math.min(a[4], b[4]) }
end

local function fmtBox(b: { number }): string
	return string.format("(%.1f,%.1f %.1fx%.1f)", b[1], b[2], b[3] - b[1], b[4] - b[2])
end

-- Largest overflow of `box` past any ClipsDescendants ancestor, and that ancestor's path.
local function ancestorClip(inst: GuiObject, root: Frame, box: { number }, scale: number): (number, string)
	local worst, where = 0, ""
	local node: Instance? = inst.Parent
	while node and node ~= root.Parent do
		if node:IsA("GuiObject") and node.ClipsDescendants then
			local a0, b0, a1, b1 = rotatedBox(node, root, scale)
			local over = math.max(a0 - box[1], box[3] - a1, b0 - box[2], box[4] - b1)
			if over > worst then
				worst = over
				where = path(node, root)
			end
		end
		node = node.Parent
	end
	return worst, where
end

-- TASK-0114 checks, appended to the rows from checkGui for one state (rows[from..]). Each new row has a category, so the
-- ledger can tell it apart from the historical 284 unmeasured rows per viewport.
local function auxChecks(gui: ScreenGui, state: string, rows: { Row }, scale: number, from: number)
	local root = gui:FindFirstChild("Root") :: Frame
	local interactive: { { inst: GuiObject, box: { number } } } = {}
	local labelBoxes: { { inst: TextLabel, box: { number }, owner: Frame? } } = {}

	-- 1. Tap size, every visible GuiButton plus Answer TextBoxes. checkGui already covers TextButtons named Hit*.
	for _, d in root:GetDescendants() do
		local isButton = d:IsA("GuiButton")
		local isAnswer = d:IsA("TextBox") and string.find(d.Name, "Answer", 1, true) ~= nil
		if (isButton or isAnswer) and visible(d :: GuiObject) then
			local g = d :: GuiObject
			local x0, y0, x1, y1 = rotatedBox(g, root, scale)
			table.insert(interactive, { inst = g, box = { x0, y0, x1, y1 } })
			if not (d:IsA("TextButton") and string.sub(d.Name, 1, 3) == "Hit") then
				local sw, sh = g.AbsoluteSize.X, g.AbsoluteSize.Y
				local ok = sw >= TAP_MIN and sh >= TAP_MIN
				table.insert(rows, {
					state = state,
					element = path(g, root) .. " [tap]",
					text = string.format("%dx%d", sw + 0.5, sh + 0.5),
					margin = "-",
					pass = ok,
					why = if ok then "" else "tap under 44 screen px",
					class = d.ClassName,
					category = "tap",
				})
			end
		end
	end

	-- 2. Interactive overlap: positive-area intersection between unrelated controls, rotation-aware (conservative AABB).
	for i = 1, #interactive do
		for j = i + 1, #interactive do
			local A, B = interactive[i], interactive[j]
			if not isRelated(A.inst, B.inst) then
				local ov = overlapBox(A.box, B.box)
				if ov[3] - ov[1] > OVERLAP_EPS and ov[4] - ov[2] > OVERLAP_EPS then
					local pa, pb = path(A.inst, root), path(B.inst, root)
					local allowed = string.find(state, "settings", 1, true) ~= nil
						and ALLOW_OVERLAP_NAMES[A.inst.Name] == true
						and ALLOW_OVERLAP_NAMES[B.inst.Name] == true
						and string.find(pa, "Row", 1, true) ~= nil
						and string.find(pb, "Row", 1, true) ~= nil
					table.insert(rows, {
						state = state,
						element = pa .. " x " .. pb,
						text = fmtBox(ov),
						margin = "-",
						pass = allowed,
						why = if allowed then "allow-list: gamepad selection surface" else "interactive overlap",
						class = A.inst.ClassName .. "/" .. B.inst.ClassName,
						category = if allowed then "overlap-allow" else "overlap",
					})
				end
			end
		end
	end

	-- 3. Ancestor clipping for stickers and off-shard labels, plus collect them for the collision check.
	for _, d in root:GetDescendants() do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and visible(d :: GuiObject) then
			local lab = d :: TextLabel
			local sticker = lab:GetAttribute("FitSticker") == true
			local owner = shapeOwner(lab)
			if (lab.Text ~= "" or sticker) and (owner == nil or sticker) then
				local x0, y0, x1, y1 = rotatedBox(lab, root, scale)
				local box = { x0, y0, x1, y1 }
				local over, where = ancestorClip(lab, root, box, scale)
				local ok = over <= CLIP_TOL
				table.insert(rows, {
					state = state,
					element = path(lab, root),
					text = lab.Text:gsub("\n", " / "),
					margin = "-",
					pass = ok,
					why = if ok then "" else string.format("clipped %.1f px by %s", over, where),
					class = lab.ClassName,
					category = "clip",
				})
				table.insert(labelBoxes, { inst = lab, box = glyphBox(lab, root, scale), owner = owner })
			end
		end
	end

	-- 4. Sticker and off-shard label collisions with unrelated visible content. Shard backgrounds (ImageLabels inside a
	-- shard) are intentional composition and are skipped.
	for _, L in labelBoxes do
		for _, d in root:GetDescendants() do
			local isText = (d:IsA("TextLabel") or d:IsA("TextButton")) and (d :: TextLabel).Text ~= ""
			local isImage = d:IsA("ImageLabel") or d:IsA("ImageButton")
			if (isText or isImage) and visible(d :: GuiObject) and not isRelated(L.inst, d) then
				local decor = isImage and shapeOwner(d) ~= nil
				if not decor then
					local g = d :: GuiObject
					local cbox
					if isText then
						cbox = glyphBox(d :: TextLabel, root, scale)
					else
						local x0, y0, x1, y1 = rotatedBox(g, root, scale)
						cbox = { x0, y0, x1, y1 }
					end
					local ov = overlapBox(L.box, cbox)
					if
						ov[3] - ov[1] > OVERLAP_EPS
						and ov[4] - ov[2] > OVERLAP_EPS
						and (ov[3] - ov[1]) * (ov[4] - ov[2]) > 0.5
					then
						-- Intentional composition is passed and labelled; anything else is a collision.
						local pl, pg = path(L.inst, root), path(g, root)
						local gl, gg = ancestorNamed(L.inst, root, "Group"), ancestorNamed(g, root, "Group")
						local cl, cg = ancestorNamed(L.inst, root, "Card"), ancestorNamed(g, root, "Card")
						local reason = ""
						if string.find(pl, "Edge", 1, true) or string.find(pg, "Edge", 1, true) then
							reason = "intentional: screen-edge decor"
						elseif gl ~= nil and gl == gg then
							reason = "intentional: sticker or label on its own control"
						elseif cl ~= nil and cl == cg and L.inst.Name == "NewBest" then
							reason = "intentional: badge on its own card"
						elseif isText and (d :: TextLabel).Text == L.inst.Text and d.Name == L.inst.Name then
							reason = "intentional: duplicate text layer (shadow or glow)"
						elseif L.inst.Name == "Vs" then
							reason = "intentional: VS badge across the panel seam"
						end
						table.insert(rows, {
							state = state,
							element = pl .. " x " .. pg,
							text = fmtBox(ov),
							margin = "-",
							pass = reason ~= "",
							why = if reason ~= ""
								then reason
								else "sticker or off-shard label overlaps unrelated content",
							class = L.inst.ClassName .. "/" .. d.ClassName,
							category = "collision",
						})
					end
				end
			end
		end
	end

	-- 5. Review rows: gap between neighbouring Row<n> controls, per column. Diagnostic, with a gate at REVIEW_GAP_MIN.
	local groups: { [string]: { { inst: GuiObject, box: { number }, parent: Instance } } } = {}
	for _, d in root:GetDescendants() do
		if d:IsA("GuiObject") and string.match(d.Name, "^Row%d+$") and visible(d :: GuiObject) and d.Parent then
			local x0, y0, x1, y1 = rotatedBox(d :: GuiObject, root, scale)
			local key = tostring(d.Parent:GetFullName()) .. " @" .. string.format("%.0f", x0)
			local list = groups[key] or {}
			table.insert(list, { inst = d :: GuiObject, box = { x0, y0, x1, y1 }, parent = d.Parent })
			groups[key] = list
		end
	end
	for _, list in groups do
		if #list >= 2 then
			local parent = list[1].parent
			table.sort(list, function(a, b)
				return a.box[2] < b.box[2]
			end)
			for k = 2, #list do
				local prev, cur = list[k - 1], list[k]
				local gap = cur.box[2] - prev.box[4]
				local ok = gap >= REVIEW_GAP_MIN
				table.insert(rows, {
					state = state,
					element = path(parent, root) .. " " .. prev.inst.Name .. "->" .. cur.inst.Name,
					text = string.format("gap %.1f px", gap),
					margin = "-",
					pass = ok,
					why = if ok then "" else string.format("review rows touch: gap %.1f < %d", gap, REVIEW_GAP_MIN),
					class = "Row",
					category = "review-gap",
				})
			end
		end
	end

	-- 6. Informational: text margin in screen px. Rows under SCREEN_MARGIN_MIN are listed, never failed.
	for k = from, #rows do
		local m = tonumber(rows[k].margin)
		if m and m * scale < SCREEN_MARGIN_MIN then
			table.insert(rows, {
				state = state,
				element = rows[k].element,
				text = rows[k].text,
				margin = string.format("%.1f screen px", m * scale),
				pass = true,
				why = "would fail under screen-px rule (informational)",
				class = rows[k].class,
				category = "info-screen-px",
			})
		end
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
			local fixtures: { string } = { "" } -- "" = the state's own model
			if state.screen == "main" then
				fixtures = {}
				for name in Preview.PlayerFixtures do
					table.insert(fixtures, name :: string)
				end
				table.sort(fixtures)
			end
			for _, fixture in fixtures do
				local view = Preview.show(state.id, if fixture == "" then nil else fixture)
				if view then
					-- Emulate the viewport: the root scales to min(w / 844, h / 390) exactly as on that device.
					local uiScale = view.root:FindFirstChildOfClass("UIScale") :: UIScale
					uiScale.Scale = HudRules.rootScale(size.w, size.h)
					task.wait() -- let AbsoluteSize / TextBounds settle
					local label = size.name .. " " .. state.id .. (if fixture ~= "" then " [" .. fixture .. "]" else "")
					local from = #rows + 1
					checkGui(view.gui, label, rows)
					auxChecks(view.gui, label, rows, uiScale.Scale, from)
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
	-- TASK-0114 ledger summary per viewport. "unmeasured" is the historical set (checkGui rows with margin "-" or "sticker").
	local tally: { [string]: { [string]: number } } = {}
	local smallest: { [string]: string } = {}
	local smallestV: { [string]: number } = {}
	for _, row in rows do
		local size = "?"
		for _, sz in SIZES do
			if string.sub(row.state, 1, #sz.name) == sz.name then
				size = sz.name
				break
			end
		end
		local cat: string = row.category
			or (
				if tonumber(row.margin)
					then "measured"
					elseif row.margin == "sticker" or row.margin == "-" then "unmeasured"
					else "other"
			)
		if tally[size] == nil then
			tally[size] = {}
		end
		local counts: { [string]: number } = tally[size]
		counts[cat] = (counts[cat] or 0) + 1
		if not row.pass then
			local key = "FAIL " .. cat
			counts[key] = (counts[key] or 0) + 1
		end
		if cat == "tap" or string.find(row.element, "[target]", 1, true) then
			local w, h = string.match(row.text, "(%d+)x(%d+)")
			if w and h then
				local v = math.min(tonumber(w) :: number, tonumber(h) :: number)
				if smallestV[size] == nil or v < smallestV[size] then
					smallestV[size] = v
					smallest[size] = row.element .. " " .. row.text
				end
			end
		end
	end
	for _, sz in SIZES do
		local t: { [string]: number } = tally[sz.name] or {}
		local keys: { string } = {}
		for k in t do
			table.insert(keys, k)
		end
		table.sort(keys)
		local parts: { string } = {}
		for _, k in keys do
			table.insert(parts, k .. "=" .. tostring(t[k]))
		end
		print("[TextFit] LEDGER " .. sz.name .. " | " .. table.concat(parts, " "))
		if smallest[sz.name] then
			print("[TextFit] SMALLEST TAP " .. sz.name .. " | " .. smallest[sz.name])
		end
	end
	print(`TEXTFIT_RESULT rows={#rows} failures={failures}`)
	return rows, failures
end

return TextFit
