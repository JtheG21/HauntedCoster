--!strict
-- Collection journal: known/unknown monsters and variants, clues, landmark progress and trophies.
-- Completion only gives cosmetic trophies on the mansion plot.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config")
local Monsters = require(Config:WaitForChild("Monsters"))
local Variants = require(Config:WaitForChild("Variants"))
local World = require(Config:WaitForChild("World"))
local Theme = require(script.Parent.Theme)
local State = require(script.Parent.Parent.State)

local JournalUI = {}

local panel: Frame
local content: ScrollingFrame
local lastSig = ""

local TRAIN_BELL_CLUE = "After your first ride, a bell tolled from the graveyard. Investigate the Bell Tower."

local function clear()
	for _, c in content:GetChildren() do
		if not c:IsA("UIListLayout") then
			c:Destroy()
		end
	end
end

local function card(): Frame
	local f = Theme.frame(content, {
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Theme.Colors.panel2,
	})
	Theme.corner(f, 8)
	Theme.pad(f, 8)
	Theme.list(f, 3)
	return f
end

local function text(parent: Instance, s: string, props: { [string]: any }?)
	local p: { [string]: any } = { AutomaticSize = Enum.AutomaticSize.Y, Size = UDim2.fromScale(1, 0), TextSize = 14 }
	for k, v in (props or {}) :: { [string]: any } do
		p[k] = v
	end
	return Theme.label(parent, s, p)
end

local function render(force: boolean?)
	if not panel.Visible then
		return
	end
	local snap = State.snap
	if not snap or not snap.journal then
		return
	end
	local j = snap.journal
	local sig = table.concat({
		tostring(#(snap.owned or {})),
		tostring(snap.landmarkCount),
		tostring(next(j.seen) ~= nil),
	}, ":")
	for k in j.seen do
		sig ..= k
	end
	for k in j.variants do
		sig ..= k
	end
	for k in j.clues do
		sig ..= k
	end
	if sig == lastSig and not force then
		return
	end
	lastSig = sig
	clear()

	local caught, seen = 0, 0
	for _, id in Monsters.Order do
		if j.caught[id] then
			caught += 1
		end
		if j.seen[id] then
			seen += 1
		end
	end
	local summary = card()
	text(
		summary,
		`Caught {caught}/{#Monsters.Order} species  ·  Seen {seen}  ·  Landmarks {snap.landmarkCount or 0}/{#World.Landmarks}`,
		{ Font = Theme.Bold, TextSize = 16 }
	)
	text(summary, "Trophies for milestones appear on your plot (cosmetic only).", { TextColor3 = Theme.Colors.dim })

	for _, id in Monsters.Order do
		local s = Monsters.Species[id]
		local c = card()
		if j.seen[id] then
			text(c, `{s.name}{if j.caught[id] then "  (caught)" else "  (seen)"}`, {
				Font = Theme.Title,
				TextSize = 22,
				TextColor3 = Monsters.RarityColor[s.rarity],
			})
			text(c, `{s.family} · {s.rarity} · {s.incomePerSecond}/s base`)
			text(c, s.blurb, { TextColor3 = Theme.Colors.dim })
			local found = {}
			for _, v in Variants.List do
				local allowed = v.zones == nil or id == "Gentleman" or id == "BellWraith"
				if allowed then
					table.insert(found, if j.variants[id .. ":" .. v.id] then v.label else "???")
				end
			end
			text(c, `Variants: {table.concat(found, ", ")}`, { TextColor3 = Theme.Colors.clue })
		else
			text(c, "??? Unknown creature", { Font = Theme.Title, TextSize = 22, TextColor3 = Theme.Colors.dim })
			local lm = World.landmarkById(s.clueLandmark)
			if lm and j.clues[lm.id] then
				text(c, `Clue: {lm.clue}`, { TextColor3 = Theme.Colors.clue })
			else
				text(c, `Rarity: {s.rarity}. Investigate the {lm and lm.name or "landmarks"} to learn more.`)
			end
		end
	end

	local clues = card()
	text(clues, "Clues", { Font = Theme.Title, TextSize = 22, TextColor3 = Theme.Colors.gold })
	local any = false
	for _, lm in World.Landmarks do
		if j.clues[lm.id] then
			any = true
			text(clues, `{lm.name}: {lm.clue}`)
		else
			text(clues, `{lm.name}: not investigated`, { TextColor3 = Theme.Colors.dim })
		end
	end
	if j.clues.TrainBell then
		any = true
		text(clues, TRAIN_BELL_CLUE, { TextColor3 = Theme.Colors.clue })
	end
	if not any then
		text(clues, "Investigate landmarks in the graveyard to record clues.", { TextColor3 = Theme.Colors.dim })
	end
end

function JournalUI.open()
	panel.Visible = true
	render(true)
	task.spawn(State.invoke, "Ack", "journal")
end

function JournalUI.close()
	panel.Visible = false
end

function JournalUI.toggle()
	if panel.Visible then
		JournalUI.close()
	else
		JournalUI.open()
	end
end

function JournalUI.mount(gui: ScreenGui)
	panel = Theme.panel(gui, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 520, 0.75, 0),
		Visible = false,
		ZIndex = 5,
	})
	local size = Instance.new("UISizeConstraint")
	size.MaxSize = Vector2.new(520, 600)
	size.MinSize = Vector2.new(300, 260)
	size.Parent = panel
	Theme.pad(panel, 12)
	Theme.label(
		panel,
		"Monster Journal",
		{ Font = Theme.Title, TextSize = 30, Size = UDim2.new(1, -60, 0, 34), TextColor3 = Theme.Colors.gold }
	)
	Theme.button(panel, "X", JournalUI.close, {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(40, 34),
		BackgroundColor3 = Theme.Colors.buttonOff,
	})
	content = Instance.new("ScrollingFrame")
	content.Position = UDim2.fromOffset(0, 44)
	content.Size = UDim2.new(1, 0, 1, -44)
	content.BackgroundTransparency = 1
	content.BorderSizePixel = 0
	content.ScrollBarThickness = 6
	content.AutomaticCanvasSize = Enum.AutomaticSize.Y
	content.CanvasSize = UDim2.new()
	content.Parent = panel
	Theme.list(content, 8)
	State.Changed:Connect(function()
		render()
	end)
end

return JournalUI
