--!strict
-- GAME-002 Haunted Collector: client entry point. Mounts the HUD and menus, and wires input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local State = require(script.State)
local LocalWorld = require(script.LocalWorld)
local Hud = require(script.UI.Hud)
local CaptureUI = require(script.UI.CaptureUI)
local MansionUI = require(script.UI.MansionUI)
local JournalUI = require(script.UI.JournalUI)
local TrackEditor = require(script.UI.TrackEditor)

local BuildInfo = require(ReplicatedStorage.Shared.BuildInfo)

print(`[HauntedCollector] client build {BuildInfo.stamp()}`)

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "HauntedHud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

-- Scale the whole UI down on small screens (phones) so fixed-size panels fit.
local scale = Instance.new("UIScale")
scale.Parent = gui
local function rescale()
	local cam = Workspace.CurrentCamera
	if cam then
		local v = cam.ViewportSize
		scale.Scale = math.clamp(math.min(v.X / 1100, v.Y / 640), 0.55, 1)
	end
end
rescale()
if Workspace.CurrentCamera then
	Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

State.start()
LocalWorld.start()
require(script.DevProbe).start() -- Studio-only; inert unless a test arms it

local function closeMenus()
	MansionUI.close()
	JournalUI.close()
end

Hud.mount(gui, {
	openJournal = function()
		MansionUI.close()
		JournalUI.toggle()
	end,
	openMansion = function()
		JournalUI.close()
		MansionUI.toggle()
	end,
	openEditor = function()
		closeMenus()
		if TrackEditor.isOpen() then
			TrackEditor.close()
		else
			TrackEditor.open()
		end
	end,
	toggleLight = LocalWorld.toggleLight,
})
CaptureUI.mount(gui, Hud.toast)
MansionUI.mount(gui, Hud.toast)
JournalUI.mount(gui)
TrackEditor.mount(gui, Hud.toast);

(State.remote("Toast") :: RemoteEvent).OnClientEvent:Connect(function(t)
	if type(t) == "table" and type(t.text) == "string" then
		Hud.toast(t.text, t.kind)
	end
end);
(State.remote("RideState") :: RemoteEvent).OnClientEvent:Connect(function(info)
	if type(info) == "table" and info.riding then
		closeMenus()
		TrackEditor.close()
		Hud.toast("All aboard! Stay seated until the end for your payout.", "info")
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.F or input.KeyCode == Enum.KeyCode.DPadDown then -- DPadUp is reserved by Roblox (TEST-20261011-05)
		Hud.setLight(LocalWorld.toggleLight())
	elseif input.KeyCode == Enum.KeyCode.J then
		JournalUI.toggle()
	elseif input.KeyCode == Enum.KeyCode.M then
		MansionUI.toggle()
	end
end)
