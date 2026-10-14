--!strict
-- GAME-002 Haunted Collector: client entry point. Mounts the HUD and menus, and wires input.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local State = require(script.State)
local LocalWorld = require(script.LocalWorld)
local HauntedTrees = require(script.HauntedTrees)
local Hud = require(script.UI.Hud)
local CaptureUI = require(script.UI.CaptureUI)
local MansionUI = require(script.UI.MansionUI)
local JournalUI = require(script.UI.JournalUI)
local TrackEditor = require(script.UI.TrackEditor)
local ShopUI = require(script.UI.ShopUI)
local DecorEditor = require(script.UI.DecorEditor)
local Nav = require(script.UI.Nav)
local Effects = require(script.Art.Effects)
local Cosmetics = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("Cosmetics"))

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
-- Art is presentation only: start it off the main thread so a slow or failed bake never blocks the HUD.
local function startArt(name: string, start: () -> ())
	task.spawn(function()
		local ok, err = pcall(function()
			start()
		end)
		if not ok then
			warn(`[Art] {name} start failed: {err}`)
		end
	end)
end
startArt("Dressing", function()
	require(script.Art.Dressing).start()
end)
startArt("Creatures", function()
	require(script.Art.Creatures).start()
end)
LocalWorld.start()
HauntedTrees.start()
require(script.DevProbe).start() -- Studio-only; inert unless a test arms it

local function closeMenus()
	Nav.closeAll()
end

Hud.mount(gui, {
	openJournal = function()
		Nav.toggle("Journal")
	end,
	openMansion = function()
		Nav.toggle("Mansion")
	end,
	openEditor = function()
		Nav.toggle("TrackEditor")
	end,
	openShop = function()
		Nav.toggle("Shop")
	end,
	toggleLight = LocalWorld.toggleLight,
})
CaptureUI.mount(gui, Hud.toast)
MansionUI.mount(gui, Hud.toast, function(id)
	Nav.open("Shop")
	if id then
		ShopUI.open(id)
	end
end, function()
	Nav.open("Decorate")
end)
JournalUI.mount(gui, Hud.toast, function(id)
	Nav.open("Shop")
	if id then
		ShopUI.open(id)
	end
end)
TrackEditor.mount(gui, Hud.toast)
DecorEditor.mount(gui, Hud.toast)
ShopUI.mount(gui, Hud.toast, function(id, key)
	Nav.open("Decorate")
	DecorEditor.begin(id, key)
end)

-- One menu at a time, one back behaviour (TASK-0048).
Nav.register(
	"Journal",
	{ open = JournalUI.open, close = JournalUI.close, isOpen = JournalUI.isOpen, root = JournalUI.root }
)
Nav.register("Mansion", {
	open = function()
		MansionUI.open()
	end,
	close = MansionUI.close,
	isOpen = MansionUI.isOpen,
	root = MansionUI.root,
})
Nav.register("Shop", {
	open = function()
		ShopUI.open()
	end,
	close = ShopUI.close,
	isOpen = ShopUI.isOpen,
	root = ShopUI.root,
	back = ShopUI.back,
})
Nav.register("TrackEditor", { open = TrackEditor.open, close = TrackEditor.close, isOpen = TrackEditor.isOpen })
Nav.register("Decorate", {
	open = function()
		DecorEditor.open()
	end,
	close = DecorEditor.close,
	isOpen = DecorEditor.isOpen,
	root = DecorEditor.root,
	back = DecorEditor.back,
})
Nav.start();

-- Capture effects other players and I have equipped (TASK-0047): purely visual bursts.
(State.remote("CosmeticFx") :: RemoteEvent).OnClientEvent:Connect(function(fx)
	if
		type(fx) == "table"
		and fx.kind == "capture"
		and type(fx.id) == "string"
		and typeof(fx.position) == "Vector3"
	then
		local item = Cosmetics.ById[fx.id]
		if item and item.category == "CaptureEffect" then
			Effects.burst(fx.position, item.look)
		end
	end
end);

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
	elseif input.KeyCode == Enum.KeyCode.J or input.KeyCode == Enum.KeyCode.DPadLeft then
		Nav.toggle("Journal")
	elseif input.KeyCode == Enum.KeyCode.M or input.KeyCode == Enum.KeyCode.DPadRight then
		Nav.toggle("Mansion")
	elseif input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.ButtonSelect then
		Nav.toggle("Shop")
	end
end)
