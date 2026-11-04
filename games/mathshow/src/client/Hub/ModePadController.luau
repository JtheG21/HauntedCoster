--!strict
-- ModePadController (TASK-0122): receives ModePadOpen from ModePadService (the server saw this character step onto a hub
-- mode pad) and opens that menu screen. Client-only and one-way: it sends nothing. An open menu ignores the pad, so
-- screens never stack. ModePadLeave closes the pad's screen (or locked toast) when the player walks off. "locked:*" screens show the coming-soon toast. The pad glow is cosmetic and fails inert.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MenuCopy = require(Shared:WaitForChild("MenuCopy"))
local Net = require(Shared:WaitForChild("Net"))

local Menu = require(script.Parent.Parent.Menu)
local View = require(script.Parent.Parent.Menu.View)

local ModePadController = {}

local CONNECT_TIMEOUT = 10
local LOCKED_PREFIX = "locked:"
-- Menu screens a pad may open. Anything else is warned and ignored (the server only sends ModePadConfig.Modes values).
local OPENABLE: { [string]: boolean } = {
	confirm_blitz = true,
	confirm_vs = true,
	confirm_group = true,
	practice = true,
	skillintro = true,
}

local started = false
local inMatch = false -- ShowState.participant: the HUD is in-match. Second layer only; the server already blocks pads then.
local toastView: View.View? = nil
local lockedToastUp = false -- a locked: pad's toast may still be on screen

local function noop() end

-- A small overlay ScreenGui (same pattern as the WATCHING banner) so the toast shows with the menu closed.
local function buildToast()
	local ok, err = pcall(function()
		local handlers: View.Handlers = {
			go = noop,
			back = noop,
			locked = function(_what: string) end,
			join = noop,
			retry = noop,
			skillSelect = function(_index: number) end,
			skillLock = function(_value: number) end,
			blitzLock = function(_value: number) end,
			vsLock = function(_value: number) end,
			vsKeepWaiting = noop,
			vsRematch = noop,
			vsRetry = noop,
			setting = function(_key: string, _value: number | boolean) end,
		}
		toastView = View.build(Players.LocalPlayer:WaitForChild("PlayerGui"), handlers, {
			overlay = true,
			name = "MathShowModePadToast",
			displayOrder = 6, -- above the HUD and the WATCHING banner, below the menu
		})
	end)
	if not ok then
		warn(`[MathShow] ModePad toast failed to build: {err}`)
	end
end

local function lockedToast()
	local v = toastView
	if not v then
		return
	end
	local ok, err = pcall(function()
		v.toast(MenuCopy.Common.ComingSoon, true)
		lockedToastUp = true
	end)
	if not ok then
		warn(`[MathShow] ModePad toast failed: {err}`)
	end
end

local function onOpen(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.screen) ~= "string" then
		warn("[MathShow] ModePadOpen ignored: malformed payload")
		return
	end
	local screen: string = payload.screen
	if inMatch then
		return
	end
	if Menu.isOpen() then
		return -- a screen is already up: no stacking
	end
	if string.sub(screen, 1, #LOCKED_PREFIX) == LOCKED_PREFIX then
		lockedToast()
		return
	end
	if not OPENABLE[screen] then
		warn(`[MathShow] ModePadOpen ignored: unknown screen {screen}`)
		return
	end
	Menu.open(screen)
end

-- The player walked off a pad (ModePadLeave). Closes that pad's menu screen, or takes its locked toast down, and nothing else.
local function onLeave(payload: any)
	if typeof(payload) ~= "table" or typeof(payload.screen) ~= "string" then
		warn("[MathShow] ModePadLeave ignored: malformed payload")
		return
	end
	local screen: string = payload.screen
	if string.sub(screen, 1, #LOCKED_PREFIX) == LOCKED_PREFIX then
		local v = toastView
		if v and lockedToastUp then
			lockedToastUp = false
			v.hideToast()
		end
		return
	end
	Menu.closePadScreen(screen)
end

function ModePadController.start()
	if started then
		return
	end
	started = true
	buildToast()
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes", CONNECT_TIMEOUT)
		local remote = if folder then folder:WaitForChild(Net.ShowState, CONNECT_TIMEOUT) else nil
		if not remote or not remote:IsA("RemoteEvent") then
			warn("[MathShow] ModePadController: ShowState remote not found; the client match check is off")
			return
		end
		remote.OnClientEvent:Connect(function(payload: any)
			if typeof(payload) == "table" and typeof(payload.participant) == "boolean" then
				inMatch = payload.participant
			end
		end)
	end)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes", CONNECT_TIMEOUT)
		local remote = if folder then folder:WaitForChild(Net.ModePadLeave, CONNECT_TIMEOUT) else nil
		if not remote or not remote:IsA("RemoteEvent") then
			warn("[MathShow] ModePadController: ModePadLeave remote not found; pad prompts stay until closed")
			return
		end
		remote.OnClientEvent:Connect(function(payload: any)
			local ok, err = pcall(function()
				onLeave(payload)
			end)
			if not ok then
				warn(`[MathShow] ModePadLeave handler failed: {err}`)
			end
		end)
	end)
	task.spawn(function()
		local folder = ReplicatedStorage:WaitForChild("Remotes", CONNECT_TIMEOUT)
		local remote = if folder then folder:WaitForChild(Net.ModePadOpen, CONNECT_TIMEOUT) else nil
		if not remote or not remote:IsA("RemoteEvent") then
			warn("[MathShow] ModePadController: ModePadOpen remote not found; mode pads are inactive")
			return
		end
		remote.OnClientEvent:Connect(function(payload: any)
			local ok, err = pcall(function()
				onOpen(payload)
			end)
			if not ok then
				warn(`[MathShow] ModePadOpen handler failed: {err}`)
			end
		end)
	end)
end

return ModePadController
