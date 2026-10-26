--!strict
-- MathShow Menu (TASK-0098): the root of navigation. A local overlay on top of the HUD; the server never hears from it.
-- Navigation is a small stack (Back pops; B / Esc = Back). JOIN SHOW hides the menu and shows the HUD, and the existing
-- match loop (which starts for every player) carries on. Settings apply locally only: volume, reduced motion,
-- color-blind marks and haptics are held here until a SettingsSave exists.

local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuConfig = require(Shared:WaitForChild("MenuConfig"))
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))

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

local function model(): View.Model
	local player = Players.LocalPlayer
	return {
		player = { name = player.DisplayName, userId = player.UserId, rank = nil, failed = false },
		settings = settings,
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

local function show(id: string, focusKey: string?)
	if view then
		view.render(id, model())
		focusDefault(focusKey)
	end
end

local function go(id: string)
	table.insert(stack, id)
	show(id)
end

local function back()
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

function Menu.getSettings(): View.Settings
	return table.clone(settings)
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
		locked = function(_what: string)
			if view then
				view.toast(MenuCopy.Common.ComingSoon, true)
			end
		end,
		join = function()
			Menu.hide()
			if options then
				options.onJoin()
			end
		end,
		setting = function(key: string, value: number | boolean)
			(settings :: any)[key] = value
			applySettings()
			show(stack[#stack], key)
		end,
	}
	view = View.build(player:WaitForChild("PlayerGui"), handlers)
	applySettings()
	stack = { "main" }
	show("main")

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
	unbindBack()
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
