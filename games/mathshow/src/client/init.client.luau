--!strict
-- GAME-004 MathShow: client entry point.

local Hud = require(script.Hud)
local Menu = require(script.Menu)
local Watching = require(script.Menu.Watching)
local ModePadController = require(script.Hub.ModePadController)
local AmbientLife = require(script.Hub.AmbientLife)
local HubCosmetics = require(script.Hub.HubCosmetics)
local GlyphController = require(script.Glyphs.GlyphController)
local Quests = require(script.Menu.Quests)
local Nameplates = require(script.Hud.Nameplates)

Hud.start()
-- The menu opens first. JOIN SHOW tells the server (JoinShow remote; it decides who is in the match) and reveals the HUD;
-- a player who joins mid-match sees the WATCHING banner (Hud tells Watching) until the next match.
Hud.setVisible(false)
Watching.start({ onLeave = Menu.leaveShow })
Hud.setWatchingListener(Watching.set)
Menu.start({
	onJoin = function()
		Hud.setVisible(true)
	end,
	onLeave = function()
		Hud.setVisible(false)
		Watching.set(false)
	end,
})
Quests.start() -- QuestState, the level card and quest / level toasts (TASK-0151)
ModePadController.start()
GlyphController.start() -- hub glyphs and their counter (TASK-0121)
HubCosmetics.start() -- rank crystal spin and bob (TASK-0126); cosmetic, fails inert
AmbientLife.start() -- shooting stars and ambient loops (TASK-0144); cosmetic, fails inert
Nameplates.start() -- overhead level + title plates from Player attributes (TASK-0151); cosmetic, fails inert
print("[MathShow] client ready")
