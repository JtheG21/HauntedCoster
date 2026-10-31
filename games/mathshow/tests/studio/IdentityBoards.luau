--!strict
-- Studio board harness for the identity components (TASK-0106). Studio only; never part of check.sh. Run in a fresh Play
-- session on the CLIENT after scripts/studio-preflight.sh --game mathshow:
--   require(game.Players.LocalPlayer.PlayerScripts.StudioTests.IdentityBoards).run()
-- Other viewports: .run({ scale = HudRules.rootScale(w, h) }), which emulates that root UIScale. { keep = true } leaves the
-- boards on screen for a screenshot; destroy PlayerGui.IdentityBoards afterwards.
-- Builds the README boards (badges, chips, progress variants, six card variants, reveal, intro, results) and the rule-10
-- stress fixtures at 844x390, then prints one row per check and a last line IDENTITY_RESULT. Checks:
--   * text is not clipped (bounds fit the label) unless the label is marked AllowTruncate;
--   * content stays inside its shard box;
--   * the Group Battle rail (Placement A) and 3v3 rails (Placement B) stay out of the keep-clear zones;
--   * text-fit margin 6 via TextFitRules when a shape profile exists for the shard (scripts/shape_profiles.py generates
--     them from the PNGs); a shard without one says "no profile".
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

-- TASK-0114: tightest text-fit margin (design px) over every checked label in one run, and its path.
local minTight = math.huge
local minTightRow = "none"

local function checkText(board: string, rows: { Row }, gui: ScreenGui, scale: number)
	for _, d in gui:GetDescendants() do
		if d:IsA("TextLabel") and d.Text ~= "" then
			local params = Instance.new("GetTextBoundsParams")
			params.Text = d.Text
			params.Font = d.FontFace
			params.Size = d.TextSize
			-- Text bounds are in canvas px, so every absolute measure is divided back by the emulated scale.
			local size = d.AbsoluteSize / scale
			params.Width = if d.TextWrapped then size.X else 10000
			local ok, bounds = pcall(function()
				return TextService:GetTextBoundsAsync(params)
			end)
			local detail = `"{d.Text}"`
			local pass = true
			if ok then
				local truncates = d:GetAttribute("AllowTruncate") == true
				local fitsW = bounds.X <= size.X + 0.5
				local fitsH = bounds.Y <= size.Y + 0.5
				if not (fitsW and fitsH) and not truncates then
					pass = false
					detail ..= ` clipped: {math.ceil(bounds.X)}x{math.ceil(bounds.Y)} in {math.ceil(size.X)}x{math.ceil(
						size.Y
					)}`
				end
				local shard = owner(d)
				if shard and (truncates or fitsW) then
					local profile = TextFitRules.profile(shard:GetAttribute("ShapeKey") :: string)
					if profile then
						local x0 = (d.AbsolutePosition.X - shard.AbsolutePosition.X) / scale
						local y0 = (d.AbsolutePosition.Y - shard.AbsolutePosition.Y) / scale
						-- The text sits inside its label by alignment, so measure where it really is (as tests/studio/TextFit does).
						local w = math.min(bounds.X, size.X)
						local h = math.min(bounds.Y, size.Y)
						if d.TextXAlignment == Enum.TextXAlignment.Center then
							x0 += (size.X - w) / 2
						elseif d.TextXAlignment == Enum.TextXAlignment.Right then
							x0 += size.X - w
						end
						if d.TextYAlignment == Enum.TextYAlignment.Center then
							y0 += (size.Y - h) / 2
						elseif d.TextYAlignment == Enum.TextYAlignment.Bottom then
							y0 += size.Y - h
						end
						local rect = { x0 = x0, y0 = y0, x1 = x0 + w, y1 = y0 + h }
						local sw, sh = shard:GetAttribute("ShapeW") :: number, shard:GetAttribute("ShapeH") :: number
						local tight = 0
						for m = 0, 12, 0.25 do
							if TextFitRules.rectFits(profile, rect, m, sw, sh) then
								tight = m
							else
								break
							end
						end
						if tight < minTight then
							minTight = tight
							minTightRow = `{board} "{d.Text}" {d:GetFullName()}`
						end
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
							local best = 0
							for m = 0.25, MARGIN, 0.25 do
								if
									TextFitRules.rectFits(
										profile,
										rect,
										m,
										shard:GetAttribute("ShapeW") :: number,
										shard:GetAttribute("ShapeH") :: number
									)
								then
									best = m
								end
							end
							detail ..= ` text-fit margin {best} < {MARGIN} on {shard:GetAttribute("ShapeKey")}`
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

function IdentityBoards.run(options: { scale: number?, keep: boolean? }?): boolean
	minTight, minTightRow = math.huge, "none"
	local scale = options and options.scale or 1
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
	local uiScale = Instance.new("UIScale")
	uiScale.Scale = scale
	uiScale.Parent = canvas

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
	task.wait() -- let AbsoluteSize settle under the scale
	checkText("boards", rows, gui, scale)
	checkRails(rows, Theme)
	if not (options and options.keep) then
		gui:Destroy()
	end

	local failed, noProfile = 0, 0
	for _, r in rows do
		if string.find(r.detail, "(no profile)", 1, true) then
			noProfile += 1
		end
		if not r.pass then
			failed += 1
			print(`FAIL [{r.board}] {r.element}: {r.detail}`)
		end
	end
	local guiButtons = 0
	for _, d in gui:GetDescendants() do
		if d:IsA("GuiButton") then
			guiButtons += 1
		end
	end
	print(`IDENTITY_MIN scale={scale} margin={minTight} row={minTightRow} guiButtons={guiButtons}`)
	print(`IDENTITY_RESULT scale={scale} rows={#rows} failed={failed} no_profile={noProfile}`)
	return failed == 0
end

return IdentityBoards
