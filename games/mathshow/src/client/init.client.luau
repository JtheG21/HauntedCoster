--!strict
-- GAME-004 MathShow: client entry point.

local Hud = require(script.Hud)
local Menu = require(script.Menu)
local Watching = require(script.Menu.Watching)
local ModePadController = require(script.Hub.ModePadController)
local HubCosmetics = require(script.Hub.HubCosmetics)
local GlyphController = require(script.Glyphs.GlyphController)

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
ModePadController.start()
GlyphController.start() -- hub glyphs and their counter (TASK-0121)
HubCosmetics.start() -- rank crystal spin and bob (TASK-0126); cosmetic, fails inert
print("[MathShow] client ready")
