--!strict
-- MathShow Menu (TASK-0098): the root of navigation. A local overlay on top of the HUD; the server never hears from it.
-- Navigation is a small stack (Back pops; B / Esc = Back). JOIN SHOW hides the menu and shows the HUD, and the existing
-- match loop (which starts for every player) carries on. Settings apply locally only: volume, reduced motion,
-- color-blind marks and haptics are held here until a SettingsSave exists.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local CooldownRules = require(Shared:WaitForChild("CooldownRules"))
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))
local PracticeRules = require(Shared:WaitForChild("PracticeRules"))

local Net = require(Shared:WaitForChild("Net"))

local Fx = require(script.Parent.Hud.Fx)
local View = require(script.View)

local Menu = {}

export type Options = { onJoin: () -> () }

local BACK_ACTION = "MathShowMenuBack"

local view: View.View? = nil
local stack: { string } = {}
local settings: View.Settings = table.clone(MenuConfig.SettingsDefaults)
local inputConnection: RBXScriptConnection? = nil
local options: Options? = nil

-- What the server said about this player (TASK-0099). loaded = the MenuRequest finished; ok = it returned a profile.
local profile: {
	loaded: boolean,
	ok: boolean,
	rank: number?,
	lastTestRank: number?,
	retryAt: number?,
	blitzBest: number?,
} =
	{ loaded = false, ok = false }
local settingsTouched = false -- the player changed a setting before the profile arrived: keep theirs and send it
local saveToken = 0

local function soundGroup(name: string): SoundGroup
	local existing = SoundService:FindFirstChild(name)
	if existing and existing:IsA("SoundGroup") then
		return existing
	end
	local group = Instance.new("SoundGroup")
	group.Name = name
	group.Parent = SoundService
	return group
end

local function applySettings()
	local ok, err = pcall(function()
		soundGroup("Music").Volume = settings.music / MenuConfig.SettingMax
		soundGroup("Sfx").Volume = settings.sfx / MenuConfig.SettingMax
		Fx.setReducedMotion(settings.reducedMotion)
		if view then
			view.setReduced(settings.reducedMotion)
		end
	end)
	if not ok then
		warn(`[MathShow] Menu settings failed to apply: {err}`)
	end
end

-- The Skill Test run on screen (TASK-0102). The server decides everything; this only shows its SkillState and sends answers.
local skillCtx: {
	attempt: number,
	model: View.SkillModel?,
	endsAt: number,
	total: number,
	selected: number?,
	locked: boolean,
	chosen: number?,
	prevBest: number?,
	result: View.ResultModel?,
	started: boolean,
} =
	{
		attempt = 0,
		model = nil,
		endsAt = 0,
		total = 0,
		selected = nil,
		locked = false,
		chosen = nil,
		prevBest = nil,
		result = nil,
		started = false,
	}
local skillToken = 0

local function skillModel(): View.SkillModel?
	local m = skillCtx.model
	if m == nil then
		return nil
	end
	local copy = table.clone(m)
	copy.selected = skillCtx.selected
	copy.locked = skillCtx.locked
	copy.chosen = skillCtx.chosen
	return copy
end

local function model(): View.Model
	local player = Players.LocalPlayer
	return {
		skill = if stack[#stack] == "skill" then skillModel() else nil,
		result = if stack[#stack] == "skillresult" then skillCtx.result else nil,
		player = {
			name = player.DisplayName,
			userId = player.UserId,
			rank = profile.rank,
			failed = profile.loaded and not profile.ok,
			loading = not profile.loaded,
		},
		settings = settings,
		practice = {
			rank = profile.rank,
			lastTestRank = profile.lastTestRank,
			retryRemaining = PracticeRules.remaining(profile.retryAt, workspace:GetServerTimeNow()),
			failed = profile.loaded and not profile.ok,
		},
	}
end

local function focusDefault(key: string?)
	if not (view and UserInputService.GamepadEnabled) then
		return
	end
	local v = view
	task.defer(function()
		local target = v.defaultFocus()
		if key then
			for _, d in v.root:GetDescendants() do
				if d:IsA("TextButton") and d:GetAttribute("Setting") == key then
					target = d
					break
				end
			end
		end
		if target and target.Parent then
			GuiService.SelectedObject = target
		end
	end)
end

local tickToken = 0

-- While the Practice home shows a retake clock, counts it down each second (label only: no re-render) and re-renders the
-- screen when it reaches zero so TAKE TEST comes back. Stops as soon as another screen is shown.
local function startRetakeTicker()
	tickToken += 1
	local token = tickToken
	task.spawn(function()
		while token == tickToken and view and stack[#stack] == "practice" do
			local remaining = PracticeRules.remaining(profile.retryAt, workspace:GetServerTimeNow())
			if remaining <= 0 then
				break
			end
			view.setRetakeLabel(CooldownRules.retakeLabel(remaining))
			task.wait(1)
		end
		if token == tickToken and view and stack[#stack] == "practice" then
			view.render("practice", model())
			focusDefault(nil)
		end
	end)
end

local function show(id: string, focusKey: string?)
	tickToken += 1 -- any running retake ticker belongs to the previous screen
	if view then
		view.render(id, model())
		focusDefault(focusKey)
		if
			id == "practice"
			and profile.ok
			and PracticeRules.remaining(profile.retryAt, workspace:GetServerTimeNow()) > 0
		then
			startRetakeTicker()
		end
	end
end

local function remoteNamed(name: string): Instance?
	local folder = ReplicatedStorage:WaitForChild("Remotes", 10)
	return if folder then folder:WaitForChild(name, 10) else nil
end

local function fire(name: string, payload: any?)
	local ok, err = pcall(function()
		local remote = remoteNamed(name)
		if remote and remote:IsA("RemoteEvent") then
			if payload == nil then
				remote:FireServer()
			else
				remote:FireServer(payload)
			end
		else
			warn(`[MathShow] Menu: {name} remote not found`)
		end
	end)
	if not ok then
		warn(`[MathShow] Menu could not send {name}: {err}`)
	end
end

-- Counts the question clock down on screen (bar and seconds). A tick re-renders nothing.
local function startSkillTimer()
	skillToken += 1
	local token = skillToken
	task.spawn(function()
		while token == skillToken and view and stack[#stack] == "skill" do
			local m = skillCtx.model
			if m == nil or m.phase ~= "question" then
				break
			end
			local left = math.max(0, skillCtx.endsAt - workspace:GetServerTimeNow())
			view.setSkillTimer(left / math.max(skillCtx.total, 1), left)
			task.wait(0.1)
		end
	end)
end

local function renderSkill(isQuiet: boolean)
	if not view then
		return
	end
	local m = model()
	m.quiet = isQuiet
	view.render("skill", m)
	focusDefault(nil)
	local current = skillCtx.model
	if current and current.phase == "question" then
		startSkillTimer()
	end
end

local function go(id: string)
	if id == "skill" then
		-- START on the intro: ask the server; the screen opens when its first question arrives.
		skillCtx.started = true
		skillCtx.prevBest = profile.rank
		skillCtx.result = nil
		fire(Net.SkillStart)
		return
	end
	table.insert(stack, id)
	show(id)
end

local function back()
	if stack[#stack] == "skill" then
		return -- no leaving a Skill Test question: the run ends on its own
	end
	if #stack > 1 then
		table.remove(stack)
		show(stack[#stack])
	end
end

local function unbindBack()
	pcall(function()
		ContextActionService:UnbindAction(BACK_ACTION)
	end)
end

-- Sends the settings once, SettingsSaveDebounceSeconds after the last change. The server validates and rate limits.
local function scheduleSave()
	saveToken += 1
	local token = saveToken
	task.delay(MenuConfig.SettingsSaveDebounceSeconds, function()
		if token ~= saveToken then
			return
		end
		local ok, err = pcall(function()
			local remote = remoteNamed(Net.SettingsSave)
			if remote and remote:IsA("RemoteEvent") then
				remote:FireServer({
					music = settings.music,
					sfx = settings.sfx,
					reducedMotion = settings.reducedMotion,
					colorBlind = settings.colorBlind,
					haptics = settings.haptics,
				})
			end
		end)
		if not ok then
			warn(`[MathShow] Menu could not send settings: {err}`)
		end
	end)
end

-- Asks the server for this player's profile. Never throws and never blocks the menu: on any failure the menu keeps its
-- local defaults and the player card says RANK UNAVAILABLE.
local function requestProfile()
	task.spawn(function()
		local ok, reply = pcall(function()
			local remote = remoteNamed(Net.MenuRequest)
			if remote and remote:IsA("RemoteFunction") then
				return remote:InvokeServer({ kind = "profile" })
			end
			return nil
		end)
		local usable = ok and typeof(reply) == "table" and reply.ok == true and typeof(reply.profile) == "table"
		if usable then
			local p = reply.profile
			profile = {
				loaded = true,
				ok = true,
				rank = p.rank,
				lastTestRank = p.lastTestRank,
				retryAt = p.retryAt,
				blitzBest = p.blitzBest,
			}
			-- Studio-only test hook: pretend a Skill Test cooldown of N seconds (workspace attribute MathShowFakeRetakeSeconds). It also
			-- fills in a rank and last test (2) when there are none, so the Practice home has something to show.
			local fake = workspace:GetAttribute("MathShowFakeRetakeSeconds")
			if RunService:IsStudio() and typeof(fake) == "number" then
				profile.retryAt = workspace:GetServerTimeNow() + fake
				profile.rank = profile.rank or 2
				profile.lastTestRank = profile.lastTestRank or 2
			end
			if not settingsTouched and typeof(p.settings) == "table" then
				settings = table.clone(p.settings)
				applySettings()
			end
		else
			profile = { loaded = true, ok = false }
			warn(
				`[MathShow] Menu profile unavailable: {if ok and typeof(reply) == "table" then reply.reason else reply}`
			)
		end
		if usable and settingsTouched then
			scheduleSave()
		end
		if view and #stack > 0 then
			show(stack[#stack])
		end
	end)
end

function Menu.retryProfile()
	profile = { loaded = false, ok = false }
	requestProfile()
end

function Menu.getSettings(): View.Settings
	return table.clone(settings)
end

-- SkillState / SkillResult from the server. Malformed payloads are ignored with a warning.
local function onSkillState(p: any)
	if typeof(p) ~= "table" or typeof(p.state) ~= "string" or not view then
		warn("[MathShow] Menu ignored a malformed SkillState")
		return
	end
	if p.state == "question" or p.state == "reveal" then
		if typeof(p.problem) ~= "string" or typeof(p.rank) ~= "number" or typeof(p.kind) ~= "string" then
			warn("[MathShow] Menu ignored a malformed SkillState question")
			return
		end
		if not skillCtx.started then
			return -- a stale state from a run this menu did not start
		end
		local reveal = p.state == "reveal"
		local phase: string = p.state
		skillCtx.attempt = p.attempt
		skillCtx.endsAt = p.endsAt
		skillCtx.total = p.total
		if not reveal then
			skillCtx.locked = false
			skillCtx.selected = nil
			skillCtx.chosen = nil
		end
		skillCtx.model = {
			kind = p.kind,
			rank = p.rank,
			problem = p.problem,
			choices = p.choices or (skillCtx.model and skillCtx.model.choices),
			misses = p.misses,
			total = if reveal and skillCtx.model then skillCtx.model.total else p.total,
			phase = phase,
			selected = nil,
			locked = skillCtx.locked,
			chosen = skillCtx.chosen,
			correct = p.correct,
			correctValue = p.correctValue,
			correctIndex = p.correctIndex,
		}
		if stack[#stack] ~= "skill" then
			table.insert(stack, "skill")
		end
		renderSkill(false)
	elseif p.state == "cooldown" then
		skillCtx.started = false
		profile.retryAt = if typeof(p.retryAt) == "number" then p.retryAt else profile.retryAt
		stack = { "main", "practice" }
		show("practice")
	elseif p.state == "unavailable" then
		skillCtx.started = false
		if view then
			view.toast(MenuCopy.Main.RankUnavailable, false)
		end
	end
end

local function onSkillResult(p: any)
	if
		typeof(p) ~= "table"
		or typeof(p.best) ~= "number"
		or typeof(p.kind) ~= "string"
		or typeof(p.retryAt) ~= "number"
	then
		warn("[MathShow] Menu ignored a malformed SkillResult")
		return
	end
	skillCtx.started = false
	skillToken += 1
	profile.rank = p.best
	profile.lastTestRank = if typeof(p.cleared) == "number" then p.cleared else 0
	profile.retryAt = p.retryAt
	skillCtx.result = {
		kind = p.kind,
		best = p.best,
		cleared = p.cleared,
		previousBest = skillCtx.prevBest,
		retryRemaining = PracticeRules.remaining(p.retryAt, workspace:GetServerTimeNow()),
	}
	stack = { "main", "practice", "skillresult" }
	show("skillresult")
end

local function connectSkillRemotes()
	local state = remoteNamed(Net.SkillState)
	local result = remoteNamed(Net.SkillResult)
	if state and state:IsA("RemoteEvent") then
		state.OnClientEvent:Connect(function(p: any)
			local ok, err = pcall(function()
				onSkillState(p)
			end)
			if not ok then
				warn(`[MathShow] Menu SkillState failed: {err}`)
			end
		end)
	end
	if result and result:IsA("RemoteEvent") then
		result.OnClientEvent:Connect(function(p: any)
			local ok, err = pcall(function()
				onSkillResult(p)
			end)
			if not ok then
				warn(`[MathShow] Menu SkillResult failed: {err}`)
			end
		end)
	end
end

function Menu.start(opts: Options)
	if view then
		return
	end
	options = opts
	local player = Players.LocalPlayer
	local handlers: View.Handlers = {
		go = go,
		back = back,
		retry = function()
			Menu.retryProfile()
		end,
		skillSelect = function(index: number)
			local m = skillCtx.model
			if m and m.phase == "question" and not skillCtx.locked then
				skillCtx.selected = index
				renderSkill(true)
			end
		end,
		skillLock = function(value: number)
			local m = skillCtx.model
			if not m or m.phase ~= "question" or skillCtx.locked then
				return
			end
			-- Lock first, synchronously, so nothing can send a second answer for this question.
			skillCtx.locked = true
			if m.kind == "choice" then
				skillCtx.chosen = value
			end
			fire(Net.SkillAnswer, { attempt = skillCtx.attempt, answer = value })
			renderSkill(true)
		end,
		locked = function(_what: string)
			if view then
				view.toast(MenuCopy.Common.ComingSoon, true)
			end
		end,
		join = function()
			-- Tell the server first (it decides who is in the match); the menu hides and the HUD shows either way.
			local ok, err = pcall(function()
				local remote = remoteNamed(Net.JoinShow)
				if remote and remote:IsA("RemoteEvent") then
					remote:FireServer()
				else
					warn("[MathShow] Menu: JoinShow remote not found; the server will not count this player")
				end
			end)
			if not ok then
				warn(`[MathShow] Menu could not send JoinShow: {err}`)
			end
			Menu.hide()
			if options then
				options.onJoin()
			end
		end,
		setting = function(key: string, value: number | boolean)
			(settings :: any)[key] = value
			settingsTouched = true
			applySettings()
			scheduleSave()
			show(stack[#stack], key)
		end,
	}
	view = View.build(player:WaitForChild("PlayerGui"), handlers)
	applySettings()
	stack = { "main" }
	show("main")
	requestProfile()
	task.spawn(connectSkillRemotes)

	ContextActionService:BindAction(BACK_ACTION, function(_name, state)
		if state == Enum.UserInputState.Begin and #stack > 1 then
			back()
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.ButtonB, Enum.KeyCode.Escape)

	-- D-pad / shoulder buttons / arrows change the focused stepper row (A does nothing on it).
	inputConnection = UserInputService.InputBegan:Connect(function(input: InputObject)
		local selected = GuiService.SelectedObject
		if not selected or selected:GetAttribute("Kind") ~= "stepper" then
			return
		end
		local code = input.KeyCode
		local delta = 0
		if code == Enum.KeyCode.DPadLeft or code == Enum.KeyCode.ButtonL1 or code == Enum.KeyCode.Left then
			delta = -1
		elseif code == Enum.KeyCode.DPadRight or code == Enum.KeyCode.ButtonR1 or code == Enum.KeyCode.Right then
			delta = 1
		end
		if delta ~= 0 then
			local key = selected:GetAttribute("Setting") :: string
			local value = selected:GetAttribute("Value") :: number
			local nextValue = math.clamp(value + delta, 0, MenuConfig.SettingMax)
			if nextValue ~= value then
				handlers.setting(key, nextValue)
			end
		end
	end)
end

function Menu.hide()
	tickToken += 1 -- a running retake ticker must not re-render or take focus while the menu is hidden
	unbindBack()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	pcall(function()
		GuiService.SelectedObject = nil
	end)
	if view then
		view.gui.Enabled = false
	end
end

function Menu.stop()
	unbindBack()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	if view then
		view.destroy()
		view = nil
	end
	stack = {}
end

return Menu
