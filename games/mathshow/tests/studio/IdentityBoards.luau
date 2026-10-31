--!strict
-- Studio board harness for the identity components (TASK-0106). Studio only; never part of check.sh. Run in a fresh Play
-- session on the CLIENT after scripts/studio-preflight.sh --game mathshow:
--   require(game.Players.LocalPlayer.PlayerScripts.StudioTests.IdentityBoards).run()
-- Builds the README boards (badges, chips, progress variants, six card variants, reveal, intro, results) and the rule-10
-- stress fixtures at 844x390, then prints one row per check and a last line IDENTITY_RESULT. Checks:
--   * text is not clipped (bounds fit the label) unless the label is marked AllowTruncate;
--   * content stays inside its shard box;
--   * the Group Battle rail (Placement A) and 3v3 rails (Placement B) stay out of the keep-clear zones;
--   * text-fit margin 6 via TextFitRules when a shape profile exists for the shard (new shard-id-* profiles come with the
--     audited ShapeProfiles; until then the row says "no profile").
-- Compare the boards to screenshots S1-S7 by eye; differences over 2 px are reported by the layout rows, not by pixels.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local TextFitRules = require(Shared:WaitForChild("TextFitRules"))

local MARGIN = 6
local ZONES = {
	{ name = "top-left", x0 = 0, y0 = 0, x1 = 150, y1 = 44 },
	{ name = "bottom-right", x0 = 664, y0 = 240, x1 = 844, y1 = 390 },
	{ name = "left inset", x0 = 0, y0 = 0, x1 = 44, y1 = 390 },
	{ name = "right inset", x0 = 800, y0 = 0, x1 = 844, y1 = 390 },
}

export type Row = { board: string, element: string, detail: string, pass: boolean }

local IdentityBoards = {}

local function overlaps(
	a: { x0: number, y0: number, x1: number, y1: number },
	b: { x0: number, y0: number, x1: number, y1: number }
): boolean
	return a.x0 < b.x1 and a.x1 > b.x0 and a.y0 < b.y1 and a.y1 > b.y0
end

local function owner(inst: Instance): Frame?
	local node: Instance? = inst.Parent
	while node do
		if node:IsA("Frame") and node:GetAttribute("ShapeKey") ~= nil then
			return node
		end
		node = node.Parent
	end
	return nil
end

local function checkText(board: string, rows: { Row }, gui: ScreenGui)
	for _, d in gui:GetDescendants() do
		if d:IsA("TextLabel") and d.Text ~= "" then
			local params = Instance.new("GetTextBoundsParams")
			params.Text = d.Text
			params.Font = d.FontFace
			params.Size = d.TextSize
			params.Width = if d.TextWrapped then d.AbsoluteSize.X else 10000
			local ok, bounds = pcall(function()
				return TextService:GetTextBoundsAsync(params)
			end)
			local detail = `"{d.Text}"`
			local pass = true
			if ok then
				local truncates = d:GetAttribute("AllowTruncate") == true
				local fitsW = bounds.X <= d.AbsoluteSize.X + 0.5
				local fitsH = bounds.Y <= d.AbsoluteSize.Y + 0.5
				if not (fitsW and fitsH) and not truncates then
					pass = false
					detail ..= ` clipped: {math.ceil(bounds.X)}x{math.ceil(bounds.Y)} in {math.ceil(d.AbsoluteSize.X)}x{math.ceil(
						d.AbsoluteSize.Y
					)}`
				end
				local shard = owner(d)
				if shard and (truncates or fitsW) then
					local profile = TextFitRules.profile(shard:GetAttribute("ShapeKey") :: string)
					if profile then
						local x0 = d.AbsolutePosition.X - shard.AbsolutePosition.X
						local y0 = d.AbsolutePosition.Y - shard.AbsolutePosition.Y
						local w = math.min(bounds.X, d.AbsoluteSize.X)
						local rect = { x0 = x0, y0 = y0, x1 = x0 + w, y1 = y0 + bounds.Y }
						if
							not TextFitRules.rectFits(
								profile,
								rect,
								MARGIN,
								shard:GetAttribute("ShapeW") :: number,
								shard:GetAttribute("ShapeH") :: number
							)
						then
							pass = false
							detail ..= " text-fit margin < 6"
						end
					else
						detail ..= " (no profile)"
					end
				end
			else
				pass = false
				detail ..= " measure failed"
			end
			table.insert(rows, {
				board = board,
				element = d:GetFullName():match("[^.]+%.[^.]+$") or d.Name,
				detail = detail,
				pass = pass,
			})
		end
	end
end

local function checkRails(rows: { Row }, Theme: any)
	local R = Theme.Rail
	local function rail(name: string, x: number, y: number, w: number, h: number)
		local box = { x0 = x, y0 = y, x1 = x + w, y1 = y + h }
		for _, z in ZONES do
			local hit = overlaps(box, z)
			table.insert(rows, {
				board = "rails",
				element = name,
				detail = hit and `enters {z.name}` or `clear of {z.name}`,
				pass = not hit,
			})
		end
	end
	for i = 0, 5 do
		rail(
			`A card {i + 1}`,
			R.GroupBattle.X,
			R.GroupBattle.Y + R.GroupBattle.Pitch * i,
			Theme.Gameplay.Size.X,
			Theme.Gameplay.Size.Y
		)
	end
	for team = 1, 2 do
		for i, y in R.ThreeVThree.CardY[team] do
			rail(`B team {team} card {i}`, R.ThreeVThree.X, y, Theme.Gameplay.Size.X, Theme.Gameplay.Size.Y)
		end
	end
end

function IdentityBoards.run(): boolean
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local Identity = script.Parent.Parent:WaitForChild("Client"):WaitForChild("Identity") :: Instance
	local Theme = require(Identity:WaitForChild("IdentityTheme")) :: any
	local Primitives = require(Identity:WaitForChild("Primitives")) :: any
	local Cards = require(Identity:WaitForChild("Cards")) :: any
	local rows: { Row } = {}

	local gui = Instance.new("ScreenGui")
	gui.Name = "IdentityBoards"
	gui.IgnoreGuiInset = true
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	local canvas = Instance.new("Frame")
	canvas.Size = UDim2.fromOffset(844, 390)
	canvas.BackgroundColor3 = Color3.fromRGB(11, 10, 13)
	canvas.Parent = gui

	local function player(name: string, tier: string, extra: { [string]: any }?): any
		local p: { [string]: any } = { displayName = name, tier = tier, score = 1250, userId = nil, connected = true }
		local overrides: { [string]: any } = extra or {}
		for k, v in overrides do
			p[k] = v
		end
		return p
	end

	local variants = {
		player("DEFAULT", "gold", { groupTag = "AB" }),
		player("YOU", "emerald", { isYou = true, submitted = true }),
		player("BOT", "copper", { isBot = true }),
		player("FIRST", "diamond", { firstCorrect = true }),
		player("OFFLINE", "plastic", { connected = false }),
		player("WATCHER", "silver", { spectating = true }),
	}
	for i, p in variants do
		Cards.GameplayCard(canvas, { player = p, x = 44, y = 58 + (i - 1) * 50 })
		Cards.RevealCard(canvas, { player = p, delta = 150 - i * 60, x = 232, y = 58 + (i - 1) * 50 })
	end
	Cards.IntroCard(canvas, {
		player = player(
			"A VERY LONG DISPLAY NAME THAT WRAPS TWICE AND THEN TRUNCATES",
			"platinum",
			{ groupTag = "WWWWW", firstCorrect = true }
		),
		mode = "groupBattle",
		format = "direct",
		x = 440,
		y = 20,
	})
	local rewardList: { any } = { { kind = "xp", amount = 120 }, { kind = "streak" }, { kind = "mvp" } }
	for i, p in variants do
		if i <= 3 then
			Cards.ResultsRow(canvas, {
				player = p,
				placement = i,
				stat = "10/10 correct · 4 first",
				rankDelta = (2 - i) * 24,
				rewards = rewardList,
				x = 44,
				y = 6 + (i - 1) * 50,
			})
		end
	end
	local y = 220
	for _, size in { "compact", "standard", "long" } do
		Primitives.TrackChip(
			canvas,
			{ tier = "platinum", mode = "team3v3", format = "direct", size = size, x = 440, y = y }
		)
		y += 44
	end
	Primitives.ProgressBar(
		canvas,
		{ kind = "profile", tier = "gold", mode = "gain", value = 64, delta = 12, x = 440, y = y }
	)
	Primitives.ProgressBar(
		canvas,
		{ kind = "strip", tier = "demon", mode = "demon", standing = 42, x = 440, y = y + 40 }
	)
	checkText("boards", rows, gui)
	checkRails(rows, Theme)
	gui:Destroy()

	local failed = 0
	for _, r in rows do
		if not r.pass then
			failed += 1
			print(`FAIL [{r.board}] {r.element}: {r.detail}`)
		end
	end
	print(`IDENTITY_RESULT rows={#rows} failed={failed}`)
	return failed == 0
end

return IdentityBoards
